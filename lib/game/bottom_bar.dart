import 'package:flutter/material.dart';

class RectangleComponenet extends StatelessWidget {
  const RectangleComponenet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 100,
      color: Colors.blue, // Change color as needed
      alignment: Alignment.center,
      child: Text(
        'This is a rectangle',
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
