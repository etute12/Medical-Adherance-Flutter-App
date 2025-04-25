import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/prescription_model.dart';
import '../../components/layout/responsive_container.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final DatabaseService _databaseService = DatabaseService();
  List<PrescriptionModel> _prescriptions = [];
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<MedicationWithPrescription>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final patientId = authService.currentUser!.id;
      final prescriptions = await _databaseService.getPatientPrescriptions(patientId);
      
      setState(() {
        _prescriptions = prescriptions;
        _isLoading = false;
      });
      
      _generateEvents();
    } catch (e) {
      print('Error loading prescriptions: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading prescriptions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _generateEvents() {
    final events = <DateTime, List<MedicationWithPrescription>>{};
    
    for (var prescription in _prescriptions) {
      for (var medication in prescription.medications) {
        // Generate events for each day between start and end date
        final startDate = DateTime(
          medication.startDate.year,
          medication.startDate.month,
          medication.startDate.day,
        );
        
        final endDate = DateTime(
          medication.endDate.year,
          medication.endDate.month,
          medication.endDate.day,
        );
        
        for (var date = startDate;
            date.isBefore(endDate.add(const Duration(days: 1)));
            date = date.add(const Duration(days: 1))) {
          
          final eventDate = DateTime(date.year, date.month, date.day);
          
          if (events[eventDate] == null) {
            events[eventDate] = [];
          }
          
          events[eventDate]!.add(
            MedicationWithPrescription(
              prescription: prescription,
              medication: medication,
            ),
          );
        }
      }
    }
    
    setState(() {
      _events = events;
    });
  }

  List<MedicationWithPrescription> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ResponsiveContainer(
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                markersMaxCount: 3,
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay);
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No medications for this day',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final medicationWithPrescription = events[index];
        final medication = medicationWithPrescription.medication;
        final prescription = medicationWithPrescription.prescription;
        
        // Check if medication is taken on selected day
        final selectedDayKey = '${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}';
        final isTaken = medication.adherence[selectedDayKey] ?? false;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(medication.name),
            subtitle: Text('${medication.dosage} - ${medication.frequency}'),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(
                Icons.medication,
                color: Colors.white,
              ),
            ),
            trailing: isTaken
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.circle_outlined, color: Colors.grey),
            onTap: () {
              // Only allow toggling for today or past dates
              if (_selectedDay.isBefore(DateTime.now().add(const Duration(days: 1)))) {
                final doseId = DateTime.now().millisecondsSinceEpoch.toString();
                _databaseService.updateMedicationAdherence(
                  prescription.id,
                  medication.id,
                  doseId,
                  !isTaken,
                );
                
                // Update UI immediately
                setState(() {
                  // Update the adherence map with the new value
                  medication.adherence[selectedDayKey] = !isTaken;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You cannot mark future medications as taken'),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}

class MedicationWithPrescription {
  final PrescriptionModel prescription;
  final Medication medication;

  MedicationWithPrescription({
    required this.prescription,
    required this.medication,
  });
}
