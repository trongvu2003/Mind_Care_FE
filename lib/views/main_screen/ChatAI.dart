import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:mind_mare_fe/theme/app_colors.dart';

import '../../config.dart';
import 'message.dart';

class AichatRoom extends StatefulWidget {
  const AichatRoom({super.key});

  @override
  State<AichatRoom> createState() => _AichatroomState();
}

class _AichatroomState extends State<AichatRoom> {
  final TextEditingController _userInput = TextEditingController();
  final List<Message> _messages = [];

  final ScrollController _scrollController = ScrollController();

  // System prompt để hướng dẫn AI chỉ trả lời mind care
  final String systemPrompt = """
Bạn là MindCare AI – trợ lý tinh thần và hỗ trợ phát triển bản thân. 

Nhiệm vụ của bạn:

1. Trả lời các câu hỏi và gợi ý liên quan đến:
   - Sức khỏe tinh thần, mindfulness, stress management
   - Kỹ năng sống, quản lý cảm xúc, kỹ năng xã hội
   - Động lực, thói quen tích cực, phát triển bản thân
   - Hướng dẫn tự chăm sóc bản thân, cân bằng cuộc sống

2. KHÔNG trả lời về:
   - Chính trị, tôn giáo, các vấn đề nhạy cảm ngoài sức khỏe tinh thần
   - Giải trí, phim ảnh, âm nhạc (trừ khi liên quan đến phát triển bản thân)
   - Thông tin cá nhân của người khác hoặc đời sống riêng tư

3. Khi trả lời:
   - Sử dụng **ngôn ngữ thân thiện, nhẹ nhàng, khích lệ**.
   - Gợi ý các bước hành động tích cực, lời khuyên có tính xây dựng.
   - Nếu câu hỏi không liên quan, từ chối lịch sự và hướng dẫn người dùng về MindCare.
""";

  Future<void> talkWithGemini() async {
    final userMsg = _userInput.text.trim();
    if (userMsg.isEmpty) return;

    setState(() {
      _messages.add(
        Message(
          isUser: true,
          message: userMsg,
          date: DateTime.now().toString(),
        ),
      );
      _userInput.clear();
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: Config.geminiApiKey,
        systemInstruction: Content.text(systemPrompt),
      );

      final content = Content.text(userMsg);
      final response = await model.generateContent([content]);

      setState(() {
        _messages.add(
          Message(
            isUser: false,
            message: response.text ?? "Không có phản hồi.",
            date: DateTime.now().toString(),
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.add(
          Message(
            isUser: false,
            message: "Có lỗi xảy ra khi xử lý câu hỏi. Vui lòng thử lại.",
            date: DateTime.now().toString(),
          ),
        );
      });
    }

    await Future.delayed(const Duration(milliseconds: 100));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 100,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'AIChat',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: AppColors.text,
        foregroundColor: AppColors.title,
        elevation: 2,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.deepPurple, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tôi chỉ trả lời các câu hỏi về sức khỏe tinh thần và phát triển bản thân',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.deepPurple.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message.isUser;

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.text : Colors.deepPurple.shade300,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 0),
                          bottomRight: Radius.circular(isUser ? 0 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.message,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'HH:mm',
                            ).format(DateTime.parse(message.date)),
                            style: TextStyle(fontSize: 12, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    style: TextStyle(
                      color: AppColors.black.withOpacity(0.5),
                    ),
                    controller: _userInput,
                    decoration: InputDecoration(
                      hintText: "Nhập câu hỏi về sức khỏe tinh thần, mindfulness...",
                      hintStyle: TextStyle(
                        color: AppColors.black.withOpacity(0.5),
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onFieldSubmitted: (_) => talkWithGemini(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: talkWithGemini,
                  child: CircleAvatar(
                    radius: 24,
                    child: Icon(Icons.send, color: AppColors.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
