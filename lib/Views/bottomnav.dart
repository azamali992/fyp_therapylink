import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/Views/mainMenu.dart';
import 'package:therapylink/Views/moodanalysis.dart';
import 'package:therapylink/Views/profilepage.dart';
import 'package:therapylink/Views/settings.dart';
import 'package:therapylink/utils/colors.dart';
import 'package:therapylink/utils/constants.dart';
import 'package:therapylink/welcomepage.dart';
import 'home_page.dart'; // Import the ChatBot

class GoogleBottomBar extends StatefulWidget {
  const GoogleBottomBar({super.key});

  @override
  State<GoogleBottomBar> createState() => _GoogleBottomBarState();
}

class _GoogleBottomBarState extends State<GoogleBottomBar> {
  int _selectedIndex = 1;

  final List<Widget> _pages = [
    const ChatBot(),
    const MainMenu(),
    const ProfilePage(
      name: 'azam',
      currentMood: 'Happy',
      moodLevels: {'Happy': 0.8},
    ),
    const SettingsPage(),
    const MoodAnalysisPage()
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            Expanded(
              child: _pages[_selectedIndex], // Display the selected page
            ),
          ],
        ),
      ),
      bottomNavigationBar: SalomonBottomBar(
        backgroundColor: AppColors.bgpurple,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xff757575),
        unselectedItemColor: const Color(0xff6200ee),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: _navBarItems,
      ),
    );
  }
}

final _navBarItems = [
  SalomonBottomBarItem(
    icon: const Icon(Icons.chat),
    title: const Text("Chatbot"),
    selectedColor: Colors.pink,
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.home),
    title: const Text("Home"),
    selectedColor: Colors.purple,
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.person),
    title: const Text("Profile"),
    selectedColor: Colors.teal,
  ),
];
