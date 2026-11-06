import 'appointment_slot.dart';
import 'attachment_model.dart';
import 'booking_problem_draft.dart';
import 'provider_models.dart';


class BookingDraft {
  final String? categoryId;

  final List<String> serviceIds;

  // Kept for compatibility with the existing booking flow.
  final String? primaryIssue;

  final String problemDescription;

  final List<AttachmentModel> photos;

  // New:
  // Each selected problem can now have its own
  // description and photos.
  final List<BookingProblemDraft> problemDetails;

  final String? gasBrandPreference;

  final String address;

  final double? latitude;

  final double? longitude;

  final ProviderMatch? providerMatch;

  final AppointmentSlot? appointmentSlot;


  const BookingDraft({
    this.categoryId,
    this.serviceIds = const [],
    this.primaryIssue,
    this.problemDescription = '',
    this.photos = const [],
    this.problemDetails = const [],
    this.gasBrandPreference,
    this.address = '',
    this.latitude,
    this.longitude,
    this.providerMatch,
    this.appointmentSlot,
  });


  BookingDraft copyWith({
    String? categoryId,
    List<String>? serviceIds,
    String? primaryIssue,
    String? problemDescription,
    List<AttachmentModel>? photos,
    List<BookingProblemDraft>? problemDetails,
    String? gasBrandPreference,
    String? address,
    double? latitude,
    double? longitude,
    ProviderMatch? providerMatch,
    AppointmentSlot? appointmentSlot,
  }) {
    return BookingDraft(
      categoryId:
      categoryId ?? this.categoryId,

      serviceIds:
      serviceIds ?? this.serviceIds,

      primaryIssue:
      primaryIssue ?? this.primaryIssue,

      problemDescription:
      problemDescription ??
          this.problemDescription,

      photos:
      photos ?? this.photos,

      problemDetails:
      problemDetails ??
          this.problemDetails,

      gasBrandPreference:
      gasBrandPreference ??
          this.gasBrandPreference,

      address:
      address ?? this.address,

      latitude:
      latitude ?? this.latitude,

      longitude:
      longitude ?? this.longitude,

      providerMatch:
      providerMatch ??
          this.providerMatch,

      appointmentSlot:
      appointmentSlot ??
          this.appointmentSlot,
    );
  }
}