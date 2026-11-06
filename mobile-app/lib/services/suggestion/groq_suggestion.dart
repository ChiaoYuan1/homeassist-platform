import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/service_models.dart';
import 'service_suggestion.dart';

class GroqServiceSuggestionService
    implements ServiceSuggestionService {
  final Uri endpoint;
  final ServiceSuggestionService fallback;
  final http.Client _client;

  GroqServiceSuggestionService({
    required String endpoint,
    required this.fallback,
    http.Client? client,
  })  : endpoint = Uri.parse(endpoint),
        _client = client ?? http.Client();

  @override
  Future<ServiceSuggestionResult> suggestServiceIds({
    required String description,
    required List<ServiceItemModel> availableServices,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    final cleanDescription =
    description.trim();

    final hasImageBytes =
        imageBytes != null &&
            imageBytes.isNotEmpty;

    final hasImageMimeType =
        imageMimeType != null &&
            imageMimeType.trim().isNotEmpty;

    final hasImage =
        hasImageBytes &&
            hasImageMimeType;

    if ((cleanDescription.isEmpty && !hasImageBytes) ||
        availableServices.isEmpty) {
      return const ServiceSuggestionResult.empty();
    }

    // Image bytes exist but no MIME type was provided.
    // Qwen Worker requires both, so use Gemini fallback.
    if (hasImageBytes && !hasImageMimeType) {
      debugPrint(
        'QWEN WORKER: Image MIME type missing. '
            'Using fallback AI.',
      );

      return _useFallback(
        description: description,
        availableServices: availableServices,
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
      );
    }

    try {
      if (hasImage) {
        debugPrint(
          'SERVICE ASSISTANT REQUEST: '
              'Qwen Vision via Groq',
        );
      } else {
        debugPrint(
          'SERVICE ASSISTANT REQUEST: '
              'Qwen via Groq',
        );
      }

      final requestBody =
      <String, dynamic>{
        'description': cleanDescription,
      };

      if (hasImage) {
        requestBody['imageBase64'] =
            base64Encode(
              imageBytes,
            );

        requestBody['imageMimeType'] =
            imageMimeType.trim();
      }

      final response = await _client
          .post(
        endpoint,
        headers: {
          'Content-Type':
          'application/json',
        },
        body: jsonEncode(
          requestBody,
        ),
      )
          .timeout(
        Duration(
          seconds:
          hasImage ? 30 : 20,
        ),
      );

      debugPrint(
        'QWEN WORKER STATUS: '
            '${response.statusCode}',
      );

      debugPrint(
        'QWEN RAW RESPONSE: '
            '${response.body}',
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        debugPrint(
          'QWEN WORKER FAILED. '
              'Using fallback AI.',
        );

        return _useFallback(
          description: description,
          availableServices:
          availableServices,
          imageBytes: imageBytes,
          imageMimeType:
          imageMimeType,
        );
      }

      final decoded =
      jsonDecode(
        response.body,
      );

      if (decoded is! Map<String, dynamic>) {
        debugPrint(
          'QWEN RESPONSE WAS NOT '
              'A VALID JSON OBJECT.',
        );

        return _useFallback(
          description: description,
          availableServices:
          availableServices,
          imageBytes: imageBytes,
          imageMimeType:
          imageMimeType,
        );
      }

      final validIds =
      availableServices
          .map(
            (service) =>
        service.id,
      )
          .toSet();

      final serviceIds =
      <String>[];

      final rawIds =
      decoded['serviceIds'];

      if (rawIds is List) {
        for (final rawId in rawIds) {
          if (rawId is! String) {
            continue;
          }

          final id =
          rawId.trim();

          if (!validIds.contains(id)) {
            continue;
          }

          if (serviceIds.contains(id)) {
            continue;
          }

          serviceIds.add(id);

          if (serviceIds.length == 3) {
            break;
          }
        }
      }

      final needsClarification =
          decoded[
          'needsClarification'] ==
              true;

      final noSuitableService =
          decoded[
          'noSuitableService'] ==
              true;

      final rawQuestion =
      decoded[
      'clarificationQuestion'];

      String? clarificationQuestion;

      if (rawQuestion is String &&
          rawQuestion
              .trim()
              .isNotEmpty) {
        clarificationQuestion =
            rawQuestion.trim();
      }

      // =====================================================
      // NO SUITABLE SERVICE
      // =====================================================

      if (noSuitableService) {
        debugPrint(
          hasImage
              ? 'SERVICE ASSISTANT SOURCE: '
              'Qwen Vision/Groq'
              : 'SERVICE ASSISTANT SOURCE: '
              'Qwen/Groq',
        );

        return const ServiceSuggestionResult(
          serviceIds: [],
          needsClarification: false,
          clarificationQuestion: null,
          noSuitableService: true,
          source:
          ServiceSuggestionSource
              .groqQwen,
        );
      }

      // =====================================================
      // CLARIFICATION
      // =====================================================

      if (needsClarification) {
        debugPrint(
          hasImage
              ? 'SERVICE ASSISTANT SOURCE: '
              'Qwen Vision/Groq'
              : 'SERVICE ASSISTANT SOURCE: '
              'Qwen/Groq',
        );

        return ServiceSuggestionResult(
          serviceIds: const [],
          needsClarification: true,
          clarificationQuestion:
          clarificationQuestion ??
              'Could you provide a little more detail about the problem?',
          noSuitableService: false,
          source:
          ServiceSuggestionSource
              .groqQwen,
        );
      }

      // =====================================================
      // NORMAL RECOMMENDATION
      // =====================================================

      if (serviceIds.isNotEmpty) {
        debugPrint(
          hasImage
              ? 'SERVICE ASSISTANT SOURCE: '
              'Qwen Vision/Groq'
              : 'SERVICE ASSISTANT SOURCE: '
              'Qwen/Groq',
        );

        return ServiceSuggestionResult(
          serviceIds:
          serviceIds,
          needsClarification: false,
          clarificationQuestion: null,
          noSuitableService: false,
          source:
          ServiceSuggestionSource
              .groqQwen,
        );
      }

      debugPrint(
        'QWEN RETURNED NO USABLE RESULT. '
            'Using fallback AI.',
      );

      return _useFallback(
        description: description,
        availableServices:
        availableServices,
        imageBytes: imageBytes,
        imageMimeType:
        imageMimeType,
      );
    } catch (e, stackTrace) {
      debugPrint(
        '========================================',
      );

      debugPrint(
        'QWEN/GROQ SERVICE FAILED',
      );

      debugPrint(
        'Error: $e',
      );

      debugPrint(
        '========================================',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return _useFallback(
        description: description,
        availableServices:
        availableServices,
        imageBytes: imageBytes,
        imageMimeType:
        imageMimeType,
      );
    }
  }

  Future<ServiceSuggestionResult>
  _useFallback({
    required String description,
    required List<ServiceItemModel>
    availableServices,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) {
    return fallback.suggestServiceIds(
      description: description,
      availableServices:
      availableServices,
      imageBytes: imageBytes,
      imageMimeType:
      imageMimeType,
    );
  }
}