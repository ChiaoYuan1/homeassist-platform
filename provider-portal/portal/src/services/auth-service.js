
import {
  browserLocalPersistence,
  browserSessionPersistence,
  createUserWithEmailAndPassword,
  reload,
  sendEmailVerification,
  updateProfile,
  setPersistence,
  signInWithEmailAndPassword,
  signOut,
} from 'firebase/auth';

import {
  httpsCallable,
} from 'firebase/functions';

import {
  auth,
  functions,
} from '../firebase';

const initializeProviderProfileFunction =
  httpsCallable(
    functions,
    'initializeProviderProfile',
  );

const requestPasswordResetFunction =
  httpsCallable(
    functions,
    'requestPasswordReset',
  );

async function signIn(
  email,
  password,
  rememberMe = false,
) {
  await setPersistence(
    auth,
    rememberMe
      ? browserLocalPersistence
      : browserSessionPersistence,
  );

  const userCredential =
    await signInWithEmailAndPassword(
      auth,
      email.trim(),
      password,
    );

  return userCredential.user;
}

async function requestPasswordReset(email) {
  const result =
    await requestPasswordResetFunction({
      email: email.trim(),
    });

  return result.data;
}

async function logOut() {
  await signOut(auth);
}

// =========================
// PROVIDER ACCOUNT CREATION
// =========================

async function finishProviderAccountSetup(
  displayName,
) {
  const user = auth.currentUser;

  if (!user) {
    throw new Error(
      'Please sign in before continuing registration.',
    );
  }

  const cleanName = displayName.trim();

  if (
    cleanName.length < 2 ||
    cleanName.length > 80
  ) {
    throw new Error(
      'Enter a name between 2 and 80 characters.',
    );
  }

  await updateProfile(
    user,
    {
      displayName: cleanName,
    },
  );

  await initializeProviderProfileFunction({
    displayName: cleanName,
  });

  return user;
}

async function createProviderAccount({
  displayName,
  email,
  password,
}) {
  const cleanEmail =
    email.trim().toLowerCase();

  await setPersistence(
    auth,
    browserSessionPersistence,
  );

  await createUserWithEmailAndPassword(
    auth,
    cleanEmail,
    password,
  );

  return finishProviderAccountSetup(
    displayName,
  );
}

// =========================
// EMAIL VERIFICATION
// =========================

async function sendProviderVerificationEmail() {
  const user = auth.currentUser;

  if (!user) {
    throw new Error(
      'Please sign in to send a verification email.',
    );
  }

  await reload(user);

  if (!user.emailVerified) {
    await sendEmailVerification(user);
  }
}

async function checkProviderEmailVerified() {
  const user = auth.currentUser;

  if (!user) {
    throw new Error(
      'Please sign in to verify your email.',
    );
  }

  await reload(user);

  return user.emailVerified;
}

export {
  signIn,
  requestPasswordReset,
  logOut,
  createProviderAccount,
  finishProviderAccountSetup,
  sendProviderVerificationEmail,
  checkProviderEmailVerified,
};
