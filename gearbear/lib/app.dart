import 'package:flutter/material.dart';

import 'login.dart';
import 'gearList.dart';
import 'addGear.dart';
import 'editGear.dart';
import 'myCamp.dart';
import 'stat.dart';
import 'gearDoctor.dart';
import 'campMap.dart';
import 'myChat.dart';

import 'models/gear_model.dart';
import 'models/camp_model.dart';

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
        '/': (context) => const GearListPage(),
        '/add_gear': (context) => const AddGearPage(),
        '/my_camp': (context) => const MyCampPage(),
        '/gear_doctor': (context) => const GearDoctorPage(),
        '/camp_map': (context) => CampMapPage(),
        '/my_chat': (context) => MyChatPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/edit_gear') {
          final gear = settings.arguments as Gear;
          return MaterialPageRoute(
            builder: (context) => EditGearPage(gear: gear),
          );
        }
        if (settings.name == '/stat') {
          final camp = settings.arguments as Camp;
          return MaterialPageRoute(
            builder: (context) => StatisticsPage(camp: camp),
          );
        }
        return null;
      },
    );
  }
}
