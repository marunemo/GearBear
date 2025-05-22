import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class SubjectSegmentationPage extends StatefulWidget {
  const SubjectSegmentationPage({Key? key}) : super(key: key);

  @override
  _SubjectSegmentationPageState createState() => _SubjectSegmentationPageState();
}

class _SubjectSegmentationPageState extends State<SubjectSegmentationPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _selectedMode = 1; // 0: Video, 1: Photo, 2: Portrait

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // TODO: 실제 카메라 초기화 로직 구현
    // 임시 구현
    setState(() {
      // 실제 앱에서는 availableCameras()를 사용하여 카메라 목록을 가져옴
      _initializeControllerFuture = Future.delayed(const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    // TODO: 카메라 컨트롤러 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 카메라 미리보기 또는 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/sleeping_pad.jpg',
              fit: BoxFit.cover,
            ),
          ),
          
          // 상단 프로필 아이콘
          Positioned(
            top: 40,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
          
          // 하단 컨트롤
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              color: Colors.black.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModeButton('VIDEO', 0),
                  _buildCameraButton(),
                  _buildModeButton('PORTRAIT', 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModeButton(String label, int mode) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCameraButton() {
    return GestureDetector(
      onTap: () {
        // TODO: 사진 촬영 로직
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
