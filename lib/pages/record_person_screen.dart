import 'package:flutter/material.dart';
import 'package:nosql_application/services/couch_db_services.dart';

class RecordPersonScreen extends StatefulWidget {
  final CouchDBService couchDbService;
  final Map<String, dynamic>? person;

  const RecordPersonScreen({
    super.key,
    required this.couchDbService,
    this.person,
  });

  @override
  State<RecordPersonScreen> createState() => _RecordPersonScreenState();
}

class _RecordPersonScreenState extends State<RecordPersonScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _ageController;
  late final TextEditingController _yearBornController;

  bool _isSaving = false;

  bool get _isEditing => widget.person != null;

  @override
  void initState() {
    super.initState();

    final person = widget.person ?? {};

    _firstNameController = TextEditingController(
      text: person['first_name']?.toString() ?? '',
    );
    _lastNameController = TextEditingController(
      text: person['last_name']?.toString() ?? '',
    );
    _ageController = TextEditingController(
      text: person['age']?.toString() ?? '',
    );
    _yearBornController = TextEditingController(
      text: person['year_born']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _yearBornController.dispose();
    super.dispose();
  }

  Future<void> _savePerson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final document = <String, dynamic>{
        ...?widget.person,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'year_born': int.parse(_yearBornController.text.trim()),
      };

      await widget.couchDbService.savePerson(document);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Person updated' : 'Person added')),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save person: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter $label';
    }
    return null;
  }

  String? _validateInteger(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter $label';
    }
    if (int.tryParse(value.trim()) == null) {
      return '$label must be a whole number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Person' : 'Add Person'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.06 * 255).round()),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    _isEditing
                        ? Icons.edit_note_rounded
                        : Icons.person_add_alt_1_rounded,
                    size: 42,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'First name'),
                    validator: (value) => _requiredText(value, 'a first name'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Last name'),
                    validator: (value) => _requiredText(value, 'a last name'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age'),
                    validator: (value) => _validateInteger(value, 'Age'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _yearBornController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Year born'),
                    validator: (value) => _validateInteger(value, 'Year born'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _savePerson,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isEditing ? Icons.save_rounded : Icons.add_rounded,
                          ),
                    label: Text(_isEditing ? 'Update Person' : 'Add Person'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
