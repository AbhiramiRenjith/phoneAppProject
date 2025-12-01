import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phoneapp/constants/color_constants.dart';
import 'package:phoneapp/constants/text_constants.dart';
import 'package:phoneapp/screen/Contacts/model/contacts_model.dart';
import 'package:provider/provider.dart';
import '../provider/contact_provider.dart';

class CreateContactScreen extends StatefulWidget {
  const CreateContactScreen({super.key});

  @override
  State<CreateContactScreen> createState() => _CreateContactScreenState();
}

class _CreateContactScreenState extends State<CreateContactScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  File? pickedImage;

  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  Future<void> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        pickedImage = File(image.path);
      });
    }
  }

  Future<void> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        pickedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: ColorConstants.whiteColor),
        ),
        title:  Text(
          TextConstants.calldeleted,
          style: TextStyle(
            fontSize: 26.sp,
            color: ColorConstants.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: showImagePickerSheet,
                child: CircleAvatar(
                  radius: 50.r,
                  backgroundColor: ColorConstants.greyColor,
                  backgroundImage: pickedImage != null
                      ? FileImage(pickedImage!)
                      : null,
                  child: pickedImage == null
                      ? const Icon(Icons.camera_alt, size: 35)
                      : null,
                ),
              ),
               SizedBox(height: 22.h),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: TextConstants.name,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _numberController,
                              decoration: const InputDecoration(
                                labelText: TextConstants.phoneNumber,
                              ),

                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'phone number filed is empty';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    ListTile(
                      leading: const Icon(Icons.email),
                      title: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: TextConstants.email,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ColorConstants.blue, ColorConstants.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.transparent,
                        shadowColor: ColorConstants.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () {
                        validation();
                      },
                      child: const Text(
                        TextConstants.save,
                        style: TextStyle(
                          color: ColorConstants.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void validation() {
    if (_formKey.currentState!.validate()) {
      final contact = ContactModel(
        name: _nameController.text,
        number: _numberController.text,
        profile: pickedImage?.path ?? "",
      );

      Provider.of<ContactProvider>(context, listen: false).addContact(contact);
      Navigator.pop(context);
    }
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
                leading: const Icon(Icons.camera_alt, color: ColorConstants.greenColor),
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
}
