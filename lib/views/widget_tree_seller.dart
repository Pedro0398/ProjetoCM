import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/notifiers.dart';
import 'package:flutter_application_1/views/seller_pages/home_seller_page.dart';
import 'package:flutter_application_1/views/common_pages/profile_page.dart';
import 'package:flutter_application_1/views/common_pages/settings_page.dart';
import 'package:flutter_application_1/views/seller_pages/sales_page.dart';
import 'package:flutter_application_1/views/seller_pages/stock_page.dart';
import 'package:flutter_application_1/views/widgets/navbar_seller_widget.dart';

List<Widget> pages = [
  HomeSellerPage(),
  SalesPage(),
  StockPage(),
  ProfilePage(),
];

class WidgetTreeSeller extends StatefulWidget {
  const WidgetTreeSeller({super.key});

  @override
  State<WidgetTreeSeller> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTreeSeller> {
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
      bottomNavigationBar: NavBarSeller(),
      body: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return pages.elementAt(selectedPage);
        },
      ),
    );
  }
}
