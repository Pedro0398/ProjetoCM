import 'package:flutter/material.dart';
import 'package:flutter_application_1/data_class/auth_service.dart';
import 'package:flutter_application_1/views/acesse_pages/welcome_page.dart';

AuthService authService = AuthService();

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: FilledButton(
            onPressed: () {
              authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => WelcomePage()),
              );
            },
            style: FilledButton.styleFrom(minimumSize: Size(400, 40.0)),
            child: Text("Logout"),
          ),
        ),
      ],
    );
  }
}
