import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/notifiers.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return NavigationBar(
          destinations: [
            NavigationDestination(icon: Icon(Icons.home), label: "Inicio"),
            NavigationDestination(icon: Icon(Icons.explore), label: "Explorar"),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart),
              label: "Carrinho",
            ),
            NavigationDestination(icon: Icon(Icons.person), label: "Conta"),
          ],
          onDestinationSelected: (value) {
            selectedPageNotifier.value = value;
          },
          selectedIndex: selectedPage,
          indicatorColor: Colors.green,
        );
      },
    );
  }
}
