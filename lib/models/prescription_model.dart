class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime endDate;
  final Map<DateTime, bool> adherence;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.adherence,
  });

  factory Medication.fromMap(Map<String, dynamic> map, String id) {
    final adherenceMap = map['adherence'] as Map<dynamic, dynamic>? ?? {};
    final adherence = Map<DateTime, bool>.fromEntries(
      adherenceMap.entries.map(
        (e) => MapEntry(
          (e.key as dynamic).toDate(),
          e.value as bool,
        ),
      ),
    );

    return Medication(
      id: id,
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      startDate: (map['startDate'] as dynamic).toDate(),
      endDate: (map['endDate'] as dynamic).toDate(),
      adherence: adherence,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'startDate': startDate,
      'endDate': endDate,
      'adherence': adherence,
    };
  }
}

class PrescriptionModel {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime createdAt;
  final String notes;
  final List<Medication> medications;

  PrescriptionModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.createdAt,
    required this.notes,
    required this.medications,
  });

  factory PrescriptionModel.fromMap(Map<String, dynamic> map, String id) {
    final medicationsMap = map['medications'] as Map<String, dynamic>? ?? {};
    final medications = medicationsMap.entries
        .map((e) => Medication.fromMap(e.value as Map<String, dynamic>, e.key))
        .toList();

    return PrescriptionModel(
      id: id,
      doctorId: map['doctorId'] ?? '',
      patientId: map['patientId'] ?? '',
      createdAt: (map['createdAt'] as dynamic).toDate(),
      notes: map['notes'] ?? '',
      medications: medications,
    );
  }

  Map<String, dynamic> toMap() {
    final medicationsMap = {
      for (var medication in medications)
        medication.id: medication.toMap(),
    };

    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'createdAt': createdAt,
      'notes': notes,
      'medications': medicationsMap,
    };
  }
}
