
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phoneapp/constants/color_constants.dart';
import 'package:phoneapp/constants/text_constants.dart';
import 'package:phoneapp/screen/Contacts/model/contact_history_model.dart';
import 'package:phoneapp/screen/Contacts/provider/contact_provider.dart';
import 'package:phoneapp/screen/Contacts/view/contacts_screen.dart';
import 'package:phoneapp/screen/Dial/provider/call_provider.dart';
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
    final favouriteProvider =
        Provider.of<FavouriteProvider>(context, listen: false);
    final contactProvider =
        Provider.of<ContactProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: ColorConstants.whiteColor,
      body: Column(
        children: [
          _customFavouriteAppBar(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: favouriteProvider.favouriteBox.listenable(),
              builder: (context, Box<ContactModel> box, _) {
                final favourites = box.values.toList();
                if (favourites.isEmpty) {
                  return Center(
                    child: Text(
                      TextConstants.nofavouritecontacts,
                      style: TextStyle(fontSize: 20.sp),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: favourites.length,
                  itemBuilder: (context, index) {
                    final fav = favourites[index];

                    return Slidable(
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) => makeCall(fav.name,0),
                            foregroundColor: ColorConstants.whiteColor,
                            backgroundColor: ColorConstants.greenColor,
                            icon: Icons.call,
                            label: TextConstants.call,
                          ),
                          SlidableAction(
                            onPressed: (_) {
                              favouriteProvider.deleteFavourite(fav);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(TextConstants.calldeleted),
                                ),
                              );
                            },
                            foregroundColor: ColorConstants.whiteColor,
                            backgroundColor: ColorConstants.lightred,
                            icon: Icons.delete,
                            label: TextConstants.delete,
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: (fav.profile == null || fav.profile!.isEmpty)
                            ? CircleAvatar(
                                radius: 30.r,
                                backgroundColor: ColorConstants.blue,
                                child: FittedBox(
                                  child: Text(
                                    fav.name.isNotEmpty
                                        ? fav.name[0].toUpperCase()
                                        : "?",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                radius: 30.r,
                                backgroundImage: MemoryImage(fav.profile!),
                              ),
                        title: Text(
                          fav.name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          fav.number,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: ColorConstants.greyColor,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
          shape: const CircleBorder(),
          backgroundColor: Colors.transparent,
          onPressed: () {
            if (contactProvider.contactBox.values.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ContactScreen(showCheckbox: true),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(TextConstants.nocontacts)),
              );
            }
          },
          child: const Icon(Icons.star, color: ColorConstants.whiteColor),
        ),
      ),
    );
  }

  Widget _customFavouriteAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: 45.h,
        bottom: 15.h,
        left: 15.w,
        right: 15.w,
      ),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorConstants.blue, ColorConstants.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Text(
            TextConstants.favourites,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26.sp,
              color: ColorConstants.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> makeCall(String number, int simSlot) async {
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
      if (!status.isGranted) return;
    }
    final intent = AndroidIntent(
      action: 'android.intent.action.CALL',
      data: 'tel:$number',
      arguments: {"com.android.phone.extra.slot": simSlot},
    );
    await intent.launch();

    if (!mounted) return;
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    callProvider.addCall(number, simSlot, 0,"outgoing");
  }
}
