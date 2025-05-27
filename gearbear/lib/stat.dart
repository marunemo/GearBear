import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/gear_model.dart';
import 'models/camp_model.dart';

class StatisticsPage extends StatelessWidget {
  final Camp camp;
  
  const StatisticsPage({
    Key? key,
    required this.camp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pack Weight'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: _getGearFuture(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final gears = _parseGears(snapshot);
        if (gears.isEmpty) {
          return const Center(child: Text('No gear found'));
        }

        final chartData = _processChartData(gears);
        return _buildChartUI(chartData);
      },
    );
  }

  Future<QuerySnapshot> _getGearFuture() async {
    return FirebaseFirestore.instance
        .collection('gear')
        .where('gid', whereIn: camp.gidList)
        .get();
  }

  List<Gear> _parseGears(AsyncSnapshot<QuerySnapshot> snapshot) {
    return snapshot.data!.docs
        .map((doc) => Gear.fromFirestore(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Map<String, double> _processChartData(List<Gear> gears) {
    final categoryWeights = <String, double>{};
    
    for (final gear in gears) {
      final totalWeight = gear.weight * gear.quantity;
      categoryWeights.update(
        gear.type,
        (value) => value + totalWeight.toDouble(),
        ifAbsent: () => totalWeight.toDouble(),  
      );
    }

    return categoryWeights;
  }

  Widget _buildChartUI(Map<String, double> chartData) {
    final totalWeight = chartData.values.fold<double>(0, (sum, w) => sum + w);
    final chartSections = _buildChartSections(chartData);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildPieChart(chartSections, totalWeight),
          const SizedBox(height: 40),
          ..._buildLegendItems(chartData),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<PieChartSectionData> sections, double total) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 70,
              sectionsSpace: 0,
            ),
          ),
          Center(
            child: Text(
              '${(total / 1000).toStringAsFixed(1)} kg',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections(Map<String, double> data) {
    final colors = _getCategoryColors();
    return data.entries.map((entry) {
      return PieChartSectionData(
        color: colors[entry.key] ?? Colors.grey,
        value: entry.value,
        title: '',
        radius: 50,
        showTitle: false,
      );
    }).toList();
  }

  List<Widget> _buildLegendItems(Map<String, double> data) {
    final colors = _getCategoryColors();
    return data.entries.map((entry) {
      return _buildLegendItem(
        entry.key,
        colors[entry.key] ?? Colors.grey,
        '${(entry.value / 1000).toStringAsFixed(1)} kg',
      );
    }).toList();
  }

  Widget _buildLegendItem(String title, Color color, String weight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(width: 16, height: 16, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(weight),
        ],
      ),
    );
  }

  Map<String, Color> _getCategoryColors() {
    return {
      'Tent': Colors.blue,
      'Sleeping Bag': Colors.green,
      'Matt': Colors.orange,
      'BackPack': Colors.red,
      'Cook Set': Colors.purple,
      'Clothes': Colors.teal,
      'Electonics': Colors.amber,
      'etc': Colors.grey,
    };
  }
}
