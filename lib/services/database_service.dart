import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prescription_model.dart';
import '../models/vitals_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Doctor methods
  Future<List<UserModel>> getDoctorPatients(String doctorId) async {
    final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();
    final patientIds = List<String>.from(doctorDoc.data()?['patients'] ?? []);
    
    if (patientIds.isEmpty) return [];
    
    final patientsSnapshot = await _firestore
        .collection('users')
        .where('id', whereIn: patientIds)
        .where('role', isEqualTo: 'patient')
        .get();
    
    return patientsSnapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
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

  // Patient methods
  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientId) async {
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
  }

  Future<VitalsModel> getPatientVitals(String patientId) async {
    final patientDoc = await _firestore.collection('patients').doc(patientId).get();
    return VitalsModel.fromMap(patientDoc.data()?['vitals'] ?? {});
  }

  Future<void> updateMedicationAdherence(
    String prescriptionId, 
    String medicationId, 
    DateTime date, 
    bool taken
  ) async {
    await _firestore.collection('prescriptions').doc(prescriptionId).update({
      'medications.$medicationId.adherence.$date': taken,
    });
    
    // Recalculate adherence score
    await _updateAdherenceScore(prescriptionId);
  }

  Future<void> _updateAdherenceScore(String patientId) async {
    // Get all prescriptions
    final prescriptions = await getPatientPrescriptions(patientId);
    
    // Calculate adherence score
    double totalAdherence = 0;
    int totalMedications = 0;
    
    for (var prescription in prescriptions) {
      for (var medication in prescription.medications) {
        int takenCount = 0;
        int totalDoses = 0;
        
        medication.adherence.forEach((date, taken) {
          totalDoses++;
          if (taken) takenCount++;
        });
        
        if (totalDoses > 0) {
          totalAdherence += takenCount / totalDoses;
          totalMedications++;
        }
      }
    }
    
    final adherenceScore = totalMedications > 0 
        ? (totalAdherence / totalMedications) * 100 
        : 0;
    
    // Update patient's adherence score
    await _firestore.collection('patients').doc(patientId).update({
      'vitals.adherenceScore': adherenceScore.round(),
    });
  }
}
