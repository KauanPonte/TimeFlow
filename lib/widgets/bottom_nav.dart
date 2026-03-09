// lib/widgets/bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';

class BottomNav extends StatelessWidget {
  final int index;
  final Map<String, dynamic>? args;
  final bool isAdmin;

  const BottomNav({
    super.key,
    required this.index,
    this.args,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final data = {
      "employeeName": args?["employeeName"] ?? "",
      "profileImageUrl": args?["profileImageUrl"] ?? "",
      "employeeRole": args?["employeeRole"] ?? "",
    };

    if (isAdmin) {
      return BottomNavigationBar(
        currentIndex: index,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.surface,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          if (i == index) return;
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, "/home", arguments: data);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, "/home/employee",
                  arguments: data);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, "/profile",
                  arguments: data);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Painel",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined),
            activeIcon: Icon(Icons.access_time),
            label: "Meu Ponto",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      );
    }

    // Nav padrão para usuários normais (2 abas)
    return BottomNavigationBar(
      currentIndex: index,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: AppColors.surface,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        if (i == index) return;
        switch (i) {
          case 0:
            Navigator.pushReplacementNamed(context, "/home", arguments: data);
            break;
          case 1:
            Navigator.pushReplacementNamed(context, "/profile",
                arguments: data);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: "Perfil",
        ),
      ],
    );
  }
}
