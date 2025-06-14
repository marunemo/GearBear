import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async'; // Completer를 위해 필요

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
      imgUrl: '', // LLM imgUrl은 무시!
    );
  }

  SearchedItem copyWith({
    String? gearName,
    String? manufacturer,
    String? type,
    int? weight,
    String? imgUrl
  }) {
    return SearchedItem(
      gearName: gearName ?? this.gearName,
      manufacturer: manufacturer ?? this.manufacturer,
      type: type ?? this.type,
      weight: weight ?? this.weight,
      imgUrl: imgUrl ?? this.imgUrl
    );
  }
}

Future<Map<String, Object?>> fetchCampToolByGoogleSearch(String query) async {
  final apiKey = dotenv.env['GOOGLE_API_KEY'];
  final cx = dotenv.env['CUSTOM_SEARCH_ENGINE_ID'];
  final results = <Map<String, dynamic>>[];

  Future<void> fetchFromSite(String site) async {
    final url =
        'https://www.googleapis.com/customsearch/v1?key=$apiKey&cx=$cx&q=${Uri.encodeQueryComponent('$query site:$site')}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        results.addAll(
          items.take(10).map((item) => {
            'title': item['title'],
            'link': item['link'],
            'snippet': item['snippet'],
          }),
        );
      }
    }
  }

  await fetchFromSite('rei.com');
  await fetchFromSite('backcountry.com');

  return {
    'results': results.take(10).toList(), // 총 10개까지만 반환
  };
}

// 주어진 URL의 이미지를 Image.network가 로드할 수 있는지 테스트하는 헬퍼 함수
Future<bool> _isImageLoadable(String imageUrl) async {
  try {
    final response = await http.get(
      Uri.parse(imageUrl),
      headers: {
        'Range': 'bytes=0-1023', // 처음 1KB만 요청
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.88 Safari/537.36',
      },
    ).timeout(const Duration(seconds: 7));

    // 상태코드는 206 (Partial Content) 혹은 200일 수 있음
    if (response.statusCode == 200 || response.statusCode == 206) {
      final contentType = response.headers['content-type'] ?? '';

      // image/* 타입이면서 svg는 제외
      if (contentType.startsWith('image/') && !contentType.contains('svg')) {
        return true;
      }
    }

    return false;
  } catch (e) {
    return false;
  }
}

bool _isSupportedImageExtension(String url) {
  final lowerCaseUrl = url.toLowerCase();
  // Image.network가 일반적으로 지원하는 확장자
  return lowerCaseUrl.endsWith('.jpg') ||
         lowerCaseUrl.endsWith('.jpeg') ||
         lowerCaseUrl.endsWith('.png') ||
         lowerCaseUrl.endsWith('.gif') ||
         lowerCaseUrl.endsWith('.webp');
}

// Google Custom Search API의 'fileFormat' 정보 활용
// 예: "image/jpeg", "image/png", "image/gif", "image/svg+xml" 등
bool _isSupportedFileFormat(String? fileFormat) {
  if (fileFormat == null) return false;
  final lowerCaseFormat = fileFormat.toLowerCase();
  // SVG는 Image.network로 바로 로드되지 않으므로 제외하거나 별도 처리 필요
  return lowerCaseFormat.startsWith('image/') && !lowerCaseFormat.contains('svg');
}

Future<String?> gearNameImageSearch(SearchedItem item) async {
  final apiKey = dotenv.env['GOOGLE_API_KEY'];
  final cx = dotenv.env['CUSTOM_SEARCH_ENGINE_ID'];
  if (apiKey == null || cx == null) return null;

  Future<String?> searchFromSite(String site) async {
    final query = '${item.manufacturer} ${item.gearName} ${item.type} site:$site';
    final url = Uri.parse(
      'https://www.googleapis.com/customsearch/v1?key=$apiKey&cx=$cx&q=${Uri.encodeQueryComponent(query)}&searchType=image',
    );
    try {
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final items = data['items'] as List<dynamic>?;

        if (items != null && items.isNotEmpty) {
          for (var item in items) {
            final imageUrl = item['link'] as String?;
            final imageInfo = item['image'] as Map<String, dynamic>?;

            if (imageUrl != null && imageInfo != null) {
              return imageUrl;
            }
          }
        }
      }
    } catch (e) {
      print('Error during image search: $e');
    }
    print(url);
    return null;
  }

  // backcountry.com 우선 → rei.com 순서로 시도
  return await searchFromSite('backcountry.com') ?? await searchFromSite('rei.com');
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
      'Use your search tool to find real, currently available camping gear based ONLY on information from backcountry.com and rei.com. '
      'Primarily recommend products that are available on backcountry.com, and only recommend products from rei.com if suitable options are not available on backcountry.com. '
      'For each recommended product, also provide a direct image URL from backcountry.com or rei.com if available. '
      'The "type" of gear must be one of the following categories: ${_categories.join(', ')}. '
      'Provide the result as a JSON array where each object has "gearName", "manufacturer", "type", "weight" (in grams, integer), and imgUrl. '
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
    debugPrint(jsonString);

    if (jsonString.isEmpty) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    final List<Future<SearchedItem>> futures = jsonList.map((json) async {
      final item = SearchedItem.fromJson(json);
      String name = item.gearName;
      final manufacturer = RegExp.escape(item.manufacturer);
      final type = RegExp.escape(item.type);
      final imgUrl = await gearNameImageSearch(item);
      debugPrint(imgUrl);

      // 정규식 패턴 구성 및 앞뒤 공백 제거
      if (manufacturer.isNotEmpty) {
        name = name.replaceAll(
          RegExp(r'^\s*' + manufacturer + r'\s*', caseSensitive: false),
          '',
        );
      }
      if (type.isNotEmpty) {
        name = name.replaceAll(
          RegExp(r'\s*' + type + r'\s*$', caseSensitive: false),
          '',
        );
      }
      name = name.trim();

      // imgUrl은 오직 gearNameImageSearch에서 받아온 값만 사용
      return item.copyWith(gearName: name, imgUrl: imgUrl);
    }).toList();

    // 결과 리스트를 기다림
    final List<SearchedItem> results = await Future.wait(futures);
    return results;
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
                    trailing: FloatingActionButton(
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