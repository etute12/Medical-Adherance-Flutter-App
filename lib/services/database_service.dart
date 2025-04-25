import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/prescription_model.dart';
import '../models/vitals_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Doctor methods
  Future<List<UserModel>> getDoctorPatients(String doctorId) async {
    try {
      print('Fetching all patients for doctor ID: $doctorId');
      
      // Get all patients with role 'patient' regardless of doctor association
      final patientsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get();
          
      print('Found ${patientsSnapshot.docs.length} total patients');
      
      final allPatients = patientsSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
          
      print('Returning ${allPatients.length} patients for this doctor');
      return allPatients;
    } catch (e) {
      print('Error in getDoctorPatients: $e');
      rethrow;
    }
  }

  Future<void> updatePatientVitals(String patientId, VitalsModel vitals) async {
    await _firestore.collection('patients').doc(patientId).update({
      'vitals': vitals.toMap(),
    });
  }

  Future<void> addPrescription(PrescriptionModel prescription) async {
    final docRef = await _firestore.collection('prescriptions').add(prescription.toMap());
    
    // Update patient's prescriptions list
    await _firestore.collection('patients').doc(prescription.patientId).update({
      'prescriptions': FieldValue.arrayUnion([docRef.id]),
    });
  }

  Future<void> updatePrescription(PrescriptionModel prescription) async {
    await _firestore.collection('prescriptions').doc(prescription.id).update(prescription.toMap());
  }

  Future<void> updateMedicationDoses(
    String prescriptionId, 
    String medicationId, 
    List<MedicationDose> doses
  ) async {
    // Create a map for the doses
    Map<String, dynamic> dosesMap = {};
    
    // Populate the map with dose data
    for (var dose in doses) {
      dosesMap[dose.id] = dose.toMap();
    }
    
    // Update the document with the doses map
    await _firestore.collection('prescriptions').doc(prescriptionId).update({
      'medications.$medicationId.doses': dosesMap,
    });
  }

  Future<void> updateMedicationNotificationLeadTime(
    String prescriptionId,
    String medicationId,
    int leadTimeMinutes
  ) async {
    await _firestore.collection('prescriptions').doc(prescriptionId).update({
      'medications.$medicationId.notificationLeadTime': leadTimeMinutes,
    });
  }

  Future<void> submitMedicationTimeAppeal(
    String prescriptionId,
    String medicationId,
    MedicationTimeAppeal appeal
  ) async {
    await _firestore.collection('prescriptions').doc(prescriptionId).update({
      'medications.$medicationId.timeAppeal': appeal.toMap(),
    });
  }

  Future<void> respondToMedicationTimeAppeal(
    String prescriptionId,
    String medicationId,
    String status,
    String? response,
    List<MedicationDose>? approvedDoses
  ) async {
    final Map<String, dynamic> updates = {
      'medications.$medicationId.timeAppeal.status': status,
      'medications.$medicationId.timeAppeal.doctorResponse': response,
    };
    
    if (status == 'approved' && approvedDoses != null) {
      final dosesMap = {
        for (var dose in approvedDoses)
          dose.id: dose.toMap(),
      };
      
      updates['medications.$medicationId.doses'] = dosesMap;
    }
    
    await _firestore.collection('prescriptions').doc(prescriptionId).update(updates);
  }

  // Patient methods
  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientId) async {
    try {
      final patientDoc = await _firestore.collection('patients').doc(patientId).get();
      final prescriptionIds = List<String>.from(patientDoc.data()?['prescriptions'] ?? []);
      
      if (prescriptionIds.isEmpty) return [];
      
      final prescriptionsSnapshot = await _firestore
          .collection('prescriptions')
          .where(FieldPath.documentId, whereIn: prescriptionIds)
          .get();
      
      return prescriptionsSnapshot.docs
          .map((doc) => PrescriptionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting patient prescriptions: $e');
      rethrow;
    }
  }

  Future<VitalsModel> getPatientVitals(String patientId) async {
    final patientDoc = await _firestore.collection('patients').doc(patientId).get();
    return VitalsModel.fromMap(patientDoc.data()?['vitals'] ?? {});
  }

  Future<void> updateMedicationAdherence(
    String prescriptionId, 
    String medicationId, 
    String doseId,
    bool taken
  ) async {
    // Format date as YYYY-MM-DD-DOSEID string
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-$doseId';
    
    try {
      // Create a map for the updates
      Map<String, dynamic> updates = {};
      
      // Use set value approach for adherence
      updates['medications.$medicationId.adherence.$dateKey'] = taken;
      
      if (taken) {
        // For server timestamp, we'll handle it in the Firestore operation
        await _firestore.collection('prescriptions').doc(prescriptionId).update(updates);
        
        // Add the timestamp in a separate operation
        await _firestore.collection('prescriptions').doc(prescriptionId).update({
          'medications.$medicationId.adherenceTimes.$dateKey': FieldValue.serverTimestamp()
        });
      } else {
        // For delete operation, we need to handle it separately
        await _firestore.collection('prescriptions').doc(prescriptionId).update(updates);
        
        // Remove the timestamp if it exists
        await _firestore.collection('prescriptions').doc(prescriptionId).update({
          'medications.$medicationId.adherenceTimes.$dateKey': FieldValue.delete()
        });
      }
      
      // Recalculate adherence score
      await _updateAdherenceScore(prescriptionId);
    } catch (e) {
      print('Error updating medication adherence: $e');
      rethrow;
    }
  }

  Future<void> _updateAdherenceScore(String patientId) async {
    try {
      // Get all prescriptions
      final prescriptions = await getPatientPrescriptions(patientId);
      
      // Calculate adherence score
      double totalAdherence = 0;
      double totalOnTimeAdherence = 0;
      int totalMedications = 0;
      
      for (var prescription in prescriptions) {
        for (var medication in prescription.medications) {
          // Only include active medications in the score
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          if (today.isAfter(medication.startDate) && today.isBefore(medication.endDate.add(const Duration(days: 1)))) {
            totalAdherence += medication.calculateAdherencePercentage();
            totalOnTimeAdherence += medication.calculateOnTimeAdherencePercentage();
            totalMedications++;
          }
        }
      }
      
      // Calculate overall adherence score (70% based on taking meds, 30% based on taking them on time)
      final adherenceScore = totalMedications > 0 
          ? ((totalAdherence / totalMedications) * 0.7) + ((totalOnTimeAdherence / totalMedications) * 0.3)
          : 0;
      
      // Update patient's adherence score
      await _firestore.collection('patients').doc(patientId).update({
        'vitals.adherenceScore': adherenceScore.round(),
      });
    } catch (e) {
      print('Error updating adherence score: $e');
    }
  }

  // Get pending medication time appeals for a doctor
  Future<List<Map<String, dynamic>>> getPendingMedicationAppeals(String doctorId) async {
    try {
      // Get all prescriptions by this doctor
      final prescriptionsSnapshot = await _firestore
          .collection('prescriptions')
          .where('doctorId', isEqualTo: doctorId)
          .get();
      
      final List<Map<String, dynamic>> pendingAppeals = [];
      
      for (var doc in prescriptionsSnapshot.docs) {
        final prescription = PrescriptionModel.fromMap(doc.data(), doc.id);
        final patientId = prescription.patientId;
        
        // Get patient details
        final patientDoc = await _firestore.collection('users').doc(patientId).get();
        final patient = UserModel.fromMap(patientDoc.data()!, patientId);
        
        // Check each medication for pending appeals
        for (var medication in prescription.medications) {
          if (medication.timeAppeal != null && medication.timeAppeal!.status == 'pending') {
            pendingAppeals.add({
              'prescriptionId': prescription.id,
              'medicationId': medication.id,
              'medicationName': medication.name,
              'patient': patient,
              'appeal': medication.timeAppeal!,
            });
          }
        }
      }
      
      return pendingAppeals;
    } catch (e) {
      print('Error getting pending medication appeals: $e');
      rethrow;
    }
  }
}