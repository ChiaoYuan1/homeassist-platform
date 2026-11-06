import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  updateDoc,
  where,
  serverTimestamp,
} from 'firebase/firestore';

import {
  httpsCallable,
} from 'firebase/functions';

import {
  db,
  functions,
} from '../firebase.js';

async function getPendingProviders() {
  const pendingQuery = query(
    collection(db, 'users'),
    where('role', '==', 'provider'),
    where('providerApplicationStatus', '==', 'pending'),
  );

  const snapshot = await getDocs(pendingQuery);

  return snapshot.docs.map(
    (providerDocument) => ({
      id: providerDocument.id,
      ...providerDocument.data(),
    }),
  );
}

async function getProviderApplication(providerId) {
  const snapshot = await getDoc(
    doc(db, 'users', providerId),
  );

  if (!snapshot.exists()) {
    return null;
  }

  return {
    id: snapshot.id,
    ...snapshot.data(),
  };
}

async function approveProviderApplication(providerId) {
  const approveProvider = httpsCallable(
    functions,
    'approveProvider',
  );

  const response = await approveProvider({ providerId });
  return response.data;
}

async function rejectProviderApplication(providerId, reason) {
  const rejectProvider = httpsCallable(
    functions,
    'rejectProvider',
  );

  const response = await rejectProvider({
    providerId,
    reason: reason.trim(),
  });

  return response.data;
}

// Administration only. Firestore Rules must independently enforce admin access.
async function getAdminReports() {
  const snapshot = await getDocs(
    collection(db, 'reports'),
  );

  const reports = snapshot.docs.map(
    (reportDoc) => ({
      id: reportDoc.id,
      ...reportDoc.data(),
    }),
  );

  // Resolve each report independently: a deleted booking or provider should
  // not prevent the admin from seeing the original complaint.
  const detailed = await Promise.all(
    reports.map(async (report) => {
      const details = {
        ...report,
        providerName: 'Service provider unavailable',
        branchName: 'Not available',
        technicianName: 'Not assigned',
        bookingStatus: 'Unknown',
        appointmentStart: null,
        customerName: 'Customer',
      };

      let booking = null;

      if (report.bookingId) {
        try {
          const bookingSnapshot = await getDoc(
            doc(db, 'bookings', report.bookingId),
          );

          if (bookingSnapshot.exists()) {
            booking = bookingSnapshot.data();
            details.bookingStatus = String(
              booking.status ?? 'Unknown',
            );
            details.appointmentStart = booking.appointmentStart ?? null;
          }
        } catch (error) {
          console.warn('Cannot read complaint booking:', report.id, error);
        }
      }

      const providerId = booking?.providerId || report.providerId;

      if (providerId) {
        try {
          const providerSnapshot = await getDoc(
            doc(db, 'providers', providerId),
          );

          if (providerSnapshot.exists()) {
            const provider = providerSnapshot.data();
            details.providerName =
              String(provider.businessName || provider.name || '').trim() ||
              details.providerName;
          }
        } catch (error) {
          console.warn('Cannot read provider:', providerId, error);
        }

        // Provider registration data may still reside in users/{providerId}.
        if (details.providerName === 'Service provider unavailable') {
          try {
            const userSnapshot = await getDoc(
              doc(db, 'users', providerId),
            );

            if (userSnapshot.exists()) {
              const user = userSnapshot.data();
              details.providerName =
                String(user.businessName || user.displayName || '').trim() ||
                details.providerName;
            }
          } catch (error) {
            console.warn('Cannot read provider profile:', providerId, error);
          }
        }

        const branchId = booking?.providerBranchId;

        if (branchId) {
          try {
            const branchSnapshot = await getDoc(
              doc(db, 'providers', providerId, 'branches', branchId),
            );

            if (branchSnapshot.exists()) {
              details.branchName =
                String(branchSnapshot.data().name || '').trim() ||
                details.branchName;
            }
          } catch (error) {
            console.warn('Cannot read provider branch:', branchId, error);
          }
        }

        const technicianId = booking?.technicianId;

        if (technicianId) {
          try {
            const technicianSnapshot = await getDoc(
              doc(db, 'providers', providerId, 'technicians', technicianId),
            );

            if (technicianSnapshot.exists()) {
              details.technicianName =
                String(technicianSnapshot.data().name || '').trim() ||
                details.technicianName;
            }
          } catch (error) {
            console.warn('Cannot read assigned technician:', technicianId, error);
          }
        }
      }

      if (report.reporterId) {
        try {
          const customerSnapshot = await getDoc(
            doc(db, 'users', report.reporterId),
          );

          if (customerSnapshot.exists()) {
            const customer = customerSnapshot.data();
            details.customerName =
              String(customer.displayName || customer.name || '').trim() ||
              details.customerName;
          }
        } catch (error) {
          console.warn('Cannot read report customer:', report.reporterId, error);
        }
      }

      return details;
    }),
  );

  const toMillis = (value) => {
    if (value && typeof value.toMillis === 'function') {
      return value.toMillis();
    }

    return 0;
  };

  detailed.sort(
    (a, b) => toMillis(b.createdAt) - toMillis(a.createdAt),
  );

  return detailed;
}

