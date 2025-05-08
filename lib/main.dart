import 'package:chintufy/services/secondary_database_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'pages/login_page.dart';
import 'services/database_service.dart';
import 'services/firebase_storage_service.dart';
import 'pages/signup_page.dart';
import 'pages/homepage.dart';
import 'models/cart.dart';
import 'models/user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize primary Firebase
    await Firebase.initializeApp();

    // Initialize secondary Firebase with correct config from your JSON
    await SecondaryDatabaseService.initialize();
    
    print('Both Firebase instances initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),
        Provider<SecondaryDatabaseService>(
          create: (_) {
            try {
              return SecondaryDatabaseService();
            } catch (e) {
              print('Error creating SecondaryDatabaseService: $e');
              rethrow;
            }
          },
        ),
        ChangeNotifierProvider<CartModel>(
          create: (_) => CartModel(),
        ),
        ChangeNotifierProvider<UserProfileModel>(
          create: (_) => UserProfileModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Tuck Shop Chintufy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: LoginPage(),
        routes: {
          '/login': (context) => LoginPage(),
          '/signup': (context) => SignupPage(),
          '/home': (context) => HomePage(),
        },
      ),
    );
  }
}