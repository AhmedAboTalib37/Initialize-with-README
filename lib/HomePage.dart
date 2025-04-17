import 'package:alpha_generations/page/assignmentrev.dart';
import 'package:alpha_generations/page/dashboard.dart';
import 'package:alpha_generations/page/setting.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:alpha_generations/auth/acountpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user = FirebaseAuth.instance.currentUser;
  late Future<bool> isEmailVerified;
  late Future<Map<String, dynamic>?> userData;
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const StudentAssignmentsPage(),
    const SettingPage(),
    const AccountPage(),
  ];

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      isEmailVerified = checkEmailVerification();
      userData = getUserData();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil("login", (route) => false);
      });
    }

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil("login", (route) => false);
      } else if (mounted) {
        setState(() {
          this.user = user;
          isEmailVerified = checkEmailVerification();
          userData = getUserData();
        });
      }
    });
  }

  Future<bool> checkEmailVerification() async {
    try {
      await user?.reload();
      user = FirebaseAuth.instance.currentUser;
      return user?.emailVerified ?? false;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (user == null) return null;
    
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
          
      return userDoc.exists ? userDoc.data() as Map<String, dynamic> : null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  void sendVerificationEmail() async {
    await user?.sendEmailVerification();
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.rightSlide,
      title: 'Verification Email Sent',
      desc: 'Please check your email and verify your account.',
      btnOkText: 'OK',
      btnOkOnPress: () {},
    ).show();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil("login", (route) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Alpha Generations'),
      //   backgroundColor: Colors.redAccent,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.exit_to_app),
      //       onPressed: () {
      //         FirebaseAuth.instance.signOut();
      //         Navigator.of(context).pushNamedAndRemoveUntil("login", (route) => false);
      //       },
      //     ),
      //   ],
      // ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: userData,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (userSnapshot.hasError) {
            return _buildErrorScreen('Error loading user data');
          } else {
            final isBlocked = userSnapshot.data?['isBlocked'] ?? false;
            
            if (isBlocked) {
              return _buildBlockedMessage();
            } else {
              return FutureBuilder<bool>(
                future: isEmailVerified,
                builder: (context, verificationSnapshot) {
                  if (verificationSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (verificationSnapshot.hasError || !(verificationSnapshot.data ?? false)) {
                    return _buildVerificationPrompt();
                  } else {
                    return _pages[_currentIndex];
                  }
                },
              );
            }
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Review duties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Please verify your email to continue.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: sendVerificationEmail,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Resend Verification Email'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isEmailVerified = checkEmailVerification();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('I have verified my email'),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          const Text(
            'Your account has been blocked',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please contact support to resolve this issue',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil("login", (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              setState(() {
                userData = getUserData();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}