import 'package:concentric_transition/concentric_transition.dart';
import 'package:flutter/material.dart';
import 'package:therapylink/utils/colors.dart';
import 'package:therapylink/welcomepage.dart';

final pages = [
  const PageData(
    title: "Welcome to TherapyLink",
    imagePath: 'assets/therapylink_logo.png', // Your logo image
    bgColor: AppColors.backgroundGradientStart,
    textColor: Colors.white,
  ),
  const PageData(
    title: "Your Mental Health Companion",
    imagePath: 'assets/therapylink_logo.png', // Your logo image
    bgColor: AppColors.bgpurple,
    textColor: Colors.white,
  ),
  const PageData(
    title: "Let's Get Started",
    imagePath: 'assets/therapylink_logo.png', // Your logo image
    bgColor: AppColors.backgroundGradientEnd,
    textColor: Colors.white,
  ),
];

class ConcentricAnimationOnboarding extends StatelessWidget {
  const ConcentricAnimationOnboarding({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: ConcentricPageView(
        colors: pages.map((p) => p.bgColor).toList(),
        radius: screenWidth * 0.1,
        nextButtonBuilder: (context) => Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Icon(
            Icons.navigate_next,
            size: screenWidth * 0.08,
            color: Colors.white,
          ),
        ),
        itemCount: pages.length, // Enable to disable infinite scroll
        onFinish: () {
          // Navigate to welcome page when finished
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Welcomepage()),
          );
        },
        itemBuilder: (index) {
          final page = pages[index % pages.length];
          return SafeArea(
            child: _Page(page: page, isLastPage: index == pages.length - 1),
          );
        },
      ),
    );
  }
}

class PageData {
  final String? title;
  final String? imagePath;
  final Color bgColor;
  final Color textColor;

  const PageData({
    this.title,
    this.imagePath,
    this.bgColor = Colors.white,
    this.textColor = Colors.black,
  });
}

class _Page extends StatelessWidget {
  final PageData page;
  final bool isLastPage;

  const _Page({required this.page, this.isLastPage = false});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      decoration: isLastPage
          ? const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.backgroundGradientStart,
                  AppColors.backgroundGradientEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            )
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Image.asset(
            'assets/therapyjusttext.png',
            height: screenHeight * 0.1,
          ),
          const SizedBox(height: 32),
          // Icon
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.textColor.withOpacity(0.2),
            ),
            child: Image.asset(
              page.imagePath ?? 'assets/therapylink_logo.png',
              height: screenHeight * 0.15,
              width: screenHeight * 0.15,
              fit: BoxFit.contain,
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              page.title ?? "",
              style: TextStyle(
                color: page.textColor,
                fontSize: screenHeight * 0.035,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (isLastPage) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Welcomepage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  color: AppColors.bgpurple,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
