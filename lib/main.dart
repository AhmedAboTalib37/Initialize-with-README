import 'package:alpha_generations/assignmentdetails/add.dart';
import 'package:alpha_generations/assignmentdetails/assignlist.dart';
import 'package:alpha_generations/assignmentdetails/assinmentrev.dart';
import 'package:alpha_generations/auth/acountpage.dart';
import 'package:alpha_generations/auth/login.dart';
import 'package:alpha_generations/auth/reset.dart';
import 'package:alpha_generations/group/gr_create.dart';
import 'package:alpha_generations/group/gr_view.dart';
import 'package:alpha_generations/group/groublist.dart';
import 'package:alpha_generations/group/groupjoin.dart';
import 'package:alpha_generations/group/join.dart';
import 'package:alpha_generations/page/assignmentrev.dart';
import 'package:alpha_generations/page/control/control.dart';
import 'package:alpha_generations/page/dashboard.dart';
import 'package:alpha_generations/page/splashscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:alpha_generations/HomePage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:alpha_generations/auth/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? userId;
  Widget initialScreen = const SplashScreen();
  String? deviceId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      deviceId = await _getDeviceId();
      await checkSession();
    } catch (e) {
      print('Initialization error: \$e');
      setState(() {
        initialScreen = const LoginPage(loginMessage: 'Initialization error. Please restart the app.');
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String> _getDeviceId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Theme.of(context).platform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'ios-device-\${DateTime.now().millisecondsSinceEpoch}';
      }
      return 'unknown-device-\${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      print('Error getting device ID: \$e');
      return 'error-device-\${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('userId');
    final savedDeviceId = prefs.getString('deviceId');

    if (savedUserId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(savedUserId)
            .get();

        if (userDoc.exists) {
          setState(() {
            userId = savedUserId;
            initialScreen = const HomePage();
          });
          return;
        }
      } catch (e) {
        print('Session check error: \$e');
      }
    }

    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        await _handleSignOut(prefs);
      } else {
        await _handleSignIn(user, prefs);
      }
    });
  }

  Future<void> _handleSignOut(SharedPreferences prefs) async {
    setState(() {
      userId = null;
      initialScreen = const LoginPage(loginMessage: '');
    });
  }

  Future<void> _handleSignIn(User user, SharedPreferences prefs) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      await prefs.setString('userId', user.uid);

      setState(() {
        userId = user.uid;
        initialScreen = const HomePage();
      });
    } catch (e) {
      print('Sign-in handling error: \$e');
      await _handleSignOut(prefs);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Alpha Gen',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: initialScreen,
      routes: {
        'login': (context) => const LoginPage(loginMessage: ''),
        'signup': (context) => const SignupPage(),
        'home': (context) => const HomePage(),
        'reset': (context) => const ResetPasswordPage(),
        'account': (context) => const AccountPage(),
        'DashboardPage': (context) => const DashboardPage(),
        'assignmentview': (context) => const AssignmentsGridView(),
        'AddAssignment': (context) => const AddAssignment(),
        'assignmentreview': (context) => const AssignmentReviewPage(),
        'groupview': (context) => GroupDetailPage(groupId: '10'),
        'groupcreate': (context) => const GroupPage(),
        'UserGroupsPage': (context) => UserGroupsPage(userId: userId ?? 'unknown'),
        'grouplist': (context) => const MyGroupsPage(),
        'controlpanel': (context) => const ControlPanelPage(),
        'groupjoin': (context) => const JoinGroupPage(),
        'StudentAssignmentsPage': (context) => const StudentAssignmentsPage(),
      },
    );
  }
}
