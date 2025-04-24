import 'package:flutter/material.dart';
import '../../models/vitals_model.dart';
import 'vital_item.dart';
import '../common/adherence_score.dart';

class VitalsDisplay extends StatelessWidget {
  final VitalsModel vitals;
  final bool showTitle;
  final bool showAdherenceScore;

  const VitalsDisplay({
    super.key,
    required this.vitals,
    this.showTitle = true,
    this.showAdherenceScore = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                'Vital Signs',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
            ],
            VitalItem(
              icon: Icons.favorite,
              title: 'Heart Rate',
              value: '${vitals.heartRate} bpm',
              color: Colors.red,
            ),
            const Divider(),
            VitalItem(
              icon: Icons.speed,
              title: 'Blood Pressure',
              value: vitals.bloodPressure,
              color: Colors.blue,
            ),
            const Divider(),
            VitalItem(
              icon: Icons.height,
              title: 'Height',
              value: '${vitals.height} cm',
              color: Colors.green,
            ),
            const Divider(),
            VitalItem(
              icon: Icons.monitor_weight,
              title: 'Weight',
              value: '${vitals.weight} kg',
              color: Colors.orange,
            ),
            const Divider(),
            VitalItem(
              icon: Icons.thermostat,
              title: 'Body Temperature',
              value: '${vitals.temperature} °C',
              color: Colors.purple,
            ),
            if (showAdherenceScore) ...[
              const SizedBox(height: 24),
              AdherenceScore(score: vitals.adherenceScore),
            ],
          ],
        ),
      ),
    );
  }
}
