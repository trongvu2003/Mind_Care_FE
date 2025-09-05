import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mind_mare_fe/theme/app_colors.dart';
import 'package:provider/provider.dart';

import '../../models/diary_entry.dart';
import '../../services/diary_repository.dart';
import '../../view_models/UserViewModel.dart';
import '../../view_models/home_feed_view_model.dart';

import 'CameraAI.dart';
import 'ProfileScreen.dart';
import 'diary_detail_page.dart';
import 'statistics_page.dart';
import 'suggestions_page.dart';
import '../../widgets/custom_bottom_navigation.dart';

class MindCareHomePage extends StatefulWidget {
  @override
  _MindCareHomePageState createState() => _MindCareHomePageState();
}

class _MindCareHomePageState extends State<MindCareHomePage> {
  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(),
      const SuggestionsPage(),
      const StatisticsPage(),
      const CameraAIPage(),
      Profilescreen(uid: user?.uid ?? ""),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton.extended(
                onPressed: () => Navigator.pushNamed(context, '/newDiaryPage'),
                backgroundColor: AppColors.text,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Nhật ký mới',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                  side: const BorderSide(width: 1, color: Colors.white),
                ),
              )
              : null,
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final UserViewModel userVM;
  late final HomeFeedViewModel feedVM;
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  // ---- Multi-select state ----
  bool _multiSelect = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    userVM = UserViewModel()..loadUser(uid);
    feedVM = HomeFeedViewModel(
      repo: DiaryRepository(useUserSubcollection: true),
      uid: uid,
    )..start();
  }

  @override
  void dispose() {
    userVM.dispose();
    feedVM.dispose();
    super.dispose();
  }

  void _enterMultiSelect([DiaryEntry? e]) {
    if (!_multiSelect) {
      setState(() => _multiSelect = true);
    }
    if (e != null) _toggleSelect(e.id);
  }

  void _exitMultiSelect() {
    setState(() {
      _multiSelect = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  bool _isSelected(String id) => _selectedIds.contains(id);

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Xoá nhật ký đã chọn?'),
            content: Text(
              'Bạn muốn xoá ${_selectedIds.length} ghi chú đã tick?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.text,
                ),
                child: const Text('Huỷ'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Xoá'),
              ),
            ],
          ),
    );
    if (ok != true) return;

    try {
      await feedVM.deleteEntries(_selectedIds);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Đã xoá ${_selectedIds.length} nhật ký',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          shape: const RoundedRectangleBorder(),
          duration: const Duration(seconds: 3),
          elevation: 4,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xoá thất bại: $e')));
    } finally {
      if (mounted) _exitMultiSelect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userVM),
        ChangeNotifierProvider.value(value: feedVM),
      ],
      child: Consumer2<UserViewModel, HomeFeedViewModel>(
        builder: (context, vm, feed, child) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              leading: Icon(Icons.menu, color: AppColors.black),
              title: Row(
                children: [
                  Image.asset(
                    'assets/images/mainlogo.png',
                    width: 47,
                    height: 47,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'MindCare',
                    style: TextStyle(
                      color: AppColors.title,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              actions:
                  _multiSelect
                      ? [
                        IconButton(
                          tooltip: 'Xoá đã chọn',
                          onPressed:
                              _selectedIds.isEmpty ? null : _deleteSelected,
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                        IconButton(
                          tooltip: 'Thoát chọn',
                          onPressed: _exitMultiSelect,
                          icon: const Icon(Icons.close, color: Colors.black),
                        ),
                      ]
                      : const [
                        Icon(Icons.search, color: Colors.black),
                        SizedBox(width: 15),
                      ],
            ),
            body:
                feed.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : feed.error != null
                    ? Center(child: Text('Lỗi: ${feed.error}'))
                    : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(vm),
                          _buildSection('Hôm nay', feed.today),
                          _buildSection('Tháng này', feed.thisMonth),
                          ..._yearSections(feed.byYear),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
          );
        },
      ),
    );
  }

  Widget _header(UserViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.text,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withOpacity(0.3),
                backgroundImage:
                    vm.user?.avatarUrl.isNotEmpty == true
                        ? NetworkImage(vm.user!.avatarUrl)
                        : null,
                child:
                    vm.user?.avatarUrl.isEmpty ?? true
                        ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        )
                        : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Chào buổi sáng! Bạn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hôm nay bạn cảm thấy thế nào?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/aichatroom'),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: TextField(
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: 'AI sẽ sẵn sàng hỗ trợ bạn',
                        hintStyle: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Icon(Icons.send, color: Colors.black, size: 24),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<DiaryEntry> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...items.map(_buildChatItemFromEntry).toList(),
      ],
    );
  }

  List<Widget> _yearSections(Map<int, List<DiaryEntry>> byYear) {
    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));
    return years.map((y) => _buildSection(y.toString(), byYear[y]!)).toList();
  }

  Widget _buildChatItemFromEntry(DiaryEntry e) {
    final dt = e.createdAt.toLocal();
    final timeString = DateFormat('HH:mm dd/MM/yyyy').format(dt);
    final preview = e.content.isEmpty ? '(Không có nội dung)' : e.content;
    final senti =
        e.textSentiment.isNotEmpty
            ? ' • ${e.textSentiment}${e.textSentimentScore > 0 ? ' ${(e.textSentimentScore * 100).toStringAsFixed(0)}%' : ''}'
            : '';

    final checked = _isSelected(e.id);

    return InkWell(
      onLongPress: () => _enterMultiSelect(e),
      onTap: () {
        if (_multiSelect) {
          _toggleSelect(e.id);
          return;
        }
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => DiaryDetailPage(diaryId: e.id, uid: uid, initial: e),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.text.withOpacity(0.7),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            if (_multiSelect)
              Checkbox(value: checked, onChanged: (_) => _toggleSelect(e.id)),
            Expanded(
              child: Text(
                '$timeString  $preview$senti',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!_multiSelect)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => DiaryDetailPage(
                            diaryId: e.id,
                            uid: uid,
                            initial: e,
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.title,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                  elevation: 6,
                  minimumSize: const Size(50, 50),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
