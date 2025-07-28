import 'package:flutter/material.dart';
import 'package:therapylink/utils/colors.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgpurple,
      appBar: AppBar(
        backgroundColor: AppColors.bgpurple,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'About TherapyLink',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 26,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Opacity(
              opacity: 0.2,
              child: Lottie.asset(
                'assets/lottie/background_effect.json',
                width: 300,
                repeat: true,
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Lottie.asset('assets/lottie/about.json', height: 200),
              const SizedBox(height: 10),
              _buildAnimatedCard("\ud83d\udcf1 App Overview",
                  "TherapyLink is your smart mental wellness companion. Our Flutter-powered platform blends technology and empathy to connect users with mental health professionals and AI-powered self-care tools."),
              _buildAnimatedCard("\ud83c\udfaf Mission",
                  "To transform mental health support through intuitive technology, breaking stigmas and promoting emotional wellness across all communities."),
              _buildAnimatedCard("\ud83e\udde0 Key Features", null,
                  subContent: [
                    "\ud83e\udd16 AI-powered Chatbot for emotional support",
                    "\ud83d\udcca Real-time Sentiment Analysis",
                    "\ud83e\uddd8 Guided Mindfulness & Breathing Exercises",
                    "\ud83d\uddd2 Mood & Activity Tracker",
                    "\ud83d\udcd3 Personal Journaling",
                    "\ud83d\udd17 Connect with Certified Professionals",
                  ]),
              _buildResponsiveTimeline(),
              _buildDevelopersSection(),
              _buildAnimatedCard("\ud83c\udfeb University Info",
                  "University of Management and Technology (UMT), Lahore\nDepartment of Computer Science & IT\nFinal Year Project – 2025"),
              _buildAnimatedCard("\ud83d\udce7 Contact Us",
                  "We’d love to hear from you. Visit the Feedback section in Settings or email us at therapylink.support@umt.edu.pk."),
              _buildAnimatedCard("\ud83d\udd12 Data Privacy",
                  "Your trust is our priority. All user data is securely encrypted, stored on Firebase, and never shared."),
              _buildAnimatedCard("\ud83c\udf1f Our Vision",
                  "We aim to scale TherapyLink beyond UMT to serve communities globally through digital mental wellness tools."),
              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(String title, String? content,
      {List<String>? subContent}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SlideInUp(
        duration: const Duration(milliseconds: 600),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white24),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              if (content != null) ...[
                const SizedBox(height: 12),
                Text(content,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 16)),
              ],
              if (subContent != null)
                ...subContent.map((item) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text("• $item",
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontStyle: FontStyle.italic)),
                    ))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveTimeline() {
    final techStack = [
      {"icon": Icons.code, "label": "Flutter"},
      {"icon": Icons.cloud, "label": "Firebase"},
      {"icon": Icons.lock, "label": "Auth"},
      {"icon": Icons.sentiment_satisfied, "label": "Sentiment API"},
      {"icon": Icons.message, "label": "Chatbot"},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("\ud83d\udee0 Tech Stack Timeline",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 20,
            runSpacing: 16,
            children: techStack.map((item) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(item['icon'] as IconData,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(item['label'] as String,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 15)),
                ],
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildDevelopersSection() {
    final developers = [
      {
        "name": "Muhammad Zeeshan",
        "id": "F2021105032",
        "role": "Frontend Engineer",
        "dept": "BSCS",
        "image": "assets/images/dev1.png"
      },
      {
        "name": "Muhammad Rameez",
        "id": "F2021105064",
        "role": "AI & Logic Specialist",
        "dept": "BSIT",
        "image": "assets/images/dev2.png"
      },
      {
        "name": "Azam Afzal",
        "id": "F2021105146",
        "role": "Backend Integrator",
        "dept": "BSCS",
        "image": "assets/images/dev3.png"
      },
      {
        "name": "Ahmed Bhatti",
        "id": "F20211047",
        "role": "UI/UX & Deployment",
        "dept": "BSCS",
        "image": "assets/images/dev4.png"
      },
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FadeInUp(
        duration: const Duration(milliseconds: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("\ud83d\udc68\u200d\ud83d\udcbb Meet the Developers",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: developers.map((dev) {
                return Container(
                  width: 180,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.shade300,
                        Colors.deepPurple.shade600
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage(dev['image']!),
                        radius: 36,
                      ),
                      const SizedBox(height: 12),
                      Text(dev['name']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 6),
                      Text("ID: ${dev['id']}",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      Text(dev['dept']!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(dev['role']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
