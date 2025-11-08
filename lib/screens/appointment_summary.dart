import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'taahhutname.dart';

class AppointmentSummary extends StatefulWidget {
  final Map<String, String> selectedAdvisor;
  final DateTime selectedDate;
  final String selectedTime;
  final String? tcKimlikNo; // TC Kimlik numarası
  final String? userFullName; // Kullanıcı adı soyadı
  final String? userPhone; // Kullanıcı telefonu
  final String? userEmail; // Kullanıcı e-posta
  final String? userAddress; // Kullanıcı adresi
  final String? birthDate; // Doğum tarihi
  
  const AppointmentSummary({
    super.key,
    required this.selectedAdvisor,
    required this.selectedDate,
    required this.selectedTime,
    this.tcKimlikNo,
    this.userFullName,
    this.userPhone,
    this.userEmail,
    this.userAddress,
    this.birthDate,
  });

  @override
  State<AppointmentSummary> createState() => _AppointmentSummaryState();
}

class _AppointmentSummaryState extends State<AppointmentSummary> 
    with TickerProviderStateMixin {
  bool _isConfirming = false;
  bool _taahhutAccepted = false;
  
  // Animasyon controller'ları
  late AnimationController _cardAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _cardScaleAnimation;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _buttonFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Kart animasyonu
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Buton animasyonu
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _buttonFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _cardAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _buttonAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    const days = ['', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    
    return '${widget.selectedDate.day} ${months[widget.selectedDate.month]} ${widget.selectedDate.year}, ${days[widget.selectedDate.weekday]}';
  }

  String _extractFirstName(String fullName) {
    if (fullName.isEmpty) return '';
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  String _extractLastName(String fullName) {
    if (fullName.isEmpty) return '';
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  void _showTaahhutname() async {
    HapticFeedback.lightImpact();
    
    // Taahhütname sayfasını aç ve sonucu bekle
    final bool? accepted = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TaahhutnamePage(
          userInfo: {
            'ad': _extractFirstName(widget.userFullName ?? ''),
            'soyad': _extractLastName(widget.userFullName ?? ''),
            'tcKimlikNo': widget.tcKimlikNo ?? '',
            'tel': widget.userPhone ?? '',
            'email': widget.userEmail ?? '',
            'adres': widget.userAddress ?? '',
          },
          advisorInfo: widget.selectedAdvisor,
          appointmentDate: widget.selectedDate,
          appointmentTime: widget.selectedTime, // Randevu saatini geç
          tcKimlikNo: widget.tcKimlikNo, // TC'yi direkt geç
          birthDate: widget.birthDate, // Doğum tarihini geç
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    
    if (accepted == true) {
      setState(() {
        _taahhutAccepted = true;
      });
      
      // Kabul edildi mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Text('Taahhütname kabul edildi. Artık randevunuzu onaylayabilirsiniz.')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _confirmAppointment() async {
    if (!_taahhutAccepted) {
      _showTaahhutname();
      return;
    }

    // Doğrudan taahhütname sayfasına git ve randevu oluşturma işlemini orada yap
    _showTaahhutname();
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
            icon: Icon(
              isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
              color: Colors.black87,
              size: 20,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        title: const Text(
          'Randevu Özeti',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Başarı İkonu
            ScaleTransition(
              scale: _cardScaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Ana Bilgi Kartı
            SlideTransition(
              position: _cardSlideAnimation,
              child: ScaleTransition(
                scale: _cardScaleAnimation,
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
                    children: [
                      // Başlık
                      Text(
                        'Randevu Detayları',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Danışman Bilgisi
                      _buildDetailRow(
                        Icons.person,
                        'Danışman',
                        '${widget.selectedAdvisor['title']} ${widget.selectedAdvisor['name']}',
                        Colors.blue,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Bölüm Bilgisi
                      _buildDetailRow(
                        Icons.school,
                        'Bölüm',
                        widget.selectedAdvisor['department'] ?? '',
                        Colors.orange,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tarih Bilgisi
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Tarih',
                        _getFormattedDate(),
                        Colors.green,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Saat Bilgisi
                      _buildDetailRow(
                        Icons.access_time,
                        'Saat',
                        widget.selectedTime,
                        Colors.purple,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Konum Bilgisi
                      _buildDetailRow(
                        Icons.location_on,
                        'Konum',
                        'Emek, Bişkek Cd. 6. Sokak, Çankaya/Ankara',
                        Colors.red,
                      ),
                      
                      if (widget.selectedAdvisor['email']?.isNotEmpty == true) ...[
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          Icons.email,
                          'E-posta',
                          widget.selectedAdvisor['email']!,
                          Colors.red,
                        ),
                      ],
                      
                      if (widget.selectedAdvisor['telNo']?.isNotEmpty == true) ...[
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          Icons.phone,
                          'Telefon',
                          widget.selectedAdvisor['telNo']!,
                          Colors.teal,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Uyarı Kartı
            SlideTransition(
              position: _cardSlideAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 43, 93),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color.fromARGB(255, 0, 64, 255),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color.fromARGB(255, 0, 64, 255),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Önemli Bilgiler',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Ünitelerimizde Öğretim Görevlisi (prof., doç., dr.) danışmanlıklarından ücret alınmakla birlikte farklılık göstermektedir. Ücret bilgisi için Döner Sermaye Birimi ile iletişime geçiniz.',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color.fromARGB(255, 255, 255, 255),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Onay Butonu
            FadeTransition(
              opacity: _buttonFadeAnimation,
              child: Container(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: !_isConfirming ? _confirmAppointment : null,
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
                      gradient: !_isConfirming
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
                      boxShadow: !_isConfirming
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
                      child: _isConfirming
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Randevu Oluşturuluyor...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _taahhutAccepted ? 'Randevuyu Onayla' : 'Taahhütname & Onayla',
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
            ),
            
            const SizedBox(height: 16),
            
            // İptal Butonu
            FadeTransition(
              opacity: _buttonFadeAnimation,
              child: TextButton(
                onPressed: !_isConfirming
                    ? () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      }
                    : null,
                child: Text(
                  'Geri Dön',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isConfirming ? Colors.grey : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
