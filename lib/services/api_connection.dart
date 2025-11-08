import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiConnection {
  static const String baseUrl = 'https://adhapi-test.gazi.edu.tr';
  
  // HTTP client instance
  static final http.Client _client = http.Client();
  
  // Headers - Gerçek request header'larına göre güncellendi
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
    'isshowmessage': 'false',
    'Origin': 'https://adh-test.gazi.edu.tr',
    'Referer': 'https://adh-test.gazi.edu.tr/',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36',
  };

  // API endpoint'leri - Gerçek çalışan endpoint'ler
  static const String _clientInsert = '/Client/ClientInsert';  // ✅ Kullanıcı ekleme (randevu oluşturma)
  static const String _appointmentCancel = '/Appointment/Cancel';  // Randevu iptal
  static const String _kpsQuery = '/General/GetKps';  // ✅ KPS kimlik doğrulama
  static const String _advisors = '/Section/GetSectionAllWithDivision';  // ✅ ÇALIŞIYOR (danışman listesi)
  static const String _advisorSchedule = '/AdvisorSchedule/GetScheduleByAdvisorId';  // 🆕 Danışman programı
  static const String _advisorById = '/Advisor/GetAdvisorId';  // 🆕 Danışman detay bilgisi
  static const String _appointments = '/Client/GetAppointments';  // Tahmin

  /// Müşteri/Randevu oluşturma  
  static Future<Map<String, dynamic>> createAppointment({
    required String tcKimlikNo,
    required String birthDate,
    required String securityCode,
    required String advisorId,
    required String timeSlot,
  }) async {
    try {
      // Önce KPS'den kullanıcı bilgilerini al
      UserInfo kpsResult;
      try {
        kpsResult = await getUserInfo(tcKimlikNo: tcKimlikNo, birthDate: birthDate);
        if (kpsResult.isError) {
          // KPS hatası olsa bile randevu oluşturmaya devam et
          if (kDebugMode) {
            print('⚠️ KPS Error ama devam ediyoruz: ${kpsResult.errorMessage}');
          }
        }
      } catch (e) {
        // KPS hatası durumunda boş verilerle devam et
        if (kDebugMode) {
          print('KPS Error, using empty data: $e');
        }
        kpsResult = UserInfo(
          tc: tcKimlikNo, ad: '', soyad: '', anneAd: '', babaAd: '', 
          cinsiyet: '', cinsiyetKod: '', dogumTarih: birthDate, dogumYer: '', 
          medeniHal: '', medeniHalKod: '', seriNo: '', il: '', ilcekodu: '', 
          ilkodu: '', ilce: '', mahalle: '', csbm: '', disKapiNo: '', 
          icKapiNo: '', acikAdres: '', isError: false, errorMessage: ''
        );
      }
      
      final requestUrl = '$baseUrl$_clientInsert';
      
      // Doğum tarihini ISO formatına çevir (DD.MM.YYYY'den)
      final birthDateParts = birthDate.split('.');
      final day = int.parse(birthDateParts[0]);
      final month = int.parse(birthDateParts[1]);
      final year = int.parse(birthDateParts[2]);
      final isoDate = DateTime(year, month, day).toIso8601String();

      // Gerçek API formatına göre request body - KPS'den gelen verilerle
      final requestBody = {
        'id': 0,
        'name': kpsResult.ad.isNotEmpty ? kpsResult.ad : 'Test',
        'surname': kpsResult.soyad.isNotEmpty ? kpsResult.soyad : 'User',
        'tcId': tcKimlikNo,
        'email': 'test@example.com',  // Kullanıcıdan alınacak
        'tel': '05000000000',         // Kullanıcıdan alınacak
        'address': kpsResult.acikAdres,
        'cinsiyet': kpsResult.cinsiyet.isNotEmpty ? kpsResult.cinsiyet : 'Erkek',
        'birthDate': isoDate,
      };
      
      if (kDebugMode) {
        print('=== RANDEVU OLUŞTURMA API REQUEST DEBUG ===');
        print('URL: $requestUrl');
        print('Method: POST');
        print('Headers: $_headers');
        print('Body: ${jsonEncode(requestBody)}');
        print('==========================================');
      }
      
      final response = await _client.post(
        Uri.parse(requestUrl),
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('=== API RESPONSE DEBUG ===');
        print('Status Code: ${response.statusCode}');
        print('Response Headers: ${response.headers}');
        print('Response Body: ${response.body}');
        print('==========================');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // API response kontrolü - resultType 1 = başarılı
        if (responseData['resultType'] == 1) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'Randevu başarıyla oluşturuldu',
            'data': responseData['data'],
            'appointmentNumber': responseData['data'] is Map 
                ? responseData['data']['appointmentNumber'] ?? responseData['data']['appointmentNo']
                : responseData['data']?.toString(),
          };
        } else {
          // API hatası (resultType != 1)
          return {
            'success': false,
            'message': responseData['message'] ?? 'Randevu oluşturulamadı',
            'data': responseData['data'],
            'error': 'resultType: ${responseData['resultType']}',
          };
        }
      } else {
        throw ApiException(
          'Randevu oluşturma başarısız: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('API Error: $e');
      }
      
      throw ApiException('Randevu oluşturma başarısız: $e');
    }
  }

  /// Randevu iptal sorgulama
  static Future<Map<String, dynamic>> queryAppointmentCancel({
    required String tcKimlikNo,
    required String appointmentNumber,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$_appointmentCancel'),
        headers: _headers,
        body: jsonEncode({
          'tcKimlikNo': tcKimlikNo,
          'appointmentNumber': appointmentNumber,
        }),
      );

      if (kDebugMode) {
        print('API Response Status: ${response.statusCode}');
        print('API Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException(
          'Randevu iptal sorgulama başarısız: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('API Error: $e');
      }
      
      throw ApiException('Randevu iptal sorgulama başarısız: $e');
    }
  }

  /// KPS Kimlik doğrulama ve kullanıcı bilgilerini getir
  static Future<UserInfo> getUserInfo({
    required String tcKimlikNo,
    required String birthDate,  // Doğum tarihi gerekli
  }) async {
    try {
      final requestUrl = '$baseUrl$_kpsQuery';
      
      // Doğum tarihini parse et (DD.MM.YYYY formatından)
      final birthDateParts = birthDate.split('.');
      final gun = int.parse(birthDateParts[0]);
      final ay = int.parse(birthDateParts[1]);
      final yil = int.parse(birthDateParts[2]);
      
      // KPS sorgulaması için gerekli veriler - gerçek format
      final requestBody = {
        'tc': tcKimlikNo,
        'gun': gun,
        'ay': ay,
        'yil': yil,
      };
      
      if (kDebugMode) {
        print('=== KPS API REQUEST DEBUG ===');
        print('URL: $requestUrl');
        print('Method: POST');
        print('Headers: $_headers');
        print('Body: ${jsonEncode(requestBody)}');
        print('==============================');
      }
      
      final response = await _client.post(
        Uri.parse(requestUrl),
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('=== USER INFO API RESPONSE DEBUG ===');
        print('Status Code: ${response.statusCode}');
        print('Response Headers: ${response.headers}');
        print('Response Body: ${response.body}');
        print('====================================');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // API'den gelen veriyi UserInfo modeline dönüştür
        return UserInfo.fromJson(responseData);
      } else {
        throw ApiException(
          'Kullanıcı bilgileri alınamadı: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('API Error: $e');
      }
      
      throw ApiException('Kullanıcı bilgileri alınamadı: $e');
    }
  }

  /// Danışman listesini getir
  static Future<List<Map<String, dynamic>>> getAdvisors() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$_advisors'),
        headers: _headers,
      );

      if (kDebugMode) {
        print('API Response Status: ${response.statusCode}');
        print('API Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // API response yapısını kontrol et
        if (responseData['data'] is List) {
          final List<dynamic> data = responseData['data'];
          return data.cast<Map<String, dynamic>>();
        } else if (responseData['data'] is Map && responseData['data']['unites'] is List) {
          // Nested yapı: data.unites içindeki advisors'ları topla
          final List<Map<String, dynamic>> allAdvisors = [];
          for (var unit in responseData['data']['unites']) {
            if (unit['advisors'] is List) {
              for (var advisor in unit['advisors']) {
                allAdvisors.add(advisor as Map<String, dynamic>);
              }
            }
          }
          return allAdvisors;
        } else {
          return [];
        }
      } else {
        throw ApiException(
          'Danışman listesi alınamadı: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('API Error: $e');
      }
      
      throw ApiException('Danışman listesi alınamadı: $e');
    }
  }

  /// Danışman programını getir
  static Future<List<Map<String, dynamic>>> getAdvisorSchedule({
    required int advisorId,
    required String time,
    int advisorUserId = 0,
    int status = 0,
  }) async {
    try {
      final requestBody = {
        'advisorId': advisorId,
        'advisorUserId': advisorUserId,
        'time': time,
        'status': status,
      };

      if (kDebugMode) {
        print('=== ADVISOR SCHEDULE API REQUEST DEBUG ===');
        print('URL: $baseUrl$_advisorSchedule');
        print('Method: POST');
        print('Headers: $_headers');
        print('Body: ${jsonEncode(requestBody)}');
        print('=========================================');
      }

      final response = await _client.post(
        Uri.parse('$baseUrl$_advisorSchedule'),
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('=== ADVISOR SCHEDULE API RESPONSE DEBUG ===');
        print('Status Code: ${response.statusCode}');
        print('Response Headers: ${response.headers}');
        print('Response Body: ${response.body}');
        print('==========================================');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['resultType'] == 1 && responseData['data'] is List) {
          final List<dynamic> data = responseData['data'];
          return data.cast<Map<String, dynamic>>();
        } else {
          throw ApiException(
            responseData['message'] ?? 'Danışman programı alınamadı',
            response.statusCode,
          );
        }
      } else {
        throw ApiException(
          'Danışman programı alınamadı: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('API Error: $e');
      }
      
      throw ApiException('Danışman programı alınamadı: $e');
    }
  }

  /// Danışman detay bilgisini getir
  static Future<Map<String, dynamic>> getAdvisorById(int advisorId) async {
    try {
      if (kDebugMode) {
        print('=== ADVISOR BY ID API REQUEST DEBUG ===');
        print('URL: $baseUrl$_advisorById/$advisorId');
        print('Method: GET');
        print('Headers: $_headers');
        print('======================================');
      }

      final response = await _client.get(
        Uri.parse('$baseUrl$_advisorById/$advisorId'),
        headers: _headers,
      );

      if (kDebugMode) {
        print('=== ADVISOR BY ID API RESPONSE DEBUG ===');
        print('Status Code: ${response.statusCode}');
        print('Response Headers: ${response.headers}');
        print('Response Body: ${response.body}');
        print('=======================================');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['resultType'] == 1 && responseData['data'] != null) {
          return responseData['data'] as Map<String, dynamic>;
        } else {
          throw ApiException(
            responseData['message'] ?? 'Danışman bilgisi alınamadı',
            response.statusCode,
          );
        }
      } else {
        throw ApiException(
          'Danışman bilgisi alınamadı: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('API Error: $e');
      }
      
      throw ApiException('Danışman bilgisi alınamadı: $e');
    }
  }

  /// Danışman randevularını getir
  static Future<List<Map<String, dynamic>>> getAdvisorAppointments({
    required String advisorId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$_appointments?advisorId=$advisorId&startDate=$startDate&endDate=$endDate'),
        headers: _headers,
      );

      if (kDebugMode) {
        print('API Response Status: ${response.statusCode}');
        print('API Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw ApiException(
          'Randevu listesi alınamadı: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('API Error: $e');
      }
      
      throw ApiException('Randevu listesi alınamadı: $e');
    }
  }


  /// API endpoint'leri test etmek için
  static Future<void> testEndpoints() async {
    // Farklı base URL'leri test et
    final baseUrls = [
      'https://adhapi-test.gazi.edu.tr',  // Mevcut API
      'https://adh-test.gazi.edu.tr',     // Yeni keşfedilen frontend
    ];
    
    final testEndpoints = [
      // Bulduğunuz gerçek endpoint'ler
      '/Client/ClientInsert',
      '/General/GetKps',
      '/Section/GetSectionAllWithDivision',
      '/Language/GetLanguageAll',
      
      // Tahmin edilen ek endpoint'ler
      '/Client/GetClientAll',
      '/Client/ClientUpdate',
      '/Client/ClientDelete',
      '/Appointment/GetAppointmentAll',
      '/Appointment/Create',
      '/Appointment/Cancel',
    ];
    
    for (String baseUrl in baseUrls) {
      if (kDebugMode) {
        print('=== BASE URL TEST: $baseUrl ===');
      }
      
      for (String endpoint in testEndpoints) {
        try {
          final response = await _client.get(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
          );
          
          if (kDebugMode) {
            print('ENDPOINT TEST: $baseUrl$endpoint -> Status: ${response.statusCode}');
            if (response.statusCode != 404) {
              print('✅ ÇALIŞAN ENDPOINT BULUNDU: $baseUrl$endpoint');
              print('Response Length: ${response.body.length}');
              print('Response: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');
              print('==========================================');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('ENDPOINT TEST: $baseUrl$endpoint -> Error: $e');
          }
        }
      }
    }
  }

  /// HTTP client'ı kapat
  static void dispose() {
    _client.close();
  }
}

