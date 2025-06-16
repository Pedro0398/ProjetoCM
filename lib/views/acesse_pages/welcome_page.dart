import 'package:flutter/material.dart';
import 'package:flutter_application_1/views/acesse_pages/login_page.dart';
import 'package:flutter_application_1/views/acesse_pages/signup_page.dart';
import 'package:flutter_application_1/views/widgets/hero_widget.dart';
import 'package:lottie/lottie.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150), // Define a altura da AppBar
        child: AppBar(
          backgroundColor: Colors.transparent, // Torna o fundo transparente
          elevation: 0, // Remove a sombra da AppBar
          flexibleSpace: const HeroWidget(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: SizedBox(
                  width: 400, // Espaço que a animação ocupa
                  height: 410, // Espaço que a animação ocupa
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Lottie.asset(
                      'assets/welcome.json',
                      fit: BoxFit
                          .cover, // Aumenta o tamanho da animação dentro do espaço
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 90),
              const FittedBox(
                child: Text(
                  "Bem-vindo ao MarketPlace da Agricultura",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 8, 116, 11),
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupPage()),
                    );
                  },
                  style: FilledButton.styleFrom(minimumSize: const Size(400, 40.0)),
                  child: const Text("Get Started"),
                ),
              ),
              const SizedBox(height: 5.0),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
