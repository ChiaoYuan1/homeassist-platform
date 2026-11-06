import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';
import '../../widgets/homeassist_action_dialog.dart';
import '../../viewmodels/service_assistant_viewmodel.dart';
import '../../viewmodels/customer_booking_viewmodel.dart';
import 'booking/service_problem_page.dart';

class ServiceAssistantPage extends StatefulWidget {
  const ServiceAssistantPage({
    super.key,
  });

  @override
  State<ServiceAssistantPage> createState() =>
      _ServiceAssistantPageState();
}

class _ServiceAssistantPageState
    extends State<ServiceAssistantPage> {
  final _controller = TextEditingController();

  final _clarificationController =
  TextEditingController();

  final _vm = ServiceAssistantViewModel();

  final ImagePicker _imagePicker =
  ImagePicker();

  Uint8List? _imageBytes;
  String? _imageMimeType;
  String? _imageName;

  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  // Keeps the complete problem context.
  // This includes clarification answers so they are not lost.
  String _analysisDescription = '';

  @override
  void dispose() {
    _cooldownTimer?.cancel();

    _controller.dispose();
    _clarificationController.dispose();
    _vm.dispose();

    super.dispose();
  }

  // =========================================================
  // IMAGE
  // =========================================================

  Future<void> _pickImage() async {
    try {
      final image =
      await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (image == null) {
        return;
      }

      final bytes =
      await image.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        _imageBytes = bytes;

        _imageName =
            image.name;

        _imageMimeType =
            image.mimeType ??
                _getMimeType(
                  image.name,
                );
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      debugPrint('Unable to select image: $e');

      await showHomeAssistMessageDialog(
        context: context,
        title: 'Unable to Select Photo',
        message: 'The selected photo could not be loaded. '
            'Please try selecting another photo.',
        type: HomeAssistMessageType.error,
      );
    }
  }

  String _getMimeType(
      String fileName,
      ) {
    final lower =
    fileName.toLowerCase();

    if (lower.endsWith('.png')) {
      return 'image/png';
    }

    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }

    if (lower.endsWith('.heic')) {
      return 'image/heic';
    }

    return 'image/jpeg';
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageMimeType = null;
      _imageName = null;
    });
  }

  // =========================================================
  // SERVICE SUGGESTION
  // =========================================================

  Future<void> _suggestServices() async {
    final description =
    _controller.text.trim();

    if (description.isEmpty && _imageBytes == null) {
      await showHomeAssistMessageDialog(
        context: context,
        title: 'Problem Details Required',
        message: 'Please describe the problem or add a photo '
            'before requesting service suggestions.',
        type: HomeAssistMessageType.warning,
      );
      return;
    }

    if (_cooldownSeconds > 0) {
      return;
    }

    _clarificationController.clear();

    // Start a fresh analysis context.
    _analysisDescription =
        description;

    await _vm.suggest(
      description,
      imageBytes: _imageBytes,
      imageMimeType:
      _imageMimeType,
    );

    if (!mounted) {
      return;
    }

    _syncCooldown();
  }

  // =========================================================
  // CLARIFICATION
  // =========================================================

  Future<void> _submitClarification() async {
    final answer =
    _clarificationController
        .text
        .trim();

    if (answer.isEmpty) {
      await showHomeAssistMessageDialog(
        context: context,
        title: 'Clarification Required',
        message: 'Please answer the clarification question '
            'before continuing.',
        type: HomeAssistMessageType.warning,
      );

      return;
    }

    if (_cooldownSeconds > 0) {
      return;
    }

    // If this is somehow empty, fall back to the
    // original description currently in the text field.
    if (_analysisDescription
        .trim()
        .isEmpty) {
      _analysisDescription =
          _controller.text.trim();
    }

    final previousContext =
    _analysisDescription.trim();

    final combinedDescription =
    previousContext.isEmpty
        ? '''
Additional information from the customer:
$answer
'''
        : '''
$previousContext

Additional clarification from the customer:
$answer
''';

    // Keep the clarification as part of the continuing context.
    _analysisDescription =
        combinedDescription.trim();

    await _vm.suggest(
      _analysisDescription,
      imageBytes: _imageBytes,
      imageMimeType:
      _imageMimeType,
    );

    if (!mounted) {
      return;
    }

    _clarificationController.clear();

    _syncCooldown();
  }

  // =========================================================
  // COOLDOWN
  // =========================================================

  void _syncCooldown() {
    if (!_vm.temporarilyUnavailable) {
      _stopCooldown();
      return;
    }

    final seconds =
        _vm.retryAfterSeconds;

    if (seconds == null ||
        seconds <= 0) {
      _stopCooldown();
      return;
    }

    _startCooldown(
      seconds,
    );
  }

  void _startCooldown(
      int seconds,
      ) {
    _cooldownTimer?.cancel();

    setState(() {
      _cooldownSeconds =
          seconds;
    });

    _cooldownTimer =
        Timer.periodic(
          const Duration(seconds: 1),
              (timer) {
            if (!mounted) {
              timer.cancel();
              return;
            }

            if (_cooldownSeconds <= 1) {
              timer.cancel();

              setState(() {
                _cooldownSeconds = 0;
              });

              return;
            }

            setState(() {
              _cooldownSeconds--;
            });
          },
        );
  }

  void _stopCooldown() {
    _cooldownTimer?.cancel();

    _cooldownTimer = null;

    if (_cooldownSeconds != 0 &&
        mounted) {
      setState(() {
        _cooldownSeconds = 0;
      });
    }
  }

  // =========================================================
  // RESET
  // =========================================================

  void _resetAssistant() {
    _cooldownTimer?.cancel();

    _controller.clear();
    _clarificationController.clear();

    _vm.reset();

    setState(() {
      _imageBytes = null;
      _imageMimeType = null;
      _imageName = null;

      _cooldownSeconds = 0;

      _analysisDescription = '';
    });
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final cooldownActive =
        _cooldownSeconds > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Service Assistant',
        ),
      ),
      body: ListView(
        padding:
        const EdgeInsets.all(20),
        children: [
          const Text(
            'Describe the problem',
            style: TextStyle(
              fontSize: 24,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'Describe the issue, add a photo, or use both. '
                'HomeAssist will suggest suitable services, '
                'while the final choice remains with the customer.',
            style: TextStyle(
              color:
              AppTheme.textSecondary,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          TextField(
            controller:
            _controller,
            minLines: 5,
            maxLines: 8,
            decoration:
            const InputDecoration(
              hintText:
              'Example: The socket beside my bed suddenly stopped working.',
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          OutlinedButton.icon(
            onPressed:
            _vm.isLoading
                ? null
                : _pickImage,
            icon: const Icon(
              Icons
                  .add_photo_alternate_outlined,
            ),
            label: Text(
              _imageBytes == null
                  ? 'Add Photo'
                  : 'Change Photo',
            ),
          ),

          if (_imageBytes != null) ...[
            const SizedBox(
              height: 14,
            ),

            _imagePreview(),
          ],

          const SizedBox(
            height: 18,
          ),

          ListenableBuilder(
            listenable: _vm,
            builder: (
                context,
                _,
                ) {
              return Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                    _vm.isLoading ||
                        cooldownActive
                        ? null
                        : _suggestServices,
                    icon:
                    _vm.isLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2,
                      ),
                    )
                        : const Icon(
                      Icons
                          .auto_awesome,
                    ),
                    label: Text(
                      _vm.isLoading
                          ? 'Analyzing...'
                          : cooldownActive
                          ? 'Try Again in ${_cooldownSeconds}s'
                          : 'Suggest Services',
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  if (_vm.temporarilyUnavailable)
                    _temporaryUnavailableCard(),

                  if (_vm.needsClarification)
                    _clarificationCard(),

                  if (_vm.noSuitableService)
                    _noSuitableServiceCard(),

                  if (_vm.suggestions
                      .isNotEmpty) ...[
                    const Align(
                      alignment:
                      Alignment
                          .centerLeft,
                      child: Text(
                        'Suggested Services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight
                              .w700,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),
                  ],

                  ..._vm.suggestions.map(
                        (service) => Card(
                      child: ListTile(
                        title: Text(
                          service.name,
                        ),
                        subtitle: Text(
                          '${service.defaultDurationMinutes} min estimated',
                        ),
                        trailing:
                        const Icon(
                          Icons
                              .chevron_right,
                        ),
                        onTap: () async {
                          final bookingVm =
                          CustomerBookingViewModel();

                          final bookingDescription =
                          _analysisDescription
                              .trim()
                              .isNotEmpty
                              ? _analysisDescription
                              .trim()
                              : _controller
                              .text
                              .trim();

                          final success =
                          await bookingVm
                              .startFromSuggestedService(
                            service:
                            service,
                            description:
                            bookingDescription,
                          );

                          if (!mounted) {
                            return;
                          }

                          if (!success) {
                            await showHomeAssistMessageDialog(
                              context: context,
                              title: 'Unable to Start Booking',
                              message: 'The booking process could not be started '
                                  'with the selected service. Please try again.',
                              type: HomeAssistMessageType.error,
                            );

                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ServiceProblemPage(
                                    viewModel:
                                    bookingVm,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TEMPORARY UNAVAILABLE CARD
  // =========================================================

  Widget _temporaryUnavailableCard() {
    final waiting =
        _cooldownSeconds > 0;

    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 18,
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.schedule_outlined,
              color:
              AppTheme.primary,
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  const Text(
                    'Service Assistant is temporarily busy',
                    style:
                    TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    waiting
                        ? 'Please try again in $_cooldownSeconds seconds.'
                        : 'You can try again now.',
                    style:
                    const TextStyle(
                      color: AppTheme
                          .textSecondary,
                    ),
                  ),

                  if (!waiting) ...[
                    const SizedBox(
                      height: 10,
                    ),

                    TextButton.icon(
                      onPressed:
                      _vm.isLoading
                          ? null
                          : _suggestServices,
                      icon:
                      const Icon(
                        Icons.refresh,
                      ),
                      label:
                      const Text(
                        'Try Again',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // CLARIFICATION CARD
  // =========================================================

  Widget _clarificationCard() {
    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 18,
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons
                      .help_outline,
                  color:
                  AppTheme.primary,
                ),

                SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    'A little more detail is needed',
                    style:
                    TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              _vm.clarificationQuestion ??
                  'Could you provide a little more detail about the problem?',
            ),

            const SizedBox(
              height: 14,
            ),

            TextField(
              controller:
              _clarificationController,
              minLines: 2,
              maxLines: 4,
              decoration:
              const InputDecoration(
                hintText:
                'Type your answer here...',
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            SizedBox(
              width:
              double.infinity,
              child:
              ElevatedButton.icon(
                onPressed:
                _vm.isLoading ||
                    _cooldownSeconds >
                        0
                    ? null
                    : _submitClarification,
                icon: const Icon(
                  Icons
                      .chat_outlined,
                ),
                label: Text(
                  _cooldownSeconds > 0
                      ? 'Try Again in ${_cooldownSeconds}s'
                      : 'Submit Clarification',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // NO SUITABLE SERVICE CARD
  // =========================================================

  Widget _noSuitableServiceCard() {
    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 18,
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              color:
              AppTheme.textSecondary,
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  const Text(
                    'No suitable service found',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  const Text(
                    'The problem does not appear to match a service currently available in HomeAssist.',
                    style:
                    TextStyle(
                      color: AppTheme
                          .textSecondary,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  TextButton(
                    onPressed:
                    _resetAssistant,
                    child:
                    const Text(
                      'Try Another Problem',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // IMAGE PREVIEW
  // =========================================================

  Widget _imagePreview() {
    return Card(
      clipBehavior:
      Clip.antiAlias,
      child: Column(
        children: [
          Stack(
            children: [
              Image.memory(
                _imageBytes!,
                width:
                double.infinity,
                height: 220,
                fit:
                BoxFit.cover,
              ),

              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color:
                  Colors.black54,
                  shape:
                  const CircleBorder(),
                  child:
                  IconButton(
                    onPressed:
                    _removeImage,
                    icon:
                    const Icon(
                      Icons.close,
                      color:
                      Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_imageName != null)
            Padding(
              padding:
              const EdgeInsets
                  .all(12),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .image_outlined,
                    size: 20,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      _imageName!,
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}