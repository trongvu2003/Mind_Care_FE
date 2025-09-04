class ImageEmotion {
  final String url;
  final String overallEmotion;
  final double confidence;
  final Map<String, double> scores;
  final String? summary;
  final List<String> suggestions;

  ImageEmotion({
    required this.url,
    required this.overallEmotion,
    required this.confidence,
    required this.scores,
    this.summary,
    this.suggestions = const [],
  });

  Map<String, dynamic> toMap() => {
    'url': url,
    'overallEmotion': overallEmotion,
    'confidence': confidence,
    'scores': scores,
    if (summary != null) 'summary': summary,
    'suggestions': suggestions,
  };

  factory ImageEmotion.fromMap(Map<String, dynamic> m) => ImageEmotion(
    url: (m['url'] ?? '').toString(),
    overallEmotion: (m['overallEmotion'] ?? 'neutral').toString(),
    confidence: (m['confidence'] ?? 0).toDouble(),
    scores: Map<String, double>.from(
      (m['scores'] ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
    ),
    summary: (m['summary'] as String?)?.toString(),
    suggestions: List<String>.from(m['suggestions'] ?? []),
  );
}
