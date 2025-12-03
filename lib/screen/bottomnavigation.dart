import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
class _BottomnavigationScreenState extends State<BottomnavigationScreen> {
  int selctedTab = 0;
final pages = [DialScreen(),ContactScreen(),FavouriteScreen()];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: ColorConstants.blaclColor, offset: Offset(5, 4), blurRadius: 5),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: ColorConstants.whiteColor,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.call,size: 24.sp),
              label: TextConstants.dial,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_2,size: 24.sp),
              label: TextConstants.contacts,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite,size: 24.sp),
              label: TextConstants.favourites,
            ),
            
          ],
          currentIndex: selctedTab,
          selectedFontSize: 14.sp,
          unselectedFontSize: 12.sp,
          
          onTap: (int index) {
            setState(() {
              selctedTab = index;
            });
          },
          selectedItemColor: ColorConstants.blue,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold,fontSize: 14.sp),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.bold,fontSize: 12.sp),
        ),
      ),
      body: pages[selctedTab],
    );
  }
}