/// API Exception sınıfı
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
}

/// API Response model sınıfları
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJson(json['data']) : null,
      statusCode: json['statusCode'],
    );
  }
}

/// Kullanıcı bilgileri modeli
class UserInfo {
  final String tc;
  final String ad;
  final String soyad;
  final String anneAd;
  final String babaAd;
  final String cinsiyet;
  final String cinsiyetKod;
  final String dogumTarih;
  final String dogumYer;
  final String medeniHal;
  final String medeniHalKod;
  final String seriNo;
  final String il;
  final String ilcekodu;
  final String ilkodu;
  final String ilce;
  final String mahalle;
  final String csbm;
  final String disKapiNo;
  final String icKapiNo;
  final String acikAdres;
  final bool isError;
  final String errorMessage;

  UserInfo({
    required this.tc,
    required this.ad,
    required this.soyad,
    required this.anneAd,
    required this.babaAd,
    required this.cinsiyet,
    required this.cinsiyetKod,
    required this.dogumTarih,
    required this.dogumYer,
    required this.medeniHal,
    required this.medeniHalKod,
    required this.seriNo,
    required this.il,
    required this.ilcekodu,
    required this.ilkodu,
    required this.ilce,
    required this.mahalle,
    required this.csbm,
    required this.disKapiNo,
    required this.icKapiNo,
    required this.acikAdres,
    required this.isError,
    required this.errorMessage,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      tc: json['tc'] ?? '',
      ad: json['ad'] ?? '',
      soyad: json['soyad'] ?? '',
      anneAd: json['anneAd'] ?? '',
      babaAd: json['babaAd'] ?? '',
      cinsiyet: json['cinsiyet'] ?? '',
      cinsiyetKod: json['cinsiyetKod'] ?? '',
      dogumTarih: json['dogumTarih'] ?? '',
      dogumYer: json['dogumYer'] ?? '',
      medeniHal: json['medeniHal'] ?? '',
      medeniHalKod: json['medeniHalKod'] ?? '',
      seriNo: json['seriNo'] ?? '',
      il: json['il'] ?? '',
      ilcekodu: json['ilcekodu'] ?? '',
      ilkodu: json['ilkodu'] ?? '',
      ilce: json['ilce'] ?? '',
      mahalle: json['mahalle'] ?? '',
      csbm: json['csbm'] ?? '',
      disKapiNo: json['disKapiNo'] ?? '',
      icKapiNo: json['icKapiNo'] ?? '',
      acikAdres: json['acikAdres'] ?? '',
      isError: json['isError'] ?? false,
      errorMessage: json['errorMessage'] ?? '',
    );
  }

