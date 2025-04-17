import 'package:alpha_generations/assignmentdetails/add.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageAssignmentsPage extends StatelessWidget {
  const ManageAssignmentsPage({super.key});

  void _editAssignment(BuildContext context, String groupId, String assignmentId, String currentTitle, String currentDeadline) {
    TextEditingController titleController = TextEditingController(text: currentTitle);
    TextEditingController deadlineController = TextEditingController(text: currentDeadline);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Assignment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Assignment Title'),
              ),
              TextField(
                controller: deadlineController,
                decoration: const InputDecoration(labelText: 'Deadline (YYYY-MM-DD)'),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    deadlineController.text = pickedDate.toIso8601String().split('T')[0];
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('groups').doc(groupId).collection('assignments').doc(assignmentId).update({
                  'title': titleController.text,
                  'deadline': deadlineController.text,
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAssignment(BuildContext context, String groupId, String assignmentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this assignment? This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                FirebaseFirestore.instance.collection('groups').doc(groupId).collection('assignments').doc(assignmentId).delete();
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Assignments'),
        backgroundColor: Colors.greenAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Assignment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddAssignment()));
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('groups').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var groups = snapshot.data!.docs;
                  return ListView(
                    children: groups.map((group) {
                      return FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance.collection('groups').doc(group.id).collection('assignments').get(),
                        builder: (context, assignmentSnapshot) {
                          if (!assignmentSnapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          var assignments = assignmentSnapshot.data!.docs;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  group['name'] ?? 'Unnamed Group',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                              ...assignments.map((assignment) {
                                var assignmentData = assignment.data() as Map<String, dynamic>;
                                return Card(
                                  elevation: 4,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  child: ListTile(
                                    title: Text(
                                      assignmentData['title'] ?? 'Untitled Assignment',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text('Deadline: ${assignmentData['deadline'] ?? 'No Deadline'}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.orange),
                                          onPressed: () => _editAssignment(
                                            context,
                                            group.id,
                                            assignment.id,
                                            assignmentData['title'] ?? '',
                                            assignmentData['deadline'] ?? '',
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteAssignment(context, group.id, assignment.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 10),
                            ],
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
