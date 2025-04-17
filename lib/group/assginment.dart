import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AssignmentDetailsPage extends StatefulWidget {
  final String groupId;
  final String assignmentId;

  const AssignmentDetailsPage({
    Key? key,
    required this.groupId,
    required this.assignmentId,
  }) : super(key: key);

  @override
  _AssignmentDetailsPageState createState() => _AssignmentDetailsPageState();
}

class _AssignmentDetailsPageState extends State<AssignmentDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? assignmentData;
  TextEditingController _noteController = TextEditingController();
  PlatformFile? pickedFile;
  UploadTask? uploadTask;
  String? uploadedFileUrl;
  String? studentEmail;

  @override
  void initState() {
    super.initState();
    _loadAssignmentDetails();
  }

  Future<void> _loadAssignmentDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('assignments')
          .doc(widget.assignmentId)
          .get();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        studentEmail = user.email;
      }

      if (doc.exists) {
        setState(() {
          assignmentData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading assignment: $e');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    setState(() => pickedFile = result.files.first);
  }

  Future<void> _uploadFile() async {
    if (pickedFile == null || studentEmail == null) return;

    final file = File(pickedFile!.path!);
    final fileName = pickedFile!.name;
    final destination = 'assignments/${widget.assignmentId}/$fileName';

    try {
      final ref = FirebaseStorage.instance.ref(destination);
      uploadTask = ref.putFile(file);

      final snapshot = await uploadTask!.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();

      setState(() {
        uploadedFileUrl = url;
      });
    } catch (e) {
      print('Upload error: $e');
    }
  }

  Future<void> _submitAssignment() async {
    if (studentEmail == null || (pickedFile == null && _noteController.text.isEmpty)) return;

    try {
      await _uploadFile();

      final submissionData = {
        'submittedAt': Timestamp.now(),
        'fileUrl': uploadedFileUrl ?? '',
        'note': _noteController.text.trim(),
        'userEmail': studentEmail,
        'fileName': pickedFile?.name ?? '',
      };

      // تحديث مستند الواجب الأصلي
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('assignments')
          .doc(widget.assignmentId)
          .update({
        'submission': submissionData,
      });

      // إضافة التسليم في مجموعة submissions (علشان المعلم يشوفه)
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('assignments')
          .doc(widget.assignmentId)
          .collection('submissions')
          .doc(studentEmail) // أو استخدم user.uid لو حابب
          .set(submissionData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم التسليم بنجاح')),
      );

      setState(() {
        pickedFile = null;
        _noteController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حصل خطأ أثناء التسليم: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الواجب')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: assignmentData == null
            ? const Text('لم يتم العثور على بيانات للواجب.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignmentData!['title'] ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(assignmentData!['note'] ?? ''),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'ملاحظتك (اختياري)'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(pickedFile == null ? 'اختار ملف' : pickedFile!.name),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitAssignment,
                    child: const Text('تسليم'),
                  ),
                ],
              ),
      ),
    );
  }
}
