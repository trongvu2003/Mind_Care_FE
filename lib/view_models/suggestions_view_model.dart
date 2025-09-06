import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SuggestionsViewModel extends ChangeNotifier {
  final String uid;
  SuggestionsViewModel({required this.uid});

  bool loading = true;
  String? error;
  bool hasToday= false;
  String label = 'Không rõ';

  // % mức độ tích cực hiển thị (0..1)
  double percent = 0.0;

  // Danh sách gợi ý hiển thị
  List<String> suggestions = const [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  void start() {
    loading = true;
    error = null;
    notifyListeners();

    _sub?.cancel();
    if (uid.isEmpty) {
      _setEmptyToday();
      return;
    }

    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diaries')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snap) {
            try {
              if (snap.docs.isEmpty) {
                _setEmptyToday();
                return;
              }

              final doc = snap.docs.first;
              final m = doc.data();
              DateTime? createdAt;
              final rawTs = m['createdAt'];
              if (rawTs is Timestamp) {
                createdAt = rawTs.toDate();
              } else if (rawTs is int) {
                createdAt = DateTime.fromMillisecondsSinceEpoch(rawTs);
              }
              if (createdAt == null ||
                  !_isSameDay(createdAt.toLocal(), DateTime.now())) {
                _setEmptyToday();
                return;
              }

              // Lấy feeling/label
              final selectedFeeling = (m['selectedFeeling'] as String?)?.trim();
              final textSentiment = (m['textSentiment'] as String?)?.trim();
              final textScore =
                  (m['textSentimentScore'] is num)
                      ? (m['textSentimentScore'] as num).toDouble()
                      : null;

              // imageEmotions[0]
              final List imageEmotions =
                  (m['imageEmotions'] as List?) ?? const [];
              Map<String, dynamic> img0 = {};
              if (imageEmotions.isNotEmpty && imageEmotions.first is Map) {
                img0 = Map<String, dynamic>.from(imageEmotions.first as Map);
              }
              final overallEmotion =
                  (img0['overallEmotion'] as String?)?.trim();
              final confidence =
                  (img0['confidence'] is num)
                      ? (img0['confidence'] as num).toDouble()
                      : null;
              final Map<String, dynamic> scores =
                  (img0['scores'] is Map)
                      ? Map<String, dynamic>.from(img0['scores'])
                      : {};

              // Nhãn ưu tiên: selectedFeeling -> textSentiment -> overallEmotion
              final computedLabel =
                  selectedFeeling ??
                  _vnSentiment(textSentiment) ??
                  _vnEmotion(overallEmotion) ??
                  'Không rõ';

              // % ưu tiên: textScore -> scores[label] -> confidence
              double? p = textScore;
              if (p == null && scores.isNotEmpty) {
                final enKey = _enEmotionFromVN(computedLabel);
                if (enKey != null && scores[enKey] is num) {
                  p = (scores[enKey] as num).toDouble();
                }
              }
              p ??= confidence ?? 0.0;
              p = p.clamp(0.0, 1.0);

              // Gợi ý
              final rawSugs = (m['suggestions'] as List?) ?? const [];
              final sugList =
                  rawSugs
                      .whereType<String>()
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

              label = computedLabel;
              percent = p;
              suggestions = sugList.isEmpty ? _fallback() : sugList;
              hasToday = true;
              loading = false;
              error = null;
              notifyListeners();
            } catch (e) {
              loading = false;
              error = e.toString();
              notifyListeners();
            }
          },
          onError: (e) {
            loading = false;
            error = e.toString();
            notifyListeners();
          },
        );
  }

  // Hôm nay chưa có entry → rỗng/empty-state (không lấy gần nhất)
  void _setEmptyToday() {
    hasToday = false;
    label = 'Chưa có dữ liệu hôm nay';
    percent = 0.0;
    suggestions = const [];
    loading = false;
    error = null;
    notifyListeners();
  }

  // Nếu muốn vẫn có gợi ý chung khi có entry hôm nay nhưng thiếu 'suggestions'
  List<String> _fallback() => const [
    "🎶 Nghe một bản nhạc bạn yêu thích.",
    "📓 Ghi lại 3 điều bạn biết ơn hôm nay.",
    "🚶 Đi dạo 10–15 phút để thư giãn.",
  ];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Map sentiment EN → VN
  String? _vnSentiment(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'positive':
        return 'Vui vẻ';
      case 'negative':
        return 'Tiêu cực';
      case 'neutral':
        return 'Bình thường';
    }
    return null;
  }

  // Map emotion EN → VN
  String? _vnEmotion(String? e) {
    switch ((e ?? '').toLowerCase()) {
      case 'happy':
        return 'Vui vẻ';
      case 'sad':
        return 'Buồn';
      case 'angry':
        return 'Tức giận';
      case 'fear':
        return 'Lo lắng';
      case 'disgust':
        return 'Khó chịu';
      case 'surprise':
        return 'Ngạc nhiên';
      case 'neutral':
        return 'Bình thường';
    }
    return null;
  }

  // Dò key EN từ label VN để tra scores
  String? _enEmotionFromVN(String vn) {
    final v = vn.toLowerCase();
    if (v.contains('vui')) return 'happy';
    if (v.contains('buồn')) return 'sad';
    if (v.contains('giận') || v.contains('tức')) return 'angry';
    if (v.contains('lo lắng')) return 'fear';
    if (v.contains('khó chịu') ||
        v.contains('ghê') ||
        v.contains('chán ghét')) {
      return 'disgust';
    }
    if (v.contains('ngạc nhiên')) return 'surprise';
    if (v.contains('bình thường')) return 'neutral';
    if (v.contains('tiêu cực')) return 'negative';
    return null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
