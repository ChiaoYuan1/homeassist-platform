import {
  collection,
  getDocs,
  writeBatch,
  doc,
} from 'firebase/firestore';

import {
  db,
} from '../firebase.js';


async function getActiveServiceCategories() {
  const snapshot = await getDocs(
    collection(db, 'serviceCategories'),
  );

  const categories = snapshot.docs
    .map((document) => ({
      id: document.id,
      ...document.data(),
    }))
    .filter(
      (category) =>
        category.active !== false,
    );

  categories.sort((a, b) =>
    (a.name || '').localeCompare(b.name || ''),
  );

  return categories;
}


async function getActiveServices() {
  const snapshot = await getDocs(
    collection(db, 'services'),
  );

  const services = snapshot.docs
    .map((document) => ({
      id: document.id,
      ...document.data(),
    }))
    .filter(
      (service) =>
        service.active !== false,
    );

  services.sort((a, b) =>
    (a.name || '').localeCompare(b.name || ''),
  );

  return services;
}


async function seedCoreCatalogue() {
  const categories = [
    {
      id: 'plumbing',
      name: 'Plumbing',
      description:
        'Pipe, drain, tap and toilet services.',
      active: true,
    },
    {
      id: 'electrical',
      name: 'Electrical',
      description:
        'Sockets, wiring, lighting and power issues.',
      active: true,
    },
    {
      id: 'appliance_repair',
      name: 'Appliance Repair',
      description:
        'Repair common household appliances.',
      active: true,
    },
    {
      id: 'gas_replacement',
      name: 'Gas Tank Replacement',
      description:
        'Household gas cylinder replacement.',
      active: true,
    },
  ];

  const services = [
    {
      id: 'leaking_pipe',
      categoryId: 'plumbing',
      name: 'Leaking Pipe',
      defaultDurationMinutes: 60,
      active: true,
    },
    {
      id: 'clogged_drain',
      categoryId: 'plumbing',
      name: 'Clogged Drain',
      defaultDurationMinutes: 60,
      active: true,
    },
    {
      id: 'broken_tap',
      categoryId: 'plumbing',
      name: 'Broken Tap',
      defaultDurationMinutes: 45,
      active: true,
    },
    {
      id: 'toilet_problem',
      categoryId: 'plumbing',
      name: 'Toilet Problem',
      defaultDurationMinutes: 60,
      active: true,
    },
    {
      id: 'power_outage',
      categoryId: 'electrical',
      name: 'Power Outage',
      defaultDurationMinutes: 90,
      active: true,
    },
    {
      id: 'faulty_socket',
      categoryId: 'electrical',
      name: 'Faulty Socket',
      defaultDurationMinutes: 45,
      active: true,
    },
    {
      id: 'wiring_problem',
      categoryId: 'electrical',
      name: 'Wiring Problem',
      defaultDurationMinutes: 120,
      active: true,
    },
    {
      id: 'light_problem',
      categoryId: 'electrical',
      name: 'Light Problem',
      defaultDurationMinutes: 45,
      active: true,
    },
    {
      id: 'air_conditioner',
      categoryId: 'appliance_repair',
      name: 'Air Conditioner',
      defaultDurationMinutes: 90,
      active: true,
    },
    {
      id: 'refrigerator',
      categoryId: 'appliance_repair',
      name: 'Refrigerator',
      defaultDurationMinutes: 120,
      active: true,
    },
    {
      id: 'washing_machine',
      categoryId: 'appliance_repair',
      name: 'Washing Machine',
      defaultDurationMinutes: 90,
      active: true,
    },
    {
      id: 'water_heater',
      categoryId: 'appliance_repair',
      name: 'Water Heater',
      defaultDurationMinutes: 90,
      active: true,
    },
    {
      id: 'gas_tank_replacement',
      categoryId: 'gas_replacement',
      name: 'Gas Tank Replacement',
      defaultDurationMinutes: 30,
      supportsBrandPreference: true,
      active: true,
    },
  ];

  const batch = writeBatch(db);

  categories.forEach((category) => {
    const {
      id,
      ...data
    } = category;

    batch.set(
      doc(
        db,
        'serviceCategories',
        id,
      ),
      data,
      {
        merge: true,
      },
    );
  });

  services.forEach((service) => {
    const {
      id,
      ...data
    } = service;

    batch.set(
      doc(
        db,
        'services',
        id,
      ),
      data,
      {
        merge: true,
      },
    );
  });

  await batch.commit();

  console.log(
    'HomeAssist service catalogue seeded successfully.',
  );
}


async function getRegistrationCatalogue() {
  let [
    categories,
    services,
  ] = await Promise.all([
    getActiveServiceCategories(),
    getActiveServices(),
  ]);

  if (
    categories.length === 0 ||
    services.length === 0
  ) {
    console.log(
      'HomeAssist catalogue missing. Initialising development catalogue...',
    );

    await seedCoreCatalogue();

    [
      categories,
      services,
    ] = await Promise.all([
      getActiveServiceCategories(),
      getActiveServices(),
    ]);
  }

  return categories.map((category) => ({
    ...category,

    services: services.filter(
      (service) =>
        service.categoryId === category.id,
    ),
  }));
}


export {
  getActiveServiceCategories,
  getActiveServices,
  getRegistrationCatalogue,
};