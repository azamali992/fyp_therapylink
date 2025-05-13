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
    elevation: 40.0,
    borderRadius: BorderRadius.circular(25.0),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isClicked[label]!
                  ? buttonColors[label]!.withOpacity(0.3)
                  : buttonColors[label]!.withOpacity(0.7),
              isClicked[label]!
                  ? buttonColors[label]!.withOpacity(0.4)
                  : buttonColors[label]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isClicked[label]!
                ? Colors.white.withOpacity(0.3)
                : Colors.transparent,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: isClicked[label]!
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.2),
              spreadRadius: isClicked[label]! ? 1 : 2,
              blurRadius: isClicked[label]! ? 15 : 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: width * 0.4,
                height: height * 0.4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24.0, color: buttonColors[label]),
              ),
              const SizedBox(height: 8.0),
              Text(
                label,
                style: TextStyle(
                  fontSize: baseFontSize * 0.9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: baseFontSize * 0.7,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
