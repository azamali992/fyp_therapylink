import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:therapylink/Views/mainMenu.dart';
import 'package:therapylink/Views/moodanalysis.dart';
import 'package:therapylink/Views/profilepage.dart';
import 'package:therapylink/Views/settings.dart';
import 'package:therapylink/utils/colors.dart';
import 'home_page.dart'; // Import the ChatBot

class GoogleBottomBar extends StatefulWidget {
  const GoogleBottomBar({super.key});

  @override
  State<GoogleBottomBar> createState() => _GoogleBottomBarState();
}

class _GoogleBottomBarState extends State<GoogleBottomBar>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Widget> _pages = [
    const ChatBot(),
    const MainMenu(),
    const ProfilePage(),
    const SettingsPage(),
    const MoodAnalysisPage()
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_selectedIndex),
                  child: _pages[_selectedIndex], // Display the selected page
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.backgroundGradientStart,
              Color.fromARGB(255, 55, 13, 104),
              AppColors.backgroundGradientEnd,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: SalomonBottomBar(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.6),
            itemShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            itemPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            curve: Curves.easeOutCubic,
            duration: const Duration(milliseconds: 600),
            onTap: (index) {
              if (_selectedIndex != index) {
                _animationController.reset();
                _animationController.forward();
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
            items: _navBarItems,
          ),
        ),
      ),
    );
  }
}

final _navBarItems = [
  SalomonBottomBarItem(
    icon: const Icon(Icons.chat_bubble_rounded),
    title: const Text(
      "Chatbot",
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    selectedColor: const Color(0xFFA36FFF), // Light purple
    activeIcon: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.chat_bubble_rounded),
    ),
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.home_rounded),
    title: const Text(
      "Home",
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    selectedColor: const Color(0xFF8A4FFF), // Medium purple
    activeIcon: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.home_rounded),
    ),
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.person_rounded),
    title: const Text(
      "Profile",
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    selectedColor: const Color(0xFF6E29FF), // Deep purple
    activeIcon: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.person_rounded),
    ),
  ),
];