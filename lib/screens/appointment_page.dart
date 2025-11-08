import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_info_page.dart';
import '../services/api_connection.dart';

/// Tarih girişi için özel formatlayıcı sınıfı
/// Kullanıcının girdiği rakamları otomatik olarak DD.MM.YYYY formatına çevirir
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('.', '');
    
    if (text.length > 8) {
      return oldValue;
    }
    
    String formattedText = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) {
        formattedText += '.';
      }
      formattedText += text[i];
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

/// Randevu işlemleri ana sayfası
/// Kullanıcıların randevu alması veya mevcut randevularını iptal etmesi için kullanılır
/// TC Kimlik No, doğum tarihi ve güvenlik kodu ile kimlik doğrulaması yapar
class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

/// AppointmentPage'in state yönetimi sınıfı
/// Form verilerini, animasyonları ve API işlemlerini yönetir
/// Tab değişimi, tarih seçimi ve randevu işlemlerini kontrol eder
class _AppointmentPageState extends State<AppointmentPage> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tcController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _securityCodeController;
  late final TextEditingController _appointmentNumberController;
  bool _mounted = true;
  int _selectedTabIndex = 0; // 0: e-Randevu, 1: e-Randevu İptal
  String _securityCode = ''; // Random güvenlik kodu
  
  // Animasyon controller'ları
  late AnimationController _logoAnimationController;
  late AnimationController _tabAnimationController;
  late AnimationController _formAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _tabSlideAnimation;
  late Animation<double> _formFadeAnimation;

  @override
  void initState() {
    super.initState();
    _tcController = TextEditingController();
    _birthDateController = TextEditingController();
    _securityCodeController = TextEditingController();
    _appointmentNumberController = TextEditingController();
    
    // Random güvenlik kodu oluştur (6 haneli)
    _generateSecurityCode();
    
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

    // Tab animasyonu
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _tabSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _tabAnimationController,
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
      _tabAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _formAnimationController.forward();
    });
  }

  void _generateSecurityCode() {
    final random = Random();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += random.nextInt(10).toString();
    }
    _securityCode = code;
  }

  @override
  void dispose() {
    _mounted = false;
    _tcController.dispose();
    _birthDateController.dispose();
    _securityCodeController.dispose();
    _appointmentNumberController.dispose();
    _logoAnimationController.dispose();
    _tabAnimationController.dispose();
    _formAnimationController.dispose();
    super.dispose();
  }


  void _query() async {
    if (!_mounted) return;
    
    if (_formKey.currentState?.validate() == true) {
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
                Expanded(
                  child: Text(_selectedTabIndex == 0 
                    ? 'Randevu oluşturuluyor...' 
                    : 'Randevu iptal sorgulanıyor...'),
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
        Map<String, dynamic> result;
        
        if (_selectedTabIndex == 0) {
          // e-Randevu oluşturma
          result = await ApiConnection.createAppointment(
            tcKimlikNo: _tcController.text,
            birthDate: _birthDateController.text,
            securityCode: _securityCodeController.text,
            advisorId: '1', // Varsayılan danışman (daha sonra seçim eklenecek)
            timeSlot: DateTime.now().add(const Duration(days: 7)).toIso8601String(), // 1 hafta sonra
          );
        } else {
          // e-Randevu iptal sorgulama
          result = await ApiConnection.queryAppointmentCancel(
            tcKimlikNo: _tcController.text,
            appointmentNumber: _appointmentNumberController.text,
          );
        }
        
        // Loading snackbar'ı kapat
        if (_mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }
        
        // Sonucu kontrol et
        if (result['success'] == true) {
          // KPS API'yi doğrudan çağırıp hata kontrolü yap
          try {
            final birthDateParts = _birthDateController.text.split('.');
            final day = int.parse(birthDateParts[0]);
            final month = int.parse(birthDateParts[1]); 
            final year = int.parse(birthDateParts[2]);
            
            final requestBody = {
              'tc': _tcController.text,
              'gun': day,
              'ay': month,
              'yil': year,
            };
            
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
            
            if (response.statusCode == 200) {
              final responseData = jsonDecode(response.body);
              if (responseData['data'] != null) {
                final userData = responseData['data'];
                final isError = userData['isError'] ?? false;
                final errorMessage = userData['errorMessage'] ?? '';
                
                // Hata kontrolü
                if (isError == true || 
                    (errorMessage.isNotEmpty && errorMessage.contains('Kimlik No alanına girdiğiniz değer geçerli bir T.C. Kimlik Numarası değildir'))) {
                  // TC Kimlik hatası - UserInfoPage'e geçme
                  if (_mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('Bilgiler hatalıdır. Lütfen TC Kimlik Numarası ve doğum tarihinizi kontrol ediniz.')),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                  return; // UserInfoPage'e geçmeyi engelle
                }
              }
            }
            
            // Buraya geldiysek veri geçerli - UserInfo'yu ApiConnection'dan al
            final userInfo = await ApiConnection.getUserInfo(
              tcKimlikNo: _tcController.text,
              birthDate: _birthDateController.text,
            );
            
            // Başarılı sonuç
            if (_mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(result['message'] ?? 'İşlem başarılı')),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            
            // UserInfoPage'e yönlendir
            if (_mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserInfoPage(
                    tcKimlikNo: _tcController.text,
                    userName: userInfo.fullName.isNotEmpty ? userInfo.fullName : 'Bilinmeyen Kullanıcı',
                    userInfo: userInfo, // API'den gelen UserInfo objesi
                    birthDate: _birthDateController.text, // AppointmentPage'den girilen doğum tarihi
                  ),
                ),
              );
            }
          } catch (e) {
            // KPS API hatası
            if (_mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Bilgiler hatalıdır. Lütfen TC Kimlik Numarası ve doğum tarihinizi kontrol ediniz.')),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        } else {
          // Hata durumu
          if (_mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(result['message'] ?? 'Bir hata oluştu')),
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
      } catch (e) {
        // Loading snackbar'ı kapat
        if (_mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }
        
        // Hata mesajı göster
        if (_mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Bağlantı hatası: $e'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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

  void _selectTab(int index) {
    if (_mounted && index != _selectedTabIndex) {
      // Haptic feedback
      HapticFeedback.selectionClick();
      
      setState(() {
        _selectedTabIndex = index;
        // Form alanlarını temizle
        _tcController.clear();
        _birthDateController.clear();
        _securityCodeController.clear();
        _appointmentNumberController.clear();
      });
      
      // Tab değişim animasyonu
      _tabAnimationController.reset();
      _tabAnimationController.forward();
    }
  }

  Future<void> _selectDate() async {
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && _mounted) {
      // Haptic feedback
      HapticFeedback.selectionClick();
      
      setState(() {
        _birthDateController.text = 
            '${picked.day.toString().padLeft(2, '0')}.'
            '${picked.month.toString().padLeft(2, '0')}.'
            '${picked.year}';
      });
    }
  }

  void _goBack() {
    // Haptic feedback
    HapticFeedback.lightImpact();
    Navigator.pop(context);
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
                      'Randevu İşlemleri',
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
                      
                      // Sekmeler (Animasyonlu)
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(_tabSlideAnimation),
                        child: Container(
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
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectTab(0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: _selectedTabIndex == 0 
                                        ? (isIOS ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.1))
                                        : Colors.transparent,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(isIOS ? 10 : 12),
                                        bottomLeft: Radius.circular(isIOS ? 10 : 12),
                                      ),
                                      border: Border(
                                        bottom: BorderSide(
                                          color: _selectedTabIndex == 0 
                                            ? Colors.blue 
                                            : Colors.transparent,
                                          width: isIOS ? 2 : 3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Randevu Al',
                                      style: TextStyle(
                                        fontSize: isIOS ? 15 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedTabIndex == 0 
                                          ? Colors.blue 
                                          : Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectTab(1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: _selectedTabIndex == 1 
                                        ? (isIOS ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.1))
                                        : Colors.transparent,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(isIOS ? 10 : 12),
                                        bottomRight: Radius.circular(isIOS ? 10 : 12),
                                      ),
                                      border: Border(
                                        bottom: BorderSide(
                                          color: _selectedTabIndex == 1 
                                            ? Colors.blue 
                                            : Colors.transparent,
                                          width: isIOS ? 2 : 3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Randevu İptal',
                                      style: TextStyle(
                                        fontSize: isIOS ? 15 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedTabIndex == 1 
                                          ? Colors.blue 
                                          : Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
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
                              // TC Kimlik Numarası
                              Text(
                                'T.C Kimlik Numarası *',
                                style: TextStyle(
                                  fontSize: isIOS ? 15 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1e3c72),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _tcController,
                                keyboardType: TextInputType.number,
                                maxLength: 11,
                                style: TextStyle(
                                  fontSize: isIOS ? 16 : 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'T.C Kimlik Numarası giriniz',
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
                                  counterText: '',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: isIOS ? 12 : 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'T.C Kimlik Numarası gereklidir';
                                  }
                                  if (value.length != 11) {
                                    return 'T.C Kimlik Numarası 11 haneli olmalıdır';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              
                              // e-Randevu sekmesi için ek alanlar
                              if (_selectedTabIndex == 0) ...[
                                // Doğum Tarihi
                                Text(
                                  'Doğum Tarihi *',
                                  style: TextStyle(
                                    fontSize: isIOS ? 15 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1e3c72),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _birthDateController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 10, // DD.MM.YYYY format
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    _DateInputFormatter(),
                                  ],
                                  style: TextStyle(
                                    fontSize: isIOS ? 16 : 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'GG.AA.YYYY',
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
                                    suffixIcon: GestureDetector(
                                      onTap: _selectDate,
                                      child: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(isIOS ? 6 : 8),
                                        ),
                                        child: Icon(
                                          isIOS ? Icons.calendar_today : Icons.calendar_today,
                                          color: Colors.white,
                                          size: isIOS ? 18 : 20,
                                        ),
                                      ),
                                    ),
                                    counterText: '', // Karakter sayacını gizle
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: isIOS ? 12 : 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Doğum tarihi gereklidir';
                                    }
                                    if (value.length != 10) {
                                      return 'Doğum tarihi GG.AA.YYYY formatında olmalıdır';
                                    }
                                    // Tarih geçerliliğini kontrol et
                                    try {
                                      final parts = value.split('.');
                                      if (parts.length != 3) {
                                        throw Exception();
                                      }
                                      final day = int.parse(parts[0]);
                                      final month = int.parse(parts[1]);
                                      final year = int.parse(parts[2]);
                                      
                                      if (day < 1 || day > 31) {
                                        return 'Geçersiz gün (1-31)';
                                      }
                                      if (month < 1 || month > 12) {
                                        return 'Geçersiz ay (1-12)';
                                      }
                                      if (year < 1900 || year > DateTime.now().year) {
                                        return 'Geçersiz yıl';
                                      }
                                      
                                      // Gerçek tarih kontrolü
                                      final date = DateTime(year, month, day);
                                      if (date.day != day || date.month != month || date.year != year) {
                                        return 'Geçersiz tarih';
                                      }
                                    } catch (e) {
                                      return 'Geçersiz tarih formatı';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                
                                // Güvenlik Kodu
                                Row(
                                  children: [
                                    Text(
                                      'Güvenlik Kodu *',
                                      style: TextStyle(
                                        fontSize: isIOS ? 15 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1e3c72),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(isIOS ? 6 : 8),
                                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        _securityCode,
                                        style: TextStyle(
                                          fontSize: isIOS ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _securityCodeController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  style: TextStyle(
                                    fontSize: isIOS ? 16 : 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Güvenlik kodunu giriniz',
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
                                    counterText: '',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: isIOS ? 12 : 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Güvenlik kodu gereklidir';
                                    }
                                    if (value != _securityCode) {
                                      return 'Güvenlik kodu hatalı';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              
                              // e-Randevu İptal sekmesi için ek alan
                              if (_selectedTabIndex == 1) ...[
                                // Randevu Numarası
                                Text(
                                  'Randevu Numarası *',
                                  style: TextStyle(
                                    fontSize: isIOS ? 15 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1e3c72),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _appointmentNumberController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    fontSize: isIOS ? 16 : 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Randevu numarasını giriniz',
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
                                      return 'Randevu numarası gereklidir';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              
                              const SizedBox(height: 32),
                              
                              // Sorgula butonu
                              SizedBox(
                                width: double.infinity,
                                height: isIOS ? 50 : 56,
                                child: ElevatedButton(
                                  onPressed: _query,
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
                                    _selectedTabIndex == 0 ? 'Randevu Oluştur' : 'Randevuyu Getir',
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
