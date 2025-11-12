import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/ponto_page.dart';
import 'pages/profile_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_password'); // verifica se há senha salva
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isRegistered(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final isRegistered = snapshot.data!;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "App de Ponto",
          theme: ThemeData(
            primarySwatch: Colors.indigo,
            scaffoldBackgroundColor: Colors.grey[100],
            fontFamily: 'Roboto',
          ),
          home: isRegistered ? const LoginPage() : const RegisterPage(),
        );
      },
    );
  }
}

// ---------------------------
// Tela principal com as abas
// ---------------------------
class HomeNavigation extends StatefulWidget {
  final String nomeFuncionario;

  const HomeNavigation({Key? key, required this.nomeFuncionario})
    : super(key: key);

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const PontoPage(),
      ProfilePage(nomeFuncionario: widget.nomeFuncionario),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Ponto',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
