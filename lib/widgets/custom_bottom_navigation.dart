import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
class CustomBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.text,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.text,
        selectedItemColor: AppColors.title,
        unselectedItemColor: AppColors.black,
        elevation: 0,
        items: _buildBottomNavItems(),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildBottomNavItems() {
    return [
      _buildBottomNavItem(Icons.edit_note, 'Nhật ký'),
      _buildBottomNavItem(Icons.lightbulb_outline, 'Gợi ý'),
      _buildBottomNavItem(Icons.bar_chart, 'Thống kê'),
      _buildBottomNavItem(Icons.camera_alt, 'Camera AI'),
      _buildBottomNavItem(Icons.person_outline, 'Cá nhân'),
    ];
  }

  BottomNavigationBarItem _buildBottomNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
    );
  }
}