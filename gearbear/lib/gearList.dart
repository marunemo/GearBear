import 'package:flutter/material.dart';

class GearListPage extends StatefulWidget {
  const GearListPage({Key? key}) : super(key: key);

  @override
  _GearListPageState createState() => _GearListPageState();
}

class _GearListPageState extends State<GearListPage> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gear List'),
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
      body: Column(
        children: [
          // 검색 필드
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                // TODO: 검색 기능 구현
                setState(() {});
              },
            ),
          ),
          
          // 장비 목록
          Expanded(
            child: ListView.builder(
              itemCount: 8, // 예시 데이터 수
              itemBuilder: (context, index) {
                return _buildGearListItem(
                  name: 'Gossamer Gear The One',
                  weight: '539 g',
                  isFavorite: index % 2 == 0,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 장비 추가 페이지로 이동
          Navigator.pushNamed(context, '/add_gear');
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  
  Widget _buildGearListItem({
    required String name,
    required String weight,
    required bool isFavorite,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // 아이콘 영역
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.backpack, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          
          // 텍스트 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tent $weight',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // 즐겨찾기 아이콘
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.amber : Colors.grey,
            ),
            onPressed: () {
              // TODO: 즐겨찾기 기능 구현
            },
          ),
        ],
      ),
    );
  }
}
