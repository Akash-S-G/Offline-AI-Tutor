import 'package:flutter/material.dart';
import '../data/educational_repository.dart';
import '../models/educational_models.dart';
import 'grade_screen.dart';

/// Curriculum home screen showing available grades
/// 
/// Entry point for offline educational learning.
/// Users select a grade to navigate through subjects → chapters → topics.
class CurriculumHomeScreen extends StatefulWidget {
  const CurriculumHomeScreen({Key? key}) : super(key: key);

  @override
  State<CurriculumHomeScreen> createState() => _CurriculumHomeScreenState();
}

class _CurriculumHomeScreenState extends State<CurriculumHomeScreen> {
  late Future<List<GradeModel>> _gradesFuture;

  @override
  void initState() {
    super.initState();
    _gradesFuture = EducationalRepository.getAllGrades();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Educational Learning'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<GradeModel>>(
        future: _gradesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading grades: ${snapshot.error}'),
            );
          }

          final grades = snapshot.data ?? [];

          if (grades.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No grades available',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Download educational packs to get started',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grades.length,
            itemBuilder: (context, index) {
              final grade = grades[index];
              return _GradeCard(grade: grade);
            },
          );
        },
      ),
    );
  }
}

/// Card widget for individual grade selection
class _GradeCard extends StatelessWidget {
  final GradeModel grade;

  const _GradeCard({required this.grade});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            '${grade.gradeNumber}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ),
        title: Text(
          grade.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: grade.description != null
            ? Text(
                grade.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GradeScreen(grade: grade),
            ),
          );
        },
      ),
    );
  }
}
