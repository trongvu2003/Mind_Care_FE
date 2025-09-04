class ImageEmotion {
  final String url;
  final String overallEmotion;
  final double confidence;
  final Map<String, double> scores;

  ImageEmotion({
    required this.url,
    required this.overallEmotion,
    required this.confidence,
    required this.scores,
  });

  Map<String, dynamic> toMap() => {
    'url': url,
    'overallEmotion': overallEmotion,
    'confidence': confidence,
    'scores': scores,
  };

  factory ImageEmotion.fromMap(Map<String, dynamic> m) => ImageEmotion(
    url: (m['url'] ?? '').toString(),
    overallEmotion: (m['overallEmotion'] ?? '').toString(),
    confidence: (m['confidence'] ?? 0).toDouble(),
    scores: (m['scores'] as Map?)
        ?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ??
        <String, double>{},
  );
}
