import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/notifiers.dart';
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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const SplashScreen(),
      );
      },
    );
  }
}