// Keep values consistent with ReportStatusX.fromValue in app_enums.dart.
// Verify the exact under-review string before enabling this status in production.
async function updateAdminReportStatus(reportId, status) {
  const allowed = new Set([
    'open',
    'under_review',
    'resolved',
    'dismissed',
  ]);

  if (!allowed.has(status)) {
    throw new Error('Invalid complaint status.');
  }

  if (!String(reportId ?? '').trim()) {
    throw new Error('Report ID is required.');
  }

  await updateDoc(
    doc(db, 'reports', reportId),
    {
      status,
      updatedAt: serverTimestamp(),
    },
  );
}

// Administrative provider directory. Uses the existing users and providers
// collections; no duplicate provider records are created.
async function getAdminProviders() {
  const providerQuery = query(
    collection(db, 'users'),
    where('role', '==', 'provider'),
  );

  const snapshot = await getDocs(providerQuery);

  const results = await Promise.all(
    snapshot.docs.map(async (userDocument) => {
      const user = userDocument.data();
      const providerId = userDocument.id;
      const providerDocument = await getDoc(
        doc(db, 'providers', providerId),
      );
      const provider = providerDocument.exists()
        ? providerDocument.data()
        : null;

      const approvalStatus = String(
        user.providerApplicationStatus ||
        (user.providerVerified === true ? 'approved' : 'draft'),
      );

      return {
        id: providerId,
        businessName: String(
          provider?.businessName ||
          user.businessName ||
          user.displayName ||
          'Unnamed provider',
        ),
        email: String(user.email || ''),
        businessAddress: String(
          provider?.businessAddress || user.businessAddress || '',
        ),
        approvalStatus,
        isVerified: user.providerVerified === true ||
          approvalStatus === 'approved' ||
          provider?.verificationStatus === 'approved',
        hasProviderRecord: provider !== null,
        active: provider !== null && provider.active !== false,
        categoryIds: Array.isArray(provider?.categoryIds)
          ? provider.categoryIds
          : Array.isArray(user.categoryIds) ? user.categoryIds : [],
        serviceIds: Array.isArray(provider?.serviceIds)
          ? provider.serviceIds
          : Array.isArray(user.serviceIds) ? user.serviceIds : [],
      };
    }),
  );

  return results.sort((a, b) =>
    a.businessName.localeCompare(b.businessName),
  );
}

// This action changes service listing availability ONLY. It does not
// disable a Firebase Auth account or modify application verification.
// Firestore Security Rules must enforce administrator write permissions.
async function setAdminProviderListingActive(providerId, active) {
  const cleanedProviderId = String(providerId ?? '').trim();

  if (!cleanedProviderId) {
    throw new Error('Provider ID is required.');
  }

  if (typeof active !== 'boolean') {
    throw new Error('Listing status must be true or false.');
  }

  const userSnapshot = await getDoc(
    doc(db, 'users', cleanedProviderId),
  );

  if (!userSnapshot.exists() || userSnapshot.data().role !== 'provider') {
    throw new Error('Provider account not found.');
  }

  const user = userSnapshot.data();
  const approved = user.providerVerified === true ||
    user.providerApplicationStatus === 'approved';

  if (!approved) {
    throw new Error('Only approved providers can have active listings.');
  }

  const providerReference = doc(
    db,
    'providers',
    cleanedProviderId,
  );
  const providerSnapshot = await getDoc(providerReference);

  if (!providerSnapshot.exists()) {
    throw new Error('Provider business profile is not ready.');
  }

  await updateDoc(
    providerReference,
    {
      active,
      updatedAt: serverTimestamp(),
    },
  );
}

// The dashboard counts booking statuses, not merely all booking records.
async function getAdminActiveBookingCount() {
  const snapshot = await getDocs(
    collection(db, 'bookings'),
  );

  const activeStatuses = new Set([
    'pending',
    'accepted',
    'onTheWay',
    'on_the_way',
    'arrived',
    'inProgress',
    'in_progress',
  ]);

  return snapshot.docs.filter((bookingDocument) =>
    activeStatuses.has(bookingDocument.data().status),
  ).length;
}

export {
  approveProviderApplication,
  getPendingProviders,
  getProviderApplication,
  rejectProviderApplication,
  getAdminReports,
  updateAdminReportStatus,
  getAdminProviders,
  setAdminProviderListingActive,
  getAdminActiveBookingCount,
};