  // Tam adı döndüren yardımcı getter
  String get fullName => '$ad $soyad';
  
  // Tam adres döndüren yardımcı getter  
  String get fullAddress {
    List<String> addressParts = [];
    if (mahalle.isNotEmpty) addressParts.add(mahalle);
    if (ilce.isNotEmpty) addressParts.add(ilce);
    if (il.isNotEmpty) addressParts.add(il);
    if (acikAdres.isNotEmpty) addressParts.add(acikAdres);
    return addressParts.join(', ');
  }
}

/// Danışman bilgileri modeli
class Advisor {
  final String id;
  final String name;
  final String title;
  final String department;
  final String email;
  final String phone;
  final String office;
  final String specialization;

  Advisor({
    required this.id,
    required this.name,
    required this.title,
    required this.department,
    required this.email,
    required this.phone,
    required this.office,
    required this.specialization,
  });

  factory Advisor.fromJson(Map<String, dynamic> json) {
    return Advisor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      department: json['department'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      office: json['office'] ?? '',
      specialization: json['specialization'] ?? '',
    );
  }
}

/// Randevu bilgileri modeli
class Appointment {
  final String id;
  final String day;
  final String date;
  final String time;
  final String status;
  final String? studentName;
  final String? studentNumber;

  Appointment({
    required this.id,
    required this.day,
    required this.date,
    required this.time,
    required this.status,
    this.studentName,
    this.studentNumber,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? '',
      day: json['day'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? '',
      studentName: json['studentName'],
      studentNumber: json['studentNumber'],
    );
  }
}