import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddAssignment extends StatefulWidget {
  final String? assignmentId;
  final String? groupId;
  final Map<String, dynamic>? existingAssignment;

  const AddAssignment({
    super.key,
    this.assignmentId,
    this.groupId,
    this.existingAssignment,
  });

  @override
  _AddAssignmentState createState() => _AddAssignmentState();
}

class _AddAssignmentState extends State<AddAssignment> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noticeController = TextEditingController();
  DateTime? _deadline;
  File? _selectedFile;
  String? _selectedGroup;
  String? _userEmail;
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();

    if (widget.existingAssignment != null) {
      _titleController.text = widget.existingAssignment!['title'] ?? '';
      _noticeController.text = widget.existingAssignment!['notice'] ?? '';
      _deadline = widget.existingAssignment!['deadline']?.toDate();
      _selectedGroup = widget.groupId;
    }
  }

  Future<void> _fetchUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userEmail = userDoc.exists ? userDoc.get('email') : "Unknown";
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _isUploading = true;
      });
    }
  }

  Future<void> _pickDeadline(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _deadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<String?> _uploadFileToStorage() async {
    if (_selectedFile == null) return null;

    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.path.split('/').last}';
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('assignments/${_selectedGroup}/$fileName');

      UploadTask uploadTask = ref.putFile(_selectedFile!);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading file: $e")),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _addOrUpdateAssignment() async {
    if (_selectedGroup == null || _titleController.text.isEmpty || _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields!")),
      );
      return;
    }

    try {
      String? fileUrl = await _uploadFileToStorage();

      final assignmentData = {
        'title': _titleController.text,
        'notice': _noticeController.text,
        'deadline': Timestamp.fromDate(_deadline!),
        'fileUrl': fileUrl,
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'userEmail': _userEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.assignmentId == null) {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(_selectedGroup)
            .collection('assignments')
            .add(assignmentData);
      } else {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(_selectedGroup)
            .collection('assignments')
            .doc(widget.assignmentId)
            .update(assignmentData);
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignmentId == null ? 'Add Assignment' : 'Edit Assignment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGroupDropdown(),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _noticeController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildDeadlinePicker(),
              const SizedBox(height: 20),
              _buildFileUploadSection(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('groups').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        return DropdownButtonFormField<String>(
          value: _selectedGroup,
          decoration: const InputDecoration(
            labelText: 'Group *',
            border: OutlineInputBorder(),
          ),
          items: snapshot.data!.docs.map((group) {
            return DropdownMenuItem<String>(
              value: group.id,
              child: Text(group['name'] ?? 'Unnamed Group'),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedGroup = value),
        );
      },
    );
  }

  Widget _buildDeadlinePicker() {
    return InkWell(
      onTap: () => _pickDeadline(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Deadline *',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _deadline == null
                  ? 'Select deadline'
                  : DateFormat('yyyy-MM-dd HH:mm').format(_deadline!),
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assignment File',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_selectedFile != null) ...[
          Text('Selected: ${_selectedFile!.path.split('/').last}'),
          const SizedBox(height: 8),
        ],
        if (_isUploading)
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[200],
            color: Colors.blue,
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.attach_file),
          label: const Text('Select File'),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _addOrUpdateAssignment,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          widget.assignmentId == null ? 'Create Assignment' : 'Update Assignment',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}