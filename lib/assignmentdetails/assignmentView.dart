// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class AssignmentView extends StatelessWidget {
//   final String title;
//   final String description;
//   final DateTime dueDate;
//   final String? fileUrl; // رابط الملف لو موجود

//   const AssignmentView({
//     super.key,
//     required this.title,
//     required this.description,
//     required this.dueDate,
//     this.fileUrl, // إضافة الملف كاختياري
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Assignment Details'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               description,
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Due Date: ${DateFormat('yyyy-MM-dd HH:mm').format(dueDate)}',
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),
//             if (fileUrl != null) // لو فيه ملف مرفق، اعرض الزر
//               Center(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // فتح الملف في المتصفح أو تحميله
//                     _openFile(fileUrl!);
//                   },
//                   child: const Text('Download File'),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _openFile(String url) {
//     // هنا تقدر تستخدم أي مكتبة زي url_launcher لفتح الرابط
//     print("Opening file: $url");
//   }
// }
