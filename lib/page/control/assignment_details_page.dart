import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentDetailsPage extends StatefulWidget {
  final String assignmentId;
  final String userId;

  const AssignmentDetailsPage({super.key, required this.assignmentId, required this.userId});

  @override
  _AssignmentDetailsPageState createState() => _AssignmentDetailsPageState();
}

class _AssignmentDetailsPageState extends State<AssignmentDetailsPage> {
  Map<String, dynamic>? assignmentData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignment();
  }

  Future<void> _loadAssignment() async {
    try {
      DocumentSnapshot assignmentSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .collection("assignments")
          .doc(widget.assignmentId)
          .get();

      if (assignmentSnapshot.exists) {
        setState(() {
          assignmentData = assignmentSnapshot.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Assignment not found.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading assignment: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assignment  Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : assignmentData == null
              ? const Center(child: Text("No assignment data found."))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Title: ${assignmentData!["title"]}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text("Notes: ${assignmentData!["notice"]}", style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      Text("Grade: ${assignmentData!["grade"]}/10", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await launchUrl(Uri.parse(assignmentData!["fileUrl"]));
                        },
                        icon: const Icon(Icons.download),
                        label: const Text("Download PDF"),
                      ),
                    ],
                  ),
                ),
    );
  }
}
