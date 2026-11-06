
import 'package:flutter/foundation.dart';

import '../models/appointment_slot.dart';
import '../models/attachment_model.dart';
import '../models/booking_draft.dart';
import '../models/booking_model.dart';
import '../models/booking_problem_draft.dart';
import '../models/provider_models.dart';
import '../models/service_models.dart';
import '../services/app_services.dart';
import 'base_viewmodel.dart';

class CustomerBookingViewModel extends BaseViewModel {
  BookingDraft _draft = const BookingDraft();

  List<ServiceItemModel> _categoryServices = [];
  List<ServiceItemModel> _selectedServices = [];
  List<ProviderMatch> _providerMatches = [];
  List<AppointmentSlot> _availableSlots = [];

  // Prevent results of an older provider/availability request from
  // replacing results for a newer service, location or provider selection.
  int _selectionRevision = 0;

  // Optional sequential booking mode: only used when the customer chooses
  // to book selected services with different providers. Ordinary combined
  // and single-service bookings keep their existing behavior.
  final List<BookingDraft> _remainingSeparateDrafts = [];
  int _separateTotal = 0;
  int _separateProcessed = 0;
  int _separateSubmitted = 0;
  String? _lastSubmittedBookingId;

  bool get isSeparateBookingFlow => _separateTotal > 0;

  bool get canBookServicesSeparately =>
      !isSeparateBookingFlow && _draft.serviceIds.length > 1;

  int get separateBookingTotal => _separateTotal;

  int get separateBookingPosition =>
      isSeparateBookingFlow ? _separateProcessed + 1 : 0;

  int get separateBookingsSubmitted => _separateSubmitted;

  int get remainingSeparateBookings => _remainingSeparateDrafts.length;

  String? get lastSubmittedBookingId => _lastSubmittedBookingId;

  String get currentSeparateServiceName {
    if (_selectedServices.isNotEmpty) return _selectedServices.first.name;
    if (_draft.serviceIds.isEmpty) return 'this service';
    return _formatServiceName(_draft.serviceIds.first);
  }

  String _formatServiceName(String id) => id.split('_').map((word) {
    if (word.isEmpty) return word;
    return '${word[0].toUpperCase()}${word.substring(1)}';
  }).join(' ');

  void _clearSeparateFlow() {
    _remainingSeparateDrafts.clear();
    _separateTotal = 0;
    _separateProcessed = 0;
    _separateSubmitted = 0;
  }

  BookingDraft get draft => _draft;

  List<ServiceItemModel> get categoryServices =>
      List.unmodifiable(_categoryServices);

  List<ServiceItemModel> get selectedServices =>
      List.unmodifiable(_selectedServices);

  List<ProviderMatch> get providerMatches =>
      List.unmodifiable(_providerMatches);

  List<AppointmentSlot> get availableSlots =>
      List.unmodifiable(_availableSlots);

  void startCategory(String categoryId) {
    _clearSeparateFlow();
    _lastSubmittedBookingId = null;
    _selectionRevision++;

    _draft = BookingDraft(categoryId: categoryId);
    _categoryServices = [];
    _selectedServices = [];
    _providerMatches = [];
    _availableSlots = [];

    clearError();
    notifyListeners();
  }

  Future<void> loadCategoryServices() async {
    final id = _draft.categoryId;
    if (id == null) return;

    final revision = _selectionRevision;

    setLoading(true);
    clearError();

    try {
      final services =
      await AppServices.catalog.getServicesByCategory(id);

      if (revision != _selectionRevision || _draft.categoryId != id) {
        return;
      }

      _categoryServices = services;

      _selectedServices = _categoryServices
          .where((service) => _draft.serviceIds.contains(service.id))
          .toList();

      notifyListeners();
    } catch (e) {
      if (revision == _selectionRevision) {
        setError('Unable to load services: $e');
      }
    } finally {
      setLoading(false);
    }
  }

