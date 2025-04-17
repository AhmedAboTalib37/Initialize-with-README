import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageGroupsPage extends StatelessWidget {
  const ManageGroupsPage({super.key});

  void _editGroup(BuildContext context, String groupId, String currentName) {
    TextEditingController nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Group'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Group Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('groups').doc(groupId).update({
                  'name': nameController.text,
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteGroup(String groupId) {
    FirebaseFirestore.instance.collection('groups').doc(groupId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Groups'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Group'),
              onPressed: () {
                Navigator.of(context).pushNamed('groupcreate');
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('groups').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var groups = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      var group = groups[index].data() as Map<String, dynamic>;
                      String groupId = groups[index].id;
                      return Card(
                        child: ListTile(
                          title: Text(group['name'] ?? 'Unnamed Group'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () => _editGroup(context, groupId, group['name'] ?? ''),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteGroup(groupId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}