import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/config/config_manager.dart';
import '../../core/models/listing_filters.dart';
import '../models/lead_model.dart';
import '../models/offer_model.dart';
import '../models/stock_model.dart';
import 'auth_service.dart';

class CRMService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ConfigManager.baseUrl));
  final AuthService _auth = AuthService();

  Future<Map<String, dynamic>> fetchData({
    required String endpoint,
    int page = 1,
    int limit = 10,
    String search = "",
    ListingFilters filters = ListingFilters.empty,
  }) async {
    try {
      final token = await _auth.getToken();
      final queryParameters = _buildQueryParameters(
        page: page,
        limit: limit,
        search: search,
        filters: filters,
      );

      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final payload = response.data as Map<String, dynamic>;
        final meta = (payload['meta'] as Map<String, dynamic>?) ?? const {};
        final summary =
            (payload['summary'] as Map<String, dynamic>?) ?? const {};
        final items = ((payload['data'] as List?) ?? const [])
            .map((item) => LeadModel.fromJson(item))
            .toList();

        return {
          "items": items,
          "meta": meta,
          "summary": summary,
          "total": meta['total'] ?? meta['totalItems'] ?? 0,
          "lastPage": meta['last_page'] ?? meta['totalPages'] ?? 1,
          "hasNextPage": meta['hasNextPage'] == true,
        };
      }
      return {
        "items": const <LeadModel>[],
        "meta": const <String, dynamic>{},
        "summary": const <String, dynamic>{},
        "total": 0,
        "lastPage": 1,
        "hasNextPage": false,
      };
    } catch (e) {
      debugPrint("API Error at $endpoint: $e");
      return {
        "items": const <LeadModel>[],
        "meta": const <String, dynamic>{},
        "summary": const <String, dynamic>{},
        "total": 0,
        "lastPage": 1,
        "hasNextPage": false,
      };
    }
  }

  Future<Map<String, dynamic>> fetchOffers({
    int page = 1,
    int limit = 10,
    String search = "",
    ListingFilters filters = ListingFilters.empty,
  }) async {
    try {
      final token = await _auth.getToken();
      final queryParameters = _buildQueryParameters(
        page: page,
        limit: limit,
        search: search,
        filters: filters,
      );

      final response = await _dio.get(
        '/offers',
        queryParameters: queryParameters,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final payload = response.data as Map<String, dynamic>;
        final meta = (payload['meta'] as Map<String, dynamic>?) ?? const {};
        final summary =
            (payload['summary'] as Map<String, dynamic>?) ?? const {};
        final items = ((payload['data'] as List?) ?? const [])
            .map((item) => OfferModel.fromJson(item))
            .toList();

        return {
          "items": items,
          "meta": meta,
          "summary": summary,
          "total": meta['total'] ?? meta['totalItems'] ?? 0,
          "lastPage": meta['last_page'] ?? meta['totalPages'] ?? 1,
          "hasNextPage": meta['hasNextPage'] == true,
        };
      }

      return {
        "items": const <OfferModel>[],
        "meta": const <String, dynamic>{},
        "summary": const <String, dynamic>{},
        "total": 0,
        "lastPage": 1,
        "hasNextPage": false,
      };
    } catch (e) {
      debugPrint("Offers API Error: $e");
      return {
        "items": const <OfferModel>[],
        "meta": const <String, dynamic>{},
        "summary": const <String, dynamic>{},
        "total": 0,
        "lastPage": 1,
        "hasNextPage": false,
      };
    }
  }

  Future<Map<String, dynamic>> fetchStock({
    int page = 1,
    int limit = 10,
    String search = "",
    ListingFilters filters = ListingFilters.empty,
  }) async {
    try {
      final token = await _auth.getToken();
      final queryParameters = _buildQueryParameters(
        page: page,
        limit: limit,
        search: search,
        filters: filters,
      );

      final response = await _dio.get(
        '/stock',
        queryParameters: queryParameters,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final payload = response.data as Map<String, dynamic>;
        final meta = (payload['meta'] as Map<String, dynamic>?) ?? const {};
        final summary =
            (payload['summary'] as Map<String, dynamic>?) ?? const {};
        final items = ((payload['data'] as List?) ?? const [])
            .map((item) => StockModel.fromJson(item))
            .toList();

        return {
          "items": items,
          "meta": meta,
          "summary": summary,
          "total": meta['total'] ?? meta['totalItems'] ?? 0,
          "lastPage": meta['last_page'] ?? meta['totalPages'] ?? 1,
          "hasNextPage": meta['hasNextPage'] == true,
        };
      }

      return {
        "items": const <StockModel>[],
        "meta": const <String, dynamic>{},
        "summary": const <String, dynamic>{},
        "total": 0,
        "lastPage": 1,
        "hasNextPage": false,
      };
    } catch (e) {
      debugPrint("Stock API Error: $e");
      return {
        "items": const <StockModel>[],
        "meta": const <String, dynamic>{},
        "summary": const <String, dynamic>{},
        "total": 0,
        "lastPage": 1,
        "hasNextPage": false,
      };
    }
  }

  Future<StockDetailModel?> fetchStockDetail(String stockId) async {
    try {
      final token = await _auth.getToken();
      final response = await _dio.get(
        '/stock/$stockId',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final payload = response.data as Map<String, dynamic>;
        return StockDetailModel.fromJson(
          (payload['data'] as Map<String, dynamic>?) ?? const {},
        );
      }
      return null;
    } catch (e) {
      debugPrint("Stock detail API Error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> createStock({
    required Map<String, dynamic> payload,
    required List<String> filePaths,
    bool isPublic = true,
  }) async {
    try {
      final token = await _auth.getToken();
      final formData = FormData();
      final cleanedPayload = Map<String, dynamic>.fromEntries(
        payload.entries.where(
          (entry) =>
              entry.value != null &&
              (entry.value is! String || (entry.value as String).trim().isNotEmpty),
        ),
      );

      formData.fields.add(MapEntry('payload', jsonEncode(cleanedPayload)));
      formData.fields.add(MapEntry('isPublic', isPublic.toString()));

      for (final path in filePaths) {
        formData.files.add(
          MapEntry(
            'files[]',
            await MultipartFile.fromFile(
              path,
              filename: path.split('/').last,
            ),
          ),
        );
      }

      final response = await _dio.post(
        '/stock',
        data: formData,
        options: Options(
          validateStatus: (status) => status != null && status < 600,
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      final payloadResponse = response.data as Map<String, dynamic>? ?? const {};
      debugPrint(
        "Create stock response: status=${response.statusCode}, body=$payloadResponse",
      );

      return {
        'success':
            (response.statusCode == 200 || response.statusCode == 201) &&
            payloadResponse['success'] == true,
        'message': payloadResponse['message']?.toString() ?? 'Failed to create stock.',
        'data': payloadResponse['data'],
      };
    } catch (e) {
      debugPrint("Create stock API Error: $e");
      return {
        'success': false,
        'message': 'Unable to create stock right now.',
      };
    }
  }

  Future<StockGalleryData?> fetchStockGallery(String stockId) async {
    try {
      final token = await _auth.getToken();
      final response = await _dio.get(
        '/stock/$stockId/images',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return StockGalleryData.fromJson(
          response.data as Map<String, dynamic>? ?? const {},
        );
      }
      return null;
    } catch (e) {
      debugPrint("Stock gallery API Error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> uploadStockImages({
    required String stockId,
    required List<String> filePaths,
    bool isPublic = true,
  }) async {
    try {
      final token = await _auth.getToken();
      final formData = FormData();

      formData.fields.add(MapEntry('isPublic', isPublic.toString()));

      for (final path in filePaths) {
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(
              path,
              filename: path.split('/').last,
            ),
          ),
        );
      }

      final response = await _dio.post(
        '/stock/$stockId/images',
        data: formData,
        options: Options(
          validateStatus: (status) => status != null && status < 600,
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      final payloadResponse = response.data as Map<String, dynamic>? ?? const {};
      debugPrint(
        "Upload stock images response: status=${response.statusCode}, body=$payloadResponse",
      );
      return {
        'success':
            (response.statusCode == 200 || response.statusCode == 201) &&
            payloadResponse['success'] == true,
        'message':
            payloadResponse['message']?.toString() ?? 'Failed to upload gallery images.',
      };
    } catch (e) {
      debugPrint("Stock image upload API Error: $e");
      return {
        'success': false,
        'message': 'Unable to upload images right now.',
      };
    }
  }

  Future<Map<String, dynamic>> updateStockGallery({
    required String stockId,
    String? featuredImageId,
    List<String>? orderedImageIds,
  }) async {
    try {
      final token = await _auth.getToken();
      final payload = <String, dynamic>{};

      if (featuredImageId != null && featuredImageId.trim().isNotEmpty) {
        payload['featuredImageId'] = featuredImageId.trim();
      }
      if (orderedImageIds != null && orderedImageIds.isNotEmpty) {
        payload['orderedImageIds'] = orderedImageIds;
      }

      final response = await _dio.patch(
        '/stock/$stockId/images',
        data: payload,
        options: Options(
          validateStatus: (status) => status != null && status < 600,
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      final payloadResponse = response.data as Map<String, dynamic>? ?? const {};
      return {
        'success': response.statusCode == 200 && payloadResponse['success'] == true,
        'message':
            payloadResponse['message']?.toString() ?? 'Unable to update gallery right now.',
      };
    } catch (e) {
      debugPrint("Stock gallery update API Error: $e");
      return {
        'success': false,
        'message': 'Unable to update gallery right now.',
      };
    }
  }

  Future<Map<String, dynamic>> deleteStockImage({
    required String stockId,
    required String imageId,
  }) async {
    try {
      final token = await _auth.getToken();
      final response = await _dio.delete(
        '/stock/$stockId/images/$imageId',
        options: Options(
          validateStatus: (status) => status != null && status < 600,
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      final payloadResponse = response.data as Map<String, dynamic>? ?? const {};
      return {
        'success': response.statusCode == 200 && payloadResponse['success'] == true,
        'message':
            payloadResponse['message']?.toString() ??
            'Unable to delete image right now.',
        'featuredImageId': payloadResponse['featuredImageId']?.toString(),
      };
    } catch (e) {
      debugPrint("Stock image delete API Error: $e");
      return {
        'success': false,
        'message': 'Unable to delete image right now.',
      };
    }
  }

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    try {
      final token = await _auth.getToken();
      final response = await _dio.get(
        '/dashboard/stats',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final payload = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'stats': (payload['stats'] as Map<String, dynamic>?) ?? const {},
          'summary': (payload['summary'] as Map<String, dynamic>?) ?? const {},
          'generatedAt': payload['generatedAt']?.toString(),
          'message': payload['message']?.toString(),
        };
      }

      return {
        'success': false,
        'stats': const <String, dynamic>{},
        'summary': const <String, dynamic>{},
        'generatedAt': null,
      };
    } catch (e) {
      debugPrint("Dashboard stats API Error: $e");
      return {
        'success': false,
        'stats': const <String, dynamic>{},
        'summary': const <String, dynamic>{},
        'generatedAt': null,
      };
    }
  }

  Future<Map<String, dynamic>> fetchStockPrefill({
    required String registrationNumber,
    required int mileage,
  }) async {
    try {
      final token = await _auth.getToken();
      final response = await _dio.post(
        '/stock/prefill',
        data: {
          "registrationNumber": registrationNumber,
          "mileage": mileage,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final payload = response.data as Map<String, dynamic>? ?? const {};
      final success = response.statusCode == 200 && payload['success'] == true;

      return {
        'success': success,
        'message': payload['message']?.toString(),
        'data': payload['data'],
      };
    } catch (e) {
      debugPrint("Stock prefill API Error: $e");
      return {
        'success': false,
        'message': 'Unable to find vehicle',
      };
    }
  }

  Map<String, dynamic> _buildQueryParameters({
    required int page,
    required int limit,
    required String search,
    required ListingFilters filters,
  }) {
    final queryParameters = <String, dynamic>{"page": page, "limit": limit};

    if (search.trim().isNotEmpty) {
      queryParameters["search"] = search.trim();
    }
    if (filters.dateFrom != null) {
      queryParameters["dateFrom"] = _formatDate(filters.dateFrom!);
    }
    if (filters.dateTo != null) {
      queryParameters["dateTo"] = _formatDate(filters.dateTo!);
    }
    if (filters.mileageMin != null) {
      queryParameters["mileageMin"] = filters.mileageMin;
    }
    if (filters.mileageMax != null) {
      queryParameters["mileageMax"] = filters.mileageMax;
    }
    if (filters.priceMin != null) {
      queryParameters["priceMin"] = filters.priceMin;
    }
    if (filters.priceMax != null) {
      queryParameters["priceMax"] = filters.priceMax;
    }

    return queryParameters;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "${date.year}-$month-$day";
  }
}
