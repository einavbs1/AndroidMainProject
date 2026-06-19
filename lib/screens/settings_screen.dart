import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          // Collapsing Header
          SliverAppBar(
            expandedHeight: 150.0,
            pinned: true,
            automaticallyImplyLeading: false, // Ensure no back button is displayed
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFB74D), // Soft warm pastel orange
                    Color(0xFFE1BEE7), // Soft pastel purple
                    Color(0xFF81C784), // Soft pastel green
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text(
                  'SETTINGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    fontSize: 16,
                  ),
                ),
                background: Center(
                  child: Icon(
                    Icons.settings_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
          ),

          // Settings Items
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Preferences'),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          children: [
                            SwitchListTile(
                              title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3F3D56))),
                              subtitle: const Text('Get real-time updates on your bookings'),
                              value: _notificationsEnabled,
                              activeColor: const Color(0xFF6C63FF),
                              onChanged: (bool value) {
                                setState(() {
                                  _notificationsEnabled = value;
                                });
                              },
                              secondary: const Icon(Icons.notifications_active_outlined, color: Color(0xFF6C63FF)),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3F3D56))),
                              subtitle: const Text('Toggle between dark and light themes'),
                              value: _darkModeEnabled,
                              activeColor: const Color(0xFF6C63FF),
                              onChanged: (bool value) {
                                setState(() {
                                  _darkModeEnabled = value;
                                });
                              },
                              secondary: const Icon(Icons.dark_mode_outlined, color: Color(0xFF6C63FF)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),
                        _buildSectionHeader('Support & Legal'),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF6C63FF)),
                              title: const Text('Help Center', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3F3D56))),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {},
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.gavel_outlined, color: Color(0xFF6C63FF)),
                              title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3F3D56))),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {},
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF6C63FF)),
                              title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3F3D56))),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {},
                            ),
                            const Divider(height: 1),
                            const ListTile(
                              leading: Icon(Icons.people_outline_rounded, color: Color(0xFF6C63FF)),
                              title: Text('Authors', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3F3D56))),
                              subtitle: Text('Einav Momi Ben Shushan & Chen Tzafir'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                        
                        // Red Danger Signout Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                Navigator.of(context, rootNavigator: true).pushReplacement(
                                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.logout),
                            label: const Text('LOGOUT FROM ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.grey[500],
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: children),
      ),
    );
  }

}
