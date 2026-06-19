import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'story_list_screen.dart';
import 'home_page.dart';
import '../app_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Guest';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5), // Cheerful off-white pastel background
      body: CustomScrollView(
        slivers: [
          // Playful Parent & Toddler themed Header
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false, // Disables back button
            backgroundColor: Colors.transparent,
            actions: [
              if (user != null)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935), // Bold Red background
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pushReplacement(
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      'LOGOUT',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                    ),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: const Icon(Icons.login_rounded, color: Color(0xFF6C63FF), size: 18),
                    label: const Text(
                      'LOGIN',
                      style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
            ],
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
                  'STORY-LAND',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 18,
                  ),
                ),
                background: Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 90,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),
          
          // Stories Selection Columns & Rows
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      // Friendly Intro
                      const Text(
                        '📚 Read a Story Together!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3F3D56),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome, ${AppState().customDisplayName.isNotEmpty ? AppState().customDisplayName : displayName}! 👋',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6C63FF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select an age range to browse custom DOC or PDF adventures.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // Column Headers: DOC stories vs PDF stories
                      Row(
                        children: [
                          Expanded(
                            child: _buildColumnHeader(
                              title: 'DOC Stories',
                              icon: Icons.description_rounded,
                              color: const Color(0xFF2196F3), // Clean Blue
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildColumnHeader(
                              title: 'PDF Stories',
                              icon: Icons.picture_as_pdf_rounded,
                              color: const Color(0xFFE91E63), // Clean Pink/Red
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Row 1: Ages 0-4
                      _buildAgeRow(
                        context,
                        ageLabel: 'Ages 0-4',
                        imageUrl: 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?auto=format&fit=crop&q=80&w=400',
                      ),
                      const SizedBox(height: 20),

                      // Row 2: Ages 4-8
                      _buildAgeRow(
                        context,
                        ageLabel: 'Ages 4-8',
                        imageUrl: 'https://images.unsplash.com/photo-1516627145497-ae6968895b74?auto=format&fit=crop&q=80&w=400',
                      ),
                      const SizedBox(height: 20),

                      // Row 3: Ages 8-12
                      _buildAgeRow(
                        context,
                        ageLabel: 'Ages 8-12',
                        imageUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&q=80&w=400',
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Authors: Einav Momi Ben Shushan & Chen Tzafir',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeRow(
    BuildContext context, {
    required String ageLabel,
    required String imageUrl,
  }) {
    return Row(
      children: [
        // Left Column Card (Word)
        Expanded(
          child: _buildStoryCard(
            context,
            ageLabel: ageLabel,
            imageUrl: imageUrl,
            fileType: 'word',
            color: const Color(0xFF2196F3),
            icon: Icons.description_rounded,
          ),
        ),
        const SizedBox(width: 16),
        // Right Column Card (PDF)
        Expanded(
          child: _buildStoryCard(
            context,
            ageLabel: ageLabel,
            imageUrl: imageUrl,
            fileType: 'pdf',
            color: const Color(0xFFE91E63),
            icon: Icons.picture_as_pdf_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStoryCard(
    BuildContext context, {
    required String ageLabel,
    required String imageUrl,
    required String fileType,
    required Color color,
    required IconData icon,
  }) {
    final title = '$ageLabel ${fileType == 'word' ? 'doc' : fileType}';
    final categoryKey = '${ageLabel.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_')}_$fileType';

    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Image
            Image.network(
              imageUrl,
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            // Playful Pastel Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.2),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Details & Tap target
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoryListScreen(
                        categoryTitle: title,
                        categoryKey: categoryKey,
                        fileType: fileType,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: color, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              fileType == 'word' ? 'DOC' : fileType.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Age label
                      Text(
                        ageLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
