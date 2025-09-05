import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/diary_repository.dart';
import '../../theme/app_colors.dart';
import '../../view_models/new_diary_view_model.dart';

class NewDiaryPage extends StatelessWidget {
  const NewDiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Config API base (đổi IP LAN khi chạy trên device thật)
    const baseUrl = 'http://192.168.1.72:3000';

    return ChangeNotifierProvider(
      create:
          (_) => NewDiaryViewModel(
            repo: DiaryRepository(useUserSubcollection: true),
            ai: AIService(baseUrl: baseUrl),
          ),
      child: const _NewDiaryView(),
    );
  }
}

class _NewDiaryView extends StatefulWidget {
  const _NewDiaryView();

  @override
  State<_NewDiaryView> createState() => _NewDiaryViewState();
}

class _NewDiaryViewState extends State<_NewDiaryView> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  static const feelings = ['Vui', 'Bình thường', 'Buồn', 'Mệt mỏi'];

  Future<void> _pickImages(NewDiaryViewModel vm) async {
    final picked = await _picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 88,
    );
    if (picked.isEmpty) return;
    vm.addLocalImages(picked.map((x) => File(x.path)).toList());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NewDiaryViewModel>(
      builder: (context, vm, _) {
        final canSave = vm.canSave && !vm.saving;

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
                  onPressed:
                      canSave
                          ? () async {
                            try {
                              final id = await vm.save(analyzeImages: true);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Đã lưu nhật ký',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                  duration: const Duration(seconds: 3),
                                  elevation: 6,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                ),
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Lỗi: $e',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red.shade600,
                                  duration: const Duration(seconds: 4),
                                  elevation: 6,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                ),
                              );
                            }
                          }
                          : null,

                  style: TextButton.styleFrom(
                    backgroundColor:
                        canSave ? AppColors.white : Colors.grey[400],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    vm.saving ? 'Đang lưu...' : 'Lưu',
                    style: TextStyle(
                      color: canSave ? const Color(0xFF009206) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // feelings
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: feelings.length,
                    itemBuilder: (_, i) {
                      final f = feelings[i];
                      final selected = vm.feeling == f;
                      return GestureDetector(
                        onTap: () => vm.setFeeling(f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                selected ? Colors.grey[800] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: TextField(
                      controller: _controller,
                      onChanged: vm.setContent,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: "Hôm nay bạn cảm thấy thế nào?",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                const Divider(thickness: 4, color: Colors.grey),

                // images
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child:
                      vm.localImages.isEmpty
                          ? GestureDetector(
                            onTap: () => _pickImages(vm),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.folder_open,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "Thêm tệp hình ảnh",
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
                                  itemCount: vm.localImages.length + 1,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (_, i) {
                                    if (i == vm.localImages.length) {
                                      return GestureDetector(
                                        onTap: () => _pickImages(vm),
                                        child: Container(
                                          width: 80,
                                          height: 90,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            size: 32,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    }
                                    final file = vm.localImages[i];
                                    return Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.file(
                                            file,
                                            width: 80,
                                            height: 90,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          right: 4,
                                          top: 4,
                                          child: GestureDetector(
                                            onTap: () => vm.removeLocalAt(i),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              padding: const EdgeInsets.all(2),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Đã thêm ${vm.localImages.length} tệp",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                ),

                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Lỗi: ${vm.error}',
                      style: const TextStyle(color: Colors.red),
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
