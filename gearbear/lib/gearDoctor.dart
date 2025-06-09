import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase/firebase_options.dart';
import 'models/gear_model.dart';

final List<String> categories = [
  'Tent', 'Sleeping Bag', 'Matt', 'BackPack', 'Cook Set',
  'Clothes', 'Electonics', 'etc'
];

// SearchedItem 클래스는 기존과 동일합니다.
class SearchedItem {
  final String gearName;
  final String manufacturer;
  final String type;
  final int weight;
  final String imgUrl;

  SearchedItem({
    required this.gearName,
    required this.manufacturer,
    required this.type,
    required this.weight,
    required this.imgUrl,
  });

  factory SearchedItem.fromJson(Map<String, dynamic> json) {
    return SearchedItem(
      gearName: json['gearName'] ?? 'N/A',
      manufacturer: json['manufacturer'] ?? 'N/A',
      type: json['type'] ?? 'etc',
      weight: (json['weight'] as num?)?.toInt() ?? 0,
      imgUrl: json['imgUrl'] ?? '',
    );
  }
}

// GeminiService 수정: Google 검색 Tool 적용
class GeminiService {
  final GenerativeModel _model;

  GeminiService()
      // 모델 초기화 시 tools 파라미터에 GoogleSearch()를 추가합니다.
      : _model = FirebaseAI.googleAI().generativeModel(
          model: 'gemini-2.0-flash', // Google Search Tool과 호환되는 모델 사용
          // tools: [Tool.googleSearch()], // <<< Google 검색 Tool 활성화
          generationConfig: GenerationConfig(
            temperature: 0.3,
            responseMimeType: 'application/json',
          ),
        );

  final _categories = const ['Tent', 'Sleeping Bag', 'Matt', 'BackPack', 'Cook Set', 'Clothes', 'Electonics', 'etc'];

  Future<List<SearchedItem>> searchCampingGear(String query) async {
    // 시스템 프롬프트 수정: 검색 Tool 사용을 명시적으로 지시
    final systemPrompt =
      'You are a helpful camping gear shopping assistant with access to Google Search. '
      'Use your search tool to find real, currently available camping gear based on the user\'s query. '
      'The "type" of gear must be one of the following categories: ${_categories.join(', ')}. '
      'Provide the result as a JSON array where each object has "gearName", "manufacturer", "type", "weight" (in grams, integer), and "imgUrl". '
      'Only respond with the JSON array.';

    final content = [
      Content.text(systemPrompt),
      Content.text('Search query: "$query"'),
    ];
    final response = await _model.generateContent(content);
    final jsonString = response.text;

    if (jsonString == null || jsonString.isEmpty) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => SearchedItem.fromJson(json)).toList();
  }
}


// --- 메인 앱 및 화면 위젯 ---
class GearDoctorPage extends StatelessWidget {
  const GearDoctorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camping Gear Finder',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('🏕️ Gemini Gear Finder (No State-Management)'),
        ),
        // 핵심 로직을 담고 있는 StatefulWidget을 body에 배치
        body: const GearFinderWidget(),
      ),
    );
  }
}

// --- 상태 관리 없는 핵심 로직 위젯 ---
class GearFinderWidget extends StatefulWidget {
  const GearFinderWidget({super.key});

  @override
  State<GearFinderWidget> createState() => _GearFinderWidgetState();
}

// GearFinderWidget의 State 클래스
class _GearFinderWidgetState extends State<GearFinderWidget> {
  final GeminiService _geminiService = GeminiService();
  // SearchController 대신 TextEditingController 사용
  final TextEditingController _searchController = TextEditingController(); 
  
  bool _isLoading = false;
  List<SearchedItem> _searchResults = [];
  String? _errorMessage;

  // _performSearch 함수는 기존과 동일하게 유지됩니다.
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _geminiService.searchCampingGear(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "검색 중 오류 발생: $e";
        _searchResults = []; // 오류 발생 시 이전 결과 초기화
        _isLoading = false;
      });
    }
  }

  // Firestore에 장비를 추가하는 함수
  Future<void> _addGearToFirestore(SearchedItem item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final gearCollection = FirebaseFirestore.instance.collection('Gear');
    final docRef = gearCollection.doc();
    final gid = docRef.id;

    final newGear = Gear(
      uid: uid,     // 예시 사용자 ID
      gid: gid,     // Firestore 문서 ID를 장비의 고유 ID로 사용
      gearName: item.gearName,
      manufacturer: item.manufacturer,
      type: item.type,
      weight: item.weight,
      quantity: 1,
      imgUrl: item.imgUrl,
    );

    try {
      // Gear 객체를 Map으로 변환하여 Firestore에 저장
      await docRef.set(newGear.toMap());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.gearName}이(가) Firestore에 추가되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firestore 저장 실패: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // build 메서드 수정: UI 로직 변경
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- 검색창 UI 변경 ---
        Padding(
          padding: const EdgeInsets.all(16.0),
          // TextField와 검색 버튼으로 구성
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: '캠핑 장비 검색...',
                    border: OutlineInputBorder(),
                  ),
                  // 키보드의 완료 버튼으로도 검색 실행
                  onSubmitted: (value) => _performSearch(value),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _performSearch(_searchController.text),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- 검색 결과 표시 UI ---
        // 로딩 중일 때 인디케이터 표시
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        // 에러 발생 시 메시지 표시
        else if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          )
        // 검색 결과가 있을 때 리스트 표시
        else if (_searchResults.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(item.gearName),
                    subtitle: Text('${item.manufacturer} / ${item.type} / ${item.weight}g'),
                    trailing: ElevatedButton(
                      child: const Text('추가'),
                      onPressed: () => _addGearToFirestore(item),
                    ),
                  ),
                );
              },
            ),
          )
        // 검색 결과가 없을 때 (초기 상태 포함)
        else
          const Expanded(
            child: Center(child: Text('검색어를 입력하고 검색 버튼을 누르세요.')),
          ),

        const Divider(),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("내 캠핑 장비 목록 (from Firestore)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        
        // --- Firestore 데이터 표시 UI ---
        Expanded(
          // StreamBuilder를 사용하여 Firestore 'Gear' 컬렉션의 변경사항을 실시간으로 감지
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Gear').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('데이터를 불러오지 못했습니다: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('저장된 장비가 없습니다.'));
              }

              // Firestore 문서를 Gear 객체 리스트로 변환
              final gears = snapshot.data!.docs.map((doc) => Gear.fromDocument(doc)).toList();

              return ListView.builder(
                itemCount: gears.length,
                itemBuilder: (context, index) {
                  final gear = gears[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(gear.type.isNotEmpty ? gear.type.substring(0, 1) : "E")),
                    title: Text(gear.gearName),
                    subtitle: Text('${gear.manufacturer} | ${gear.type}'),
                    trailing: Text('${gear.weight}g'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}