import 'package:flutter/material.dart';
import 'package:phoneapp/constants/color_constants.dart';
import 'package:phoneapp/constants/text_constants.dart';
import 'package:phoneapp/screen/Contacts/view/contacts_screen.dart';
import 'package:phoneapp/screen/Dial/view/dial_screen.dart';
import 'package:phoneapp/screen/Favourites/view/favourites_screen.dart';



class BottomnavigationScreen extends StatefulWidget {
  const BottomnavigationScreen({super.key});

  @override
  State<BottomnavigationScreen> createState() => _BottomnavigationScreenState();
}

int selctedTab = 0;
final pages = [DialScreen(),ContactScreen(),FavouriteScreen()];

class _BottomnavigationScreenState extends State<BottomnavigationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black, offset: Offset(5, 4), blurRadius: 5),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: ColorConstants.whiteColor,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.call),
              label: TextConstants.dial,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_2),
              label: TextConstants.contacts,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: TextConstants.favourites,
            ),
          ],
          currentIndex: selctedTab,
          onTap: (int index) {
            setState(() {
              selctedTab = index;
            });
          },
          selectedItemColor: ColorConstants.blue,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: pages[selctedTab],
    );
  }
}
