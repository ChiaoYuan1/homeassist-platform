import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  where,
} from 'firebase/firestore';

import {
  db,
} from '../firebase.js';


async function getProviderDashboardData(
  providerId,
) {
  const providerReference = doc(
    db,
    'providers',
    providerId,
  );

  const [
    providerSnapshot,
    branchSnapshot,
    bookingSnapshot,
  ] = await Promise.all([
    getDoc(
      providerReference,
    ),

    getDocs(
      collection(
        providerReference,
        'branches',
      ),
    ),

    getDocs(
      query(
        collection(
          db,
          'bookings',
        ),
        where(
          'providerId',
          '==',
          providerId,
        ),
      ),
    ),
  ]);

  if (!providerSnapshot.exists()) {
    return null;
  }

  const provider = {
    id:
      providerSnapshot.id,
    ...providerSnapshot.data(),
  };

  const branches = branchSnapshot.docs.map(
    (branchDocument) => ({
      id:
        branchDocument.id,
      ...branchDocument.data(),
    }),
  );

  const serviceIds = Array.isArray(
    provider.serviceIds,
  )
    ? provider.serviceIds
    : [];

  const serviceSnapshots = await Promise.all(
    serviceIds.map(
      (serviceId) =>
        getDoc(
          doc(
            db,
            'services',
            serviceId,
          ),
        ),
    ),
  );

  const services = serviceSnapshots
    .filter(
      (serviceSnapshot) =>
        serviceSnapshot.exists(),
    )
    .map(
      (serviceSnapshot) => ({
        id:
          serviceSnapshot.id,
        ...serviceSnapshot.data(),
      }),
    );

  const bookings = bookingSnapshot.docs.map(
    (bookingDocument) => ({
      id:
        bookingDocument.id,
      ...bookingDocument.data(),
    }),
  );

  const activeBookingStatuses = new Set([
    'pending',
    'accepted',
    'onTheWay',
    'arrived',
    'inProgress',
  ]);

  return {
    provider,
    branches,
    services,
    bookingCount:
      bookings.length,
    activeBookingCount:
      bookings.filter(
        (booking) =>
          activeBookingStatuses.has(
            booking.status,
          ),
      ).length,
  };
}


export {
  getProviderDashboardData,
};
