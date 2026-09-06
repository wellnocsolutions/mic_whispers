import 'package:flutter/material.dart';

void main() {
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
      home: const MainNavigationScreen(),
    );
  }
}

/* ============================================================================
   DATA MODELS
============================================================================ */

class Whisper {
  final String id;
  final String authorHandle;
  final String authorTag;
  final String content;
  final String category;
  final String timeAgo;
  int likes;
  int dislikes;
  bool isLiked;
  bool isDisliked;
  final List<String> comments;

  Whisper({
    required this.id,
    required this.authorHandle,
    required this.authorTag,
    required this.content,
    required this.category,
    required this.timeAgo,
    this.likes = 0,
    this.dislikes = 0,
    this.isLiked = false,
    this.isDisliked = false,
    List<String>? comments,
  }) : comments = comments ?? [];
}

/* ============================================================================
   MAIN NAVIGATION & SCREEN
============================================================================ */

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTabIndex = 0;

  // Global list of whispers
  final List<Whisper> _whispers = [
    Whisper(
      id: '1',
      authorHandle: 'Silent Falcon #42',
      authorTag: 'BSc CS 3rd Year',
      content:
          'Flutter Fusion workshop by Wellnoc Solutions is so smooth! 🚀 Building mobile apps with Dart in under an hour is crazy fast.',
      category: 'Campus Life',
      timeAgo: 'Just now',
      likes: 38,
      comments: [
        'Facts! The UI Hot Reload is unbelievable.',
        'Wait till you see the Firebase integration!',
      ],
    ),
    Whisper(
      id: '2',
      authorHandle: 'Secret Coder #07',
      authorTag: 'Lab Room 2',
      content:
          'HOD announced lab exam records must be submitted by 3 PM today... anyone has the OS scheduling algorithm completed? 😭',
      category: 'Exams & Lab',
      timeAgo: '12m ago',
      likes: 24,
      dislikes: 1,
      comments: ['I finished Round Robin, message me!'],
    ),
    Whisper(
      id: '3',
      authorHandle: 'Chai Philosopher #88',
      authorTag: 'Canteen Squad',
      content:
          'Unpopular opinion: The Chattachal junction tea with parotta at 11 AM hits 100x harder than any energy drink.',
      category: 'Canteen & Chai',
      timeAgo: '35m ago',
      likes: 56,
      comments: ['100% agreed', 'Add extra sugar next time 😂'],
    ),
    Whisper(
      id: '4',
      authorHandle: 'Mysterious Raven #19',
      authorTag: 'Hostel Block B',
      content:
          'To the person who returned my lost college ID card to the CS department office: Thank you so much, you saved me ₹500 fine! ❤️',
      category: 'Confessions',
      timeAgo: '1h ago',
      likes: 45,
      comments: ['MIC students always got each others backs 🤝'],
    ),
  ];

  String _selectedFilter = '🔥 Top Liked';

  // Sorting / Filtering Algorithm
  List<Whisper> get _filteredWhispers {
    List<Whisper> list = List.from(_whispers);

    if (_selectedFilter == '🔥 Top Liked') {
      list.sort((a, b) => b.likes.compareTo(a.likes));
    } else if (_selectedFilter == '⏱️ Recent') {
      // Natural order (newest first)
    } else {
      // Category filter
      list = list.where((w) => w.category == _selectedFilter).toList();
    }
    return list;
  }

  void _addWhisper(String content, String category) {
    setState(() {
      _whispers.insert(
        0,
        Whisper(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          authorHandle: 'Anonymous Student #${_whispers.length + 101}',
          authorTag: 'BSc Computer Science',
          content: content,
          category: category,
          timeAgo: 'Just now',
          likes: 1,
          isLiked: true,
        ),
      );
    });
  }

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
                color: const Color(0xFF10B981).withOpacity(0.15),
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
                      'MIC Campus • 148 Live',
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
          ? _buildFeedView()
          : _buildProfileView(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF334155), width: 0.8),
          ),
        ),
        child: NavigationBar(
          backgroundColor: const Color(0xFF0F172A),
          indicatorColor: const Color(0xFF10B981).withOpacity(0.2),
          selectedIndex: _currentTabIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dynamic_feed_rounded, color: Color(0xFF94A3B8)),
              selectedIcon:
                  Icon(Icons.dynamic_feed_rounded, color: Color(0xFF10B981)),
              label: 'Whispers Feed',
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
              icon: const Icon(Icons.edit_note_rounded, size: 22),
              label: const Text(
                'Whisper',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            )
          : null,
    );
  }

  /* ==========================================================================
     FEED VIEW (WITH FILTER ALGORITHMS)
  ========================================================================== */

  Widget _buildFeedView() {
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
                  if (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  }
                },
              );
            },
          ),
        ),

        // List of Whispers
        Expanded(
          child: _filteredWhispers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 48, color: Colors.grey.shade600),
                      const SizedBox(height: 12),
                      Text(
                        'No whispers in "$_selectedFilter" yet!',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: _filteredWhispers.length,
                  itemBuilder: (context, index) {
                    final whisper = _filteredWhispers[index];
                    return _buildWhisperCard(whisper);
                  },
                ),
        ),
      ],
    );
  }

  /* ==========================================================================
     WHISPER CARD COMPONENT
  ========================================================================== */

  Widget _buildWhisperCard(Whisper whisper) {
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
                backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                child: Text(
                  whisper.authorHandle.substring(0, 1),
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
                      whisper.authorHandle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${whisper.authorTag} • ${whisper.timeAgo}',
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
                  whisper.category,
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

          // Content
          Text(
            whisper.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFFF1F5F9),
            ),
          ),

          const SizedBox(height: 14),

          // Interaction Bar (Stateful Actions)
          Row(
            children: [
              // Like / Upvote Button
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    if (whisper.isLiked) {
                      whisper.likes--;
                      whisper.isLiked = false;
                    } else {
                      whisper.likes++;
                      whisper.isLiked = true;
                      if (whisper.isDisliked) {
                        whisper.dislikes--;
                        whisper.isDisliked = false;
                      }
                    }
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: whisper.isLiked
                        ? const Color(0xFF10B981).withOpacity(0.2)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: whisper.isLiked
                          ? const Color(0xFF10B981)
                          : const Color(0xFF334155),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        whisper.isLiked
                            ? Icons.thumb_up_alt_rounded
                            : Icons.thumb_up_off_alt_rounded,
                        size: 15,
                        color: whisper.isLiked
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${whisper.likes}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: whisper.isLiked
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
                onTap: () {
                  setState(() {
                    if (whisper.isDisliked) {
                      whisper.dislikes--;
                      whisper.isDisliked = false;
                    } else {
                      whisper.dislikes++;
                      whisper.isDisliked = true;
                      if (whisper.isLiked) {
                        whisper.likes--;
                        whisper.isLiked = false;
                      }
                    }
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: whisper.isDisliked
                        ? Colors.redAccent.withOpacity(0.2)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: whisper.isDisliked
                          ? Colors.redAccent
                          : const Color(0xFF334155),
                    ),
                  ),
                  child: Icon(
                    whisper.isDisliked
                        ? Icons.thumb_down_alt_rounded
                        : Icons.thumb_down_off_alt_rounded,
                    size: 15,
                    color: whisper.isDisliked
                        ? Colors.redAccent
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Comment Sheet Trigger
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showCommentsSheet(context, whisper),
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
                        '${whisper.comments.length}',
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

              // Share / Copy Icon
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 16),
                color: const Color(0xFF94A3B8),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Whisper link copied! Ready to share 🚀'),
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

  /* ==========================================================================
     COMMENTS BOTTOM SHEET
  ========================================================================== */

  void _showCommentsSheet(BuildContext context, Whisper whisper) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SizedBox(
                height: 420,
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
                    Text(
                      'Comments (${whisper.comments.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: whisper.comments.isEmpty
                          ? const Center(
                              child: Text(
                                'No comments yet. Be the first to reply!',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            )
                          : ListView.separated(
                              itemCount: whisper.comments.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(color: Color(0xFF334155)),
                              itemBuilder: (context, idx) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor:
                                            const Color(0xFF10B981).withOpacity(0.2),
                                        child: Text(
                                          '#${idx + 1}',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          whisper.comments[idx],
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Add an anonymous reply...',
                                hintStyle:
                                    const TextStyle(color: Color(0xFF94A3B8)),
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF334155)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: () {
                              if (commentController.text.trim().isNotEmpty) {
                                final newText = commentController.text.trim();
                                setState(() {
                                  whisper.comments.add(newText);
                                });
                                setSheetState(() {});
                                commentController.clear();
                              }
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
      },
    );
  }

  /* ==========================================================================
     POST A WHISPER BOTTOM SHEET
  ========================================================================== */

  void _showPostWhisperSheet(BuildContext context) {
    final textController = TextEditingController();
    String category = 'Campus Life';

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
                    'Encrypted & Anonymous. Keep it respectful to fellow students.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 16),

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

                  const SizedBox(height: 16),

                  TextField(
                    controller: textController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                          'Share your campus thought, tip, or confession...',
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

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        if (textController.text.trim().isNotEmpty) {
                          _addWhisper(textController.text.trim(), category);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎉 Your Whisper has been published!'),
                              backgroundColor: Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.rocket_launch_rounded),
                      label: const Text(
                        'Publish Whisper',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /* ==========================================================================
     MY PERSONA / PROFILE VIEW
  ========================================================================== */

  Widget _buildProfileView() {
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
                const Text(
                  'Silent Falcon #42',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Department of BSc Computer Science\nMIC Arts & Science College, Kasaragod',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '📍 Verified Inside MIC Campus (Geofence OK)',
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

          // Campus Karma Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Whispers',
                  value: '${_whispers.length}',
                  icon: Icons.chat_bubble_outline_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Upvotes',
                  value: '163',
                  icon: Icons.thumb_up_alt_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Karma Rank',
                  value: '#12',
                  icon: Icons.emoji_events_outlined,
                  color: const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Student Development & Tech Scope Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.school_rounded,
                        color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Wellnoc Student Developer Path',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'This project was engineered during the Flutter Fusion Certification Program organized by Wellnoc Solutions.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _showRoadmapDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.rocket_rounded, size: 16),
                  label: const Text('View Architecture & AI Roadmap'),
                ),
              ],
            ),
          ),
        ],
      ),
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

  /* ==========================================================================
     ROADMAP & AI SCOPE DIALOG
  ========================================================================== */

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
                desc: 'Google Gemini AI checks posts before publishing to filter toxicity.',
              ),
              const SizedBox(height: 12),
              _buildScopeItem(
                icon: Icons.location_on_rounded,
                title: 'Campus Geofence',
                desc: 'Restricts posting permissions to students physically within MIC campus.',
              ),
              const SizedBox(height: 12),
              _buildScopeItem(
                icon: Icons.mic_rounded,
                title: 'Voice Whispers',
                desc: 'Record 10-second anonymous voice notes with audio waves.',
              ),
              const SizedBox(height: 12),
              _buildScopeItem(
                icon: Icons.cloud_sync_rounded,
                title: 'Firebase Live Streams',
                desc: 'Firestore real-time sync across all student devices instantly.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Color(0xFF10B981))),
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
