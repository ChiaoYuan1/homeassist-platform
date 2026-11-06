import {
  doc,
  getDoc,
} from 'firebase/firestore';

import {
  db,
} from '../firebase.js';


async function getUserById(uid) {
  if (!uid) {
    return null;
  }

  const userReference =
    doc(
      db,
      'users',
      uid,
    );

  const snapshot =
    await getDoc(
      userReference,
    );

  if (!snapshot.exists()) {
    return null;
  }

  return {
    id: snapshot.id,
    ...snapshot.data(),
  };
}


export {
  getUserById,
};