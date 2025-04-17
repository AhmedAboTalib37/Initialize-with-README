import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentDetailsPage extends StatefulWidget {
  final String groupId;
  final String assignmentId;

  const AssignmentDetailsPage({
    super.key,
    required this.groupId,
    required this.assignmentId,
  });

  @override
  _AssignmentDetailsPageState createState() => _AssignmentDetailsPageState();
}

class _AssignmentDetailsPageState extends State<AssignmentDetailsPage> {
  File? _submittedFile;
  String? _submittedFileUrl;
  String? _fileName;
  bool _isSubmitted = false;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  bool _isCheckingSubmission = true;
  DocumentSnapshot? _assignmentDetails;
  DocumentSnapshot? _userSubmission;
  String? _assignmentTitle;
  String? _assignmentDescription;

  @override
  void initState() {
    super.initState();
    _loadAssignmentDetails();
    _checkUserSubmission();
  }

  Future<void> _loadAssignmentDetails() async {
    try {
      final assignmentDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('assignments')
          .doc(widget.assignmentId)
          .get();

      if (assignmentDoc.exists) {
        setState(() {
          _assignmentDetails = assignmentDoc;
          _assignmentTitle = assignmentDoc['title'];
          _assignmentDescription = assignmentDoc['description'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل تفاصيل الواجب: $e')),
      );
    }
  }

  Future<void> _checkUserSubmission() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userSubmissionRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('assignments')
          .doc(widget.assignmentId)
          .collection('submissions')
          .doc(user.uid);

      final submission = await userSubmissionRef.get();

      setState(() {
        _isSubmitted = submission.exists;
        if (_isSubmitted) {
          _userSubmission = submission;
          _submittedFileUrl = submission['fileUrl'];
          _fileName = submission['fileName'];
        }
        _isCheckingSubmission = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingSubmission = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في التحقق من التسليم: $e')),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _submittedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختيار الملف: $e')),
      );
    }
  }

  Future<void> _submitAssignment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    if (_submittedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب اختيار ملف لتسليمه')),
      );
      return;
    }

    try {
      setState(() {
        _isUploading = true;
      });

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = _fileName?.split('.').last ?? 'file';
      final storageFileName = 'assignment_${widget.assignmentId}_$timestamp.$fileExtension';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('assignments/${widget.groupId}/${widget.assignmentId}/${user.uid}/$storageFileName');

      final uploadTask = storageRef.putFile(_submittedFile!);

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        setState(() {
          _uploadProgress = (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
        });
      });

      final TaskSnapshot uploadSnapshot = await uploadTask;
      final fileUrl = await uploadSnapshot.ref.getDownloadURL();

      final userSubmissionRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('assignments')
          .doc(widget.assignmentId)
          .collection('submissions')
          .doc(user.uid);

      await userSubmissionRef.set({
        'fileUrl': fileUrl,
        'fileName': _fileName,
        'fileSize': uploadSnapshot.totalBytes,
        'userId': user.uid,
        'userEmail': user.email,
        'submittedAt': FieldValue.serverTimestamp(),
        'lastModified': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'assignmentId': widget.assignmentId,
        'groupId': widget.groupId,
      }, SetOptions(merge: true));

      // Update submission count in assignment
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('assignments')
          .doc(widget.assignmentId)
          .update({
        'submissionCount': FieldValue.increment(1),
      });

      setState(() {
        _isSubmitted = true;
        _isUploading = false;
        _submittedFileUrl = fileUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسليم الواجب بنجاح'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تسليم الواجب: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل فتح الملف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_assignmentTitle ?? 'تفاصيل الواجب'),
        centerTitle: true,
      ),
      body: _isCheckingSubmission
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_assignmentTitle != null)
                    Text(
                      _assignmentTitle!,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  const SizedBox(height: 8),
                  if (_assignmentDescription != null)
                    Text(
                      _assignmentDescription!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  const SizedBox(height: 24),
                  Card(
                    color: _isSubmitted ? Colors.green[50] : Colors.orange[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isSubmitted ? Icons.check_circle : Icons.pending,
                                color: _isSubmitted ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isSubmitted ? 'تم التسليم' : 'لم يتم التسليم بعد',
                                style: TextStyle(
                                  color: _isSubmitted ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          if (_isSubmitted && _userSubmission != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'تاريخ التسليم: ${DateFormat('yyyy-MM-dd - hh:mm a').format((_userSubmission!['submittedAt'] as Timestamp).toDate())}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isSubmitted)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الملف المرفوع:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.attach_file),
                          title: Text(_fileName ?? 'ملف بدون اسم'),
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: _submittedFileUrl != null
                                ? () => _launchURL(_submittedFileUrl!)
                                : null,
                          ),
                          subtitle: _userSubmission?['fileSize'] != null
                              ? Text(
                                  '${(_userSubmission!['fileSize'] / 1024).toStringAsFixed(2)} KB')
                              : null,
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        const Text(
                          'قم برفع ملف لحل الواجب:',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.attach_file),
                          label: const Text('bbbاختيار ملف'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_submittedFile != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'تم اختيار: $_fileName',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _isUploading
                            ? Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: _uploadProgress / 100,
                                    backgroundColor: Colors.grey[200],
                                    color: Colors.blue,
                                    minHeight: 8,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'جاري الرفع: ${_uploadProgress.toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              )
                            : ElevatedButton.icon(
                                onPressed: _submittedFile != null
                                    ? _submitAssignment
                                    : null,
                                icon: const Icon(Icons.send),
                                label: const Text('تسليم الواجب'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                              ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}