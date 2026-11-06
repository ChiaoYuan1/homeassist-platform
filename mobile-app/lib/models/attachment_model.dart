import 'dart:typed_data';

class AttachmentModel {
  final String name;
  final Uint8List bytes;
  final String? mimeType;
  const AttachmentModel({required this.name, required this.bytes, this.mimeType});
}
