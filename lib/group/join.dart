import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gr_view.dart';

class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({super.key});

  @override
  _JoinGroupPageState createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  String? groupId;
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _joinGroup() async {
    if (groupNameController.text.isEmpty || passwordController.text.isEmpty) return;

    QuerySnapshot groups = await FirebaseFirestore.instance
        .collection('groups')
        .where('name', isEqualTo: groupNameController.text)
        .where('password', isEqualTo: passwordController.text)
        .get();

    if (groups.docs.isNotEmpty) {
      DocumentSnapshot groupDoc = groups.docs.first;
      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;

      List<dynamic> members = groupData['members'];
      int maxMembers = groupData['maxMembers'] ?? 10;

      if (members.length >= maxMembers) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Group is full! Cannot join.")),
        );
        return;
      }

      await groupDoc.reference.update({
        'members': FieldValue.arrayUnion([userId])
      });

      setState(() {
        groupId = groupDoc.id;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect group name or password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (groupId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Join a Group"),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: groupNameController,
                    decoration: InputDecoration(
                      labelText: "Group Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      prefixIcon: const Icon(Icons.group),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: _joinGroup,
                      child: const Text(
                        "Join Group",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return GroupDetailPage(groupId: groupId!);
    }
  }
}