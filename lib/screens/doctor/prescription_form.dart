import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/prescription_model.dart';
import '../../components/layout/responsive_container.dart';
import '../../components/medication/medication_dose_form.dart';

class PrescriptionForm extends StatefulWidget {
  final String patientId;
  final PrescriptionModel? existingPrescription;

  const PrescriptionForm({
    super.key, 
    required this.patientId,
    this.existingPrescription,
  });

  @override
  State<PrescriptionForm> createState() => _PrescriptionFormState();
}

class _PrescriptionFormState extends State<PrescriptionForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final List<MedicationFormData> _medications = [];
  bool _isLoading = false;
  
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    
    if (widget.existingPrescription != null) {
      // Populate form with existing prescription data
      _notesController.text = widget.existingPrescription!.notes;
      
      // Convert existing medications to form data
      for (var medication in widget.existingPrescription!.medications) {
        _medications.add(MedicationFormData(
          existingMedication: medication,
        ));
      }
    } else {
      // Add an initial empty medication
      _addMedication();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (var medication in _medications) {
      medication.dispose();
    }
    super.dispose();
  }

  void _addMedication() {
    setState(() {
      _medications.add(MedicationFormData());
    });
  }

  void _removeMedication(int index) {
    setState(() {
      _medications[index].dispose();
      _medications.removeAt(index);
    });
  }

  Future<void> _savePrescription() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final doctorId = authService.currentUser!.id;
        
        final medications = _medications.map((medicationData) {
          return Medication(
            id: medicationData.existingMedication?.id ?? 
                DateTime.now().millisecondsSinceEpoch.toString() + medicationData.hashCode.toString(),
            name: medicationData.nameController.text,
            dosage: medicationData.dosageController.text,
            frequency: medicationData.frequencyController.text,
            startDate: medicationData.startDate,
            endDate: medicationData.endDate,
            adherence: medicationData.existingMedication?.adherence ?? {},
            adherenceTimes: medicationData.existingMedication?.adherenceTimes ?? {},
            doses: medicationData.doses,
            timeAppeal: medicationData.existingMedication?.timeAppeal,
            notificationLeadTime: medicationData.notificationLeadTime ?? 30,
          );
        }).toList();
        
        if (widget.existingPrescription != null) {
          // Update existing prescription
          final updatedPrescription = PrescriptionModel(
            id: widget.existingPrescription!.id,
            doctorId: doctorId,
            patientId: widget.patientId,
            createdAt: widget.existingPrescription!.createdAt,
            notes: _notesController.text,
            medications: medications,
          );
          
          await _databaseService.updatePrescription(updatedPrescription);
          
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prescription updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Create new prescription
          final prescription = PrescriptionModel(
            id: '',
            doctorId: doctorId,
            patientId: widget.patientId,
            createdAt: DateTime.now(),
            notes: _notesController.text,
            medications: medications,
          );
          
          await _databaseService.addPrescription(prescription);
          
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prescription added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving prescription: $e'),
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
        title: Text(widget.existingPrescription != null ? 'Edit Prescription' : 'New Prescription'),
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveContainer(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Add any notes or instructions for the patient',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Medications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...List.generate(_medications.length, (index) {
                return _buildMedicationForm(index);
              }),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _addMedication,
                icon: const Icon(Icons.add),
                label: const Text('Add Medication'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _savePrescription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.existingPrescription != null ? 'Update Prescription' : 'Save Prescription'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationForm(int index) {
    final medication = _medications[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medication ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_medications.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeMedication(index),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: medication.nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter medication name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: medication.dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 500mg',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter dosage';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: medication.frequencyController,
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Twice daily',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter frequency';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Duration',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: medication.startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          medication.startDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        '${medication.startDate.day}/${medication.startDate.month}/${medication.startDate.year}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: medication.endDate,
                        firstDate: medication.startDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          medication.endDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        '${medication.endDate.day}/${medication.endDate.month}/${medication.endDate.year}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            MedicationDoseForm(
              initialDoses: medication.doses,
              onDosesChanged: (doses) {
                medication.doses = doses;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              decoration: const InputDecoration(
                labelText: 'Default Notification Time',
                border: OutlineInputBorder(),
              ),
              value: medication.notificationLeadTime,
              items: [
                DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                DropdownMenuItem(value: 60, child: Text('1 hour before')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    medication.notificationLeadTime = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MedicationFormData {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController frequencyController = TextEditingController();
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 7));
  List<MedicationDose> doses = [];
  int? notificationLeadTime = 30;
  final Medication? existingMedication;

  MedicationFormData({this.existingMedication}) {
    if (existingMedication != null) {
      nameController.text = existingMedication!.name;
      dosageController.text = existingMedication!.dosage;
      frequencyController.text = existingMedication!.frequency;
      startDate = existingMedication!.startDate;
      endDate = existingMedication!.endDate;
      doses = List.from(existingMedication!.doses);
      notificationLeadTime = existingMedication!.notificationLeadTime;
    } else {
      // Create a default dose at 8:00 AM
      doses = [
        MedicationDose(
          id: 'dose_${DateTime.now().millisecondsSinceEpoch}',
          time: const TimeOfDay(hour: 8, minute: 0),
          quantity: 1,
        )
      ];
    }
  }

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
  }
}
