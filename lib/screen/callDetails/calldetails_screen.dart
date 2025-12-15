import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:phoneapp/constants/color_constants.dart';
import 'package:phoneapp/constants/text_constants.dart';
import 'package:phoneapp/screen/Contacts/model/contact_history_model.dart';
import 'package:phoneapp/screen/Contacts/provider/contact_provider.dart';
import 'package:phoneapp/screen/Contacts/view/create_contact.dart';
import 'package:phoneapp/screen/Dial/helper/call_helper.dart';
import 'package:phoneapp/screen/Dial/model/call_log_model.dart';
import 'package:phoneapp/screen/Dial/provider/call_provider.dart';
import 'package:provider/provider.dart';


class CallDetailsPage extends StatefulWidget {
  final CallModel call;
  final int simCount;
  const CallDetailsPage({
    super.key,
    required this.call,
    required this.simCount,
  });

  @override
  State<CallDetailsPage> createState() => _CallDetailsPageState();
}

String normalizeNumber(String number) {
  return number
      .replaceAll(RegExp(r'[^0-9]'), '')
      .replaceFirst(RegExp(r'^91'), '');
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


class _CallDetailsPageState extends State<CallDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final contactProvider = Provider.of<ContactProvider>(context);
    final callProvider = Provider.of<CallProvider>(context);

    final contact = contactProvider.contactBox.values.firstWhere(
      (c) => normalizeNumber(c.number) == normalizeNumber(widget.call.number),
      orElse: () =>
          ContactModel(name: "", number: "", profile: null, profilePath: null),
    );

    bool isSavedContact = contact.number.isNotEmpty;

    return Scaffold(
      body: Column(
        children: [
          Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: ColorConstants.whiteColor,
                    size: 22.sp,
                  ),
                ),
                Text(
                  TextConstants.details,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26.sp,
                    color: ColorConstants.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isSavedContact)
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateContactScreen(
                            isEditing: false,
                            call: widget.call,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.person_add,
                      color: ColorConstants.whiteColor,
                      size: 25.sp,
                    ),
                  ),
                if (isSavedContact)
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateContactScreen(
                            isEditing: true,
                            contact: contact,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.edit_rounded,
                      color: ColorConstants.whiteColor,
                      size: 25.sp,
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: 50.h),

          buildContactAvatar(contact, radius: 45.r),

          SizedBox(height: 12.h),

          Text(
            isSavedContact ? contact.name : widget.call.number,
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
          ),

          if (isSavedContact)
            Text(
              contact.number,
              style: TextStyle(
                fontSize: 16.sp,
                color: ColorConstants.greyColor,
              ),
            ),

          SizedBox(height: 25.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(
                Icons.message,
                "Message",
                () => _sendMessage(context, widget.call.number),
                bgColor: Colors.blue,
              ),
              if (widget.simCount == 1)
                _actionButton(
                  Icons.call,
                  "SIM 1",
                  () =>CallHelper.makeCall(context,widget.call.number, 0),
                )
              else ...[
                _actionButton(

            
                  Icons.call,
                  "SIM 1",
                  () => CallHelper.makeCall(context,widget.call.number, 0),
                ),
                _actionButton(
                  Icons.call,
                  "SIM 2",
                  () => CallHelper.makeCall(context, widget.call.number, 1),
                ),
              ],
              _actionButton(
                Icons.videocam,
                "Video",
                () => _videoCall(context, widget.call.number),
              ),
            ],
          ),

          SizedBox(height: 25.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Call History",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          Expanded(
            child: ValueListenableBuilder(
              valueListenable: callProvider.box.listenable(),
              builder: (context, Box<CallModel> box, _) {
                final logs =
                    box.values
                        .where(
                          (c) =>
                              normalizeNumber(c.number) ==
                              normalizeNumber(widget.call.number),
                        )
                        .toList()
                      ..sort((a, b) => b.time.compareTo(a.time));

                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, i) {
                    final log = logs[i];
                    return ListTile(
                      leading: Icon(
                        log.simSlot == 0 ? Icons.looks_one : Icons.looks_two,
                        color: log.simSlot == 0 ? Colors.blue : Colors.green,
                      ),
                      title: Text(DateFormat("dd MMM yyyy").format(log.time)),
                      subtitle: Text(DateFormat("hh:mm a").format(log.time)),
                      trailing: log.duration == 0
                          ? Text(
                              "not connect",
                              style: TextStyle(
                                color: ColorConstants.greyColor,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Text(formatDuration(log.duration)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, String number) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SENDTO',
      data: 'smsto:$number',
    );
    await intent.launch();
  }

  void _videoCall(BuildContext context, String number) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.CALL',
      data: 'tel:$number',
      package: 'com.google.android.apps.tachyon',
    );
    await intent.launch();
  }
}


Widget _actionButton(
  IconData icon,
  String label,
  VoidCallback onTap, {
  Color bgColor = Colors.green,
}) {
  return Column(
    children: [
      ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.all(16),
          backgroundColor: bgColor,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
      SizedBox(height: 5.h),
      Text(label),
    ],
  );
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
