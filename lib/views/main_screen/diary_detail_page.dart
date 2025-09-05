import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/diary_entry.dart';
import '../../services/diary_repository.dart';
import '../../theme/app_colors.dart';
import '../../view_models/diary_detail_view_model.dart';

class DiaryDetailPage extends StatelessWidget {
  final String diaryId;
  final String uid;
  final DiaryEntry? initial;

  const DiaryDetailPage({
    super.key,
    required this.diaryId,
    required this.uid,
    this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => DiaryDetailViewModel(
            repo: DiaryRepository(useUserSubcollection: true),
            uid: uid,
            diaryId: diaryId,
          )..start(),
      child: const _DiaryDetailView(),
    );
  }
}

class _DiaryDetailView extends StatelessWidget {
  const _DiaryDetailView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DiaryDetailViewModel>();
    final entry = vm.entry;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chi tiết nhật ký",
          style: TextStyle(
            color: AppColors.title,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body:
          vm.loading
              ? const Center(child: CircularProgressIndicator())
              : vm.error != null
              ? Center(child: Text('Lỗi: ${vm.error}'))
              : (entry == null)
              ? const Center(child: Text('Bài viết không còn tồn tại'))
              : _DetailBody(entry: entry),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final DiaryEntry entry;
  const _DetailBody({required this.entry});

  @override
  Widget build(BuildContext context) {
    // Nếu DiaryEntry.createdAt là DateTime (theo repo đã chuẩn hoá), dùng trực tiếp:
    final dt = entry.createdAt.toLocal();
    // Nếu model của bạn vẫn là Timestamp, đổi thành:
    // final dt = (entry.createdAt as Timestamp).toDate().toLocal();

    final timeStr = DateFormat('HH:mm, dd/MM/yyyy').format(dt);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header thời gian + chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.edit_note, color: Colors.teal, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (entry.selectedFeeling != null &&
                  entry.selectedFeeling!.isNotEmpty)
                _Chip(label: 'Cảm xúc: ${entry.selectedFeeling}'),
              if (entry.textSentiment.isNotEmpty)
                _Chip(
                  label:
                      'Text: ${entry.textSentiment}'
                      '${entry.textSentimentScore > 0 ? ' (${(entry.textSentimentScore * 100).toStringAsFixed(0)}%)' : ''}',
                ),
            ],
          ),
          const SizedBox(height: 16),

          /// Tóm tắt bài viết (SUMMARY) — ĐÃ ĐƯA VÀO CHILDREN ĐÚNG CHỖ
          if ((entry.summary ?? '').trim().isNotEmpty) ...[
            const Text(
              'Tóm tắt',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              entry.summary!,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 16),
          ],

          /// Nội dung
          if (entry.content.isNotEmpty) ...[
            const Text(
              'Nội dung',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              entry.content,
              style: const TextStyle(fontSize: 17, height: 1.5),
            ),
            const SizedBox(height: 16),
          ],

          /// Ảnh (grid)
          if (entry.imageUrls.isNotEmpty) ...[
            const Text(
              'Hình ảnh',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            _ImagesGrid(urls: entry.imageUrls),
            const SizedBox(height: 16),
          ],

          /// Phân tích ảnh — “Tóm tắt ảnh” ĐƯỢC ĐƯA VÀO BÊN TRONG VÒNG LẶP MỖI ẢNH
          if (entry.imageEmotions.isNotEmpty) ...[
            const Text(
              'Phân tích ảnh',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Column(
              children:
                  entry.imageEmotions.map((em) {
                    final conf = (em.confidence ?? 0) * 100;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nhận định: ${em.overallEmotion ?? '-'}  '
                            '(${conf.toStringAsFixed(0)}%)',
                          ),

                          if ((em.summary ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Tóm tắt ảnh: ${em.summary!}'),
                          ],

                          const SizedBox(height: 8),
                          _ScoresRow(scores: em.scores ?? const {}),
                        ],
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          /// Gợi ý
          const Text(
            'Gợi ý',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          _SuggestionList(entry: entry),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _ImagesGrid extends StatelessWidget {
  final List<String> urls;
  const _ImagesGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      final u = urls.first;
      return GestureDetector(
        onTap: () => _preview(context, u),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(u, fit: BoxFit.cover, width: double.infinity),
        ),
      );
    }

    return GridView.builder(
      itemCount: urls.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (_, i) {
        final u = urls[i];
        return GestureDetector(
          onTap: () => _preview(context, u),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(u, fit: BoxFit.cover),
          ),
        );
      },
    );
  }

  void _preview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.all(12),
            backgroundColor: Colors.black,
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              child: Stack(
                children: [
                  Center(child: Image.network(url)),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class _ScoresRow extends StatelessWidget {
  final Map<String, double> scores;
  const _ScoresRow({required this.scores});

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) return const SizedBox.shrink();
    final keys = [
      'happy',
      'neutral',
      'sad',
      'angry',
      'fear',
      'disgust',
      'surprise',
    ];
    return Column(
      children:
          keys.where((k) => scores[k] != null).map((k) {
            final v = (scores[k] ?? 0) * 100;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(k)),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (v / 100).clamp(0, 1),
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.teal,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${v.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  final DiaryEntry entry;
  const _SuggestionList({required this.entry});

  @override
  Widget build(BuildContext context) {
    final sugs = entry.suggestions ?? const [];
    if (sugs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Chưa có gợi ý. Viết nhật ký hoặc thêm ảnh để AI đề xuất nhé!',
        ),
      );
    }
    return Column(
      children:
          sugs.map((s) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.title,
                    size: 35,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s, style: const TextStyle(fontSize: 17)),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
