// import 'package:alpha_generations/group/assginment.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';

// class AllAssignmentsPage extends StatefulWidget {
//   const AllAssignmentsPage({super.key});

//   @override
//   _AllAssignmentsPageState createState() => _AllAssignmentsPageState();
// }

// class _AllAssignmentsPageState extends State<AllAssignmentsPage> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   List<Map<String, dynamic>> _assignments = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadAllAssignments();
//   }

//   Future<void> _loadAllAssignments() async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) return;

//       // جلب جميع الجروبات التي ينتمي إليها المستخدم
//       final userGroups = await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('groups')
//           .get();

//       List<Map<String, dynamic>> allAssignments = [];

//       // جلب جميع الإسمنتات من كل مجموعة
//       for (var groupDoc in userGroups.docs) {
//         final groupId = groupDoc.id;
//         final assignments = await _firestore
//             .collection('groups')
//             .doc(groupId)
//             .collection('assignments')
//             .get();

//         for (var assignmentDoc in assignments.docs) {
//           final assignmentData = assignmentDoc.data();
//           assignmentData['groupId'] = groupId;
//           assignmentData['assignmentId'] = assignmentDoc.id;
//           assignmentData['groupName'] = groupDoc.data()['name'] ?? 'مجموعة غير معروفة';
          
//           // جلب حالة التسليم إذا وجدت
//           final submission = await _firestore
//               .collection('groups')
//               .doc(groupId)
//               .collection('assignments')
//               .doc(assignmentDoc.id)
//               .collection('submissions')
//               .doc(user.uid)
//               .get();

//           assignmentData['isSubmitted'] = submission.exists;
//           assignmentData['submissionData'] = submission.data();
          
//           allAssignments.add(assignmentData);
//         }
//       }

//       setState(() {
//         _assignments = allAssignments;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('جميع الواجبات'),
//         centerTitle: true,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _assignments.isEmpty
//               ? const Center(child: Text('لا توجد واجبات متاحة'))
//               : ListView.builder(
//                   itemCount: _assignments.length,
//                   itemBuilder: (context, index) {
//                     final assignment = _assignments[index];
//                     return _buildAssignmentCard(assignment);
//                   },
//                 ),
//     );
//   }

//   Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
//     final deadline = (assignment['deadline'] as Timestamp?)?.toDate();
//     final isSubmitted = assignment['isSubmitted'] ?? false;
//     final submissionData = assignment['submissionData'] as Map<String, dynamic>?;
//     final grade = submissionData?['grade']?.toString();

//     return Card(
//       margin: const EdgeInsets.all(8.0),
//       child: InkWell(
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AssignmentDetailsPage(
//                 groupId: assignment['groupId'],
//                 assignmentId: assignment['assignmentId'],
//               ),
//             ),
//           );
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     assignment['title'] ?? 'بدون عنوان',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Chip(
//                     label: Text(assignment['groupName']),
//                     backgroundColor: Colors.blue[100],
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 assignment['description'] ?? 'لا يوجد وصف',
//                 style: TextStyle(color: Colors.grey[600]),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   const Icon(Icons.access_time, size: 16),
//                   const SizedBox(width: 8),
//                   Text(
//                     'آخر موعد: ${deadline != null ? DateFormat('yyyy-MM-dd - hh:mm a').format(deadline) : 'غير محدد'}',
//                     style: TextStyle(
//                       color: deadline != null && deadline.isBefore(DateTime.now())
//                           ? Colors.red
//                           : null,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Icon(
//                     isSubmitted ? Icons.check_circle : Icons.warning,
//                     color: isSubmitted ? Colors.green : Colors.orange,
//                     size: 16,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     isSubmitted ? 'تم التسليم' : 'لم يتم التسليم',
//                     style: TextStyle(
//                       color: isSubmitted ? Colors.green : Colors.orange,
//                     ),
//                   ),
//                   if (grade != null) ...[
//                     const Spacer(),
//                     Text(
//                       'الدرجة: $grade/10',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: _getGradeColor(grade),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getGradeColor(String grade) {
//     final numericGrade = double.tryParse(grade);
//     if (numericGrade == null) return Colors.black;
    
//     if (numericGrade >= 8.5) return Colors.green;
//     if (numericGrade >= 7) return Colors.blue;
//     if (numericGrade >= 5) return Colors.orange;
//     return Colors.red;
//   }
// }