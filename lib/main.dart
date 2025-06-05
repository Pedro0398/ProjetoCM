import 'package:flutter/material.dart';
// Remova a importação direta de WelcomePage se o AppRouter for lidar com isso
// import 'package:flutter_application_1/views/acesse_pages/welcome_page.dart';

// Importações necessárias para o Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/views/acesse_pages/splashScreen.dart';
import 'firebase_options.dart'; // Importe o ficheiro gerado pelo flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    const MyApp(),
  ); // Alterado para const se MyApp não precisar de chaves variáveis
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      // Especificar o tipo para o ValueListenableBuilder
      valueListenable: darkModeNotifier,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
            // Pode adicionar mais configurações de tema aqui se necessário
          ),
          // AQUI ESTÁ A ALTERAÇÃO PRINCIPAL:
          // O AppRouter agora é o ponto de entrada que decidirá qual página mostrar.
          home: const SplashScreen(), // Usa o AppRouter como ponto de entrada
        );
      },
    );
  }
}

// Correção: declaração com tipo bool
ValueNotifier<bool> darkModeNotifier = ValueNotifier<bool>(false);
