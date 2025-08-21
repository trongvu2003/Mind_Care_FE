import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
class SuggestionsPage extends StatelessWidget {
  const SuggestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> suggestions = [
      {
        "icon": Icons.phone,
        "title": "Liên lạc với bạn",
        "desc": "Gọi điện cho một người bạn thân và trò chuyện để chia sẻ niềm vui",
      },
      {
        "icon": Icons.shopping_cart,
        "title": "Mua sắm",
        "desc": "Dành thời gian khám phá những món đồ mà bạn yêu thích",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Gợi ý hôm nay",
          style: TextStyle(color: AppColors.title, fontWeight: FontWeight.bold,fontSize: 32),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trạng thái cảm xúc hôm nay
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.face_outlined,
                      color: Colors.black, size: 50),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Vui vẻ",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text("Mức độ tích cực"),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: 0.8, // 80%
                          backgroundColor: Colors.grey[300],
                          color: Colors.blue,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text("80%"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Danh sách gợi ý",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Danh sách gợi ý
            Column(
              children: suggestions.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item["icon"], size: 40, color: Colors.black54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["title"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item["desc"],
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.text,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                                child: const Text(
                                  "Thực hiện ngay",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}
