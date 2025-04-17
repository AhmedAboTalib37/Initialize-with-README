import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherAllAssignmentsPage extends StatefulWidget {
  const TeacherAllAssignmentsPage({super.key});

  @override
  _TeacherAllAssignmentsPageState createState() => _TeacherAllAssignmentsPageState();
}

class _TeacherAllAssignmentsPageState extends State<TeacherAllAssignmentsPage> {
  final Map<String, TextEditingController> _gradeControllers = {};

  @override
  void dispose() {
    _gradeControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع الواجبات في المجموعات',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('assignments')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ));
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('حدث خطأ: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('لا توجد واجبات حتى الآن',
                    style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final assignment = snapshot.data!.docs[index];
              final data = assignment.data() as Map<String, dynamic>;
              final assignmentId = assignment.id;
              final groupId = _getGroupIdFromReference(assignment.reference);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group and assignment info
                      _buildSectionTitle('المجموعة: ${data['groupName'] ?? 'غير معروف'}'),
                      _buildSectionTitle('عنوان الواجب: ${data['title'] ?? 'لا يوجد عنوان'}'),
                      Text(
                        'تم الإنشاء في: ${DateFormat('yyyy-MM-dd - hh:mm a').format((data['createdAt'] as Timestamp).toDate())}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      
                      // Display submission count if available
                      if (data['submissionCount'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'عدد التسليمات: ${data['submissionCount']}',
                            style: TextStyle(color: Colors.green[700], fontSize: 14),
                          ),
                        ),
                      
                      const Divider(height: 24, thickness: 1),

                      // View submissions button
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TeacherSubmissionsPage(
                                  groupId: groupId,
                                  assignmentId: assignmentId,
                                  assignmentTitle: data['title'] ?? 'واجب بدون عنوان',
                                ),
                              ),
                            );
                          },
                          child: const Text('عرض تسليمات الطلاب'),
                        ),
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

  String _getGroupIdFromReference(DocumentReference ref) {
    // المسار: groups/{groupId}/assignments/{assignmentId}
    final path = ref.path.split('/');
    return path[1]; // groupId هو العنصر الثاني في المسار
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue),
      ),
    );
  }
}

class TeacherSubmissionsPage extends StatefulWidget {
  final String groupId;
  final String assignmentId;
  final String assignmentTitle;

  const TeacherSubmissionsPage({
    super.key,
    required this.groupId,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  @override
  _TeacherSubmissionsPageState createState() => _TeacherSubmissionsPageState();
}

class _TeacherSubmissionsPageState extends State<TeacherSubmissionsPage> {
  final Map<String, TextEditingController> _gradeControllers = {};
  final Map<String, TextEditingController> _noteControllers = {};

  @override
  void dispose() {
    _gradeControllers.forEach((key, controller) => controller.dispose());
    _noteControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تسليمات: ${widget.assignmentTitle}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded, size: 26),
            onPressed: _saveAllGradesAndNotes,
            tooltip: 'حفظ جميع التقديرات والملاحظات',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('assignments')
            .doc(widget.assignmentId)
            .collection('submissions')
            .orderBy('submittedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ));
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('حدث خطأ: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('لا توجد تسليمات حتى الآن',
                    style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final submission = snapshot.data!.docs[index];
              final data = submission.data() as Map<String, dynamic>;
              final submissionId = submission.id;

              // Initialize controllers if not exists
              if (!_gradeControllers.containsKey(submissionId)) {
                final grade = data['grade']?.toString() ?? '';
                _gradeControllers[submissionId] = TextEditingController(text: grade);
              }
              
              if (!_noteControllers.containsKey(submissionId)) {
                final note = data['teacherNote']?.toString() ?? '';
                _noteControllers[submissionId] = TextEditingController(text: note);
              }

              return _buildSubmissionCard(data, submission.reference);
            },
          );
        },
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> data, DocumentReference submissionRef) {
    final submissionId = submissionRef.id;
    final submittedDate = (data['submittedAt'] as Timestamp).toDate();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  radius: 20,
                  child: Text(
                    data['studentEmail']?.toString().substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['studentEmail'] ?? 'بريد غير معروف',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تم التسليم: ${DateFormat('yyyy-MM-dd - hh:mm a').format(submittedDate)}',
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),

            // Submitted file
            if (data['fileUrl'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('ملف الحل المرفق'),
                  InkWell(
                    onTap: () => _launchFile(data['fileUrl']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color.fromARGB(255, 94, 112, 126)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file,
                              size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'فتح الملف',
                            style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Teacher notes
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('ملاحظات المعلم'),
                TextField(
                  controller: _noteControllers[submissionId],
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'أدخل ملاحظاتك هنا...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Grading section
            _buildSectionTitle('تقييم الواجب'),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _gradeControllers[submissionId],
                    decoration: InputDecoration(
                      labelText: 'إدخال التقدير',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () => _saveGradeAndNote(submissionRef),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('حفظ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (data['gradedAt'] != null)
              Text(
                'تم التقييم في: ${DateFormat('yyyy-MM-dd - hh:mm a').format((data['gradedAt'] as Timestamp).toDate())}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue),
      ),
    );
  }

  Future<void> _launchFile(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن فتح الملف: $url'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _saveGradeAndNote(DocumentReference submissionRef) async {
    final submissionId = submissionRef.id;
    final gradeText = _gradeControllers[submissionId]!.text;
    final noteText = _noteControllers[submissionId]!.text;

    try {
      final grade = gradeText.isNotEmpty ? double.tryParse(gradeText) : null;
      
      await submissionRef.update({
        if (grade != null) 'grade': grade,
        'teacherNote': noteText,
        'gradedAt': FieldValue.serverTimestamp(),
        'gradedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حفظ التقدير والملاحظات بنجاح'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الحفظ: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _saveAllGradesAndNotes() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (var entry in _gradeControllers.entries) {
        final submissionId = entry.key;
        final gradeText = entry.value.text;
        final noteText = _noteControllers[submissionId]?.text ?? '';
        final grade = gradeText.isNotEmpty ? double.tryParse(gradeText) : null;
        
        final submissionRef = FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('assignments')
            .doc(widget.assignmentId)
            .collection('submissions')
            .doc(submissionId);
        
        batch.update(submissionRef, {
          if (grade != null) 'grade': grade,
          'teacherNote': noteText,
          'gradedAt': FieldValue.serverTimestamp(),
          'gradedBy': FirebaseAuth.instance.currentUser?.uid,
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حفظ جميع التقديرات والملاحظات بنجاح'),
          backgroundColor: Colors.blue[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الحفظ: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}