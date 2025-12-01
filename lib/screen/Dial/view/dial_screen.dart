import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phoneapp/constants/color_constants.dart';
import 'package:phoneapp/constants/text_constants.dart';
import 'package:phoneapp/screen/Contacts/model/contacts_model.dart';
import 'package:phoneapp/screen/Contacts/provider/contact_provider.dart';
import 'package:phoneapp/screen/Dial/provider/call_provider.dart';
import 'package:phoneapp/screen/Dial/view/keys.dart';
import 'package:phoneapp/screen/Dial/model/call_history_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class DialScreen extends StatefulWidget {
  const DialScreen({super.key});

  @override
  State<DialScreen> createState() => _DialScreenState();
}

class _DialScreenState extends State<DialScreen> {
  String typedNumber = "";
  bool selectionMode = false;
  bool selectAll = false;
  List<CallModel> selectedCalls = [];
  bool allSelect = false;
  int simCount = 1;
  bool showShare = false;
  CallModel? shareNumber;
  bool showDialer = true;

  @override
  void initState() {
    super.initState();
    detectSimCount();
    if (showDialer) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showDialerBottomSheet();
    });
  } 
  }

  Future<void> detectSimCount() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    bool isDualSim =
        androidInfo.supportedAbis.length > 1 ||
        androidInfo.version.sdkInt >= 22;

