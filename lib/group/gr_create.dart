import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gr_view.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  String? groupId;
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController maxMembersController = TextEditingController();

  Future<void> _createGroup() async {
    if (groupNameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        maxMembersController.text.isEmpty) return;

    int maxMembers = int.tryParse(maxMembersController.text) ?? 10;

    DocumentReference groupRef = await FirebaseFirestore.instance.collection('groups').add({
      'name': groupNameController.text,
      'password': passwordController.text, // ⚠️ يفضل تشفيرها
      'ownerId': userId,
      'members': [userId],
      'maxMembers': maxMembers,
      'icon': 'https://via.placeholder.com/150' // صورة افتراضية
    });

    setState(() {
      groupId = groupRef.id;
    });
  }

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
        appBar: AppBar(title: const Text("Join or Create a Group")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: groupNameController,
                decoration: const InputDecoration(labelText: "Group Name"),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              TextField(
                controller: maxMembersController,
                decoration: const InputDecoration(labelText: "Max Members"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _createGroup,
                child: const Text("Create Group"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _joinGroup,
                child: const Text("Join Group"),
              ),
            ],
          ),
        ),
      );
    } else {
      return GroupDetailPage(groupId: groupId!);
    }
  }
}
