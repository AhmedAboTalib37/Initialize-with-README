import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';

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
  File? _submittedFile;
  String? _submittedFileUrl;
  bool _isSubmitted = false;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  bool _isLoading = true;
  DocumentSnapshot? _assignmentData;
  DocumentSnapshot? _userSubmission;
  String? _grade;
  String? _teacherNote;
  String? _correctionFileUrl;
  String? _assignmentFileUrl;
  final Dio _dio = Dio();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadData();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null && response.payload!.isNotEmpty) {
          await OpenFile.open(response.payload);
        }
      },
    );
  }

  Future<void> _showDownloadCompleteNotification(String filePath) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'download_channel',
      'تنزيل الملفات',
      channelDescription: 'إشعارات بخصوص الملفات المنزلة',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
      enableVibration: true,
    );
    
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    
    await flutterLocalNotificationsPlugin.show(
      0,
      'تم تنزيل الملف',
      'انقر لفتح الملف الذي تم تنزيله',
      notificationDetails,
      payload: filePath,
    );
  }

  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final assignment = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('assignments')
          .doc(widget.assignmentId)
          .get();

      final submission = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('assignments')
          .doc(widget.assignmentId)
          .collection('submissions')
          .doc(user.uid)
          .get();

      setState(() {
        _assignmentData = assignment;
        _userSubmission = submission;
        _isSubmitted = submission.exists;
        
        if (_isSubmitted) {
          final submissionData = submission.data();
          _submittedFileUrl = submissionData?['fileUrl'];
          _grade = submissionData?['grade']?.toString();
          _teacherNote = submissionData?['teacherNote'];
          _correctionFileUrl = submissionData?['correctionFileUrl'];
        }
        
        if (assignment.exists) {
          final assignmentData = assignment.data();
          _assignmentFileUrl = assignmentData?['fileUrl'];
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في تحميل البيانات: $e')),
      );
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _submittedFile = File(result.files.single.path!);
      });
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

      final storageRef = FirebaseStorage.instance.ref().child(
          'assignments_submissions/${user.uid}/${widget.assignmentId}/${_submittedFile!.path.split('/').last}');
      final uploadTask = storageRef.putFile(_submittedFile!);

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        setState(() {
          _uploadProgress = (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
        });
      });

      final fileUrl = await (await uploadTask).ref.getDownloadURL();

      final submissionRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('assignments')
          .doc(widget.assignmentId)
          .collection('submissions')
          .doc(user.uid);

      await submissionRef.set({
        'fileUrl': fileUrl,
        'fileName': _submittedFile!.path.split('/').last,
        'studentId': user.uid,
        'studentEmail': user.email,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'assignmentId': widget.assignmentId,
        'groupId': widget.groupId,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('assignments')
          .doc(widget.assignmentId)
          .update({
        'submissionCount': FieldValue.increment(1),
      });

      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسليم الواجب بنجاح'),
          backgroundColor: Colors.green,
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
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _launchURL(String? url) async {
    if (url == null) return;
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        await _downloadAndOpenFile(url);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في فتح الملف: $e')),
      );
    }
  }

  Future<void> _downloadAndOpenFile(String url) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري تحميل الملف...')),
      );

      final tempDir = await getTemporaryDirectory();
      final fileName = url.split('/').last;
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);

      await _dio.download(url, filePath);

      if (await canLaunchUrl(Uri.parse(filePath))) {
        await launchUrl(
          Uri.parse(filePath),
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد تطبيق لفتح هذا النوع من الملفات')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في تحميل الملف: $e')),
      );
    }
  }

  Future<void> _downloadFile(String url) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('تم رفض إذن التخزين');
      }

      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        throw Exception('لا يمكن الوصول إلى التخزين الخارجي');
      }

      final downloadsDir = Directory('${dir.path}/Download');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final fileName = url.split('/').last;
      final filePath = '${downloadsDir.path}/$fileName';
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري تحميل الملف...')),
      );

      await _dio.download(url, filePath);

      await _showDownloadCompleteNotification(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تنزيل الملف إلى مجلد التنزيلات')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التنزيل: $e')),
      );
    }
  }

  Widget _buildFileCard(String title, String? fileUrl, String? fileName, IconData icon, Color color) {
    if (fileUrl == null) return const SizedBox();
    
    IconData fileIcon = icon;
    if (fileName != null) {
      final lowerCaseName = fileName.toLowerCase();
      if (lowerCaseName.endsWith('.pdf')) {
        fileIcon = Icons.picture_as_pdf;
      } else if (lowerCaseName.endsWith('.doc') || lowerCaseName.endsWith('.docx')) {
        fileIcon = Icons.description;
      } else if (lowerCaseName.endsWith('.jpg') || lowerCaseName.endsWith('.jpeg') || 
                 lowerCaseName.endsWith('.png')) {
        fileIcon = Icons.image;
      } else if (lowerCaseName.endsWith('.xls') || lowerCaseName.endsWith('.xlsx')) {
        fileIcon = Icons.table_chart;
      }
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(fileIcon, color: color),
        title: Text(title),
        subtitle: Text(fileName ?? 'ملف مرفق'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _launchURL(fileUrl),
              tooltip: 'فتح الملف',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadFile(fileUrl),
              tooltip: 'تحميل الملف',
            ),
          ],
        ),
        onTap: () => _launchURL(fileUrl),
      ),
    );
  }

  Widget _buildSubmissionStatus() {
    return Card(
      color: _isSubmitted ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isSubmitted ? Icons.check_circle : Icons.warning,
                  color: _isSubmitted ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isSubmitted ? 'تم تسليم الواجب' : 'لم يتم تسليم الواجب بعد',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isSubmitted ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            if (_isSubmitted && _userSubmission != null && _userSubmission!.exists) ...[
              const SizedBox(height: 8),
              Text(
                'تاريخ التسليم: ${DateFormat('yyyy-MM-dd HH:mm').format(((_userSubmission!.data() as Map<String, dynamic>)['submittedAt'] as Timestamp).toDate())}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_assignmentData == null || !_assignmentData!.exists) {
      return const Center(child: Text('الواجب غير موجود'));
    }

    final assignment = _assignmentData!.data() as Map<String, dynamic>;
    final deadline = (assignment['deadline'] as Timestamp?)?.toDate();
    final createdAt = (assignment['createdAt'] as Timestamp?)?.toDate();

    return Scaffold(
      appBar: AppBar(
        title: Text(assignment['title'] ?? 'تفاصيل الواجب'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment['title'] ?? 'بدون عنوان',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      assignment['notice'] ?? 'لا يوجد وصف',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'تاريخ الإنشاء: ${createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt) : 'غير معروف'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'آخر موعد للتسليم: ${deadline != null ? DateFormat('yyyy-MM-dd HH:mm').format(deadline) : 'غير محدد'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: deadline != null && deadline.isBefore(DateTime.now())
                                ? Colors.red
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_assignmentFileUrl != null)
              _buildFileCard(
                'ملف الواجب',
                _assignmentFileUrl,
                _assignmentFileUrl?.split('/').last,
                Icons.assignment,
                Colors.blue,
              ),

            const SizedBox(height: 20),

            _buildSubmissionStatus(),

            if (_isSubmitted && _submittedFileUrl != null)
              _buildFileCard(
                'ملف التسليم',
                _submittedFileUrl,
                (_userSubmission?.data() as Map<String, dynamic>?)?['fileName'],
                Icons.upload_file,
                Colors.green,
              ),

            if (_isSubmitted && (_grade != null || _teacherNote != null))
              Card(
                elevation: 3,
                margin: const EdgeInsets.only(top: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'التقييم',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      if (_grade != null) ...[
                        Row(
                          children: [
                            const Text('الدرجة: '),
                            Text(
                              _grade!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getGradeColor(_grade!),
                              ),
                            ),
                            const Text(' / 10'),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_teacherNote != null) ...[
                        const Text(
                          'ملاحظات المعلم:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(_teacherNote!),
                      ],
                    ],
                  ),
                ),
              ),

            if (_isSubmitted && _correctionFileUrl != null)
              _buildFileCard(
                'ملف التصحيح',
                _correctionFileUrl,
                _correctionFileUrl?.split('/').last,
                Icons.fact_check,
                Colors.purple,
              ),

            if (!_isSubmitted) ...[
              const SizedBox(height: 20),
              const Text(
                'تسليم الواجب',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (_submittedFile != null) ...[
                Text('الملف المحدد: ${_submittedFile!.path.split('/').last}'),
                const SizedBox(height: 8),
              ],
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: const Text('اختيار ملف'),
              ),
              const SizedBox(height: 16),
              if (_isUploading) ...[
                LinearProgressIndicator(value: _uploadProgress / 100),
                const SizedBox(height: 8),
                Text('جاري الرفع: ${_uploadProgress.toStringAsFixed(1)}%'),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submittedFile != null ? _submitAssignment : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'تسليم الواجب',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    final numericGrade = double.tryParse(grade);
    if (numericGrade == null) return Colors.black;
    
    if (numericGrade >= 8.5) return Colors.green;
    if (numericGrade >= 7) return Colors.blue;
    if (numericGrade >= 5) return Colors.orange;
    return Colors.red;
  }
}