import 'package:flutter/material.dart';
import 'package:flutter_application_1/data_class/auth_service.dart';
import 'package:flutter_application_1/views/common_pages/profile_page.dart';
import 'package:flutter_application_1/views/costumer_pages/cart_page.dart';
import 'package:flutter_application_1/data_class/user.dart' as app_user;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 1,
        centerTitle: true,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconWithLabel(
                        icon: Icons.person_outline,
                        label: 'Perfil',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(),
                            ),
                          );
                        },
                      ),
                      IconWithLabel(icon: Icons.lock_outline, label: 'Segurança'),
                      IconWithLabel(icon: Icons.notifications_none, label: 'Notificações'),
                      IconWithLabel(icon: Icons.language, label: 'Idioma'),
                    ],
                  ),
                ),
                ListTile(
                  tileColor: isDark ? Colors.green.shade900 : const Color(0xFFEFFAF2),
                  leading: const Icon(Icons.account_circle_outlined, color: Colors.green),
                  title: const Text('Configurações da Conta'),
                  subtitle: const Text('Gerencie suas informações pessoais'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text(
                    'Configurações',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ...[
                  {
                    'title': 'Informações Pessoais',
                    'icon': Icons.person_outline,
                    'onTap': () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(),
                        ),
                      );
                    }
                  },
                  {'title': 'Senha e Segurança', 'icon': Icons.lock_outline},
                  {'title': 'Preferências de Notificação', 'icon': Icons.notifications_outlined},
                  {'title': 'Catálogo de Endereços', 'icon': Icons.location_on_outlined},
                  {'title': 'Idioma e Região', 'icon': Icons.language},
                  {'title': 'Ajuda e Suporte', 'icon': Icons.help_outline},
                  {'title': 'Sobre Nós', 'icon': Icons.info_outline},
                ].map((item) {
                  return ListTile(
                    leading: Icon(item['icon'] as IconData),
                    title: Text(item['title'] as String),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: item['onTap'] as void Function()?,
                  );
                }),
              ],
            ),
    );
  }
}

class IconWithLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const IconWithLabel({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(icon, color: theme.iconTheme.color),
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
