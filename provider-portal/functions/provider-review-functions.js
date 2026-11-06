
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const {getAuth} = require("firebase-admin/auth");

const REGION = "asia-southeast1";
const MAX_BRANCHES = 20;
const MAX_SERVICES = 50;

/**
 * Confirms that the caller is signed in and has the admin role.
 * @param {object} request Firebase callable request.
 * @return {Promise<string>} Administrator user ID.
 */
async function requireAdmin(request) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const db = getFirestore();
  const adminSnapshot = await db.collection("users")
      .doc(request.auth.uid).get();
  const adminData = adminSnapshot.exists ? adminSnapshot.data() : null;

  if (!adminData || adminData.role !== "admin") {
    throw new HttpsError(
        "permission-denied", "Administrator access is required.");
  }
  return request.auth.uid;
}

/**
 * Reads the provider ID from the submitted request.
 * @param {object} request Firebase callable request.
 * @return {string} Provider ID.
 */
function readProviderId(request) {
  const suppliedId = request.data && request.data.providerId != null ?
    request.data.providerId : "";
  const providerId = String(suppliedId).trim();

  if (!providerId) {
    throw new HttpsError("invalid-argument", "A provider ID is required.");
  }
  return providerId;
}

/**
 * Removes empty entries and duplicates from an array of strings.
 * @param {*} value Input value.
 * @return {string[]} Cleaned values.
 */
function cleanStringArray(value) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.map((item) => String(item).trim()).filter(Boolean))];
}

/**
 * Validates the provider's submitted branch locations.
 * @param {*} value Branch list.
 * @return {object[]} Validated branches.
 */
function validateBranches(value) {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpsError(
        "failed-precondition", "At least one provider branch is required.");
  }
  if (value.length > MAX_BRANCHES) {
    throw new HttpsError("failed-precondition",
        `A maximum of ${MAX_BRANCHES} branches is supported.`);
  }

  return value.map((branch, index) => {
    const item = branch || {};
    const name = String(item.name == null ? "" : item.name).trim();
    const address = String(item.address == null ? "" : item.address).trim();
    const latitude = Number(item.latitude);
    const longitude = Number(item.longitude);

    if (!name || !address ||
        !Number.isFinite(latitude) || !Number.isFinite(longitude) ||
        latitude < -90 || latitude > 90 ||
        longitude < -180 || longitude > 180) {
      throw new HttpsError("failed-precondition",
          `Branch ${index + 1} has incomplete or invalid ` +
          "location information.");
    }
    return {name, address, latitude, longitude, active: item.active !== false};
  });
}

/**
 * Confirms required verification documents have been supplied.
 * @param {string[]} categoryIds Selected categories.
 * @param {object} documents Uploaded verification document metadata.
 * @return {void}
 */
function validateRequiredDocuments(categoryIds, documents) {
  const docs = documents || {};
  if (!docs.ssm || !docs.ssm.downloadUrl) {
    throw new HttpsError("failed-precondition",
        "The SSM verification document is required.");
  }
  if (categoryIds.includes("electrical")) {
    if (!docs.stContractor || !docs.stContractor.downloadUrl) {
      throw new HttpsError("failed-precondition",
          "The ST contractor document is required for Electrical providers.");
    }
    if (!docs.stCompetency || !docs.stCompetency.downloadUrl) {
      throw new HttpsError("failed-precondition",
          "The ST competency document is required for Electrical providers.");
    }
  }
  if (categoryIds.includes("gas_replacement") &&
      (!docs.kpdn || !docs.kpdn.downloadUrl)) {
    throw new HttpsError("failed-precondition",
        "The KPDN document is required for Gas/LPG providers.");
  }
}

/**
 * Loads and validates selected services against the service catalogue.
 * @param {object} db Firestore database instance.
 * @param {string[]} categoryIds Selected category IDs.
 * @param {string[]} serviceIds Selected service IDs.
 * @return {Promise<Map>} Map of valid services.
 */
async function getValidatedServices(db, categoryIds, serviceIds) {
  if (serviceIds.length === 0) {
    throw new HttpsError("failed-precondition",
        "At least one service must be selected.");
  }
  if (serviceIds.length > MAX_SERVICES) {
    throw new HttpsError("failed-precondition",
        `A maximum of ${MAX_SERVICES} services is supported.`);
  }

  const references = serviceIds.map((id) => db.collection("services").doc(id));
  const snapshots = await db.getAll(...references);
  const services = new Map();

  for (const snapshot of snapshots) {
    if (!snapshot.exists) {
      throw new HttpsError("failed-precondition",
          `Service ${snapshot.id} does not exist.`);
    }
    const data = snapshot.data();
    if (!data || data.active !== true) {
      throw new HttpsError("failed-precondition",
          `Service ${snapshot.id} is not active.`);
    }
    const categoryId = String(data.categoryId == null ? "" : data.categoryId);
    if (!categoryIds.includes(categoryId)) {
      throw new HttpsError("failed-precondition",
          `Service ${snapshot.id} does not belong to a selected category.`);
    }
    services.set(snapshot.id, data);
  }
  return services;
}

