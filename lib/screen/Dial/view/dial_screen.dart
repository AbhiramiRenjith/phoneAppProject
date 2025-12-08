import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:phoneapp/constants/color_constants.dart';
import 'package:phoneapp/constants/text_constants.dart';
import 'package:phoneapp/screen/Contacts/model/contact_history_model.dart';
import 'package:phoneapp/screen/Contacts/provider/contact_provider.dart';
import 'package:phoneapp/screen/Dial/helper/call_helper.dart';
import 'package:phoneapp/screen/Dial/helper/sim_helper.dart';
import 'package:phoneapp/screen/Dial/model/callhistory_model.dart';
import 'package:phoneapp/screen/Dial/provider/call_provider.dart';
import 'package:phoneapp/screen/callDetails/calldetails_screen.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phoneapp/screen/Dial/view/keys.dart';

class DialScreen extends StatefulWidget {
  const DialScreen({super.key});
  @override
  State<DialScreen> createState() => _DialScreenState();
}

class _DialScreenState extends State<DialScreen> {
  String typedNumber = "";
  bool selectionMode = false;
  List<CallModel> selectedCalls = [];
  bool allSelect = false;
  int simCount = 0;
  bool showShare = false;
  CallModel? shareNumber;
  bool showDialer = true;
  bool showCheckbox = true;

