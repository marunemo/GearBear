import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pack Weight'),
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
            const SizedBox(height: 20),
            // 파이 차트
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: Colors.teal,
                          value: 2.1,
                          title: '',
                          radius: 50,
                        ),
                        PieChartSectionData(
                          color: Colors.red,
                          value: 0.6,
                          title: '',
                          radius: 50,
                        ),
                        PieChartSectionData(
                          color: Colors.blue,
                          value: 0.2,
                          title: '',
                          radius: 50,
                        ),
                        PieChartSectionData(
                          color: Colors.orange,
                          value: 1.8,
                          title: '',
                          radius: 50,
                        ),
                      ],
                      centerSpaceRadius: 70,
                      sectionsSpace: 0,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          '2.6 kg',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // 범례
            _buildLegendItem('Big 4', Colors.blue, '1.6 kg'),
            _buildLegendItem('Kitchen', Colors.orange, '0.6 kg'),
            _buildLegendItem('Clothes', Colors.red, '0.2 kg'),
            _buildLegendItem('ETC', Colors.teal, '0.2 kg'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(String title, Color color, String weight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
          const Spacer(),
          Text(
            weight,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
