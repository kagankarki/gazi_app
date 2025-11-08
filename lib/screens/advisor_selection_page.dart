import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'appointment_calendar.dart';
import '../models/advisor_list.dart' as advisor_models;

/// Danışman seçim sayfası
/// Kullanıcının randevu almak istediği danışmanı seçmesini sağlar
/// API'den gerçek danışman verilerini çeker ve listeler
class AdvisorSelectionPage extends StatefulWidget {
  final String? tcKimlikNo;
  final String? userFullName;
  final String? userPhone;
  final String? userEmail;
  final String? userAddress;
  final String? birthDate;
  
  const AdvisorSelectionPage({
    super.key,
    this.tcKimlikNo,
    this.userFullName,
    this.userPhone,
    this.userEmail,
    this.userAddress,
    this.birthDate,
  });

  @override
  State<AdvisorSelectionPage> createState() => _AdvisorSelectionPageState();
}

/// AdvisorSelectionPage'in state yönetimi sınıfı
/// Danışman listesini yönetir, animasyonları kontrol eder
/// API'den danışman verilerini çeker ve seçim işlemlerini yapar
class _AdvisorSelectionPageState extends State<AdvisorSelectionPage> 
    with TickerProviderStateMixin {
  String? _selectedAdvisor;
  bool _mounted = true;
  
  // Danışman listesi (API'den gelecek)
  List<advisor_models.Advisor> _advisors = [];
  bool _isLoadingAdvisors = true;
  
  // Animasyon controller'ları
  late AnimationController _logoAnimationController;
  late AnimationController _titleAnimationController;
  late AnimationController _formAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _formFadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animasyon controller'larını başlat
    _initializeAnimations();
    
    // Animasyonları başlat
    _startAnimations();
    
    // Danışman listesini API'den yükle
    _loadAdvisors();
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

    // Başlık animasyonu
    _titleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _titleSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _titleAnimationController,
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
      _titleAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _formAnimationController.forward();
    });
  }

  Future<void> _loadAdvisors() async {
    try {
      // Yeni API'den danışman listesini çek
      final advisors = await advisor_models.AdvisorList.fetchAdvisors();
      
      if (_mounted) {
        setState(() {
          _advisors = advisors;
          _isLoadingAdvisors = false;
        });
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          _isLoadingAdvisors = false;
        });
        
        // Hata durumunda snackbar göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Danışman listesi yüklenemedi: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }


  @override
  void dispose() {
    _mounted = false;
    _logoAnimationController.dispose();
    _titleAnimationController.dispose();
    _formAnimationController.dispose();
    super.dispose();
  }

  void _selectAdvisor(int advisorId) {
    setState(() {
      _selectedAdvisor = advisorId.toString();
    });
    HapticFeedback.selectionClick();
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  void _continueToNext() {
    if (_selectedAdvisor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir danışman seçiniz'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      HapticFeedback.heavyImpact();
      return;
    }
    
    HapticFeedback.lightImpact();
    
    // Seçilen danışmanı bul
    final selectedAdvisor = _advisors.firstWhere(
      (advisor) => advisor.id.toString() == _selectedAdvisor,
    );
    
    // Randevu takvimi sayfasına yönlendir
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AppointmentCalendar(
              selectedAdvisor: {
                'id': selectedAdvisor.id.toString(),
                'name': selectedAdvisor.fullName,
                'title': selectedAdvisor.title,
                'department': selectedAdvisor.uniteName,
                'email': selectedAdvisor.email,
                'telNo': selectedAdvisor.telNo,
              },
              tcKimlikNo: widget.tcKimlikNo,
              userFullName: widget.userFullName,
              userPhone: widget.userPhone,
              userEmail: widget.userEmail,
              userAddress: widget.userAddress,
              birthDate: widget.birthDate,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
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
                      'Danışman Seçimi',
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
                    
                    // Başlık metinleri (Animasyonlu)
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(_titleSlideAnimation),
                      child: Container(
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
                    ),
                    const SizedBox(height: 32),
                    
                    // Danışman Seçme Alanı (Animasyonlu)
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
                            Text(
                              'Danışman Seçiniz',
                              style: TextStyle(
                                fontSize: isIOS ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1e3c72),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Danışman listesi
                            if (_isLoadingAdvisors)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                ),
                              )
                            else
                              ..._advisors.map((advisor) => _buildAdvisorCard(
                                advisor,
                                _selectedAdvisor == advisor.id.toString(),
                                isIOS,
                              )).toList(),
                            
                            const SizedBox(height: 32),
                            
                            // Devam Et butonu
                            SizedBox(
                              width: double.infinity,
                              height: isIOS ? 50 : 56,
                              child: ElevatedButton(
                                onPressed: _continueToNext,
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
                                  'Devam Et',
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
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisorCard(advisor_models.Advisor advisor, bool isSelected, bool isIOS) {
    return GestureDetector(
      onTap: () => _selectAdvisor(advisor.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(isIOS ? 8 : 12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Seçim göstergesi
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.blue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Danışman bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    advisor.getUniqueDisplayName(_advisors),
                    style: TextStyle(
                      fontSize: isIOS ? 16 : 17,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.blue : const Color(0xFF1e3c72),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    advisor.uniteName,
                    style: TextStyle(
                      fontSize: isIOS ? 14 : 15,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Seçim ikonu
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.blue : Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
