import 'package:flutter/material.dart';
import '../../models/prescription_model.dart';

class PrescriptionItem extends StatelessWidget {
  final PrescriptionModel prescription;
  final int index;

  const PrescriptionItem({
    super.key,
    required this.prescription,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          'Prescription #${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Created on: ${prescription.createdAt.day}/${prescription.createdAt.month}/${prescription.createdAt.year}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (prescription.notes.isNotEmpty) ...[
                  Text(
                    'Notes:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(prescription.notes),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Medications:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...prescription.medications.map((medication) {
                  return ListTile(
                    title: Text(medication.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dosage: ${medication.dosage}'),
                        Text('Frequency: ${medication.frequency}'),
                        Text(
                          'Duration: ${medication.startDate.day}/${medication.startDate.month}/${medication.startDate.year} - ${medication.endDate.day}/${medication.endDate.month}/${medication.endDate.year}',
                        ),
                      ],
                    ),
                    leading: const Icon(Icons.medication),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
