import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mind_mare_fe/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../view_models/UserViewModel.dart';
import '../../widgets/custom_bottom_navigation.dart';
import 'CameraAI.dart';
import 'ProfileScreen.dart';
import 'statistics_page.dart';
import 'suggestions_page.dart';

class MindCareHomePage extends StatefulWidget {
  @override
  _MindCareHomePageState createState() => _MindCareHomePageState();
}

class _MindCareHomePageState extends State<MindCareHomePage> {
  int _selectedIndex = 0;
  final TextEditingController _messageController = TextEditingController();
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
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/newDiaryPage',
                  );

                },
                backgroundColor: AppColors.text,
                child: Icon(Icons.add, color: Colors.white, size: 30),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                  side: BorderSide(
                    width: 1,
                    color: Colors.white,
                  ),
                ),
              )
              : null,
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _messageController = TextEditingController();
  late final UserViewModel userVM;
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    userVM = UserViewModel();
    userVM.loadUser(uid);
  }

  @override
  void dispose() {
    _messageController.dispose();
    userVM.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: userVM,
      child: Consumer<UserViewModel>(
        builder: (context, vm, child) {
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
                  SizedBox(width: 10),
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
              actions: [
                Icon(Icons.search, color: Colors.black),
                SizedBox(width: 15),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
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
                                      ? Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 30,
                                      )
                                      : null,
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chào buổi sáng! ${vm.user?.name ?? 'Bạn'}',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Hôm nay bạn cảm thấy thế nào?',
                                    style: TextStyle(
                                      color: AppColors.white,
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
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/aichatroom');
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    enabled: false,
                                    decoration: InputDecoration(
                                      hintText: 'AI sẽ sẵn sàng hỗ trợ bạn',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[500],
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
                                  padding: const EdgeInsets.only(right: 14),
                                  child: Icon(
                                    Icons.send,
                                    color: AppColors.black,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSection('Hôm nay', [
                    '11:37 PM Hôm nay tôi chán quá',
                  ], true),
                  _buildSection('Tháng này', [
                    '05/05/2025 Hôm nay tôi chán quá',
                    '04/05/2025 Hôm nay tôi chán quá',
                    '02/05/2025 Hôm nay tôi chán quá',
                    '01/05/2025 Hôm nay tôi chán quá',
                  ]),
                  _buildSection('2024', [
                    '05/05/2025 Hôm nay tôi chán quá',
                    '05/05/2025 Hôm nay tôi chán quá',
                    '02/05/2025 Hôm nay tôi chán quá',
                    '01/05/2025 Hôm nay tôi chán quá',
                  ]),
                  SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<String> items, [
    bool isToday = false,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 10),
        ...items.map((e) => _buildChatItem(e, isToday)).toList(),
      ],
    );
  }

  Widget _buildChatItem(String text, [bool isToday = false]) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.text.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
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
                side: BorderSide(color: Colors.white, width: 2),
              ),
              elevation: 6,
              minimumSize: Size(50, 50),
              padding: EdgeInsets.all(0),
            ),
            child: Icon(
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
