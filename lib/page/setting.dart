import 'package:flutter/material.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _isDarkTheme = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';

  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkTheme = isDark;
    });
  }

  void _toggleNotifications(bool enabled) {
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  void _changeLanguage(String? language) {
    if (language != null) {
      setState(() {
        _selectedLanguage = language;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // صورة رمزية أو أيقونة
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profile.png'), // استبدل بمسار الصورة
              child: Icon(Icons.person, size: 50), // إذا لم تكن الصورة متوفرة
            ),
          ),
          const SizedBox(height: 20),

          // قسم الثيم
          Card(
            elevation: 2,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.color_lens),
                  title: Text('Theme'),
                ),
                SwitchListTile(
                  title: const Text('Dark Theme'),
                  value: _isDarkTheme,
                  onChanged: _toggleTheme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // قسم الإشعارات
          Card(
            elevation: 2,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text('Notifications'),
                ),
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // قسم اللغة
          Card(
            elevation: 2,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Language'),
                ),
                ListTile(
                  title: const Text('Select Language'),
                  trailing: DropdownButton<String>(
                    value: _selectedLanguage,
                    onChanged: _changeLanguage,
                    items: const [
                      DropdownMenuItem(value: 'English', child: Text('English')),
                      DropdownMenuItem(value: 'Arabic', child: Text('Arabic')),
                      DropdownMenuItem(value: 'French', child: Text('French')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // قسم حول الفريق
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About Team'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutTeamPage()),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // قسم اتصل بنا
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.contact_support),
              title: const Text('Contact Us'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactUsPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AboutTeamPage extends StatelessWidget {
  const AboutTeamPage({super.key});

  // بيانات الأعضاء
  final List<Map<String, String>> teamMembers = const [
    {
      'name': 'Dr-Hammad Ali',
      'role': 'Coordinator', // دور العضو
      'image': 'images/hammad.jpg', // استبدل بمسار الصورة
    },
    {
      'name': 'khaled Mahmoud',
      'role': 'assistant leader',
      'image': 'images/khaledMahmoud.jpg', // استبدل بمسار الصورة
    },
    {
      'name': 'Dr shady ouda',
      'role': 'Teacher',
      'image': 'images/shadyouda.jpg', // استبدل بمسار الصورة
    },
    {
      'name': 'Dr Mariam',
      'role': 'assistant',
      'image': 'images/Mariam.jpg', // استبدل بمسار الصورة
    },
    {
      'name': 'Dr Ahsrakat',
      'role': 'assistant',
      'image': 'images/Ahsrakat.jpg', // استبدل بمسار الصورة
    },{
      'name': 'Dr Nesma Nagah',
      'role': ' leader',
      'image': 'images/NesmaNagah.jpg', // استبدل بمسار الصورة
    },{
      'name': 'Dr Ahmed rezk',
      'role': 'assistant',
      'image': 'images/Ahmedrezk.jpg', // استبدل بمسار الصورة
    },{
      'name': 'Dr Ibrahim Gomaa',
      'role': 'assistant',
      'image': 'images/IbrahimGomaa.jpg', // استبدل بمسار الصورة
    },
    {
      'name': 'Dr Rahma Omara',
      'role': 'assistant',
      'image': 'images/RahmaOmara.jpg', // استبدل بمسار الصورة
    },
    // أضف باقي الأعضاء هنا
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Team'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Who Are We?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'We are a group of medical students dedicated to making learning a clear and engaging experience for our students. We believe that effective education is built on understanding and interaction, so we strive to present information in a simplified and practical way, supported by examples and scientific concepts. Our goal is to help students achieve their best academic performance while fostering a love for science and learning. We are committed to providing a supportive and enriching educational environment.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Our Team',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // عدد الأعمدة
                crossAxisSpacing: 10, // المسافة بين العناصر
                mainAxisSpacing: 10, // المسافة بين الصفوف
                childAspectRatio: 0.8, // نسبة العرض إلى الارتفاع
              ),
              itemCount: teamMembers.length, // عدد الأعضاء
              itemBuilder: (context, index) {
                final member = teamMembers[index];
                return Card(
                  elevation: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage(member['image']!),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        member['name']!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        member['role']!,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
      ),
      body: const Center(
        child: Text('WhatsApp: +96550189121'),
      ),
    );
  }
}