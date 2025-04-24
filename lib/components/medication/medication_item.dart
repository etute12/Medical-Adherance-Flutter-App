import 'package:flutter/material.dart';
import '../../models/prescription_model.dart';

class MedicationItem extends StatelessWidget {
  final Medication medication;
  final bool isTaken;
  final bool isActive;
  final VoidCallback? onToggle;

  const MedicationItem({
    super.key,
    required this.medication,
    required this.isTaken,
    required this.isActive,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        medication.dosage,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                if (isActive && onToggle != null)
                  Checkbox(
                    value: isTaken,
                    onChanged: (_) => onToggle!(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(medication.frequency),
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            const SizedBox(height: 8),
            Text(
              'Take until: ${medication.endDate.day}/${medication.endDate.month}/${medication.endDate.year}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (!isActive)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  DateTime.now().isBefore(medication.startDate) ? 'Not started yet' : 'Completed',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