if (!mounted) return;
    setState(() {
      simCount = isDualSim ? 2 : 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final callhistoryProvider = Provider.of<CallProvider>(context);
    final callProvider = Provider.of<CallProvider>(context);
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
          selectionMode ? TextConstants.selectCall : TextConstants.dial,
          style:  TextStyle(
            fontWeight: FontWeight.bold,
            color: ColorConstants.whiteColor,
            fontSize: 28.sp,
          ),
        ),

         leading: showShare
      ? IconButton(
          icon: const Icon(Icons.close,color: ColorConstants.whiteColor,),
          onPressed: () {
            setState(() {
              showShare = false;
              shareNumber = null;
            });
          },
        )
      : null,

  actions: showShare
      ? [

 IconButton(
          icon: const Icon(Icons.share, color: ColorConstants.whiteColor),
    onPressed: () {
  if (shareNumber != null) {

    final contactProvider =
        Provider.of<ContactProvider>(context, listen: false);
    final matchedContact = contactProvider.contactBox.values.firstWhere(
      (element) => element.number == shareNumber!.number,
      orElse: () => ContactModel(name: "", number: "", profile: ""),
    );
    String textToShare;

    if (matchedContact.name.isNotEmpty) {
      textToShare =
          "Name: ${matchedContact.name}\nPhone Number: ${shareNumber!.number}";
    } else {
      textToShare = "Phone Number: ${shareNumber!.number}";
    }

 
    Share.share(textToShare);
  }
},
        ),
        
        ]
      : (selectionMode
          ? [
              IconButton(
                onPressed: unselectAll,
                icon:  Icon(Icons.close),
              ),
              TextButton(
                onPressed: selectAllItems,
                child:  Text(
                  TextConstants.all,
                  style: TextStyle(
                    color: ColorConstants.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]
          : null),
      ),

      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [ 
                 (!showShare&& callProvider.box.values.isEmpty) ? Text("") :   IconButton(
                        onPressed: () {
                          setState(() {
                            selectionMode = true;
                            selectedCalls.clear();
                          });
                        },
                        icon:  Icon(Icons.check_box_outlined),
                      ),
            ],
          ),
                    Expanded(
            child: ValueListenableBuilder(
              valueListenable: callProvider.box.listenable(),
              builder: (context, Box<CallModel> box, _) {
                final calls = box.values.toList().reversed.toList();

                if (calls.isEmpty) {
                  return const Center(child: Text(TextConstants.nocallsyet));
                }

                return ListView.builder(
                  itemCount: calls.length,
                  itemBuilder: (context, index) {
                    final call = calls[index];
                    return Slidable(
                      key: Key(call.key.toString()),
                      endActionPane: !selectionMode
                          ? ActionPane(
                              motion: const DrawerMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) {
                                    callhistoryProvider.deleteCall(call);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(TextConstants.calldeleted),
                                      ),
                                    );
                                  },
                                  backgroundColor: ColorConstants.lightred,
                                  foregroundColor: ColorConstants.whiteColor,
                                  icon: Icons.delete,
                                  label: TextConstants.delete,
                                ),
                              ],
                            )
                          : null,
                      child: Padding(
                        padding:  EdgeInsets.symmetric(horizontal: 10.w),
                        child: Card(
                          color: shareNumber == call? ColorConstants.lightGrey: ColorConstants.whiteColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(2.r),
                          ),
                          child: ListTile(
                            onLongPress: () {
                              setState(() {
                                 showShare = true;
                              shareNumber = call;
                              });
                             
                            },
                            leading: selectionMode
                                ? Checkbox(
                                    value: selectedCalls.contains(call),
                                    activeColor: ColorConstants.blueColor,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedCalls.add(call);
                                        } else {
                                          selectedCalls.remove(call);
                                        }
                                      });
                                    },
                                  )
                                : const Icon(
                                    Icons.phone,
                                    color: ColorConstants.greenColor,
                                  ),

                            title: Consumer<ContactProvider>(
                              builder: (context, contactProvider, child) {
                                final matchedContact = contactProvider
                                    .contactBox
                                    .values
                                    .firstWhere(
                                      (element) =>
                                          element.number == call.number,
                                      orElse: () => ContactModel(
                                        name: "",
                                        number: "",
                                        profile: "",
                                      ),
                                    );

                                return Text(
                                  matchedContact.name.isNotEmpty
                                      ? matchedContact.name
                                      : call.number,
                                  style:  TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                            subtitle: Consumer<ContactProvider>(
                              builder: (context, contactProvider, child) {
                                final matchedContact = contactProvider
                                    .contactBox
                                    .values
                                    .firstWhere(
                                      (element) =>
                                          element.number == call.number,
                                      orElse: () => ContactModel(
                                        name: "",
                                        number: "",
                                        profile: "",
                                      ),
                                    );
                                return Row(
                                  children: [
                                    call.simSlot == 0
                                        ? Icon(
                                            Icons.looks_one_rounded,
                                            color: ColorConstants.greyColor,
                                            size: 18.sp,
                                          )
                                        : Icon(
                                            Icons.looks_two,
                                            color: ColorConstants.greyColor,
                                            size: 18.sp,
                                          ),

                                    matchedContact.name.isNotEmpty
                                        ? Text(
                                            call.number,
                                            style:  TextStyle(
                                              fontSize: 13.sp,
                                            ),
                                          )
                                        : Text(
                                            TextConstants.unknownlocation,
                                            style: TextStyle(
                                              color: ColorConstants.greyColor,
                                            ),
                                          ),
                                  ],
                                );
                              },
                            ),

                            trailing: Text(
                              DateFormat('hh.mm a').format(call.time),
                              style:  TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                                color: ColorConstants.greyColor,
                              ),
                            ),

                            onTap: selectionMode
                                ? () {
                                    setState(() {
                                      callProvider.deleteCall(call);
                                    });
                                  }
                                : null,
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
      floatingActionButtonLocation: selectionMode
          ? FloatingActionButtonLocation.centerFloat
          : FloatingActionButtonLocation.endFloat,

      floatingActionButton: (selectionMode && selectedCalls.isNotEmpty)
          ? FloatingActionButton(
              shape: const CircleBorder(),
              onPressed: deleteSelected,
              backgroundColor: ColorConstants.lightred,
              child: const Icon(Icons.delete, color: ColorConstants.whiteColor),
            )
          : (!selectionMode)
          ? FloatingActionButton(
              shape: const CircleBorder(),
              backgroundColor: ColorConstants.greenColor,
              onPressed: (){
                setState(() {
                  showDialerBottomSheet();
                showDialer = !showDialer;
                  
                });
                
              },
              child: const Icon(Icons.dialpad, color: ColorConstants.whiteColor),
            )
          : null,
    );
  }

  void selectAllItems() {
    final callhistoryProvider = Provider.of<CallProvider>(
      context,
      listen: false,
    );

    setState(() {
      allSelect = !allSelect;
      if (allSelect == true) {
        selectedCalls = callhistoryProvider.box.values.toList();
      } else {
        selectedCalls.clear();
      }
    });
  }

  void unselectAll() {
    setState(() {
      selectionMode = false;
      selectedCalls.clear();
    });
  }

  void deleteSelected() {
    final callhistoryProvider = Provider.of<CallProvider>(
      context,
      listen: false,
    );
    for (CallModel call in selectedCalls) {
      callhistoryProvider.deleteCall(call);
    }

    setState(() {
      selectionMode = false;
      selectedCalls.clear();
      allSelect = false;
    });
  }

  void showDialerBottomSheet() {
    
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorConstants.whiteColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setBottomState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.70,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    typedNumber,
                    style:  TextStyle(
                      fontSize: 34.sp,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.blaclColor,
                    ),
                  ),

                   SizedBox(height: 20.h),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    children: keys.map((key) {
                      return Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorConstants.lightBlue,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TextButton(
                          onPressed: () {
                            setState(() => typedNumber += key[TextConstants.digit]!);
                            setBottomState(() {});
                          },
                          onLongPress: () {
                            if (key[TextConstants.digit] == '0') {
                              setState(() {
                                typedNumber += '+';
                              });
                              setBottomState(() {});
                            }
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                key[TextConstants.digit]!,
                                style:  TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.bold,
                                  color: ColorConstants.blaclColor,
                                ),
                              ),

                              Text(
                                key[TextConstants.letters]!,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: ColorConstants.greyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu,
                        size: 28.sp,
                        color: ColorConstants.blaclColor,
                      ),

                       SizedBox(width: 10.w),

                      callButton(TextConstants.sim1, 0),
                       SizedBox(width: 5.w),
                      callButton(TextConstants.sim2, 1),

                      SizedBox(width: 10.w),

                      IconButton(
                        onPressed: () {
                          if (typedNumber.isNotEmpty) {
                            setState(() {
                              typedNumber = typedNumber.substring(
                                0,
                                typedNumber.length - 1,
                              );
                            });
                            setBottomState(() {});
                          }
                        },
                        icon:  Icon(Icons.backspace_outlined, size: 28.sp),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> makeCall(String number, int simSlot) async {
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
      if (!status.isGranted) {
        return;
      }
    }

    final intent = AndroidIntent(
      action: 'android.intent.action.CALL',
      data: 'tel:$number',
      arguments: {"com.android.phone.extra.slot": simSlot},
    );
    await intent.launch();
    if (!mounted) return;
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    callProvider.addCall(number, simSlot);
  }

  Widget callButton(String title, int slot) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize:  Size(100.w, 40.h),
        padding:  EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.r)),
        backgroundColor: ColorConstants.greenColor,
      ),
      onPressed: () {
       if(typedNumber.isNotEmpty) makeCall(typedNumber, slot);
      },
      icon:  Icon(Icons.call, color: ColorConstants.whiteColor, size: 18.sp),
      label: Text(
        title,
        style:  TextStyle(
          color: ColorConstants.whiteColor,
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
      ),
    );
  }
}
