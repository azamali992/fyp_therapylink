import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ViewUserInsightsPage extends StatelessWidget {
  const ViewUserInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View User Insights'),
        backgroundColor: AppColors.bgpurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Emotional Trends and Sentiment Analysis',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aggregated Reports for Users (with consent)',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount:
                      5, // Replace with the actual number of user reports
                  itemBuilder: (context, index) {
                    return Card(
                      color: Colors.white.withOpacity(0.8),
                      child: ListTile(
                        title: Text('User Report ${index + 1}'),
                        subtitle:
                            Text('Details about user report ${index + 1}'),
                        onTap: () {
                          // Handle card tap
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
