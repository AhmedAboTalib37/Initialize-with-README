import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? displayName;
  String? email;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // دالة لتحميل بيانات المستخدم
  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        displayName = user.displayName;
        email = user.email;

        // تعبئة الحقول بالنصوص الحالية
        _nameController.text = displayName ?? '';
        _emailController.text = email ?? '';
      });
    }
  }

  // دالة لتحديث بيانات المستخدم
  Future<void> _updateProfile() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        await user.updateProfile(displayName: _nameController.text);
        await user.reload();
        user = _auth.currentUser; // Refresh user data

        if (_emailController.text.isNotEmpty) {
          await user?.updateEmail(_emailController.text);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        // يمكنك العودة إلى الصفحة السابقة إذا رغبت
        Navigator.pop(context);
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFFf96163),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                //   primary: const Color(0xFFf96163),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}