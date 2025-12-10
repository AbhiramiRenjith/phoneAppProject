import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phoneapp/constants/color_constants.dart';
import 'package:phoneapp/constants/text_constants.dart';
import 'package:phoneapp/screen/Contacts/model/contact_history_model.dart';
import 'package:phoneapp/screen/Dial/model/call_log_history_model.dart';
import 'package:provider/provider.dart';
import '../provider/contact_provider.dart';


class CreateContactScreen extends StatefulWidget {
  final bool isEditing;
  final CallModel? call;
  final ContactModel? contact;

  const CreateContactScreen({
    super.key,
    this.isEditing = false,
    this.call,
    this.contact,
  });

  @override
  State<CreateContactScreen> createState() => _CreateContactScreenState();
}

class _CreateContactScreenState extends State<CreateContactScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  ContactModel? editingContact;

  File? pickedImage;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.contact != null) {
      editingContact = widget.contact;
      _nameController.text = editingContact!.name;
      _numberController.text = editingContact!.number;

      if (editingContact!.profilePath != null &&
          File(editingContact!.profilePath!).existsSync()) {
        pickedImage = File(editingContact!.profilePath!);
      } else if (editingContact!.profile != null &&
          editingContact!.profile!.isNotEmpty) {
        pickedImage = null;
      }
    } else if (widget.call != null) {
      _numberController.text = widget.call!.number;
    }
  }

  Future<void> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => pickedImage = File(image.path));
  }

  Future<void> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) setState(() => pickedImage = File(image.path));
  }

  void showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SizedBox(
          height: 220,
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: ColorConstants.blaclColor),
                  ),
                ],
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: ColorConstants.blue),
                title: const Text(TextConstants.chooseFromGallary),
                onTap: () {
                  Navigator.pop(context);
                  pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: ColorConstants.greenColor,
                ),
                title: const Text(TextConstants.takePhoto),
                onTap: () {
                  Navigator.pop(context);
                  pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void validation() async {
    if (_formKey.currentState!.validate()) {
      final contactProvider = Provider.of<ContactProvider>(
        context,
        listen: false,
      );

      Uint8List? profileBytes;
      if (pickedImage != null) {
        profileBytes = await pickedImage!.readAsBytes();
      }

      if (widget.isEditing && editingContact != null) {
        await contactProvider.updateContact(
          editingContact!,
          updatedName: _nameController.text,
          updatedPhone: _numberController.text,
          updatedImageBytes: profileBytes ?? editingContact!.profile,

          updatedPath: pickedImage?.path ?? editingContact!.profilePath,
        );
      } else {
        final newContact = ContactModel(
          name: _nameController.text,
          number: _numberController.text,
          profile: profileBytes,
          profilePath: pickedImage?.path,
        );
        contactProvider.addContact(newContact);
      }
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.whiteColor,
      body: Column(
        children: [
          customAppBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 50),
                  GestureDetector(
                    onTap: showImagePickerSheet,
                    child: CircleAvatar(
                      radius: 50.w,
                      backgroundColor: ColorConstants.greyColor,
                      backgroundImage: pickedImage != null
                          ? FileImage(pickedImage!)
                          : (editingContact?.profile != null
                                ? MemoryImage(editingContact!.profile!)
                                : null),
                      child:
                          (pickedImage == null &&
                              (editingContact?.profile == null ||
                                  editingContact!.profile!.isEmpty))
                          ? Icon(
                              Icons.camera_alt,
                              size: 50.w,
                              color: ColorConstants.blaclColor,
                            )
                          : null,
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.person, size: 20.sp),
                            title: TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: TextConstants.name,
                                labelStyle: TextStyle(fontSize: 15.sp),
                              ),
                            ),
                          ),
                          SizedBox(height: 5.h),
                          ListTile(
                            leading: Icon(Icons.phone, size: 20.sp),
                            title: TextFormField(
                              controller: _numberController,
                              decoration: InputDecoration(
                                labelText: TextConstants.phoneNumber,
                                labelStyle: TextStyle(fontSize: 15.sp),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Phone number field is empty';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ColorConstants.blue,
                              ColorConstants.purple,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: Size(100.w, 50.h),
                          ),
                          onPressed: validation,
                          child: Text(
                            TextConstants.save,
                            style: TextStyle(
                              color: ColorConstants.whiteColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget customAppBar() {
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              size: 20.sp,
              color: ColorConstants.whiteColor,
            ),
          ),
          Text(
            TextConstants.createContact,
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
}
