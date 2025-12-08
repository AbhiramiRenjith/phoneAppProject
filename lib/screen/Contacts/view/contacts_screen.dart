import 'dart:io';
import 'dart:typed_data';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phoneapp/screen/Contacts/provider/contact_provider.dart';
import 'package:provider/provider.dart';
import 'package:phoneapp/constants/color_constants.dart';
import 'package:phoneapp/constants/text_constants.dart';
import 'package:phoneapp/screen/Contacts/model/contact_history_model.dart';
import 'package:phoneapp/screen/Contacts/view/create_contact.dart';
import 'package:phoneapp/screen/Dial/provider/call_provider.dart';
import 'package:phoneapp/screen/Favourites/provider/favourite_provider.dart';

class ContactScreen extends StatefulWidget {
  final bool showCheckbox;
  const ContactScreen({super.key, this.showCheckbox = false});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  bool allSelect = false;
  List<ContactModel> favContacts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<ContactProvider>(context, listen: false).loadDeviceContacts();
  }

  bool isFavourite(ContactModel contact) {
    final favBox = Hive.box<ContactModel>('favourites');
    return favBox.values.any((e) => e.number == contact.number);
  }

  Future<void> sendMessage(String number) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SENDTO',
      data: 'smsto:$number',
    );
    await intent.launch();
  }

  void _showDeleteDialog(BuildContext context, ContactModel contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(TextConstants.deleteContact),
        content: const Text(TextConstants.doyouwant),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(TextConstants.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final contactProvider = Provider.of<ContactProvider>(
                context,
                listen: false,
              );
              contactProvider.deleteContactFromDevice(contact);

              final favBox = Hive.box<ContactModel>('favourites');
              final favKey = favBox.values
                  .firstWhere(
                    (e) => e.number == contact.number,
                    orElse: () => ContactModel(
                      name: '',
                      number: '',
                      profile: Uint8List(0),
                    ),
                  )
                  .key;
              if (favKey != null) favBox.delete(favKey);

              setState(() {
                favContacts.remove(contact);
              });
            },
            child: const Text(
              TextConstants.delete,
              style: TextStyle(color: ColorConstants.lightred),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAvatar(ContactModel contact) {
    if (contact.profile != null && contact.profile!.isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          contact.profile!,
          width: 60.r,
          height: 60.r,
          fit: BoxFit.cover,
        ),
      );
    } else if (contact.profilePath != null &&
        File(contact.profilePath!).existsSync()) {
      return ClipOval(
        child: Image.file(
          File(contact.profilePath!),
          width: 60.r,
          height: 60.r,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return CircleAvatar(
        radius: 30.r,
        backgroundColor: ColorConstants.blue,
        child: Text(
          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : "?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  CircleAvatar buildContactAvatar(ContactModel contact, {double radius = 45}) {
    if (contact.profile != null && contact.profile!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(contact.profile!),
      );
    } else if (contact.profilePath != null &&
        File(contact.profilePath!).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(contact.profilePath!)),
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.blue,
        child: Text(
          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : "?",
          style: TextStyle(color: Colors.white, fontSize: radius / 1.5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactProvider = Provider.of<ContactProvider>(context);

    return Scaffold(
      backgroundColor: ColorConstants.whiteColor,
      body: Column(
        children: [
          customContactAppBar(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: contactProvider.contactBox.listenable(),
              builder: (context, Box<ContactModel> box, _) {
                List<ContactModel> contacts = box.values.toList();

                final query = _searchController.text.trim().toLowerCase();
                if (query.isNotEmpty) {
                  contacts = contacts.where((c) {
                    return c.name.toLowerCase().contains(query) ||
                        c.number.contains(query);
                  }).toList();
                }

                final grouped = groupContacts(contacts);

                if (grouped.isEmpty) {
                  return Center(
                    child: Text(
                      TextConstants.noContactFount,
                      style: TextStyle(fontSize: 20.sp),
                    ),
                  );
                }

                return ListView(
                  children: grouped.entries.map((entry) {
                    final letter = entry.key;
                    final groupContacts = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 15.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                              color: ColorConstants.greyColor,
                            ),
                          ),
                        ),
                        ...groupContacts.map((contact) {
                          return Slidable(
                            key: ValueKey("${contact.number}_${contact.name}"),
                            startActionPane: ActionPane(
                              motion: const StretchMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (_) => makeCall(contact.number, 0),
                                  icon: Icons.call,
                                  backgroundColor: Colors.green,
                                  label: "Call",
                                ),
                                SlidableAction(
                                  onPressed: (_) => sendMessage(contact.number),
                                  icon: Icons.message,
                                  backgroundColor: Colors.blue,
                                  label: "SMS",
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: widget.showCheckbox
                                  ? Checkbox(
                                      value: favContacts.contains(contact),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            favContacts.add(contact);
                                          } else {
                                            favContacts.remove(contact);
                                          }
                                        });
                                      },
                                    )
                                  : buildAvatar(contact),
                              title: Text(
                                contact.name,
                                style: TextStyle(fontSize: 12.sp),
                              ),
                              subtitle: Text(
                                contact.number,
                                style: TextStyle(fontSize: 12.sp),
                              ),
                              trailing: widget.showCheckbox
                                  ? null
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: ColorConstants.greyColor,
                                            size: 20.sp,
                                          ),
                                          onPressed: () => _showDeleteDialog(
                                            context,
                                            contact,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isFavourite(contact)
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            size: 20.sp,
                                            color: isFavourite(contact)
                                                ? ColorConstants.lightred
                                                : ColorConstants.greyColor,
                                          ),
                                          onPressed: () {
                                            final favouriteProvider =
                                                Provider.of<FavouriteProvider>(
                                                  context,
                                                  listen: false,
                                                );
                                            setState(() {
                                              if (isFavourite(contact)) {
                                                favouriteProvider
                                                    .deleteFavourite(contact);
                                              } else {
                                                favouriteProvider
                                                    .addToFavourite([contact]);
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: widget.showCheckbox
          ? FloatingActionButtonLocation.centerFloat
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: (!widget.showCheckbox && favContacts.isEmpty)
          ? Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [ColorConstants.blue, ColorConstants.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateContactScreen(),
                    ),
                  );
                },
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: ColorConstants.whiteColor),
              ),
            )
          : (favContacts.isNotEmpty)
          ? FloatingActionButton(
              shape: const CircleBorder(),
              backgroundColor: ColorConstants.lightred,
              onPressed: () {
                final favouriteProvider = Provider.of<FavouriteProvider>(
                  context,
                  listen: false,
                );
                favouriteProvider.addToFavourite(favContacts);
                Navigator.pop(context);
              },
              child: Icon(Icons.favorite, color: ColorConstants.whiteColor),
            )
          : null,
    );
  }

  Map<String, List<ContactModel>> groupContacts(List<ContactModel> contacts) {
    final Map<String, List<ContactModel>> grouped = {};
    contacts.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    for (var contact in contacts) {
      String firstLetter = contact.name.isNotEmpty
          ? contact.name[0].toUpperCase()
          : "?";
      grouped.putIfAbsent(firstLetter, () => []);
      grouped[firstLetter]!.add(contact);
    }
    return grouped;
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
    callProvider.addCall(number, simSlot, 0);
  }

  Widget customContactAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: 12.h,
        left: 16.w,
        right: 16.w,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorConstants.blue, ColorConstants.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (Navigator.canPop(context))
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.white),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: TextConstants.searchContacts,
                hintStyle: const TextStyle(color: Colors.white),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
