import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/notifiers.dart';
import 'package:flutter_application_1/views/costumer_pages/cart_page.dart';
import 'package:flutter_application_1/views/costumer_pages/explore_page.dart';
import 'package:flutter_application_1/views/costumer_pages/home_page.dart';
import 'package:flutter_application_1/views/common_pages/profile_page.dart';
import 'package:flutter_application_1/views/common_pages/settings_page.dart';
import 'package:flutter_application_1/views/widgets/navbar_widget.dart';

List<Widget> pages = [
  HomePage(title: ''),
  ExplorePage(),
  CartPage(),
  ProfilePage(),
];

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  void initState() {
    selectedPageNotifier.value = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Hello Farmer",
          style: TextStyle(
            color: const Color.fromARGB(255, 8, 116, 11),
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              darkModeNotifier.value = !darkModeNotifier.value;
            },
            icon: ValueListenableBuilder(
              valueListenable: darkModeNotifier,
              builder: (context, isDarkMode, child) {
                return Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: const Color.fromARGB(255, 8, 116, 11),
                );
              },
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            icon: Icon(
              Icons.settings,
              color: const Color.fromARGB(255, 8, 116, 11),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavBar(),
      body: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return pages.elementAt(selectedPage);
        },
      ),
    );
  }
}
