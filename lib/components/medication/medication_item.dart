import 'package:flutter/material.dart';
import '../../models/prescription_model.dart';

class MedicationItem extends StatelessWidget {
  final Medication medication;
  final bool isActive;
  final Function(String)? onToggleDose;
  final Function()? onRequestTimeChange;
  final Function(int?)? onUpdateNotificationTime;

  const MedicationItem({
    super.key,
    required this.medication,
    required this.isActive,
    this.onToggleDose,
    this.onRequestTimeChange,
    this.onUpdateNotificationTime,
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
              ],
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(medication.frequency),
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'Schedule:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (medication.doses.isEmpty)
              const Text('No specific times set')
            else
              ...medication.doses.map((dose) => _buildDoseItem(context, dose)).toList(),
            
            const SizedBox(height: 16),
            Text(
              'Duration: ${medication.startDate.day}/${medication.startDate.month}/${medication.startDate.year} - ${medication.endDate.day}/${medication.endDate.month}/${medication.endDate.year}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            
            if (medication.timeAppeal != null) ...[
              const SizedBox(height: 16),
              _buildAppealStatus(context, medication.timeAppeal!),
            ],
            
            if (isActive) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: const Text('Request Time Change'),
                      onPressed: onRequestTimeChange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNotificationDropdown(context),
                  ),
                ],
              ),
            ],
            
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

  Widget _buildDoseItem(BuildContext context, MedicationDose dose) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}-${dose.id}';
    final isTaken = medication.adherence[todayKey] ?? false;
    
    // Check if this dose time has passed for today
    final doseTime = DateTime(
      today.year,
      today.month,
      today.day,
      dose.time.hour,
      dose.time.minute,
    );
    final hasPassed = now.isAfter(doseTime);
    
    // Check if this dose was taken on time (within 30 minutes)
    final takenTime = medication.adherenceTimes[todayKey];
    bool takenOnTime = false;
    
    if (takenTime != null) {
      final difference = takenTime.difference(doseTime).inMinutes.abs();
      takenOnTime = difference <= 30;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${dose.time.hour.toString().padLeft(2, '0')}:${dose.time.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Text(
                  '${dose.quantity} ${dose.quantity == 1 ? 'tablet' : 'tablets'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (dose.instructions.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '(${dose.instructions})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isActive && onToggleDose != null)
            IconButton(
              icon: isTaken
                ? Icon(
                    Icons.check_circle,
                    color: takenOnTime ? Colors.green : Colors.orange,
                  )
                : Icon(
                    hasPassed ? Icons.error_outline : Icons.circle_outlined,
                    color: hasPassed ? Colors.red : Colors.grey,
                  ),
              onPressed: () => onToggleDose!(dose.id),
              tooltip: isTaken
                ? takenOnTime
                    ? 'Taken on time'
                    : 'Taken late'
                : hasPassed
                    ? 'Missed'
                    : 'Not taken yet',
            ),
        ],
      ),
    );
  }

  Widget _buildAppealStatus(BuildContext context, MedicationTimeAppeal appeal) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (appeal.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Time change request pending';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Time change approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Time change rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
        statusText = 'Unknown status';
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (appeal.doctorResponse != null && appeal.doctorResponse!.isNotEmpty)
                  Text(
                    appeal.doctorResponse!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationDropdown(BuildContext context) {
    return DropdownButtonFormField<int?>(
      decoration: const InputDecoration(
        labelText: 'Notify me',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      value: medication.notificationLeadTime,
      items: [
        DropdownMenuItem(value: 5, child: Text('5 minutes before')),
        DropdownMenuItem(value: 15, child: Text('15 minutes before')),
        DropdownMenuItem(value: 30, child: Text('30 minutes before')),
        DropdownMenuItem(value: 60, child: Text('1 hour before')),
      ],
      onChanged: onUpdateNotificationTime,
    );
  }
}
