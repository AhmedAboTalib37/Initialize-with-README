import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class AssignmentReviewPage extends StatefulWidget {
  const AssignmentReviewPage({super.key});

  @override
  _AssignmentReviewPageState createState() => _AssignmentReviewPageState();
}

class _AssignmentReviewPageState extends State<AssignmentReviewPage> {
  // متغير لتخزين الassignment المختار من القائمة
  QueryDocumentSnapshot? selectedAssignment;
  // المتغيرات الخاصة بعملية التصحيح
  String? correctionFilePath;
  double rating = 5.0; // القيمة الافتراضية للتقييم من 0 لـ 10
  bool submitted = false;

  Future<void> _uploadCorrectionFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        correctionFilePath = result.files.single.path;
      });
    }
  }

  Future<void> _submitCorrection(String submissionId) async {
    if (correctionFilePath != null) {
      await FirebaseFirestore.instance.collection('corrections').add({
        'submissionId': submissionId,
        'correctionFile': correctionFilePath,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        submitted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // إذا لم يتم اختيار assignment، نظهر القائمة
    if (selectedAssignment == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Select an Assignment"),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('assignments')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No assignments found."));
            }
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var assignmentDoc = snapshot.data!.docs[index];
                var data = assignmentDoc.data() as Map<String, dynamic>;
                return ListTile(
                  // تغيير لون الخلفية لكل عنصر حسب حالة التصحيح
                  tileColor: (data.containsKey('submitted') && data['submitted'] == true)
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  title: Text(data['title'] ?? 'No Title'),
                  subtitle: Text(data['deadline'] ?? 'No Deadline'),
                  onTap: () {
                    setState(() {
                      selectedAssignment = assignmentDoc;
                      // إعادة تعيين المتغيرات الخاصة بالتصحيح في حالة اختيار assignment جديد
                      submitted = false;
                      correctionFilePath = null;
                      rating = 5.0;
                    });
                  },
                );
              },
            );
          },
        ),
      );
    }
    // إذا تم اختيار assignment، نظهر واجهة التصحيح
    else {
      var assignmentData =
          selectedAssignment!.data() as Map<String, dynamic>;
      return Scaffold(
        // تغيير لون الخلفية بناءً على حالة التصحيح
        backgroundColor: submitted ? Colors.green.shade100 : Colors.red.shade100,
        appBar: AppBar(
          title: Text(assignmentData['title'] ?? 'Review Assignment'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                selectedAssignment = null;
                submitted = false;
                correctionFilePath = null;
                rating = 5.0;
              });
            },
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('submissions')
              .where('assignmentId', isEqualTo: selectedAssignment!.id)
              .snapshots(),
          builder: (context, submissionSnapshot) {
            if (submissionSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!submissionSnapshot.hasData ||
                submissionSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No submission found"));
            }
            // نفترض هنا وجود submission واحد لكل assignment
            var submissionDoc = submissionSnapshot.data!.docs.first;
            var submissionData =
                submissionDoc.data() as Map<String, dynamic>;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Student Response:",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  submissionData['file'] != null
                      ? ElevatedButton.icon(
                          onPressed: () {
                            // هنا تضيف كود لتحميل الملف لو حابب
                            print(
                                "Downloading file: ${submissionData['file']}");
                          },
                          icon: const Icon(Icons.download),
                          label: const Text("Download Response"),
                        )
                      : const Text("No submission file available."),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    "Upload Correction File:",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _uploadCorrectionFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload Correction File"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue),
                  ),
                  if (correctionFilePath != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Selected file: ${correctionFilePath!.split('/').last}",
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    "Rating: ${rating.toInt()}/10",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Slider(
                    value: rating,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: rating.toInt().toString(),
                    onChanged: (value) {
                      setState(() {
                        rating = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _submitCorrection(submissionDoc.id),
                    icon: const Icon(Icons.send),
                    label: const Text("Submit Correction"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                  ),
                  if (submitted)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text(
                        "Correction submitted successfully!",
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    }
  }
}
