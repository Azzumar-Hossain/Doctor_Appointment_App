/*import 'package:demo_appointment/core/api_client.dart';
import 'package:demo_appointment/models/login_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  /// 🔹 Login
  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await ApiClient.dio.post(
        "login",
        queryParameters: {"email": email, "password": password},
      );

      print("📥 Login Response: ${response.data}");

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(response.data);

        // Debug
        print("📩 Raw Login Response: ${response.data}");
        print("✅ Login successful");
        print("👉 User ID: ${loginResponse.userId}");
        print("👉 Token: ${loginResponse.token}");

        // Save to secure storage
        await _storage.write(
          key: "user_id",
          value: loginResponse.userId.toString(),
        );
        await _storage.write(key: "token", value: loginResponse.token ?? "");

        return loginResponse;
      } else {
        throw Exception("❌ Login failed. Please check your server");
      }
    } on DioError catch (e) {
      if (e.type == DioErrorType.connectionError ||
          e.type == DioErrorType.unknown) {
        // No internet / DNS / socket error
        throw Exception(
          "Login failed. Please check your internet connection of your device.",
        );
      } else if (e.type == DioErrorType.badResponse) {
        // Server responded with error (4xx, 5xx)
        throw Exception("Login failed. Please check your server");
      } else {
        throw Exception("Login failed");
      }
    } catch (e) {
      throw Exception("Login failed. Unexpected error: $e");
    }
  }

  /// 🔹 Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: "token");
  }

  /// 🔹 Get stored userId
  Future<String?> getUserId() async {
    return await _storage.read(key: "user_id");
  }

  /// 🔹 Logout
  Future<bool> logout() async {
    try {
      final userId = await getUserId();
      final token = await getToken();

      if (userId == null || token == null || token.isEmpty) {
        print("⚠️ No token found in storage.");
        return false;
      }

      print("🚀 Logging out...");
      print("👉 Sending userId=$userId, token=$token");

      final response = await ApiClient.dio.post(
        "loggout",
        queryParameters: {"user_id": int.parse(userId), "api_token": token},
      );

      print("🔗 Logout Request URL: ${response.realUri}");
      print("📥 Logout Response: ${response.data}");

      if (response.statusCode == 200 && response.data['status'] == true) {
        print("✅ Logout successful. Clearing storage...");
        await _storage.deleteAll();
        return true;
      } else {
        print("❌ Logout failed. Status code: ${response.statusCode}");
        return false;
      }
    } on DioError catch (e) {
      print("🔥 Dio Logout Error: ${e.response?.data ?? e.message}");
      return false;
    }
  }
}*/

import 'package:demo_appointment/core/api_client.dart';
import 'package:demo_appointment/models/login_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  /// 🔹 Login
  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await ApiClient.dio.post(
        "login",
        queryParameters: {"email": email, "password": password},
      );

      print("📥 Login Response: ${response.data}");

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(response.data);

        print("📩 Raw Login Response: ${response.data}");
        print("✅ Login successful");
        print("👉 User ID: ${loginResponse.userId}");
        print("👉 Token: ${loginResponse.token}");

        // ✅ Save to secure storage
        await _storage.write(
          key: "user_id",
          value: loginResponse.userId.toString(),
        );
        await _storage.write(key: "token", value: loginResponse.token ?? "");

        return loginResponse;
      } else {
        throw Exception("❌ Login failed. Please check your server.");
      }
    } on DioError catch (e) {
      if (e.type == DioErrorType.connectionError ||
          e.type == DioErrorType.unknown) {
        throw Exception(
          "❌ Login failed. Please check your internet connection.",
        );
      } else if (e.type == DioErrorType.badResponse) {
        throw Exception("❌ Login failed. Please check your server.");
      } else {
        throw Exception("❌ Login failed.");
      }
    } catch (e) {
      throw Exception("❌ Unexpected error: $e");
    }
  }

  /// 🔑 Add stored token to a request payload
  Future<Map<String, dynamic>> addTokenToPayload(
    Map<String, dynamic> payload, {
    String key = "token",
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception("❌ No token found. User may need to log in again.");
    }

    payload[key] = token;
    return payload;
  }

  /// 🔹 Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: "token");
  }

  /// 🔹 Get stored userId
  Future<String?> getUserId() async {
    return await _storage.read(key: "user_id");
  }

  /// 🔹 Logout
  Future<bool> logout() async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        print("⚠️ No userId found in storage.");
        return false;
      }

      // ✅ Build payload and add token
      final payload = await addTokenToPayload({
        "user_id": int.parse(userId),
      }, key: "api_token");

      print("🚀 Logging out...");
      print("📤 Payload: $payload");

      final response = await ApiClient.dio.post(
        "loggout",
        queryParameters: payload,
      );

      print("🔗 Logout Request URL: ${response.realUri}");
      print("📥 Logout Response: ${response.data}");

      if (response.statusCode == 200 && response.data['status'] == true) {
        print("✅ Logout successful. Clearing storage...");
        await _storage.deleteAll();
        return true;
      } else {
        print("❌ Logout failed. Status code: ${response.statusCode}");
        return false;
      }
    } on DioError catch (e) {
      print("🔥 Dio Logout Error: ${e.response?.data ?? e.message}");
      return false;
    } catch (e) {
      print("🔥 Logout Exception: $e");
      return false;
    }
  }
}
