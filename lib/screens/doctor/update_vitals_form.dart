import 'package:flutter/material.dart';
import '../../models/vitals_model.dart';
import '../../services/database_service.dart';

class UpdateVitalsForm extends StatefulWidget {
  final String patientId;
  final VitalsModel currentVitals;
  final Function onVitalsUpdated;

  const UpdateVitalsForm({
    super.key,
    required this.patientId,
    required this.currentVitals,
    required this.onVitalsUpdated,
  });

  @override
  State<UpdateVitalsForm> createState() => _UpdateVitalsFormState();
}

class _UpdateVitalsFormState extends State<UpdateVitalsForm> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  
  late TextEditingController _heartRateController;
  late TextEditingController _bloodPressureController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _temperatureController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _heartRateController = TextEditingController(text: widget.currentVitals.heartRate.toString());
    _bloodPressureController = TextEditingController(text: widget.currentVitals.bloodPressure);
    _heightController = TextEditingController(text: widget.currentVitals.height.toString());
    _weightController = TextEditingController(text: widget.currentVitals.weight.toString());
    _temperatureController = TextEditingController(text: widget.currentVitals.temperature.toString());
  }

  @override
  void dispose() {
    _heartRateController.dispose();
    _bloodPressureController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  Future<void> _saveVitals() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedVitals = VitalsModel(
          heartRate: int.parse(_heartRateController.text),
          bloodPressure: _bloodPressureController.text,
          height: double.parse(_heightController.text),
          weight: double.parse(_weightController.text),
          temperature: double.parse(_temperatureController.text),
          adherenceScore: widget.currentVitals.adherenceScore, // Keep the existing adherence score
        );

        await _databaseService.updatePatientVitals(widget.patientId, updatedVitals);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vitals updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          widget.onVitalsUpdated(updatedVitals);
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating vitals: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Patient Vitals'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildVitalField(
              controller: _heartRateController,
              label: 'Heart Rate',
              hint: 'bpm',
              icon: Icons.favorite,
              color: Colors.red,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter heart rate';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildVitalField(
              controller: _bloodPressureController,
              label: 'Blood Pressure',
              hint: 'e.g., 120/80',
              icon: Icons.speed,
              color: Colors.blue,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter blood pressure';
                }
                if (!value.contains('/')) {
                  return 'Format should be systolic/diastolic (e.g., 120/80)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildVitalField(
              controller: _heightController,
              label: 'Height',
              hint: 'cm',
              icon: Icons.height,
              color: Colors.green,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter height';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildVitalField(
              controller: _weightController,
              label: 'Weight',
              hint: 'kg',
              icon: Icons.monitor_weight,
              color: Colors.orange,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter weight';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildVitalField(
              controller: _temperatureController,
              label: 'Body Temperature',
              hint: '°C',
              icon: Icons.thermostat,
              color: Colors.purple,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter body temperature';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveVitals,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Vitals'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
            keyboardType: keyboardType,
            validator: validator,
          ),
        ),
      ],
    );
  }
}
