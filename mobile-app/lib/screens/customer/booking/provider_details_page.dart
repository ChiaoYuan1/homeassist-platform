import 'package:flutter/material.dart';

import '../../../services/app_services.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/customer_booking_viewmodel.dart';
import 'appointment_page.dart';

class ProviderDetailsPage
    extends StatefulWidget {
  final CustomerBookingViewModel viewModel;
  final int providerIndex;

  const ProviderDetailsPage({
    super.key,
    required this.viewModel,
    required this.providerIndex,
  });

  @override
  State<ProviderDetailsPage> createState() =>
      _ProviderDetailsPageState();
}

class _ProviderDetailsPageState
    extends State<ProviderDetailsPage> {
  bool _loadingTechnicians = true;
  bool _selecting = false;

  List<dynamic> _technicians = [];

  String? _technicianError;

  @override
  void initState() {
    super.initState();

    _loadTechnicians();
  }

  Future<void> _loadTechnicians() async {
    final match =
    widget.viewModel.providerMatches[
    widget.providerIndex];

    try {
      final technicians =
      await AppServices.technician
          .getQualifiedActiveTechnicians(
        providerId: match.provider.id,
        serviceIds:
        widget.viewModel.draft.serviceIds,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _technicians = technicians;
        _loadingTechnicians = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingTechnicians = false;
        _technicianError =
        'Unable to load technician information.';
      });
    }
  }

  Future<void> _selectProvider() async {
    if (_selecting) {
      return;
    }

    final match =
    widget.viewModel.providerMatches[
    widget.providerIndex];

    setState(() {
      _selecting = true;
    });

    try {
      widget.viewModel.selectProvider(
        match,
      );

      await widget.viewModel
          .loadAvailableSlots(
        DateTime.now(),
      );

      if (!mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AppointmentPage(
                viewModel:
                widget.viewModel,
              ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _selecting = false;
        });
      }
    }
  }

  String _formatServiceName(
      String serviceId,
      ) {
    return serviceId
        .trim()
        .replaceAll(
      '_',
      ' ',
    )
        .split(' ')
        .where(
          (word) =>
      word.isNotEmpty,
    )
        .map(
          (word) =>
      '${word[0].toUpperCase()}'
          '${word.substring(1)}',
    )
        .join(' ');
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final match =
    widget.viewModel.providerMatches[
    widget.providerIndex];

    final provider =
        match.provider;

    final branch =
        match.branch;

    final hasRating =
        provider.rating > 0;

    return Scaffold(
      backgroundColor:
      AppTheme.background,

      appBar: AppBar(
        title: const Text(
          'Provider Details',
        ),
      ),

      body: ListView(
        padding:
        const EdgeInsets.all(
          20,
        ),

        children: [
          Card(
            child: Padding(
              padding:
              const EdgeInsets.all(
                20,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration:
                        BoxDecoration(
                          color:
                          AppTheme.primary
                              .withValues(
                            alpha: 0.10,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            14,
                          ),
                        ),
                        child: const Icon(
                          Icons
                              .business_outlined,
                          color:
                          AppTheme.primary,
                        ),
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              provider
                                  .businessName,
                              style:
                              const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                FontWeight
                                    .w800,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              branch.name,
                              style:
                              const TextStyle(
                                color:
                                AppTheme
                                    .textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .location_on_outlined,
                        size: 19,
                        color:
                        AppTheme.primary,
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Expanded(
                        child: Text(
                          '${match.distanceKm.toStringAsFixed(1)} km from your service location',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Row(
                    children: [
                      Icon(
                        hasRating
                            ? Icons
                            .star_rounded
                            : Icons
                            .star_outline_rounded,
                        size: 19,
                        color:
                        hasRating
                            ? AppTheme
                            .primary
                            : AppTheme
                            .textSecondary,
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Text(
                        hasRating
                            ? 'Rating ${provider.rating.toStringAsFixed(1)}'
                            : 'No ratings yet',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Card(
            child: Padding(
              padding:
              const EdgeInsets.all(
                18,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [
                  const Text(
                    'Branch Information',
                    style:
                    TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  const Text(
                    'Branch',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    branch.name,
                    style:
                    const TextStyle(
                      color:
                      AppTheme
                          .textSecondary,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  const Text(
                    'Address',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    branch.address
                        .trim()
                        .isEmpty
                        ? 'Address not provided'
                        : branch.address,
                    style:
                    const TextStyle(
                      color:
                      AppTheme
                          .textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Card(
            child: Padding(
              padding:
              const EdgeInsets.all(
                18,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [
                  const Text(
                    'Services for This Booking',
                    style:
                    TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                    widget
                        .viewModel
                        .draft
                        .serviceIds
                        .map(
                          (serviceId) {
                        return Chip(
                          label: Text(
                            _formatServiceName(
                              serviceId,
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Card(
            child: Padding(
              padding:
              const EdgeInsets.all(
                18,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [
                  const Text(
                    'Qualified Technicians',
                    style:
                    TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  const Text(
                    'Technicians shown here are qualified for the selected service. The actual technician is assigned when the booking is confirmed.',
                    style:
                    TextStyle(
                      color:
                      AppTheme
                          .textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  if (_loadingTechnicians)
                    const Center(
                      child:
                      Padding(
                        padding:
                        EdgeInsets.all(
                          12,
                        ),
                        child:
                        CircularProgressIndicator(),
                      ),
                    )
                  else if (
                  _technicianError !=
                      null
                  )
                    Text(
                      _technicianError!,
                      style:
                      const TextStyle(
                        color:
                        AppTheme.error,
                      ),
                    )
                  else if (
                    _technicians.isEmpty
                    )
                      const Text(
                        'No qualified technician information is currently available.',
                        style:
                        TextStyle(
                          color:
                          AppTheme
                              .textSecondary,
                        ),
                      )
                    else
                      ..._technicians.map(
                            (
                            technician,
                            ) {
                          return Padding(
                            padding:
                            const EdgeInsets
                                .only(
                              bottom: 12,
                            ),

                            child: Container(
                              padding:
                              const EdgeInsets
                                  .all(
                                14,
                              ),
                              decoration:
                              BoxDecoration(
                                color:
                                AppTheme.primary
                                    .withValues(
                                  alpha: 0.04,
                                ),
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  14,
                                ),
                              ),

                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                    AppTheme
                                        .primary
                                        .withValues(
                                      alpha:
                                      0.10,
                                    ),
                                    child:
                                    const Icon(
                                      Icons
                                          .engineering_outlined,
                                      color:
                                      AppTheme
                                          .primary,
                                    ),
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
                                        Text(
                                          technician
                                              .name ??
                                              'Technician',
                                          style:
                                          const TextStyle(
                                            fontWeight:
                                            FontWeight
                                                .w700,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 4,
                                        ),

                                        const Text(
                                          'Qualified for the selected service',
                                          style:
                                          TextStyle(
                                            color:
                                            AppTheme
                                                .textSecondary,
                                            fontSize:
                                            12.5,
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
                      ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          ElevatedButton(
            onPressed:
            _selecting
                ? null
                : _selectProvider,

            child: Text(
              _selecting
                  ? 'Loading...'
                  : 'Select This Provider',
            ),
          ),

          const SizedBox(
            height: 28,
          ),
        ],
      ),
    );
  }
}