const approveProvider = onCall({region: REGION}, async (request) => {
  const adminId = await requireAdmin(request);
  const providerId = readProviderId(request);
  const db = getFirestore();
  const userReference = db.collection("users").doc(providerId);
  const userSnapshot = await userReference.get();

  if (!userSnapshot.exists) {
    throw new HttpsError("not-found", "Provider application was not found.");
  }
  const application = userSnapshot.data();
  if (!application || application.role !== "provider") {
    throw new HttpsError("failed-precondition",
        "The selected account is not a provider account.");
  }
  if (application.providerApplicationStatus !== "pending") {
    throw new HttpsError("failed-precondition",
        "Only submitted pending applications can be approved.");
  }

  // New accounts must verify email ownership before approval.
  if (application.emailVerificationRequired === true) {
    const authUser = await getAuth().getUser(providerId);
    if (!authUser.emailVerified) {
      throw new HttpsError("failed-precondition",
          "The provider must verify their email before approval.");
    }
  }

  const businessName = String(application.businessName == null ?
    "" : application.businessName).trim();
  const businessAddress = String(application.businessAddress == null ?
    "" : application.businessAddress).trim();
  const businessRegistrationNumber = String(
      application.businessRegistrationNumber == null ?
        "" : application.businessRegistrationNumber).trim();

  if (!businessName || !businessAddress || !businessRegistrationNumber) {
    throw new HttpsError("failed-precondition",
        "The provider business information is incomplete.");
  }

  const categoryIds = cleanStringArray(application.categoryIds);
  const serviceIds = cleanStringArray(application.serviceIds);
  if (categoryIds.length === 0) {
    throw new HttpsError("failed-precondition",
        "At least one service category is required.");
  }

  const branches = validateBranches(application.registrationBranches);
  const verificationDocuments = application.verificationDocuments || {};
  validateRequiredDocuments(categoryIds, verificationDocuments);
  const services = await getValidatedServices(db, categoryIds, serviceIds);

  const providerReference = db.collection("providers").doc(providerId);
  const [existingProviderSnapshot, existingBranchesSnapshot,
    existingOfferingsSnapshot] = await Promise.all([
    providerReference.get(),
    providerReference.collection("branches").get(),
    providerReference.collection("serviceOfferings").get(),
  ]);
  const existingProvider = existingProviderSnapshot.exists ?
    existingProviderSnapshot.data() : {};
  const batch = db.batch();

  batch.set(providerReference, {
    businessName,
    businessAddress,
    businessRegistrationNumber,
    verificationStatus: "approved",
    active: true,
    categoryIds,
    serviceIds,
    workingHours: existingProvider.workingHours || {},
    rating: Number(existingProvider.rating == null ?
      0 : existingProvider.rating),
    reviewCount: Number(existingProvider.reviewCount == null ?
      0 : existingProvider.reviewCount),
    verificationDocuments,
    approvedAt: FieldValue.serverTimestamp(),
    approvedBy: adminId,
    updatedAt: FieldValue.serverTimestamp(),
    createdAt: existingProvider.createdAt || FieldValue.serverTimestamp(),
  }, {merge: true});

  const wantedBranchIds = new Set();
  branches.forEach((branch, index) => {
    const branchId = `branch_${String(index + 1).padStart(2, "0")}`;
    wantedBranchIds.add(branchId);
    batch.set(providerReference.collection("branches").doc(branchId), {
      ...branch,
      providerId,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });
  for (const oldBranch of existingBranchesSnapshot.docs) {
    if (!wantedBranchIds.has(oldBranch.id)) batch.delete(oldBranch.ref);
  }

  const wantedServiceIds = new Set(serviceIds);
  for (const serviceId of serviceIds) {
    const serviceData = services.get(serviceId);
    const duration = serviceData && serviceData.defaultDurationMinutes != null ?
      serviceData.defaultDurationMinutes : 60;
    batch.set(providerReference.collection("serviceOfferings").doc(serviceId), {
      active: true,
      estimatedDurationMinutes: Number(duration),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
  for (const oldOffering of existingOfferingsSnapshot.docs) {
    if (!wantedServiceIds.has(oldOffering.id)) batch.delete(oldOffering.ref);
  }

  batch.update(userReference, {
    providerVerified: true,
    providerApplicationStatus: "approved",
    reviewedAt: FieldValue.serverTimestamp(),
    reviewedBy: adminId,
    rejectionReason: FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();

  return {success: true, providerId, branchCount: branches.length,
    serviceCount: serviceIds.length};
});

const rejectProvider = onCall({region: REGION}, async (request) => {
  const adminId = await requireAdmin(request);
  const providerId = readProviderId(request);
  const suppliedReason = request.data && request.data.reason != null ?
    request.data.reason : "";
  const reason = String(suppliedReason).trim();

  if (!reason) {
    throw new HttpsError("invalid-argument", "A rejection reason is required.");
  }
  if (reason.length > 500) {
    throw new HttpsError(
        "invalid-argument", "The rejection reason is too long.");
  }

  const db = getFirestore();
  const userReference = db.collection("users").doc(providerId);
  const userSnapshot = await userReference.get();
  if (!userSnapshot.exists) {
    throw new HttpsError("not-found", "Provider application was not found.");
  }
  const application = userSnapshot.data();
  if (!application || application.role !== "provider") {
    throw new HttpsError("failed-precondition",
        "The selected account is not a provider account.");
  }
  if (application.providerApplicationStatus !== "pending") {
    throw new HttpsError("failed-precondition",
        "Only submitted pending applications can be rejected.");
  }

  const providerReference = db.collection("providers").doc(providerId);
  const providerSnapshot = await providerReference.get();
  const batch = db.batch();
  batch.update(userReference, {
    providerVerified: false,
    providerApplicationStatus: "rejected",
    reviewedAt: FieldValue.serverTimestamp(),
    reviewedBy: adminId,
    rejectionReason: reason,
    updatedAt: FieldValue.serverTimestamp(),
  });

  if (providerSnapshot.exists) {
    batch.set(providerReference, {
      verificationStatus: "rejected",
      active: false,
      reviewedAt: FieldValue.serverTimestamp(),
      reviewedBy: adminId,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
  await batch.commit();
  return {success: true, providerId};
});

module.exports = {approveProvider, rejectProvider};
