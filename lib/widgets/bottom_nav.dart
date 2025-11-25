// lib/widgets/bottom_nav.dart
import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int index;
  final Map<String, dynamic>? args;

  const BottomNav({
    super.key,
    required this.index,
    this.args,
  });

  @override
  Widget build(BuildContext context) {
    // garante que sempre exista um mapa utilizável
    final data = {
      "employeeName": args?["employeeName"] ?? "",
      "profileImageUrl": args?["profileImageUrl"] ?? "",
    };

    return BottomNavigationBar(
      currentIndex: index,
      onTap: (i) {
        if (i == index) return;

        switch (i) {
          case 0:
            Navigator.pushReplacementNamed(context, "/history", arguments: data);
            break;

          case 1:
            Navigator.pushReplacementNamed(context, "/home", arguments: data);
            break;

          case 2:
            Navigator.pushReplacementNamed(context, "/profile", arguments: data);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.menu), label: ""),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
      ],
    );
  }
}
