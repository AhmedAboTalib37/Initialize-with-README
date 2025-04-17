import 'package:alpha_generations/group/GroupAssignmentsPage.dart';
import 'package:alpha_generations/group/lecgroup.dart';
import 'package:flutter/material.dart';

class GroupDetailPage extends StatelessWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Group Overview")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const Icon(Icons.play_circle_fill, size: 50, color: Colors.blue),
                  title: const Text("Course Videos", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Watch recorded lectures"),
                  onTap: () {
                    if (groupId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseVideosPage(groupId: groupId),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid group ID")),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 15),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const Icon(Icons.assignment, size: 50, color: Colors.green),
                  title: const Text("Assignments", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("View and complete assignments"),
                  onTap: () {
                    if (groupId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupAssignmentsPage(groupId: groupId),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid group ID")),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
