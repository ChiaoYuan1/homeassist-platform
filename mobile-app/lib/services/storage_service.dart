
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attachment_model.dart';
import '../models/provider_application_model.dart';
import '../models/booking_problem_draft.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // ============================================
  // SUPABASE - CUSTOMER BOOKING PHOTOS
  // ============================================

  static const String _bookingBucket = 'booking-photos';
  static const int _maxImageBytes = 10 * 1024 * 1024;

  // Temporary signed URLs valid for 7 days.
  static const int _signedUrlSeconds = 7 * 24 * 60 * 60;

  Future<String> _getCustomerUid() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError(
        'Please sign in before uploading booking photos.',
      );
    }

    // Refresh the token to obtain the latest custom claims.
    final tokenResult = await user.getIdTokenResult(true);

    if (tokenResult.claims?['role'] != 'authenticated') {
      throw StateError(
        'Supabase authentication claim is missing. '
            'Please verify your Firebase account configuration.',
      );
    }

    return user.uid;
  }

  String _safePathPart(String value) {
    return value.replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
  }

  String _getContentType(AttachmentModel photo) {
    final mime = photo.mimeType
        ?.toLowerCase()
        .split(';')
        .first
        .trim();

    if (mime == 'image/jpeg' ||
        mime == 'image/png' ||
        mime == 'image/webp') {
      return mime!;
    }

    final name = photo.name.toLowerCase();

    if (name.endsWith('.jpg') ||
        name.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    if (name.endsWith('.png')) {
      return 'image/png';
    }

    if (name.endsWith('.webp')) {
      return 'image/webp';
    }

    throw StateError(
      'Only JPG, PNG and WebP images are supported.',
    );
  }

  String _getExtension(String contentType) {
    switch (contentType) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      default:
        return 'jpg';
    }
  }

  Future<String> _uploadToSupabase({
    required String uid,
    required String bookingId,
    required AttachmentModel photo,
    required int index,
    String? serviceId,
  }) async {
    if (photo.bytes.isEmpty) {
      throw StateError('The selected photo is empty.');
    }

    if (photo.bytes.length > _maxImageBytes) {
      throw StateError(
        'Each booking photo must be 10 MB or smaller.',
      );
    }

    final contentType = _getContentType(photo);
    final extension = _getExtension(contentType);

    // The first folder must match the Firebase UID,
    // as required by our Supabase RLS policies.
    final parts = <String>[
      uid,
      _safePathPart(bookingId),
      if (serviceId != null) _safePathPart(serviceId),
      '${DateTime.now().microsecondsSinceEpoch}'
          '_$index.$extension',
    ];

    final objectPath = parts.join('/');

    final bucket = Supabase.instance.client.storage
        .from(_bookingBucket);

    // Upload to the private Supabase Storage bucket.
    await bucket.uploadBinary(
      objectPath,
      photo.bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: false,
      ),
    );

    // Generate a temporary URL for existing
    // customer and provider image interfaces.
    final signedUrl = await bucket.createSignedUrl(
      objectPath,
      _signedUrlSeconds,
    );

    return signedUrl;
  }

  // ============================================
  // UPLOAD BOOKING PHOTOS
  // ============================================

  Future<List<String>> uploadBookingPhotos({
    required String bookingId,
    required List<AttachmentModel> photos,
  }) async {
    final urls = <String>[];

    if (photos.isEmpty) {
      return urls;
    }

    final uid = await _getCustomerUid();

    for (var i = 0; i < photos.length; i++) {
      final signedUrl = await _uploadToSupabase(
        uid: uid,
        bookingId: bookingId,
        photo: photos[i],
        index: i,
      );

      urls.add(signedUrl);
    }

    return urls;
  }

  // ============================================
  // UPLOAD BOOKING PROBLEM PHOTOS
  // ============================================

  Future<Map<String, List<String>>> uploadBookingProblemPhotos({
    required String bookingId,
    required List<BookingProblemDraft> problems,
  }) async {
    final result = <String, List<String>>{};
    String? uid;

    for (final problem in problems) {
      final urls = <String>[];

      if (problem.photos.isNotEmpty) {
        uid ??= await _getCustomerUid();
      }

      for (var i = 0; i < problem.photos.length; i++) {
        final photo = problem.photos[i];

        final signedUrl = await _uploadToSupabase(
          uid: uid!,
          bookingId: bookingId,
          serviceId: problem.serviceId,
          photo: photo,
          index: i,
        );

        urls.add(signedUrl);
      }

      result[problem.serviceId] = urls;
    }

    return result;
  }

  // ============================================
  // PROVIDER VERIFICATION DOCUMENTS
  // EXISTING FIREBASE STORAGE IMPLEMENTATION
  // ============================================

  Future<List<ApplicationDocumentModel>> uploadProviderDocuments({
    required String applicationId,
    required List<PendingVerificationDocument> documents,
  }) async {
    final result = <ApplicationDocumentModel>[];

    for (var i = 0; i < documents.length; i++) {
      final document = documents[i];

      final ref = _storage.ref(
        'provider_applications/$applicationId/'
            '${DateTime.now().microsecondsSinceEpoch}_${i}_'
            '${document.attachment.name}',
      );

      final task = await ref.putData(
        document.attachment.bytes,
        document.attachment.mimeType == null
            ? null
            : SettableMetadata(
          contentType: document.attachment.mimeType,
        ),
      );

      result.add(
        ApplicationDocumentModel(
          label: document.label,
          authority: document.authority,
          documentType: document.documentType,
          serviceCategoryId: document.serviceCategoryId,
          fileName: document.attachment.name,
          downloadUrl: await task.ref.getDownloadURL(),
          registrationNumber: document.registrationNumber,
          expiryDate: document.expiryDate,
        ),
      );
    }

    return result;
  }
}
