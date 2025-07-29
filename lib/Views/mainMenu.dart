import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/Views/maps/map 2.dart';
import 'package:therapylink/Views/moodanalysis.dart';
import 'package:therapylink/Views/psychologicaltest.dart';
import 'package:therapylink/Views/settings.dart';
import 'package:therapylink/Views/voicechat.dart';
import 'package:therapylink/bloc/chat_bloc.dart';
import 'package:therapylink/utils/colors.dart';
import 'package:therapylink/utils/menu_item_builder.dart';
import 'stress_relieving.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu>
    with SingleTickerProviderStateMixin {
  // More refined color palette
  final Map<String, Color> _buttonColors = {
    'Eve': const Color.fromARGB(255, 3, 43, 189), // Deep purple
    'Psychological Test': const Color.fromARGB(255, 188, 6, 6), // Deep blue
    'Mood Analysis': const Color.fromARGB(255, 207, 214, 4), // Teal
    'Stress Relief': const Color(0xFF7B1FA2), // Purple
    'Local Clinics': const Color.fromARGB(255, 3, 161, 14), // Indigo
  };

  final Map<String, bool> _isClicked = {
    'Eve': false,
    'Psychological Test': false,
    'Mood Analysis': false,
    'Stress Relief': false,
    'Local Clinics': false,
  };

  late AnimationController _animationController;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create staggered animations for menu items
    _itemAnimations = List.generate(
      5,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.1 * index,
            0.1 * index + 0.5,
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String? _selectedLabel;

  void _handleMenuItemTap(String label) {
    setState(() {
      _selectedLabel = label;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      switch (label) {
        case 'Eve':
          final chatBloc = context.read<ChatBloc?>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: chatBloc ??
                    ChatBloc(userId: FirebaseAuth.instance.currentUser!.uid),
                child: const VoiceChatPage(),
              ),
            ),
          );
          break;

        case 'Psychological Test':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PsychologicalTestPage()),
          );
          break;
        case 'Mood Analysis':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MoodAnalysisPage()),
          );
          break;
        case 'Stress Relief':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const StressRelievingPage()),
          );
          break;
        case 'Local Clinics':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapScreen()),
          );
          break;
        default:
          break;
      }
      setState(() {
        _selectedLabel = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double baseFontSize = screenWidth * 0.05;

    return Scaffold(
      appBar: CustomAppBar(
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              ),
            );
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundGradientStart,
              Color.fromARGB(255, 55, 13, 104),
              AppColors.backgroundGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with welcome text

              const SizedBox(height: 10),
              Expanded(
                child: StaggeredGridView.countBuilder(
                  physics: const BouncingScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 18.0,
                  crossAxisSpacing: 18.0,
                  itemCount: 5,
                  itemBuilder: (BuildContext context, int index) {
                    String label;
                    IconData icon;
                    String subLabel;

                    switch (index) {
                      case 0:
                        label = 'Eve';
                        icon = Icons.voice_chat;
                        subLabel = 'Your personal therapist';
                        break;
                      case 1:
                        label = 'Psychological Test';
                        icon = Icons.psychology;
                        subLabel = 'Psych Evaluations';
                        break;
                      case 2:
                        label = 'Mood Analysis';
                        icon = Icons.analytics;
                        subLabel = 'Analyze your mood';
                        break;
                      case 3:
                        label = 'Stress Relief';
                        icon = Icons.spa;
                        subLabel = 'Relieve your stress';
                        break;
                      case 4:
                        label = 'Local Clinics';
                        icon = Icons.location_on;
                        subLabel = 'Find nearby clinics';
                        break;
                      default:
                        return Container();
                    }

                    return FadeTransition(
                      opacity: _itemAnimations[index],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(_itemAnimations[index]),
                        child: buildMenuItem(
                          icon: icon,
                          label: label,
                          subLabel: subLabel,
                          context: context,
                          height: 150.0,
                          width: 150.0,
                          baseFontSize: baseFontSize,
                          buttonColors: _buttonColors,
                          isClicked: _isClicked,
                          handleMenuItemTap: _handleMenuItemTap,
                        ),
                      ),
                    );
                  },
                  staggeredTileBuilder: (int index) {
                    switch (index) {
                      case 0:
                        return const StaggeredTile.count(2, 3);
                      case 1:
                        return const StaggeredTile.count(2, 2);
                      case 2:
                        return const StaggeredTile.count(2, 3);
                      case 3:
                        return const StaggeredTile.count(2, 2);
                      case 4:
                        return const StaggeredTile.count(4, 2);
                      default:
                        return const StaggeredTile.count(1, 1);
                    }
                  },
                ),
              ),
              // Footer with version info
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.health_and_safety,
                      color: Colors.white.withOpacity(0.4),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "TherapyLink v1.0.0",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.4),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
