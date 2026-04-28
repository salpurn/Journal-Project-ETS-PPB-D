import 'package:flutter/material.dart';
import 'package:online_journal/pages/home_page.dart';
import 'package:online_journal/pages/login_page.dart';
import 'package:online_journal/pages/register_page.dart';
import 'package:online_journal/pages/user_info_page.dart';
import 'package:online_journal/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initializeNotification();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Fungsi helper untuk simpan data user ke root collection 'users'
  void _syncUserToFirestore(User? user) {
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'uid': user.uid,
        'lastSeen': Timestamp.now(),
      }, SetOptions(merge: true)); // Merge true agar tidak menimpa data lama
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Online Journal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            Future.microtask(() => _syncUserToFirestore(snapshot.data));
            return const HomePage();
          } 
          return const LoginPage();
        },
      ),
      routes: {
        'login': (context) => const LoginPage(),
        'register': (context) => const RegisterPage(),
        'home': (context) => const HomePage(),
        'user_info': (context) => const UserInfoPage(),
      },
    );
  }
}