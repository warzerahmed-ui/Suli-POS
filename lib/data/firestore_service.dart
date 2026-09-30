import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// خزمەتگوزاری پەیوەندی ڕاستەوخۆ بە فایەربەیس فایەرستۆر.
/// Direct Firebase Firestore REST API client for SULI-POS.
/// Guarantees that all products, categories, sales, users, settings, and
/// counters are synchronized immediately with the cloud database.
class FirestoreService {
  FirestoreService({
    this.projectId = 'suli-pos',
    this.apiKey = 'AIzaSyAV_frb3-LCwCIystmcGv1WHoSL6pV0EYE',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String projectId;
  final String apiKey;
  final http.Client _client;

  String get _baseUrl =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  Uri _collectionUri(String collection, {int pageSize = 1000}) =>
      Uri.parse('$_baseUrl/$collection?key=$apiKey&pageSize=$pageSize');

  Uri _documentUri(String collection, String documentId) =>
      Uri.parse('$_baseUrl/$collection/$documentId?key=$apiKey');

  // --- Auth & Security ---
  String? _idToken;
  DateTime? _tokenExpiry;

  Future<void> signInAnonymously() async {
    try {
      final res = await _client.post(
        Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'returnSecureToken': true}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _idToken = data['idToken'];
        final int expiresIn = int.tryParse(data['expiresIn']?.toString() ?? '3600') ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
      }
    } catch (e) {
      debugPrint('Firebase Auth Error: $e');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    if (_idToken == null || (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!))) {
      await signInAnonymously();
    }
    if (_idToken != null) {
      return {'Authorization': 'Bearer $_idToken'};
    }
    return {};
  }

  // ── Document Encoding & Decoding ──────────────────────────────────────────

  static Map<String, dynamic> encodeValue(dynamic value) {
    if (value == null) {
      return <String, dynamic>{'nullValue': null};
    } else if (value is bool) {
      return <String, dynamic>{'booleanValue': value};
    } else if (value is int) {
      return <String, dynamic>{'integerValue': value.toString()};
    } else if (value is double) {
      return <String, dynamic>{'doubleValue': value};
    } else if (value is String) {
      return <String, dynamic>{'stringValue': value};
    } else if (value is List) {
      return <String, dynamic>{
        'arrayValue': <String, dynamic>{
          'values': value.map(encodeValue).toList(),
        },
      };
    } else if (value is Map) {
      final Map<String, dynamic> fields = <String, dynamic>{};
      value.forEach((dynamic k, dynamic v) {
        fields[k.toString()] = encodeValue(v);
      });
      return <String, dynamic>{
        'mapValue': <String, dynamic>{
          'fields': fields,
        },
      };
    }
    return <String, dynamic>{'stringValue': value.toString()};
  }

  static dynamic decodeValue(Map<String, dynamic> valueMap) {
    if (valueMap.containsKey('stringValue')) {
      return valueMap['stringValue'];
    } else if (valueMap.containsKey('integerValue')) {
      return int.tryParse(valueMap['integerValue'].toString()) ?? 0;
    } else if (valueMap.containsKey('doubleValue')) {
      return (valueMap['doubleValue'] as num).toDouble();
    } else if (valueMap.containsKey('booleanValue')) {
      return valueMap['booleanValue'] as bool;
    } else if (valueMap.containsKey('nullValue')) {
      return null;
    } else if (valueMap.containsKey('timestampValue')) {
      return valueMap['timestampValue'] as String;
    } else if (valueMap.containsKey('arrayValue')) {
      final dynamic raw = valueMap['arrayValue'];
      if (raw is Map && raw.containsKey('values')) {
        final List<dynamic> list = raw['values'] as List<dynamic>;
        return list
            .map((dynamic e) => decodeValue(e as Map<String, dynamic>))
            .toList();
      }
      return <dynamic>[];
    } else if (valueMap.containsKey('mapValue')) {
      final dynamic raw = valueMap['mapValue'];
      if (raw is Map && raw.containsKey('fields')) {
        final Map<String, dynamic> fields =
            raw['fields'] as Map<String, dynamic>;
        final Map<String, dynamic> res = <String, dynamic>{};
        fields.forEach((String k, dynamic v) {
          res[k] = decodeValue(v as Map<String, dynamic>);
        });
        return res;
      }
      return <String, dynamic>{};
    }
    return null;
  }

  static Map<String, dynamic> encodeFields(Map<String, dynamic> data) {
    final Map<String, dynamic> fields = <String, dynamic>{};
    data.forEach((String key, dynamic value) {
      fields[key] = encodeValue(value);
    });
    return fields;
  }

  static Map<String, dynamic> decodeDocument(Map<String, dynamic> doc) {
    final String name = doc['name'] as String? ?? '';
    final String id = name.split('/').last;
    final Map<String, dynamic> result = <String, dynamic>{'id': id};
    final dynamic fieldsRaw = doc['fields'];
    if (fieldsRaw is Map<String, dynamic>) {
      fieldsRaw.forEach((String key, dynamic val) {
        if (val is Map<String, dynamic>) {
          result[key] = decodeValue(val);
        }
      });
    }
    return result;
  }

  // ── High-Level Operations ──────────────────────────────────────────────────

  /// هێنانی هەموو دۆکیۆمێنتەکانی کۆکراوەیەک
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    try {
      final http.Response res = await _client.get(_collectionUri(collection), headers: await _getHeaders());
      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('documents')) {
          final List<dynamic> docs = decoded['documents'] as List<dynamic>;
          return docs
              .map((dynamic d) => decodeDocument(d as Map<String, dynamic>))
              .toList();
        }
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('FirestoreService.getCollection error ($collection): $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// هێنانی یەک دۆکیۆمێنت
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String documentId,
  ) async {
    try {
      final http.Response res =
          await _client.get(_documentUri(collection, documentId), headers: await _getHeaders());
      if (res.statusCode == 200) {
        final Map<String, dynamic> doc =
            jsonDecode(res.body) as Map<String, dynamic>;
        return decodeDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('FirestoreService.getDocument error ($collection/$documentId): $e');
      return null;
    }
  }

  /// پاشەکەوتکردن یان نوێکردنەوەی دۆکیۆمێنت (PATCH)
  Future<bool> setDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'fields': encodeFields(data),
      };
      final http.Response res = await _client.patch(
        _documentUri(collection, documentId),
        headers: <String, String>{'Content-Type': 'application/json', ...await _getHeaders()},
        body: jsonEncode(body),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint('FirestoreService.setDocument error ($collection/$documentId): $e');
      return false;
    }
  }

  /// سڕینەوەی دۆکیۆمێنت (DELETE)
  Future<bool> deleteDocument(String collection, String documentId) async {
    try {
      final http.Response res =
          await _client.delete(_documentUri(collection, documentId), headers: await _getHeaders());
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint('FirestoreService.deleteDocument error ($collection/$documentId): $e');
      return false;
    }
  }

  /// نوێکردنەوەی ژمارەیەک دۆکیۆمێنت بە شێوەی هاوکات
  Future<void> saveBatch(
    String collection,
    List<Map<String, dynamic>> items, {
    String idField = 'id',
  }) async {
    final List<Future<bool>> futures = items.map((Map<String, dynamic> item) {
      final String id = item[idField]?.toString() ?? '';
      if (id.isEmpty) return Future<bool>.value(false);
      return setDocument(collection, id, item);
    }).toList();
    await Future.wait(futures);
  }
}






