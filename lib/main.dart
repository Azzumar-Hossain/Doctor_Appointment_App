import 'package:demo_appointment/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: DemoAppointment()));
}

class DemoAppointment extends StatelessWidget {
  const DemoAppointment({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Appointment",
      theme: ThemeData(primarySwatch: Colors.amber, useMaterial3: true),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
