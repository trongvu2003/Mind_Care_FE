import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../view_models/UserViewModel.dart';

class NewDiaryPage extends StatefulWidget {
  const NewDiaryPage({super.key});

  @override
  State<NewDiaryPage> createState() => _NewDiaryPageState();
}

class _NewDiaryPageState extends State<NewDiaryPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _attachments = [];
  String? selectedFeeling;
  late final UserViewModel userVM;
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final List<String> feelings = ["Vui", "Bình thường", "Buồn", "Mệt mỏi"];
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  static const int maxImages = 5;
  @override
  void initState() {
    super.initState();
    userVM = UserViewModel();
    userVM.loadUser(uid);
  }

  Future<void> _pickImages() async {
    try {
      if (_selectedImages.length >= maxImages) {
        Get.snackbar(
          "Thông báo",
          "Bạn chỉ có thể chọn tối đa $maxImages ảnh",
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final remainingSlots = maxImages - _selectedImages.length;
      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty && mounted) {
        List<File> newImages = [];
        final imagesToAdd = pickedFiles.take(remainingSlots).toList();

        for (var pickedFile in imagesToAdd) {
          newImages.add(File(pickedFile.path));
        }

        setState(() {
          _selectedImages.addAll(newImages);
        });

        if (pickedFiles.length > remainingSlots) {
          Get.snackbar(
            "Thông báo",
            "Chỉ có thể thêm $remainingSlots ảnh nữa. Đã thêm ${imagesToAdd.length} ảnh.",
            backgroundColor: Colors.orange.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      print('Error picking images: $e');
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể chọn ảnh: $e",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final canSave = _controller.text.isNotEmpty || _attachments.isNotEmpty;

    return ChangeNotifierProvider.value(
      value: userVM,
      child: Consumer<UserViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              backgroundColor: Colors.cyan,
              elevation: 0,
              title: const Text(
                "Nhật ký mới",
                style: TextStyle(
                  color: AppColors.title,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 10, bottom: 8),
                  child: TextButton(
                    onPressed: canSave
                        ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Đã lưu nhật ký")),
                      );
                    }
                        : null,
                    style: TextButton.styleFrom(
                      backgroundColor: canSave ? AppColors.white : Colors.grey[800],
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Lưu",
                      style: TextStyle(
                        color: canSave ? const Color(0xFF009206): AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: vm.user?.avatarUrl.isNotEmpty == true
                        ? NetworkImage(vm.user!.avatarUrl)
                        : null,
                    child: vm.user?.avatarUrl.isEmpty ?? true
                        ? const Icon(Icons.person, color: Colors.white, size: 28)
                        : null,
                  ),
                  title: Text(
                    vm.user?.name ?? "Người dùng",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.black54),
                    onPressed: () {},
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: feelings.length,
                    itemBuilder: (context, index) {
                      final feeling = feelings[index];
                      final isSelected = selectedFeeling == feeling;
                      return GestureDetector(
                        onTap: () => setState(() => selectedFeeling = feeling),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.grey[800] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            feeling,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Text nhập nội dung
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: "Hôm nay bạn cảm thấy thế nào?",
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                Divider(
                  thickness: 4,
                  color: Colors.grey,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _selectedImages.isEmpty
                      ? GestureDetector(
                    onTap: _pickImages,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Icon(Icons.folder_open, size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          "Thêm tệp hình ảnh",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            if (index == _selectedImages.length) {
                              return GestureDetector(
                                onTap: _pickImages,
                                child: Container(
                                  width: 80,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.add, size: 32, color: Colors.grey),
                                ),
                              );
                            }

                            final file = _selectedImages[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                file,
                                width: 80,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        "Đã thêm ${_selectedImages.length} tệp",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}