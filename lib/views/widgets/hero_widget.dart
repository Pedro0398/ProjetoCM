import 'package:flutter/material.dart';

class HeroWidget extends StatelessWidget {
  const HeroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'logo',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 20.0,
            left: 10.0,
            right: 10.0,
          ), // Espaçamento superior
          child: Container(
            margin: const EdgeInsets.only(
              top: 20,
            ), // Margem superior para espaçamento
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), // Bordas arredondadas
              color: Colors.white, // Cor de fundo do "cartão"
            ),
            padding: const EdgeInsets.all(0), // Espaçamento interno
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  8,
                  116,
                  11,
                ), // Define o fundo verde
                borderRadius: BorderRadius.circular(
                  20,
                ), // Aplica o mesmo arredondamento
              ),
              child: ClipRRect(
                child: SizedBox(
                  width: 600,
                  height: 600,
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
