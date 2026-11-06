import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/attachment_model.dart';
import '../../../models/booking_problem_draft.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/customer_booking_viewmodel.dart';
import '../../../widgets/homeassist_action_dialog.dart';
import 'location_page.dart';

class ServiceProblemPage extends StatefulWidget {
  final CustomerBookingViewModel viewModel;

  const ServiceProblemPage({
    super.key,
    required this.viewModel,
  });

  @override
  State<ServiceProblemPage> createState() => _ServiceProblemPageState();
}

class _ServiceProblemPageState extends State<ServiceProblemPage> {
  static const String _otherIssueId = 'other_not_sure';
  static const String _otherIssueName = 'Other / Not sure';

  final ImagePicker _picker = ImagePicker();
  final List<_ProblemFormData> _problems = [];

  String? _gasBrand;

  bool get _gasSelected => widget.viewModel.selectedServices.any(
        (service) => service.supportsBrandPreference,
  );

  @override
  void initState() {
    super.initState();

    final selectedServices = widget.viewModel.selectedServices;
    final selectedServiceIds = selectedServices
        .map((service) => service.id)
        .toSet();
    final existingProblems = widget.viewModel.draft.problemDetails;

    // Restore an existing draft only if every problem still belongs
    // to the current service selection. This also protects against
    // stale drafts from an earlier booking flow.
    final canRestore = existingProblems.isNotEmpty &&
        existingProblems.every(
              (problem) => problem.serviceId == _otherIssueId ||
              selectedServiceIds.contains(problem.serviceId),
        );

    if (canRestore) {
      for (final problem in existingProblems) {
        _problems.add(
          _ProblemFormData(
            serviceId: problem.serviceId,
            serviceName: problem.serviceName,
            description: problem.description,
            photos: List.from(problem.photos),
            isPrimary: problem.isPrimary,
          ),
        );
      }
    } else {
      String? firstServiceId;
      String? firstServiceName;

      if (selectedServices.length == 1) {
        firstServiceId = selectedServices.first.id;
        firstServiceName = selectedServices.first.name;
      }

      _problems.add(
        _ProblemFormData(
          serviceId: firstServiceId,
          serviceName: firstServiceName,
          isPrimary: true,
        ),
      );
    }

    _gasBrand = widget.viewModel.draft.gasBrandPreference;
  }

  @override
  void dispose() {
    for (final problem in _problems) {
      problem.descriptionController.dispose();
    }
    super.dispose();
  }

  List<_ProblemOption> get _problemOptions {
    return [
      ...widget.viewModel.selectedServices.map(
            (service) => _ProblemOption(
          id: service.id,
          name: service.name,
        ),
      ),
      const _ProblemOption(
        id: _otherIssueId,
        name: _otherIssueName,
      ),
    ];
  }

  List<_ProblemOption> _availableOptions(int currentIndex) {
    final usedIds = <String>{};

    for (var i = 0; i < _problems.length; i++) {
      if (i == currentIndex) {
        continue;
      }
      final serviceId = _problems[i].serviceId;
      if (serviceId != null) {
        usedIds.add(serviceId);
      }
    }

    return _problemOptions
        .where((option) => !usedIds.contains(option.id))
        .toList();
  }

  bool get _canAddAnotherProblem {
    final selectedServiceIds = widget.viewModel.selectedServices
        .map((service) => service.id)
        .toSet();

    final usedServiceIds = _problems
        .map((problem) => problem.serviceId)
        .whereType<String>()
        .where((id) => id != _otherIssueId)
        .toSet();

    return selectedServiceIds.any((id) => !usedServiceIds.contains(id));
  }

  void _addAnotherProblem() {
    if (!_canAddAnotherProblem) {
      return;
    }

    setState(() {
      _problems.add(_ProblemFormData(isPrimary: false));
    });
  }

  void _removeProblem(int index) {
    if (index == 0) {
      return;
    }

    setState(() {
      final removed = _problems.removeAt(index);
      removed.descriptionController.dispose();
    });
  }

  void _changeProblem(int index, String? serviceId) {
    if (serviceId == null) {
      return;
    }

    final option = _problemOptions.firstWhere(
          (option) => option.id == serviceId,
    );

    setState(() {
      _problems[index].serviceId = option.id;
      _problems[index].serviceName = option.name;
    });
  }

