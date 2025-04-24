import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/prescription_model.dart';
import '../../components/medication/medication_item.dart';
import '../../components/common/loading_indicator.dart';
import '../../components/common/empty_state.dart';

class MedicationList extends StatefulWidget {
  const MedicationList({super.key});

  @override
  State<MedicationList> createState() => _MedicationListState();
}

class _MedicationListState extends State<MedicationList> {
  final DatabaseService _databaseService = DatabaseService();
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading prescriptions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleMedicationTaken(
    String prescriptionId,
    String medicationId,
    bool currentValue,
  ) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final patientId = authService.currentUser!.id;
      
      await _databaseService.updateMedicationAdherence(
        prescriptionId,
        medicationId,
        DateTime.now(),
        !currentValue,
      );
      
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allMedications.length,
        itemBuilder: (context, index) {
          final medicationWithPrescription = allMedications[index];
          final medication = medicationWithPrescription.medication;
          final prescription = medicationWithPrescription.prescription;
          
          // Check if medication is taken today
          final today = DateTime.now();
          final todayKey = DateTime(today.year, today.month, today.day);
          final isTakenToday = medication.adherence[todayKey] ?? false;
          
          // Check if medication is active (between start and end dates)
          final isActive = today.isAfter(medication.startDate) && 
                          today.isBefore(medication.endDate.add(const Duration(days: 1)));
          
          return MedicationItem(
            medication: medication,
            isTaken: isTakenToday,
            isActive: isActive,
            onToggle: isActive ? () {
              _toggleMedicationTaken(
                prescription.id,
                medication.id,
                isTakenToday,
              );
            } : null,
          );
        },
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
