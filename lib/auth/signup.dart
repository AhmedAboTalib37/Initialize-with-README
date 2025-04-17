import 'package:alpha_generations/component/textfieldform.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  TextEditingController username = TextEditingController();
  bool _isLoading = false;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (password.text != confirmPassword.text) {
        _showErrorDialog('Passwords do not match.');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email.text,
          password: password.text,
        );

        User? user = credential.user;
        if (user != null) {
          await user.updateDisplayName(username.text);
          await user.reload();
          user = FirebaseAuth.instance.currentUser;

          await FirebaseFirestore.instance
              .collection("users")
              .doc(user?.uid)
              .set({
            "email": user?.email,
            "uid": user?.uid,
            "username": username.text,
            "createdAt": FieldValue.serverTimestamp(),
          });

          Navigator.of(context).pushReplacementNamed(
            'account',
            arguments: user,
          );
        }
      } on FirebaseAuthException catch (e) {
        _showErrorDialog(e.message ?? 'An error occurred.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(50),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_circle,
                      size: 140, color: Colors.blue),
                  const SizedBox(height: 20),
                  const Text(
                    'Sign up',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 50),
                  TextFieldForm(
                    hinttext: 'Username',
                    mycontroller: username,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter your username' : null,
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  TextFieldForm(
                    hinttext: 'Email',
                    mycontroller: email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  TextFieldForm(
                    hinttext: 'Password',
                    mycontroller: password,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  TextFieldForm(
                    hinttext: 'Confirm Password',
                    mycontroller: confirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != password.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    obscureText: true,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 110,
                    height: 50,
                    child: MaterialButton(
                      color: _isLoading
                          ? Colors.grey
                          : const Color.fromARGB(255, 169, 217, 224),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      onPressed: _isLoading ? null : _signUp,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text('Sign up'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushReplacementNamed('login'),
                    child: const Text(
                      'Already have an account? Login',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
