import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'kvkk_page.dart';
import 'advisor_selection_page.dart';
import '../services/api_connection.dart';

class UserInfoPage extends StatefulWidget {
  final String tcKimlikNo;
  final String userName;
  final UserInfo? userInfo; // API'den gelen kullanıcı verileri
  final String? birthDate; // AppointmentPage'den gelen doğum tarihi
  
  const UserInfoPage({
    super.key,
    required this.tcKimlikNo,
    required this.userName,
    this.userInfo,
    this.birthDate,
  });

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _kvkkAccepted = false;
  bool _communicationAccepted = false;
  bool _mounted = true;
  
  // Animasyon controller'ları
  late AnimationController _logoAnimationController;
  late AnimationController _infoAnimationController;
  late AnimationController _formAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _infoSlideAnimation;
  late Animation<double> _formFadeAnimation;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    
    // API'den gelen kullanıcı verilerini form alanlarına doldur
    _populateUserData();
    
    // Animasyon controller'larını başlat
    _initializeAnimations();
    
    // Animasyonları başlat
    _startAnimations();
  }

  void _initializeAnimations() {
    // Logo animasyonu
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Kullanıcı bilgileri animasyonu
    _infoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _infoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _infoAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Form animasyonu
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _formFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _logoAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _infoAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _formAnimationController.forward();
    });
  }

  void _populateUserData() {
    // API'den gelen kullanıcı bilgileri varsa form alanlarını doldur
    // Not: Yeni API yapısında e-posta ve telefon bilgisi yok,
    // kullanıcı bunları manuel olarak girecek
    
    // Adres bilgisini doldur
    if (widget.userInfo?.fullAddress.isNotEmpty == true) {
      _addressController.text = widget.userInfo!.fullAddress;
    }
  }

  Future<String> _getKpsName() async {
    try {
      // KPS API'yi doğrudan çağıralım - api_connection.dart kullanmadan
      final birthDate = _getBirthDateFromUserInfo();
      final birthDateParts = birthDate.split('.');
      final day = int.parse(birthDateParts[0]);
      final month = int.parse(birthDateParts[1]); 
      final year = int.parse(birthDateParts[2]);
      
      final requestBody = {
        'tc': widget.tcKimlikNo,
        'gun': day,
        'ay': month,
        'yil': year,
      };
      
      print('🔍 KPS Direct API Call - Request: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('https://adhapi-test.gazi.edu.tr/General/GetKps'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
          'isshowmessage': 'false',
          'Origin': 'https://adh-test.gazi.edu.tr',
          'Referer': 'https://adh-test.gazi.edu.tr/',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36',
        },
        body: jsonEncode(requestBody),
      );
      
      print('🔍 KPS Direct API Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['resultType'] == 1 && responseData['data'] != null) {
          final userData = responseData['data'];
          final ad = userData['ad'] ?? '';
          final soyad = userData['soyad'] ?? '';
          
          print('🔍 KPS DEBUG Direct: ad="$ad" soyad="$soyad"');
          
          if (ad.isNotEmpty && soyad.isNotEmpty) {
            return '$ad $soyad';
          }
        }
      }
    } catch (e) {
      print('❌ KPS Direct API Error: $e');
    }
    
    return widget.userName.isNotEmpty ? widget.userName : 'Test Kullanıcı';
  }
  
  String _getBirthDateFromUserInfo() {
    // Önce AppointmentPage'den gelen doğum tarihini kullan
    if (widget.birthDate?.isNotEmpty == true) {
      print('🔍 Using birthDate from AppointmentPage: ${widget.birthDate}');
      return widget.birthDate!;
    }
    
    // UserInfo'dan doğum tarihini çek ve DD.MM.YYYY formatına çevir
    if (widget.userInfo?.dogumTarih.isNotEmpty == true) {
      try {
        final date = DateTime.parse(widget.userInfo!.dogumTarih);
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      } catch (e) {
        print('Date parse error: $e');
      }
    }
    
    // Fallback - bugünün tarihinden bir yaş çıkar
    final now = DateTime.now();
    final fallbackDate = DateTime(now.year - 20, now.month, now.day);
    return '${fallbackDate.day.toString().padLeft(2, '0')}.${fallbackDate.month.toString().padLeft(2, '0')}.${fallbackDate.year}';
  }

  String _getDisplayName() {
    // KPS'den gerçek isim-soyisim geliyorsa userName'de olmalı
    // Çünkü appointment_page.dart'ta userInfo.fullName ile set ediliyor
    
    print('🔍 DEBUG: widget.userName = "${widget.userName}"');
    
    // userName'de gerçek isim varsa onu kullan, yoksa fallback
    if (widget.userName.isNotEmpty && 
        widget.userName != 'Bilinmeyen Kullanıcı' && 
        !widget.userName.contains('Test')) {
      return widget.userName;
    }
    
    // Son çare olarak UserInfo'yu dene (muhtemelen boş olacak)
    if (widget.userInfo != null && widget.userInfo!.fullName.trim().isNotEmpty) {
      return widget.userInfo!.fullName;
    }
    
    return 'Test Kullanıcı';
  }

  Future<void> _saveUserContactInfo() async {
    try {
      // KPS'den isim-soyisimi al (doğrudan API çağrısı ile)
      final kpsName = await _getKpsName();
      final nameParts = kpsName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : 'Test';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'User';
      
      print('🔍 Client Insert - Name: $firstName, Surname: $lastName');
      
      // Doğum tarihini ISO formatına çevir
      final birthDate = _getBirthDateFromUserInfo();
      final birthDateParts = birthDate.split('.');
      final day = int.parse(birthDateParts[0]);
      final month = int.parse(birthDateParts[1]);
      final year = int.parse(birthDateParts[2]);
      final isoDate = DateTime(year, month, day).toIso8601String();
      
      // Client/ClientInsert'e gönderilecek veri
      final requestBody = {
        'id': 0,
        'name': firstName,
        'surname': lastName,
        'tcId': widget.tcKimlikNo,
        'email': _emailController.text,
        'tel': _phoneController.text,
        'address': widget.userInfo?.acikAdres ?? '',
        'cinsiyet': widget.userInfo?.cinsiyet ?? 'Erkek',
        'birthDate': isoDate,
      };
      
      print('🔍 CLIENT INSERT REQUEST: ${jsonEncode(requestBody)}');
      
      // API'ye gönder (api_connection.dart'taki aynı method'u kullan)
      // Bu HTTP isteğini doğrudan yapalım
      final response = await http.post(
        Uri.parse('https://adhapi-test.gazi.edu.tr/Client/ClientInsert'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
          'isshowmessage': 'false',
          'Origin': 'https://adh-test.gazi.edu.tr',
          'Referer': 'https://adh-test.gazi.edu.tr/',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36',
        },
        body: jsonEncode(requestBody),
      );
      
      print('🔍 CLIENT INSERT RESPONSE: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['resultType'] != 1) {
          throw Exception(responseData['message'] ?? 'Kayıt başarısız');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ CLIENT INSERT ERROR: $e');
      throw e;
    }
  }



  @override
  void dispose() {
    _mounted = false;
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _logoAnimationController.dispose();
    _infoAnimationController.dispose();
    _formAnimationController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_mounted) return;
    
    if (_formKey.currentState?.validate() == true) {
      if (!_kvkkAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KVKK onayı gereklidir'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // Haptic feedback
      HapticFeedback.lightImpact();
      
      // Loading state
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('Bilgiler kaydediliyor...'),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      try {
        // Client/ClientInsert API'ye e-posta ve telefon bilgilerini gönder
        await _saveUserContactInfo();
        
        // Loading snackbar'ı kapat
        if (_mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }
        
        // Başarı mesajı
        if (_mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Bilgileriniz başarıyla kaydedildi')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        // Danışman seçme sayfasına yönlendir
        Future.delayed(const Duration(seconds: 1), () {
          if (_mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdvisorSelectionPage(
                  tcKimlikNo: widget.tcKimlikNo,
                  userFullName: widget.userName,
                  userPhone: _phoneController.text,
                  userEmail: _emailController.text,
                  userAddress: _addressController.text,
                  birthDate: widget.birthDate,
                ),
              ),
            );
          }
        });
        
      } catch (e) {
        // Loading snackbar'ı kapat
        if (_mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }
        
        // Hata mesajı
        if (_mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Kayıt hatası: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      // Validation hatası durumunda haptic feedback
      HapticFeedback.heavyImpact();
    }
  }

  void _goBack() {
    // Haptic feedback
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  void _openKvkkPage() {
    // Haptic feedback
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KvkkPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    
    return Scaffold(
      backgroundColor: isIOS ? const Color(0xFFF2F2F7) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Geri tuşu ve başlık
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isIOS ? Colors.white : Colors.transparent,
                border: isIOS ? Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 0.5,
                  ),
                ) : null,
              ),
              child: Row(
                children: [
                  // Native geri tuşu
                  GestureDetector(
                    onTap: _goBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
                        color: isIOS ? Colors.blue : Colors.blue,
                        size: isIOS ? 20 : 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Başlık
                  Expanded(
                    child: Text(
                      'Kullanıcı Bilgileri',
                      style: TextStyle(
                        fontSize: isIOS ? 17 : 18,
                        fontWeight: isIOS ? FontWeight.w600 : FontWeight.bold,
                        color: isIOS ? Colors.black : const Color(0xFF1e3c72),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Ana içerik
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Gazi Üniversitesi Logosu (Animasyonlu)
                      ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: Center(
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/logo-gazi.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.account_circle,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      
                      // Başlık metinleri
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isIOS ? Colors.white : Colors.white,
                          borderRadius: BorderRadius.circular(isIOS ? 10 : 12),
                          boxShadow: isIOS ? null : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Sağlık Bilimleri Fakültesi',
                              style: TextStyle(
                                fontSize: isIOS ? 24 : 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1e3c72),
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Akademik Danışmanlık Hizmeti',
                              style: TextStyle(
                                fontSize: isIOS ? 16 : 18,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2a5298),
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Kullanıcı Bilgileri (Animasyonlu)
                      SlideTransition(
                        position: _infoSlideAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(isIOS ? 10 : 12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              FutureBuilder<String>(
                                future: _getKpsName(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Text(
                                      'Sayın: ${_getDisplayName()}',
                                      style: TextStyle(
                                        fontSize: isIOS ? 18 : 20,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1e3c72),
                                      ),
                                      textAlign: TextAlign.center,
                                    );
                                  }
                                  
                                  return Text(
                                    'Sayın: ${snapshot.data ?? _getDisplayName()}',
                                    style: TextStyle(
                                      fontSize: isIOS ? 18 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1e3c72),
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'TC Kimlik Numarası: ${widget.tcKimlikNo}',
                                style: TextStyle(
                                  fontSize: isIOS ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1e3c72),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (widget.userInfo?.dogumTarih.isNotEmpty == true) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Doğum Tarihi: ${widget.userInfo!.dogumTarih}',
                                  style: TextStyle(
                                    fontSize: isIOS ? 14 : 16,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF2a5298),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              if (widget.userInfo?.fullAddress.isNotEmpty == true) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Adres: ${widget.userInfo!.fullAddress}',
                                  style: TextStyle(
                                    fontSize: isIOS ? 14 : 16,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF2a5298),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Form Container (Animasyonlu)
                      FadeTransition(
                        opacity: _formFadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isIOS ? Colors.white : Colors.white,
                            borderRadius: BorderRadius.circular(isIOS ? 10 : 16),
                            boxShadow: isIOS ? null : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // E-posta Adresi
                              Text(
                                'E-posta Adresi: *',
                                style: TextStyle(
                                  fontSize: isIOS ? 15 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1e3c72),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  fontSize: isIOS ? 16 : 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'E-posta adresinizi giriniz',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: isIOS ? 16 : 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(isIOS ? 8 : 12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(isIOS ? 8 : 12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(isIOS ? 8 : 12),
                                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: isIOS ? Colors.grey[50] : Colors.grey[50],
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: isIOS ? 12 : 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'E-posta adresi gereklidir';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Geçerli bir e-posta adresi giriniz';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              
                              // Cep Telefonu
                              Text(
                                'Cep Telefonu: *',
                                style: TextStyle(
                                  fontSize: isIOS ? 15 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1e3c72),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: TextStyle(
                                  fontSize: isIOS ? 16 : 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: '05 ile başlayan telefon numarası',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: isIOS ? 16 : 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(isIOS ? 8 : 12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(isIOS ? 8 : 12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(isIOS ? 8 : 12),
                                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: isIOS ? Colors.grey[50] : Colors.grey[50],
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: isIOS ? 12 : 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Cep telefonu gereklidir';
                                  }
                                  if (!value.startsWith('05') || value.length != 11) {
                                    return '05 ile başlayan 11 haneli telefon numarası giriniz';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              
                              // KVKK Onay Kutusu
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _kvkkAccepted,
                                      onChanged: (value) {
                                        setState(() {
                                          _kvkkAccepted = value ?? false;
                                        });
                                        HapticFeedback.selectionClick();
                                      },
                                      activeColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _openKvkkPage,
                                      child: Text(
                                        'KVKK uyarınca ilgili Bilgilendirme\'yi okudum. Kişisel verilerimin belirtilen kapsamda işlenmesini kabul ediyorum.',
                                        style: TextStyle(
                                          fontSize: isIOS ? 14 : 15,
                                          color: Colors.blue,
                                          height: 1.4,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // İletişim Onay Kutusu
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _communicationAccepted,
                                      onChanged: (value) {
                                        setState(() {
                                          _communicationAccepted = value ?? false;
                                        });
                                        HapticFeedback.selectionClick();
                                      },
                                      activeColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Randevu hatırlatma, randevunun iptali vb. durumlarda e-posta adresi/telefon üzerinden iletişim kurulmasına izin veriyorum.',
                                      style: TextStyle(
                                        fontSize: isIOS ? 14 : 15,
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              
                              // Giriş butonu
                              SizedBox(
                                width: double.infinity,
                                height: isIOS ? 50 : 56,
                                child: ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    elevation: isIOS ? 0 : 3,
                                    shadowColor: isIOS ? null : Colors.blue.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(isIOS ? 8 : 16),
                                    ),
                                  ),
                                  child: Text(
                                    'Giriş',
                                    style: TextStyle(
                                      fontSize: isIOS ? 17 : 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
