import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class AssignmentsGridView extends StatelessWidget {
  const AssignmentsGridView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('assignments').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Assignments Available"));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var document = snapshot.data!.docs[index];
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;

              // محاولة تحويل deadline إلى DateTime
              DateTime deadline;
              try {
                deadline = DateTime.parse(data['deadline'] ?? '');
              } catch (e) {
                deadline = DateTime.now();
              }

              // لو الديدلاين انتهى، مش هنعرض الكارد
              if (DateTime.now().isAfter(deadline)) return const SizedBox.shrink();

              bool isSubmitted = data.containsKey('submitted') ? data['submitted'] : false;
              Color cardColor = isSubmitted ? Colors.green : Colors.red.shade200;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignmentDetails(document: document),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Deadline: ${data['deadline'] ?? 'No Deadline'}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
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

class AssignmentDetails extends StatefulWidget {
  final QueryDocumentSnapshot document;
  const AssignmentDetails({super.key, required this.document});

  @override
  _AssignmentDetailsState createState() => _AssignmentDetailsState();
}

class _AssignmentDetailsState extends State<AssignmentDetails>
    with SingleTickerProviderStateMixin {
  String? uploadedFilePath;
  bool submitted = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        uploadedFilePath = result.files.single.path!;
      });
    }
  }

  Future<void> _submitAssignment() async {
    if (uploadedFilePath != null) {
      await FirebaseFirestore.instance.collection('submissions').add({
        'assignmentId': widget.document.id,
        'file': uploadedFilePath,
      });
      await FirebaseFirestore.instance
          .collection('assignments')
          .doc(widget.document.id)
          .update({'submitted': true});
      setState(() {
        submitted = true;
      });
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data =
        widget.document.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(title: Text(data['title'] ?? 'Assignment Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Notice:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(data['notice'] ?? 'No Notice'),
                const SizedBox(height: 16),
                const Text(
                  "Deadline:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(data['deadline'] ?? 'No Deadline'),
                const SizedBox(height: 16),
                if (data['file'] != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      // هنا ممكن تضيف كود تحميل الملف لو حابب
                      print("Downloading file: ${data['file']}");
                    },
                    icon: const Icon(Icons.download),
                    label: const Text("Download Assignment"),
                  ),
                const SizedBox(height: 16),
                // زر رفع الملف منفصل
                ElevatedButton.icon(
                  onPressed: _uploadFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload Answer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
                if (uploadedFilePath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "File Selected: ${uploadedFilePath!.split('/').last}",
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 16),
                // زر إرسال الإجابة منفصل
                ElevatedButton.icon(
                  onPressed: _submitAssignment,
                  icon: const Icon(Icons.send),
                  label: const Text("Submit Answer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                if (submitted)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text(
                      "Assignment Submitted Successfully!",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
