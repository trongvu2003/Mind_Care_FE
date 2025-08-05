import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class Intro2Screen extends StatelessWidget {
  const Intro2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/intro1.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 10),
                Image.asset(
                  'assets/images/intro2.png',
                ),
                Column(
                  children: [
                    const Text(
                      'SẴN SÀNG LẮNG NGHE, GIẢI ĐÁP VÀ ĐỒNG HÀNH CÙNG BẠN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'LUÔN SẴN SÀNG HỖ TRỢ VÀ ĐỒNG HÀNH',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.button,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          )
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("TRỞ LẠI"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.text,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          )
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/startscreen');
                        },
                        child: const Text("TIẾP TỤC"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
