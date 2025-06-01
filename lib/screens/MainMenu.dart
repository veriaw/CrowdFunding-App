import 'package:flutter/material.dart';
import 'package:project_tpm/models/user.dart';
import 'package:project_tpm/shared/color_palette.dart';

class MainMenu extends StatefulWidget {
  final User? user;
  const MainMenu({super.key, required this.user});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Main Menu"),
          backgroundColor: secondaryColor,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: secondaryColor,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined,),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.book),
            label: 'Bookmark',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_pin),
            label: 'User Profile',
          ),
        ],
      ),
      body: <Widget>[
        // index 0
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Welcome to Main Menu"),
                Text("Selamat Datang Peserta ${widget.user?.id}"),
              ],
            )
          ],
        ),

        // index 1
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Welcome to Page of Something")
              ],
            )
          ],
        ),

        // index 2
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Welcome to User Profile")
              ],
            )
          ],
        )
      ][currentPageIndex],

    );
  }
}