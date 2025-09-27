import 'package:demo_appointment/data/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:demo_appointment/core/api_client.dart';

class AppointmentService {
  final AuthService _authService = AuthService();

  /// 🔹 Submit Appointment
  Future<Map<String, dynamic>> submitAppointment({
    required String patientType,
    required String name,
    required String mobileNumber,
    required String patientIdNo,
    required String age,
    required String ageParameter,
    required String presentAddress,
    required int sex,
    required String date,
    required int doctorId,
    required int scheduleId,
    required String time,
    required int serialNum,
    required int status,
    required int accountId,
    required int paymentWayId,
    required int invoiceType,
    required int tokenNo,
    required Map<String, dynamic> feeData, // <-- from doctor fees API
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception("❌ No token found. Please login again.");
      }

      // Extract fee IDs + amount from feeData
      final doctorFeeId = feeData['id'];
      final doctorFeesId = feeData['id'];
      final doctorFee = feeData['amount'];

      final response = await ApiClient.dio.post(
        "employee/online_appointment_store",
        queryParameters: {
          "patient_type": patientType,
          "name": name,
          "patient_id": "",
          "mobile_number": mobileNumber,
          "patient_id_no": patientIdNo,
          "age": age,
          "age_parameter": ageParameter,
          "present_address": presentAddress,
          "sex": sex,
          "date": date,
          "doctor_id": doctorId,
          "schedule_id": scheduleId,
          "time": time,
          "serial_num": serialNum,
          "status": status,
          "doctor_fee_id": doctorFeeId,
          "doctor_fee": doctorFee,
          "doctor_fees_id": doctorFeesId,
          "payable_amount": doctorFee,
          "payment_way_id": paymentWayId,
          "invoice_type": invoiceType,
          "account_id": accountId,
          "token": token, // 🔑 token from storage
        },
      );

      print("📥 API Response Status: ${response.statusCode}");
      print("📥 API Raw Response: ${response.data}");

      print("📥 Submit Appointment Response: ${response.data}");

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception("❌ Failed to submit appointment");
      }
    } on DioError catch (e) {
      print("🔥 Dio Error: ${e.response?.data ?? e.message}");
      rethrow;
    } catch (e) {
      print("🔥 Submit Error: $e");
      rethrow;
    }
  }
}
