import 'dart:convert';
import 'package:http/http.dart' as http;

/// Danışman bilgilerini temsil eden model sınıfı
class Advisor {
  final int id;
  final String name;
  final String surname;
  final String telNo;
  final String title;
  final String email;
  final String iban;
  final String bankName;
  final String sicilNo;
  final String uniteName;
  final int uniteId;
  final String creationDate;
  final int creationUserId;
  final String? updateDate;
  final int? updateUserId;
  final String? deleteDate;

  Advisor({
    required this.id,
    required this.name,
    required this.surname,
    required this.telNo,
    required this.title,
    required this.email,
    required this.iban,
    required this.bankName,
    required this.sicilNo,
    required this.uniteName,
    required this.uniteId,
    required this.creationDate,
    required this.creationUserId,
    this.updateDate,
    this.updateUserId,
    this.deleteDate,
  });

  factory Advisor.fromJson(Map<String, dynamic> json) {
    return Advisor(
      id: json['id'] ?? 0,
      name: (json['name'] ?? '').toString().trim(),
      surname: (json['surname'] ?? '').toString().trim(),
      telNo: json['telNo'] ?? '0',
      title: json['title'] ?? '',
      email: json['email'] ?? '',
      iban: json['iban'] ?? '',
      bankName: json['bankName'] ?? '',
      sicilNo: json['sicilNo'] ?? '',
      uniteName: json['uniteName'] ?? '',
      uniteId: json['uniteId'] ?? 0,
      creationDate: json['creationDate'] ?? '',
      creationUserId: json['creationUserId'] ?? 0,
      updateDate: json['updateDate'],
      updateUserId: json['updateUserId'],
      deleteDate: json['deleteDate'],
    );
  }

  String get fullName => '$name $surname'.trim();
  String get displayName => '$title $fullName'.trim();
  
  /// Danışmanın benzersiz görünen adını döndürür (aynı isimli danışmanlar için)
  String getUniqueDisplayName(List<Advisor> allAdvisors) {
    // Aynı tam ada sahip danışmanları bul
    final sameNameAdvisors = allAdvisors.where(
      (advisor) => advisor.fullName.toLowerCase() == fullName.toLowerCase() && advisor.id != id
    ).toList();
    
    if (sameNameAdvisors.isNotEmpty) {
      // Aynı isimli danışman varsa, bölüm bilgisi ekle
      return '$displayName ($uniteName)';
    }
    
    return displayName;
  }
}

/// Ünite bilgilerini temsil eden model sınıfı
class Unite {
  final List<Advisor> advisors;

  Unite({required this.advisors});

  factory Unite.fromJson(Map<String, dynamic> json) {
    final advisorsList = json['advisors'] as List<dynamic>? ?? [];
    return Unite(
      advisors: advisorsList.map((advisor) => Advisor.fromJson(advisor)).toList(),
    );
  }
}

/// API'den danışman listesini çeken ve yöneten sınıf
class AdvisorList {
  static List<Advisor> _cachedAdvisors = [];
  static DateTime? _lastFetchTime;

  /// API'den danışman listesini çeker
  static Future<List<Advisor>> fetchAdvisors({bool forceRefresh = false}) async {
    // Cache kontrolü - 5 dakika geçerli
    if (!forceRefresh && 
        _cachedAdvisors.isNotEmpty && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!).inMinutes < 5) {
      return _cachedAdvisors;
    }

