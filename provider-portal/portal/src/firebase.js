import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getAnalytics } from 'firebase/analytics';
import { getFunctions } from 'firebase/functions';
import {connectFunctionsEmulator} from 'firebase/functions';
import { getStorage, connectStorageEmulator} from 'firebase/storage';

const firebaseConfig = {
  apiKey: 'AIzaSyBMp6AliXqmbIALzsDYzbk_Mct4foVwa_M',
  authDomain: 'homeassist-fyp-2026.firebaseapp.com',
  projectId: 'homeassist-fyp-2026',
  storageBucket: 'homeassist-fyp-2026.firebasestorage.app',
  messagingSenderId: '585275499836',
  appId: '1:585275499836:web:e457046480b8d986f92a39',
  measurementId: "G-E641LDZ0PC"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
const storage = getStorage(app);

// Firebase Authentication
const auth = getAuth(app);

// Cloud Firestore
const db = getFirestore(app);
const functions = (
  getFunctions(
    app,
    'asia-southeast1',
  )
);

//Local Testing
if (window.location.hostname === 'localhost') {
  connectFunctionsEmulator(
    functions,
    '127.0.0.1',
    5001,
  );
  // connectStorageEmulator(
  //   storage,
  //   '127.0.0.1',
  //   9199
  // );
}

export {
  app,
  analytics,
  auth,
  db,
  functions,
  storage
};