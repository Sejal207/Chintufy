import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'pages/login_page.dart';
import 'services/database_service.dart';
import 'services/firebase_storage_service.dart';
import 'pages/signup_page.dart';
import 'pages/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyAvnIEJuZ6nfuu5YY-SrRQPj3SuTUAZUXc',
        appId: '1:1060417338481:android:ecbcebe7dd7f06667e2fd0',
        messagingSenderId: '1060417338481',
        projectId: 'tuckshop-chintufy',
        storageBucket: 'tuckshop-chintufy.firebasestorage.app'
      )
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),
        Provider<FirebaseStorageService>(
          create: (_) => FirebaseStorageService(),
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