import 'package:demo_appointment/providers/auth_provider.dart';
import 'package:demo_appointment/screens/appointment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = const FlutterSecureStorage();

    Future<bool> _onWillPop() async {
      return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Exit App"),
              content: const Text("Are you sure you want to exit?"),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(false), // Stay in app
                  child: const Text("No"),
                ),
                TextButton(
                  onPressed: () async {
                    final userId = await storage.read(key: "user_id");
                    final token = await storage.read(key: "token");

                    if (userId != null && token != null) {
                      final success = await ref
                          .read(authServiceProvider)
                          .logout();

                      if (success) {
                        // Remove token from storage
                        await storage.deleteAll();

                        // Show SnackBar with removed token
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "✅ Logout successful. Token removed: $token",
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );

                        Navigator.of(context).pop(true); // Exit app
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("❌ Logout failed. Try again."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("⚠️ No token found in storage."),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: const Text("Yes"),
                ),
              ],
            ),
          ) ??
          false;
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Doctor Appointment",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.amber,
          centerTitle: true,
        ),
        body: Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppointmentScreen()),
              );
            },
            child: const Text(
              "Get Appointment",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
