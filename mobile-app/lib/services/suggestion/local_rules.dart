import 'dart:typed_data';

import '../../models/service_models.dart';
import 'service_suggestion.dart';

class LocalServiceSuggestionService
    implements ServiceSuggestionService {
  @override
  Future<ServiceSuggestionResult> suggestServiceIds({
    required String description,
    required List<ServiceItemModel> availableServices,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    final text =
    _normalize(
      description,
    );

    final hasImage =
        imageBytes != null &&
            imageBytes.isNotEmpty;

    // Local rules cannot inspect image contents.
    if (text.isEmpty) {
      if (hasImage) {
        return const ServiceSuggestionResult(
          serviceIds: [],
          needsClarification: true,
          clarificationQuestion:
          'Could you briefly describe the problem shown in the photo?',
          noSuitableService: false,
        );
      }

      return const ServiceSuggestionResult.empty();
    }

    final scores =
    <String, int>{};

    void score(
        String id,
        int amount,
        ) {
      final exists =
      availableServices.any(
            (service) =>
        service.id == id,
      );

      if (!exists) {
        return;
      }

      scores[id] =
          (scores[id] ?? 0) +
              amount;
    }

    bool hasAny(
        List<String> phrases,
        ) {
      return phrases.any(
            (phrase) =>
            text.contains(
              _normalize(
                phrase,
              ),
            ),
      );
    }

    // ========================================================
    // EXACT CATALOGUE NAMES
    // ========================================================

    for (final service in availableServices) {
      final serviceName =
      _normalize(
        service.name,
      );

      if (serviceName.isNotEmpty &&
          text.contains(
            serviceName,
          )) {
        score(
          service.id,
          12,
        );
      }
    }

    // ========================================================
    // LEAKING PIPE
    // ========================================================

    if (hasAny([
      'leak',
      'leaking',
      'pipe leaking',
      'leaky pipe',
      'dripping pipe',
      'water pipe',
      'burst pipe',
    ])) {
      score(
        'leaking_pipe',
        8,
      );
    }

    // ========================================================
    // CLOGGED DRAIN
    // ========================================================

    if (hasAny([
      'clogged drain',
      'clog drain',
      'blocked drain',
      'drain blocked',
      'slow drain',
      'not draining',
      'water not draining',
      'sink blocked',
      'sink clogged',
    ])) {
      score(
        'clogged_drain',
        9,
      );
    } else if (hasAny([
      'drain',
      'clog',
      'clogged',
    ])) {
      score(
        'clogged_drain',
        6,
      );
    }

    // ========================================================
    // FAULTY SOCKET
    // ========================================================

    if (hasAny([
      'wall socket',
      'power socket',
      'socket not working',
      'socket no power',
      'electrical socket',
      'wall outlet',
      'power outlet',
      'outlet not working',
      'plug point',
    ])) {
      score(
        'faulty_socket',
        10,
      );
    } else if (hasAny([
      'socket',
      'outlet',
      'plug point',
    ])) {
      score(
        'faulty_socket',
        7,
      );
    }

    // ========================================================
    // AIR CONDITIONER
    // ========================================================

    final mentionsAirConditioner =
    hasAny([
      'air conditioner',
      'air conditioning',
      'aircond',
      'air con',
      'aircon',
    ]);

    if (mentionsAirConditioner) {
      score(
        'air_conditioner',
        9,
      );

      if (hasAny([
        'not cold',
        'not cooling',
        'warm air',
        'no cold air',
        'leaking water',
      ])) {
        score(
          'air_conditioner',
          3,
        );
      }
    }

    // ========================================================
    // GAS TANK REPLACEMENT
    // ========================================================

    if (hasAny([
      'gas tank',
      'gas cylinder',
      'lpg cylinder',
      'lpg tank',
      'cooking gas',
      'replace gas',
      'gas finished',
      'gas empty',
    ])) {
      score(
        'gas_tank_replacement',
        9,
      );
    }

    // ========================================================
    // LIGHT PROBLEM
    // ========================================================

    if (hasAny([
      'light not working',
      'light stopped working',
      'flickering light',
      'light flickering',
      'bulb not working',
      'lamp not working',
      'light keeps flickering',
      'light is dim',
      'light dim',
    ])) {
      score(
        'light_problem',
        9,
      );
    } else if (hasAny([
      'light',
      'bulb',
      'lamp',
      'flicker',
      'flickering',
    ])) {
      score(
        'light_problem',
        6,
      );
    }

    // ========================================================
    // POWER OUTAGE
    // ========================================================

    if (hasAny([
      'power outage',
      'blackout',
      'whole house no power',
      'whole house no electricity',
      'entire house no power',
      'entire house no electricity',
      'no electricity anywhere',
      'all power is out',
    ])) {
      score(
        'power_outage',
        11,
      );
    }

    // ========================================================
    // REFRIGERATOR
    // ========================================================

    final mentionsFridge =
    hasAny([
      'refrigerator',
      'fridge',
      'freezer',
    ]);

    if (mentionsFridge) {
      score(
        'refrigerator',
        9,
      );

      if (hasAny([
        'not cold',
        'not cooling',
        'warm',
        'ice melting',
      ])) {
        score(
          'refrigerator',
          3,
        );
      }
    }

    // ========================================================
    // TOILET PROBLEM
    // ========================================================

    if (hasAny([
      'toilet',
      'toilet bowl',
      'toilet flush',
      'flush not working',
      'cannot flush',
      'toilet clogged',
      'toilet blocked',
      'toilet leaking',
      'toilet overflow',
    ])) {
      score(
        'toilet_problem',
        9,
      );
    }

    // ========================================================
    // WASHING MACHINE
    // ========================================================

    final mentionsWashingMachine =
    hasAny([
      'washing machine',
      'washing mashine',
      'washin machine',
      'washin mashine',
      'washer',
      'laundry machine',
    ]);

    if (mentionsWashingMachine) {
      score(
        'washing_machine',
        10,
      );

      if (hasAny([
        'not spinning',
        'not spin',
        'spinning',
        'not draining',
        'not washing',
      ])) {
        score(
          'washing_machine',
          3,
        );
      }
    } else if (hasAny([
      'wasing machine',
      'wasing mashine',
      'wash machine',
    ])) {
      score(
        'washing_machine',
        8,
      );
    }

    // ========================================================
    // WATER HEATER
    // ========================================================

    if (hasAny([
      'water heater',
      'shower heater',
      'heater not working',
      'no hot water',
      'water not hot',
      'cold shower',
    ])) {
      score(
        'water_heater',
        9,
      );
    }

    // ========================================================
    // WIRING PROBLEM
    // ========================================================

    if (hasAny([
      'electrical wiring',
      'wiring problem',
      'faulty wiring',
      'loose wire',
      'damaged wire',
      'burnt wire',
      'burning wire',
      'exposed wire',
      'wire sparking',
    ])) {
      score(
        'wiring_problem',
        10,
      );
    } else if (hasAny([
      'wiring',
      'electrical wire',
      'electric wire',
    ])) {
      score(
        'wiring_problem',
        7,
      );
    }

    // ========================================================
    // AMBIGUOUS CHARGING PROBLEMS
    // ========================================================

    final chargingProblem =
    hasAny([
      'phone not charging',
      'phone is not charging',
      'cannot charge phone',
      'cant charge phone',
      'not charging',
    ]);

    final explicitlyMentionsSocket =
    hasAny([
      'socket',
      'outlet',
      'plug point',
      'wall plug',
    ]);

    if (chargingProblem &&
        !explicitlyMentionsSocket) {
      return const ServiceSuggestionResult(
        serviceIds: [],
        needsClarification: true,
        clarificationQuestion:
        'Does the phone fail to charge only from one wall socket, or does it also fail with other chargers and sockets?',
        noSuitableService: false,
      );
    }

    // ========================================================
    // VAGUE ELECTRICAL PROBLEMS
    // ========================================================

    final vagueElectricalProblem =
    hasAny([
      'something electrical',
      'electricity is weird',
      'electrical problem',
      'power problem',
    ]);

    if (vagueElectricalProblem &&
        scores.isEmpty) {
      return const ServiceSuggestionResult(
        serviceIds: [],
        needsClarification: true,
        clarificationQuestion:
        'Is the problem affecting a socket, the lights, or the whole property\'s electricity?',
        noSuitableService: false,
      );
    }

    // ========================================================
    // CLEAR REQUESTS OUTSIDE HOMEASSIST
    // ========================================================

    if (hasAny([
      'paint bedroom',
      'paint my room',
      'paint the wall',
      'wall painting',
      'house painting',
      'pest control',
      'termite',
      'move furniture',
      'moving house',
      'furniture assembly',
    ])) {
      return const ServiceSuggestionResult(
        serviceIds: [],
        needsClarification: false,
        clarificationQuestion: null,
        noSuitableService: true,
      );
    }

    // ========================================================
    // RANK RESULTS
    // ========================================================

    final ranked = scores.entries
        .where(
          (entry) =>
      entry.value >= 5,
    )
        .toList()
      ..sort(
            (a, b) =>
            b.value.compareTo(
              a.value,
            ),
      );

    if (ranked.isEmpty) {
      return const ServiceSuggestionResult(
        serviceIds: [],
        needsClarification: true,
        clarificationQuestion:
        'Could you provide a little more detail about which appliance or area of the home is affected?',
        noSuitableService: false,
      );
    }

    final topScore =
        ranked.first.value;

    if (topScore < 7) {
      return const ServiceSuggestionResult(
        serviceIds: [],
        needsClarification: true,
        clarificationQuestion:
        'Could you provide a little more detail about the problem?',
        noSuitableService: false,
      );
    }

    final ids = ranked
        .where(
          (entry) =>
      entry.value >=
          topScore - 2,
    )
        .take(3)
        .map(
          (entry) => entry.key,
    )
        .toList();

    return ServiceSuggestionResult(
      serviceIds: ids,
    );
  }

  String _normalize(
      String value,
      ) {
    return value
        .toLowerCase()
        .replaceAll(
      RegExp(
        r'[^a-z0-9\s]',
      ),
      ' ',
    )
        .replaceAll(
      RegExp(
        r'\s+',
      ),
      ' ',
    )
        .trim();
  }
}