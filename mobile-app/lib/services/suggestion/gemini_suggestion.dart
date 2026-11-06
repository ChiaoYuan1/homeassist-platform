import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../models/service_models.dart';
import 'service_suggestion.dart';

class AIServiceSuggestionService
    implements ServiceSuggestionService {
  final ServiceSuggestionService fallback;

  static const String _primaryModel =
      'gemini-3.8-flash';

  static const String _secondaryModel =
      'gemini-3.5-flash-lite';

  static const Duration _retryDelay =
  Duration(seconds: 2);

  static const Duration _cooldownDuration =
  Duration(seconds: 60);

  DateTime? _primaryUnavailableUntil;
  DateTime? _secondaryUnavailableUntil;

  AIServiceSuggestionService({
    required this.fallback,
  });

  @override
  Future<ServiceSuggestionResult> suggestServiceIds({
    required String description,
    required List<ServiceItemModel> availableServices,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    final cleanDescription =
    description.trim();

    final hasImage =
        imageBytes != null &&
            imageBytes.isNotEmpty &&
            imageMimeType != null &&
            imageMimeType.trim().isNotEmpty;

    if ((cleanDescription.isEmpty && !hasImage) ||
        availableServices.isEmpty) {
      return const ServiceSuggestionResult.empty();
    }

    final validIds = availableServices
        .map(
          (service) => service.id,
    )
        .toSet();

    final catalogue = availableServices
        .map(
          (service) =>
      '${service.id} — ${service.name}',
    )
        .join('\n');

    final prompt = _buildPrompt(
      catalogue: catalogue,
      cleanDescription: cleanDescription,
    );

    Object? primaryFailure;

    // =========================================================
    // 1. PRIMARY GEMINI
    // =========================================================

    if (_isCoolingDown(
      _primaryUnavailableUntil,
    )) {
      debugPrint(
        'PRIMARY AI CURRENTLY IN COOLDOWN.',
      );

      debugPrint(
        'PRIMARY AI COOLDOWN REMAINING: '
            '${_remainingCooldownSeconds(_primaryUnavailableUntil!)} seconds',
      );
    } else {
      try {
        final result =
        await _requestGemini(
          modelName: _primaryModel,
          prompt: prompt,
          validIds: validIds,
          imageBytes: imageBytes,
          imageMimeType: imageMimeType,
          hasImage: hasImage,
        );

        if (result != null) {
          _primaryUnavailableUntil = null;

          return _withSource(
            result,
            ServiceSuggestionSource
                .primaryGemini,
            _primaryModel,
          );
        }

        debugPrint(
          'PRIMARY GEMINI RETURNED '
              'NO USABLE RESULT.',
        );
      } catch (
      e,
      stackTrace
      ) {
        primaryFailure = e;

        _logGeminiFailure(
          modelName: _primaryModel,
          error: e,
          stackTrace: stackTrace,
        );

        if (_shouldRetryPrimary(e)) {
          debugPrint(
            'TEMPORARY GEMINI ERROR DETECTED.',
          );

          debugPrint(
            'Retrying $_primaryModel in '
                '${_retryDelay.inSeconds} seconds...',
          );

          await Future.delayed(
            _retryDelay,
          );

          try {
            final retryResult =
            await _requestGemini(
              modelName: _primaryModel,
              prompt: prompt,
              validIds: validIds,
              imageBytes: imageBytes,
              imageMimeType: imageMimeType,
              hasImage: hasImage,
            );

            if (retryResult != null) {
              _primaryUnavailableUntil =
              null;

              return _withSource(
                retryResult,
                ServiceSuggestionSource
                    .primaryGeminiRetry,
                '$_primaryModel (retry)',
              );
            }

            debugPrint(
              'PRIMARY GEMINI RETRY RETURNED '
                  'NO USABLE RESULT.',
            );
          } catch (
          retryError,
          retryStackTrace
          ) {
            primaryFailure =
                retryError;

            _logGeminiFailure(
              modelName:
              '$_primaryModel (retry)',
              error: retryError,
              stackTrace:
              retryStackTrace,
            );

            if (_shouldStartCooldown(
              retryError,
            )) {
              _startPrimaryCooldown();
            }
          }
        } else if (_shouldStartCooldown(e)) {
          _startPrimaryCooldown();
        }
      }
    }

    // Authentication, App Check and malformed-request
    // failures normally affect both Gemini models.
    if (primaryFailure != null &&
        !_shouldTrySecondary(
          primaryFailure,
        )) {
      debugPrint(
        'NON-TEMPORARY GEMINI ERROR DETECTED.',
      );

      debugPrint(
        'Skipping secondary AI model.',
      );

      return _useFallback(
        description: description,
        availableServices:
        availableServices,
        imageBytes: imageBytes,
        imageMimeType:
        imageMimeType,
        retryAfterSeconds:
        _nextCooldownSeconds(),
      );
    }

    // =========================================================
    // 2. SECONDARY GEMINI
    // =========================================================

    if (_isCoolingDown(
      _secondaryUnavailableUntil,
    )) {
      debugPrint(
        'SECONDARY AI CURRENTLY IN COOLDOWN.',
      );

      debugPrint(
        'SECONDARY AI COOLDOWN REMAINING: '
            '${_remainingCooldownSeconds(_secondaryUnavailableUntil!)} seconds',
      );
    } else {
      debugPrint(
        'TRYING SECONDARY GEMINI MODEL: '
            '$_secondaryModel',
      );

      try {
        final secondaryResult =
        await _requestGemini(
          modelName: _secondaryModel,
          prompt: prompt,
          validIds: validIds,
          imageBytes: imageBytes,
          imageMimeType:
          imageMimeType,
          hasImage: hasImage,
        );

        if (secondaryResult != null) {
          _secondaryUnavailableUntil =
          null;

          return _withSource(
            secondaryResult,
            ServiceSuggestionSource
                .secondaryGemini,
            _secondaryModel,
          );
        }

        debugPrint(
          'SECONDARY GEMINI RETURNED '
              'NO USABLE RESULT.',
        );
      } catch (
      e,
      stackTrace
      ) {
        _logGeminiFailure(
          modelName: _secondaryModel,
          error: e,
          stackTrace: stackTrace,
        );

        if (_shouldStartCooldown(e)) {
          _startSecondaryCooldown();
        }
      }
    }

    // =========================================================
    // 3. LOCAL FALLBACK
    // =========================================================

    return _useFallback(
      description: description,
      availableServices:
      availableServices,
      imageBytes: imageBytes,
      imageMimeType:
      imageMimeType,
      retryAfterSeconds:
      _nextCooldownSeconds(),
    );
  }

  Future<ServiceSuggestionResult?>
  _requestGemini({
    required String modelName,
    required String prompt,
    required Set<String> validIds,
    required bool hasImage,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    debugPrint(
      'SERVICE ASSISTANT REQUEST: $modelName',
    );

    final model =
    FirebaseAI.googleAI().generativeModel(
      model: modelName,
    );

    late final GenerateContentResponse response;

    if (hasImage) {
      final imagePart =
      InlineDataPart(
        imageMimeType!,
        imageBytes!,
      );

      response =
      await model.generateContent([
        Content.multi([
          TextPart(prompt),
          imagePart,
        ]),
      ]);
    } else {
      response =
      await model.generateContent([
        Content.text(
          prompt,
        ),
      ]);
    }

    final responseText =
    response.text?.trim();

    debugPrint(
      'GEMINI RAW RESPONSE '
          '[$modelName]: $responseText',
    );

    if (responseText == null ||
        responseText.isEmpty) {
      return null;
    }

    final result =
    _parseResult(
      responseText,
      validIds,
    );

    if (_isUsableResult(result)) {
      return result;
    }

    return null;
  }

  String _buildPrompt({
    required String catalogue,
    required String cleanDescription,
  }) {
    return '''
You are the service recommendation assistant for HomeAssist.

Analyze the customer's household problem and determine the most suitable
services from the supplied HomeAssist service catalogue.

Available HomeAssist services:
$catalogue

Customer description:
"${cleanDescription.isEmpty ? 'No written description was provided.' : cleanDescription}"

An image of the household problem may also be provided.

If an image is provided:
- Use visible evidence from the image together with the written description.
- Do not assume details that cannot reasonably be observed.
- If the text and image appear inconsistent, ask for clarification instead
  of guessing.

Understand realistic customer input, including:
- Informal wording.
- Short or incomplete descriptions.
- Spelling mistakes.
- Different ways of describing the same symptom.
- Descriptions that do not explicitly name a service.
- Image-only problems.
- Text and image used together.

Recommendation rules:
- Recommend only services from the supplied HomeAssist catalogue.
- Return between 1 and 3 service IDs when there is enough evidence.
- Put the strongest recommendation first.
- Do not invent service IDs.
- Do not add unrelated or weak possibilities just to reach 3 suggestions.
- Prefer one strong recommendation over several weak recommendations.

Clarification rules:
- If the information is too vague to identify a suitable service reliably,
  do not guess.
- If multiple different service types are similarly possible and there is
  not enough evidence to choose, ask one short clarification question.
- The clarification question should help distinguish between the likely
  service types.
- When clarification is required, return an empty serviceIds list.

No suitable service rules:
- If the customer's request clearly falls outside the available HomeAssist
  service catalogue, do not force a recommendation.
- Set noSuitableService to true.
- When no suitable service exists, return an empty serviceIds list.

Return ONLY valid JSON using exactly this structure:

{
  "serviceIds": [],
  "needsClarification": false,
  "clarificationQuestion": null,
  "noSuitableService": false
}

Example - clear problem:

{
  "serviceIds": ["leaking_pipe"],
  "needsClarification": false,
  "clarificationQuestion": null,
  "noSuitableService": false
}

Example - unclear electrical problem:

{
  "serviceIds": [],
  "needsClarification": true,
  "clarificationQuestion": "Is the problem affecting one socket, the lights, or the whole property's electricity?",
  "noSuitableService": false
}

Example - service outside the catalogue:

{
  "serviceIds": [],
  "needsClarification": false,
  "clarificationQuestion": null,
  "noSuitableService": true
}

Do not include explanations outside the JSON.
Do not include markdown.
Do not include code blocks.
''';
  }

  // =========================================================
  // RESULT HELPERS
  // =========================================================

  bool _isUsableResult(
      ServiceSuggestionResult result,
      ) {
    return result.serviceIds.isNotEmpty ||
        result.needsClarification ||
        result.noSuitableService ||
        result.temporarilyUnavailable;
  }

  ServiceSuggestionResult _withSource(
      ServiceSuggestionResult result,
      ServiceSuggestionSource source,
      String sourceName,
      ) {
    debugPrint(
      'SERVICE ASSISTANT SOURCE: $sourceName',
    );

    return ServiceSuggestionResult(
      serviceIds:
      result.serviceIds,
      needsClarification:
      result.needsClarification,
      clarificationQuestion:
      result.clarificationQuestion,
      noSuitableService:
      result.noSuitableService,
      source: source,
      temporarilyUnavailable:
      result.temporarilyUnavailable,
      retryAfterSeconds:
      result.retryAfterSeconds,
    );
  }

  // =========================================================
  // RETRY / FAILURE HANDLING
  // =========================================================

  bool _shouldRetryPrimary(
      Object error,
      ) {
    final message =
    error
        .toString()
        .toLowerCase();

    return message.contains(
      'server error [500]',
    ) ||
        message.contains(
          '"code": 500',
        ) ||
        message.contains(
          'code: 500',
        ) ||
        message.contains(
          'server error [503]',
        ) ||
        message.contains(
          '"code": 503',
        ) ||
        message.contains(
          'code: 503',
        ) ||
        message.contains(
          'high demand',
        ) ||
        message.contains(
          'temporarily unavailable',
        ) ||
        message.contains(
          'service unavailable',
        ) ||
        message.contains(
          'internal server error',
        );
  }

  bool _shouldStartCooldown(
      Object error,
      ) {
    final message =
    error
        .toString()
        .toLowerCase();

    return _shouldRetryPrimary(error) ||
        message.contains(
          'server error [429]',
        ) ||
        message.contains(
          '"code": 429',
        ) ||
        message.contains(
          'code: 429',
        ) ||
        message.contains(
          'too many requests',
        ) ||
        message.contains(
          'resource_exhausted',
        ) ||
        message.contains(
          'quota exceeded',
        ) ||
        message.contains(
          'quota',
        );
  }

  bool _shouldTrySecondary(
      Object error,
      ) {
    final message =
    error
        .toString()
        .toLowerCase();

    if (message.contains(
      'app attestation failed',
    ) ||
        message.contains(
          'firebase_app_check',
        ) ||
        message.contains(
          'server error [403]',
        ) ||
        message.contains(
          '"code": 403',
        ) ||
        message.contains(
          'code: 403',
        ) ||
        message.contains(
          'server error [400]',
        ) ||
        message.contains(
          '"code": 400',
        ) ||
        message.contains(
          'code: 400',
        )) {
      return false;
    }

    return true;
  }

  void _logGeminiFailure({
    required String modelName,
    required Object error,
    required StackTrace stackTrace,
  }) {
    debugPrint(
      '========================================',
    );

    debugPrint(
      'GEMINI SERVICE SUGGESTION FAILED',
    );

    debugPrint(
      'MODEL: $modelName',
    );

    debugPrint(
      'Error: $error',
    );

    debugPrint(
      '========================================',
    );

    debugPrintStack(
      stackTrace: stackTrace,
    );
  }

  // =========================================================
  // COOLDOWN
  // =========================================================

  bool _isCoolingDown(
      DateTime? unavailableUntil,
      ) {
    if (unavailableUntil == null) {
      return false;
    }

    return DateTime.now().isBefore(
      unavailableUntil,
    );
  }

  int _remainingCooldownSeconds(
      DateTime unavailableUntil,
      ) {
    final remaining =
        unavailableUntil
            .difference(
          DateTime.now(),
        )
            .inSeconds;

    return remaining < 1
        ? 1
        : remaining;
  }

  void _startPrimaryCooldown() {
    _primaryUnavailableUntil =
        DateTime.now().add(
          _cooldownDuration,
        );

    debugPrint(
      'PRIMARY AI COOLDOWN STARTED: '
          '${_cooldownDuration.inSeconds} seconds',
    );
  }

  void _startSecondaryCooldown() {
    _secondaryUnavailableUntil =
        DateTime.now().add(
          _cooldownDuration,
        );

    debugPrint(
      'SECONDARY AI COOLDOWN STARTED: '
          '${_cooldownDuration.inSeconds} seconds',
    );
  }

  int? _nextCooldownSeconds() {
    final now =
    DateTime.now();

    final remaining =
    <int>[];

    if (_primaryUnavailableUntil != null &&
        now.isBefore(
          _primaryUnavailableUntil!,
        )) {
      remaining.add(
        _remainingCooldownSeconds(
          _primaryUnavailableUntil!,
        ),
      );
    }

    if (_secondaryUnavailableUntil != null &&
        now.isBefore(
          _secondaryUnavailableUntil!,
        )) {
      remaining.add(
        _remainingCooldownSeconds(
          _secondaryUnavailableUntil!,
        ),
      );
    }

    if (remaining.isEmpty) {
      return null;
    }

    remaining.sort();

    return remaining.first;
  }

  // =========================================================
  // GEMINI RESPONSE PARSING
  // =========================================================

  ServiceSuggestionResult _parseResult(
      String responseText,
      Set<String> validIds,
      ) {
    final decoded =
    _decodeResponseObject(
      responseText,
    );

    if (decoded != null) {
      final rawIds =
      decoded['serviceIds'];

      final ids =
      rawIds is List
          ? _validateIds(
        rawIds,
        validIds,
      )
          : <String>[];

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

      if (noSuitableService) {
        return const ServiceSuggestionResult(
          serviceIds: [],
          needsClarification: false,
          clarificationQuestion: null,
          noSuitableService: true,
        );
      }

      if (needsClarification) {
        return ServiceSuggestionResult(
          serviceIds: const [],
          needsClarification: true,
          clarificationQuestion:
          clarificationQuestion ??
              'Could you provide a little more detail about the problem?',
          noSuitableService: false,
        );
      }

      if (ids.isNotEmpty) {
        return ServiceSuggestionResult(
          serviceIds: ids,
          needsClarification: false,
          clarificationQuestion: null,
          noSuitableService: false,
        );
      }
    }

    final detected = validIds
        .map(
          (id) => MapEntry(
        id,
        responseText.indexOf(id),
      ),
    )
        .where(
          (entry) =>
      entry.value >= 0,
    )
        .toList()
      ..sort(
            (a, b) =>
            a.value.compareTo(
              b.value,
            ),
      );

    final detectedIds =
    detected
        .map(
          (entry) =>
      entry.key,
    )
        .take(3)
        .toList();

    if (detectedIds.isNotEmpty) {
      return ServiceSuggestionResult(
        serviceIds: detectedIds,
      );
    }

    return const ServiceSuggestionResult.empty();
  }

  Map<String, dynamic>?
  _decodeResponseObject(
      String responseText,
      ) {
    try {
      final decoded =
      jsonDecode(
        responseText,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Continue with defensive extraction.
    }

    final start =
    responseText.indexOf(
      '{',
    );

    final end =
    responseText.lastIndexOf(
      '}',
    );

    if (start == -1 ||
        end == -1 ||
        end <= start) {
      return null;
    }

    final jsonPart =
    responseText.substring(
      start,
      end + 1,
    );

    try {
      final decoded =
      jsonDecode(
        jsonPart,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  List<String> _validateIds(
      List<dynamic> rawIds,
      Set<String> validIds,
      ) {
    final result =
    <String>[];

    for (final rawId in rawIds) {
      if (rawId is! String) {
        continue;
      }

      final id =
      rawId.trim();

      if (!validIds.contains(id)) {
        continue;
      }

      if (result.contains(id)) {
        continue;
      }

      result.add(id);

      if (result.length == 3) {
        break;
      }
    }

    return result;
  }

  // =========================================================
  // LOCAL FALLBACK ENTRY
  // =========================================================

  Future<ServiceSuggestionResult>
  _useFallback({
    required String description,
    required List<ServiceItemModel>
    availableServices,
    Uint8List? imageBytes,
    String? imageMimeType,
    int? retryAfterSeconds,
  }) async {
    debugPrint(
      'USING LOCAL SERVICE FALLBACK',
    );

    final result =
    await fallback
        .suggestServiceIds(
      description: description,
      availableServices:
      availableServices,
      imageBytes:
      imageBytes,
      imageMimeType:
      imageMimeType,
    );

    if (_isUsableResult(result)) {
      return _withSource(
        result,
        ServiceSuggestionSource
            .localFallback,
        'local-fallback',
      );
    }

    if (retryAfterSeconds != null) {
      debugPrint(
        'SERVICE ASSISTANT TEMPORARILY '
            'UNAVAILABLE. RETRY AFTER '
            '$retryAfterSeconds SECONDS.',
      );

      return ServiceSuggestionResult(
        serviceIds: const [],
        temporarilyUnavailable:
        true,
        retryAfterSeconds:
        retryAfterSeconds,
        source:
        ServiceSuggestionSource
            .localFallback,
      );
    }

    return _withSource(
      result,
      ServiceSuggestionSource
          .localFallback,
      'local-fallback',
    );
  }
}