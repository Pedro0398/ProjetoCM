import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Para FirebaseAuthException
import 'package:flutter_application_1/app_router.dart';
import 'package:flutter_application_1/data_class/auth_service.dart';
import 'package:flutter_application_1/views/acesse_pages/signup_page.dart'; 


// Assumindo que estes são os seus widgets e serviços.
// Certifique-se que os caminhos estão corretos.
import 'package:flutter_application_1/views/widgets/hero_widget.dart';
// Não precisamos importar WidgetTree e WidgetTreeSeller aqui,
// pois o AppRouter tratará do direcionamento.

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores agora são membros da classe de estado
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    // Fecha o teclado se estiver aberto
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Se o login for bem-sucedido, o StreamBuilder no AppRouter
      // irá detetar a alteração e navegar para a página correta.
      // Então, podemos simplesmente fechar a página de login se ela foi "pushed".
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AppRouter(),
          ), // Ou MainAppRouter se usou esse nome
          (Route<dynamic> route) =>
              false, // Este predicado remove todas as rotas anteriores
        );
      }
      // Se a LoginPage for a raiz para utilizadores não autenticados (e não "pushed"),
      // o AppRouter irá reconstruir e mostrar a página correta automaticamente.
      // Não é necessário fazer push para WidgetTree/WidgetTreeSeller daqui.
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Nenhum utilizador encontrado para esse email.';
          break;
        case 'wrong-password':
          message = 'Senha incorreta fornecida para esse utilizador.';
          break;
        case 'invalid-email':
          message = 'O formato do email é inválido.';
          break;
        case 'user-disabled':
          message = 'Este utilizador foi desabilitado.';
          break;
        case 'invalid-credential':
          message = 'Credenciais inválidas. Verifique o email e a senha.';
          break;
        default:
          message = 'Ocorreu um erro de autenticação. Tente novamente.';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocorreu um erro inesperado. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150), // Define a altura da AppBar
        child: AppBar(
          backgroundColor: Colors.transparent, // Torna o fundo transparente
          elevation: 0, // Remove a sombra da AppBar
          flexibleSpace: HeroWidget(),
          // Adiciona um botão de voltar se esta página puder ser "popped"
          leading:
              ModalRoute.of(context)?.canPop == true
                  ? BackButton(color: Theme.of(context).colorScheme.onSurface)
                  : null,
        ),
      ),
      body: Center(
        // Adicionado Center para melhor alinhamento vertical em ecrãs maiores
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // Aumentado padding geral
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centraliza verticalmente
              crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch, // Estica os widgets horizontalmente
              children: [
                // Pode adicionar um título aqui se desejar
                Text(
                  'Bem-vindo de Volta!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: "Email", // Alterado de hintText para labelText
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        12.0,
                      ), // Bordas mais arredondadas
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira o seu email.';
                    }
                    if (!RegExp(
                      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
                    ).hasMatch(value.trim())) {
                      return 'Por favor, insira um email válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText:
                        "Password", // Alterado de hintText para labelText
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a sua password.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                      onPressed: _loginUser,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ), // Padding vertical
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Log In"),
                    ),
                const SizedBox(height: 20),
                // Opcional: Link para a página de registo
                TextButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                           Navigator.of(context).push(MaterialPageRoute(builder: (_) => SignupPage()));
                          },
                  child: Text(
                    'Não tem uma conta? Crie uma aqui!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
