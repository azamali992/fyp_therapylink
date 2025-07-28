import 'package:flutter/material.dart';
import 'package:therapylink/utils/colors.dart';
import 'test_page.dart';

class PsychologicalTestPage extends StatelessWidget {
  const PsychologicalTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> tests = [
      {
        "name": "Beck Depression Inventory (BDI-II)",
        "icon": Icons.sentiment_very_dissatisfied,
        "color": Colors.redAccent,
      },
      {
        "name": "GAD-7 Anxiety Test",
        "icon": Icons.psychology_alt,
        "color": Colors.deepPurpleAccent,
      },
      {
        "name": "Perceived Stress Scale (PSS-10)",
        "icon": Icons.spa,
        "color": AppColors.successGreen,
      },
      {
        "name": "Rosenberg Self-Esteem Scale",
        "icon": Icons.star,
        "color": Colors.blueAccent,
      },
      {
        "name": "Connor-Davidson Resilience Scale",
        "icon": Icons.security,
        "color": AppColors.bgreen,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Psychological Tests", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: AppColors.bgpurple,
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
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: tests.length,
          itemBuilder: (context, index) {
            final test = tests[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestPage(testName: test["name"]),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      test["color"].withOpacity(0.8),
                      test["color"].withOpacity(0.5)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(test["icon"], color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      test["name"],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
