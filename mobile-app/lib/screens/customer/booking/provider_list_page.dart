
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../viewmodels/customer_booking_viewmodel.dart';
import 'appointment_page.dart';
import 'provider_details_page.dart';
import 'customer_booking_status_page.dart';
import '../customer_navigation.dart';

class ProviderListPage extends StatelessWidget {
  final CustomerBookingViewModel viewModel;

  const ProviderListPage({
    super.key,
    required this.viewModel,
  });

  // =====================================================
  // START SEQUENTIAL BOOKING
  // =====================================================

  Future<void> _beginSeparateBookings(
      BuildContext context,
      ) async {
    if (!viewModel.startSeparateBookings()) {
      return;
    }

    // Remove the previous multi-service selection screens
    // from the current navigation flow.
    //
    // The new flow uses one service at a time while
    // preserving the original problem details and location.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ProviderListPage(
          viewModel: viewModel,
        ),
      ),
          (route) => route.isFirst,
    );

    // Find providers for the first individual service.
    await viewModel.findProviders();
  }

  // =====================================================
  // SKIP AN UNAVAILABLE SERVICE
  // =====================================================

  Future<void> _skipUnavailableService(
      BuildContext context,
      ) async {
    final service = viewModel.currentSeparateServiceName;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Skip this service?',
        ),
        content: Text(
          'No provider was found for $service. '
              'Skipping it will NOT create a booking for this service. '
              'You can still book it later.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                false,
              );
            },
            child: const Text(
              'Keep Searching',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                true,
              );
            },
            child: const Text(
              'Skip Service',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final hasNext =
    viewModel.skipUnavailableSeparateService();

    if (hasNext) {
      // Continue to the next remaining service.
      await viewModel.findProviders();
      return;
    }

    // All remaining services have been processed.
    final lastBooking =
        viewModel.lastSubmittedBookingId;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => lastBooking == null
            ? const CustomerNavigation(
          initialIndex: 1,
        )
            : CustomerBookingStatusPage(
          bookingId: lastBooking,
        ),
      ),
          (route) => route.isFirst,
    );
  }

  // =====================================================
  // SEQUENTIAL BOOKING INFORMATION
  // =====================================================

  Widget _separateInformationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking ${viewModel.separateBookingPosition} '
                  'of ${viewModel.separateBookingTotal}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Choose a provider for '
                  '${viewModel.currentSeparateServiceName}. '
                  'Your service address, problem description '
                  'and photos have been carried over.',
            ),

            if (viewModel.separateBookingsSubmitted > 0) ...[
              const SizedBox(height: 6),

              Text(
                '${viewModel.separateBookingsSubmitted} '
                    'booking(s) already submitted.',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =====================================================
  // MAIN PAGE
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        title: const Text(
          'Nearby Providers',
        ),
      ),

      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {

          // =============================================
          // LOADING PROVIDERS
          // =============================================

          if (viewModel.isLoading &&
              viewModel.providerMatches.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // =============================================
          // PROVIDER SEARCH ERROR
          // =============================================

          if (viewModel.errorMessage != null &&
              viewModel.providerMatches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      viewModel.errorMessage!,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton(
                      onPressed: viewModel.findProviders,
                      child: const Text(
                        'Retry Provider Search',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // =============================================
          // NO PROVIDERS FOUND
          // =============================================

          if (viewModel.providerMatches.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [

                // Show current booking progress if the
                // customer is booking services separately.
                if (viewModel.isSeparateBookingFlow)
                  _separateInformationCard(),

                const SizedBox(height: 24),

                const Icon(
                  Icons.search_off_outlined,
                  size: 46,
                  color: AppTheme.textSecondary,
                ),

                const SizedBox(height: 12),

                const Text(
                  'No suitable providers found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  viewModel.isSeparateBookingFlow
                      ? 'No nearby provider currently offers '
                      '${viewModel.currentSeparateServiceName}. '
                      'This problem has not been booked.'
                      : viewModel.canBookServicesSeparately
                      ? 'No single provider was found for all '
                      'of your selected services. '
                      'You can book them one at a time '
                      'without re-entering the location '
                      'or problems.'
                      : 'No nearby provider was found for '
                      'this service. You can return to '
                      'service selection or try again.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 18),

                // Allow customers to book each service
                // individually when no single provider
                // can handle all selected services.
                if (viewModel.canBookServicesSeparately)
                  ElevatedButton.icon(
                    onPressed: () {
                      _beginSeparateBookings(context);
                    },
                    icon: const Icon(
                      Icons.call_split,
                    ),
                    label: const Text(
                      'Book Services Separately',
                    ),
                  ),

                // If already in sequential booking mode,
                // allow skipping an unavailable service.
                if (viewModel.isSeparateBookingFlow) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      _skipUnavailableService(context);
                    },
                    icon: const Icon(
                      Icons.skip_next,
                    ),
                    label: Text(
                      viewModel.remainingSeparateBookings > 0
                          ? 'Skip This Service and Continue'
                          : 'Finish Without This Service',
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: viewModel.findProviders,
                  child: const Text(
                    'Retry Provider Search',
                  ),
                ),
              ],
            );
          }

          // =============================================
          // PROVIDERS AVAILABLE
          // =============================================

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [

              // =========================================
              // SEQUENTIAL BOOKING PROGRESS
              // =========================================

              if (viewModel.isSeparateBookingFlow) ...[
                _separateInformationCard(),

                const SizedBox(height: 12),
              ]

              // =========================================
              // OPTIONAL SEPARATE BOOKING
              // =========================================

              else if (viewModel.canBookServicesSeparately) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Need different providers?',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'These companies offer all selected '
                              'services. You can also book each '
                              'selected service with a different provider.',
                        ),

                        const SizedBox(height: 8),

                        OutlinedButton(
                          onPressed: () {
                            _beginSeparateBookings(context);
                          },
                          child: const Text(
                            'Book Services Separately',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],

              // =========================================
              // CUSTOMER SERVICE LOCATION
              // =========================================

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.primary,
                  ),
                  title: const Text(
                    'Service Location',
                  ),
                  subtitle: Text(
                    viewModel.draft.address,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =========================================
              // PROVIDER SECTION TITLE
              // =========================================

              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Suitable providers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  Text(
                    'Nearest first',
                    style: TextStyle(
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // =========================================
              // PROVIDER CARDS
              // =========================================

              ...viewModel.providerMatches
                  .asMap()
                  .entries
                  .map((entry) {

                final index = entry.key;
                final match = entry.value;

                final hasRating =
                    match.provider.reviewCount > 0;

                // =====================================
                // OPEN PROVIDER DETAILS
                // =====================================

                void openDetails() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderDetailsPage(
                        viewModel: viewModel,
                        providerIndex: index,
                      ),
                    ),
                  );
                }

                // =====================================
                // SELECT PROVIDER
                // =====================================

                Future<void> selectProvider() async {
                  viewModel.selectProvider(match);

                  await viewModel.loadAvailableSlots(
                    DateTime.now(),
                  );

                  if (!context.mounted) {
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppointmentPage(
                        viewModel: viewModel,
                      ),
                    ),
                  );
                }

                // =====================================
                // PROVIDER CARD UI
                // =====================================

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),

                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: openDetails,

                      child: Padding(
                        padding: const EdgeInsets.all(18),

                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [

                            // Provider business name.
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    match.provider.businessName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),

                                if (index == 0)
                                  const Chip(
                                    label: Text(
                                      'Nearest',
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            // Provider branch.
                            Text(
                              match.branch.name,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Provider distance and rating.
                            Text(
                              '${match.distanceKm.toStringAsFixed(1)} km away'
                                  ' · '
                                  '${hasRating ? '★ ${match.provider.rating.toStringAsFixed(1)} (${match.provider.reviewCount} reviews)' : 'No ratings yet'}',
                            ),

                            const SizedBox(height: 10),

                            // Provider branch location.
                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(
                                    top: 2,
                                  ),
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),

                                const SizedBox(width: 6),

                                Expanded(
                                  child: Text(
                                    match.branch.address
                                        .trim()
                                        .isEmpty
                                        ? 'Address not provided'
                                        : match.branch.address,
                                    maxLines: 2,
                                    overflow:
                                    TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      height: 1.35,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // View provider details.
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: openDetails,
                                icon: const Icon(
                                  Icons.info_outline_rounded,
                                ),
                                label: const Text(
                                  'View Details',
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Select provider and proceed to appointment.
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: selectProvider,
                                child: const Text(
                                  'Select Provider',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
