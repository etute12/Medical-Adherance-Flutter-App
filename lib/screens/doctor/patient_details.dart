import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/vitals_model.dart';
import '../../models/prescription_model.dart';
import '../../components/vitals/vitals_display.dart';
import '../../components/medication/prescription_item.dart';
import '../../components/common/loading_indicator.dart';
import '../../components/common/empty_state.dart';
import 'prescription_form.dart';
import 'update_vitals_form.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailsScreen({super.key, required this.patientId});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;
  VitalsModel? _vitals;
  List<PrescriptionModel> _prescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vitals = await _databaseService.getPatientVitals(widget.patientId);
      final prescriptions = await _databaseService.getPatientPrescriptions(widget.patientId);
      
      setState(() {
        _vitals = vitals;
        _prescriptions = prescriptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading patient data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openUpdateVitalsForm() {
    if (_vitals == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UpdateVitalsForm(
          patientId: widget.patientId,
          currentVitals: _vitals!,
          onVitalsUpdated: (updatedVitals) {
            setState(() {
              _vitals = updatedVitals;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Vitals'),
            Tab(text: 'Prescriptions'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVitalsTab(),
                _buildPrescriptionsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _openUpdateVitalsForm();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PrescriptionForm(patientId: widget.patientId),
              ),
            ).then((_) => _loadPatientData());
          }
        },
        child: Icon(
          _tabController.index == 0 ? Icons.edit : Icons.add,
        ),
      ),
    );
  }

  Widget _buildVitalsTab() {
    if (_vitals == null) {
      return const Center(
        child: Text('No vitals data available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VitalsDisplay(vitals: _vitals!),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsTab() {
    if (_prescriptions.isEmpty) {
      return EmptyState(
        icon: Icons.medication_outlined,
        title: 'No prescriptions yet',
        message: 'Add a prescription using the button below',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _prescriptions.length,
      itemBuilder: (context, index) {
        return PrescriptionItem(
          prescription: _prescriptions[index],
          index: index,
        );
      },
    );
  }
}
