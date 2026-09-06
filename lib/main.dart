import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MicWhispersApp());
}

class MicWhispersApp extends StatelessWidget {
  const MicWhispersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIC Whispers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          secondary: Color(0xFFF59E0B),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/* ============================================================================
   AUTH GATE: Listen to Auth state changes
============================================================================ */

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigationScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

/* ============================================================================
   AUTH SCREEN: Quick Student Login / Sign Up
============================================================================ */

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _handleController = TextEditingController(text: 'Silent Falcon');
  String _department = 'BSc Computer Science';
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _departments = [
    'BSc Computer Science',
    'BCA',
    'BBA',
    'B.Com',
    'BA English',
    'Campus Faculty / Staff',
  ];

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Save initial profile
        if (cred.user != null) {
          await cred.user!.updateDisplayName(_handleController.text.trim());
          await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .set({
            'handle': _handleController.text.trim().isEmpty
                ? 'Student #${cred.user!.uid.substring(0, 4)}'
                : _handleController.text.trim(),
            'department': _department,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Authentication failed.');
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 1-Click Quick Access for fast live demoing
  Future<void> _quickStudentDemoAccess() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final randomId = DateTime.now().millisecondsSinceEpoch % 10000;
    final demoEmail = 'student_$randomId@miccampus.in';
    const demoPassword = 'micwhispers2026';

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: demoEmail,
        password: demoPassword,
      );
      if (cred.user != null) {
        final demoHandle = 'Campus Whisperer #$randomId';
        await cred.user!.updateDisplayName(demoHandle);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'handle': demoHandle,
          'department': 'BSc Computer Science',
          'email': demoEmail,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Fallback if anonymous is enabled
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (err) {
        setState(() => _errorMessage = 'Quick login failed: $err');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0x2610B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF10B981), width: 2),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF10B981),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'MIC Whispers',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Encrypted Campus Social Hub • MIC Arts & Science College',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 28),

                // Error alert
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Auth Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSignUp ? 'Create Student Persona' : 'Student Sign In',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_isSignUp) ...[
                        // Handle
                        TextField(
                          controller: _handleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Anonymous Handle (e.g. Shadow Ninja)',
                            labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFF334155)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Department Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _department,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Department',
                            labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFF334155)),
                            ),
                          ),
                          items: _departments.map((d) {
                            return DropdownMenuItem(value: d, child: Text(d));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _department = val);
                          },
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'College / Personal Email',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFF334155)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFF334155)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  _isSignUp ? 'Sign Up & Enter' : 'Sign In',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Toggle Sign Up / Sign In
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              setState(() => _isSignUp = !_isSignUp),
                          child: Text(
                            _isSignUp
                                ? 'Already have an account? Sign In'
                                : 'New student? Create Persona',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Demo Entry Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _quickStudentDemoAccess,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.flash_on_rounded,
                        color: Color(0xFFF59E0B)),
                    label: const Text(
                      '⚡ 1-Click Fast Student Entry (No Typing)',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
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

/* ============================================================================
   MAIN NAVIGATION SCREEN (Feed & Persona Tabs)
============================================================================ */

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTabIndex = 0;
  String _selectedFilter = '🔥 Top Liked';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0x2610B981),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MIC Whispers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Cloud Sync • Live',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B)),
            tooltip: 'Product Roadmap & AI Scope',
            onPressed: () => _showRoadmapDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _currentTabIndex == 0
          ? _buildRealtimeFeedView()
          : const PersonaProfileView(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF334155), width: 0.8),
          ),
        ),
        child: NavigationBar(
          backgroundColor: const Color(0xFF0F172A),
          indicatorColor: const Color(0x3310B981),
          selectedIndex: _currentTabIndex,
          onDestinationSelected: (index) {
            setState(() => _currentTabIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dynamic_feed_rounded, color: Color(0xFF94A3B8)),
              selectedIcon:
                  Icon(Icons.dynamic_feed_rounded, color: Color(0xFF10B981)),
              label: 'Live Whispers',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8)),
              selectedIcon:
                  Icon(Icons.person_rounded, color: Color(0xFF10B981)),
              label: 'My Persona',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showPostWhisperSheet(context),
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                'Post Whisper',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            )
          : null,
    );
  }

  /* ==========================================================================
     FIRESTORE REAL-TIME STREAM FEED
  ========================================================================== */

  Widget _buildRealtimeFeedView() {
    final filters = [
      '🔥 Top Liked',
      '⏱️ Recent',
      'Campus Life',
      'Exams & Lab',
      'Canteen & Chai',
      'Confessions',
    ];

    return Column(
      children: [
        // Algorithmic Filter Chips
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = _selectedFilter == filter;

              return ChoiceChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF10B981),
                backgroundColor: const Color(0xFF1E293B),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : const Color(0xFF334155),
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _selectedFilter = filter);
                },
              );
            },
          ),
        ),

        // Live Firestore Query Stream
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('whispers')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF10B981)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Firestore Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 54, color: Color(0xFF64748B)),
                      const SizedBox(height: 12),
                      const Text(
                        'No campus whispers yet!',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Be the first student to whisper to MIC Campus.',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showPostWhisperSheet(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Post First Whisper'),
                      ),
                    ],
                  ),
                );
              }

              // Apply client-side sorting / filtering algorithm
              List<QueryDocumentSnapshot> filteredDocs = List.from(docs);

              if (_selectedFilter == '🔥 Top Liked') {
                filteredDocs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final likesA = (dataA['likes'] ?? 0) as int;
                  final likesB = (dataB['likes'] ?? 0) as int;
                  return likesB.compareTo(likesA);
                });
              } else if (_selectedFilter == '⏱️ Recent') {
                // already sorted by createdAt descending
              } else {
                // Category filter
                filteredDocs = filteredDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['category'] == _selectedFilter;
                }).toList();
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  return WhisperCard(doc: doc);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /* ==========================================================================
     POST A WHISPER BOTTOM SHEET (Supports Text, Image, & Poll)
  ========================================================================== */

  void _showPostWhisperSheet(BuildContext context) {
    final textController = TextEditingController();
    String category = 'Campus Life';
    String postType = 'text'; // 'text' | 'image' | 'poll'
    Uint8List? selectedImageBytes;
    String? selectedImageName;
    final pollOption1 = TextEditingController(text: 'Option 1');
    final pollOption2 = TextEditingController(text: 'Option 2');
    bool isPublishing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 16,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '🤫 Whisper to MIC Campus',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Encrypted & Anonymous • Instantly syncs across campus',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 16),

                    // Post Format Tabs: Text vs Image vs Poll
                    Row(
                      children: [
                        _buildTypeTab(
                          icon: Icons.chat_rounded,
                          label: 'Text',
                          isSelected: postType == 'text',
                          onTap: () => setModalState(() => postType = 'text'),
                        ),
                        const SizedBox(width: 8),
                        _buildTypeTab(
                          icon: Icons.image_rounded,
                          label: 'Image',
                          isSelected: postType == 'image',
                          onTap: () => setModalState(() => postType = 'image'),
                        ),
                        const SizedBox(width: 8),
                        _buildTypeTab(
                          icon: Icons.poll_rounded,
                          label: 'Campus Poll',
                          isSelected: postType == 'poll',
                          onTap: () => setModalState(() => postType = 'poll'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Category Selector
                    Wrap(
                      spacing: 8,
                      children: [
                        'Campus Life',
                        'Exams & Lab',
                        'Canteen & Chai',
                        'Confessions',
                      ].map((cat) {
                        final isSelected = category == cat;
                        return ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFF59E0B),
                          backgroundColor: const Color(0xFF0F172A),
                          onSelected: (val) {
                            if (val) setModalState(() => category = cat);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    // Main Text Field
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: postType == 'poll'
                            ? 'What is the poll question for campus?'
                            : 'What is happening on campus right now?',
                        hintStyle: const TextStyle(color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFF334155)),
                        ),
                      ),
                    ),

                    // Image Upload Section
                    if (postType == 'image') ...[
                      const SizedBox(height: 12),
                      if (selectedImageBytes != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                selectedImageBytes!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton.filled(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  setModalState(() {
                                    selectedImageBytes = null;
                                    selectedImageName = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF10B981)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 75,
                              maxWidth: 1024,
                            );
                            if (picked != null) {
                              final bytes = await picked.readAsBytes();
                              setModalState(() {
                                selectedImageBytes = bytes;
                                selectedImageName = picked.name;
                              });
                            }
                          },
                          icon: const Icon(Icons.photo_library_rounded,
                              color: Color(0xFF10B981)),
                          label: const Text(
                            'Pick Campus Photo from Gallery',
                            style: TextStyle(color: Color(0xFF10B981)),
                          ),
                        ),
                    ],

                    // Poll Section
                    if (postType == 'poll') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: pollOption1,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Option 1',
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: pollOption2,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Option 2',
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: isPublishing
                            ? null
                            : () async {
                                final text = textController.text.trim();
                                if (text.isEmpty && selectedImageBytes == null) {
                                  return;
                                }

                                setModalState(() => isPublishing = true);

                                try {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  final userDoc = await FirebaseFirestore
                                      .instance
                                      .collection('users')
                                      .doc(user?.uid)
                                      .get();
                                  final userData =
                                      userDoc.data() ?? <String, dynamic>{};
                                  final handle = userData['handle'] ??
                                      user?.displayName ??
                                      'Anonymous Student';
                                  final dept = userData['department'] ??
                                      'BSc Computer Science';

                                  String? uploadedImageUrl;

                                  // Upload image to Firebase Storage if selected
                                  if (selectedImageBytes != null) {
                                    final storageRef = FirebaseStorage.instance
                                        .ref()
                                        .child('whisper_images')
                                        .child(
                                            '${DateTime.now().millisecondsSinceEpoch}_${selectedImageName ?? 'image.jpg'}');

                                    final uploadTask = await storageRef.putData(
                                      selectedImageBytes!,
                                      SettableMetadata(contentType: 'image/jpeg'),
                                    );
                                    uploadedImageUrl =
                                        await uploadTask.ref.getDownloadURL();
                                  }

                                  // Poll data
                                  Map<String, dynamic>? pollData;
                                  if (postType == 'poll') {
                                    pollData = {
                                      'options': {
                                        pollOption1.text.trim(): 0,
                                        pollOption2.text.trim(): 0,
                                      },
                                      'voters': <String, dynamic>{},
                                    };
                                  }

                                  // Write to Firestore
                                  await FirebaseFirestore.instance
                                      .collection('whispers')
                                      .add({
                                    'authorId': user?.uid ?? 'anon',
                                    'authorHandle': handle,
                                    'authorDept': dept,
                                    'content': text,
                                    'category': category,
                                    'postType': postType,
                                    'imageUrl': uploadedImageUrl,
                                    'pollData': pollData,
                                    'likes': 0,
                                    'dislikes': 0,
                                    'likedBy': <String>[],
                                    'dislikedBy': <String>[],
                                    'commentsCount': 0,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });

                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            '🚀 Your Whisper is live on campus!'),
                                        backgroundColor: Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isPublishing = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Publish error: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: isPublishing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.rocket_launch_rounded),
                        label: Text(
                          isPublishing ? 'Publishing...' : 'Publish Whisper',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0x2610B981)
                : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF10B981)
                  : const Color(0xFF334155),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : const Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoadmapDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text(
                'MIC Whispers v2.0 Scope',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScopeItem(
                icon: Icons.security_rounded,
                title: 'AI Content Moderation',
                desc:
                    'Google Gemini AI checks whispers before publishing to filter toxic content.',
              ),
              const SizedBox(height: 12),
              _buildScopeItem(
                icon: Icons.location_on_rounded,
                title: 'Campus Geofencing',
                desc:
                    'Restricts posting permissions to students physically inside MIC campus.',
              ),
              const SizedBox(height: 12),
              _buildScopeItem(
                icon: Icons.mic_rounded,
                title: 'Voice Notes Whisper',
                desc:
                    '10-second anonymous voice notes with pitch modulation.',
              ),
              const SizedBox(height: 12),
              _buildScopeItem(
                icon: Icons.work_outline_rounded,
                title: 'Wellnoc Solutions Internships',
                desc:
                    'Top student contributors receive direct interview slots for Flutter developer internships!',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close',
                  style: TextStyle(color: Color(0xFF10B981))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScopeItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFFF59E0B)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ============================================================================
   INDIVIDUAL WHISPER CARD (Realtime Likes, Dislikes, Media & Comments)
============================================================================ */

class WhisperCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const WhisperCard({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final whisperId = doc.id;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final authorHandle = data['authorHandle'] ?? 'Anonymous Student';
    final authorDept = data['authorDept'] ?? 'MIC Campus';
    final content = data['content'] ?? '';
    final category = data['category'] ?? 'Campus Life';
    final postType = data['postType'] ?? 'text';
    final imageUrl = data['imageUrl'] as String?;
    final pollData = data['pollData'] as Map<String, dynamic>?;

    final likes = (data['likes'] ?? 0) as int;
    final likedBy = List<String>.from(data['likedBy'] ?? []);
    final dislikedBy = List<String>.from(data['dislikedBy'] ?? []);
    final commentsCount = (data['commentsCount'] ?? 0) as int;

    final isLiked = likedBy.contains(currentUserId);
    final isDisliked = dislikedBy.contains(currentUserId);

    // Format timestamp
    final timestamp = data['createdAt'] as Timestamp?;
    final timeString = timestamp != null
        ? DateFormat('h:mm a').format(timestamp.toDate())
        : 'Just now';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0x2610B981),
                child: Text(
                  authorHandle.isNotEmpty ? authorHandle[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorHandle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$authorDept • $timeString',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Whisper Text Content
          if (content.isNotEmpty)
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFFF1F5F9),
              ),
            ),

          // Image Attachment
          if (postType == 'image' && imageUrl != null && imageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 200,
                    color: const Color(0xFF0F172A),
                    child: const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF10B981)),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: const Color(0xFF0F172A),
                  child: const Center(
                    child: Text('Image failed to load',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ),
            ),
          ],

          // Poll Widget
          if (postType == 'poll' && pollData != null) ...[
            const SizedBox(height: 12),
            _buildPollWidget(context, whisperId, pollData, currentUserId),
          ],

          const SizedBox(height: 14),

          // Interactive Action Bar (Atomic Firestore updates)
          Row(
            children: [
              // Like Button
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleLike(whisperId, currentUserId, isLiked, isDisliked),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLiked
                        ? const Color(0x3310B981)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLiked
                          ? const Color(0xFF10B981)
                          : const Color(0xFF334155),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLiked
                            ? Icons.thumb_up_alt_rounded
                            : Icons.thumb_up_off_alt_rounded,
                        size: 15,
                        color: isLiked
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$likes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isLiked
                              ? const Color(0xFF10B981)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Dislike Button
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    _toggleDislike(whisperId, currentUserId, isLiked, isDisliked),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDisliked
                        ? Colors.redAccent.withValues(alpha: 0.2)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDisliked
                          ? Colors.redAccent
                          : const Color(0xFF334155),
                    ),
                  ),
                  child: Icon(
                    isDisliked
                        ? Icons.thumb_down_alt_rounded
                        : Icons.thumb_down_off_alt_rounded,
                    size: 15,
                    color: isDisliked
                        ? Colors.redAccent
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Comments Button
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showCommentsSheet(context, whisperId),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 15,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$commentsCount',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Share Icon
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 16),
                color: const Color(0xFF94A3B8),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Whisper link ready to share on campus!'),
                      backgroundColor: Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Poll rendering & voting
  Widget _buildPollWidget(
    BuildContext context,
    String whisperId,
    Map<String, dynamic> pollData,
    String currentUserId,
  ) {
    final rawOptions = pollData['options'] as Map<String, dynamic>? ?? {};
    final voters = pollData['voters'] as Map<String, dynamic>? ?? {};
    final userVotedOption = voters[currentUserId] as String?;

    int totalVotes = 0;
    rawOptions.forEach((_, val) => totalVotes += (val as int? ?? 0));

    return Column(
      children: rawOptions.entries.map((entry) {
        final optionName = entry.key;
        final voteCount = entry.value as int? ?? 0;
        final percent = totalVotes > 0 ? (voteCount / totalVotes) : 0.0;
        final isSelected = userVotedOption == optionName;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              if (userVotedOption != null) return; // already voted
              final docRef =
                  FirebaseFirestore.instance.collection('whispers').doc(whisperId);

              await FirebaseFirestore.instance.runTransaction((tx) async {
                final snap = await tx.get(docRef);
                final currentPoll =
                    snap.get('pollData') as Map<String, dynamic>? ?? {};
                final currentOpts =
                    Map<String, dynamic>.from(currentPoll['options'] ?? {});
                final currentVoters =
                    Map<String, dynamic>.from(currentPoll['voters'] ?? {});

                currentOpts[optionName] =
                    (currentOpts[optionName] as int? ?? 0) + 1;
                currentVoters[currentUserId] = optionName;

                tx.update(docRef, {
                  'pollData': {
                    'options': currentOpts,
                    'voters': currentVoters,
                  }
                });
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : const Color(0xFF334155),
                ),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: percent.clamp(0.0, 1.0),
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0x3310B981)
                            : const Color(0x1A94A3B8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        optionName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.white,
                        ),
                      ),
                      Text(
                        '${(percent * 100).toInt()}% ($voteCount)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Like Firestore logic
  void _toggleLike(
      String whisperId, String currentUserId, bool isLiked, bool isDisliked) {
    final ref =
        FirebaseFirestore.instance.collection('whispers').doc(whisperId);
    if (isLiked) {
      ref.update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([currentUserId]),
      });
    } else {
      final updates = <String, dynamic>{
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([currentUserId]),
      };
      if (isDisliked) {
        updates['dislikes'] = FieldValue.increment(-1);
        updates['dislikedBy'] = FieldValue.arrayRemove([currentUserId]);
      }
      ref.update(updates);
    }
  }

  // Dislike Firestore logic
  void _toggleDislike(
      String whisperId, String currentUserId, bool isLiked, bool isDisliked) {
    final ref =
        FirebaseFirestore.instance.collection('whispers').doc(whisperId);
    if (isDisliked) {
      ref.update({
        'dislikes': FieldValue.increment(-1),
        'dislikedBy': FieldValue.arrayRemove([currentUserId]),
      });
    } else {
      final updates = <String, dynamic>{
        'dislikes': FieldValue.increment(1),
        'dislikedBy': FieldValue.arrayUnion([currentUserId]),
      };
      if (isLiked) {
        updates['likes'] = FieldValue.increment(-1);
        updates['likedBy'] = FieldValue.arrayRemove([currentUserId]);
      }
      ref.update(updates);
    }
  }

  // Comments Bottom Sheet
  void _showCommentsSheet(BuildContext context, String whisperId) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: SizedBox(
            height: 440,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Campus Comments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Real-time comments query
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('whispers')
                        .doc(whisperId)
                        .collection('comments')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF10B981)),
                        );
                      }
                      final commentDocs = snapshot.data?.docs ?? [];

                      if (commentDocs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No comments yet. Be the first to drop a reply!',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: commentDocs.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Color(0xFF334155)),
                        itemBuilder: (context, idx) {
                          final cData =
                              commentDocs[idx].data() as Map<String, dynamic>;
                          final author =
                              cData['authorHandle'] ?? 'Anonymous Student';
                          final text = cData['text'] ?? '';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: const Color(0x3310B981),
                                  child: Text(
                                    author.isNotEmpty
                                        ? author[0].toUpperCase()
                                        : '#',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        author,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        text,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Comment input
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Add an anonymous campus reply...',
                            hintStyle:
                                const TextStyle(color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  const BorderSide(color: Color(0xFF334155)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () async {
                          final commentText = commentController.text.trim();
                          if (commentText.isEmpty) return;

                          final user = FirebaseAuth.instance.currentUser;
                          final userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user?.uid)
                              .get();
                          final handle = userDoc.data()?['handle'] ??
                              user?.displayName ??
                              'Anonymous Student';

                          // Write comment doc
                          await FirebaseFirestore.instance
                              .collection('whispers')
                              .doc(whisperId)
                              .collection('comments')
                              .add({
                            'authorId': user?.uid ?? 'anon',
                            'authorHandle': handle,
                            'text': commentText,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          // Atomically increment comments count
                          await FirebaseFirestore.instance
                              .collection('whispers')
                              .doc(whisperId)
                              .update({
                            'commentsCount': FieldValue.increment(1),
                          });

                          commentController.clear();
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/* ============================================================================
   PERSONA PROFILE VIEW (Student Identity, Karma & Stats)
============================================================================ */

class PersonaProfileView extends StatelessWidget {
  const PersonaProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final userData =
            snapshot.data?.data() as Map<String, dynamic>? ?? <String, dynamic>{};
        final handle = userData['handle'] ??
            user?.displayName ??
            'Anonymous Whisperer';
        final dept = userData['department'] ?? 'Department of Computer Science';
        final email = userData['email'] ?? user?.email ?? 'anonymous@mic.ac.in';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Persona Identity Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 36,
                        backgroundColor: Color(0xFF1E293B),
                        child: Icon(
                          Icons.shield_outlined,
                          size: 40,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      handle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dept\nMIC Arts & Science College, Kasaragod',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x2610B981),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '📍 Verified Inside MIC Campus (Geofence Active)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Query User's Whispers & Calculate Stats
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('whispers')
                    .where('authorId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, snap) {
                  final myWhispers = snap.data?.docs ?? [];
                  int totalUpvotes = 0;
                  for (var doc in myWhispers) {
                    final d = doc.data() as Map<String, dynamic>;
                    totalUpvotes += (d['likes'] ?? 0) as int;
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'My Whispers',
                          value: '${myWhispers.length}',
                          icon: Icons.chat_bubble_outline_rounded,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Upvotes',
                          value: '$totalUpvotes',
                          icon: Icons.thumb_up_alt_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Campus Karma',
                          value: '#${(150 - totalUpvotes).clamp(1, 150)}',
                          icon: Icons.emoji_events_outlined,
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Sign Out & Controls
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: const Text(
                    'Sign Out of Persona',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
