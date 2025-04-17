import 'package:alpha_generations/group/AssignmentDetailsPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GroupAssignmentsPage extends StatelessWidget {
  final String groupId;

  const GroupAssignmentsPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Assignments"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('assignments')
            .orderBy('deadline', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No assignments available",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
          }

          // الحصول على الوقت الحالي
          DateTime now = DateTime.now();

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var assignment = doc.data() as Map<String, dynamic>;

              // التحقق من الموعد النهائي
              Timestamp? dueTimestamp = assignment['deadline'];
              if (dueTimestamp == null) {
                return const SizedBox.shrink(); // إخفاء الواجب إذا لم يكن له موعد نهائي
              }

              DateTime dueDate = dueTimestamp.toDate();
              if (now.isAfter(dueDate)) {
                return const SizedBox.shrink(); // إخفاء الواجب إذا انتهى الوقت
              }

              // تنسيق التاريخ
              String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(dueDate);

              bool isSubmitted = assignment['submitted'] ?? false;

              return Card(
                elevation: 4,
                color: isSubmitted ? Colors.green.shade200 : Colors.red.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: Icon(
                    Icons.assignment,
                    color: isSubmitted ? Colors.green : Colors.red,
                    size: 50,
                  ),
                  title: Text(
                    assignment['title'] ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    "Due: $formattedDate",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  trailing: isSubmitted
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 30)
                      : const Icon(Icons.pending_actions, color: Colors.orange, size: 30),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssignmentDetailsPage(
                          groupId: groupId,
                          assignmentId: doc.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}