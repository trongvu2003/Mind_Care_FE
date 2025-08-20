import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mind_mare_fe/theme/app_colors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/upload_service.dart';
import '../../view_models/UserViewModel.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  AppUser? _user;
  File? _avatarImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bạn chưa đăng nhập!")),
        );
        return;
      }
      final uid = currentUser.uid;
      if (uid != null) {
        final vm = Provider.of<UserViewModel>(context, listen: false);
        vm.loadUser(uid);
      }
    });
  }

  Future<void> _saveChanges(UserViewModel vm) async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu không khớp!")),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn chưa đăng nhập!")),
      );
      return;
    }

    String? newAvatarUrl;

    // Upload avatar nếu người dùng chọn ảnh mới
    if (_avatarImage != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await UploadService.uploadImage(_avatarImage!);
      Navigator.pop(context);

      if (result['url'] != null) {
        newAvatarUrl = result['url'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? "Tải ảnh lên thất bại")),
        );
        return;
      }
    }

    // Cập nhật thông tin user nếu vm.user != null
    if (vm.user != null) {
      await vm.updateUserInfo(
        name: _usernameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        avatarUrl: newAvatarUrl,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thông tin user chưa load xong!")),
      );
      return;
    }

    // Cập nhật mật khẩu nếu có
    if (_passwordController.text.isNotEmpty) {
      try {
        await currentUser.updatePassword(_passwordController.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi cập nhật mật khẩu: $e")),
        );
        return;
      }
    }

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Cập nhật thành công!",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }


  void _showSaveDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Center(
            child: Text(
              "Xác nhận",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: const Text("Bạn có chắc muốn lưu thay đổi không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.text,
              ),
              child: Text("Hủy"),
            ),
            ElevatedButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.red,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                onConfirm();
              },
              child: const Text("Xác nhận"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      PermissionStatus storageStatus = PermissionStatus.denied;
      PermissionStatus photosStatus = PermissionStatus.denied;

      if (Platform.isAndroid) {
        storageStatus = await Permission.storage.request();
      }

      photosStatus = await Permission.photos.request();

      if (storageStatus.isGranted || photosStatus.isGranted) {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (pickedFile != null && mounted) {
          setState(() {
            _avatarImage = File(pickedFile.path);
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng cấp quyền truy cập để chọn ảnh'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        if (storageStatus.isPermanentlyDenied ||
            photosStatus.isPermanentlyDenied) {
          await openAppSettings();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildProfilePicture(UserViewModel vm) {
    final user = vm.user;

    ImageProvider avatarProvider;

    if (_avatarImage != null) {
      avatarProvider = FileImage(_avatarImage!);
    } else if (user != null && user.avatarUrl.isNotEmpty) {
      avatarProvider = NetworkImage(user.avatarUrl);
    } else {
      avatarProvider = const AssetImage("");
    }

    return Stack(
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
            child: Image(
              image: avatarProvider,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              _pickImage();
            },
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
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.user != null) {
          _usernameController.text = vm.user!.name;
          _emailController.text = vm.user!.email;
          _phoneController.text = vm.user!.phone;
        }

        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.text,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Chỉnh sửa hồ sơ",
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                _buildProfilePicture(vm),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("ID: ", style: TextStyle(color: Colors.black, fontSize: 14,fontWeight:FontWeight.bold)),
                    Text(
                      "${vm.user?.uid ?? ''}",
                      style: const TextStyle(color: Colors.black, fontSize: 14,fontWeight:FontWeight.w400),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                buildTextField("Tên người dùng", _usernameController),
                SizedBox(height: 10,),
                buildTextField("Email", _emailController),
                SizedBox(height: 10,),
                buildTextField("Số điện thoại", _phoneController),
                SizedBox(height: 10,),
                buildPasswordField("Mật khẩu", _passwordController, true),
                SizedBox(height: 10,),
                buildPasswordField(
                  "Nhập lại mật khẩu",
                  _confirmPasswordController,
                  false,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.text,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      _showSaveDialog(context, () => _saveChanges(vm));
                    },
                    child: const Text(
                      "Lưu thay đổi",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18
                      ),
                    ),
                  )
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }


  Widget buildPasswordField(
    String label,
    TextEditingController controller,
    bool isPassword,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : _obscureConfirmPassword,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: IconButton(
            icon: Icon(
              isPassword
                  ? (_obscurePassword ? Icons.visibility_off : Icons.visibility)
                  : (_obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
            ),
            onPressed: () {
              setState(() {
                if (isPassword) {
                  _obscurePassword = !_obscurePassword;
                } else {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                }
              });
            },
          ),
        ),
      ),
    );
  }
}