  Future<void> _pickPhotos(int index) async {
    final problem = _problems[index];
    final remaining = 5 - problem.photos.length;

    if (remaining <= 0) {
      return;
    }

    final files = await _picker.pickMultiImage(
      imageQuality: 80,
      limit: remaining,
    );

    for (final file in files.take(remaining)) {
      problem.photos.add(
        AttachmentModel(
          name: file.name,
          bytes: await file.readAsBytes(),
          mimeType: file.mimeType,
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  // Show a consistent HomeAssist dialog before allowing navigation.
  // This method must be asynchronous because dialogs are awaited.
  Future<bool> _validateProblems() async {
    for (var i = 0; i < _problems.length; i++) {
      final problem = _problems[i];

      final matchingOptions = _availableOptions(i).where(
            (option) => option.id == problem.serviceId,
      );

      // Do not let a stale (or duplicate) service ID reach the ViewModel,
      // even if the dropdown displayed with a safe null initial value.
      if (problem.serviceId == null ||
          problem.serviceName == null ||
          matchingOptions.length != 1) {
        await showHomeAssistMessageDialog(
          context: context,
          title: 'Problem Selection Required',
          message: i == 0
              ? 'Please select the main problem before continuing.'
              : 'Please select the additional problem before continuing.',
          type: HomeAssistMessageType.warning,
        );
        return false;
      }

      if (problem.serviceId == _otherIssueId &&
          problem.descriptionController.text.trim().isEmpty) {
        await showHomeAssistMessageDialog(
          context: context,
          title: 'Problem Description Required',
          message: 'Please describe the problem when selecting '
              'Other / Not sure.',
          type: HomeAssistMessageType.warning,
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _continue() async {
    final valid = await _validateProblems();
    if (!mounted || !valid) {
      return;
    }

    final problemDetails = _problems.asMap().entries.map((entry) {
      final index = entry.key;
      final problem = entry.value;

      return BookingProblemDraft(
        serviceId: problem.serviceId!,
        serviceName: problem.serviceName!,
        description: problem.descriptionController.text.trim(),
        photos: List.unmodifiable(problem.photos),
        isPrimary: index == 0,
      );
    }).toList();

    widget.viewModel.setProblemDetailsByProblem(
      problemDetails: problemDetails,
      gasBrandPreference:
      _gasSelected ? (_gasBrand ?? 'No preference') : null,
    );

    // The ViewModel performs the authoritative service-ID validation.
    // Only navigate when that save succeeds.
    if (widget.viewModel.errorMessage != null) {
      if (!mounted) return;
      await showHomeAssistMessageDialog(
        context: context,
        title: 'Problem Details Need Updating',
        message: widget.viewModel.errorMessage!,
        type: HomeAssistMessageType.warning,
      );
      return;
    }
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPage(viewModel: widget.viewModel),
      ),
    );
  }

  Widget _buildProblemSection(int index) {
    final problem = _problems[index];
    final isPrimary = index == 0;
    final options = _availableOptions(index);
    final descriptionRequired = problem.serviceId == _otherIssueId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isPrimary ? 'Main Problem' : 'Additional Problem $index',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!isPrimary)
                  IconButton(
                    tooltip: 'Remove problem',
                    onPressed: () => _removeProblem(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: ValueKey('problem-$index-${problem.serviceId}'),
              // A saved dropdown value must exist exactly once among
              // the current options, otherwise Flutter throws an assertion.
              initialValue: options.where(
                    (option) => option.id == problem.serviceId,
              ).length == 1
                  ? problem.serviceId
                  : null,
              decoration: InputDecoration(
                labelText: isPrimary ? 'Main problem *' : 'Problem *',
              ),
              items: options
                  .map(
                    (option) => DropdownMenuItem(
                  value: option.id,
                  child: Text(option.name),
                ),
              )
                  .toList(),
              onChanged: (value) => _changeProblem(index, value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: problem.descriptionController,
              minLines: 4,
              maxLines: 7,
              maxLength: 800,
              decoration: InputDecoration(
                labelText: 'Problem details',
                hintText: 'Describe your problem if you\'re not sure, '
                    'or add any useful details.',
                alignLabelWithHint: true,
                helperText: descriptionRequired
                    ? 'Required for Other / Not sure.'
                    : 'Optional',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Problem Photos',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${problem.photos.length}/5',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: problem.photos.length >= 5
                  ? null
                  : () => _pickPhotos(index),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add Photos'),
            ),
            ...problem.photos.asMap().entries.map(
                  (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.image_outlined,
                  color: AppTheme.primary,
                ),
                title: Text(entry.value.name),
                trailing: IconButton(
                  onPressed: () {
                    setState(() {
                      problem.photos.removeAt(entry.key);
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Problem Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Tell the provider what is happening',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the main problem first. Add another problem '
                'only if separate details or photos are needed.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ..._problems.asMap().entries.map(
                (entry) => _buildProblemSection(entry.key),
          ),
          if (_canAddAnotherProblem) ...[
            OutlinedButton.icon(
              onPressed: _addAnotherProblem,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Problem'),
            ),
            const SizedBox(height: 18),
          ],
          if (_gasSelected) ...[
            DropdownButtonFormField<String>(
              initialValue: _gasBrand,
              decoration: const InputDecoration(
                labelText: 'Preferred gas brand',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'No preference',
                  child: Text('No preference'),
                ),
                DropdownMenuItem(
                  value: 'Petronas',
                  child: Text('Petronas'),
                ),
                DropdownMenuItem(
                  value: 'Petron',
                  child: Text('Petron'),
                ),
                DropdownMenuItem(
                  value: 'MyGaz',
                  child: Text('MyGaz'),
                ),
                DropdownMenuItem(
                  value: 'Other',
                  child: Text('Other'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _gasBrand = value;
                });
              },
            ),
            const SizedBox(height: 20),
          ],
          ElevatedButton(
            onPressed: _continue,
            child: const Text('Continue'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ProblemOption {
  final String id;
  final String name;

  const _ProblemOption({
    required this.id,
    required this.name,
  });
}

class _ProblemFormData {
  String? serviceId;
  String? serviceName;
  final bool isPrimary;
  final TextEditingController descriptionController;
  final List<AttachmentModel> photos;

  _ProblemFormData({
    this.serviceId,
    this.serviceName,
    String description = '',
    List<AttachmentModel> photos = const [],
    required this.isPrimary,
  })  : descriptionController = TextEditingController(text: description),
        photos = List.from(photos);
}
