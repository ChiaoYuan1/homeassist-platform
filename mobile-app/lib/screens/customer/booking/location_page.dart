import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/customer_booking_viewmodel.dart';
import 'provider_list_page.dart';

class LocationPage extends StatefulWidget {
  final CustomerBookingViewModel viewModel;

  const LocationPage({
    super.key,
    required this.viewModel,
  });

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final _address = TextEditingController();

  bool _usingCurrentLocation = false;
  String _lastResolvedAddress = '';

  @override
  void initState() {
    super.initState();

    if (widget.viewModel.draft.address.isNotEmpty) {
      _address.text = widget.viewModel.draft.address;
      _lastResolvedAddress = widget.viewModel.draft.address;

      _usingCurrentLocation =
          widget.viewModel.draft.latitude != null &&
              widget.viewModel.draft.longitude != null;
    }

    _address.addListener(_handleAddressChanged);
  }

  @override
  void dispose() {
    _address.removeListener(_handleAddressChanged);
    _address.dispose();
    super.dispose();
  }

  void _handleAddressChanged() {
    if (_address.text.trim() != _lastResolvedAddress.trim()) {
      _usingCurrentLocation = false;
    }
  }

  Future<void> _current() async {
    await widget.viewModel.useCurrentLocation();

    if (!mounted) return;

    if (
    widget.viewModel.draft.address.isNotEmpty &&
        widget.viewModel.draft.latitude != null &&
        widget.viewModel.draft.longitude != null
    ) {
      _lastResolvedAddress =
          widget.viewModel.draft.address;

      _usingCurrentLocation = true;

      _address.text =
          widget.viewModel.draft.address;
    }
  }

  Future<void> _continue() async {
    final address = _address.text.trim();

    if (address.isEmpty) return;

    if (!_usingCurrentLocation) {
      final ok = await widget.viewModel
          .setAddressAndGeocode(address);

      if (!ok) return;

      _lastResolvedAddress =
          widget.viewModel.draft.address;
    }

    await widget.viewModel.findProviders();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderListPage(
          viewModel: widget.viewModel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Service Location'),
    ),
    body: ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Where is the service needed?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use the current device location or enter the address where the service is required. Nearby providers are ranked using this location.',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _address,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Service address *',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed:
              widget.viewModel.isLoading
                  ? null
                  : _current,
              icon: const Icon(
                Icons.my_location,
              ),
              label: const Text(
                'Use Current Location',
              ),
            ),
            if (widget.viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                ),
                child: Text(
                  widget.viewModel.errorMessage!,
                  style: const TextStyle(
                    color: AppTheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 26),
            ElevatedButton(
              onPressed:
              widget.viewModel.isLoading
                  ? null
                  : _continue,
              child: Text(
                widget.viewModel.isLoading
                    ? 'Finding Providers...'
                    : 'Find Nearby Providers',
              ),
            ),
          ],
        );
      },
    ),
  );
}
