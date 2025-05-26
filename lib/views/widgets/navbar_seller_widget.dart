import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/notifiers.dart';

class NavBarSeller extends StatelessWidget {
  const NavBarSeller({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return NavigationBar(
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.store_mall_directory),
              label: "Loja",
            ),
            NavigationDestination(icon: Icon(Icons.sell), label: "Vendas"),
            NavigationDestination(
              icon: Icon(Icons.inventory_outlined),
              label: "Stock",
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
