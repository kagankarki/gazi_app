import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/appointment_insert.dart';

class TaahhutnamePage extends StatefulWidget {
  final Map<String, String>? userInfo; // API'den gelen kullanıcı bilgileri
  final Map<String, String>? advisorInfo; // API'den gelen danışman bilgileri
  final DateTime? appointmentDate; // Randevu tarihi
  final String? appointmentTime; // Randevu saati (örn: "10:00")
  final String? tcKimlikNo; // TC Kimlik No
  final String? birthDate; // Doğum tarihi
  
  const TaahhutnamePage({
    super.key,
    this.userInfo,
    this.advisorInfo,
    this.appointmentDate,
    this.appointmentTime,
    this.tcKimlikNo,
    this.birthDate,
  });

  @override
  State<TaahhutnamePage> createState() => _TaahhutnamePageState();
}

class _TaahhutnamePageState extends State<TaahhutnamePage> 
    with TickerProviderStateMixin {
  bool _isAccepted = false;
  String _kpsAd = '';
  String _kpsSoyad = '';
  String _kpsAdres = '';
  bool _isLoadingKps = true;
  
  // Animasyon controller'ları
  late AnimationController _pageAnimationController;
  late AnimationController _checkboxAnimationController;
  late Animation<double> _pageSlideAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<double> _checkboxScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadKpsData(); // KPS verilerini yükle
    _debugLogInitialData(); // Debug logları
  }

  void _debugLogInitialData() {
    print('🔍 TAAHHUTNAME - Initial Data Debug:');
    print('  userInfo: ${widget.userInfo}');
    print('  advisorInfo: ${widget.advisorInfo}');
    print('  appointmentDate: ${widget.appointmentDate}');
    print('  tcKimlikNo: ${widget.tcKimlikNo}');
    print('  birthDate: ${widget.birthDate}');
    
    if (widget.userInfo != null) {
      print('  userInfo Details:');
      widget.userInfo!.forEach((key, value) {
        print('    $key: "$value"');
      });
    }
    
    if (widget.advisorInfo != null) {
      print('  advisorInfo Details:');
      widget.advisorInfo!.forEach((key, value) {
        print('    $key: "$value"');
      });
    }
  }

  void _initializeAnimations() {
    // Sayfa animasyonu
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pageSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Checkbox animasyonu
    _checkboxAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _checkboxScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _checkboxAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    _pageAnimationController.forward();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _checkboxAnimationController.dispose();
    super.dispose();
  }

  void _onCheckboxChanged(bool? value) {
    setState(() {
      _isAccepted = value ?? false;
    });
    
    if (_isAccepted) {
      HapticFeedback.lightImpact();
    }
  }

  // user_info_page.dart'taki KPS çağrısını kopyala
  Future<void> _loadKpsData() async {
    if (widget.tcKimlikNo == null || widget.birthDate == null) {
      setState(() {
        _isLoadingKps = false;
      });
      return;
    }

    try {
      // KPS API'yi doğrudan çağıralım - user_info_page.dart'taki gibi
      final birthDate = widget.birthDate!;
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
      
      print('🔍 TAAHHUTNAME - KPS Direct API Call - Request: ${jsonEncode(requestBody)}');
      
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
      
      print('🔍 TAAHHUTNAME - KPS Direct API Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['resultType'] == 1 && responseData['data'] != null) {
          final userData = responseData['data'];
          
          setState(() {
            _kpsAd = userData['ad'] ?? '';
            _kpsSoyad = userData['soyad'] ?? '';
            _kpsAdres = userData['acikAdres'] ?? '';
            _isLoadingKps = false;
          });
          
          print('🔍 TAAHHUTNAME - KPS DEBUG Direct: ad="$_kpsAd" soyad="$_kpsSoyad"');
        } else {
          setState(() {
            _isLoadingKps = false;
          });
        }
      } else {
        setState(() {
          _isLoadingKps = false;
        });
      }
    } catch (e) {
      print('❌ TAAHHUTNAME - KPS Direct API Error: $e');
      setState(() {
        _isLoadingKps = false;
      });
    }
  }

  void _onAccept() async {
    if (_isAccepted) {
      HapticFeedback.mediumImpact();
      
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Randevu oluşturuluyor...'),
              ],
            ),
          ),
        ),
      );
      
      try {
        await _createAppointment();
        
        // Loading kapat
        Navigator.of(context).pop();
        
        // Başarı mesajı
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Randevunuz Oluşturuldu!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '${_getFormattedDate()} - ${widget.appointmentTime ?? ""}',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '${widget.advisorInfo?['title'] ?? ''} ${widget.advisorInfo?['name'] ?? ''}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        // Bir sonraki sayfaya başarı bilgisini ilet ve ana sayfaya dön
        Navigator.of(context).pop(true); // Appointment Summary'ye başarı bilgisi ilet
        Navigator.of(context).popUntil((route) => route.isFirst);
        
      } catch (e) {
        // Loading kapat
        Navigator.of(context).pop();
        
        // Hata mesajı
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Randevu oluşturulurken hata: $e',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _createAppointment() async {
    // Randevu No oluştur (örnek)
    final appointmentNo = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    
    // Tarih ve saati birleştir
    final appointmentDate = widget.appointmentDate ?? DateTime.now();
    final timeStr = widget.appointmentTime ?? "10:00";
    final timeParts = timeStr.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    final fullDateTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      hour,
      minute,
    );
    
    final isoDate = fullDateTime.toIso8601String();
    
    // AppointmentInsert model'ini oluştur
    final appointmentInsert = AppointmentInsert(
      id: 0,
      advisorId: int.parse(widget.advisorInfo?['id'] ?? '0'),
      clientId: 83, // Bu API'den gelecek - şimdilik sabit
      time: isoDate,
      appointmentNo: appointmentNo,
      status: AppointmentStatus.confirmed,
      type: AppointmentType.consultation,
      paymentStatus: PaymentStatus.paid,
      source: 1,
      clientName: widget.userInfo?['ad'] ?? '',
      clientSurname: widget.userInfo?['soyad'] ?? '',
      clientTcId: widget.userInfo?['tcKimlikNo'] ?? '',
      paymentAmount: 0.0,
      paymentExp: "",
      iptalExp: "",
      unitName: widget.advisorInfo?['department'] ?? '',
      unitId: 32, // Bu değer departmana göre değişecek
      advisorName: "${widget.advisorInfo?['title'] ?? ''} ${widget.advisorInfo?['name'] ?? ''}",
      reference: "",
      isAccess: false,
      image: null, // Resim yok
      notes: "Taahhütname ile oluşturulan randevu",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    print('🔍 APPOINTMENT INSERT MODEL:');
    print(appointmentInsert.toString());
    
    final requestBody = appointmentInsert.toApiJson();
    
    print('🔍 APPOINTMENT INSERT REQUEST: ${jsonEncode(requestBody)}');
    
    final response = await http.post(
      Uri.parse('https://adhapi-test.gazi.edu.tr/Appointment/AppointmentInsert'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
        'isshowmessage': 'true',
        'Origin': 'https://adh-test.gazi.edu.tr',
        'Referer': 'https://adh-test.gazi.edu.tr/',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36',
      },
      body: jsonEncode(requestBody),
    );
    
    print('🔍 APPOINTMENT INSERT RESPONSE: ${response.body}');
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['resultType'] != 1) {
        throw Exception(responseData['message'] ?? 'Randevu oluşturulamadı');
      }
      
      // Başarılı durum - randevu ID'sini logla
      final appointmentId = responseData['data'];
      print('✅ APPOINTMENT CREATED SUCCESSFULLY! ID: $appointmentId');
      print('✅ MESSAGE: ${responseData['message']}');
      print('✅ STATUS: ${AppointmentStatus.getStatusText(appointmentInsert.status)}');
      print('✅ TYPE: ${AppointmentType.getTypeText(appointmentInsert.type)}');
      print('✅ PAYMENT: ${PaymentStatus.getPaymentStatusText(appointmentInsert.paymentStatus)}');
      
    } else {
      throw Exception('HTTP Error: ${response.statusCode}');
    }
  }

  String _getFormattedDate() {
    final date = widget.appointmentDate ?? DateTime.now();
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _getDisplayName() {
    // Önce userInfo'dan ad ve soyad bilgilerini al
    final userAd = widget.userInfo?['ad'] ?? '';
    final userSoyad = widget.userInfo?['soyad'] ?? '';
    
    print('🔍 TAAHHUTNAME - _getDisplayName Debug:');
    print('  userAd from userInfo: "$userAd"');
    print('  userSoyad from userInfo: "$userSoyad"');
    print('  _kpsAd from KPS: "$_kpsAd"');
    print('  _kpsSoyad from KPS: "$_kpsSoyad"');
    
    if (userAd.isNotEmpty && userSoyad.isNotEmpty) {
      final fullName = '$userAd $userSoyad';
      print('  Using userInfo name: "$fullName"');
      return fullName;
    }
    
    // Eğer userInfo'da yoksa KPS'den gelen bilgileri kullan
    if (_kpsAd.isNotEmpty && _kpsSoyad.isNotEmpty) {
      final fullName = '$_kpsAd $_kpsSoyad';
      print('  Using KPS name: "$fullName"');
      return fullName;
    }
    
    print('  No name found, using default');
    return 'Bilinmeyen Kullanıcı';
  }

  String _getDisplayTcKimlikNo() {
    // Önce userInfo'dan TC kimlik no'yu al
    final userTc = widget.userInfo?['tcKimlikNo'] ?? '';
    final widgetTc = widget.tcKimlikNo ?? '';
    
    print('🔍 TAAHHUTNAME - _getDisplayTcKimlikNo Debug:');
    print('  userTc from userInfo: "$userTc"');
    print('  widgetTc from widget: "$widgetTc"');
    
    if (userTc.isNotEmpty) {
      print('  Using userInfo TC: "$userTc"');
      return userTc;
    }
    
    // Eğer userInfo'da yoksa widget parametresinden al
    if (widget.tcKimlikNo?.isNotEmpty == true) {
      print('  Using widget TC: "$widgetTc"');
      return widget.tcKimlikNo!;
    }
    
    print('  No TC found, returning empty');
    return '';
  }

  Widget _buildInfoTable() {
    print('🔍 TAAHHUTNAME - _buildInfoTable Debug:');
    print('  _isLoadingKps: $_isLoadingKps');
    
    if (_isLoadingKps) {
      return Container(
        height: 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 16),
              Text(
                'KPS verisi yükleniyor...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayName = _getDisplayName();
    final displayTc = _getDisplayTcKimlikNo();
    final tel = widget.userInfo?['tel'] ?? '';
    final adres = widget.userInfo?['adres'] ?? _kpsAdres;
    
    print('🔍 TAAHHUTNAME - Final Display Values:');
    print('  displayName: "$displayName"');
    print('  displayTc: "$displayTc"');
    print('  tel: "$tel"');
    print('  adres: "$adres"');

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      children: [
        _buildTableRow('Adı - Soyadı', ': $displayName'),
        _buildTableRow('T.C. Kimlik No', ': $displayTc'),
        _buildTableRow('Tel', ': $tel'),
        _buildTableRow('Adres', ': $adres'),
      ],
    );
  }

  Widget _buildLawInfoTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      children: [
        _buildTableRow('Kanun Numarası', ': 2547'),
        _buildTableRow('Kabul Tarihi', ': 04/11/1981'),
        _buildTableRow('Yayımlandığı Resmi Gazete Tarihi', ': 06/11/1981'),
        _buildTableRow('Yayımlandığı Resmi Gazete Sayısı', ': 17506'),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black87, width: 1),
            ),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: CustomPaint(
              size: Size(20, 20),
              painter: XIconPainter(),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context, false);
            },
          ),
        ),
        title: const Text(
          'Taahhütname',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _pageSlideAnimation,
        child: SlideTransition(
          position: _contentSlideAnimation,
          child: Column(
            children: [
              // Ana İçerik
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık - Resmi Format
                        Center(
                          child: Text(
                            'TAAHHÜTNAME',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Giriş Metni
                        Text(
                          'Gazi Üniversitesi Sağlık Bilimleri Fakültesi Öğretim Üyesinden ${widget.advisorInfo?['title'] ?? ''} ${widget.advisorInfo?['name'] ?? ''} dan Bilimsel Mütalaa görüş aldım. Bedelini Yükseköğretim Kurulu 2547 sayılı Kanunun 37.maddesine göre Özel Sigorta ve SGK\'dan talep etmeyeceğimi kabul, beyan ve taahhüt ederim.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.justify,
                          overflow: TextOverflow.visible,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Çizgi
                        Container(
                          height: 1,
                          color: Colors.grey.shade400,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // "Bu belge tarafımdan rızamla imzalanmıştır."
                        Padding(
                          padding: const EdgeInsets.only(left: 50),
                          child: Text(
                            'Bu belge tarafımdan rızamla imzalanmıştır.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Tarih Bölümü
                        Row(
                          children: [
                            Text(
                              'Tarih : ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.black87, width: 1),
                                  ),
                                ),
                                child: Text(
                                  _getFormattedDate(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Kişisel Bilgiler Tablosu
                        _buildInfoTable(),
                        
                        const SizedBox(height: 32),
                        
                        // Yükseköğretim Kanunu Bölümü
                        Text(
                          'YÜKSEKÖĞRETİM KANUNU',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Kanun Bilgileri
                        _buildLawInfoTable(),
                        
                        const SizedBox(height: 24),
                        
                        // Madde 37 Bölümü
                        Text(
                          'ÜNİVERSİTELERİN UYGULAMA ALANINA YARDIMI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          'Madde 37 - Yükseköğretim kurumları dışındaki kuruluş veya kişilerce, üniversite içinde veya dışında istihdam edilecek hizmetlerin gerektiği yerde, üniversiteler ve bağlı birimlerden istenecek, bilimsel proje, araştırma ve benzeri hizmetler için üniversitede ve üniversiteye bağlı kurumlarda, hasta muayene ve tedavisi ve bunlarla ilgili tıbbi tahliller ve araştırmalar üniversite yönetimine bildirilmek ve usulüne bağlı olmak üzere yapılabilir. Bu hususta alınacak ücretler ilgili Yükseköğretim kurumunun veya buna bağlı birimin özel sermayesine gelir kaydedilir.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.justify,
                          overflow: TextOverflow.visible,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Alt Kısım - Onay ve Buton
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Onay Checkbox'ı
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isAccepted 
                              ? Colors.blue.shade50 
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isAccepted 
                                ? Colors.blue.shade300 
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _isAccepted,
                                onChanged: _onCheckboxChanged,
                                activeColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Yukarıdaki taahhütname maddelerini okudum, anladım ve kabul ediyorum.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _isAccepted 
                                      ? Colors.blue.shade700 
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Kabul Et Butonu
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isAccepted ? _onAccept : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: _isAccepted
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.blue.shade600,
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [Colors.grey.shade300, Colors.grey.shade400],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isAccepted
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Kabul Et ve Devam Et',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// Custom X Icon Painter - SVG'deki X ikonunu çizer
class XIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Sol üstten sağ alta çizgi
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.8),
      paint,
    );

    // Sağ üstten sol alta çizgi
    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.2, size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
