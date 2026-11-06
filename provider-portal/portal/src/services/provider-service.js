import {
  db,
} from '../firebase.js';

import {
  supabase,
} from '../supabase.js';

import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const DOCUMENT_BUCKET =
  'homeassist-demo-files';

const MAX_DOCUMENT_SIZE_BYTES =
  10 * 1024 * 1024;

const ALLOWED_DOCUMENT_TYPES =
  new Set([
    'application/pdf',
    'image/jpeg',
    'image/png',
  ]);

async function saveBusinessInformation(
  providerId,
  {
    businessName,
    businessRegistrationNumber,
    businessAddress,
  },
) {
  const providerReference =
    doc(
      db,
      'users',
      providerId,
    );


  await updateDoc(
    providerReference,
    {
      businessName:
        businessName.trim(),

      businessRegistrationNumber:
        businessRegistrationNumber.trim(),

      businessAddress:
        businessAddress.trim(),

      providerApplicationStatus:
        'draft',

      registrationStep:
        'services',

      updatedAt:
        serverTimestamp(),
    },
  );
}


async function saveServicesOffered(
  providerId,
  {
    categoryIds,
    serviceIds,
  },
) {
  const providerReference =
    doc(
      db,
      'users',
      providerId,
    );


  await updateDoc(
    providerReference,
    {
      categoryIds,
      serviceIds,

      // Kept temporarily for compatibility
      // with the earlier registration draft
      // structure.
      servicesOffered:
        categoryIds,

      providerApplicationStatus:
        'draft',

      registrationStep:
        'documents',

      updatedAt:
        serverTimestamp(),
    },
  );
}


async function saveVerificationAndLocations(
  providerId,
  {
    branches,
    files,
    existingDocuments = {},
  },
) {
  const uploadedDocuments = {
    ...existingDocuments,
  };


  for (
    const [
      documentType,
      file,
    ] of Object.entries(files)
  ) {
    if (!file) {
      continue;
    }


    validateVerificationFile(
      file,
    );


    uploadedDocuments[
      documentType
    ] =
      await uploadVerificationDocument(
        providerId,
        documentType,
        file,
      );
  }


  const providerReference =
    doc(
      db,
      'users',
      providerId,
    );


  await updateDoc(
    providerReference,
    {
      registrationBranches:
        branches,

      verificationDocuments:
        uploadedDocuments,

      providerApplicationStatus:
        'draft',

      registrationStep:
        'review',

      updatedAt:
        serverTimestamp(),
    },
  );


  return uploadedDocuments;
}


async function submitProviderApplication(
  providerId,
) {
  const providerReference =
    doc(
      db,
      'users',
      providerId,
    );


  await updateDoc(
    providerReference,
    {
      providerApplicationStatus:
        'pending',

      providerVerified:
        false,

      registrationStep:
        'review',

      submittedAt:
        serverTimestamp(),

      updatedAt:
        serverTimestamp(),
    },
  );
}


async function uploadVerificationDocument(
  providerId,
  documentType,
  file,
) {
  const safeFileName =
    sanitiseFileName(
      file.name,
    );


  const storagePath = [
    'providerApplications',
    providerId,
    'verification',
    documentType,
    `${Date.now()}_${safeFileName}`,
  ].join('/');


  const {
    error: uploadError,
  } =
    await supabase.storage
      .from(
        DOCUMENT_BUCKET,
      )
      .upload(
        storagePath,
        file,
        {
          cacheControl:
            '3600',

          contentType:
            file.type,

          upsert:
            false,
        },
      );


  if (uploadError) {
    throw new Error(
      `Document upload failed: ${uploadError.message}`,
    );
  }


  const {
    data: publicUrlData,
  } =
    supabase.storage
      .from(
        DOCUMENT_BUCKET,
      )
      .getPublicUrl(
        storagePath,
      );


  if (
    !publicUrlData
      ?.publicUrl
  ) {
    throw new Error(
      'Document uploaded, but its cloud URL could not be created.',
    );
  }


  return {
    originalName:
      file.name,

    contentType:
      file.type,

    sizeBytes:
      file.size,

    storageProvider:
      'supabase',

    bucket:
      DOCUMENT_BUCKET,

    storagePath,

    // Keep the same field name used
    // by the existing Admin UI.
    downloadUrl:
      publicUrlData.publicUrl,
  };
}


