import 'package:flutter/material.dart';
import 'package:flutter_application_1/data_class/auth_service.dart';
import 'package:flutter_application_1/data_class/user.dart' as app_user;

class EditProfilePage extends StatefulWidget {
  final app_user.Utilizador userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.userData.nome);
  }

  Future<void> _salvarAlteracoes() async {
    if (_formKey.currentState!.validate()) {
      try {
        final uid = _authService.currentUser!.uid;

        await _authService.atualizarNome(
        uid: uid,
        novoNome: _nomeController.text.trim(),
        );


        await _authService.currentUser!.updateDisplayName(_nomeController.text.trim());

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Nome atualizado com sucesso!")),
        );

        // ignore: use_build_context_synchronously
        Navigator.pop(context, true); // volta e indica sucesso
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao atualizar o perfil.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) => value == null || value.isEmpty ? 'Digite seu nome' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _salvarAlteracoes,
                icon: const Icon(Icons.save),
                label: const Text("Salvar Alterações"),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
