import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class SubmissionsPage extends StatefulWidget {
  final String assignmentId;
  final String groupId;

  const SubmissionsPage({
    super.key,
    required this.assignmentId,
    required this.groupId,
  });

  @override
  _SubmissionsPageState createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  late CollectionReference _submissionsRef;
  File? _selectedFile;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _submissionsRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('assignments')
        .doc(widget.assignmentId)
        .collection('submissions');
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _uploadCorrection(String submissionId) async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a correction file first!")),
      );
      return;
    }

    String filePath = 'corrections/${widget.groupId}/${widget.assignmentId}/$submissionId/${_selectedFileName}';
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('assignments')
          .doc(widget.assignmentId)
          .collection('submissions')
          .doc(submissionId)
          .update({
        'correctionFile': filePath,
        'correctionSubmitted': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correction uploaded successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading correction: $e")),
      );
    }
  }

  Future<void> _updateGrade(String submissionId, double grade) async {
    try {
      await _submissionsRef.doc(submissionId).update({
        'grade': grade,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Grade updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating grade: $e")),
      );
    }
  }

  Future<void> _downloadFile(String filePath) async {
    // You can implement the logic to download files, either from Firebase Storage or locally.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Downloading file...")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Submissions"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _submissionsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var submissions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              var submission = submissions[index];
              var studentId = submission.id;
              var studentEmail = submission['studentEmail'];
              var studentGrade = submission['grade'] ?? 'Not Graded';
              var filePath = submission['file'] ?? '';
              var correctionFile = submission['correctionFile'] ?? '';
              var isCorrectionSubmitted = submission['correctionSubmitted'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Student: $studentEmail", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text("Grade: $studentGrade", style: const TextStyle(fontSize: 14)),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () {
                              // Open dialog to enter grade
                              showDialog(
                                context: context,
                                builder: (context) {
                                  TextEditingController gradeController = TextEditingController();
                                  return AlertDialog(
                                    title: const Text("Enter Grade"),
                                    content: TextField(
                                      controller: gradeController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(hintText: 'Enter grade (0-10)'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          double grade = double.tryParse(gradeController.text) ?? 0.0;
                                          _updateGrade(studentId, grade);
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Save Grade"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: const Text("Grade"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(filePath.isNotEmpty ? "Submitted File: $filePath" : "No file submitted"),
                          const Spacer(),
                          filePath.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () => _downloadFile(filePath),
                                )
                              : const SizedBox(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(isCorrectionSubmitted
                              ? "Correction Submitted: $correctionFile"
                              : "No correction uploaded"),
                          const Spacer(),
                          !isCorrectionSubmitted
                              ? ElevatedButton(
                                  onPressed: () {
                                    _pickFile();
                                    if (_selectedFile != null) {
                                      _uploadCorrection(studentId);
                                    }
                                  },
                                  child: const Text("Upload Correction"),
                                )
                              : const SizedBox(),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
