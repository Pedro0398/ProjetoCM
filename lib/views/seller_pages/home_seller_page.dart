import 'package:flutter/material.dart';

class HomeSellerPage extends StatelessWidget {
  const HomeSellerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text(
          'Bem-vindo, vendedor!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
