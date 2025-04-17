import 'package:alpha_generations/group/VideoPlayerPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class CourseVideosPage extends StatefulWidget {
  final String groupId;

  const CourseVideosPage({super.key, required this.groupId});

  @override
  _CourseVideosPageState createState() => _CourseVideosPageState();
}

class _CourseVideosPageState extends State<CourseVideosPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool _isUploading = false;

  // قائمة بالإيميلات المسموح لها برفع المحاضرات
  final List<String> adminEmails = [
    "ahmedabotalib37@gmail.com",
    "nesmanagah2000@gmail.com",
    "rahmaomara554@gmail.com",
    "ha424361@gmail.com",
    "gomaaibrahim537@gmail.com",
    "ahmedrezkragab2592004@gmail.com",
    "Shadyfarag64@gmail.com",
    "Khaledelewa23@gmail.com",
    "ashrakat748@gmail.com"
  ];

  Future<void> _uploadLecture() async {
    try {
      if (widget.groupId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Group ID is missing!")),
        );
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No video selected!")),
        );
        return;
      }

      File file = File(result.files.single.path!);
      int fileSize = await file.length();

      if (fileSize > 100 * 1024 * 1024) { // ✅ تصحيح الحجم لـ 100MB
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File too large! Max size is 100MB.")),
        );
        return;
      }

      String fileName = "${DateTime.now().millisecondsSinceEpoch}.mp4";
      Reference storageRef = FirebaseStorage.instance.ref().child("lectures/$fileName");

      setState(() => _isUploading = true);

      UploadTask uploadTask = storageRef.putFile(
        file, 
        SettableMetadata(contentType: "video/mp4"),
      );

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      if (downloadUrl.isNotEmpty) {
        await FirebaseFirestore.instance.collection('groups')
            .doc(widget.groupId)
            .collection('lectures')
            .add({
          'title': _titleController.text.trim(),
          'details': _detailsController.text.trim(),
          'videoUrl': downloadUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lecture uploaded successfully!")),
        );
      } else {
        throw Exception("Download URL is empty");
      }
    } catch (e) {
      debugPrint("Upload error: $e"); // ✅ طباعة الخطأ لتسهيل تصحيحه
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload video. Please try again!")),
      );
    }

    setState(() => _isUploading = false);
    _titleController.clear();
    _detailsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final bool isAdmin = user != null && adminEmails.contains(user.email);

    return Scaffold(
      appBar: AppBar(title: const Text("Course Videos")),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _showUploadDialog(),
              child: const Icon(Icons.upload),
            )
          : null,
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('lectures')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No recorded lectures available"));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic>? lecture = doc.data() as Map<String, dynamic>?;
                    if (lecture == null) return const SizedBox();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.play_circle_fill, size: 50, color: Colors.blue),
                        title: Text(lecture['title'] ?? 'Untitled'),
                        subtitle: Text(lecture['details'] ?? 'No details'),
                        onTap: () {
                          if (lecture['videoUrl'] == null || lecture['videoUrl'].isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Error: Video URL is missing!")),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerPage(
                                videoUrl: lecture['videoUrl'],
                                title: lecture['title'] ?? 'Untitled',
                                details: lecture['details'] ?? 'No details',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Upload Lecture"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Lecture Title")),
            TextField(controller: _detailsController, decoration: const InputDecoration(labelText: "Lecture Details")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () {
            Navigator.pop(context);
            _uploadLecture();
          }, child: const Text("Upload")),
        ],
      ),
    );
  }

  @override
  void dispose() { // ✅ إضافة `dispose`
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }
}