function validateVerificationFile(
  file,
) {
  if (
    !ALLOWED_DOCUMENT_TYPES
      .has(file.type)
  ) {
    throw new Error(
      'Only PDF, JPG and PNG files are allowed.',
    );
  }


  if (
    file.size >
    MAX_DOCUMENT_SIZE_BYTES
  ) {
    throw new Error(
      'Each verification document must be 10 MB or smaller.',
    );
  }
}


function sanitiseFileName(
  fileName,
) {
  return fileName
    .trim()
    .replace(
      /[^a-zA-Z0-9._-]/g,
      '_',
    );
}


async function saveProviderWorkingHours(
  providerId,
  workingHours,
) {
  const providerReference =
    doc(
      db,
      'providers',
      providerId,
    );


  await updateDoc(
    providerReference,
    {
      workingHours,

      updatedAt:
        serverTimestamp(),
    },
  );
}


async function getProviderTechnicians(
  providerId,
) {
  const snapshot =
    await getDocs(
      collection(
        db,
        'providers',
        providerId,
        'technicians',
      ),
    );


  return snapshot.docs.map(
    (
      technicianDocument,
    ) => ({
      id:
        technicianDocument.id,

      ...technicianDocument
        .data(),
    }),
  );
}

async function addProviderTechnician(
  providerId,
  {
    name,
    workEmail,
    branchId,
    serviceIds,
  },
) {
  const cleanedName =
    String(
      name ?? '',
    ).trim();

  const cleanedWorkEmail =
    String(
      workEmail ?? '',
    )
      .trim()
      .toLowerCase();

  const cleanedBranchId =
    String(
      branchId ?? '',
    ).trim();


  if (!cleanedName) {
    throw new Error(
      'Technician name is required.',
    );
  }


  if (!cleanedWorkEmail) {
    throw new Error(
      'Work email is required.',
    );
  }


  const emailPattern =
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (
    !emailPattern.test(
      cleanedWorkEmail,
    )
  ) {
    throw new Error(
      'Please enter a valid work email.',
    );
  }


  if (!cleanedBranchId) {
    throw new Error(
      'Please assign a branch.',
    );
  }


  if (
    !Array.isArray(
      serviceIds,
    ) ||
    serviceIds.length === 0
  ) {
    throw new Error(
      'Select at least one service.',
    );
  }


  const cleanedServiceIds =
    [
      ...new Set(
        serviceIds
          .map(
            (serviceId) =>
              String(
                serviceId ?? '',
              ).trim(),
          )
          .filter(Boolean),
      ),
    ];


  if (
    cleanedServiceIds.length === 0
  ) {
    throw new Error(
      'Select at least one valid service.',
    );
  }


  await addDoc(
    collection(
      db,
      'providers',
      providerId,
      'technicians',
    ),
    {
      name:
        cleanedName,

      workEmail:
        cleanedWorkEmail,

      workEmailNormalized:
        cleanedWorkEmail,

      branchId:
        cleanedBranchId,

      active:
        true,

      serviceIds:
        cleanedServiceIds,

      accountStatus:
        'pending',

      authUid:
        null,

      createdAt:
        serverTimestamp(),

      updatedAt:
        serverTimestamp(),
    },
  );
}

async function updateProviderTechnician(
  providerId,
  technicianId,
  {
    branchId,
    serviceIds,
    active,
  },
) {
  const cleanedProviderId =
    String(
      providerId ?? '',
    ).trim();


  const cleanedTechnicianId =
    String(
      technicianId ?? '',
    ).trim();


  if (!cleanedProviderId) {
    throw new Error(
      'Provider ID is required.',
    );
  }


  if (!cleanedTechnicianId) {
    throw new Error(
      'Technician ID is required.',
    );
  }


  const updates = {
    updatedAt:
      serverTimestamp(),
  };


  /** Only change branchId when the caller explicitly sends it.*/
  if (
    branchId !== undefined
  ) {
    const cleanedBranchId =
      String(
        branchId ?? '',
      ).trim();


    updates.branchId =
      cleanedBranchId ||
      null;
  }


  /* Only change qualified services
   * when serviceIds is supplied. */
  if (
    serviceIds !== undefined
  ) {
    if (
      !Array.isArray(
        serviceIds,
      )
    ) {
      throw new Error(
        'Qualified services must be a list.',
      );
    }


    const cleanedServiceIds =
      [
        ...new Set(
          serviceIds
            .map(
              (serviceId) =>
                String(
                  serviceId ??
                  '',
                ).trim(),
            )
            .filter(Boolean),
        ),
      ];


    if (
      cleanedServiceIds
        .length === 0
    ) {
      throw new Error(
        'Select at least one service.',
      );
    }


    updates.serviceIds =
      cleanedServiceIds;
  }


  /*
   * Only change technician status
   * when active is supplied.
   */
  if (
    active !== undefined
  ) {
    if (
      typeof active !==
      'boolean'
    ) {
      throw new Error(
        'Technician status must be active or inactive.',
      );
    }


    updates.active =
      active;
  }


  /*
   * updatedAt is always included,
   * so check whether another field
   * was actually supplied.
   */
  if (
    Object.keys(
      updates,
    ).length === 1
  ) {
    throw new Error(
      'No technician changes were provided.',
    );
  }


  const technicianReference =
    doc(
      db,
      'providers',
      cleanedProviderId,
      'technicians',
      cleanedTechnicianId,
    );


  await updateDoc(
    technicianReference,
    updates,
  );
}

