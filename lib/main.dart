import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/splash_page.dart';
import 'pages/detail_page.dart';
import 'pages/add_form_page.dart';
import 'pages/register_page.dart';
import 'package:flutter/material.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MaterialApp(
    title: 'Lapor Book',
    initialRoute: '/',
    routes: {
      '/': (context) => const SplashPage(),
      '/login': (context) => const LoginPage(),
      '/add': (context) => const AddFormPage(),
      '/detail': (context) => const DetailPage(),
      '/register': (context) => const RegisterPage(),
      '/dashboard': (context) => const DashboardPage(),
    },
  ));
}
