import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../components/common/loading_indicator.dart';
import '../../components/common/empty_state.dart';
import '../../components/navigation/app_drawer.dart';
import 'patient_details.dart';
import 'doctor_profile.dart';
import '../../components/layout/responsive_container.dart';
import 'medication_appeals_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final DatabaseService _databaseService = DatabaseService();
  String _currentRoute = 'patients';
  List<UserModel> _patients = [];
  bool _isLoading = true;
  int _pendingAppealsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final doctorId = authService.currentUser!.id;
      
      // Load patients
      final patients = await _databaseService.getDoctorPatients(doctorId);
      
      // Load pending appeals count
      final appeals = await _databaseService.getPendingMedicationAppeals(doctorId);
      
      setState(() {
        _patients = patients;
        _pendingAppealsCount = appeals.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _changeRoute(String route) {
    setState(() {
      _currentRoute = route;
    });
  }

  void _navigateToAppeals() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MedicationAppealsScreen(),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final doctor = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRoute == 'patients' ? 'Patients' : 'Profile'),
        actions: [
          if (_pendingAppealsCount > 0)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: _navigateToAppeals,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _pendingAppealsCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      drawer: AppDrawer(
        currentRoute: _currentRoute,
        onRouteChanged: _changeRoute,
      ),
      body: _currentRoute == 'patients'
          ? _buildPatientsTab()
          : DoctorProfile(doctor: doctor!),
    );
  }

  Widget _buildPatientsTab() {
    if (_isLoading) {
      return const LoadingIndicator();
    }

    if (_patients.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'No patients yet',
        message: 'Patients who register with your doctor ID will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ResponsiveContainer(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: _patients.length,
          itemBuilder: (context, index) {
            final patient = _patients[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(patient.name),
                subtitle: Text(patient.email),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PatientDetailsScreen(patientId: patient.id),
                    ),
                  ).then((_) => _loadData());
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
