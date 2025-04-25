import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/prescription_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../components/layout/responsive_container.dart';
import '../../components/medication/medication_dose_form.dart';

class MedicationTimeAppealForm extends StatefulWidget {
  final String prescriptionId;
  final String medicationId;
  final Medication medication;
  final Function() onAppealSubmitted;

  const MedicationTimeAppealForm({
    super.key,
    required this.prescriptionId,
    required this.medicationId,
    required this.medication,
    required this.onAppealSubmitted,
  });

  @override
  State<MedicationTimeAppealForm> createState() => _MedicationTimeAppealFormState();
}

class _MedicationTimeAppealFormState extends State<MedicationTimeAppealForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  List<MedicationDose> _suggestedDoses = [];
  bool _isLoading = false;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    // Start with the current doses
    _suggestedDoses = List.from(widget.medication.doses);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitAppeal() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final appeal = MedicationTimeAppeal(
          id: 'appeal_${DateTime.now().millisecondsSinceEpoch}',
          requestedAt: DateTime.now(),
          reason: _reasonController.text,
          suggestedDoses: _suggestedDoses,
          status: 'pending',
        );

        await _databaseService.submitMedicationTimeAppeal(
          widget.prescriptionId,
          widget.medicationId,
          appeal,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Time change request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onAppealSubmitted();
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting time change request: $e'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Time Change'),
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveContainer(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Request Time Change for ${widget.medication.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Time Change',
                  hintText: 'Please explain why you need to change the medication times',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide a reason for the time change request';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Suggest New Times',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              MedicationDoseForm(
                initialDoses: widget.medication.doses,
                onDosesChanged: (doses) {
                  _suggestedDoses = doses;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitAppeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
