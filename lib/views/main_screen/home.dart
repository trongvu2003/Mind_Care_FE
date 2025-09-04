import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mind_mare_fe/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../services/diary_repository.dart';
import '../../view_models/UserViewModel.dart';
import '../../view_models/home_feed_view_model.dart';
import '../../models/diary_entry.dart';

import 'CameraAI.dart';
import 'ProfileScreen.dart';
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
      SuggestionsPage(),
      StatisticsPage(),
      CameraAIPage(),
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
              actions: const [
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
                  children: [
                    Text(
                      'Chào buổi sáng! ${vm.user?.name ?? 'Bạn'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Text(
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
              child: Row(
                children: const [
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.text.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
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
          ElevatedButton(
            onPressed: () {},
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
    );
  }
}
