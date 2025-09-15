import 'package:dio/dio.dart';

class ApiClient {
  static Dio dio = Dio(
    BaseOptions(
      baseUrl: "http://20.20.20.37:8080/proyashospital/api/",
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ),
  );
}
