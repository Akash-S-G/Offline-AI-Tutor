import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'grade_sync_screen.dart';
import '../../home/presentation/main_dashboard_screen.dart';

class GradeSelectionScreen extends StatefulWidget {
  const GradeSelectionScreen({super.key});

  @override
  State<GradeSelectionScreen> createState() => _GradeSelectionScreenState();
}

class _GradeSelectionScreenState extends State<GradeSelectionScreen> {
  int? _selectedGrade;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Tutor Onboarding'),
        backgroundColor: const Color(0xFF0B6E4F),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.school_rounded,
                size: 80,
                color: Color(0xFF0B6E4F),
              ),
              const SizedBox(height: 24),
              const Text(
                'What grade are you studying?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select your grade to download the required offline curriculum. This reduces storage usage and sync time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    final grade = index + 1;
                    final isSelected = _selectedGrade == grade;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedGrade = grade;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFF0B6E4F).withValues(alpha: 0.1) 
                                : Colors.white,
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFF0B6E4F) 
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Grade $grade',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF0B6E4F) : Colors.black87,
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF0B6E4F),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _selectedGrade == null ? null : _saveAndContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B6E4F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    if (_selectedGrade == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_grade', _selectedGrade!);

    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GradeSyncScreen(grade: _selectedGrade!),
      ),
    );
  }
}
