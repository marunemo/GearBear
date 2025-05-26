import 'package:flutter/material.dart';

import 'login.dart';
import 'menu.dart';
import 'packSet.dart';
import 'stat.dart';
import 'gearList.dart';
import 'addGear.dart';
import 'subjectSegment.dart';
import 'profile.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GearBear',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/menu': (context) => const MenuPage(),
        '/pack_setting': (context) => const PackSettingPage(),
        '/statistics': (context) => const StatisticsPage(),
        '/': (context) => const GearListPage(),
        '/add_gear': (context) => const AddGearPage(),
        '/subject_segmentation': (context) => const SubjectSegmentationPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
