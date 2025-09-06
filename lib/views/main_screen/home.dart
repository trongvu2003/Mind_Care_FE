import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mind_mare_fe/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../models/diary_entry.dart';
import '../../services/diary_repository.dart';
import '../../view_models/UserViewModel.dart';
import '../../view_models/home_feed_view_model.dart';
import '../../view_models/sign_in_viewmodel.dart';
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
      HomePage(onSelectTab: (i) => setState(() => _selectedIndex = i)),
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
              ? FloatingActionButton(
                onPressed: () => Navigator.pushNamed(context, '/newDiaryPage'),
                backgroundColor: AppColors.text,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                  side: const BorderSide(width: 1, color: Colors.white),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 35),
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
  const HomePage({super.key, this.onSelectTab});
  final void Function(int index)? onSelectTab;
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final UserViewModel userVM;
  late final HomeFeedViewModel feedVM;
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _multiSelect = false;
  final Set<String> _selectedIds = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _searching = false;

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
    _searchCtrl.dispose();
    userVM.dispose();
    feedVM.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final now = DateTime.now().hour;
    if (now < 11) return 'Chào buổi sáng';
    if (now < 13) return 'Chào buổi trưa';
    if (now < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Center(
            child: Text(
              "Đăng xuất",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: Text("Bạn có chắc muốn đăng xuất?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.text,
              ),
              child: Text("Hủy"),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.red,
              ),
              onPressed: () async {
                await dialogContext.read<SignInViewModel>().signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/signinscreen');
                }
              },
              child: Text("Đăng xuất"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, UserViewModel vm) {
    final user = vm.user;
    final displayName = (user?.name?.isNotEmpty == true) ? user!.name : 'Bạn';
    final avatar =
        (user?.avatarUrl.isNotEmpty == true) ? user!.avatarUrl : null;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.text, AppColors.text.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    backgroundImage:
                        (avatar != null) ? NetworkImage(avatar) : null,
                    child:
                        (avatar == null)
                            ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            )
                            : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$displayName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Chúc bạn một ngày tốt lành!',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Nav items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: const Text('Trang chủ'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lightbulb_outline),
                    title: const Text('Gợi ý hôm nay'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelectTab?.call(1);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart_outlined),
                    title: const Text('Thống kê'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelectTab?.call(2);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: const Text('Camera AI'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelectTab?.call(3);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Hồ sơ'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelectTab?.call(4);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Chế độ tối'),
                    value: false,
                    onChanged: (v) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Demo: bật/tắt chế độ tối'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  List<DiaryEntry> _filterEntries(List<DiaryEntry> list, String q) {
    final s = q.toLowerCase().trim();
    if (s.isEmpty) return list;

    return list.where((e) {
        final content = e.content.toLowerCase();
        final feeling = (e.selectedFeeling ?? '').toLowerCase();
        final senti = e.textSentiment.toLowerCase();
        final time1 =
            DateFormat(
              'dd/MM/yyyy',
            ).format(e.createdAt.toLocal()).toLowerCase();
        final time2 =
            DateFormat(
              'HH:mm dd/MM',
            ).format(e.createdAt.toLocal()).toLowerCase();

        return content.contains(s) ||
            feeling.contains(s) ||
            senti.contains(s) ||
            time1.contains(s) ||
            time2.contains(s);
      }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

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
                style: TextButton.styleFrom(foregroundColor: AppColors.text),
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
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Đã xoá nhật ký đã chọn',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
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

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchCtrl.clear();
        _query = '';
        FocusScope.of(context).unfocus();
      } else {}
    });
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
          final allEntries = <DiaryEntry>[
            ...feed.today,
            ...feed.thisMonth,
            for (final list in feed.byYear.values) ...list,
          ];
          final showSearch = _query.trim().isNotEmpty;
          final searchResults =
              showSearch
                  ? _filterEntries(allEntries, _query)
                  : const <DiaryEntry>[];

          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              leading: Builder(
                builder:
                    (ctx) => IconButton(
                      tooltip: 'Menu',
                      icon: const Icon(Icons.menu, color: Colors.black),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
              ),
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
                      : [
                        IconButton(
                          tooltip: _searching ? 'Đóng tìm kiếm' : 'Tìm kiếm',
                          onPressed: _toggleSearch,
                          icon: Icon(
                            _searching ? Icons.close : Icons.search,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
              //  _searching = true
              bottom:
                  _searching
                      ? PreferredSize(
                        preferredSize: const Size.fromHeight(56),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: Colors.white,
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v),
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Tìm theo nội dung, cảm xúc, ngày...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon:
                                  (_query.isNotEmpty)
                                      ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() => _query = '');
                                        },
                                      )
                                      : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE0E0E0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE0E0E0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      : null,
            ),
            drawer: _buildDrawer(context, vm),
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
                          if (showSearch)
                            _buildSection('Kết quả tìm kiếm', searchResults)
                          else ...[
                            _buildSection('Hôm nay', feed.today),
                            _buildSection('Tháng này', feed.thisMonth),
                            ..._yearSections(feed.byYear),
                          ],

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
    final name = (vm.user?.name ?? 'Bạn');
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
                      '${_getGreeting()}! $name',
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
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
    if (items.isEmpty) {
      if (title == 'Kết quả tìm kiếm') {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Không tìm thấy kết quả phù hợp.'),
          ),
        );
      }
      return const SizedBox.shrink();
    }

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
                  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
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
