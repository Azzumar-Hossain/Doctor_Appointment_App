class LoginResponse {
  final bool status;
  final String token;
  final String? message;
  final int companyId;
  final int userId;
  final bool isActive;

  LoginResponse({
    required this.status,
    required this.token,
    this.message,
    required this.companyId,
    required this.userId,
    required this.isActive,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'] ?? false,
      token: json['token'] ?? "",
      message: json['message'],
      companyId: json['company_id'] ?? 0, // ✅ fixed
      userId: json['user_id'] ?? 0, // ✅ fixed
      isActive: json['is_active'] ?? false,
    );
  }
}
