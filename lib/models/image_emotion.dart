class ImageEmotion {
  final String label;
  final double score;
  final List<double> box;
  final Map<String, double> scores;
  final String? imageUrl;             // ảnh đã phân tích (Cloudinary)

  ImageEmotion({
    required this.label,
    required this.score,
    required this.box,
    required this.scores,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
    'label': label,
    'score': score,
    'box': box,
    'scores': scores,
    'imageUrl': imageUrl,
  };

  factory ImageEmotion.fromMap(Map<String, dynamic> m) => ImageEmotion(
    label: (m['label'] ?? '').toString(),
    score: (m['score'] as num?)?.toDouble() ?? 0,
    box: ((m['box'] as List?) ?? []).map((e) => (e as num).toDouble()).toList(),
    scores: (m['scores'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    ) ??
        {},
    imageUrl: m['imageUrl'] as String?,
  );
}
