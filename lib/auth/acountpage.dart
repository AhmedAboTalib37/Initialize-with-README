import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  File? _image;
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    _user = FirebaseAuth.instance.currentUser;
    await _user?.reload();
    setState(() {
      _imageUrl = _user?.photoURL ?? "";
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password", style: TextStyle(color: Colors.blueAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Old Password",
                labelStyle: TextStyle(color: Colors.blueAccent),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
              ),
            ),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password",
                labelStyle: TextStyle(color: Colors.blueAccent),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.blueAccent)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text.isNotEmpty) {
                try {
                  AuthCredential credential = EmailAuthProvider.credential(
                    email: _user!.email!,
                    password: oldPasswordController.text,
                  );
                  await _user!.reauthenticateWithCredential(credential);
                  await _user!.updatePassword(newPasswordController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password changed successfully")),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text("Change", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      setState(() {
        _image = file;
      });
      _uploadImage(file);
    }
  }

  Future<void> _uploadImage(File file) async {
    setState(() {
      _isLoading = true;
    });
    try {
      Reference ref = FirebaseStorage.instance.ref().child("profile_images/${_user!.uid}.jpg");
      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();
      await _user!.updatePhotoURL(downloadUrl);
      setState(() {
        _imageUrl = downloadUrl;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: ${e.toString()}")),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Account", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 65,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage: _image != null
                                  ? FileImage(_image!)
                                  : (_imageUrl != null && _imageUrl!.isNotEmpty
                                      ? NetworkImage(_imageUrl!)
                                      : const AssetImage('assets/default_profile.png')) as ImageProvider,
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(5),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.blueAccent),
                        title: Text(_user?.displayName ?? "No Name", style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: const Icon(Icons.email, color: Colors.blueAccent),
                        title: Text(_user?.email ?? "No Email", style: const TextStyle(fontSize: 18, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton.icon(
                        onPressed: _changePassword,
                        icon: const Icon(Icons.lock_outline),
                        label: const Text("Change Password"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 13, 53, 123),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
