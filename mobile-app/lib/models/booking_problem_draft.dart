import 'attachment_model.dart';


class BookingProblemDraft {
  final String serviceId;
  final String serviceName;
  final String description;
  final List<AttachmentModel> photos;
  final bool isPrimary;


  const BookingProblemDraft({
    required this.serviceId,
    required this.serviceName,
    this.description = '',
    this.photos = const [],
    this.isPrimary = false,
  });


  BookingProblemDraft copyWith({
    String? serviceId,
    String? serviceName,
    String? description,
    List<AttachmentModel>? photos,
    bool? isPrimary,
  }) {
    return BookingProblemDraft(
      serviceId:
      serviceId ?? this.serviceId,

      serviceName:
      serviceName ?? this.serviceName,

      description:
      description ?? this.description,

      photos:
      photos ?? this.photos,

      isPrimary:
      isPrimary ?? this.isPrimary,
    );
  }
}