  // IMPORTANT: BookingDraft.copyWith() does not clear nullable values when
  // null is passed in. Rebuild the draft when services change so that old
  // providers, appointment slots and legacy problem fields are truly cleared.
  void toggleService(ServiceItemModel s) {
    // A manual selection change invalidates an unfinished split plan.
    if (isSeparateBookingFlow) {
      _clearSeparateFlow();
    }

    final ids = List<String>.from(_draft.serviceIds);

    if (ids.contains(s.id)) {
      ids.remove(s.id);
    } else {
      if (ids.length >= 3) {
        setError('You can select up to 3 services.');
        return;
      }

      if (s.categoryId != _draft.categoryId) {
        setError('All selected services must be from the same category.');
        return;
      }

      ids.add(s.id);
    }

    final previousDraft = _draft;

    _selectedServices = _categoryServices
        .where((service) => ids.contains(service.id))
        .toList();

    // Preserve descriptions/photos for services that remain selected.
    // An 'Other / Not sure' explanation can also be retained when the
    // user only adds a service. If a service is removed/replaced, that
    // explanation is cleared to avoid carrying over the old problem.
    final removedAnOldService = previousDraft.serviceIds.any(
          (id) => !ids.contains(id),
    );

    final retained = previousDraft.problemDetails
        .where(
          (problem) =>
      ids.contains(problem.serviceId) ||
          (!removedAnOldService &&
              problem.serviceId == 'other_not_sure'),
    )
        .toList();

    // Ensure that exactly the first retained problem is the primary one.
    final retainedProblems = <BookingProblemDraft>[
      for (var i = 0; i < retained.length; i++)
        BookingProblemDraft(
          serviceId: retained[i].serviceId,
          serviceName: retained[i].serviceName,
          description: retained[i].description,
          photos: List<AttachmentModel>.from(retained[i].photos),
          isPrimary: i == 0,
        ),
    ];

    final primary =
    retainedProblems.isEmpty ? null : retainedProblems.first;

    _draft = BookingDraft(
      categoryId: previousDraft.categoryId,
      serviceIds: ids,
      primaryIssue: primary?.serviceName,
      problemDescription: primary?.description ?? '',
      photos: retainedProblems
          .expand((problem) => problem.photos)
          .toList(),
      problemDetails: retainedProblems,
      gasBrandPreference: _selectedServices.any(
            (service) => service.supportsBrandPreference,
      )
          ? previousDraft.gasBrandPreference
          : null,

      // Preserve the customer's address if they navigate backwards.
      address: previousDraft.address,
      latitude: previousDraft.latitude,
      longitude: previousDraft.longitude,

      // Deliberately omit providerMatch and appointmentSlot: both must
      // be chosen again for the new combination of services.
    );

    _providerMatches = [];
    _availableSlots = [];
    _selectionRevision++;

    clearError();
    notifyListeners();
  }

  Future<bool> startFromSuggestedService({
    required ServiceItemModel service,
    required String description,
  }) async {
    startCategory(service.categoryId);
    await loadCategoryServices();

    if (errorMessage != null) {
      return false;
    }

    final matches = _categoryServices.where(
          (item) => item.id == service.id,
    );

    if (matches.isEmpty) {
      setError('Unable to load the suggested service.');
      return false;
    }

    final selectedService = matches.first;
    toggleService(selectedService);

    if (!_draft.serviceIds.contains(selectedService.id)) {
      return false;
    }

    setProblemDetailsByProblem(
      problemDetails: [
        BookingProblemDraft(
          serviceId: selectedService.id,
          serviceName: selectedService.name,
          description: description.trim(),
          photos: const [],
          isPrimary: true,
        ),
      ],
    );

    return true;
  }

  // Legacy entry point, retained for compatibility with older screens.
  void setProblemDetails({
    String? primaryIssue,
    required String description,
    required List<AttachmentModel> photos,
    String? gasBrandPreference,
  }) {
    _draft = _draft.copyWith(
      primaryIssue: primaryIssue,
      problemDescription: description.trim(),
      photos: photos,
      gasBrandPreference: gasBrandPreference,
    );

    notifyListeners();
  }

