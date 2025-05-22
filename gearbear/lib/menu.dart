import 'package:flutter/material.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pack Setting'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // TODO: 메뉴 드로어 열기
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            onPressed: () {
              // TODO: 데이터 다운로드 로직
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 메뉴 헤더
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Pack Setting',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // 메뉴 항목들
            _buildMenuItem(
              title: 'Pack Weight',
              icon: Icons.scale,
              onTap: () => Navigator.pushNamed(context, '/statistics'),
              trailingText: '1160 g',
            ),
            _buildMenuItem(
              title: 'Gear List',
              icon: Icons.list_alt,
              onTap: () => Navigator.pushNamed(context, '/gear_list'),
            ),
            _buildMenuItem(
              title: 'Camping Map',
              icon: Icons.map,
              onTap: () {
                // TODO: 캠핑 지도 페이지로 이동
              },
            ),
            _buildMenuItem(
              title: 'Community',
              icon: Icons.people,
              onTap: () {
                // TODO: 커뮤니티 페이지로 이동
              },
            ),
            
            // 추가 카테고리 섹션
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildMenuItem(
              title: 'Big 4',
              icon: Icons.add_home_work,
              onTap: () {
                // TODO: Big 4 카테고리로 이동
              },
              trailingText: '1500 g',
            ),
            _buildMenuItem(
              title: 'Kitcheon',
              icon: Icons.kitchen,
              onTap: () {
                // TODO: Kitcheon 카테고리로 이동
              },
              trailingText: '215 g',
            ),
            
            // 추가 버튼
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 장비 추가 페이지로 이동
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(100, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Add gear', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.deepPurple),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              if (trailingText != null)
                Text(
                  trailingText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
