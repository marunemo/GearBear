import 'package:flutter/material.dart';

class PackSettingPage extends StatefulWidget {
  const PackSettingPage({Key? key}) : super(key: key);

  @override
  _PackSettingPageState createState() => _PackSettingPageState();
}

class _PackSettingPageState extends State<PackSettingPage> {
  String _selectedSeason = 'Winter (0~5°C)';
  final List<String> _seasons = ['Winter (0~5°C)', 'Spring (5~15°C)', 'Summer (15~25°C)', 'Fall (5~15°C)'];
  
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
            // 시즌 선택 드롭다운
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButton<String>(
                value: _selectedSeason,
                icon: const Icon(Icons.arrow_drop_down),
                isExpanded: true,
                underline: Container(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSeason = newValue!;
                  });
                },
                items: _seasons.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Big 4 카테고리
            _buildCategorySection(
              title: 'Big 4',
              items: [
                GearItem(name: 'Nemo Kunai', weight: '1160 g', icon: Icons.add_home_work),
                GearItem(name: 'Thermarest xLite', weight: '595 g', icon: Icons.airline_seat_flat),
                GearItem(name: '2-pack Nero', weight: '365g', icon: Icons.backpack),
                GearItem(name: 'Cumulus Panyam', weight: '940 g', icon: Icons.bed),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Kitcheon 카테고리
            _buildCategorySection(
              title: 'Kitcheon',
              items: [
                GearItem(name: 'BRS-3000T', weight: '25 g', icon: Icons.local_fire_department),
                GearItem(name: 'Titanium pot', weight: '150 g', icon: Icons.soup_kitchen),
                GearItem(name: 'Opinel knife', weight: '40 g', icon: Icons.kitchen),
              ],
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
  
  Widget _buildCategorySection({required String title, required List<GearItem> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: 카테고리 편집 기능
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => _buildGearItem(item)).toList(),
        ],
      ),
    );
  }
  
  Widget _buildGearItem(GearItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.iconColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Text(
            item.name,
            style: const TextStyle(fontSize: 16),
          ),
          const Spacer(),
          Text(
            item.weight,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class GearItem {
  final String name;
  final String weight;
  final IconData icon;
  final Color iconColor;
  
  GearItem({
    required this.name,
    required this.weight,
    required this.icon,
    this.iconColor = Colors.orangeAccent,
  });
}
