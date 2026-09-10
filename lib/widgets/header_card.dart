import 'package:flutter/material.dart';
import 'package:multitracks/config/app_theme.dart';

class HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 30,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: Center(
        child: Text(
          'REPRODUCTOR MULTITRACK',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
