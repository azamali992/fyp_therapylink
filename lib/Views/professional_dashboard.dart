import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../utils/colors.dart';
import '../auth.dart';
import 'login.dart';
import '../utils/menu_item_builder.dart';
import 'view_user_insights.dart'; // Add this import

class ProfessionalDashboard extends StatelessWidget {
  const ProfessionalDashboard({super.key});

  final Map<String, Color> _buttonColors = const {
    'View User Insights': Colors.black,
    'Access Professional Resources': Colors.red,
    'Collaborate with System': Colors.orange,
    'Patient Management': Colors.green,
  };

  final Map<String, bool> _isClicked = const {
    'View User Insights': false,
    'Access Professional Resources': false,
    'Collaborate with System': false,
    'Patient Management': false,
  };

  void _handleMenuItemTap(BuildContext context, String label) {
    switch (label) {
      case 'View User Insights':
      case 'Patient Management':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ViewUserInsightsPage()),
        );
        break;
      // Handle other cases here
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double baseFontSize =
        screenWidth * 0.05; // Adjust this value as needed

    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Dashboard',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.bgpurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
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
          child: StaggeredGridView.countBuilder(
            crossAxisCount: 4,
            mainAxisSpacing: 32.0,
            crossAxisSpacing: 20.0,
            itemCount: 4,
            itemBuilder: (BuildContext context, int index) {
              String label;
              IconData icon;
              String subLabel;
              switch (index) {
                case 0:
                  label = 'View User Insights';
                  icon = Icons.insights;
                  subLabel =
                      'Emotional Trends and Sentiment Analysis\nAggregated Reports for Users (with consent)';
                  break;
                case 1:
                  label = 'Patient Management';
                  icon = Icons.people;
                  subLabel =
                      'View patient profiles, chat summaries and appointment history';
                  break;
                case 2:
                  label = 'Access Professional Resources';
                  icon = Icons.book;
                  subLabel =
                      'Specialized Counseling Techniques\nCase Study Integration';
                  break;
                case 3:
                  label = 'Collaborate with System';
                  icon = Icons.group;
                  subLabel =
                      'Use the app as a supplementary tool for therapy sessions.';
                  break;
                default:
                  return Container();
              }

              return buildMenuItem(
                icon: icon,
                label: label,
                subLabel: subLabel,
                context: context,
                height: 200.0,
                width: 150.0,
                baseFontSize: baseFontSize,
                buttonColors: _buttonColors,
                isClicked: _isClicked,
                handleMenuItemTap: (label) =>
                    _handleMenuItemTap(context, label),
              );
            },
            staggeredTileBuilder: (int index) {
              switch (index) {
                case 0:
                  return const StaggeredTile.count(4, 2);
                case 1:
                  return const StaggeredTile.count(4, 2);
                case 2:
                  return const StaggeredTile.count(4, 2);
                case 3:
                  return const StaggeredTile.count(4, 2);
                default:
                  return const StaggeredTile.count(1, 1);
              }
            },
          ),
        ),
      ),
    );
  }
}
