import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _isPasswordVisible = false;
  bool _isRegistered = false;
  String? _savedName;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('user_name');
    final savedRole = prefs.getString('user_role');
    final savedPassword = prefs.getString('user_password');

    setState(() {
      _savedName = savedName;
      _isRegistered = savedPassword != null;
      if (savedName != null) _nameController.text = savedName;
      if (savedRole != null) _roleController.text = savedRole;
    });
  }

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final role = _roleController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || role.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos para continuar.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_role', role);
    await prefs.setString('user_password', password);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cadastro realizado com sucesso!')),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeNavigation(nomeFuncionario: name)),
    );
  }

  Future<void> _loginUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('user_password');
    final savedName = prefs.getString('user_name');
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite sua senha.')),
      );
      return;
    }

    if (password != savedPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha incorreta.')),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeNavigation(nomeFuncionario: savedName ?? 'Usuário')),
    );
  }

  Future<void> _logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _isRegistered = false;
      _passwordController.clear();
      _nameController.clear();
      _roleController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegistered ? 'Login' : 'Cadastro'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Icon(
              _isRegistered ? Icons.lock_outline : Icons.person_add_alt,
              size: 88,
              color: Colors.indigo,
            ),
            const SizedBox(height: 16),
            Text(
              _isRegistered
                  ? 'Olá ${_savedName ?? ''}, digite sua senha'
                  : 'Crie seu cadastro',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),

            // Campos de nome e cargo — só no primeiro cadastro
            if (!_isRegistered) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Cargo / Função',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Campo de senha (sempre aparece)
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: _isRegistered ? 'Senha' : 'Crie uma senha',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      if (_isRegistered) {
                        await _loginUser();
                      } else {
                        await _registerUser();
                      }
                      setState(() => _loading = false);
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isRegistered ? 'Entrar' : 'Cadastrar e Entrar'),
            ),

            const SizedBox(height: 12),

            if (_isRegistered)
              TextButton(
                onPressed: _logoutUser,
                child: const Text('Esqueci minha senha / Refazer cadastro'),
              ),
          ],
        ),
      ),
    );
  }
}
