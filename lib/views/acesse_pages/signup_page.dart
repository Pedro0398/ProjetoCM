import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/data_class/auth_service.dart';
// Assumindo que estes são os seus widgets personalizados.
// Certifique-se que os caminhos estão corretos.
import 'package:flutter_application_1/views/widget_tree.dart';
import 'package:flutter_application_1/views/widget_tree_seller.dart';
import 'package:flutter_application_1/views/widgets/hero_widget.dart';

// Importações para o AuthService e, opcionalmente, a classe Utilizador
// Ajuste os caminhos conforme a sua estrutura de projeto.
// import 'package:flutter_application_1/data_class/user.dart'; // Se precisar de referenciar o tipo Utilizador explicitamente

// Enum para os tipos de utilizador, como usado anteriormente
enum TipoUtilizadorOpcao { comprador, vendedor }

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthService _authService =
      AuthService(); // Instância do seu AuthService
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  TipoUtilizadorOpcao _tipoUtilizadorSelecionado =
      TipoUtilizadorOpcao.comprador;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitForm() async {
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
      String tipoUtilizadorStr =
          _tipoUtilizadorSelecionado == TipoUtilizadorOpcao.comprador
              ? "Comprador"
              : "Vendedor"; // Ajuste o rótulo "Vendedor" se "Consumidor" for diferente

      await _authService.registerWithEmailAndPassword(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        tipoUtilizador: tipoUtilizadorStr,
      );

      if (mounted) {
        // Após registo bem-sucedido, pode navegar para WidgetTree
        // ou para uma página de login para o utilizador entrar.
        // Se o WidgetTree já lida com o estado de autenticação, isto pode ser adequado.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registo bem-sucedido! A redirecionar...'),
            backgroundColor: Colors.green,
          ),
        );
        if (tipoUtilizadorStr == "Comprador") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WidgetTree(),
            ), // Navegação original do seu botão
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WidgetTreeSeller(),
            ), // Navegação original do seu botão
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "Ocorreu um erro de autenticação.";
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Ocorreu um erro inesperado. Tente novamente.";
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
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A sua AppBar personalizada
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150), // Define a altura da AppBar
        child: AppBar(
          backgroundColor: Colors.transparent, // Torna o fundo transparente
          elevation: 0, // Remove a sombra da AppBar
          flexibleSpace: HeroWidget(), // O seu HeroWidget
          leading:
              ModalRoute.of(context)?.canPop == true
                  ? BackButton(color: Theme.of(context).colorScheme.onSurface)
                  : null,
        ),
      ),
      // O corpo da página com a imagem e o formulário
      body: Center(
        child: SingleChildScrollView(
          // Adicionado para evitar overflow com o teclado
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A sua imagem

              // Título do Formulário
              Text(
                'Crie a sua Conta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Formulário de Registo
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _nomeController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Nome Completo',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira o seu nome.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira uma senha.';
                        }
                        if (value.length < 6) {
                          return 'A senha deve ter pelo menos 6 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Senha',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, confirme a sua senha.';
                        }
                        if (value != _passwordController.text) {
                          return 'As senhas não coincidem.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Registar como:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Theme(
                      // Para que os RadioListTile usem o tema corretamente
                      data: Theme.of(context).copyWith(
                        unselectedWidgetColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      child: Column(
                        children: <Widget>[
                          RadioListTile<TipoUtilizadorOpcao>(
                            title: const Text('Comprador'),
                            value: TipoUtilizadorOpcao.comprador,
                            groupValue: _tipoUtilizadorSelecionado,
                            onChanged:
                                _isLoading
                                    ? null
                                    : (TipoUtilizadorOpcao? value) {
                                      setState(() {
                                        _tipoUtilizadorSelecionado = value!;
                                      });
                                    },
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                          RadioListTile<TipoUtilizadorOpcao>(
                            title: const Text(
                              'Vendedor',
                            ), // Ou o seu rótulo "Consumidor"
                            value: TipoUtilizadorOpcao.vendedor,
                            groupValue: _tipoUtilizadorSelecionado,
                            onChanged:
                                _isLoading
                                    ? null
                                    : (TipoUtilizadorOpcao? value) {
                                      setState(() {
                                        _tipoUtilizadorSelecionado = value!;
                                      });
                                    },
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
                          // Mantido o seu FilledButton
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _submitForm, // Chama o método de submissão
                          child: const Text(
                            "Criar Conta",
                          ), // Texto do botão alterado
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
