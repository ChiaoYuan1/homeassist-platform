import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/input_validators.dart';
import '../../models/attachment_model.dart';
import '../../models/provider_application_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/provider_registration_viewmodel.dart';

class ProviderRegistrationPage extends StatefulWidget {
  const ProviderRegistrationPage({super.key});

  @override
  State<ProviderRegistrationPage> createState() =>
      _ProviderRegistrationPageState();
}

class _ProviderRegistrationPageState extends State<ProviderRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _viewModel = ProviderRegistrationViewModel();

  final _businessNameController = TextEditingController();
  final _ssmNumberController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  final _stRegistrationController = TextEditingController();
  final _kpdnLicenceController = TextEditingController();

  String _businessType = 'sole_proprietorship';
  DateTime? _registrationDate;
  DateTime? _registrationExpiryDate;
  DateTime? _stExpiryDate;
  DateTime? _kpdnExpiryDate;

  bool get _requiresSsmExpiry =>
      _businessType == 'sole_proprietorship' || _businessType == 'partnership';

  @override
  void initState() {
    super.initState();
    _viewModel.loadCategories();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ssmNumberController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _stRegistrationController.dispose();
    _kpdnLicenceController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate({DateTime? initialDate}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 10),
    );
  }

  Future<AttachmentModel?> _pickAttachment() async {
    final file = await FilePicker.pickFile();

    if (file == null) {
      return null;
    }

    final extension = (file.extension ?? '').toLowerCase();
    const allowed = {'pdf', 'jpg', 'jpeg', 'png'};

    if (!allowed.contains(extension)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload a PDF, JPG, JPEG or PNG file.'),
          ),
        );
      }
      return null;
    }

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The selected file is empty.')),
        );
      }
      return null;
    }

    return AttachmentModel(
      name: file.name,
      bytes: bytes,
      mimeType: switch (extension) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        _ => 'image/jpeg',
      },
    );
  }

  Future<void> _uploadSsmDocument() async {
    final error = InputValidators.ssmRegistrationNumber(
      _ssmNumberController.text,
      businessType: _businessType,
    );

    if (error != null) {
      _showMessage(error);
      return;
    }

    if (_registrationDate == null) {
      _showMessage('Select the SSM registration date first.');
      return;
    }

    if (_requiresSsmExpiry && _registrationExpiryDate == null) {
      _showMessage('Select the SSM registration expiry date first.');
      return;
    }

    final attachment = await _pickAttachment();
    if (attachment == null) return;

    _viewModel.upsertDocument(
      PendingVerificationDocument(
        label: 'SSM Business Registration',
        authority: 'Suruhanjaya Syarikat Malaysia (SSM)',
        documentType: 'ssm_registration',
        attachment: attachment,
        registrationNumber:
        InputValidators.digitsOnly(_ssmNumberController.text),
        expiryDate: _registrationExpiryDate,
      ),
    );
  }

  Future<void> _uploadElectricalDocument() async {
    final error = InputValidators.credentialNumber(
      _stRegistrationController.text,
      label: 'ST registration number',
    );

    if (error != null) {
      _showMessage(error);
      return;
    }

    if (_stExpiryDate == null) {
      _showMessage('Select the electrical credential expiry date first.');
      return;
    }

    final attachment = await _pickAttachment();
    if (attachment == null) return;

    _viewModel.upsertDocument(
      PendingVerificationDocument(
        label: 'Electrical Contractor / Competency Registration',
        authority: 'Suruhanjaya Tenaga (ST)',
        documentType: 'st_electrical_contractor',
        serviceCategoryId: 'electrical',
        attachment: attachment,
        registrationNumber: _stRegistrationController.text.trim(),
        expiryDate: _stExpiryDate,
      ),
    );
  }

  Future<void> _uploadGasDocument() async {
    final error = InputValidators.credentialNumber(
      _kpdnLicenceController.text,
      label: 'KPDN licence number',
    );

    if (error != null) {
      _showMessage(error);
      return;
    }

    if (_kpdnExpiryDate == null) {
      _showMessage('Select the LPG licence expiry date first.');
      return;
    }

    final attachment = await _pickAttachment();
    if (attachment == null) return;

    _viewModel.upsertDocument(
      PendingVerificationDocument(
        label: 'LPG Controlled Goods Licence / Supporting Document',
        authority: 'Kementerian Perdagangan Dalam Negeri (KPDN)',
        documentType: 'kpdn_lpg_licence',
        serviceCategoryId: 'gas_replacement',
        attachment: attachment,
        registrationNumber: _kpdnLicenceController.text.trim(),
        expiryDate: _kpdnExpiryDate,
      ),
    );
  }

  Future<void> _submitApplication() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_registrationDate == null) {
      _showMessage('Please select the SSM registration date.');
      return;
    }

    if (_requiresSsmExpiry && _registrationExpiryDate == null) {
      _showMessage('Please select the SSM registration expiry date.');
      return;
    }

    final success = await _viewModel.submit(
      businessName: _businessNameController.text.trim(),
      businessType: _businessType,
      registrationNumber:
      InputValidators.digitsOnly(_ssmNumberController.text),
      registrationDate: _registrationDate!,
      registrationExpiryDate: _registrationExpiryDate,
      contactName: _contactNameController.text.trim(),
      phone: InputValidators.normalizeMalaysiaMobile(_phoneController.text),
      email: _emailController.text.trim(),
      businessAddress: _addressController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted for admin review.'),
        ),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Select date';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _businessTypeLabel(String value) {
    return switch (value) {
      'sole_proprietorship' => 'Sole Proprietorship',
      'partnership' => 'Partnership',
      'company' => 'Company (e.g. Sdn. Bhd.)',
      'llp' => 'Limited Liability Partnership (LLP)',
      _ => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Service Provider Registration',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(),
                        const SizedBox(height: 20),
                        _businessSection(),
                        const SizedBox(height: 18),
                        _serviceSection(),
                        const SizedBox(height: 18),
                        _verificationSection(),
                        const SizedBox(height: 18),
                        if (_viewModel.errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _viewModel.errorMessage!,
                              style: const TextStyle(color: AppTheme.error),
                            ),
                          ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: _viewModel.isLoading
                              ? null
                              : _submitApplication,
                          child: _viewModel.isLoading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text('Submit for Verification'),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: AppTheme.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provider Verification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Business and service credentials are reviewed by an '
                      'administrator before provider access is approved.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _businessSection() {
    return _sectionCard(
      icon: Icons.business_outlined,
      title: '1. Business Information',
      subtitle: 'Enter details exactly as shown on the SSM record.',
      children: [
        _field(
          controller: _businessNameController,
          label: 'Registered Business / Company Name *',
          validator: (value) => InputValidators.requiredText(
            value,
            label: 'Business name',
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: _businessType,
          decoration: const InputDecoration(labelText: 'Business Type *'),
          items: const [
            'sole_proprietorship',
            'partnership',
            'company',
            'llp',
          ]
              .map(
                (value) => DropdownMenuItem(
              value: value,
              child: Text(_businessTypeLabel(value)),
            ),
          )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _businessType = value;
              if (!_requiresSsmExpiry) {
                _registrationExpiryDate = null;
              }
            });
          },
        ),
        const SizedBox(height: 12),
        _field(
          controller: _ssmNumberController,
          label: 'SSM Registration Number (12 digits) *',
          hint: 'Example format: 202603000001',
          keyboardType: TextInputType.number,
          validator: (value) => InputValidators.ssmRegistrationNumber(
            value,
            businessType: _businessType,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _dateButton(
                label: 'Registration Date *',
                value: _registrationDate,
                onTap: () async {
                  final date = await _pickDate(initialDate: _registrationDate);
                  if (date != null && mounted) {
                    setState(() => _registrationDate = date);
                  }
                },
              ),
            ),
            if (_requiresSsmExpiry) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _dateButton(
                  label: 'Registration Expiry *',
                  value: _registrationExpiryDate,
                  onTap: () async {
                    final date = await _pickDate(
                      initialDate: _registrationExpiryDate,
                    );
                    if (date != null && mounted) {
                      setState(() => _registrationExpiryDate = date);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _field(
          controller: _contactNameController,
          label: 'Contact Person *',
          validator: (value) => InputValidators.requiredText(
            value,
            label: 'Contact person',
          ),
        ),
        _field(
          controller: _phoneController,
          label: 'Malaysian Mobile Number *',
          hint: '0123456789 or +60123456789',
          keyboardType: TextInputType.phone,
          validator: InputValidators.malaysiaMobile,
        ),
        _field(
          controller: _emailController,
          label: 'Business Email *',
          keyboardType: TextInputType.emailAddress,
          validator: InputValidators.email,
        ),
        _field(
          controller: _addressController,
          label: 'Registered / Business Address *',
          maxLines: 3,
          validator: (value) => InputValidators.requiredText(
            value,
            label: 'Business address',
          ),
        ),
      ],
    );
  }

  Widget _serviceSection() {
    return _sectionCard(
      icon: Icons.home_repair_service_outlined,
      title: '2. Services Offered',
      subtitle: 'Select the categories and specific services offered.',
      children: [
        if (_viewModel.isLoading && _viewModel.categories.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_viewModel.categories.isEmpty)
          const Text(
            'No service categories are available yet. Seed the Firestore '
                'service catalogue first.',
            style: TextStyle(color: AppTheme.textSecondary),
          )
        else
          ..._viewModel.categories.map((category) {
            final selected =
            _viewModel.selectedCategoryIds.contains(category.id);
            final services =
                _viewModel.servicesByCategory[category.id] ?? const [];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: selected,
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(category.description),
                    onChanged: (value) {
                      _viewModel.toggleCategory(
                        categoryId: category.id,
                        selected: value ?? false,
                      );
                    },
                  ),
                  if (selected)
                    ...services.map(
                          (service) => Padding(
                        padding: const EdgeInsets.only(left: 18, right: 8),
                        child: CheckboxListTile(
                          value: _viewModel.selectedServiceIds
                              .contains(service.id),
                          title: Text(service.name),
                          subtitle: Text(
                            'Default duration: '
                                '${service.defaultDurationMinutes} minutes',
                          ),
                          onChanged: (value) {
                            _viewModel.toggleService(
                              service.id,
                              value ?? false,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _verificationSection() {
    final electricalSelected =
    _viewModel.selectedCategoryIds.contains('electrical');
    final gasSelected =
    _viewModel.selectedCategoryIds.contains('gas_replacement');

    return _sectionCard(
      icon: Icons.fact_check_outlined,
      title: '3. Verification Documents',
      subtitle:
      'Upload the document and enter credential details exactly as printed.',
      children: [
        _credentialCard(
          title: 'SSM Business Registration *',
          authority: 'Suruhanjaya Syarikat Malaysia (SSM)',
          description:
          'Required for every service provider. Upload the current '
              'business registration/profile document.',
          uploaded: _viewModel.hasDocument('ssm_registration'),
          onUpload: _uploadSsmDocument,
        ),
        if (electricalSelected) ...[
          const SizedBox(height: 12),
          _credentialCard(
            title: 'Electrical Credential *',
            authority: 'Suruhanjaya Tenaga (ST)',
            description:
            'Enter the contractor/competency registration number exactly '
                'as shown on the ST document.',
            uploaded: _viewModel.hasDocument(
              'st_electrical_contractor',
              serviceCategoryId: 'electrical',
            ),
            extraChildren: [
              _field(
                controller: _stRegistrationController,
                label: 'ST Registration / Certificate Number *',
                validator: electricalSelected
                    ? (value) => InputValidators.credentialNumber(
                  value,
                  label: 'ST registration number',
                )
                    : null,
              ),
              _dateButton(
                label: 'Credential Expiry Date *',
                value: _stExpiryDate,
                onTap: () async {
                  final date = await _pickDate(initialDate: _stExpiryDate);
                  if (date != null && mounted) {
                    setState(() => _stExpiryDate = date);
                  }
                },
              ),
            ],
            onUpload: _uploadElectricalDocument,
          ),
        ],
        if (gasSelected) ...[
          const SizedBox(height: 12),
          _credentialCard(
            title: 'LPG Supply Credential *',
            authority: 'Kementerian Perdagangan Dalam Negeri (KPDN)',
            description:
            'For LPG cylinder supply/replacement, enter the relevant '
                'licence number exactly as shown on the current document.',
            uploaded: _viewModel.hasDocument(
              'kpdn_lpg_licence',
              serviceCategoryId: 'gas_replacement',
            ),
            extraChildren: [
              _field(
                controller: _kpdnLicenceController,
                label: 'KPDN Licence Number *',
                validator: gasSelected
                    ? (value) => InputValidators.credentialNumber(
                  value,
                  label: 'KPDN licence number',
                )
                    : null,
              ),
              _dateButton(
                label: 'Licence Expiry Date *',
                value: _kpdnExpiryDate,
                onTap: () async {
                  final date = await _pickDate(initialDate: _kpdnExpiryDate);
                  if (date != null && mounted) {
                    setState(() => _kpdnExpiryDate = date);
                  }
                },
              ),
            ],
            onUpload: _uploadGasDocument,
          ),
        ],
        if (_viewModel.documents.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'Attached Documents',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ..._viewModel.documents.map(
                (document) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(
                  Icons.description_outlined,
                  color: AppTheme.primary,
                ),
              ),
              title: Text(document.label),
              subtitle: Text(
                '${document.authority}\n${document.attachment.name}',
              ),
              trailing: IconButton(
                tooltip: 'Remove',
                onPressed: () => _viewModel.removeDocument(document),
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _credentialCard({
    required String title,
    required String authority,
    required String description,
    required bool uploaded,
    required VoidCallback onUpload,
    List<Widget> extraChildren = const [],
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (uploaded)
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                    SizedBox(width: 5),
                    Text(
                      'Uploaded',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            authority,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          if (extraChildren.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...extraChildren,
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(uploaded ? 'Replace Document' : 'Upload Document'),
          ),
        ],
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          _formatDate(value),
          style: TextStyle(
            color: value == null
                ? AppTheme.textSecondary
                : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }
}