  void setProblemDetailsByProblem({
    required List<BookingProblemDraft> problemDetails,
    String? gasBrandPreference,
  }) {
    if (problemDetails.isEmpty) {
      setError('At least one problem is required.');
      return;
    }

    final allowedIds = _draft.serviceIds.toSet();

    final invalidProblem = problemDetails.any(
          (problem) =>
      problem.serviceId != 'other_not_sure' &&
          !allowedIds.contains(problem.serviceId),
    );

    if (invalidProblem) {
      setError(
        'One of the problems is no longer part of the selected services.',
      );
      return;
    }

    final cleanedProblems = problemDetails
        .map(
          (problem) => problem.copyWith(
        description: problem.description.trim(),
      ),
    )
        .toList();

    final primaryProblem = cleanedProblems.firstWhere(
          (problem) => problem.isPrimary,
      orElse: () => cleanedProblems.first,
    );

    final allPhotos = cleanedProblems
        .expand((problem) => problem.photos)
        .toList();

    _draft = _draft.copyWith(
      primaryIssue: primaryProblem.serviceName,

      // Keep legacy fields populated for older parts of the app.
      problemDescription: primaryProblem.description,
      photos: allPhotos,

      // New structure stores separate details for each problem.
      problemDetails: cleanedProblems,
      gasBrandPreference: gasBrandPreference,
    );

    clearError();
    notifyListeners();
  }

