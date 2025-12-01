import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phoneapp/constants/color_constants.dart';
import 'package:phoneapp/constants/text_constants.dart';
import 'package:phoneapp/screen/Contacts/model/contacts_model.dart';
import 'package:phoneapp/screen/Contacts/provider/contact_provider.dart';
import 'package:phoneapp/screen/Contacts/view/contacts_screen.dart';
import 'package:phoneapp/screen/Favourites/provider/favourite_provider.dart';
import 'package:provider/provider.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  @override
  Widget build(BuildContext context) {
  
    final provider = Provider.of<FavouriteProvider>(context, listen: false);
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: ColorConstants.whiteColor,
      appBar: AppBar(
           backgroundColor: ColorConstants.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [ColorConstants.blue, ColorConstants.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
         TextConstants.favourites,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28.sp,color: ColorConstants.whiteColor),
        ),
        
       
      ),
      body: ValueListenableBuilder(
        valueListenable: provider.favouriteBox.listenable(),
        builder: (context, Box<ContactModel> box, _) {
          final favourites = box.values.toList();
          if (favourites.isEmpty) {
            return const Center(child: Text(TextConstants.noContactFount));
          }

          return ListView.builder(
            itemCount: box.values.length,
            itemBuilder: (context, index) {
              final fav = favourites[index];

              return Slidable(
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),

                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        makeCall(fav);
                      },

                      foregroundColor: ColorConstants.whiteColor,
                      backgroundColor: ColorConstants.greenColor,
                      icon: Icons.call,
                    ),
                    SlidableAction(
                      onPressed: (context) {
                        provider.deleteFavourite(fav);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(TextConstants.calldeleted)),
                        );
                      },

                      foregroundColor: ColorConstants.whiteColor,
                      backgroundColor: ColorConstants.lightred,
                      icon: Icons.delete,
                    ),
                  ],
                ),

                child: ListTile(
                  leading: fav.profile.isEmpty
                      ? CircleAvatar(
                          backgroundColor: Colors.blue.shade700,
                          child: Text(
                            fav.name.isNotEmpty
                                ? fav.name[0].toUpperCase()
                                : "?",
                            style:  TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : CircleAvatar(
                          backgroundImage: fav.profile.startsWith("/")
                              ? FileImage(File(fav.profile))
                              : AssetImage(fav.profile) as ImageProvider,
                        ),

                  title: Text(fav.name),
                  subtitle: Text(fav.number),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Container(
         decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [ColorConstants.blue, ColorConstants.purple],   
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        child: FloatingActionButton(
          shape: CircleBorder(),
          backgroundColor: ColorConstants.transparent,
          onPressed: () {
            if(contactProvider.contactBox.values.isNotEmpty){
               Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ContactScreen(showCheckbox: true),
              ),
            );
        
            }else{
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(TextConstants.nocontacts)));
            }
           
          },
          child: Icon(Icons.star, color: ColorConstants.whiteColor),
        ),
      ),
    );
  }

  void makeCall(ContactModel contact) async {
    if (contact.number.isEmpty) return;

    try {
      await FlutterPhoneDirectCaller.callNumber(contact.number);
      if (!mounted) return;


      // ignore: empty_catches
    } catch (e) {}
  }
}
