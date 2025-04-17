import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    
    // قائمة بالإيميلات اللي تعتبر أدمن
    final List<String> adminEmails = [
      "ahmedabotalib37@gmail.com",
      "nesmanagah2000@gmail.com",
      "rahmaomara554@gmail.com",
      "ha424361@gmail.com",
      "gomaaibrahim537@gmail.com",
      "ahmedrezkragab2592004@gmail.com",
      "Shadyfarag64@gmail.com",
      "Khaledelewa23@gmail.com",
      "ashrakat748@gmail.com"
    ];

    final bool isAdmin = user != null && adminEmails.contains(user.email);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LMS Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              children: [
                FadeInRight(
                  duration: const Duration(milliseconds: 500),
                  child: DashboardCard(
                    icon: Icons.groups,
                    title: 'My Groups',
                    onTap: () {
                      Navigator.of(context).pushNamed('grouplist');
                    },
                  ),
                ),
                FadeInRight(
                  duration: const Duration(milliseconds: 500),
                  child: DashboardCard(
                    icon: Icons.create_rounded,
                    title: 'Join Group',
                    onTap: () {
                      Navigator.of(context).pushNamed('groupjoin');
                    },
                  ),
                ),
                                FadeInRight(
                  duration: const Duration(milliseconds: 500),
                  child: DashboardCard(
                    icon: Icons.assignment_turned_in,
                    title: 'Quiz',
                    onTap: () {
                      Navigator.of(context).pushNamed('QuizPage');
                    },
                  ),
                ),

                if (isAdmin)
                  FadeInRight(
                    duration: const Duration(milliseconds: 500),
                    child: DashboardCard(
                      icon: Icons.admin_panel_settings,
                      title: 'Control Panel',
                      onTap: () {
                        Navigator.of(context).pushNamed('controlpanel');
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DashboardCard({super.key, required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 8,
        shadowColor: Colors.blueAccent.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 50.0, color: Colors.white),
                const SizedBox(height: 16.0),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