  Future<void> useCurrentLocation() async {
    setLoading(true);
    clearError();

    try {
      final result =
      await AppServices.location.getCurrentLocation();

      setLocation(
        address: result.address,
        latitude: result.latitude,
        longitude: result.longitude,
      );
    } catch (e) {
      setError('Unable to get current location: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<bool> setAddressAndGeocode(String address) async {
    setLoading(true);
    clearError();

    try {
      final result =
      await AppServices.location.geocodeAddress(address);

      setLocation(
        address: result.address,
        latitude: result.latitude,
        longitude: result.longitude,
      );

      return true;
    } catch (e) {
      setError('Unable to find that location: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  void setLocation({
    required String address,
    required double latitude,
    required double longitude,
  }) {
    final trimmedAddress = address.trim();

    final locationChanged =
        _draft.address != trimmedAddress ||
            _draft.latitude != latitude ||
            _draft.longitude != longitude;

    if (!locationChanged) return;

    final previousDraft = _draft;

    // A changed address invalidates provider matching and the chosen slot.
    _draft = BookingDraft(
      categoryId: previousDraft.categoryId,
      serviceIds: previousDraft.serviceIds,
      primaryIssue: previousDraft.primaryIssue,
      problemDescription: previousDraft.problemDescription,
      photos: previousDraft.photos,
      problemDetails: previousDraft.problemDetails,
      gasBrandPreference: previousDraft.gasBrandPreference,
      address: trimmedAddress,
      latitude: latitude,
      longitude: longitude,

      // providerMatch and appointmentSlot intentionally cleared.
    );

    _providerMatches = [];
    _availableSlots = [];
    _selectionRevision++;

    notifyListeners();
  }

  Future<void> findProviders() async {
    if (_draft.latitude == null || _draft.longitude == null) return;

    final revision = _selectionRevision;
    final ids = List<String>.from(_draft.serviceIds);
    final latitude = _draft.latitude!;
    final longitude = _draft.longitude!;

    setLoading(true);
    clearError();

    try {
      final matches =
      await AppServices.provider.findNearbyProviders(
        serviceIds: ids,
        customerLatitude: latitude,
        customerLongitude: longitude,
      );

      if (revision != _selectionRevision) return;

      _providerMatches = matches;
      notifyListeners();
    } catch (e) {
      if (revision == _selectionRevision) {
        setError('Unable to find providers: $e');
      }
    } finally {
      setLoading(false);
    }
  }

  // =====================================================
  // SEQUENTIAL MULTI-SERVICE BOOKING
  // =====================================================

  /// Prepare separate drafts from the existing (same-category) service
  /// selection. The first entry is the customer's primary problem when it
  /// points to a selected service. All other selected services stay queued.
  /// No Firestore documents are created until each booking is confirmed.
  bool startSeparateBookings() {
    if (!canBookServicesSeparately || isLoading) return false;

    if (_draft.latitude == null || _draft.longitude == null) {
      setError('Please choose a service location first.');
      return false;
    }

    final original = _draft;
    final selectedIds = List<String>.from(original.serviceIds);

    final primary = original.problemDetails.where(
          (problem) =>
      problem.isPrimary &&
          selectedIds.contains(problem.serviceId),
    );

    if (primary.isNotEmpty) {
      final firstId = primary.first.serviceId;
      selectedIds.remove(firstId);
      selectedIds.insert(0, firstId);
    }

    final drafts = <BookingDraft>[
      for (var i = 0; i < selectedIds.length; i++)
        _singleServiceDraft(
          original: original,
          serviceId: selectedIds[i],
          includeOtherIssue: i == 0,
        ),
    ];

    if (drafts.length < 2) return false;

    _remainingSeparateDrafts
      ..clear()
      ..addAll(drafts.skip(1));

    _separateTotal = drafts.length;
    _separateProcessed = 0;
    _separateSubmitted = 0;
    _lastSubmittedBookingId = null;

    _activateSeparateDraft(drafts.first);

    return true;
  }

  BookingDraft _singleServiceDraft({
    required BookingDraft original,
    required String serviceId,
    required bool includeOtherIssue,
  }) {
    final matching = original.problemDetails.where(
          (problem) =>
      problem.serviceId == serviceId ||
          (includeOtherIssue &&
              problem.serviceId == 'other_not_sure'),
    ).toList();

    // A service may have been selected without adding an optional second
    // problem section. It must still be included in the booking plan.
    if (!matching.any((problem) => problem.serviceId == serviceId)) {
      final service =
      _categoryServices.where((s) => s.id == serviceId);

      matching.add(
        BookingProblemDraft(
          serviceId: serviceId,
          serviceName: service.isEmpty
              ? _formatServiceName(serviceId)
              : service.first.name,
          description: '',
          photos: const [],
          isPrimary: matching.isEmpty,
        ),
      );
    }

    // Preserve the chosen primary problem when it is part of this group.
    final primaryIndex =
    matching.indexWhere((problem) => problem.isPrimary);

    final ordered = <BookingProblemDraft>[
      if (primaryIndex >= 0) matching[primaryIndex],
      ...matching.where(
            (problem) =>
        primaryIndex < 0 ||
            !identical(problem, matching[primaryIndex]),
      ),
    ];

    final normalized = <BookingProblemDraft>[
      for (var i = 0; i < ordered.length; i++)
        BookingProblemDraft(
          serviceId: ordered[i].serviceId,
          serviceName: ordered[i].serviceName,
          description: ordered[i].description,
          photos: List<AttachmentModel>.from(ordered[i].photos),
          isPrimary: i == 0,
        ),
    ];

    final service =
    _categoryServices.where((s) => s.id == serviceId);

    final supportsBrand =
        service.isNotEmpty &&
            service.first.supportsBrandPreference;

    return BookingDraft(
      categoryId: original.categoryId,
      serviceIds: [serviceId],
      primaryIssue: normalized.first.serviceName,
      problemDescription: normalized.first.description,
      photos: normalized
          .expand((problem) => problem.photos)
          .toList(),
      problemDetails: normalized,
      gasBrandPreference:
      supportsBrand ? original.gasBrandPreference : null,
      address: original.address,
      latitude: original.latitude,
      longitude: original.longitude,

      // Provider and appointment must always be selected for this booking.
    );
  }

  void _activateSeparateDraft(BookingDraft next) {
    _draft = next;

    _selectedServices = _categoryServices
        .where((service) => next.serviceIds.contains(service.id))
        .toList();

    _providerMatches = [];
    _availableSlots = [];
    _selectionRevision++;

    clearError();
    notifyListeners();
  }

  /// Call ONLY after submitBooking() returns a non-null saved booking.
  /// Returns true if the customer should choose a provider for another
  /// problem. A failed submission must leave the queue untouched.
  bool prepareNextAfterSuccessfulBooking(String bookingId) {
    _lastSubmittedBookingId = bookingId;

    if (!isSeparateBookingFlow) return false;

    _separateSubmitted++;
    _separateProcessed++;

    if (_remainingSeparateDrafts.isEmpty) {
      _clearSeparateFlow();
      notifyListeners();
      return false;
    }

    final next = _remainingSeparateDrafts.removeAt(0);
    _activateSeparateDraft(next);

    return true;
  }

  /// Called only when the customer explicitly skips a service for which no
  /// provider was found. Skipping never creates a booking silently.
  bool skipUnavailableSeparateService() {
    if (!isSeparateBookingFlow || isLoading) return false;

    _separateProcessed++;

    if (_remainingSeparateDrafts.isEmpty) {
      _clearSeparateFlow();
      notifyListeners();
      return false;
    }

    final next = _remainingSeparateDrafts.removeAt(0);
    _activateSeparateDraft(next);

    return true;
  }

  // =====================================================
  // PROVIDER AND APPOINTMENT SELECTION
  // =====================================================

  void selectProvider(ProviderMatch match) {
    final previous = _draft.providerMatch;

    final providerChanged =
        previous == null ||
            previous.provider.id != match.provider.id ||
            previous.branch.id != match.branch.id;

    if (providerChanged) {
      final previousDraft = _draft;

      _draft = BookingDraft(
        categoryId: previousDraft.categoryId,
        serviceIds: previousDraft.serviceIds,
        primaryIssue: previousDraft.primaryIssue,
        problemDescription: previousDraft.problemDescription,
        photos: previousDraft.photos,
        problemDetails: previousDraft.problemDetails,
        gasBrandPreference: previousDraft.gasBrandPreference,
        address: previousDraft.address,
        latitude: previousDraft.latitude,
        longitude: previousDraft.longitude,
        providerMatch: match,

        // Do not keep an appointment slot from another provider or branch.
      );

      _selectionRevision++;
    } else {
      _draft = _draft.copyWith(providerMatch: match);
    }

    _availableSlots = [];
    notifyListeners();
  }

  Future<void> loadAvailableSlots(DateTime date) async {
    final match = _draft.providerMatch;
    if (match == null) return;

    final revision = _selectionRevision;
    final ids = List<String>.from(_draft.serviceIds);

    setLoading(true);
    clearError();

    try {
      final slots =
      await AppServices.availability.getAvailableSlots(
        providerId: match.provider.id,
        branchId: match.branch.id,
        serviceIds: ids,
        date: date,
      );

      if (revision != _selectionRevision) return;

      _availableSlots = slots;
      notifyListeners();
    } catch (e, stackTrace) {
      if (revision == _selectionRevision) {
        debugPrint('AVAILABILITY ERROR: $e');
        debugPrintStack(stackTrace: stackTrace);

        setError('Unable to load availability: $e');
      }
    } finally {
      setLoading(false);
    }
  }

  void selectAppointmentSlot(AppointmentSlot slot) {
    _draft = _draft.copyWith(appointmentSlot: slot);
    notifyListeners();
  }

  // =====================================================
  // BOOKING SUBMISSION
  // =====================================================

  Future<BookingModel?> submitBooking() async {
    final uid = AppServices.auth.currentUserId;

    if (uid == null) {
      setError('Please sign in before booking.');
      return null;
    }

    setLoading(true);
    clearError();

    try {
      final id = AppServices.booking.createBookingId();

      final problemPhotoUrls =
      await AppServices.storage.uploadBookingProblemPhotos(
        bookingId: id,
        problems: _draft.problemDetails,
      );

      // Keep a combined list for compatibility with existing screens.
      final allPhotoUrls = problemPhotoUrls.values
          .expand((urls) => urls)
          .toList();

      return await AppServices.booking.createBooking(
        bookingId: id,
        customerId: uid,
        draft: _draft,
        photoUrls: allPhotoUrls,
        problemPhotoUrls: problemPhotoUrls,
      );
    } catch (e) {
      setError('Unable to submit booking: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }
}
