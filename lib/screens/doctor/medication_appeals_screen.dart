import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/prescription_model.dart';
import '../../models/user_model.dart';
import '../../components/layout/responsive_container.dart';
import '../../components/common/loading_indicator.dart';
import '../../components/common/empty_state.dart';
import '../../components/medication/medication_dose_form.dart';

class MedicationAppealsScreen extends StatefulWidget {
  const MedicationAppealsScreen({super.key});

  @override
  State<MedicationAppealsScreen> createState() => _MedicationAppealsScreenState();
}

class _MedicationAppealsScreenState extends State<MedicationAppealsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _pendingAppeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingAppeals();
  }

  Future<void> _loadPendingAppeals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final doctorId = authService.currentUser!.id;
      
      final appeals = await _databaseService.getPendingMedicationAppeals(doctorId);
      
      setState(() {
        _pendingAppeals = appeals;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pending appeals: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading appeals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAppealDetailsDialog(Map<String, dynamic> appealData) {
    final appeal = appealData['appeal'] as MedicationTimeAppeal;
    final patient = appealData['patient'] as UserModel;
    final medicationName = appealData['medicationName'] as String;
    final prescriptionId = appealData['prescriptionId'] as String;
    final medicationId = appealData['medicationId'] as String;
    
    final responseController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Time Change Request'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Patient: ${patient.name}'),
              Text('Medication: $medicationName'),
              const SizedBox(height: 8),
              Text('Reason for request:'),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(appeal.reason),
              ),
              const SizedBox(height: 16),
              Text('Suggested times:'),
              ...appeal.suggestedDoses.map((dose) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• ${dose.time.hour.toString().padLeft(2, '0')}:${dose.time.minute.toString().padLeft(2, '0')} - ${dose.quantity} ${dose.quantity == 1 ? 'tablet' : 'tablets'}${dose.instructions.isNotEmpty ? ' (${dose.instructions})' : ''}',
                ),
              )).toList(),
              const SizedBox(height: 16),
              TextField(
                controller: responseController,
                decoration: const InputDecoration(
                  labelText: 'Your Response (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _databaseService.respondToMedicationTimeAppeal(
                prescriptionId,
                medicationId,
                'rejected',
                responseController.text.isNotEmpty ? responseController.text : null,
                null,
              );
              
              if (mounted) {
                Navigator.pop(context);
                _loadPendingAppeals();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Time change request rejected'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _databaseService.respondToMedicationTimeAppeal(
                prescriptionId,
                medicationId,
                'approved',
                responseController.text.isNotEmpty ? responseController.text : null,
                appeal.suggestedDoses,
              );
              
              if (mounted) {
                Navigator.pop(context);
                _loadPendingAppeals();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Time change request approved'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator();
    }

    if (_pendingAppeals.isEmpty) {
      return const EmptyState(
        icon: Icons.access_time,
        title: 'No Pending Requests',
        message: 'You have no pending medication time change requests',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Time Requests'),
      ),
      body: ResponsiveContainer(
        child: RefreshIndicator(
          onRefresh: _loadPendingAppeals,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _pendingAppeals.length,
            itemBuilder: (context, index) {
              final appealData = _pendingAppeals[index];
              final appeal = appealData['appeal'] as MedicationTimeAppeal;
              final patient = appealData['patient'] as UserModel;
              final medicationName = appealData['medicationName'] as String;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text('$medicationName Time Change'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Patient: ${patient.name}'),
                      Text('Requested: ${appeal.requestedAt.day}/${appeal.requestedAt.month}/${appeal.requestedAt.year}'),
                    ],
                  ),
                  leading: const CircleAvatar(
                    child: Icon(Icons.access_time),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAppealDetailsDialog(appealData),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
