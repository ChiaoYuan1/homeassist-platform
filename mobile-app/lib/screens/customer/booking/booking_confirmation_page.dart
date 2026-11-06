
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/attachment_model.dart';
import '../../../models/booking_problem_draft.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/customer_booking_viewmodel.dart';
import '../../../widgets/homeassist_action_dialog.dart';
import 'customer_booking_status_page.dart';
import 'provider_list_page.dart';

class BookingConfirmationPage extends StatelessWidget {
  final CustomerBookingViewModel viewModel;

  const BookingConfirmationPage({
    super.key,
    required this.viewModel,
  });

  // =====================================================
  // APPOINTMENT TIME FORMATTING
  // =====================================================

  // Convert 24-hour time to 12-hour time.
  // Example: 13:00 -> 1:00 p.m.
  String _formatAppointment(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0
        ? 12
        : dateTime.hour % 12;

    final minute =
    dateTime.minute.toString().padLeft(2, '0');

    final period =
    dateTime.hour < 12 ? 'a.m.' : 'p.m.';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '$hour:$minute $period';
  }

  // =====================================================
  // MAIN CONFIRMATION PAGE
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Confirm Booking',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        top: false,

        child: ListenableBuilder(
          listenable: viewModel,

          builder: (context, _) {
            final draft = viewModel.draft;
            final match = draft.providerMatch;
            final slot = draft.appointmentSlot;

            // =========================================
            // INCOMPLETE BOOKING INFORMATION
            // =========================================

            if (match == null || slot == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),

                  child: Text(
                    'Booking details are incomplete. '
                        'Please go back and select a provider '
                        'and appointment.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // =========================================
            // DISPLAY INFORMATION
            // =========================================

            final services = viewModel.selectedServices
                .map((service) => service.name)
                .join(', ');

            final providerInfo =
                '${match.provider.businessName}\n'
                '${match.branch.name}\n'
                '${match.distanceKm.toStringAsFixed(1)} km away';

            final appointmentInfo =
                '${_formatAppointment(slot.start)}\n'
                'Technician: ${slot.technicianName}';

            return LayoutBuilder(
              builder: (context, constraints) {
                final sideBySide =
                    constraints.maxWidth >= 380;

                const pagePadding = 16.0;
                const cardSpacing = 8.0;

                return Column(
                  children: [
                    // =================================
                    // SCROLLABLE BOOKING INFORMATION
                    // =================================

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          pagePadding,
                          10,
                          pagePadding,
                          8,
                        ),

                        children: [
                          // =============================
                          // SEQUENTIAL BOOKING PROGRESS
                          // =============================

                          if (viewModel.isSeparateBookingFlow) ...[
                            Text(
                              'Booking '
                                  '${viewModel.separateBookingPosition} '
                                  'of ${viewModel.separateBookingTotal}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 6),
                          ],

                          const Text(
                            'Review your booking',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // =============================
                          // SERVICES
                          // =============================

                          _buildCard(
                            'Services',
                            services,
                          ),

                          const SizedBox(
                            height: cardSpacing,
                          ),

                          // =============================
                          // PROBLEM
                          // =============================

                          if (draft.problemDetails.isNotEmpty)
                            ...draft.problemDetails.asMap().entries.map(
                                  (entry) => _buildEditableProblemCard(
                                context,
                                entry.key,
                                entry.value,
                              ),
                            )
                          else
                            _buildCard(
                              'Problem',
                              draft.problemDescription,
                            ),

                          const SizedBox(
                            height: cardSpacing,
                          ),

                          // =============================
                          // PROVIDER AND APPOINTMENT
                          // =============================

                          // Keep Provider and Appointment
                          // side by side on wider screens.
                          if (sideBySide)
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.stretch,

                                children: [
                                  Expanded(
                                    child: _buildCard(
                                      'Provider',
                                      providerInfo,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: _buildCard(
                                      'Appointment',
                                      appointmentInfo,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            _buildCard(
                              'Provider',
                              providerInfo,
                            ),

                            const SizedBox(
                              height: cardSpacing,
                            ),

                            _buildCard(
                              'Appointment',
                              appointmentInfo,
                            ),
                          ],

                          const SizedBox(
                            height: cardSpacing,
                          ),

                          // =============================
                          // SERVICE LOCATION
                          // =============================

                          _buildCard(
                            'Location',
                            draft.address,
                          ),

                          // =============================
                          // PROBLEM PHOTOS
                          // =============================

                          if (draft.problemDetails.any(
                                (problem) =>
                            problem.photos.isNotEmpty,
                          )) ...[
                            const SizedBox(
                              height: cardSpacing,
                            ),

                            _buildPhotoCard(
                              context,
                              draft.problemDetails,
                            ),
                          ],

                          // =============================
                          // GAS BRAND PREFERENCE
                          // =============================

                          if (draft.gasBrandPreference != null &&
                              draft.gasBrandPreference!
                                  .trim()
                                  .isNotEmpty) ...[
                            const SizedBox(
                              height: cardSpacing,
                            ),

                            _buildCard(
                              'Gas Brand Preference',
                              draft.gasBrandPreference!,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // =================================
                    // FIXED BOTTOM SUBMISSION BUTTON
                    // =================================

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        pagePadding,
                        6,
                        pagePadding,
                        8,
                      ),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                        children: [
                          // =============================
                          // BOOKING ERROR MESSAGE
                          // =============================

                          if (viewModel.errorMessage != null) ...[
                            Text(
                              viewModel.errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.error,
                              ),
                            ),

                            const SizedBox(height: 8),
                          ],

                          // =============================
                          // SUBMIT BOOKING
                          // =============================

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize:
                              const Size.fromHeight(48),
                            ),

                            onPressed: viewModel.isLoading
                                ? null
                                : () async {
                              // Submit the currently
                              // selected service booking.
                              final booking =
                              await viewModel.submitBooking();

                              // If submission failed,
                              // do not advance to the
                              // next service.
                              if (booking == null ||
                                  !context.mounted) {
                                return;
                              }

                              // =====================
                              // NEXT BOOKING LOGIC
                              // =====================

                              // Only advance after
                              // the current booking
                              // has been created.
                              final hasAnother = viewModel
                                  .prepareNextAfterSuccessfulBooking(
                                booking.id,
                              );

                              // =====================
                              // MORE SERVICES REMAIN
                              // =====================

                              if (hasAnother) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProviderListPage(
                                          viewModel: viewModel,
                                        ),
                                  ),
                                      (route) => route.isFirst,
                                );

                                // Reuse the customer's
                                // existing address and
                                // saved problem details.
                                //
                                // Find providers for
                                // the next individual
                                // service only.
                                await viewModel.findProviders();

                                return;
                              }

                              // =====================
                              // FINAL BOOKING
                              // =====================

                              // Existing navigation
                              // remains unchanged for
                              // normal single or
                              // combined bookings.
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CustomerBookingStatusPage(
                                        bookingId: booking.id,
                                      ),
                                ),
                                    (route) => route.isFirst,
                              );
                            },

                            child: Text(
                              viewModel.isLoading
                                  ? 'Submitting...'
                                  : 'Submit Booking',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // =====================================================
  // GENERAL INFORMATION CARD
  // =====================================================

  Widget _buildCard(
      String title,
      String value,
      ) {
    return Card(
      margin: EdgeInsets.zero,

      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 11,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              value.trim().isEmpty
                  ? 'Not provided'
                  : value,
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // PHOTO THUMBNAILS
  // =====================================================

  Widget _buildPhotoCard(
      BuildContext context,
      List<BookingProblemDraft> problems,
      ) {
    final photos = <_ReviewPhoto>[];

    // Keep each photo linked to its own problem.
    for (
    var problemIndex = 0;
    problemIndex < problems.length;
    problemIndex++
    ) {
      final problem = problems[problemIndex];

      for (
      var photoIndex = 0;
      photoIndex < problem.photos.length;
      photoIndex++
      ) {
        photos.add(
          _ReviewPhoto(
            problemIndex: problemIndex,
            photoIndex: photoIndex,
            photo: problem.photos[photoIndex],
            serviceName: problem.serviceName,
          ),
        );
      }
    }

    return Card(
      margin: EdgeInsets.zero,

      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              'Attachments (${photos.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Tap to preview or use the edit icon '
                  'to replace a photo.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 88,

              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,

                separatorBuilder: (_, __) =>
                const SizedBox(width: 10),

                itemBuilder: (context, index) {
                  final entry = photos[index];

                  return SizedBox(
                    width: 88,
                    height: 88,

                    child: Stack(
                      children: [
                        // =============================
                        // PHOTO PREVIEW
                        // =============================

                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius:
                            BorderRadius.circular(10),

                            child: InkWell(
                              onTap: () => _showPhotoPreview(
                                context,
                                entry,
                                index + 1,
                                photos.length,
                              ),

                              child: Image.memory(
                                entry.photo.bytes,
                                fit: BoxFit.cover,
                                cacheWidth: 264,

                                errorBuilder:
                                    (_, __, ___) => Container(
                                  color: Colors.black12,
                                  alignment: Alignment.center,

                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // =============================
                        // REPLACE PHOTO BUTTON
                        // =============================

                        Positioned(
                          right: 2,
                          bottom: 2,

                          child: Material(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(8),
                            elevation: 2,

                            child: InkWell(
                              borderRadius:
                              BorderRadius.circular(8),

                              onTap: viewModel.isLoading
                                  ? null
                                  : () => _replacePhoto(
                                context,
                                entry,
                              ),

                              child: const SizedBox(
                                width: 36,
                                height: 36,

                                child: Tooltip(
                                  message: 'Replace photo',

                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 19,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEditableProblemCard(
      BuildContext context,
      int problemIndex,
      BookingProblemDraft problem,
      ) {
    final photos = problem.photos;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              problem.isPrimary
                  ? 'Main Problem'
                  : 'Additional Problem $problemIndex',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              problem.serviceName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => _editDescription(
                    context,
                    problemIndex,
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 17,
                  ),
                  label: const Text('Edit Description'),
                ),
              ],
            ),
            Text(
              problem.description.trim().isEmpty
                  ? 'No additional details provided.'
                  : problem.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Photos (${photos.length}/5)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed:
                  viewModel.isLoading || photos.length >= 5
                      ? null
                      : () => _addPhotos(
                    context,
                    problemIndex,
                  ),
                  icon: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 17,
                  ),
                  label: const Text('Add Picture'),
                ),
              ],
            ),
            if (photos.isEmpty)
              const Text(
                'No pictures attached.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var photoIndex = 0;
                  photoIndex < photos.length;
                  photoIndex++)
                    SizedBox(
                      width: 96,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: InkWell(
                              onTap: () => _showPhotoPreview(
                                context,
                                _ReviewPhoto(
                                  problemIndex: problemIndex,
                                  photoIndex: photoIndex,
                                  photo: photos[photoIndex],
                                  serviceName: problem.serviceName,
                                ),
                                photoIndex + 1,
                                photos.length,
                              ),
                              child: Image.memory(
                                photos[photoIndex].bytes,
                                width: 96,
                                height: 78,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: viewModel.isLoading
                                ? null
                                : () => _replacePhoto(
                              context,
                              _ReviewPhoto(
                                problemIndex: problemIndex,
                                photoIndex: photoIndex,
                                photo: photos[photoIndex],
                                serviceName: problem.serviceName,
                              ),
                            ),
                            child: const Text('Replace'),
                          ),
                          TextButton(
                            onPressed: viewModel.isLoading
                                ? null
                                : () => _removePhoto(
                              problemIndex,
                              photoIndex,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.error,
                            ),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Update the unsent draft, not the Firestore booking.
  void _updateProblem(
      int problemIndex,
      BookingProblemDraft Function(BookingProblemDraft) update,
      ) {
    final current = viewModel.draft.problemDetails;

    if (problemIndex < 0 || problemIndex >= current.length) {
      return;
    }

    final updated = List<BookingProblemDraft>.from(current);
    updated[problemIndex] = update(current[problemIndex]);

    viewModel.setProblemDetailsByProblem(
      problemDetails: updated,
      gasBrandPreference: viewModel.draft.gasBrandPreference,
    );
  }

  Future<void> _editDescription(
      BuildContext context,
      int problemIndex,
      ) async {
    if (viewModel.isLoading) return;

    final current = viewModel.draft.problemDetails;
    if (problemIndex >= current.length) return;

    String edited = current[problemIndex].description;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Edit ${current[problemIndex].serviceName} Description',
        ),
        content: TextFormField(
          initialValue: edited,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 800,
          onChanged: (value) => edited = value,
          decoration: const InputDecoration(
            hintText: 'Describe the problem...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              false,
            ),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              true,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    final latest = viewModel.draft.problemDetails;
    if (problemIndex >= latest.length) return;

    if (latest[problemIndex].serviceId == 'other_not_sure' &&
        edited.trim().isEmpty) {
      await showHomeAssistMessageDialog(
        context: context,
        title: 'Description Required',
        message:
        'Please describe the issue for Other / Not sure.',
        type: HomeAssistMessageType.warning,
      );
      return;
    }

    _updateProblem(
      problemIndex,
          (problem) => BookingProblemDraft(
        serviceId: problem.serviceId,
        serviceName: problem.serviceName,
        description: edited.trim(),
        photos: List<AttachmentModel>.from(problem.photos),
        isPrimary: problem.isPrimary,
      ),
    );
  }

  Future<void> _addPhotos(
      BuildContext context,
      int problemIndex,
      ) async {
    if (viewModel.isLoading) return;

    final current = viewModel.draft.problemDetails;
    if (problemIndex >= current.length) return;

    final remaining =
        5 - current[problemIndex].photos.length;

    if (remaining <= 0) return;

    try {
      final files = await ImagePicker().pickMultiImage(
        imageQuality: 80,
        limit: remaining,
      );

      if (!context.mounted || files.isEmpty) return;

      final attachments = <AttachmentModel>[];

      for (final file in files.take(remaining)) {
        attachments.add(
          AttachmentModel(
            name: file.name,
            bytes: await file.readAsBytes(),
            mimeType: file.mimeType,
          ),
        );
      }

      if (!context.mounted) return;

      _updateProblem(
        problemIndex,
            (problem) => BookingProblemDraft(
          serviceId: problem.serviceId,
          serviceName: problem.serviceName,
          description: problem.description,
          photos: [
            ...problem.photos,
            ...attachments.take(
              5 - problem.photos.length,
            ),
          ],
          isPrimary: problem.isPrimary,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to add booking photos: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!context.mounted) return;

      await showHomeAssistMessageDialog(
        context: context,
        title: 'Unable to Add Photos',
        message:
        'The selected photos could not be added. '
            'Please try again.',
        type: HomeAssistMessageType.error,
      );
    }
  }

  void _removePhoto(
      int problemIndex,
      int photoIndex,
      ) {
    if (viewModel.isLoading) return;

    _updateProblem(
      problemIndex,
          (problem) {
        final photos =
        List<AttachmentModel>.from(problem.photos);

        if (photoIndex >= 0 &&
            photoIndex < photos.length) {
          photos.removeAt(photoIndex);
        }

        return BookingProblemDraft(
          serviceId: problem.serviceId,
          serviceName: problem.serviceName,
          description: problem.description,
          photos: photos,
          isPrimary: problem.isPrimary,
        );
      },
    );
  }

  // =====================================================
  // FULL-SIZE PHOTO PREVIEW
  // =====================================================

  Future<void> _showPhotoPreview(
      BuildContext context,
      _ReviewPhoto entry,
      int photoNumber,
      int totalPhotos,
      ) async {
    await showDialog<void>(
      context: context,

      builder: (dialogContext) {
        final screenSize =
        MediaQuery.sizeOf(dialogContext);

        var replacing = false;

        return StatefulBuilder(
          builder: (
              dialogContext,
              setDialogState,
              ) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),

              clipBehavior: Clip.antiAlias,

              child: SizedBox(
                width: screenSize.width - 32,
                height: screenSize.height * 0.70,

                child: Column(
                  children: [
                    // =============================
                    // PHOTO PREVIEW HEADER
                    // =============================

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        8,
                        4,
                        8,
                      ),

                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Photo $photoNumber of $totalPhotos',

                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          IconButton(
                            tooltip: 'Close photo preview',

                            onPressed: replacing
                                ? null
                                : () {
                              Navigator.of(
                                dialogContext,
                              ).pop();
                            },

                            icon: const Icon(
                              Icons.close,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // =============================
                    // FULL-SIZE PHOTO
                    // =============================

                    Expanded(
                      child: Container(
                        color: Colors.black,
                        width: double.infinity,

                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,

                          child: Center(
                            child: Image.memory(
                              entry.photo.bytes,
                              fit: BoxFit.contain,

                              errorBuilder:
                                  (_, __, ___) => const Text(
                                'Unable to preview this photo.',

                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // =============================
                    // PHOTO INFORMATION AND EDIT
                    // =============================

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        10,
                        12,
                        12,
                      ),

                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                        children: [
                          Text(
                            '${entry.serviceName} • ${entry.photo.name}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,

                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 8),

                          OutlinedButton.icon(
                            onPressed:
                            replacing || viewModel.isLoading
                                ? null
                                : () async {
                              setDialogState(
                                    () => replacing = true,
                              );

                              final replaced =
                              await _replacePhoto(
                                dialogContext,
                                entry,
                              );

                              if (!dialogContext.mounted) {
                                return;
                              }

                              if (replaced) {
                                Navigator.of(
                                  dialogContext,
                                ).pop();
                              } else {
                                setDialogState(
                                      () => replacing = false,
                                );
                              }
                            },

                            icon: replacing
                                ? const SizedBox(
                              width: 18,
                              height: 18,

                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(
                              Icons.photo_library_outlined,
                            ),

                            label: Text(
                              replacing
                                  ? 'Opening Photos...'
                                  : 'Replace Photo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================
  // REPLACE SELECTED PHOTO
  // =====================================================

  Future<bool> _replacePhoto(
      BuildContext context,
      _ReviewPhoto entry,
      ) async {
    if (viewModel.isLoading) {
      return false;
    }

    try {
      // =============================================
      // PICK A REPLACEMENT PHOTO
      // =============================================

      final selectedFile =
      await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (selectedFile == null) {
        return false;
      }

      final newBytes =
      await selectedFile.readAsBytes();

      if (!context.mounted) {
        return false;
      }

      // =============================================
      // VALIDATE THE SELECTED PROBLEM
      // =============================================

      final currentProblems =
          viewModel.draft.problemDetails;

      if (entry.problemIndex >=
          currentProblems.length) {
        throw StateError(
          'The selected problem is no longer available.',
        );
      }

      final oldProblem =
      currentProblems[entry.problemIndex];

      if (entry.photoIndex >=
          oldProblem.photos.length) {
        throw StateError(
          'The selected attachment is no longer available.',
        );
      }

      // =============================================
      // REPLACE THE SELECTED PHOTO
      // =============================================

      final updatedPhotos =
      List<AttachmentModel>.from(
        oldProblem.photos,
      );

      updatedPhotos[entry.photoIndex] =
          AttachmentModel(
            name: selectedFile.name,
            bytes: newBytes,
            mimeType: selectedFile.mimeType,
          );

      // =============================================
      // UPDATE THE RELEVANT PROBLEM
      // =============================================

      final updatedProblems =
      List<BookingProblemDraft>.from(
        currentProblems,
      );

      updatedProblems[entry.problemIndex] =
          BookingProblemDraft(
            serviceId: oldProblem.serviceId,
            serviceName: oldProblem.serviceName,
            description: oldProblem.description,

            photos: List<AttachmentModel>.unmodifiable(
              updatedPhotos,
            ),

            isPrimary: oldProblem.isPrimary,
          );

      // =============================================
      // SAVE THE UPDATED DRAFT
      // =============================================

      viewModel.setProblemDetailsByProblem(
        problemDetails: updatedProblems,

        gasBrandPreference:
        viewModel.draft.gasBrandPreference,
      );

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to replace booking photo: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!context.mounted) {
        return false;
      }

      await showHomeAssistMessageDialog(
        context: context,
        title: 'Unable to Replace Photo',

        message:
        'The replacement photo could not be selected. '
            'Please try again.',

        type: HomeAssistMessageType.error,
      );

      return false;
    }
  }
}

// =====================================================
// PHOTO REVIEW HELPER
// =====================================================

// This helper class must remain outside
// BookingConfirmationPage.
class _ReviewPhoto {
  final int problemIndex;
  final int photoIndex;
  final AttachmentModel photo;
  final String serviceName;

  const _ReviewPhoto({
    required this.problemIndex,
    required this.photoIndex,
    required this.photo,
    required this.serviceName,
  });
}
