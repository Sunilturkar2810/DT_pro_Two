import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

class DelegationService {
  final Dio _dio = DioClient().dio;

  // 1. GET ALL (READ)
  Future<List<dynamic>> getAllDelegations() async {
    try {
      final response = await _dio.get(ApiConstants.delegations);
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  // 2. GET BY ID (READ)
  Future<Map<String, dynamic>> getDelegationById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.delegations}/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // 3. CREATE
  Future<Map<String, dynamic>> createDelegation(
      Map<String, dynamic> data) async {
    try {
      final response =
      await _dio.post(ApiConstants.delegations, data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // 4. UPDATE (PATCH)
  Future<void> updateDelegation(String id, Map<String, dynamic> data) async {
    try {
      await _dio.patch('${ApiConstants.delegations}/$id', data: data);
    } catch (e) {
      rethrow;
    }
  }

  // 5. DELETE
  // ✅ ROOT CAUSE: DioClient mein globally 'Content-Type: application/json' set hai.
  // Backend DELETE pe body expect karta hai jab Content-Type json ho.
  // Fix: Content-Type override karke 'text/plain' karo — body ki zarurat nahi padegi.
  Future<void> deleteDelegation(String id) async {
    try {
      final String path = '${ApiConstants.delegations}/$id';

      final response = await _dio.delete(
        path,
        options: Options(
          headers: {
            'Content-Type': 'text/plain', // JSON body required nahi hogi
          },
        ),
      );

      print('✅ DELETE SUCCESS: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ DELETE ERROR: ${e.response?.statusCode}');
      print('❌ BODY: ${e.response?.data}');
      rethrow;
    }
  }

  // 6. ADD REMARK (POST)
  Future<void> addRemark(String id, String remark, String userId) async {
    try {
      await _dio.post(
        '${ApiConstants.delegations}/$id/remarks',
        data: {
          "remark": remark,
          "userId": userId,    // ✅ Backend expects "userId" not "assignedUserId"
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // 7. UPDATE REMARK (PATCH)
  Future<void> updateRemark(String delegationId, String remarkId, String remark) async {
    try {
      await _dio.patch(
        '${ApiConstants.delegations}/$delegationId/remarks/$remarkId',
        data: {"remark": remark},
      );
    } catch (e) {
      rethrow;
    }
  }

  // 8. DELETE REMARK (DELETE)
  Future<void> deleteRemark(String delegationId, String remarkId) async {
    try {
      await _dio.delete(
        '${ApiConstants.delegations}/$delegationId/remarks/$remarkId',
        options: Options(headers: {'Content-Type': 'text/plain'}),
      );
    } catch (e) {
      rethrow;
    }
  }
  // 9. UPLOAD FILE → returns public URL string
  // NOTE: Fresh Dio used here (no interceptor) to avoid FormData jsonEncode crash
  Future<String> uploadFile(File file, {String folder = 'general'}) async {
    try {
      final fileName = file.path.split('/').last.split('\\').last;

      // Clean Dio — no logging interceptor that breaks FormData
      final uploadDio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.requestTimeout,
      ));

      // Auth token manually add karo
      final token = Hive.box('settingsBox').get('auth_token');
      final extraHeaders = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      print('📤 Uploading file: $fileName to folder: $folder');

      final response = await uploadDio.post(
        '${ApiConstants.delegations}/upload?folder=$folder',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: extraHeaders,
        ),
      );

      final url = response.data['url'] as String;
      print('✅ Upload success: $url');
      return url;
    } catch (e) {
      print('❌ Upload error: $e');
      rethrow;
    }
  }

  // 10. UPDATE CHECKLIST STATUS (PATCH)
  Future<void> updateChecklistStatus(String delegationId, String checklistId, String status) async {
    try {
      await _dio.patch(
        '${ApiConstants.delegations}/$delegationId/checklist/$checklistId',
        data: {"status": status},
      );
    } catch (e) {
      rethrow;
    }
  }
}
