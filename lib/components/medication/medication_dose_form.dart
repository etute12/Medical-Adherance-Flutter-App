import 'package:flutter/material.dart';
import '../../models/prescription_model.dart';

class MedicationDoseForm extends StatefulWidget {
  final List<MedicationDose> initialDoses;
  final Function(List<MedicationDose>) onDosesChanged;

  const MedicationDoseForm({
    super.key,
    this.initialDoses = const [],
    required this.onDosesChanged,
  });

  @override
  State<MedicationDoseForm> createState() => _MedicationDoseFormState();
}

class _MedicationDoseFormState extends State<MedicationDoseForm> {
  late List<MedicationDoseData> _doses;

  @override
  void initState() {
    super.initState();
    
    if (widget.initialDoses.isEmpty) {
      // Create a default dose at 8:00 AM
      _doses = [MedicationDoseData(
        id: 'dose_${DateTime.now().millisecondsSinceEpoch}',
        time: const TimeOfDay(hour: 8, minute: 0),
        quantity: 1,
      )];
    } else {
      _doses = widget.initialDoses.map((dose) => MedicationDoseData(
        id: dose.id,
        time: dose.time,
        quantity: dose.quantity,
        instructions: dose.instructions,
      )).toList();
    }
  }

  void _addDose() {
    setState(() {
      _doses.add(MedicationDoseData(
        id: 'dose_${DateTime.now().millisecondsSinceEpoch}',
        time: const TimeOfDay(hour: 12, minute: 0),
        quantity: 1,
      ));
    });
    _notifyDosesChanged();
  }

  void _removeDose(int index) {
    setState(() {
      _doses.removeAt(index);
    });
    _notifyDosesChanged();
  }

  void _updateDose(int index, {TimeOfDay? time, int? quantity, String? instructions}) {
    setState(() {
      if (time != null) _doses[index].time = time;
      if (quantity != null) _doses[index].quantity = quantity;
      if (instructions != null) _doses[index].instructions = instructions;
    });
    _notifyDosesChanged();
  }

  void _notifyDosesChanged() {
    final doses = _doses.map((data) => MedicationDose(
      id: data.id,
      time: data.time,
      quantity: data.quantity,
      instructions: data.instructions,
    )).toList();
    
    widget.onDosesChanged(doses);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dosage Schedule',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._doses.asMap().entries.map((entry) {
          final index = entry.key;
          final dose = entry.value;
          return _buildDoseItem(index, dose);
        }).toList(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _addDose,
          icon: const Icon(Icons.add),
          label: const Text('Add Another Time'),
        ),
      ],
    );
  }

  Widget _buildDoseItem(int index, MedicationDoseData dose) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dose ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (_doses.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeDose(index),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: dose.time,
                      );
                      if (time != null) {
                        _updateDose(index, time: time);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _formatTimeOfDay(dose.time),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    value: dose.quantity,
                    items: List.generate(10, (i) => i + 1).map((qty) {
                      return DropdownMenuItem<int>(
                        value: qty,
                        child: Text('$qty ${qty == 1 ? 'tablet' : 'tablets'}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updateDose(index, quantity: value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: dose.instructions,
              decoration: const InputDecoration(
                labelText: 'Instructions',
                hintText: 'e.g., Take with food',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _updateDose(index, instructions: value);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class MedicationDoseData {
  final String id;
  TimeOfDay time;
  int quantity;
  String instructions;

  MedicationDoseData({
    required this.id,
    required this.time,
    required this.quantity,
    this.instructions = '',
  });
}
