import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class KvkkPage extends StatefulWidget {
  const KvkkPage({super.key});

  @override
  State<KvkkPage> createState() => _KvkkPageState();
}

class _KvkkPageState extends State<KvkkPage> {
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
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
                      'KVKK Aydınlatma Metni',
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
                    // Gazi Üniversitesi Logosu
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                              spreadRadius: 1,
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
                                  size: 60,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Başlık
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
                            'Kişisel Verilerin Korunması',
                            style: TextStyle(
                              fontSize: isIOS ? 22 : 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1e3c72),
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Aydınlatma Metni',
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
                    const SizedBox(height: 24),
                    
                    // KVKK Metni
                    Container(
                      padding: const EdgeInsets.all(20),
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
                          // Tanımlar Bölümü
                          Text(
                            'Tanımlar',
                            style: TextStyle(
                              fontSize: isIOS ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1e3c72),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'İşbu aydınlatma metninde geçen;',
                            style: TextStyle(
                              fontSize: isIOS ? 15 : 16,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Tanım listesi
                          _buildDefinitionItem(
                            'Kişisel Veri:',
                            'Kimliği belirli veya belirlenebilir gerçek kişiye ilişkin her türlü bilgiyi,',
                            isIOS,
                          ),
                          _buildDefinitionItem(
                            'Kişisel Verilerin Korunması Kanunu ("KVKK"):',
                            '7 Nisan 2016 tarihinde Resmi Gazete\'de yayınlanarak yürürlüğe giren 6698 sayılı Kişisel Verilerin Korunması Kanunu\'nu,',
                            isIOS,
                          ),
                          _buildDefinitionItem(
                            'Sabancı Vakfı:',
                            'Sabancı Center 34330 4. Levent Beşiktaş İstanbul Türkiye adresinde mukim Hacı Ömer Sabancı Vakfı\'nı,',
                            isIOS,
                          ),
                          _buildDefinitionItem(
                            'Veri İşleyen:',
                            'Veri sorumlusunun verdiği yetkiye dayanarak onun adına Kişisel Verileri işleyen gerçek veya tüzel kişiyi,',
                            isIOS,
                          ),
                          _buildDefinitionItem(
                            'Veri Sorumlusu:',
                            'Kişisel Verilerin işleme amaçlarını ve vasıtalarını belirleyen, veri kayıt sisteminin kurulmasından ve yönetilmesinden sorumlu olan gerçek veya tüzel kişiyi,',
                            isIOS,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ifade eder.',
                            style: TextStyle(
                              fontSize: isIOS ? 15 : 16,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Veri Sorumlusu Bölümü
                          Text(
                            'Veri Sorumlusu',
                            style: TextStyle(
                              fontSize: isIOS ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1e3c72),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'KVKK uyarınca muhatap, üye, bağışçı, bursiyer, stajyer, tedarikçi, ziyaretçi, hibe alan, ödül alan, desteklenen, Fark Yaratan, yarışmacı, program ortağı ve/veya vakıf çalışanı/yöneticisi sıfatıyla paylaştığınız kişisel verileriniz; veri sorumlusu olarak belirlenen Sabancı Vakfı tüzel kişiliği tarafından aşağıda belirtilen kapsamda değerlendirilecektir.',
                            style: TextStyle(
                              fontSize: isIOS ? 15 : 16,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Kişisel Verilerin İşlenme Amacı Bölümü
                          Text(
                            'Kişisel Verilerin İşlenme Amacı',
                            style: TextStyle(
                              fontSize: isIOS ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1e3c72),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'KVKK\'nın 4., 5. ve 6. maddeleri uyarınca kişisel verileriniz;',
                            style: TextStyle(
                              fontSize: isIOS ? 15 : 16,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Madde listesi
                          _buildListItem(
                            'Hukuka ve dürüstlük kurallarına uygun',
                            isIOS,
                          ),
                          _buildListItem(
                            'Doğru ve gerektiğinde güncel',
                            isIOS,
                          ),
                          _buildListItem(
                            'Belirli, açık ve meşru amaçlar için',
                            isIOS,
                          ),
                          _buildListItem(
                            'İşlendikleri amaçla bağlantılı, sınırlı ve ölçülü',
                            isIOS,
                          ),
                          _buildListItem(
                            'İlgili mevzuatta öngörülen veya işlendikleri amaç için gerekli olan süre kadar muhafaza edilme kurallarına uygun bir şekilde',
                            isIOS,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sabancı Vakfı\'nın aşağıda yer alan faaliyetleri ile bağlantılı olacak şekilde işlenecektir.',
                            style: TextStyle(
                              fontSize: isIOS ? 15 : 16,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Kapat butonu
                    SizedBox(
                      width: double.infinity,
                      height: isIOS ? 50 : 56,
                      child: ElevatedButton(
                        onPressed: _goBack,
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
                          'Kapat',
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
    );
  }

  Widget _buildDefinitionItem(String title, String content, bool isIOS) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isIOS ? 15 : 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1e3c72),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: isIOS ? 14 : 15,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String text, bool isIOS) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 12),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isIOS ? 14 : 15,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
