import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_theme.dart';
import 'features/auth/auth_wrapper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Temporary test function to write to Firestore
  Future.delayed(const Duration(seconds: 2), () async {
    try {
      final docRef = FirebaseFirestore.instance.collection('test_connection').doc('status_check');
      await docRef.set({
        'status': 'connected',
        'timestamp': FieldValue.serverTimestamp(),
        'device': 'emulator/device',
        'message': 'Successfully connected to Firebase!',
      });
      debugPrint('🔥 FIRESTORE SUCCESS: Data written to collection [test_connection] at document [status_check]');
    } catch (e) {
      debugPrint('🚨 FIRESTORE ERROR: $e');
      debugPrint('💡 TIP: Check if your Firestore Rules allow writes or if the database has been created in the console.');
    }
  });

  runApp(const SmartCropAssistantApp());
}

class SmartCropAssistantApp extends StatelessWidget {
  const SmartCropAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Crop Assistant',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
