import 'package:d_table_delegate_system/config/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:developer' as dev;

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;

  DioClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.requestTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = Hive.box('settingsBox').get('auth_token');
          if (token != null) options.headers['Authorization'] = 'Bearer $token';

          // 🔥 Request Print karega
          print("🚀 SENDING REQUEST: [${options.method}] ${options.path}");
          if (options.data != null) {
            // FormData ko jsonEncode mat karo — woh crash karta hai!
            if (options.data is FormData) {
              print("📦 PAYLOAD: [FormData / multipart upload]");
            } else {
              try {
                print("📦 PAYLOAD: ${jsonEncode(options.data)}");
              } catch (_) {
                print("📦 PAYLOAD: [non-serializable data]");
              }
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // 🔥 Success Response Print karega
          print("✅ RESPONSE RECEIVED: [${response.statusCode}] ${response.requestOptions.path}");
          dev.log("📄 DATA: ${jsonEncode(response.data)}"); // Bada data log karne ke liye dev.log
          return handler.next(response);
        },
        onError: (DioException err, handler) {
          // 🔥 Error Print karega
          print("❌ API ERROR: [${err.response?.statusCode}] ${err.requestOptions.path}");
          print("⚠️ MESSAGE: ${err.response?.data?['message'] ?? err.message}");

          if (err.response?.statusCode == 401) {
            Hive.box('settingsBox').clear();
          }
          return handler.next(err);
        }
    ));
  }
  factory DioClient() => _instance;
}
