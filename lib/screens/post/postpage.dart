import 'package:flutter/material.dart';

/// Placeholder for the post tab in bottom navigation
/// This screen is shown when the post tab index is selected,
/// but we'll navigate to CreatePostScreen instead when the plus button is tapped
class Postpage extends StatelessWidget {
  const Postpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.photo_camera,
              size: 64,
              color: Color(0xFF3620B3),
            ),
            SizedBox(height: 16),
            Text(
              'Tap the + button to create a post',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}