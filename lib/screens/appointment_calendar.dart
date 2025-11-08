import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import '../services/api_connection.dart';
import 'appointment_summary.dart';

class AppointmentCalendar extends StatefulWidget {
  final Map<String, String> selectedAdvisor;
  final String? tcKimlikNo;
  final String? userFullName;
  final String? userPhone;
  final String? userEmail;
  final String? userAddress;
  final String? birthDate;
  
  const AppointmentCalendar({
    super.key,
    required this.selectedAdvisor,
    this.tcKimlikNo,
    this.userFullName,
    this.userPhone,
    this.userEmail,
    this.userAddress,
    this.birthDate,
  });

  @override
  State<AppointmentCalendar> createState() => _AppointmentCalendarState();
}

class _AppointmentCalendarState extends State<AppointmentCalendar> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  bool _isLoading = false;
  bool _isLoadingSchedule = true;
  
  // API'den gelecek zaman slotları
  List<Map<String, dynamic>> _timeSlots = [];
  List<Map<String, dynamic>> _allScheduleData = []; // API'den gelen tam veri

  @override
  void initState() {
    super.initState();
    _loadAdvisorSchedule();
  }

  Future<void> _loadAdvisorSchedule() async {
    try {
      setState(() {
        _isLoadingSchedule = true;
      });

      final advisorId = int.parse(widget.selectedAdvisor['id'] ?? '69');
      final now = DateTime.now().toIso8601String();
      
      print('🔍 Loading schedule for advisor: $advisorId at time: $now');
      
      final scheduleData = await ApiConnection.getAdvisorSchedule(
        advisorId: advisorId,
        time: now,
      );

      print('🔍 Schedule data received: ${scheduleData.length} items');

      if (mounted) {
        setState(() {
          _allScheduleData = scheduleData;
          _updateTimeSlotsForSelectedDate();
          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      print('❌ Error loading advisor schedule: $e');
      if (mounted) {
        setState(() {
          _isLoadingSchedule = false;
          // Fallback data - gerçek görünümlü test verisi
          _timeSlots = [
            {'time': '09:00', 'available': true},
            {'time': '09:30', 'available': false},
            {'time': '10:00', 'available': true},
            {'time': '10:30', 'available': false},
            {'time': '11:00', 'available': true},
            {'time': '11:30', 'available': true},
            {'time': '13:00', 'available': false},
            {'time': '13:30', 'available': true},
            {'time': '14:00', 'available': true},
            {'time': '14:30', 'available': false},
            {'time': '15:00', 'available': true},
            {'time': '15:30', 'available': true},
          ];
        });
        
        // Kullanıcıya hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Randevu saatleri yüklenemedi. Örnek veriler gösteriliyor.')),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _updateTimeSlotsForSelectedDate() {
    print('🔍 Updating time slots for date: $_selectedDate');
    print('🔍 All schedule data count: ${_allScheduleData.length}');
    
    if (_allScheduleData.isEmpty) {
      print('⚠️ No schedule data available, using default slots');
      _timeSlots = [
        {'time': '09:00', 'available': true},
        {'time': '09:30', 'available': false},
        {'time': '10:00', 'available': true},
        {'time': '10:30', 'available': true},
        {'time': '11:00', 'available': false},
        {'time': '11:30', 'available': true},
        {'time': '13:00', 'available': true},
        {'time': '13:30', 'available': false},
        {'time': '14:00', 'available': true},
        {'time': '14:30', 'available': true},
        {'time': '15:00', 'available': false},
        {'time': '15:30', 'available': true},
      ];
      return;
    }
    
    try {
      // API'den gelen verileri filtrele
      final daySchedules = _allScheduleData.where((schedule) {
        try {
          final scheduleTime = DateTime.parse(schedule['time']);
          return _isSameDay(scheduleTime, _selectedDate);
        } catch (e) {
          print('Error parsing schedule time: ${schedule['time']}');
          return false;
        }
      }).toList();

      print('🔍 Found ${daySchedules.length} schedules for selected date');
      print('📅 Selected date: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}');

      // Tüm API verilerini debug et
      print('🔍 ALL API SCHEDULE DATA:');
      for (int i = 0; i < _allScheduleData.length; i++) {
        final schedule = _allScheduleData[i];
        print('  [$i] time: ${schedule['time']}, status: ${schedule['status']}, client: "${schedule['client']}", id: ${schedule['id']}');
      }

      // Saatleri organize et
      Map<String, bool> timeMap = {};
      
      // Mevcut randevuları işle
      for (var schedule in daySchedules) {
        try {
          final scheduleTime = DateTime.parse(schedule['time']);
          final timeStr = '${scheduleTime.hour.toString().padLeft(2, '0')}:${scheduleTime.minute.toString().padLeft(2, '0')}';
          
          // status: 1 = dolu, 0 = boş
          final isAvailable = schedule['status'] == 0;
          timeMap[timeStr] = isAvailable;
          
          print('🔍 Time slot: $timeStr - Available: $isAvailable (status: ${schedule['status']}, client: "${schedule['client']}")');
        } catch (e) {
          print('Error processing schedule: $e');
        }
      }

      // API'deki tüm unique saatleri al ve standart saatlerle birleştir
      Set<String> allTimes = {};
      
      // API'den gelen saatleri ekle
      for (var schedule in daySchedules) {
        try {
          final scheduleTime = DateTime.parse(schedule['time']);
          final timeStr = '${scheduleTime.hour.toString().padLeft(2, '0')}:${scheduleTime.minute.toString().padLeft(2, '0')}';
          allTimes.add(timeStr);
        } catch (e) {
          print('Error adding API time: $e');
        }
      }
      
      // Standart saatleri de ekle
      for (int hour = 9; hour <= 16; hour++) {
        for (int minute = 0; minute < 60; minute += 15) {
          final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          allTimes.add(timeStr);
        }
      }
      
      // Saatleri sırala ve time slots oluştur
      final sortedTimes = allTimes.toList()..sort();
      
      _timeSlots = sortedTimes.map((timeStr) {
        final isAvailable = timeMap[timeStr] ?? true; // Default: müsait
        print('🔍 Final time slot: $timeStr - Available: $isAvailable');
        return {
          'time': timeStr,
          'available': isAvailable,
        };
      }).toList();
      
      // Maksimum 16 slot göster (çok fazla olmasın)
      if (_timeSlots.length > 16) {
        _timeSlots = _timeSlots.take(16).toList();
      }

      print('🔍 Generated ${_timeSlots.length} time slots');
      
    } catch (e) {
      print('❌ Error in _updateTimeSlotsForSelectedDate: $e');
      // Fallback data
      _timeSlots = [
        {'time': '09:00', 'available': true},
        {'time': '10:00', 'available': false},
        {'time': '11:00', 'available': true},
        {'time': '13:00', 'available': true},
        {'time': '14:00', 'available': false},
        {'time': '15:00', 'available': true},
      ];
    }
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
        title: Text(
          'Randevu Takvimi',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: Colors.green,
                size: 20,
              ),
              onPressed: () async {
                HapticFeedback.lightImpact();
                
                // Cache'i temizle ve müsaitlik durumunu yeniden yükle
                setState(() {
                  _selectedTimeSlot = null;
                  _allScheduleData.clear(); // Cache'i temizle
                  _timeSlots.clear(); // Mevcut slotları temizle
                  _isLoadingSchedule = true; // Loading göster
                });
                
                print('🔄 Cache temizlendi, API\'den fresh data çekiliyor...');
                await _loadAdvisorSchedule();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Müsaitlik durumu yenilendi'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Danışman Bilgi Kartı
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                // Bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.selectedAdvisor['title']} ${widget.selectedAdvisor['name']}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.selectedAdvisor['department'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        color: Colors.green,
                        size: 8,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Aktif',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tarih Seçici
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: Colors.blue,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tarih Seçin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 14, // 2 hafta
                    itemBuilder: (context, index) {
                      final date = DateTime.now().add(Duration(days: index));
                      final isSelected = _isSameDay(_selectedDate, date);
                      final isToday = _isSameDay(DateTime.now(), date);
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                            _selectedTimeSlot = null; // Reset seçilen saat
                            _updateTimeSlotsForSelectedDate(); // Yeni tarihe göre saatleri güncelle
                          });
                          HapticFeedback.selectionClick();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 64,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.blue.shade600,
                                    ],
                                  )
                                : null,
                            color: !isSelected
                                ? isToday
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.grey[50]
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            border: isToday && !isSelected
                                ? Border.all(color: Colors.blue.shade300, width: 2)
                                : isSelected
                                    ? null
                                    : Border.all(color: Colors.grey.shade200, width: 1),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getDayName(date.weekday),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                _getMonthName(date.month),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Saat Seçici
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.blue,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Saat Seçin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedTimeSlot != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedTimeSlot!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _isLoadingSchedule
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Randevu saatleri yükleniyor...',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.5,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemCount: _timeSlots.length,
                            itemBuilder: (context, index) {
                        final slot = _timeSlots[index];
                        final isSelected = _selectedTimeSlot == slot['time'];
                        final apiAvailable = slot['available'] as bool; // API'den gelen gerçek durum
                        
                        // UI'de tersine göster: API'de available=true ise UI'de "Dolu" göster, API'de available=false ise UI'de "Müsait" göster
                        final uiAvailable = !apiAvailable;
                        
                        return GestureDetector(
                          onTap: uiAvailable
                              ? () {
                                  setState(() {
                                    _selectedTimeSlot = slot['time'];
                                  });
                                  HapticFeedback.selectionClick();
                                }
                              : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: isSelected && uiAvailable
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.blue.shade600,
                                    ],
                                  )
                                : null,
                            color: !uiAvailable
                                ? Colors.grey[100]
                                : isSelected
                                    ? null
                                    : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !uiAvailable
                                  ? Colors.grey[300]!
                                  : isSelected
                                      ? Colors.blue.shade600
                                      : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected && uiAvailable
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  slot['time'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: !uiAvailable
                                        ? Colors.grey[500]
                                        : isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  uiAvailable ? 'Müsait' : 'Dolu',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: !uiAvailable
                                        ? Colors.grey[500]
                                        : isSelected
                                            ? Colors.white70
                                            : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          
          // Randevu Al Butonu
          Container(
            margin: const EdgeInsets.all(16),
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _selectedTimeSlot != null && !_isLoading
                  ? _bookAppointment
                  : null,
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
                  gradient: _selectedTimeSlot != null && !_isLoading
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
                  boxShadow: _selectedTimeSlot != null && !_isLoading
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
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Randevu Al',
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
    );
  }

  String _getDayName(int weekday) {
    const days = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[weekday];
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return months[month];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _updateLocalScheduleForCreatedAppointment() {
    if (_selectedTimeSlot == null) return;
    
    print('🔄 Local olarak $_selectedTimeSlot saatini dolu olarak işaretliyorum');
    
    setState(() {
      // Seçili saati time slots'ta "dolu" yap
      for (int i = 0; i < _timeSlots.length; i++) {
        if (_timeSlots[i]['time'] == _selectedTimeSlot) {
          _timeSlots[i]['available'] = true; // API mantığı: true = dolu, false = müsait
          print('✅ ${_selectedTimeSlot} saati dolu olarak işaretlendi');
          break;
        }
      }
      
      // Aynı zamanda allScheduleData'ya da ekle
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(_selectedTimeSlot!.split(':')[0]),
        int.parse(_selectedTimeSlot!.split(':')[1]),
      );
      
      final newScheduleEntry = {
        'time': appointmentDateTime.toIso8601String(),
        'status': 1, // 1 = dolu
        'client': 'Yeni Randevu',
        'id': DateTime.now().millisecondsSinceEpoch,
      };
      
      _allScheduleData.add(newScheduleEntry);
      print('✅ Yeni randevu schedule data\'ya eklendi: ${newScheduleEntry}');
    });
  }

  void _bookAppointment() async {
    if (_selectedTimeSlot == null) return;
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // AppointmentSummary sayfasına yönlendir ve sonucu bekle
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AppointmentSummary(
          selectedAdvisor: widget.selectedAdvisor,
          selectedDate: _selectedDate,
          selectedTime: _selectedTimeSlot!,
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
          const curve = Curves.easeInOut;

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
    
    // Eğer randevu başarıyla oluşturulduysa schedule'ı yenile
    if (result == true) {
      print('🔄 Randevu oluşturuldu, schedule yenileniyor...');
      
      // 1. Local olarak seçili saati "dolu" yap
      _updateLocalScheduleForCreatedAppointment();
      
      // 2. Seçili saati temizle
      setState(() {
        _selectedTimeSlot = null;
      });
      
      // 3. API'den yeniden yükle (biraz gecikmeli)
      Future.delayed(Duration(seconds: 1), () async {
        if (mounted) {
          await _loadAdvisorSchedule();
          print('🔄 API\'den schedule yeniden yüklendi');
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Randevu oluşturuldu ve takvim güncellendi'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}