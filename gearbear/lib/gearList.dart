import 'package:flutter/material.dart';

class GearListPage extends StatefulWidget {
  const GearListPage({Key? key}) : super(key: key);

  @override
  State<GearListPage> createState() => _GearListPageState();
}

class _GearListPageState extends State<GearListPage> {
  bool _isDrawerOpen = false;

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              AppBar(
                title: const Text('Gear List'),
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: _toggleDrawer,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text('장비 목록 페이지입니다.'),
                ),
              ),
            ],
          ),

          // Floating drawer
          if (_isDrawerOpen)
            Positioned(
              top: 60,
              left: 10,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.95),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Gear List'),
                        onTap: () {
                          // TODO: Navigate to Home
                          _toggleDrawer();
                        },
                      ),
                      ListTile(
                        title: const Text('Add Gear'),
                        onTap: () {
                          Navigator.pushNamed(context, '/add_gear');
                          _toggleDrawer();
                        },
                      ),
                      ListTile(
                        title: const Text('My Camp'),
                        onTap: () {
                          // TODO: Navigate to Summarization
                          _toggleDrawer();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
