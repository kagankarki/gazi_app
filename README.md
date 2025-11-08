# 🏥 Gazi Üniversitesi Randevu Sistemi

Gazi Üniversitesi için geliştirilmiş modern ve kullanıcı dostu randevu yönetim uygulaması. Flutter ile geliştirilmiş bu mobil uygulama, öğrencilerin ve kullanıcıların kolayca randevu almasını, iptal etmesini ve danışman programlarını görüntülemesini sağlar.

## ✨ Özellikler

### 🔐 Güvenli Kimlik Doğrulama
- **KPS Entegrasyonu**: TC Kimlik No ve doğum tarihi ile güvenli kimlik doğrulama
- **Güvenlik Kodu**: Her işlemde rastgele oluşturulan güvenlik kodu ile ek güvenlik
- **Otomatik Veri Doldurma**: KPS'den gelen bilgilerle otomatik form doldurma

### 📅 Randevu Yönetimi
- **e-Randevu Alma**: Danışman seçimi, tarih ve saat seçimi ile kolay randevu alma
- **e-Randevu İptal**: Randevu numarası ile randevu iptal etme
- **Takvim Görünümü**: Görsel takvim ile uygun tarih seçimi
- **Zaman Slotları**: Danışman müsaitlik durumuna göre zaman slotları görüntüleme

### 👨‍⚕️ Danışman Yönetimi
- **Danışman Listesi**: Tüm danışmanları görüntüleme ve filtreleme
- **Danışman Programı**: Seçilen danışmanın müsaitlik programını görüntüleme
- **Danışman Detayları**: Danışman bilgilerini detaylı görüntüleme

### 📋 Diğer Özellikler
- **KVKK Uyumluluğu**: Kişisel verilerin korunması kanununa uygun bilgilendirme
- **Taahhütname**: Kullanıcı taahhütnamesi ve onay süreci
- **Admin Paneli**: Yönetim işlemleri için admin sayfası
- **Randevu Özeti**: Randevu detaylarını görüntüleme ve onaylama
- **Modern UI/UX**: Material Design 3 ile modern ve kullanıcı dostu arayüz
- **Animasyonlar**: Akıcı geçişler ve kullanıcı deneyimi için animasyonlar

## 🛠️ Teknolojiler

- **Flutter** `^3.6.1` - Cross-platform mobil uygulama geliştirme framework'ü
- **Dart** - Programlama dili
- **HTTP** `^1.1.0` - RESTful API iletişimi
- **URL Launcher** `^6.2.5` - Harici URL'leri açma
- **Material Design 3** - Modern UI bileşenleri

## 📱 Desteklenen Platformlar

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🚀 Kurulum

### Gereksinimler

- Flutter SDK (3.6.1 veya üzeri)
- Dart SDK
- Android Studio / Xcode (platforma göre)
- Git

### Adımlar

1. **Projeyi klonlayın:**
```bash
git clone https://github.com/kullaniciadi/gazi_app.git
cd gazi_app
```

2. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

3. **Uygulamayı çalıştırın:**
```bash
flutter run
```

### Platforma Özel Kurulum

#### Android
```bash
flutter run -d android
```

#### iOS
```bash
flutter run -d ios
```

#### Web
```bash
flutter run -d chrome
```

## 📁 Proje Yapısı

```
gazi_app/
├── lib/
│   ├── main.dart                 # Uygulama giriş noktası
│   ├── models/                   # Veri modelleri
│   │   ├── advisor_list.dart
│   │   └── appointment_insert.dart
│   ├── screens/                  # Ekranlar
│   │   ├── entry_page.dart       # Giriş sayfası
│   │   ├── appointment_page.dart # Randevu ana sayfası
│   │   ├── advisor_selection_page.dart # Danışman seçimi
│   │   ├── appointment_calendar.dart  # Takvim görünümü
│   │   ├── appointment_summary.dart   # Randevu özeti
│   │   ├── user_info_page.dart        # Kullanıcı bilgileri
│   │   ├── kvkk_page.dart             # KVKK sayfası
│   │   ├── taahhutname.dart           # Taahhütname
│   │   └── admin_page.dart            # Admin paneli
│   └── services/                 # Servisler
│       └── api_connection.dart   # API bağlantı servisi
├── assets/                       # Statik dosyalar
│   └── logo-gazi.png
├── android/                      # Android platform dosyaları
├── ios/                          # iOS platform dosyaları
├── web/                          # Web platform dosyaları
├── windows/                      # Windows platform dosyaları
├── macos/                        # macOS platform dosyaları
├── linux/                        # Linux platform dosyaları
├── pubspec.yaml                  # Proje bağımlılıkları
└── README.md                     # Bu dosya
```

## 🔌 API Entegrasyonu

Uygulama Gazi Üniversitesi API'si ile entegre çalışmaktadır:

### Randevu Alma

1. Uygulamayı açın
2. "e-Randevu" sekmesini seçin
3. TC Kimlik No, doğum tarihi ve güvenlik kodunu girin
4. "Devam Et" butonuna tıklayın
5. Danışman seçin
6. Tarih ve saat seçin
7. Randevu bilgilerini kontrol edin ve onaylayın

### Randevu İptal

1. Uygulamayı açın
2. "e-Randevu İptal" sekmesini seçin
3. TC Kimlik No ve randevu numarasını girin
4. "İptal Et" butonuna tıklayın

## 🎨 Ekran Görüntüleri

<img width="1229" height="676" alt="image" src="https://github.com/user-attachments/assets/1d3faaa7-5f06-4c61-8691-51f883f8197d" />


## 📝 Lisans

Bu proje özel bir projedir. Tüm hakları saklıdır.

## 👥 Geliştiriciler

- Gazi Üniversitesi - Proje sahibi

## 🙏 Teşekkürler

- Gazi Üniversitesi

---
