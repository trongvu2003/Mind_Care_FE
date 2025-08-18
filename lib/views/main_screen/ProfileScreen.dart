import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mind_mare_fe/theme/app_colors.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../view_models/UserViewModel.dart';
import '../../view_models/sign_in_viewmodel.dart';

class Profilescreen extends StatefulWidget {
  final String uid;

  const Profilescreen({super.key, required this.uid});

  @override
  State<Profilescreen> createState() => _Profilescreen();
}

class _Profilescreen extends State<Profilescreen> {
  final UserViewModel _viewModel = UserViewModel();
  AppUser? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      await _viewModel.loadUser(widget.uid);
      setState(() {
        _user = _viewModel.user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Lỗi khi load user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _user == null
                ? const Center(child: Text("Không tìm thấy người dùng"))
                : _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.text,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        "Thông tin cá nhân",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.black),
          tooltip: 'Cài đặt',
          onPressed: () => _showSettings(context),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildMainContainer(),
      ),
    );
  }

  Widget _buildMainContainer() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 50),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.black, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 70, 24, 30),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildInfoRow(Icons.person, "Họ tên", _user!.name),
              const SizedBox(height: 25),
              _buildInfoRow(Icons.mail, "Email", _user!.email),
              const SizedBox(height: 25),
              _buildInfoRow(
                Icons.phone,
                "Số điện thoại",
                _user!.phone.isNotEmpty ? _user!.phone : "Chưa có",
              ),
              const SizedBox(height: 25),
              _buildInfoRow(
                Icons.calendar_today,
                " Ngày tạo",
                _user!.createdAt?.toLocal().toString().split('.')[0] ?? "N/A",
              ),
              const SizedBox(height: 25),
              _buildInfoRow(
                Icons.timer,
                "Đăng nhập gần nhất",
                _user!.lastLogin?.toLocal().toString().split('.')[0] ?? "N/A",
              ),
              const SizedBox(height: 35),
            ],
          ),
        ),
        Positioned(top: 0, child: _buildProfilePicture()),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.2),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(icon, color: Colors.black),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    return GestureDetector(
      onTap: () {
        debugPrint("Profile picture tapped");
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.yellow, width: 3),
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image:
                        _user!.avatarUrl.isNotEmpty
                            ? NetworkImage(_user!.avatarUrl)
                            : "" as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.text,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Chỉnh sửa trang cá nhân"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/editProfile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Đăng xuất"),
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
          ],
        );
      },
    );
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
}
