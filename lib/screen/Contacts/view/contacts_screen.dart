import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phoneapp/constants/color_constants.dart';
import 'package:phoneapp/constants/text_constants.dart';
import 'package:phoneapp/screen/Contacts/model/contacts_model.dart';
import 'package:phoneapp/screen/Contacts/provider/contact_provider.dart';
import 'package:phoneapp/screen/Contacts/view/create_contact.dart';
import 'package:phoneapp/screen/Favourites/provider/favourite_provider.dart';
import 'package:phoneapp/screen/Favourites/view/favourites_screen.dart';
import 'package:provider/provider.dart';

class ContactScreen extends StatefulWidget {
  final bool showCheckbox;
  const ContactScreen({super.key, this.showCheckbox = false});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  bool allSelect = false;
  List<ContactModel> favContacts = [];
  List<ContactModel> allContacts = [];
  List<ContactModel> displayedContacts = [];
  final TextEditingController _searchController = TextEditingController();
  bool isFavourite(ContactModel contact) {
    final favBox = Hive.box<ContactModel>('favourites');
    return favBox.values.any((e) => e.number == contact.number);
  }

  @override
  void initState() {
    super.initState();
    final box = Hive.box<ContactModel>('contacts');
    allContacts = box.values.toList();
    displayedContacts = List.from(allContacts);

    box.watch().listen((event) {
      setState(() {
        allContacts = box.values.toList();
        filterContacts(_searchController.text);
      });
    });
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
      if (!grouped.containsKey(firstLetter)) {
        grouped[firstLetter] = [];
      }
      grouped[firstLetter]!.add(contact);
    }
    return grouped;
  }

  void filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        displayedContacts = List.from(allContacts);
      } else {
        displayedContacts = allContacts.where((c) {
          return c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.number.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedContacts = groupContacts(displayedContacts);

    return Scaffold(
      backgroundColor: ColorConstants.whiteColor,
      appBar: AppBar(
         backgroundColor: ColorConstants.transparent,
          iconTheme: const IconThemeData(
    color: ColorConstants.whiteColor, 
    
    
  ),
  
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
        title:  Text(
          TextConstants.contacts,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ColorConstants.whiteColor,
            fontSize: 28.sp,
          ),
        ),
          leading: Navigator.canPop(context)
      ? IconButton(
          icon:  Icon(
            Icons.arrow_back_ios_new,
            size: 22.sp,
            color: ColorConstants.whiteColor,
          ),
          onPressed: () => Navigator.pop(context),
        )
      : null,
        
        actions: [
          if (widget.showCheckbox)
            IconButton(
              onPressed: selectAllItems,
              icon: allSelect
                  ? Icon(Icons.favorite, color: ColorConstants.whiteColor)
                  : Icon(Icons.favorite_border, color: ColorConstants.whiteColor),
            ),
        ],
        
        bottom: PreferredSize(
          preferredSize:  Size.fromHeight(50.h),
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: TextField(
              controller: _searchController,
              
              decoration:  InputDecoration(
                hint: Text(TextConstants.searchContacts,style: TextStyle(color: ColorConstants.whiteColor,fontSize: 18.sp),),
                prefixIcon: Icon(Icons.search,color: ColorConstants.whiteColor,),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.r)),
                
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: ColorConstants.whiteColor,width: 0.5.w)
                )
                
              ),
              
              onChanged: filterContacts,
            ),
          ),
        ),
      ),

      body: groupedContacts.isEmpty
          ? const Center(child: Text(TextConstants.noContactFount))
          : ListView(
              children: groupedContacts.entries.map((entry) {
                String letter = entry.key;
                List<ContactModel> contacts = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 15.h),

                    Container(
                      padding:  EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 4.h,
                      ),
                      child: Text(
                        letter,
                        style:  TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                          color: ColorConstants.greyColor,
                        ),
                      ),
                    ),

                    ...contacts.map(
                      (contact) => ListTile(
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
                            : contact.profile.isEmpty
                            ? CircleAvatar(
                                backgroundColor: Colors.blue.shade700,
                                child: Text(
                                  contact.name[0].toUpperCase(),
                                  style:  TextStyle(
                                    color: ColorConstants.whiteColor,
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                backgroundImage: contact.profile.startsWith("/")
                                    ? FileImage(File(contact.profile))
                                    : AssetImage(contact.profile)
                                          as ImageProvider,
                              ),
                        title: Text(contact.name),
                        subtitle: Text(contact.number),

                        trailing: widget.showCheckbox
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: ColorConstants.greyColor,
                                    ),
                                    onPressed: () =>
                                        _showDeleteDialog(context, contact),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isFavourite(contact)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color:isFavourite(contact)? ColorConstants.lightred :ColorConstants.greyColor
                                    ),
                                    onPressed: () {
                                      final favouriteProvider =
                                          Provider.of<FavouriteProvider>(
                                            context,
                                            listen: false,
                                          );

                                      setState(() {
                                        if (isFavourite(contact)) {
                                          favouriteProvider.deleteFavourite(
                                            contact,
                                          );
                                        } else {
                                          favouriteProvider.addToFavourite([
                                            contact,
                                          ]);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
      floatingActionButtonLocation: widget.showCheckbox
          ? FloatingActionButtonLocation.centerFloat
          : FloatingActionButtonLocation.endFloat,

floatingActionButton: 
  (! widget.showCheckbox && favContacts.isEmpty)
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
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateContactScreen()),
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
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavouriteScreen()),
                );
              },
              child: Icon(Icons.favorite, color: ColorConstants.whiteColor),
            )
          : null, 



    );
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

              final contactsProvider = Provider.of<ContactProvider>(
                context,
                listen: false,
              );
              final favProvider = Provider.of<FavouriteProvider>(
                context,
                listen: false,
              );

              contactsProvider.deleteContact(contact);
              favProvider.deleteFavourite(contact);

              setState(() {
                allContacts.remove(contact);
                displayedContacts.remove(contact);
                favContacts.remove(contact);

                filterContacts(_searchController.text);
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

  void selectAllItems() {
    setState(() {
      allSelect = !allSelect;
      if (allSelect) {
        favContacts = List.from(displayedContacts);
      } else {
        favContacts.clear();
      }
    });
  }

  void unselectAll() {
    setState(() {
      favContacts.clear();
    });
  }
}