    try {
      final response = await http.get(
        Uri.parse('https://adhapi-test.gazi.edu.tr/Section/GetSectionAllWithDivision'),
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
          'Content-Type': 'application/json',
          'isshowmessage': 'true',
          'Origin': 'https://adh-test.gazi.edu.tr',
          'Referer': 'https://adh-test.gazi.edu.tr/',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Advisor> allAdvisors = [];

        if (data['data'] != null) {
          for (var section in data['data']) {
            if (section['unites'] != null) {
              for (var uniteData in section['unites']) {
                final unite = Unite.fromJson(uniteData);
                allAdvisors.addAll(unite.advisors);
              }
            }
          }
        }

        // Tekrarlayan danışmanları filtrele (ID'ye göre)
        final uniqueAdvisors = <int, Advisor>{};
        for (var advisor in allAdvisors) {
          uniqueAdvisors[advisor.id] = advisor;
        }
        
        // Aynı isme sahip danışmanlar için bölüm bilgisi ekle
        final processedAdvisors = _processAdvisorsWithSameName(uniqueAdvisors.values.toList());

        // Cache'i güncelle
        _cachedAdvisors = processedAdvisors;
        _lastFetchTime = DateTime.now();
        
        return processedAdvisors;
      } else {
        throw Exception('API isteği başarısız: ${response.statusCode}');
      }
    } catch (e) {
      // Hata durumunda cache'deki veriyi döndür
      if (_cachedAdvisors.isNotEmpty) {
        return _cachedAdvisors;
      }
      throw Exception('Danışman listesi yüklenemedi: $e');
    }
  }

  /// Advisor listesini ID'ye göre filtreler
  static Future<Advisor?> getAdvisorById(int id) async {
    try {
      final advisors = await fetchAdvisors();
      return advisors.firstWhere((advisor) => advisor.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Tüm advisor listesini döndürür
  static Future<List<Advisor>> getAllAdvisors({bool forceRefresh = false}) async {
    return fetchAdvisors(forceRefresh: forceRefresh);
  }

  /// Ünite adına göre danışmanları filtreler
  static Future<List<Advisor>> getAdvisorsByUnit(String uniteName) async {
    try {
      final advisors = await fetchAdvisors();
      return advisors.where((advisor) => advisor.uniteName == uniteName).toList();
    } catch (e) {
      return [];
    }
  }

  /// Tüm ünite adlarını döndürür
  static Future<List<String>> getAllUnitNames() async {
    try {
      final advisors = await fetchAdvisors();
      return advisors.map((advisor) => advisor.uniteName).toSet().toList();
    } catch (e) {
      return [];
    }
  }

  /// Cache'i temizler
  static void clearCache() {
    _cachedAdvisors = [];
    _lastFetchTime = null;
  }

  /// Aynı isme sahip danışmanları işler ve benzersiz görünen adlar oluşturur
  static List<Advisor> _processAdvisorsWithSameName(List<Advisor> advisors) {
    // İsim tekrarlarını kontrol et
    final nameCount = <String, int>{};
    for (var advisor in advisors) {
      final fullName = advisor.fullName.toLowerCase();
      nameCount[fullName] = (nameCount[fullName] ?? 0) + 1;
    }

    // Aynı isimli danışmanları grupla
    final groupedByName = <String, List<Advisor>>{};
    for (var advisor in advisors) {
      final fullName = advisor.fullName.toLowerCase();
      if (nameCount[fullName]! > 1) {
        groupedByName[fullName] ??= [];
        groupedByName[fullName]!.add(advisor);
      }
    }

    // Her grup için bölüm bilgilerini ekle
    for (var group in groupedByName.values) {
      if (group.length > 1) {
        // Aynı isimli danışmanları bölümlerine göre sırala
        group.sort((a, b) => a.uniteName.compareTo(b.uniteName));
      }
    }

    // Danışmanları alfabetik olarak sırala
    advisors.sort((a, b) {
      // Önce unvan karşılaştır
      final titleOrder = {'Prof.Dr.': 1, 'Doç.Dr.': 2, 'Dr.': 3, 'Arş.Gör.': 4, 'Öğr.Gör.': 5};
      final aOrder = titleOrder[a.title] ?? 99;
      final bOrder = titleOrder[b.title] ?? 99;
      
      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      
      // Sonra isim karşılaştır
      return a.fullName.compareTo(b.fullName);
    });

    return advisors;
  }
}