const TECHNICIAN_AVAILABILITY_MODES =
  new Set([
    'business_hours',
    'custom_weekly',
  ]);


const TECHNICIAN_OVERRIDE_STATUSES =
  new Set([
    'available',
    'absent',
    'on_leave',
    'custom_hours',
  ]);


const WEEK_DAYS = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];


async function saveTechnicianAvailabilitySettings(
  providerId,
  technicianId,
  {
    availabilityMode,
    weeklyAvailability,
  },
) {
  const cleanedProviderId =
    String(
      providerId ?? '',
    ).trim();

  const cleanedTechnicianId =
    String(
      technicianId ?? '',
    ).trim();


  if (!cleanedProviderId) {
    throw new Error(
      'Provider ID is required.',
    );
  }


  if (!cleanedTechnicianId) {
    throw new Error(
      'Technician ID is required.',
    );
  }


  if (
    !TECHNICIAN_AVAILABILITY_MODES
      .has(availabilityMode)
  ) {
    throw new Error(
      'Invalid technician availability mode.',
    );
  }


  const updates = {
    availabilityMode,

    updatedAt:
      serverTimestamp(),
  };


  /*
   * If the technician follows business hours,
   * the provider working hours are used.
   *
   * Existing custom weekly settings are not
   * deleted, so they can be restored later if
   * the manager switches back to custom mode.
   */
  if (
    availabilityMode ===
    'custom_weekly'
  ) {
    updates.weeklyAvailability =
      normaliseWeeklyAvailability(
        weeklyAvailability,
      );
  }


  const technicianReference =
    doc(
      db,
      'providers',
      cleanedProviderId,
      'technicians',
      cleanedTechnicianId,
    );


  await updateDoc(
    technicianReference,
    updates,
  );
}


function normaliseWeeklyAvailability(
  weeklyAvailability,
) {
  if (
    !weeklyAvailability ||
    typeof weeklyAvailability !==
      'object'
  ) {
    throw new Error(
      'Weekly availability is required.',
    );
  }


  const normalised = {};


  for (
    const day of WEEK_DAYS
  ) {
    const daySettings =
      weeklyAvailability[day] ??
      {};


    const enabled =
      daySettings.enabled === true;


    const startMinute =
      Number(
        daySettings.startMinute ??
        540,
      );


    const endMinute =
      Number(
        daySettings.endMinute ??
        1080,
      );


    if (
      enabled &&
      !isValidAvailabilityTimeRange(
        startMinute,
        endMinute,
      )
    ) {
      throw new Error(
        `Invalid working hours for ${formatAvailabilityDay(
          day,
        )}.`,
      );
    }


    normalised[day] = {
      enabled,
      startMinute,
      endMinute,
    };
  }


  return normalised;
}


async function getTechnicianAvailabilityOverrides(
  providerId,
  technicianId,
) {
  const snapshot =
    await getDocs(
      collection(
        db,
        'providers',
        providerId,
        'technicians',
        technicianId,
        'availabilityOverrides',
      ),
    );


  const overrides =
    snapshot.docs.map(
      (
        availabilityDocument,
      ) => ({
        id:
          availabilityDocument.id,

        ...availabilityDocument
          .data(),
      }),
    );


  overrides.sort(
    (first, second) =>
      String(
        first.date ??
        first.id,
      ).localeCompare(
        String(
          second.date ??
          second.id,
        ),
      ),
  );


  return overrides;
}


