import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'firebase/firebase_options.dart';
import 'models/gear_model.dart';

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

Future<Map<String, Object?>> fetchCampToolByGoogleSearch(String query) async {
  final apiKey = 'AIzaSyB5euO_bgCm-DXABEn1WMKHiHrU-1U2tJo';
  final cx = '004e3e712339d45f3';
  final url = 'https://www.googleapis.com/customsearch/v1?key=$apiKey&cx=$cx&q=$query';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    // 대표 검색 결과 10개만 추출
    final items = data['items'] as List<dynamic>?;
    if (items != null && items.isNotEmpty) {
      return {
        'results': items.take(10).map((item) => {
          'title': item['title'],
          'link': item['link'],
          'snippet': item['snippet'],
        }).toList(),
      };
    } else {
      return {'results': []};
    }
  } else {
    return {'error': '검색 실패: ${response.statusCode}'};
  }
}

// GeminiService 수정: Google 검색 Tool 적용
class GeminiService {
  final GenerativeModel _model;
  final FunctionDeclaration fetchCampToolByGoogleSearchTool;

  GeminiService()
      : fetchCampToolByGoogleSearchTool = FunctionDeclaration(
          'fetchCampToolByGoogleSearch',
          'Get real-time camp tool information via Google search',
          parameters: {
            'query': Schema.string(
              description: 'Camp tool name or related keyword to search for (e.g., camp lantern recommends)'
            ),
          },
        ),
        _model = FirebaseAI.googleAI().generativeModel(
          model: 'gemini-2.0-flash',
          tools: [
            Tool.functionDeclarations([
              FunctionDeclaration(
                'fetchCampToolByGoogleSearch',
                'Get real-time camp tool information via Google search',
                parameters: {
                  'query': Schema.string(
                    description: 'Camp tool name or related keyword to search for (e.g., camp lantern recommends)'
                  ),
                },
              ),
            ]),
          ],
          generationConfig: GenerationConfig(
            temperature: 0.3,
            // responseMimeType: 'application/json',
          ),
        );

  final _categories = const [
    'Tent', 'Sleeping Bag', 'Matt', 'BackPack', 'Cook Set',
    'Clothes', 'Electonics', 'etc'
  ];

  Future<List<SearchedItem>> searchCampingGear(String query) async {
    final systemPrompt =
      'You are a helpful camping gear shopping assistant with access to Google Search. '
      'Use your search tool to find real, currently available camping gear based on the user\'s query. '
      'The "type" of gear must be one of the following categories: ${_categories.join(', ')}. '
      'Provide the result as a JSON array where each object has "gearName", "manufacturer", "type", "weight" (in grams, integer), and "imgUrl". '
      'Only respond with the JSON array.';

    final chat = _model.startChat();

    // 1. 사용자 프롬프트 전달
    var response = await chat.sendMessage(Content.text('$systemPrompt\nSearch query: "$query"'));

    // 2. 함수 호출이 필요한지 확인
    final functionCalls = response.functionCalls.toList();
    if (functionCalls.isNotEmpty) {
      final functionCall = functionCalls.first;
      if (functionCall.name == 'fetchCampToolByGoogleSearch') {
        final searchQuery = functionCall.args['query'] as String;
        // 3. 실제 구글 검색 함수 호출
        final functionResult = await fetchCampToolByGoogleSearch(searchQuery);
        // 4. 함수 결과를 모델에 전달
        response = await chat.sendMessage(
          Content.functionResponse(functionCall.name, functionResult)
        );
      }
    }

    String extractPureJson(String? responseText) {
      if(responseText == null) return "";
      
      // ```json ... `````` ... ``` 지우기
      final regex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
      final match = regex.firstMatch(responseText);
      if (match != null) {
        return match.group(1)!.trim();
      }
      return responseText.trim();
    }

    // 5. AI의 최종 응답(JSON) 파싱
    final jsonString = extractPureJson(response.text);

    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => SearchedItem.fromJson(json)).toList();
  }
}


class GearDoctorPage extends StatelessWidget {
  const GearDoctorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gear Doctor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // 핵심 로직을 담고 있는 StatefulWidget을 body에 배치
      body: const GearFinderWidget(),
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
        _errorMessage = "Error in search: $e";
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
      uid: uid,     //  사용자 UID
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
          SnackBar(content: Text('${item.gearName} is added.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fail to add the gear: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          // TextField와 검색 버튼으로 구성
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Searching gear...',
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
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    leading: SizedBox(
                      width: 56,
                      height: 56,
                      child:
                          item.imgUrl.isNotEmpty
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  item.imgUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 32,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                              )
                              : Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                              ),
                    ),
                    title: Text(
                      item.gearName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.manufacturer,
                            style: TextStyle(
                              color: Colors.blueGrey[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 16,
                                color: Colors.blueGrey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.type,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.scale,
                                size: 16,
                                color: Colors.blueGrey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.weight}g',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: ElevatedButton(
                      child: const Text('Add'),
                      onPressed: () => _addGearToFirestore(item),
                    ),
                  )
                );
              },
            ),
          )
        // 검색 결과가 없을 때 (초기 상태 포함)
        else
          const Expanded(
            child: Center(child: Text('Enter your search term and press the search button.')),
          ),
      ],
    );
  }
}