
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_enums.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      return null;
    }

    return UserModel.fromMap(doc.id, doc.data()!);
  }

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    required String phone,
    required UserRole role,
  }) {
    return _firestore.collection('users').doc(uid).set(
      {
        'email': email.trim(),
        'displayName': displayName.trim(),
        'phone': phone.trim(),
        'role': role.value,
        'providerVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // =====================================================
  // TECHNICIAN ACCOUNT ACTIVATION
  // =====================================================

  Future<UserModel> activateTechnicianProfile({
    required String uid,
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Check the currently signed-in Firebase account.
    final currentAuthUser = FirebaseAuth.instance.currentUser;

    if (currentAuthUser == null ||
        currentAuthUser.uid != uid) {
      throw StateError(
        'Please sign in with your technician account.',
      );
    }

    await currentAuthUser.reload();

    final verifiedUser = FirebaseAuth.instance.currentUser;

    if (verifiedUser == null || verifiedUser.uid != uid) {
      throw StateError(
        'Your sign-in session has expired.',
      );
    }

    if (!verifiedUser.emailVerified) {
      throw StateError(
        'Please verify your work email before continuing.',
      );
    }

    if (verifiedUser.email?.trim().toLowerCase() !=
        normalizedEmail) {
      throw StateError(
        'The verified email does not match this account.',
      );
    }

    // Refresh the token after email verification.
    await verifiedUser.getIdToken(true);

    // =================================================
    // FIND TECHNICIAN INVITATION
    // =================================================

    // Use the indexed normalized email field.
    //
    // The old workEmail fallback has been removed
    // because it requires a separate collection-group
    // index and caused the previous Firebase error.
    final snapshot = await _firestore
        .collectionGroup('technicians')
        .where(
      'workEmailNormalized',
      isEqualTo: normalizedEmail,
    )
        .limit(2)
        .get();

    if (snapshot.docs.isEmpty) {
      throw StateError(
        'No technician invitation was found '
            'for this email address.',
      );
    }

    if (snapshot.docs.length > 1) {
      throw StateError(
        'This email is linked to more than one '
            'technician record. Please contact the '
            'service provider.',
      );
    }

    final technicianRef = snapshot.docs.first.reference;

    final providerRef = technicianRef.parent.parent;

    if (providerRef == null) {
      throw StateError(
        'Unable to identify the technician provider.',
      );
    }

    final providerId = providerRef.id;
    final technicianId = technicianRef.id;

    final userRef = _firestore
        .collection('users')
        .doc(uid);

    // =================================================
    // VERIFY AND LINK ACCOUNT ATOMICALLY
    // =================================================

    await _firestore.runTransaction((transaction) async {
      // Read the current invitation and user profile.
      final latestTechnician =
      await transaction.get(technicianRef);

      final existingUser =
      await transaction.get(userRef);

      if (!latestTechnician.exists) {
        throw StateError(
          'The technician invitation no longer exists.',
        );
      }

      final data = latestTechnician.data()!;

      final invitedEmail =
      (data['workEmailNormalized'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      if (invitedEmail != normalizedEmail) {
        throw StateError(
          'The technician invitation has changed.',
        );
      }

      if (data['active'] == false) {
        throw StateError(
          'This technician account is inactive.',
        );
      }

      final existingAuthUid =
      (data['authUid'] ?? '')
          .toString()
          .trim();

      if (existingAuthUid.isNotEmpty &&
          existingAuthUid != uid) {
        throw StateError(
          'This technician account has already '
              'been activated.',
        );
      }

      // Only a pending invitation or the same
      // previously linked account can continue.
      final accountStatus =
      (data['accountStatus'] ?? 'pending')
          .toString()
          .trim()
          .toLowerCase();

      final resumingOwnAccount =
          accountStatus == 'active' &&
              existingAuthUid == uid;

      if (accountStatus != 'pending' &&
          !resumingOwnAccount) {
        throw StateError(
          'This technician invitation is not available.',
        );
      }

      // Do not overwrite an existing customer
      // or service provider account.
      if (existingUser.exists) {
        final previous = existingUser.data()!;

        if (previous['role'] !=
            UserRole.technician.value) {
          throw StateError(
            'This email already belongs to an '
                'existing HomeAssist account.',
          );
        }

        final linkedProvider =
        (previous['providerId'] ?? '').toString();

        final linkedTechnician =
        (previous['technicianId'] ?? '').toString();

        if ((linkedProvider.isNotEmpty &&
            linkedProvider != providerId) ||
            (linkedTechnician.isNotEmpty &&
                linkedTechnician != technicianId)) {
          throw StateError(
            'This HomeAssist account is already '
                'linked to another technician.',
          );
        }
      }

      final technicianName =
      (data['name'] ?? '')
          .toString()
          .trim();

      // Create or update the technician's user profile.
      transaction.set(
        userRef,
        {
          'email': normalizedEmail,
          'displayName': technicianName,
          'role': UserRole.technician.value,
          'providerId': providerId,
          'technicianId': technicianId,
          if (!existingUser.exists)
            'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Link this Firebase Authentication account
      // to the provider-created technician record.
      transaction.update(
        technicianRef,
        {
          'authUid': uid,
          'accountStatus': 'active',
          'workEmailNormalized': normalizedEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    });

    final createdUser = await getUser(uid);

    if (createdUser == null) {
      throw StateError(
        'Technician user profile could not be created.',
      );
    }

    return createdUser;
  }

  // =====================================================
  // TECHNICIAN DETAILS
  // =====================================================

  Future<Map<String, dynamic>?> getTechnicianDetails({
    required String providerId,
    required String technicianId,
  }) async {
    final technicianDoc = await _firestore
        .collection('providers')
        .doc(providerId)
        .collection('technicians')
        .doc(technicianId)
        .get();

    if (!technicianDoc.exists) {
      return null;
    }

    return {
      'id': technicianDoc.id,
      ...technicianDoc.data()!,
    };
  }

  // =====================================================
  // CUSTOMER PROFILE
  // =====================================================

  Future<void> updateCustomerProfile({
    required String uid,
    required String displayName,
    required String phone,
  }) async {
    final cleanedName = displayName.trim();
    final cleanedPhone = phone.trim();

    if (cleanedName.isEmpty) {
      throw StateError('Name cannot be empty.');
    }

    if (cleanedPhone.isNotEmpty &&
        !RegExp(r'^01\d{8,9}$').hasMatch(cleanedPhone)) {
      throw StateError(
        'Please enter a valid Malaysian mobile number.',
      );
    }

    await _firestore.collection('users').doc(uid).set(
      {
        'displayName': cleanedName,
        'phone': cleanedPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // =====================================================
  // TECHNICIAN PHONE UPDATE
  // =====================================================

  Future<void> updateTechnicianPhone({
    required String uid,
    required String providerId,
    required String technicianId,
    required String phone,
  }) async {
    final cleanedPhone = phone.trim();

    if (cleanedPhone.isNotEmpty &&
        !RegExp(r'^01\d{8,9}$').hasMatch(cleanedPhone)) {
      throw StateError(
        'Please enter a valid Malaysian mobile number.',
      );
    }

    final userReference = _firestore
        .collection('users')
        .doc(uid);

    final technicianReference = _firestore
        .collection('providers')
        .doc(providerId)
        .collection('technicians')
        .doc(technicianId);

    final batch = _firestore.batch();

    batch.set(
      userReference,
      {
        'phone': cleanedPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.update(
      technicianReference,
      {
        'phone': cleanedPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }
}
