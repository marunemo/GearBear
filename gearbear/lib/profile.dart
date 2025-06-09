import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
          children: [
            // 프로필 이미지 및 이름
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/profile_bear.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Handong Kim',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '12345678@handong.ac.kr',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 프로필 편집 버튼
                  OutlinedButton(
                    onPressed: () {
                      // TODO: 프로필 편집 기능 구현
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Edit profile'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 설정 옵션들
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Notice',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const Divider(),
            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const Divider(),
            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Impairment',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const Divider(),
            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Logout',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
