
 // HomeAssist Firestore security smoke tests (local emulator only).
 // Save in C:\homeassist_portal\security-tests\firestore.rules.test.cjs
 // Install test dependencies within security-tests using:
 //   npm init -y
 //   npm install --save-dev firebase @firebase/rules-unit-testing
 // Run after starting the emulator in a separate terminal:
 //   node --test firestore.rules.test.cjs
 // This test uses the local emulator on 127.0.0.1:8080, NOT live Firestore.

const { test, before, after } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');

const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
} = require('firebase/firestore');

let env;

before(async () => {
  const rulesPath = path.resolve(
    __dirname,
    '..',
    'firestore.rules',
  );

  if (!fs.existsSync(rulesPath)) {
    throw new Error(
      `Missing local rules file: ${rulesPath}`,
    );
  }

  env = await initializeTestEnvironment({
    projectId: 'homeassist-fyp-2026',
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync(
        rulesPath,
        'utf8',
      ),
    },
  });

  // Only clears emulator data.
  // Never points to a live Firebase database.
  await env.clearFirestore();

  // Seed fictional test data as the emulator's
  // privileged test context.
  await env.withSecurityRulesDisabled(
    async (context) => {
      const db = context.firestore();

      await setDoc(
        doc(db, 'users', 'test-customer-a'),
        {
          role: 'customer',
          email: 'test-customer-a@example.com',
          displayName: 'Test Customer A',
          phone: '',
        },
      );

      await setDoc(
        doc(db, 'users', 'test-customer-b'),
        {
          role: 'customer',
          email: 'test-customer-b@example.com',
          displayName: 'Test Customer B',
          phone: '',
        },
      );

      await setDoc(
        doc(db, 'bookings', 'test-booking-a'),
        {
          customerId: 'test-customer-a',
          providerId: 'test-provider',
          technicianId: 'test-technician',
          status: 'pending',
        },
      );

      await setDoc(
        doc(db, 'bookings', 'test-booking-b'),
        {
          customerId: 'test-customer-b',
          providerId: 'test-provider',
          technicianId: 'test-technician',
          status: 'pending',
        },
      );
    },
  );
});

after(async () => {
  if (env) {
    await env.cleanup();
  }
});

function customerA() {
  return env.authenticatedContext(
    'test-customer-a',
    {
      email: 'test-customer-a@example.com',
      email_verified: true,
    },
  ).firestore();
}

// =====================================================
// TEST 1: CUSTOMER READS THEIR OWN PROFILE
// =====================================================

test('Customer can read their own profile', async () => {
  await assertSucceeds(
    getDoc(
      doc(
        customerA(),
        'users',
        'test-customer-a',
      ),
    ),
  );
});

// =====================================================
// TEST 2: CUSTOMER CANNOT READ ANOTHER PROFILE
// =====================================================

test('Customer cannot read another customer profile', async () => {
  await assertFails(
    getDoc(
      doc(
        customerA(),
        'users',
        'test-customer-b',
      ),
    ),
  );
});

// =====================================================
// TEST 3: CUSTOMER CANNOT BECOME ADMIN
// =====================================================

test('Customer cannot change their role to admin', async () => {
  await assertFails(
    updateDoc(
      doc(
        customerA(),
        'users',
        'test-customer-a',
      ),
      {
        role: 'admin',
      },
    ),
  );
});

// =====================================================
// TEST 4: CUSTOMER READS THEIR OWN BOOKING
// =====================================================

test('Customer can read their own booking', async () => {
  await assertSucceeds(
    getDoc(
      doc(
        customerA(),
        'bookings',
        'test-booking-a',
      ),
    ),
  );
});

// =====================================================
// TEST 5: CUSTOMER CANNOT READ ANOTHER BOOKING
// =====================================================

test('Customer cannot read another customer booking', async () => {
  await assertFails(
    getDoc(
      doc(
        customerA(),
        'bookings',
        'test-booking-b',
      ),
    ),
  );
});

// =====================================================
// TEST 6: UNAUTHENTICATED USER CANNOT READ PROFILE
// =====================================================

test('Signed-out user cannot read a customer profile', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(
    getDoc(
      doc(
        db,
        'users',
        'test-customer-a',
      ),
    ),
  );
});

 // =====================================================
 // TEST 7: CUSTOMER CAN UPDATE THEIR OWN DISPLAY NAME
 // =====================================================

test('Customer can update their own display name', async () => {
  await assertSucceeds(
    updateDoc(
      doc(
        customerA(),
        'users',
        'test-customer-a',
      ),
      {
        displayName: 'Updated Test Customer A',
      },
    ),
  );
});
