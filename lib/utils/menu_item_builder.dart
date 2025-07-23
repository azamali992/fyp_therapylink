import 'package:flutter/material.dart';

Widget buildMenuItem({
  required IconData icon,
  required String label,
  required String subLabel,
  required BuildContext context,
  required double height,
  required double width,
  required double baseFontSize,
  required Map<String, Color> buttonColors,
  required Map<String, bool> isClicked,
  required Function(String) handleMenuItemTap,
}) {
  return Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(30.0),
    child: InkWell(
      onTap: () {
        handleMenuItemTap(label);
      },
      onTapDown: (_) {
        isClicked[label] = true;
      },
      onTapUp: (_) {
        isClicked[label] = false;
      },
      onTapCancel: () {
        isClicked[label] = false;
      },
      borderRadius: BorderRadius.circular(30.0),
      splashColor: Colors.white.withOpacity(0.2),
      highlightColor: Colors.white.withOpacity(0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: height,
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isClicked[label]!
                  ? buttonColors[label]!.withOpacity(0.4)
                  : buttonColors[label]!.withOpacity(0.5),
              isClicked[label]!
                  ? buttonColors[label]!.withOpacity(0.6)
                  : buttonColors[label]!.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: buttonColors[label]!.withOpacity(0.3),
              spreadRadius: isClicked[label]! ? 1 : 2,
              blurRadius: isClicked[label]! ? 10 : 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30.0),
          child: Stack(
            children: [
              // Background design elements
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 26.0,
                        color: Colors.white,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: baseFontSize * 0.9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                blurRadius: 3.0,
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          subLabel,
                          style: TextStyle(
                            fontSize: baseFontSize * 0.65,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Overlay effect when pressed
              if (isClicked[label]!)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}