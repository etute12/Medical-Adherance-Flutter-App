import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../models/prescription_model.dart';
import '../../components/medication/medication_item.dart';
import '../../components/common/loading_indicator.dart';
import '../../components/common/empty_state.dart';
import '../../components/layout/responsive_container.dart';
import 'medication_time_appeal_form.dart';

class MedicationList extends StatefulWidget {
  const MedicationList({super.key});

  @override
  State<MedicationList> createState() => _MedicationListState();
}

class _MedicationListState extends State<MedicationList> {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  List<PrescriptionModel> _prescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final patientId = authService.currentUser!.id;
      final prescriptions = await _databaseService.getPatientPrescriptions(patientId);
      
      setState(() {
        _prescriptions = prescriptions;
        _isLoading = false;
      });
      
      // Schedule notifications for all medications
      await _notificationService.scheduleAllMedications(prescriptions);
    } catch (e) {
      print('Error loading medications: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading medications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleMedicationDose(
    String prescriptionId,
    String medicationId,
    String doseId,
    bool currentValue,
  ) async {
    try {
      await _databaseService.updateMedicationAdherence(
        prescriptionId,
        medicationId,
        doseId,
        !currentValue,
      );
      
      // If marking as not taken, schedule a missed medication reminder
      if (currentValue) {
        // Find the medication
        final prescription = _prescriptions.firstWhere((p) => p.id == prescriptionId);
        final medication = prescription.medications.firstWhere((m) => m.id == medicationId);
      
        await _notificationService.scheduleMedicationReminders(
          medication,
          prescriptionId
        );
      }
      
      // Reload prescriptions to get updated adherence score
      await _loadPrescriptions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentValue
              ? 'Medication marked as taken'
              : 'Medication marked as not taken'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating medication status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating medication status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateNotificationTime(
    String prescriptionId,
    String medicationId,
    int leadTimeMinutes,
  ) async {
    try {
      await _databaseService.updateMedicationNotificationLeadTime(
        prescriptionId,
        medicationId,
        leadTimeMinutes,
      );
      
      // Reload prescriptions and reschedule notifications
      await _loadPrescriptions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification time updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating notification time: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating notification time: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTimeAppealForm(
    String prescriptionId,
    String medicationId,
    Medication medication,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MedicationTimeAppealForm(
          prescriptionId: prescriptionId,
          medicationId: medicationId,
          medication: medication,
          onAppealSubmitted: _loadPrescriptions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator();
    }

    if (_prescriptions.isEmpty) {
      return const EmptyState(
        icon: Icons.medication_outlined,
        title: 'No medications yet',
        message: 'Your prescribed medications will appear here',
      );
    }

    // Flatten all medications from all prescriptions
    final allMedications = <MedicationWithPrescription>[];
    for (var prescription in _prescriptions) {
      for (var medication in prescription.medications) {
        allMedications.add(
          MedicationWithPrescription(
            prescription: prescription,
            medication: medication,
          ),
        );
      }
    }

    // Sort medications by start date (newest first)
    allMedications.sort((a, b) => b.medication.startDate.compareTo(a.medication.startDate));

    return RefreshIndicator(
      onRefresh: _loadPrescriptions,
      child: ResponsiveContainer(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: allMedications.length,
          itemBuilder: (context, index) {
            final medicationWithPrescription = allMedications[index];
            final medication = medicationWithPrescription.medication;
            final prescription = medicationWithPrescription.prescription;
            
            // Check if medication is active (between start and end dates)
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final isActive = today.isAfter(medication.startDate.subtract(const Duration(days: 1))) && 
                            today.isBefore(medication.endDate.add(const Duration(days: 1)));
            
            return MedicationItem(
              medication: medication,
              isActive: isActive,
              onToggleDose: isActive ? (doseId) {
                // Find if this dose is already taken today
                final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}-$doseId';
                final isTaken = medication.adherence[todayKey] ?? false;
                
                _toggleMedicationDose(
                  prescription.id,
                  medication.id,
                  doseId,
                  isTaken,
                );
              } : null,
              onRequestTimeChange: isActive && (medication.timeAppeal == null || medication.timeAppeal!.status != 'pending') ? 
                () => _showTimeAppealForm(prescription.id, medication.id, medication) : null,
              onUpdateNotificationTime: isActive ? 
                (minutes) => _updateNotificationTime(prescription.id, medication.id, minutes!) : null,
            );
          },
        ),
      ),
    );
  }
}

class MedicationWithPrescription {
  final PrescriptionModel prescription;
  final Medication medication;

  MedicationWithPrescription({
    required this.prescription,
    required this.medication,
  });
}
