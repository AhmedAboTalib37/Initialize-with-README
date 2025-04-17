import 'package:alpha_generations/component/textfieldform.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required String loginMessage});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();  // التحقق من حالة تسجيل الدخول عند بداية التطبيق
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      // إذا كان المستخدم مسجل دخول، نوجهه إلى الصفحة الرئيسية
      Navigator.of(context).pushReplacementNamed('home');
    }
  }

  Future<void> loginUser() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() => isLoading = true);

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text.trim(),
        );
        
        // حفظ حالة الجلسة بعد تسجيل الدخول بنجاح
        final prefs = await SharedPreferences.getInstance();
        prefs.setBool('isLoggedIn', true);

        Navigator.of(context).pushReplacementNamed('home');  // التوجيه للصفحة الرئيسية
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'An unexpected error occurred.';
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password provided.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Invalid email address.';
        }

        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: 'Error',
          desc: errorMessage,
          btnCancelOnPress: () {},
          btnOkOnPress: () {},
        ).show();
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // ✅ إذا كان مستخدم جديد، نحفظ بياناته في Firestore
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        User? user = userCredential.user;
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user?.uid)
            .set({
          "email": user?.email,
          "uid": user?.uid,
          "username": user?.displayName ?? '',
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      // حفظ حالة الجلسة بعد تسجيل الدخول بنجاح
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('isLoggedIn', true);

      return userCredential;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 50, bottom: 20),
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.asset(
                        'images/logo.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Login',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () =>
                            Navigator.of(context).pushNamed('reset'),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: MaterialButton(
                      color: isLoading
                          ? Colors.grey
                          : const Color.fromARGB(255, 169, 217, 224),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      onPressed: isLoading ? null : loginUser,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: MaterialButton(
                      color: const Color.fromARGB(255, 169, 217, 224),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      onPressed: () async {
                        setState(() => isLoading = true);
                        try {
                          final userCredential = await signInWithGoogle();
                          if (userCredential != null) {
                            Navigator.of(context)
                                .pushReplacementNamed('home');
                          } else {
                            throw Exception('Google Sign-In canceled.');
                          }
                        } catch (e) {
                          AwesomeDialog(
                            context: context,
                            dialogType: DialogType.error,
                            animType: AnimType.rightSlide,
                            title: 'Error',
                            desc: 'Failed to sign in with Google.',
                            btnCancelOnPress: () {},
                            btnOkOnPress: () {},
                          ).show();
                        } finally {
                          setState(() => isLoading = false);
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.g_mobiledata),
                          SizedBox(width: 10),
                          Text('Sign in with Google'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('signup'),
                    child: const Text(
                      'Don\'t have an account? Register now',
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
