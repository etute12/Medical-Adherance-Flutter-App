class VitalsModel {
  final int heartRate;
  final String bloodPressure;
  final double height;
  final double weight;
  final double temperature;
  final int adherenceScore;

  VitalsModel({
    required this.heartRate,
    required this.bloodPressure,
    required this.height,
    required this.weight,
    required this.temperature,
    required this.adherenceScore,
  });

  factory VitalsModel.fromMap(Map<String, dynamic> map) {
    return VitalsModel(
      heartRate: map['heartRate'] ?? 0,
      bloodPressure: map['bloodPressure'] ?? '0/0',
      height: (map['height'] ?? 0).toDouble(),
      weight: (map['weight'] ?? 0).toDouble(),
      temperature: (map['temperature'] ?? 0).toDouble(),
      adherenceScore: map['adherenceScore'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'heartRate': heartRate,
      'bloodPressure': bloodPressure,
      'height': height,
      'weight': weight,
      'temperature': temperature,
      'adherenceScore': adherenceScore,
    };
  }

  VitalsModel copyWith({
    int? heartRate,
    String? bloodPressure,
    double? height,
    double? weight,
    double? temperature,
    int? adherenceScore,
  }) {
    return VitalsModel(
      heartRate: heartRate ?? this.heartRate,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      temperature: temperature ?? this.temperature,
      adherenceScore: adherenceScore ?? this.adherenceScore,
    );
  }
}
