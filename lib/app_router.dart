// Ficheiro: lib/views/app_router.dart (ou o caminho que escolheu)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/data_class/auth_service.dart';

import 'package:flutter_application_1/data_class/user.dart' as app_user;
import 'package:flutter_application_1/views/acesse_pages/signup_page.dart';
import 'package:flutter_application_1/views/acesse_pages/welcome_page.dart';
import 'package:flutter_application_1/views/widget_tree.dart';
import 'package:flutter_application_1/views/widget_tree_seller.dart';

// Exemplo de como poderia importar as suas páginas existentes:
// import 'package:flutter_application_1/views/widget_tree.dart'; // A sua WidgetTree para compradores
// import 'package:flutter_application_1/views/widget_tree_seller.dart'; // A sua WidgetTreeSeller
// import 'package:flutter_application_1/views/pages/signup_page.dart'; // A sua SignupPage ou LoginPage

// ----- PLACEHOLDERS PARA AS PÁGINAS (SUBSTITUA PELAS SUAS PÁGINAS REAIS) -----
// Se já tem estas páginas, apague estes placeholders e importe as suas.

// Página para utilizadores NÃO logados (ex: sua SignupPage ou LoginPage)

// ----- FIM DOS PLACEHOLDERS -----

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        // Enquanto espera pela informação de autenticação
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se o utilizador ESTÁ autenticado no Firebase Auth
        if (authSnapshot.hasData && authSnapshot.data != null) {
          final firebaseUser = authSnapshot.data!;

          // Agora, buscar os dados do utilizador (incluindo tipoUtilizador) do Firestore
          return FutureBuilder<app_user.Utilizador?>(
            key: ValueKey(
              firebaseUser.uid,
            ), // Garante que refaz a busca se o user mudar
            future: authService.getUserData(firebaseUser.uid),
            builder: (context, userSnapshot) {
              // Enquanto espera pelos dados do utilizador do Firestore
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  ),
                );
              }

              // Se houve erro ao buscar os dados do utilizador
              if (userSnapshot.hasError) {
                // Pode fazer logout para evitar estado inconsistente ou mostrar página de erro
                // Future.microtask(() => authService.signOut());
                return const SignupPage(); // Volta para a autenticação
              }

              // Se temos os dados do utilizador e eles não são nulos
              if (userSnapshot.hasData && userSnapshot.data != null) {
                final appUser = userSnapshot.data!;

                // AQUI ESTÁ A LÓGICA DE DECISÃO
                if (appUser.tipoUtilizador == "Vendedor") {
                  return const WidgetTreeSeller(); // Exemplo: return const WidgetTreeSeller();
                } else {
                  return const WidgetTree(); // Exemplo: return const WidgetTree();
                }
              } else {
                // Autenticado no Firebase Auth, mas não encontrou dados no Firestore
                // ou o objeto Utilizador é nulo.
                // Pode fazer logout para evitar estado inconsistente
                // Future.microtask(() => authService.signOut());
                return const SignupPage(); // Volta para a autenticação
              }
            },
          );
        } else {
          // Utilizador NÃO está autenticado
          return const WelcomePage();
        }
      },
    );
  }
}
