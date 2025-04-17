import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentAssignmentsPage extends StatefulWidget {
  const StudentAssignmentsPage({super.key});

  @override
  State<StudentAssignmentsPage> createState() => _StudentAssignmentsPageState();
}

class _StudentAssignmentsPageState extends State<StudentAssignmentsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String fixedGroupId = 'huLkf8ovy2BI8F1oVgMZ';

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'You must be logged in to view assignments.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My duties', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('groups')
            .doc(fixedGroupId)
            .collection('assignments')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, assignmentsSnapshot) {
          if (assignmentsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!assignmentsSnapshot.hasData || assignmentsSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('There are no assignments currently.'));
          }

          final assignments = assignmentsSnapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              final assignmentData = assignment.data() as Map<String, dynamic>;
              final assignmentId = assignment.id;

              return StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('groups')
                    .doc(fixedGroupId)
                    .collection('assignments')
                    .doc(assignmentId)
                    .collection('submissions')
                    .doc(currentUser.uid)
                    .snapshots(),
                builder: (context, submissionSnapshot) {
                  final hasSubmission =
                      submissionSnapshot.hasData && submissionSnapshot.data!.exists;
                  final submissionData = hasSubmission
                      ? submissionSnapshot.data!.data() as Map<String, dynamic>
                      : null;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Assignment info
                          Text(
                            assignmentData['title'] ?? 'No Title',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            assignmentData['description'] ?? 'No Description',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Date of creation: ${DateFormat('yyyy-MM-dd - hh:mm a').format((assignmentData['createdAt'] as Timestamp).toDate())}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Divider(height: 24, thickness: 1),

                          // Submission status
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: hasSubmission ? Colors.green[50] : Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  hasSubmission ? Icons.check_circle : Icons.pending_actions,
                                  color: hasSubmission ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    hasSubmission ? 'Done ' : 'Not delivered yet',
                                    style: TextStyle(
                                      color: hasSubmission ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (hasSubmission)
                                  Text(
                                    DateFormat('yyyy-MM-dd - hh:mm a')
                                        .format((submissionData!['submittedAt'] as Timestamp).toDate()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Grading section (if graded)
                          if (hasSubmission && submissionData!['gradedAt'] != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Grading',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        'your grade: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        submissionData['grade']?.toString() ?? 'Not graded yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _getGradeColor(
                                              submissionData['grade']?.toString() ?? ''),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Teacher notes:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    submissionData['teacherNote']?.toString() ?? 'No notes',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Grading date: ${DateFormat('yyyy-MM-dd - hh:mm a').format((submissionData['gradedAt'] as Timestamp).toDate())}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // File section (if submitted)
                          if (hasSubmission && submissionData!['fileUrl'] != null) ...[
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () => _launchFile(submissionData['fileUrl']),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.attach_file, color: Colors.blue),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        submissionData['fileName']?.toString() ?? 'Open file',
                                        style: const TextStyle(color: Colors.blue),
                                      ),
                                    ),
                                    const Icon(Icons.open_in_new, size: 18, color: Colors.blue),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Color _getGradeColor(String grade) {
    if (grade.isEmpty || grade == 'Not graded yet') return Colors.grey;
    final numericGrade = double.tryParse(grade);
    if (numericGrade == null) return Colors.black;
    if (numericGrade >= 85) return Colors.green;
    if (numericGrade >= 70) return Colors.blue;
    if (numericGrade >= 50) return Colors.orange;
    return Colors.red;
  }

  Future<void> _launchFile(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open file')),
      );
    }
  }
}