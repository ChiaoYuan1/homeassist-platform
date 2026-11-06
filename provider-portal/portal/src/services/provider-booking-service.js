import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  where,
  writeBatch,
} from 'firebase/firestore';

import {
  db,
} from '../firebase.js';


const SLOT_MINUTES = 30;


async function getProviderBookings(
  providerId,
) {
  const snapshot =
    await getDocs(
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
    );


  const bookings =
    snapshot.docs.map(
      (bookingDocument) => ({
        id: bookingDocument.id,
        ...bookingDocument.data(),
      }),
    );


  bookings.sort(
    (a, b) => {
      const first =
        a.appointmentStart
          ?.toDate?.()
          ?.getTime?.() ?? 0;

      const second =
        b.appointmentStart
          ?.toDate?.()
          ?.getTime?.() ?? 0;

      return first - second;
    },
  );


  return bookings;
}


async function updateProviderBookingStatus({
  providerId,
  bookingId,
  status,
}) {
  const bookingReference =
    doc(
      db,
      'bookings',
      bookingId,
    );


  const bookingSnapshot =
    await getDoc(
      bookingReference,
    );


  if (!bookingSnapshot.exists()) {
    throw new Error(
      'Booking was not found.',
    );
  }


  const booking =
    bookingSnapshot.data();


  if (
    booking.providerId !==
    providerId
  ) {
    throw new Error(
      'This booking does not belong to this provider.',
    );
  }


  validateStatusChange(
    booking.status,
    status,
  );


  const batch =
    writeBatch(db);


  batch.update(
    bookingReference,
    {
      status,
      updatedAt:
        serverTimestamp(),
    },
  );

  if (
    status === 'accepted'
  ) {
    await addTechnicianAcceptedNotification({
      batch,
      providerId,
      bookingId,
      booking,
    });
  }

  if (
    status === 'rejected' ||
    status === 'cancelled'
  ) {
    releaseSlotReservations(
      batch,
      booking,
    );
  }


  await batch.commit();
}

async function addTechnicianAcceptedNotification({
  batch,
  providerId,
  bookingId,
  booking,
}) {
  const technicianId =
    String(
      booking.technicianId ?? '',
    ).trim();


  if (!technicianId) {
    return;
  }


  const technicianReference =
    doc(
      db,
      'providers',
      providerId,
      'technicians',
      technicianId,
    );


  const technicianSnapshot =
    await getDoc(
      technicianReference,
    );


  if (!technicianSnapshot.exists()) {
    return;
  }


  const technician =
    technicianSnapshot.data();


  const authUid =
    String(
      technician.authUid ?? '',
    ).trim();


  if (!authUid) {
    return;
  }


  const notificationReference =
    doc(
      collection(
        db,
        'notifications',
      ),
    );


  batch.set(
    notificationReference,
    {
      userId:
        authUid,

      title:
        'New Job Assigned',

      message:
        'A new service job has been assigned to you. '
        + 'Open the job to view the appointment details.',

      bookingId,

      read:
        false,

      createdAt:
        serverTimestamp(),
    },
  );
}

function validateStatusChange(
  currentStatus,
  nextStatus,
) {
  const allowedTransitions = {
    pending: [
      'accepted',
      'rejected',
    ],

    accepted: [
      'onTheWay',
    ],

    onTheWay: [
      'arrived',
    ],

    arrived: [
      'inProgress',
    ],

    inProgress: [
      'completed',
    ],

    completed: [],
    rejected: [],
    cancelled: [],
  };


  const allowed =
    allowedTransitions[
      currentStatus
    ] ?? [];


  if (
    !allowed.includes(
      nextStatus,
    )
  ) {
    throw new Error(
      `Booking cannot move from `
      + `${formatStatus(currentStatus)} `
      + `to ${formatStatus(nextStatus)}.`,
    );
  }
}


function releaseSlotReservations(
  batch,
  booking,
) {
  const start =
    booking.appointmentStart
      ?.toDate?.();

  const end =
    booking.appointmentEnd
      ?.toDate?.();


  if (
    !start ||
    !end ||
    !booking.providerId ||
    !booking.technicianId
  ) {
    return;
  }


  let cursor =
    new Date(
      start.getTime(),
    );


  while (
    cursor < end
  ) {
    const reservationId =
      `${booking.providerId}_`
      + `${booking.technicianId}_`
      + `${cursor.getTime()}`;


    batch.delete(
      doc(
        db,
        'slotReservations',
        reservationId,
      ),
    );


    cursor =
      new Date(
        cursor.getTime() +
        SLOT_MINUTES *
        60 *
        1000,
      );
  }
}


function formatStatus(
  status,
) {
  const labels = {
    pending: 'Pending',
    accepted: 'Accepted',
    rejected: 'Rejected',
    onTheWay: 'On the Way',
    arrived: 'Arrived',
    inProgress: 'In Progress',
    completed: 'Completed',
    cancelled: 'Cancelled',
    expired: 'Expired',
  };


  return labels[status] ??
    status;
}


export {
  formatStatus,
  getProviderBookings,
  updateProviderBookingStatus,
};