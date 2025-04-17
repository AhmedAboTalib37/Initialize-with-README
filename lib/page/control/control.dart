import 'package:alpha_generations/page/control/manageassignment.dart';
import 'package:alpha_generations/page/control/managegroup.dart';
import 'package:alpha_generations/page/control/subassinment.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ControlPanelPage extends StatelessWidget {
  const ControlPanelPage({super.key});

  // Function to toggle user block status
  void _toggleUserBlock(String userId, bool isCurrentlyBlocked) {
    FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isBlocked': !isCurrentlyBlocked,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Panel'),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.assignment_add),
              label: const Text('Add Assignment'),
              onPressed: () {
                Navigator.of(context).pushNamed('AddAssignment');
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Manage Assignments'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ManageAssignmentsPage()),
                );
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.group_add),
              label: const Text('Create Group'),
              onPressed: () {
                Navigator.of(context).pushNamed('groupcreate');
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.groups),
              label: const Text('Manage Groups'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ManageGroupsPage()),
                );
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.assignment_turned_in),
              label: const Text('Review Submissions'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const TeacherAllAssignmentsPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Registered Users:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var users = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      var user = users[index].data() as Map<String, dynamic>;
                      var userId = users[index].id;
                      bool isBlocked = user['isBlocked'] ?? false;
                      
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(user['username'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'] ?? 'No Email'),
                            Text(
                              isBlocked ? 'Status: Blocked' : 'Status: Active',
                              style: TextStyle(
                                color: isBlocked ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            isBlocked ? Icons.lock_open : Icons.block,
                            color: isBlocked ? Colors.green : Colors.red,
                          ),
                          onPressed: () {
                            _toggleUserBlock(userId, isBlocked);
                          },
                          tooltip: isBlocked ? 'Unblock User' : 'Block User',
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