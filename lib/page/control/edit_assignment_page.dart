import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class AddAssignmentPage extends StatefulWidget {
  final String studentEmail;
  final String? submittedFileUrl; // رابط إجابة الطالب

  const AddAssignmentPage({super.key, required this.studentEmail, this.submittedFileUrl});

  @override
  _AddAssignmentPageState createState() => _AddAssignmentPageState();
}

class _AddAssignmentPageState extends State<AddAssignmentPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  File? _reviewFile;
  bool _isUploading = false;
  final User? user = FirebaseAuth.instance.currentUser;

  /// **اختيار ملف PDF (لرفع التصحيح)**
  Future<void> _pickReviewFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _reviewFile = File(result.files.single.path!);
      });
    }
  }

  /// **رفع التصحيح إلى Firestore**
  Future<void> _uploadReview() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title.")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String? reviewFileUrl;

      if (_reviewFile != null) {
        reviewFileUrl = await _uploadFile(_reviewFile!, "reviews");
      }

      await FirebaseFirestore.instance.collection("assignments").add({
        "title": _titleController.text,
        "notice": _notesController.text,
        "grade": int.tryParse(_gradeController.text) ?? 0,
        "reviewFileUrl": reviewFileUrl,
        "createdBy": user?.email,
        "createdAt": FieldValue.serverTimestamp(),
        "userEmail": widget.studentEmail,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review uploaded successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  /// **رفع ملف إلى Firebase Storage**
  Future<String> _uploadFile(File file, String folder) async {
    String fileName = "${widget.studentEmail}_${DateTime.now().millisecondsSinceEpoch}.pdf";
    Reference storageRef = FirebaseStorage.instance.ref().child("$folder/$fileName");

    UploadTask uploadTask = storageRef.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Assignment"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Student: ${widget.studentEmail}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 20),

                    if (widget.submittedFileUrl != null) ...[
                      const Text("Student's Submitted Assignment:"),
                      TextButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text("Download"),
                        onPressed: () async {
                          if (await canLaunchUrl(Uri.parse(widget.submittedFileUrl!))) {
                            await launchUrl(Uri.parse(widget.submittedFileUrl!));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Could not open the file.")),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: "Notes Title",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: "Notes",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: _gradeController,
                      decoration: InputDecoration(
                        labelText: "Grade (out of 10)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: _pickReviewFile,
                      icon: const Icon(Icons.upload),
                      label: Text(_reviewFile == null ? "Upload Review PDF" : "Review Selected"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _uploadReview,
                    icon: const Icon(Icons.send),
                    label: const Text("Send Review"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
