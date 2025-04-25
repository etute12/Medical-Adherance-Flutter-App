import 'package:flutter/material.dart';

class MedicationDose {
  final String id;
  final TimeOfDay time;
  final int quantity; // Number of tablets/units
  final String instructions; // Additional instructions for this dose

  MedicationDose({
    required this.id,
    required this.time,
    required this.quantity,
    this.instructions = '',
  });

  factory MedicationDose.fromMap(Map<String, dynamic> map, String id) {
    // Parse time from hour and minute
    final hour = map['hour'] ?? 8;
    final minute = map['minute'] ?? 0;
    
    return MedicationDose(
      id: id,
      time: TimeOfDay(hour: hour, minute: minute),
      quantity: map['quantity'] ?? 1,
      instructions: map['instructions'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hour': time.hour,
      'minute': time.minute,
      'quantity': quantity,
      'instructions': instructions,
    };
  }

  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class MedicationTimeAppeal {
  final String id;
  final DateTime requestedAt;
  final String reason;
  final List<MedicationDose> suggestedDoses;
  final String status; // 'pending', 'approved', 'rejected'
  final String? doctorResponse;

  MedicationTimeAppeal({
    required this.id,
    required this.requestedAt,
    required this.reason,
    required this.suggestedDoses,
    this.status = 'pending',
    this.doctorResponse,
  });

  factory MedicationTimeAppeal.fromMap(Map<String, dynamic> map, String id) {
    final suggestedDosesMap = map['suggestedDoses'] as Map<String, dynamic>? ?? {};
    final suggestedDoses = suggestedDosesMap.entries
        .map((e) => MedicationDose.fromMap(e.value as Map<String, dynamic>, e.key))
        .toList();

    return MedicationTimeAppeal(
      id: id,
      requestedAt: Medication._parseDateTime(map['requestedAt']),
      reason: map['reason'] ?? '',
      suggestedDoses: suggestedDoses,
      status: map['status'] ?? 'pending',
      doctorResponse: map['doctorResponse'],
    );
  }

  Map<String, dynamic> toMap() {
    final suggestedDosesMap = {
      for (var dose in suggestedDoses)
        dose.id: dose.toMap(),
    };

    return {
      'requestedAt': requestedAt,
      'reason': reason,
      'suggestedDoses': suggestedDosesMap,
      'status': status,
      'doctorResponse': doctorResponse,
    };
  }
}

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, bool> adherence; // Date string -> taken status
  final Map<String, DateTime> adherenceTimes; // Date string -> time taken
  final List<MedicationDose> doses; // Specific times and quantities
  final MedicationTimeAppeal? timeAppeal; // Appeal for time change
  final int notificationLeadTime; // Minutes before dose to notify

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.adherence,
    this.adherenceTimes = const {},
    this.doses = const [],
    this.timeAppeal,
    this.notificationLeadTime = 30,
  });

  factory Medication.fromMap(Map<String, dynamic> map, String id) {
    final adherenceMap = map['adherence'] as Map<dynamic, dynamic>? ?? {};
    
    // Convert adherence map keys to strings (YYYY-MM-DD format)
    final adherence = Map<String, bool>.fromEntries(
      adherenceMap.entries.map(
        (e) => MapEntry(
          e.key.toString(), // Store as string instead of DateTime
          e.value as bool,
        ),
      ),
    );

    // Parse adherence times
    final adherenceTimesMap = map['adherenceTimes'] as Map<dynamic, dynamic>? ?? {};
    final adherenceTimes = Map<String, DateTime>.fromEntries(
      adherenceTimesMap.entries.map(
        (e) => MapEntry(
          e.key.toString(),
          _parseDateTime(e.value),
        ),
      ),
    );

    // Parse doses
    final dosesMap = map['doses'] as Map<String, dynamic>? ?? {};
    final doses = dosesMap.entries
        .map((e) => MedicationDose.fromMap(e.value as Map<String, dynamic>, e.key))
        .toList();

    // Parse time appeal if exists
    MedicationTimeAppeal? timeAppeal;
    if (map['timeAppeal'] != null) {
      timeAppeal = MedicationTimeAppeal.fromMap(
        map['timeAppeal'] as Map<String, dynamic>,
        'appeal-${id}',
      );
    }

    return Medication(
      id: id,
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      startDate: _parseDateTime(map['startDate']),
      endDate: _parseDateTime(map['endDate']),
      adherence: adherence,
      adherenceTimes: adherenceTimes,
      doses: doses,
      timeAppeal: timeAppeal,
      notificationLeadTime: map['notificationLeadTime'] ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    final dosesMap = {
      for (var dose in doses)
        dose.id: dose.toMap(),
    };

    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'startDate': startDate,
      'endDate': endDate,
      'adherence': adherence,
      'adherenceTimes': adherenceTimes.map((key, value) => MapEntry(key, value)),
      'doses': dosesMap,
      'timeAppeal': timeAppeal?.toMap(),
      'notificationLeadTime': notificationLeadTime,
    };
  }
  
  // Helper method to parse DateTime from Firestore
  static DateTime _parseDateTime(dynamic date) {
    if (date == null) return DateTime.now();
    
    try {
      if (date is DateTime) {
        return date;
      } else if (date is String) {
        return DateTime.parse(date);
      } else if (date is Map) {
        // Handle Firestore Timestamp
        if (date['seconds'] != null) {
          return DateTime.fromMillisecondsSinceEpoch(
            (date['seconds'] * 1000 + (date['nanoseconds'] ?? 0) / 1000000).round()
          );
        }
      }
      
      // If we have a toDate method (Firestore Timestamp)
      if (date.runtimeType.toString().contains('Timestamp')) {
        try {
          final dynamic result = Function.apply(
            date.toDate, 
            []
          );
          return result as DateTime;
        } catch (e) {
          print('Error converting timestamp to date: $e');
        }
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    
    return DateTime.now();
  }

  // Check if a medication dose is due today
  bool isDueToday(String doseId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return startDate.compareTo(today) <= 0 && 
           endDate.compareTo(today) >= 0;
  }

  // Get the next dose time for today
  MedicationDose? getNextDoseForToday() {
    if (doses.isEmpty) return null;
    
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    
    // Sort doses by time
    final sortedDoses = List<MedicationDose>.from(doses)
      ..sort((a, b) {
        final aMinutes = a.time.hour * 60 + a.time.minute;
        final bMinutes = b.time.hour * 60 + b.time.minute;
        return aMinutes.compareTo(bMinutes);
      });
    
    // Find the next dose that hasn't passed yet
    for (var dose in sortedDoses) {
      final doseMinutes = dose.time.hour * 60 + dose.time.minute;
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;
      
      if (doseMinutes > currentMinutes) {
        return dose;
      }
    }
    
    // If all doses for today have passed, return null
    return null;
  }

  // Check if a specific dose was taken today
  bool isDoseTakenToday(String doseId) {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-$doseId';
    return adherence[todayKey] ?? false;
  }

  // Calculate adherence percentage for this medication
  double calculateAdherencePercentage() {
    if (adherence.isEmpty) return 0.0;
    
    int takenCount = 0;
    for (var taken in adherence.values) {
      if (taken) takenCount++;
    }
    
    return takenCount / adherence.length * 100;
  }

  // Calculate on-time adherence percentage (taken within 30 minutes of scheduled time)
  double calculateOnTimeAdherencePercentage() {
    if (adherence.isEmpty || adherenceTimes.isEmpty) return 0.0;
    
    int onTimeCount = 0;
    int totalCount = 0;
    
    adherence.forEach((dateKey, taken) {
      if (taken) {
        totalCount++;
        
        // Check if we have a timestamp for when it was taken
        final takenTime = adherenceTimes[dateKey];
        if (takenTime != null) {
          // Parse the dose ID from the key
          final parts = dateKey.split('-');
          if (parts.length >= 4) {
            final doseId = parts.sublist(3).join('-');
            
            // Find the scheduled dose
            final dose = doses.firstWhere(
              (d) => d.id == doseId, 
              orElse: () => doses.first
            );
            
            // Calculate scheduled time for that day
            final scheduledDate = DateTime.parse('${parts[0]}-${parts[1]}-${parts[2]}');
            final scheduledTime = DateTime(
              scheduledDate.year,
              scheduledDate.month,
              scheduledDate.day,
              dose.time.hour,
              dose.time.minute,
            );
            
            // Check if taken within 30 minutes of scheduled time
            final difference = takenTime.difference(scheduledTime).inMinutes.abs();
            if (difference <= 30) {
              onTimeCount++;
            }
          }
        }
      }
    });
    
    return totalCount > 0 ? onTimeCount / totalCount * 100 : 0.0;
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
      createdAt: Medication._parseDateTime(map['createdAt']),
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