async function saveTechnicianAvailabilityOverride(
  providerId,
  technicianId,
  {
    date,
    status,
    startMinute,
    endMinute,
  },
) {
  const cleanedProviderId =
    String(
      providerId ?? '',
    ).trim();

  const cleanedTechnicianId =
    String(
      technicianId ?? '',
    ).trim();

  const cleanedDate =
    String(
      date ?? '',
    ).trim();


  if (!cleanedProviderId) {
    throw new Error(
      'Provider ID is required.',
    );
  }


  if (!cleanedTechnicianId) {
    throw new Error(
      'Technician ID is required.',
    );
  }


  if (
    !isValidAvailabilityDate(
      cleanedDate,
    )
  ) {
    throw new Error(
      'Please select a valid date.',
    );
  }


  if (
    !TECHNICIAN_OVERRIDE_STATUSES
      .has(status)
  ) {
    throw new Error(
      'Invalid availability status.',
    );
  }


  const overrideData = {
    date:
      cleanedDate,

    status,

    updatedAt:
      serverTimestamp(),
  };


  /*
   * Custom Hours needs an explicit
   * start and end time.
   */
  if (
    status ===
    'custom_hours'
  ) {
    const cleanedStartMinute =
      Number(startMinute);

    const cleanedEndMinute =
      Number(endMinute);


    if (
      !isValidAvailabilityTimeRange(
        cleanedStartMinute,
        cleanedEndMinute,
      )
    ) {
      throw new Error(
        'Custom closing time must be later than the opening time.',
      );
    }


    overrideData.startMinute =
      cleanedStartMinute;

    overrideData.endMinute =
      cleanedEndMinute;
  }


  /*
   * The date itself is used as the
   * Firestore document ID.
   *
   * This means one technician can have
   * only one override for a particular
   * calendar date.
   */
  const overrideReference =
    doc(
      db,
      'providers',
      cleanedProviderId,
      'technicians',
      cleanedTechnicianId,
      'availabilityOverrides',
      cleanedDate,
    );


  await setDoc(
    overrideReference,
    overrideData,
  );
}


async function deleteTechnicianAvailabilityOverride(
  providerId,
  technicianId,
  date,
) {
  const cleanedDate =
    String(
      date ?? '',
    ).trim();


  if (
    !isValidAvailabilityDate(
      cleanedDate,
    )
  ) {
    throw new Error(
      'Invalid availability date.',
    );
  }


  const overrideReference =
    doc(
      db,
      'providers',
      providerId,
      'technicians',
      technicianId,
      'availabilityOverrides',
      cleanedDate,
    );


  await deleteDoc(
    overrideReference,
  );
}


function isValidAvailabilityTimeRange(
  startMinute,
  endMinute,
) {
  return (
    Number.isInteger(
      startMinute,
    ) &&
    Number.isInteger(
      endMinute,
    ) &&
    startMinute >= 0 &&
    startMinute < 1440 &&
    endMinute > 0 &&
    endMinute <= 1440 &&
    endMinute >
      startMinute
  );
}


function isValidAvailabilityDate(
  value,
) {
  if (
    !/^\d{4}-\d{2}-\d{2}$/
      .test(value)
  ) {
    return false;
  }


  const [
    year,
    month,
    day,
  ] = value
    .split('-')
    .map(Number);


  const parsed =
    new Date(
      Date.UTC(
        year,
        month - 1,
        day,
      ),
    );


  return (
    parsed.getUTCFullYear() ===
      year &&
    parsed.getUTCMonth() ===
      month - 1 &&
    parsed.getUTCDate() ===
      day
  );
}


function formatAvailabilityDay(
  value,
) {
  return String(
    value ?? '',
  )
    .replace(
      /\b\w/g,
      (letter) =>
        letter.toUpperCase(),
    );
}

export {
  saveBusinessInformation,
  saveServicesOffered,
  saveVerificationAndLocations,
  submitProviderApplication,
  saveProviderWorkingHours,
  getProviderTechnicians,
  addProviderTechnician,
  updateProviderTechnician,
  saveTechnicianAvailabilitySettings,
  getTechnicianAvailabilityOverrides,
  saveTechnicianAvailabilityOverride,
  deleteTechnicianAvailabilityOverride,
};