  @override
  void initState() {
    super.initState();
    loadSimInfo();
    if (mounted && showDialer) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => showDialerBottomSheet(),
      );
    }
  }

  String normalizeNumber(String number) {
    number = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (number.startsWith("91") && number.length == 12) {
      number = number.substring(2);
    }
    if (number.startsWith("0") && number.length == 11) {
      number = number.substring(1);
    }
    return number;
  }

  Future<void> loadSimInfo() async {
    final sims = await SimHelper.getSimInfo();
    if (!mounted) return;
    setState(() {
      simCount = sims.length;
    });
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    String result = '';
    if (hours > 0) result += '$hours:';
    result += '${minutes.toString().padLeft(2, '0')}:';
    result += secs.toString().padLeft(2, '0');
    return '$result s';
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    return Scaffold(
      backgroundColor: ColorConstants.whiteColor,
      body: Column(
        children: [
          customAppBar(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (callProvider.box.values.isNotEmpty && showCheckbox)
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectionMode = true;
                      selectedCalls.clear();
                    });
                  },
                  icon: const Icon(Icons.check_box_outlined),
                ),
            ],
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: callProvider.box.listenable(),
              builder: (context, Box<CallModel> box, _) {
                final calls = box.values.toList().reversed.toList();

                if (calls.isEmpty) {
                  return Center(
                    child: Text(
                      TextConstants.nocallsyet,
                      style: TextStyle(fontSize: 20.sp),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: calls.length,
                  itemBuilder: (context, index) {
                    final call = calls[index];
                    return Slidable(
                      key: Key(call.key.toString()),
                      endActionPane: (!selectionMode && !showShare)
                          ? ActionPane(
                              motion: const DrawerMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (_) {
                                    callProvider.deleteCall(call);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          TextConstants.calldeleted,
                                          style: TextStyle(fontSize: 12.sp),
                                        ),
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
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Card(
                          color: shareNumber == call
                              ? ColorConstants.lightGrey
                              : ColorConstants.whiteColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                          child: ListTile(
                            onLongPress: () {
                              setState(() {
                                if (!selectionMode) {
                                  showShare = true;
                                  shareNumber = call;
                                  showCheckbox = !showCheckbox;
                                }
                              });
                            },
                            leading: selectionMode
                                ? Checkbox(
                                    value: selectedCalls.contains(call),
                                    activeColor: ColorConstants.blue,
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
                                          normalizeNumber(element.number) ==
                                          normalizeNumber(call.number),
                                      orElse: () => ContactModel(
                                        name: "",
                                        number: "",
                                        profile: null,
                                      ),
                                    );

                                return Text(
                                  matchedContact.name.isNotEmpty
                                      ? matchedContact.name
                                      : call.number,
                                  style: TextStyle(
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
                                          normalizeNumber(element.number) ==
                                          normalizeNumber(call.number),
                                      orElse: () => ContactModel(
                                        name: "",
                                        number: "",
                                        profile: null,
                                      ),
                                    );

                                return Row(
                                  children: [
                                    Icon(
                                      call.simSlot == 0
                                          ? Icons.looks_one_rounded
                                          : Icons.looks_two,
                                      color: ColorConstants.greyColor,
                                      size: 18.sp,
                                    ),
                                    SizedBox(width: 5.w),
                                    matchedContact.name.isNotEmpty
                                        ? Text(
                                            call.number,
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: ColorConstants.greyColor,
                                            ),
                                          )
                                        : Text(
                                            TextConstants.unknownlocation,
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: ColorConstants.greyColor,
                                            ),
                                          ),
                                  ],
                                );
                              },
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('hh.mm a').format(call.time),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                    color: ColorConstants.greyColor,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CallDetailsPage(
                                          call: call,
                                          simCount: simCount,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.details,
                                    color: ColorConstants.greyColor,
                                  ),
                                ),
                              ],
                            ),
                            onTap: (!selectionMode && !showShare)
                                ? () => CallHelper.makeCall(
                                    context,
                                    call.number,
                                    0,
                                  )
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
      floatingActionButton: selectionMode && selectedCalls.isNotEmpty
          ? FloatingActionButton(
              shape: const CircleBorder(),
              onPressed: deleteSelected,
              backgroundColor: ColorConstants.lightred,
              child: const Icon(Icons.delete, color: ColorConstants.whiteColor),
            )
          : !selectionMode
          ? FloatingActionButton(
              shape: const CircleBorder(),
              backgroundColor: ColorConstants.greenColor,
              onPressed: () {
                setState(() {
                  showDialerBottomSheet();
                  showShare = false;
                  shareNumber = null;
                  showDialer = !showDialer;
                });
              },
              child: const Icon(
                Icons.dialpad,
                color: ColorConstants.whiteColor,
              ),
            )
          : null,
    );
  }

  void selectAllItems() {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    setState(() {
      allSelect = !allSelect;
      selectedCalls = allSelect ? callProvider.box.values.toList() : [];
    });
  }

  void unselectAll() {
    setState(() {
      selectionMode = false;
      selectedCalls.clear();
    });
  }

  void deleteSelected() {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    for (CallModel call in selectedCalls) {
      callProvider.deleteCall(call);
    }
    setState(() {
      selectionMode = false;
      selectedCalls.clear();
      allSelect = false;
    });
  }

  Widget customAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showShare || selectionMode)
            IconButton(
              onPressed: () {
                setState(() {
                  showShare ? showShare = false : unselectAll();
                  shareNumber = null;
                  showCheckbox = !showCheckbox;
                });
              },
              icon: Icon(
                Icons.close,
                color: ColorConstants.whiteColor,
                size: 28.sp,
              ),
            )
          else
            const SizedBox(width: 30),
          Expanded(
            child: Text(
              showShare
                  ? "Share Contact"
                  : selectionMode
                  ? TextConstants.selectCall
                  : "",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26.sp,
                color: ColorConstants.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (showShare)
            IconButton(
              onPressed: () {
                if (shareNumber != null) {
                  final contactProvider = Provider.of<ContactProvider>(
                    context,
                    listen: false,
                  );
                  final matchedContact = contactProvider.contactBox.values
                      .firstWhere(
                        (e) => e.number == shareNumber!.number,
                        orElse: () =>
                            ContactModel(name: "", number: "", profile: null),
                      );
                  String textToShare = matchedContact.name.isNotEmpty
                      ? "Name: ${matchedContact.name}\nPhone: ${shareNumber!.number}"
                      : "Phone Number: ${shareNumber!.number}";
                
                  Share.share(textToShare);
                }
              },
              icon: Icon(
                Icons.share,
                color: ColorConstants.whiteColor,
                size: 28.sp,
              ),
            )
          else if (selectionMode)
            TextButton(
              onPressed: selectAllItems,
              child: Text(
                TextConstants.all,
                style: TextStyle(
                  color: ColorConstants.whiteColor,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const SizedBox(width: 30),
        ],
      ),
    );
  }

  void showDialerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorConstants.whiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setBottomState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: TextEditingController(text: typedNumber)
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: typedNumber.length),
                          ),
                        readOnly: true,
                        showCursor: true,
                        style: TextStyle(
                          fontSize: 34.sp,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.blaclColor,
                        ),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        cursorColor: ColorConstants.greenColor,
                      ),
                    ),
                    GridView.count(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      childAspectRatio: 1.2,
                      children: keys.map((key) {
                        return Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ColorConstants.lightBlue,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: TextButton(
                            onPressed: () {
                              typedNumber += key[TextConstants.digit]!;
                              setBottomState(() {});
                            },
                            onLongPress: () {
                              if (key[TextConstants.digit] == '0') {
                                typedNumber += '+';
                                setBottomState(() {});
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  key[TextConstants.digit]!,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: ColorConstants.blaclColor,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  key[TextConstants.letters]!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ColorConstants.greyColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 25.sp),

                        if (simCount == 1) ...[
                          Expanded(child: callButton(TextConstants.sim1, 0)),
                        ] else ...[
                          Expanded(child: callButton(TextConstants.sim1, 0)),
                          SizedBox(width: 5.w),
                          Expanded(child: callButton(TextConstants.sim2, 1)),
                        ],
                        SizedBox(width: 10.w),
                        IconButton(
                          onPressed: () {
                            if (typedNumber.isNotEmpty) {
                              typedNumber = typedNumber.substring(
                                0,
                                typedNumber.length - 1,
                              );
                              setBottomState(() {});
                            }
                          },
                          icon: Icon(Icons.backspace_outlined, size: 28.sp),
                        ),
                        SizedBox(width: 20.sp),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget callButton(String title, int slot) {
    BorderRadius borderRadius = slot == 0
        ? BorderRadius.only(
            topLeft: Radius.circular(12.r),
            bottomLeft: Radius.circular(12.r),
          )
        : BorderRadius.only(
            topRight: Radius.circular(12.r),
            bottomRight: Radius.circular(12.r),
          );

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(100.w, 40.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        backgroundColor: ColorConstants.greenColor,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      onPressed: () {
        if (typedNumber.isNotEmpty) {
          CallHelper.makeCall(context, typedNumber, slot);
        }
      },
      icon: Icon(Icons.call, color: ColorConstants.whiteColor, size: 18.sp),
      label: Text(
        title,
        style: TextStyle(
          color: ColorConstants.whiteColor,
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
      ),
    );
  }
}
