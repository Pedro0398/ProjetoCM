import 'package:flutter/material.dart';
import 'package:flutter_application_1/data_class/auth_service.dart';
import 'package:flutter_application_1/data_class/user.dart' as app_user;
import 'package:flutter_application_1/views/acesse_pages/welcome_page.dart';
import 'package:flutter_application_1/views/common_pages/edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  app_user.Utilizador? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final data = await _authService.getUserData(currentUser.uid);
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    await _authService.signOut();
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const WelcomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userData == null) {
      return const Center(child: Text('Erro ao carregar dados do perfil.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profile_placeholder.png'),
            ),
            const SizedBox(height: 20),
            Text(_userData!.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(_userData!.email),
            const SizedBox(height: 5),
            Text('Usuário: ${_userData!.tipoUtilizador}'),
            const SizedBox(height: 10),
            Text('Saldo: € ${_userData!.saldo.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {  
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(userData: _userData!),
                  ),
                ).then((value) {
                  if (value == true) {
                    _loadUserData(); 
                  }
                });
              },
              icon: const Icon(Icons.edit),
              label: const Text("Editar Perfil"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
