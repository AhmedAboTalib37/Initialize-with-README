import 'package:alpha_generations/group/gr_view.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// استيراد صفحة التفاصيل

class UserGroupsPage extends StatelessWidget {
  final String userId;

  const UserGroupsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Groups")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .where('members', arrayContains: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("You are not in any groups"));
          }

          var groups = snapshot.data!.docs;

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              var groupData = groups[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(groupData['name']),
                subtitle: Text("Owner: ${groupData['ownerId']}"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupDetailPage(
                        groupId: groups[index].id,
                     
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
