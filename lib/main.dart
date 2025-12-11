
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phoneapp/screen/Contacts/model/contact_history_model.dart';
import 'package:phoneapp/screen/Contacts/provider/contact_provider.dart';
import 'package:phoneapp/screen/Dial/model/call_log_model.dart';
import 'package:phoneapp/screen/Dial/provider/call_provider.dart';
import 'package:phoneapp/screen/Favourites/provider/favourite_provider.dart';
import 'package:phoneapp/screen/bottomnavigation.dart';
import 'package:provider/provider.dart';


void main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); 
  Hive.registerAdapter(CallModelAdapter());
  await Hive.openBox<CallModel>('call_log'); 
   Hive.registerAdapter(ContactModelAdapter()); 
  await Hive.openBox<ContactModel>('contacts'); 
  await Hive.openBox<ContactModel>('favourites'); 
   
   runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CallProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()..loadDeviceContacts()),
         ChangeNotifierProvider(create: (_) => FavouriteProvider()),

         
      ],
      child: const MyApp(),
    ),
  ); 
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: BottomnavigationScreen()
        );
      },
    );
  }
}


