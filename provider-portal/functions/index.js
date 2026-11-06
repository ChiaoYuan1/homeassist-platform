
const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

// Initialize Firebase Admin once for all exported Cloud Functions.
initializeApp();

setGlobalOptions({
  maxInstances: 3,
  region: "asia-southeast1",
});

// =========================
// PROVIDER REVIEW FUNCTIONS
// =========================

// Use the comprehensive provider application review implementation.
// These are the only exports for approveProvider and rejectProvider.
const {
  approveProvider,
  rejectProvider,
} = require("./provider-review-functions");

exports.approveProvider = approveProvider;
exports.rejectProvider = rejectProvider;

// =========================
// EMAILJS PASSWORD RESET
// =========================

/**
 * Sends the Firebase password reset link using the EmailJS template.
 * @param {string} email Recipient email address.
 * @param {string} resetLink One-time Firebase password reset URL.
 * @return {Promise<void>} Resolves after EmailJS accepts the request.
 */
async function sendResetEmail(email, resetLink) {
  const serviceId = process.env.EMAILJS_SERVICE_ID;
  const templateId = process.env.EMAILJS_TEMPLATE_ID;
  const publicKey = process.env.EMAILJS_PUBLIC_KEY;
  const privateKey = process.env.EMAILJS_PRIVATE_KEY;

  if (!serviceId || !templateId || !publicKey || !privateKey) {
    logger.error("EmailJS configuration is missing.");
    throw new Error("EMAIL_CONFIGURATION_MISSING");
  }

  const payload = {
    service_id: serviceId,
    template_id: templateId,
    user_id: publicKey,
    accessToken: privateKey,
    template_params: {
      to_email: email,
      reset_link: resetLink,
    },
  };

  const response = await fetch(
      "https://api.emailjs.com/api/v1.0/email/send",
      {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify(payload),
      },
  );

  const responseText = await response.text();

  if (!response.ok) {
    logger.error("EmailJS failed to send email.", {
      status: response.status,
      response: responseText,
    });
    throw new Error("EMAIL_SEND_FAILED");
  }

  logger.info("EmailJS email sent successfully.", {
    status: response.status,
  });
}

// =========================
// REQUEST PASSWORD RESET
// =========================

// Preserve the existing password reset callable and response behaviour.
exports.requestPasswordReset = onCall(async (request) => {
  const email = request.data && request.data.email;

  if (typeof email !== "string" ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) {
    throw new HttpsError(
        "invalid-argument", "Please enter a valid email address.");
  }

  const normalizedEmail = email.trim().toLowerCase();

  try {
    const resetLink = await getAuth()
        .generatePasswordResetLink(normalizedEmail);

    await sendResetEmail(normalizedEmail, resetLink);
    logger.info("Password reset email processed.");
  } catch (error) {
    // Keep the user-facing response identical for existing and unknown emails.
    logger.error("Password reset request failed.", {
      code: error && error.code ? error.code : "unknown",
    });
  }

  return {
    success: true,
    message:
      "If the email belongs to a " +
      "HomeAssist account, a password " +
      "reset link will be sent.",
  };
});

// =========================
// INITIALISE PROVIDER PROFILE
// =========================

// Create the initial, unapproved Firestore profile for a provider account.
exports.initializeProviderProfile = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign-in is required.");
  }

  const displayName = request.data &&
    typeof request.data.displayName === "string" ?
    request.data.displayName.trim() : "";

  if (displayName.length < 2 || displayName.length > 80) {
    throw new HttpsError(
        "invalid-argument", "Enter a name between 2 and 80 characters.");
  }

  const uid = request.auth.uid;
  const account = await getAuth().getUser(uid);

  if (!account.email) {
    throw new HttpsError("failed-precondition", "A valid email is required.");
  }

  const userReference = getFirestore().collection("users").doc(uid);
  const existingSnapshot = await userReference.get();

  if (existingSnapshot.exists) {
    const existingData = existingSnapshot.data();
    if (!existingData || existingData.role !== "provider") {
      throw new HttpsError(
          "already-exists", "This account belongs to another user role.");
    }
    return {success: true, existing: true};
  }

  try {
    // create() does not overwrite an existing user document.
    await userReference.create({
      displayName: displayName,
      email: account.email.toLowerCase(),
      role: "provider",
      providerVerified: false,
      providerApplicationStatus: "draft",
      registrationStep: "business",
      emailVerificationRequired: true,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    // Retry-safe handling if two requests race to create the same profile.
    if (error && (error.code === 6 || error.code === "already-exists")) {
      const createdSnapshot = await userReference.get();
      const createdData = createdSnapshot.exists ?
        createdSnapshot.data() : null;
      if (createdData && createdData.role === "provider") {
        return {success: true, existing: true};
      }
    }

    logger.error("Unable to initialize provider profile.", {
      uid: uid,
      code: error && error.code ? error.code : "unknown",
    });
    throw error;
  }

  logger.info("Provider account profile initialized.", {providerId: uid});
  return {success: true, existing: false};
});


// =========================
// SUPABASE AUTH INTEGRATION
// =========================

exports.ensureSupabaseAuthClaim = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "Sign-in is required.",
    );
  }

  const uid = request.auth.uid;
  const account = await getAuth().getUser(uid);

  if (account.disabled) {
    throw new HttpsError(
        "permission-denied",
        "This account is disabled.",
    );
  }

  const existingClaims = account.customClaims || {};

  // Do not overwrite another custom role.
  if (existingClaims.role &&
      existingClaims.role !== "authenticated") {
    logger.error("Conflicting custom role.", {uid: uid});
    throw new HttpsError(
        "failed-precondition",
        "Existing authentication role requires review.",
    );
  }

  if (existingClaims.role === "authenticated") {
    return {success: true, updated: false};
  }

  await getAuth().setCustomUserClaims(uid, {
    ...existingClaims,
    role: "authenticated",
  });

  logger.info("Supabase authentication claim assigned.", {
    uid: uid,
  });

  return {success: true, updated: true};
});
