import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../components/navigation/app_drawer.dart';
import 'medication_list.dart';
import 'calendar_view.dart';
import 'patient_profile.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  String _currentRoute = 'medications';
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final patient = authService.currentUser;
    
    Widget currentPage;
    switch (_currentRoute) {
      case 'medications':
        currentPage = const MedicationList();
        break;
      case 'calendar':
        currentPage = const CalendarView();
        break;
      case 'profile':
        currentPage = PatientProfile(patient: patient!);
        break;
      default:
        currentPage = const MedicationList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
      ),
      drawer: AppDrawer(
        currentRoute: _currentRoute,
        onRouteChanged: (route) {
          setState(() {
            _currentRoute = route;
          });
        },
      ),
      body: currentPage,
    );
  }

  String _getTitle() {
    switch (_currentRoute) {
      case 'medications':
        return 'My Medications';
      case 'calendar':
        return 'Calendar';
      case 'profile':
        return 'My Profile';
      default:
        return 'Patient Dashboard';
    }
  }
}
