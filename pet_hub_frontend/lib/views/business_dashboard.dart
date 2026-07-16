import 'dart:convert';
import 'dart:io' show Platform; 
import 'package:flutter/services.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/merchant_config.dart';
import 'customer_portal.dart';
import 'manage_team_panel.dart';
import 'manage_hours_panel.dart'; 
import 'customer_info_panel.dart'; // New separation file layout layer integration

class UnifiedMerchantDashboard extends StatefulWidget {
  final MerchantConfig config;
  final String authToken; 
  final bool isAdmin; 
  final VoidCallback onLogout;
  final Function(MerchantConfig) onConfigChanged;

  const UnifiedMerchantDashboard({
    super.key,
    required this.config,
    required this.authToken, 
    required this.isAdmin, 
    required this.onLogout,
    required this.onConfigChanged,
  });

  @override
  State<UnifiedMerchantDashboard> createState() => _UnifiedMerchantDashboardState();
}

class _UnifiedMerchantDashboardState extends State<UnifiedMerchantDashboard> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final _btnBookController = TextEditingController();
  final _btnCancelController = TextEditingController();
  final _btnEditController = TextEditingController();
  final _txtRevenueController = TextEditingController();
  List<dynamic> _businessHoursConfig = [];

  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  String _activeScheduleView = 'Daily List View'; 
  final List<String> _scheduleViewOptions = [
    'Daily List View', 
    'Daily Timeline Grid', 
    'One Week Grid Summary'
  ];

  bool _isServiceMatrixVisible = true;
  bool _isServiceLoading = false; 
  bool _isAppointmentsLoading = false;

  // Preset slots for simple dropdown pickers
  final List<String> _timePresetSlots = [
    '08:00', '08:15', '08:30', '08:45',
    '09:00', '09:15', '09:30', '09:45',
    '10:00', '10:15', '10:30', '10:45',
    '11:00', '11:15', '11:30', '11:45',
    '12:00', '12:15', '12:30', '12:45',
    '13:00', '13:15', '13:30', '13:45',
    '14:00', '14:15', '14:30', '14:45',
    '15:00', '15:15', '15:30', '15:45',
    '16:00', '16:15', '16:30', '16:45',
    '17:00'
  ];

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    return Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }

  late TabController _drawerTabController;
  List<Map<String, dynamic>> mockAppointments = []; 
  List<Map<String, dynamic>> liveServiceMatrices = [];

  @override
  void initState() {
    super.initState();
    _drawerTabController = TabController(length: widget.isAdmin ? 4 : 1, vsync: this);
    _syncControllers();
    _fetchServiceMatrices(); 
    _fetchDashboardAppointments();
    _fetchBusinessHours(); 
  }

  @override
  void dispose() {
    _drawerTabController.dispose();
    _btnBookController.dispose();
    _btnCancelController.dispose();
    _btnEditController.dispose();
    _txtRevenueController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UnifiedMerchantDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAdmin != oldWidget.isAdmin) {
      _drawerTabController.dispose();
      _drawerTabController = TabController(length: widget.isAdmin ? 4 : 1, vsync: this);
    }
  }

  void _syncControllers() {
    _btnBookController.text = widget.config.getTxt('btn_book', 'Manual Booking');
    _btnCancelController.text = widget.config.getTxt('btn_cancel', 'Cancel');
    _btnEditController.text = widget.config.getTxt('btn_edit', 'Reschedule');
    _txtRevenueController.text = widget.config.getTxt('txt_revenue', 'Today Forecast Revenue');
  }

  Future<void> _fetchServiceMatrices() async {
    setState(() => _isServiceLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/matrix?merchantId=${widget.config.merchantId}'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            liveServiceMatrices = List<Map<String, dynamic>>.from(responseData['data']);
          });
        }
      } else {
        _showSnackBar('❌ Failed to fetch backend service options matrix schema models.');
      }
    } catch (networkError) {
      _showSnackBar('❌ Transport layer connection fault during background matrix synchronization.');
    } finally {
      setState(() => _isServiceLoading = false);
    }
  }

  Future<void> _fetchBusinessHours() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/merchant/${widget.config.merchantId}/hours'),
        headers: {
          // 'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _businessHoursConfig = responseData['data'];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchDashboardAppointments() async {
    setState(() => _isAppointmentsLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/${widget.config.merchantId}/dashboard'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
          'merchantId': widget.config.merchantId,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List recentApps = responseData['data']['recentAppointments'] ?? [];
          
          List<Map<String, dynamic>> parsedLiveList = [];
          for (var item in recentApps) {
            final DateTime startTime = DateTime.parse(item['time']).toLocal();
            final DateTime endTime = DateTime.parse(item['endTime']).toLocal();
            final String timeRangeString = 
                "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";

            parsedLiveList.add({
              'id': item['id'],
              'time': timeRangeString,
              'rawStartTime': startTime,
              'rawEndTime': endTime,
              'weekdayIndex': startTime.weekday,
              'petName': item['petName'] ?? 'Unknown Pet',
              'breed': item['breed'] ?? 'Unknown Breed',
              'ownerName': item['clientName'] ?? 'No Name',
              'ownerEmail': item['clientEmail'] ?? '',
              'ownerPhone': item['clientPhone'] ?? '',
              'pastMerchantVisitsCount': 1,
              'service': item['serviceName'] ?? 'General Treatment',
              'price': (item['price'] as num?)?.toDouble() ?? 0.0,
              'status': item['status'] ?? 'PENDING',
              'isCheckedIn': item['isCheckedIn'] ?? false,
              'isDepositPaid': item['depositPaid'] ?? false,
              'isReadyForPickup': item['isReadyToPickup'] ?? false,
              'isLoyaltyWaived': item['isLoyaltyWaived'] ?? false,
              'staffTags': item['internalTags'] != null ? List<String>.from(item['internalTags']) : [],
            });
          }

          setState(() {
            mockAppointments = parsedLiveList;
          });
        }
      } else {
        _showSnackBar('❌ Failed to fetch real-time production appointment records.');
      }
    } catch (e) {
      _showSnackBar('❌ Connection error querying core administrative dashboard data.');
    } finally {
      setState(() => _isAppointmentsLoading = false);
    }
  }

  bool _checkIsDayClosed(DateTime date) {
    if (_businessHoursConfig.isEmpty) return false;
    final dayRecord = _businessHoursConfig.firstWhere(
      (element) => element['dayOfWeek'] == date.weekday,
      orElse: () => null,
    );
    return dayRecord != null && dayRecord['isClosed'] == true;
  }

  void _saveUiTextConfigToDatabase() {
    MerchantConfig updated = MerchantConfig(
      merchantId: widget.config.merchantId,
      userId: widget.config.userId,
      businessName: widget.config.businessName,
      logoIcon: widget.config.logoIcon,
      primaryColorValue: widget.config.primaryColorValue,
      tags: widget.config.tags,
      uiDictionary: {
        'btn_book': _btnBookController.text,
        'btn_cancel': _btnCancelController.text,
        'btn_edit': _btnEditController.text,
        'txt_revenue': _txtRevenueController.text,
      },
    );
    widget.onConfigChanged(updated);
    if (_scaffoldKey.currentState!.isEndDrawerOpen) {
      Navigator.pop(context);
    }
    _showSnackBar('💾 System settings synchronized globally across clusters.');
  }

  Future<void> _createServiceMatrixTier({
    required String name,
    required String coatType,
    required String weightTier,
    required int duration,
    required int priceCents,
  }) async {
    setState(() => _isServiceLoading = true);
    final String verifiedMerchantId = widget.config.merchantId;

    final Map<String, dynamic> payload = {
      'merchantId': verifiedMerchantId, 
      'name': name,    
      'speciesId': 1,                     
      'coatType': coatType,
      'weightTier': weightTier,
      'durationMinutes': duration,
      'priceCentsAud': priceCents,
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/matrix'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode(payload),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && responseData['success'] == true) {
        await _fetchServiceMatrices();
        _showSnackBar('🚀 New pricing matrix synchronized with backend production database.');
      } else {
        _showSnackBar('❌ Sync failed: ${responseData['message'] ?? 'Unknown controller validation error.'}');
      }
    } catch (networkError) {
      _showSnackBar('❌ Transport Layer Failure: Unable to locate target backend API cluster routes.');
    } finally {
      setState(() => _isServiceLoading = false);
    }
  }

  double get todayRevenue {
    final targetDate = _selectedDay ?? DateTime.now();
    return mockAppointments
        .where((app) => isSameDay(app['rawStartTime'], targetDate))
        .where((app) => app['status'] == 'CONFIRMED' || app['status'] == 'PAID' || app['status'] == 'PENDING' || app['status'] == 'COMPLETED')
        .map((app) => app['price'] as double)
        .fold(0, (p, e) => p + e);
  }

  void _showCreateBookingDialog() {
    final dogNameCtrl = TextEditingController();
    final dogBreedCtrl = TextEditingController();
    final dogWeightCtrl = TextEditingController(); // Added controller for dog weight
    final ownerNameCtrl = TextEditingController();
    final ownerPhoneCtrl = TextEditingController();
    final ownerEmailCtrl = TextEditingController();
    final dogDescCtrl = TextEditingController();

    Map<String, dynamic>? selectedMatrixRow;
    String selectedGender = 'MALE';
    bool isDesexed = false;
    DateTime? selectedDogDob; // Added state tracker for dog date of birth
    
    DateTime selectedBookingDate = _selectedDay ?? DateTime.now();
    bool isDayClosed = _checkIsDayClosed(selectedBookingDate);
    
    // List<String> dynamicAvailableSlots = [];
    // String? selectedBookingTimeSlot;
    List<String> operationalHoursTimeOptions = [];
    String? selectedOperationalTime;
    bool isLoadingSlots = false;
    bool hasFetchedInitialSlots = false;

    if (liveServiceMatrices.isNotEmpty) {
      selectedMatrixRow = liveServiceMatrices.first;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_task_outlined, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text('Create New Booking Instance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              bool isDayClosed = _checkIsDayClosed(selectedBookingDate);

              Future<void> updateCapacityAvailableSlots() async {
                if (selectedMatrixRow == null || isDayClosed) {
                  // setDialogState(() {
                  //   dynamicAvailableSlots = [];
                  //   selectedBookingTimeSlot = null;
                  // });
                  return;
                }
                
                setDialogState(() {
                  isLoadingSlots = true;
                });

                try {
                  // 1. Format the selected date to YYYY-MM-DD string required by the backend
                  final String formattedDate = "${selectedBookingDate.year}-"
                      "${selectedBookingDate.month.toString().padLeft(2, '0')}-"
                      "${selectedBookingDate.day.toString().padLeft(2, '0')}";
                  
                  // 2. Dynamic duration value (Fallback to 60 if your state/matrix selection isn't loaded yet)
                  // Replace this with your actual state variable (e.g., selectedServiceMatrix.durationMinutes)
                  final int durationMinutes = selectedMatrixRow?['durationMinutes'] ?? 60;
                  

                  // 3. Updated URL targeting the new bookings slots endpoint with query parameters
                  final String targetUrl = '$_baseUrl/api/v1/bookings/available-slots'
                      '?merchantId=${widget.config.merchantId}'
                      '&date=$formattedDate'
                      '&duration=$durationMinutes';
                  
                  final response = await http.get(
                    Uri.parse(targetUrl),
                    headers: {
                      'Content-Type': 'application/json',
                    },
                  );

                  if (response.statusCode == 200) {
                    final Map<String, dynamic> parsedBody = json.decode(response.body);
                    if (parsedBody['success'] == true && parsedBody['data'] is List) {
                      final List<dynamic> backendSlots = parsedBody['data'];

                      setDialogState(() {
                        if (backendSlots.isNotEmpty) {
                          isDayClosed = false;
                          
                          // 4. Map the 24h backend slots (e.g., "14:30") into the "02:30 PM" UI display format
                          operationalHoursTimeOptions = backendSlots.map<String>((slot) {
                            final parts = slot.toString().split(':');
                            final int hour = int.parse(parts[0]);
                            final String minute = parts[1]; // Dynamically preserves :00 or :30 from backend
                            
                            final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                            final String amPm = hour >= 12 ? 'PM' : 'AM';
                            final String paddedHour = displayHour.toString().padLeft(2, '0');
                            
                            return '$paddedHour:$minute $amPm';
                          }).toList();
                        } else {
                          // If no slots are returned, the merchant is either closed or completely fully booked
                          isDayClosed = true;
                          operationalHoursTimeOptions = [];
                        }

                        // Assign initial default selection value safely
                        if (operationalHoursTimeOptions.isNotEmpty) {
                          selectedOperationalTime = operationalHoursTimeOptions.first;
                        } else {
                          selectedOperationalTime = null;
                        }
                      });
                    }
                  } else {
                    setDialogState(() => isDayClosed = _checkIsDayClosed(selectedBookingDate));
                  }
                } catch (_) {
                  setDialogState(() => isDayClosed = _checkIsDayClosed(selectedBookingDate));
                } finally {
                  setDialogState(() => isLoadingSlots = false);
                }
              }

              if (!hasFetchedInitialSlots) {
                hasFetchedInitialSlots = true;
                if (!isDayClosed) {
                  Future.delayed(Duration.zero, () => updateCapacityAvailableSlots());
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Service Matrix Tier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Map<String, dynamic>>(
                                isExpanded: true,
                                value: selectedMatrixRow,
                                items: liveServiceMatrices.map((matrix) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: matrix,
                                    child: Text('${matrix['name']} (${matrix['weightTier']} / ${matrix['coatType']}) - \$${((matrix['priceCentsAud'] ?? 0) / 100).toStringAsFixed(2)}'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setDialogState(() => selectedMatrixRow = val);
                                  updateCapacityAvailableSlots(); 
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          const Text('Appointment Date & Time Selection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.calendar_today, size: 16),
                                  label: Text('Date: ${selectedBookingDate.day}/${selectedBookingDate.month}/${selectedBookingDate.year}'),
                                  // Locate this part within _showCreateBookingDialog -> StatefulBuilder -> OutlinedButton.icon
                                  onPressed: () async {
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: selectedBookingDate,
                                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                                    );
                                    if (pickedDate != null) {
                                      setDialogState(() {
                                        selectedBookingDate = pickedDate;
                                        isLoadingSlots = true;
                                      });

                                     try {
                                        // 1. Format the selected date to YYYY-MM-DD string required by the backend
                                        final String formattedDate = "${selectedBookingDate.year}-"
                                            "${selectedBookingDate.month.toString().padLeft(2, '0')}-"
                                            "${selectedBookingDate.day.toString().padLeft(2, '0')}";
                                        
                                        // 2. Dynamic duration value (Fallback to 60 if your state/matrix selection isn't loaded yet)
                                        // Replace this with your actual state variable (e.g., selectedServiceMatrix.durationMinutes)
                                        final int durationMinutes = selectedMatrixRow?['durationMinutes'] ?? 60;
                                        

                                        // 3. Updated URL targeting the new bookings slots endpoint with query parameters
                                        final String targetUrl = '$_baseUrl/api/v1/bookings/available-slots'
                                            '?merchantId=${widget.config.merchantId}'
                                            '&date=$formattedDate'
                                            '&duration=$durationMinutes';
                                        
                                        final response = await http.get(
                                          Uri.parse(targetUrl),
                                          headers: {
                                            'Content-Type': 'application/json',
                                          },
                                        );

                                        if (response.statusCode == 200) {
                                          final Map<String, dynamic> parsedBody = json.decode(response.body);
                                          if (parsedBody['success'] == true && parsedBody['data'] is List) {
                                            final List<dynamic> backendSlots = parsedBody['data'];

                                            setDialogState(() {
                                              if (backendSlots.isNotEmpty) {
                                                isDayClosed = false;
                                                
                                                // 4. Map the 24h backend slots (e.g., "14:30") into the "02:30 PM" UI display format
                                                operationalHoursTimeOptions = backendSlots.map<String>((slot) {
                                                  final parts = slot.toString().split(':');
                                                  final int hour = int.parse(parts[0]);
                                                  final String minute = parts[1]; // Dynamically preserves :00 or :30 from backend
                                                  
                                                  final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                                                  final String amPm = hour >= 12 ? 'PM' : 'AM';
                                                  final String paddedHour = displayHour.toString().padLeft(2, '0');
                                                  
                                                  return '$paddedHour:$minute $amPm';
                                                }).toList();
                                              } else {
                                                // If no slots are returned, the merchant is either closed or completely fully booked
                                                isDayClosed = true;
                                                operationalHoursTimeOptions = [];
                                              }

                                              // Assign initial default selection value safely
                                              if (operationalHoursTimeOptions.isNotEmpty) {
                                                selectedOperationalTime = operationalHoursTimeOptions.first;
                                              } else {
                                                selectedOperationalTime = null;
                                              }
                                            });
                                          }
                                        } else {
                                          setDialogState(() => isDayClosed = _checkIsDayClosed(selectedBookingDate));
                                        }
                                      } catch (_) {
                                        setDialogState(() => isDayClosed = _checkIsDayClosed(selectedBookingDate));
                                      } finally {
                                        setDialogState(() => isLoadingSlots = false);
                                      }
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: isDayClosed ? Colors.red.shade300 : Colors.grey.shade300), 
                                    borderRadius: BorderRadius.circular(4),
                                    color: isDayClosed ? Colors.red.shade50 : (isLoadingSlots ? Colors.grey.shade100 : Colors.white),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: isDayClosed 
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 12.0),
                                            child: Text('SHOP CLOSED', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                          )
                                        : (isLoadingSlots
                                            ? const SizedBox(
                                                height: 20, 
                                                width: 20, 
                                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                              )
                                            : DropdownButton<String>(
                                                isExpanded: true,
                                                hint: const Text('No available slots', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                                                value: selectedOperationalTime,
                                                items: operationalHoursTimeOptions.map((time) {
                                                  return DropdownMenuItem<String>(value: time, child: Text(time));
                                                }).toList(),
                                                onChanged: (val) => setDialogState(() => selectedOperationalTime = val),
                                              )),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),

                          Row(
                            children: [
                              Expanded(child: TextField(controller: dogNameCtrl, decoration: const InputDecoration(labelText: 'Dog Name *', border: OutlineInputBorder()))),
                              const SizedBox(width: 12),
                              Expanded(child: TextField(controller: dogBreedCtrl, decoration: const InputDecoration(labelText: 'Dog Breed Variant *', border: OutlineInputBorder()))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.cake_outlined, size: 16),
                                  label: Text(selectedDogDob == null 
                                      ? 'Select Dog DOB *' 
                                      : 'DOB: ${selectedDogDob!.day}/${selectedDogDob!.month}/${selectedDogDob!.year}'),
                                  onPressed: () async {
                                    final pickedDob = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDogDob ?? DateTime.now().subtract(const Duration(days: 365 * 2)),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now(),
                                    );
                                    if (pickedDob != null) {
                                      setDialogState(() => selectedDogDob = pickedDob);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: dogWeightCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // Regex ensuring numeric floating input restriction
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Dog Weight (kg) *', 
                                    border: OutlineInputBorder(),
                                    hintText: 'e.g., 14.5'
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedGender,
                                      items: const [
                                        DropdownMenuItem(value: 'MALE', child: Text('Male')),
                                        DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                                        DropdownMenuItem(value: 'UNKNOWN', child: Text('Unknown')),
                                      ],
                                      onChanged: (v) => setDialogState(() => selectedGender = v!),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                children: [
                                  Checkbox(
                                    value: isDesexed,
                                    onChanged: (v) => setDialogState(() => isDesexed = v!),
                                  ),
                                  const Text('Desexed / Neutered'),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(controller: ownerNameCtrl, decoration: const InputDecoration(labelText: 'Owner Full Name *', border: OutlineInputBorder())),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: ownerPhoneCtrl, 
                                  keyboardType: TextInputType.number, 
                                  maxLength: 10, 
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                                  decoration: const InputDecoration(
                                    labelText: 'Owner Phone * (04..)', 
                                    hintText: '0412345678',
                                    counterText: '', 
                                    border: OutlineInputBorder()
                                  )
                                )
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: ownerEmailCtrl, 
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Owner Email *', 
                                    hintText: 'example@domain.com',
                                    border: OutlineInputBorder()
                                  )
                                )
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: dogDescCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Dog Special Notes / Interaction Requests',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder()
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), 
                        child: const Text('Abort'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDayClosed ? Colors.grey : widget.config.primaryColor, 
                          foregroundColor: Colors.white
                        ),
                        onPressed: isDayClosed ? null : () async {
                          final cleanPhone = ownerPhoneCtrl.text.trim();
                          final cleanEmail = ownerEmailCtrl.text.trim();
                          final weightText = dogWeightCtrl.text.trim();

                          if (dogNameCtrl.text.isEmpty || 
                              dogBreedCtrl.text.isEmpty || 
                              weightText.isEmpty ||
                              selectedDogDob == null ||
                              ownerNameCtrl.text.isEmpty || 
                              cleanPhone.isEmpty || 
                              cleanEmail.isEmpty) {
                            _showSnackBar('⚠️ Please complete all mandatory fields marked with an asterisk (*).');
                            return;
                          }

                          if (selectedOperationalTime == null || selectedOperationalTime!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('⚠️ Please pick a generated business hour time slot.')),
                            );
                            return;
                          }

                          final String digitsOnlyPhone = cleanPhone.replaceAll(RegExp(r'\D'), '');
                          if (digitsOnlyPhone.length != 10 || !digitsOnlyPhone.startsWith('04')) {
                            _showSnackBar('⚠️ Invalid Phone number. Must be a valid 10-digit Australian mobile number starting with 04.');
                            return;
                          }

                          final RegExp emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                          if (!emailRegex.hasMatch(cleanEmail)) {
                            _showSnackBar('⚠️ Invalid Email pattern structure detected.');
                            return;
                          }

                          final double? parsedWeight = double.tryParse(weightText);
                          if (parsedWeight == null) {
                            _showSnackBar('⚠️ Invalid Weight value. Must be a valid decimal number.');
                            return;
                          }

                          final parts = selectedOperationalTime!.split(' '); // Splits "02:00" and "PM"
                          final timeParts = parts[0].split(':');             // Splits "02" and "00"
                          int hour = int.parse(timeParts[0]);
                          final int minute = int.parse(timeParts[1]);
                          final String amPm = parts[1];

                          if (amPm == 'PM' && hour < 12) {
                            hour += 12;
                          } else if (amPm == 'AM' && hour == 12) {
                            hour = 0;
                          }

                          // 3. Construct your final targetDateTime variable used by the API payload
                          final targetDateTime = DateTime(
                            selectedBookingDate.year, 
                            selectedBookingDate.month, 
                            selectedBookingDate.day, 
                            hour, 
                            minute
                          );

                          final payload = {
                            'merchantId': widget.config.merchantId,
                            'bookedById': widget.config.userId,
                            'servicePricingMatrixId': selectedMatrixRow?['id'],
                            'dogName': dogNameCtrl.text.trim(),
                            'dogBreed': dogBreedCtrl.text.trim(),
                            'dogGender': selectedGender,
                            'isDesexed': isDesexed,
                            'dogWeight': parsedWeight, // Included weight field in upstream transmission mapping
                            'dogDob': selectedDogDob!.toIso8601String(), // Included structured ISO 8601 DOB entry
                            'ownerName': ownerNameCtrl.text.trim(),
                            'ownerPhone': digitsOnlyPhone, 
                            'ownerEmail': cleanEmail,
                            'serviceTime': targetDateTime.toIso8601String(),
                            'groomerId': null,
                            'note': dogDescCtrl.text.trim(),
                          };

                          try {
                            final response = await http.post(
                              Uri.parse('$_baseUrl/api/v1/bookings/add'),
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization': 'Bearer ${widget.authToken}',
                              },
                              body: jsonEncode(payload),
                            );

                            final responseData = jsonDecode(response.body);
                            if (response.statusCode == 200 || response.statusCode == 201) {
                              Navigator.pop(context);
                              _showSnackBar('🚀 Administrative appointment successfully recorded.');
                              _fetchDashboardAppointments();
                            } else {
                              _showSnackBar('❌ Submission Rejected: ${responseData['message'] ?? 'Check input parameters.'}');
                            }
                          } catch (err) {
                            _showSnackBar('❌ Error: Could not connect to target administrative cluster route.');
                          }
                        },
                        child: const Text('Place Booking'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.config.primaryColor;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF1F5F9), 
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: themeColor.withAlpha(25), borderRadius: BorderRadius.circular(8)),
              child: Text(widget.config.logoIcon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Text(widget.config.businessName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18)),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.launch, size: 16),
            label: const Text('Customer Portal'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (_) => CustomerPortalPage(config: widget.config, activeServices: liveServiceMatrices, baseUrl: _baseUrl)
              )
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: Text(widget.config.getTxt('btn_book', 'Manual Booking')),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _showCreateBookingDialog,
          ),
          if (widget.isAdmin) ...[
            const SizedBox(width: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.people_outline, size: 16),
              label: const Text('Customer Info'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () {
                setState(() => _drawerTabController.index = 3); 
                _scaffoldKey.currentState!.openEndDrawer();
              },
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.schedule_outlined, size: 16),
              label: const Text('Business Hours'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () {
                setState(() => _drawerTabController.index = 1); 
                _scaffoldKey.currentState!.openEndDrawer();
              },
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.group_outlined, size: 16),
              label: const Text('Manage Team'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () {
                setState(() => _drawerTabController.index = 2); 
                _scaffoldKey.currentState!.openEndDrawer();
              },
            ),
          ],
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF475569)),
            tooltip: 'Configure UI Text',
            onPressed: () {
              setState(() => _drawerTabController.index = 0); 
              _scaffoldKey.currentState!.openEndDrawer();
            },
          ),
          const VerticalDivider(width: 24, indent: 12, endIndent: 12),
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: widget.onLogout),
          const SizedBox(width: 16),
        ],
      ),
      endDrawer: _buildManagementDrawer(themeColor),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Master Monthly Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 14),
                    _buildCalendarCard(themeColor),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: _isAppointmentsLoading && mockAppointments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchDashboardAppointments,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: _buildMetricHeaderSection()),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _activeScheduleView,
                                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF475569)),
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                    items: _scheduleViewOptions.map((String val) {
                                      return DropdownMenuItem<String>(value: val, child: Text(val));
                                    }).toList(),
                                    onChanged: (newVal) => setState(() => _activeScheduleView = newVal!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildBrandIdentitySection(themeColor),
                          const SizedBox(height: 24),
                          _buildActiveScheduleSection(themeColor),
                          const SizedBox(height: 24),
                          _buildToggleableServiceCatalogSection(themeColor), 
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveScheduleSection(Color themeColor) {
    switch (_activeScheduleView) {
      case 'Daily List View':
        return _buildDailyAppointmentListCard(themeColor);
      case 'Daily Timeline Grid':
        return _buildDailyTimelineGrid(themeColor);
      case 'One Week Grid Summary':
        return _buildWeeklyScheduleGrid(themeColor);
      default:
        return _buildDailyAppointmentListCard(themeColor);
    }
  }

  Widget _buildMetricHeaderSection() {
    final targetDate = _selectedDay ?? DateTime.now();
    final targetedCount = mockAppointments.where((app) => isSameDay(app['rawStartTime'], targetDate)).length;

    return Row(
      children: [
        if (widget.isAdmin) ...[
          _buildMetricCard(widget.config.getTxt('txt_revenue', 'Today Forecast Revenue'), '\$${todayRevenue.toStringAsFixed(2)} AUD', Icons.payments_outlined, Colors.green),
          const SizedBox(width: 16),
        ],
        _buildMetricCard('Total Booked Pets', '$targetedCount Active Profiles', Icons.pets_outlined, Colors.indigo),
      ],
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color col) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: col.withAlpha(20), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: col, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBrandIdentitySection(Color col) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          const Text('Traits: ', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8, 
            children: widget.config.tags.map((t) => Chip(
              backgroundColor: col.withAlpha(15), 
              side: BorderSide.none,
              label: Text(t, style: TextStyle(color: col, fontWeight: FontWeight.w500, fontSize: 12))
            )).toList()
          )
        ],
      ),
    );
  }

  Future<void> _toggleServiceActiveStatus(int matrixId, bool currentStatus) async {
    setState(() => _isServiceLoading = true);
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/v1/matrix/$matrixId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode({
          'isActive': !currentStatus,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        await _fetchServiceMatrices();
        _showSnackBar('🔄 Service definition status successfully synchronized.');
      } else {
        _showSnackBar('❌ Failed to update status: ${responseData['message'] ?? 'Error'}');
      }
    } catch (e) {
      _showSnackBar('❌ Transport Layer Error during service state modification.');
    } finally {
      setState(() => _isServiceLoading = false);
    }
  }

  Widget _buildToggleableServiceCatalogSection(Color col) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isServiceMatrixVisible = !_isServiceMatrixVisible),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_isServiceMatrixVisible ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded, color: const Color(0xFF475569)),
                      const SizedBox(width: 8),
                      const Text('Service Pricing Configuration Matrix', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    ],
                  ),
                  if (_isServiceLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  if (widget.isAdmin && _isServiceMatrixVisible)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_business_outlined, size: 16),
                      label: const Text('Add Entry'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                      onPressed: _showAddServiceMatrixDialog,
                    ),
                ],
              ),
            ),
          ),
          if (_isServiceMatrixVisible) ...[
            const Divider(height: 1),
            if (liveServiceMatrices.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No pricing profiles defined inside database layers yet.', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: liveServiceMatrices.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final matrix = liveServiceMatrices[index];
                  final bool active = matrix['isActive'] ?? true;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    matrix['name'] ?? 'Unnamed Template',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: active ? const Color(0xFF1E293B) : Colors.grey,
                                      decoration: active ? TextDecoration.none : TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: active ? Colors.green.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      active ? 'Active' : 'Inactive',
                                      style: TextStyle(fontSize: 10, color: active ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Weight Class: ${matrix['weightTier'] ?? 'ALL'} • Coat Configuration: ${matrix['coatType'] ?? 'ALL'} • Est Duration: ${matrix['durationMinutes']} mins',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '\$${((matrix['priceCentsAud'] ?? 0) / 100).toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: active ? const Color(0xFF0F172A) : Colors.grey),
                            ),
                            if (widget.isAdmin) ...[
                              const SizedBox(width: 16),
                              Switch(
                                value: active,
                                activeColor: col,
                                onChanged: (bool value) {
                                  _toggleServiceActiveStatus(matrix['id'], active);
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarCard(Color col) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TableCalendar(
        firstDay: DateTime.utc(2026, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (sd, fd) => setState(() {
          _selectedDay = sd;
          _focusedDay = fd;
        }),
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, leftChevronIcon: Icon(Icons.chevron_left, size: 20), rightChevronIcon: Icon(Icons.chevron_right, size: 20)),
      ),
    );
  }

  Widget _buildDailyAppointmentListCard(Color col) {
    final targetDate = _selectedDay ?? DateTime.now();
    final dailyFilteredApps = mockAppointments.where((app) => isSameDay(app['rawStartTime'], targetDate)).toList();

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Schedule Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          dailyFilteredApps.isEmpty
              ? const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No active scheduled booking instances found for this day.')))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dailyFilteredApps.length,
                  separatorBuilder: (_, __) => const Divider(height: 20),
                  itemBuilder: (context, index) {
                    final app = dailyFilteredApps[index];
                    return InkWell(
                      onTap: () => _showUpdateBookingOptionsDialog(app),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('Dog Name: ${app['petName']} (Breed: ${app['breed']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                        child: Text('Status: ${app['status']}', style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                                      ),
                                      if (app['isLoyaltyWaived'] == true) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4)),
                                          child: const Text('🎁 Free Reward', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                                        )
                                      ]
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Service Tier Variant: ${app['service']} • Scheduled Window: ${app['time']}', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                                  if (app['staffTags'] != null && (app['staffTags'] as List).isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('Tags: ${(app['staffTags'] as List).join(", ")}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _buildStatusBadge(app['isCheckedIn'] ? 'Checked In' : 'Not Checked In', app['isCheckedIn'] ? Colors.green : Colors.amber),
                                      _buildStatusBadge(app['isDepositPaid'] ? 'Deposit Paid' : 'No Deposit', app['isDepositPaid'] ? Colors.blue : Colors.deepOrange),
                                      _buildStatusBadge(app['isReadyForPickup'] ? 'Ready for Pickup' : 'Processing', app['isReadyForPickup'] ? Colors.purple : Colors.blueGrey),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildDailyTimelineGrid(Color col) {
    final targetDate = _selectedDay ?? DateTime.now();
    final dailyFilteredApps = mockAppointments.where((app) => isSameDay(app['rawStartTime'], targetDate)).toList();

    final dayRecord = _businessHoursConfig.firstWhere(
      (element) => element['dayOfWeek'] == targetDate.weekday,
      orElse: () => null,
    );

    bool isClosed = true;
    int startHour = 9;
    int endHour = 17;

    if (dayRecord != null && dayRecord['isClosed'] != true) {
      isClosed = false;
      final String startStr = dayRecord['openTime'] ?? '09:00';
      final String endStr = dayRecord['closeTime'] ?? '17:00';
      
      startHour = int.tryParse(startStr.split(':')[0]) ?? 9;
      endHour = int.tryParse(endStr.split(':')[0]) ?? 17;
    }

    if (isClosed) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text('Closed Today', style: TextStyle(color: Colors.grey))),
      );
    }

    // --- NEW CONFIGURATION FOR SPANNING LAYOUT ---
    const double slotHeight = 70.0; // Height allocated per hour row
    final int totalHours = endHour - startHour + 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline Lane Distribution Tracker', 
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Left Axis: Fixed Time Slots Columns (e.g., 9 AM, 10 AM)
              Column(
                children: List.generate(totalHours, (index) {
                  final hour = startHour + index;
                  final displayHour = hour > 12 
                      ? '${hour - 12} PM' 
                      : hour == 12 ? '12 PM' : '$hour AM';
                  return SizedBox(
                    height: slotHeight,
                    width: 65,
                    child: Text(
                      displayHour, 
                      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blueGrey, fontSize: 13),
                    ),
                  );
                }),
              ),
              
              // 2. Right Axis: Interactive Calendar Stack Area
              Expanded(
                child: SizedBox(
                  height: totalHours * slotHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalWidth = constraints.maxWidth;
                      
                      // Sort appointments by start time chronologically
                      final sortedApps = List.from(dailyFilteredApps)
                        ..sort((a, b) => a['rawStartTime'].compareTo(b['rawStartTime']));

                      // Distribute overlapping items into columns side-by-side
                      List<List<Map<String, dynamic>>> columns = [];
                      for (var app in sortedApps) {
                        bool placed = false;
                        for (var column in columns) {
                          final lastApp = column.last;
                          final lastStart = lastApp['rawStartTime'] as DateTime;
                          // Assumes m['rawEndTime'] exists, falls back to 1 hour duration if null
                          final lastEnd = lastApp['rawEndTime'] as DateTime? ?? lastStart.add(const Duration(hours: 1));
                          final appStart = app['rawStartTime'] as DateTime;

                          if (appStart.isAfter(lastEnd) || appStart.isAtSameMomentAs(lastEnd)) {
                            column.add(app);
                            placed = true;
                            break;
                          }
                        }
                        if (!placed) {
                          columns.add([app]);
                        }
                      }

                      final int totalCols = columns.isEmpty ? 1 : columns.length;
                      final double itemWidth = totalWidth / totalCols;

                      return Stack(
                        children: [
                          // Background Grid Separator Lines
                          ...List.generate(totalHours, (index) {
                            return Positioned(
                              top: index * slotHeight,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: slotHeight,
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
                                ),
                              ),
                            );
                          }),

                          // Foreground Rendered Spanned Booking Blocks
                          ...List.generate(columns.length, (colIndex) {
                            final currentColumnApps = columns[colIndex];
                            return currentColumnApps.map((app) {
                              final start = app['rawStartTime'] as DateTime;
                              final end = app['rawEndTime'] as DateTime? ?? start.add(const Duration(hours: 2)); // Dynamic fallback duration

                              // Compute positions relative to the timeline structure 
                              final double startMinutes = (start.hour - startHour) * 60.0 + start.minute;
                              final double endMinutes = (end.hour - startHour) * 60.0 + end.minute;

                              final double topPosition = (startMinutes / 60.0) * slotHeight;
                              final double blockHeight = ((endMinutes - startMinutes) / 60.0) * slotHeight;
                              
                              // Visual cosmetics setup
                              final cardColor = _getPastelColor(app['breed'] ?? '');

                              return Positioned(
                                top: topPosition,
                                left: colIndex * itemWidth,
                                width: itemWidth - 4,
                                height: blockHeight - 2, 
                                // 🌟 ADDED: Tooltip widget wraps the item to display full info on hover
                                child: Tooltip(
                                  richMessage: TextSpan(
                                    style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                                    children: [
                                      TextSpan(text: '🐾 Dog: ${app['petName']} (${app['breed']})\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      TextSpan(text: '👤 Owner: ${app['ownerName'] ?? 'Unknown Owner'}\n'),
                                      TextSpan(text: '📞 Phone: ${app['ownerPhone'] ?? 'No Phone'}\n'),
                                      TextSpan(text: '✉️ Email: ${app['ownerEmail'] ?? 'No Email'}'),
                                    ],
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade900.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  preferBelow: true,
                                  waitDuration: const Duration(milliseconds: 200), // Quick response on mouse hover
                                  child: GestureDetector(
                                    onTap: () => _showUpdateBookingOptionsDialog(app),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: cardColor.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: cardColor, width: 1.5),
                                      ),
                                      // 🌟 CHANGED: SingleChildScrollView prevents the "BOTTOM OVERFLOWED" red screen crash completely
                                      child: SingleChildScrollView(
                                        physics: const NeverScrollableScrollPhysics(), // Disables tiny inner scrollbars to keep UI clean
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '🐾 ${app['petName']} (${app['breed']})',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: cardColor.withRed(30).withGreen(30),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '👤 ${app['ownerName'] ?? 'Unknown Owner'}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                                color: Colors.grey.shade800,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '📞 ${app['ownerPhone'] ?? 'No Phone'}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade700,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '✉️ ${app['ownerEmail'] ?? 'No Email'}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList();
                          }).expand((element) => element).toList(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to assign distinct theme colors based on the data block
  Color _getPastelColor(String seed) {
    final int hash = seed.hashCode;
    final List<Color> colors = [Colors.green.shade600, Colors.purple.shade400, Colors.orange.shade600, Colors.blue.shade600];
    return colors[hash.abs() % colors.length];
  }

  Widget _buildWeeklyScheduleGrid(Color col) {
    final targetDate = _selectedDay ?? DateTime.now();
    final DateTime mondayOfTargetWeek = targetDate.subtract(Duration(days: targetDate.weekday - 1));

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('One Week Aggregate Density', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          Row(
            children: List.generate(7, (index) {
              final DateTime dayOfRow = mondayOfTargetWeek.add(Duration(days: index));
              final count = mockAppointments.where((a) => isSameDay(a['rawStartTime'], dayOfRow)).length;
              final bool isCurrentSelected = isSameDay(_selectedDay, dayOfRow);

              return Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    _selectedDay = dayOfRow;
                    _focusedDay = dayOfRow;
                  }),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrentSelected ? col.withAlpha(25) : Colors.blueGrey.shade50, 
                      border: isCurrentSelected ? Border.all(color: col, width: 1.5) : null,
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Column(
                      children: [
                        Text('${dayOfRow.day}/${dayOfRow.month}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('$count Grooms', style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color mappedColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: mappedColor.withAlpha(24), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: mappedColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showUpdateBookingOptionsDialog(Map<String, dynamic> app) {
    bool isCheckedIn = app['isCheckedIn'] ?? false;
    bool depositPaid = app['isDepositPaid'] ?? false;
    bool isReadyForPickup = app['isReadyForPickup'] ?? false;
    bool isLoyaltyWaived = app['isLoyaltyWaived'] ?? false;
    String currentStatus = app['status'] ?? 'PENDING';
    
    final tagsController = TextEditingController(text: (app['staffTags'] as List).join(', '));
    
    DateTime updatedBookingDate = app['rawStartTime'] ?? DateTime.now();
    String updatedBookingTimeSlot = "${updatedBookingDate.hour.toString().padLeft(2, '0')}:${updatedBookingDate.minute.toString().padLeft(2, '0')}";
    
    if (!_timePresetSlots.contains(updatedBookingTimeSlot)) {
      updatedBookingTimeSlot = '09:00';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit_calendar, color: Colors.indigo),
                const SizedBox(width: 8),
                Text('Manage Booking: Dog Name: ${app['petName']} (Breed: ${app['breed']})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Owner Account: ${app['ownerName']} (${app['ownerPhone']})', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const Divider(height: 24),
                    
                    const Text('Reschedule Date & Time Layout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 14),
                            label: Text('${updatedBookingDate.day}/${updatedBookingDate.month}/${updatedBookingDate.year}'),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: updatedBookingDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                              );
                              if (pickedDate != null) {
                                setModalState(() => updatedBookingDate = pickedDate);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: updatedBookingTimeSlot,
                                items: _timePresetSlots.map((time) {
                                  return DropdownMenuItem<String>(value: time, child: Text('Time: $time'));
                                }).toList(),
                                onChanged: (val) => setModalState(() => updatedBookingTimeSlot = val!),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    const Text('Administrative Pipeline Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    DropdownButton<String>(
                      value: currentStatus,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
                        DropdownMenuItem(value: 'PAID', child: Text('PAID')),
                        DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED')),
                        DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED')),
                      ],
                      onChanged: (val) => setModalState(() => currentStatus = val!),
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      title: const Text('Client Checked In', style: TextStyle(fontSize: 13)),
                      value: isCheckedIn,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setModalState(() => isCheckedIn = v),
                    ),
                    SwitchListTile(
                      title: const Text('Deposit Paid Status', style: TextStyle(fontSize: 13)),
                      value: depositPaid,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setModalState(() => depositPaid = v),
                    ),
                    SwitchListTile(
                      title: const Text('Pet Ready For Pickup', style: TextStyle(fontSize: 13)),
                      value: isReadyForPickup,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setModalState(() => isReadyForPickup = v),
                    ),
                    SwitchListTile(
                      title: const Text('Waive Fee (Free Loyalty Reward Groom)', style: TextStyle(fontSize: 13)),
                      value: isLoyaltyWaived,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setModalState(() => isLoyaltyWaived = v),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Internal Staff/Admin Tags (comma separated)',
                        border: OutlineInputBorder(),
                        hintText: 'Aggressive, HighAnxiety, SpecialCare',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade800, 
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          _confirmActionGuard(
                            title: 'Purge Operational Record',
                            body: 'This operation will delete booking identifier ${app['id']} permanently from the production cluster.',
                            onConfirm: () async {
                              try {
                                await http.delete(
                                  Uri.parse('$_baseUrl/api/v1/bookings/delete/${app['id']}'),
                                  headers: {'Authorization': 'Bearer ${widget.authToken}'},
                                );
                                _showSnackBar('🚀 Purge schema sync completed.');
                                _fetchDashboardAppointments();
                              } catch (e) {
                                setState(() {
                                  mockAppointments.removeWhere((item) => item['id'] == app['id']);
                                });
                                _showSnackBar('Removed local record object safely.');
                              }
                            }
                          );
                        },
                        child: const Text('Delete Permanently'),
                      ),
                    )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Discard')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                onPressed: () async {
                  final parsedTags = tagsController.text
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();

                  final timeParts = updatedBookingTimeSlot.split(':');
                  final hour = int.parse(timeParts[0]);
                  final minute = int.parse(timeParts[1]);

                  final targetFullDateTime = DateTime(
                    updatedBookingDate.year,
                    updatedBookingDate.month,
                    updatedBookingDate.day,
                    hour,
                    minute
                  );

                  final updatePayload = {
                    'status': currentStatus,
                    'startTime': targetFullDateTime.toIso8601String(),
                    'isCheckedIn': isCheckedIn,
                    'depositPaid': depositPaid,
                    'isReadyToPickup': isReadyForPickup,
                    'isLoyaltyWaived': isLoyaltyWaived,
                    'internalTags': parsedTags,
                  };

                  int serverVerifiedDuration = app['durationMinutes'] ?? 60;

                  try {
                    final response = await http.put(
                      Uri.parse('$_baseUrl/api/v1/bookings/update/${app['id']}'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer ${widget.authToken}',
                      },
                      body: jsonEncode(updatePayload),
                    );

                    if (response.statusCode == 200) {
                      final Map<String, dynamic> responseData = jsonDecode(response.body);
                      if (responseData['success'] == true && responseData['data'] != null) {
                        final appointmentSnapshot = responseData['data'];
                        if (appointmentSnapshot['durationMinutes'] != null) {
                          serverVerifiedDuration = appointmentSnapshot['durationMinutes'] as int;
                        }
                      }
                      _showSnackBar('🚀 Cloud database schema updated safely.');
                    } else {
                      _showSnackBar('⚠️ Live sync rejected; falling back to local simulation.');
                    }
                  } catch (e) {
                    _showSnackBar('🔄 Connection error; processing local simulation safely.');
                  }

                  setState(() {
                    final targetIdx = mockAppointments.indexWhere((element) => element['id'] == app['id']);
                    if (targetIdx != -1) {
                      mockAppointments[targetIdx]['isCheckedIn'] = isCheckedIn;
                      mockAppointments[targetIdx]['isDepositPaid'] = depositPaid;
                      mockAppointments[targetIdx]['isReadyForPickup'] = isReadyForPickup;
                      mockAppointments[targetIdx]['isLoyaltyWaived'] = isLoyaltyWaived;
                      mockAppointments[targetIdx]['status'] = currentStatus;
                      mockAppointments[targetIdx]['staffTags'] = parsedTags;
                      mockAppointments[targetIdx]['rawStartTime'] = targetFullDateTime;
                      mockAppointments[targetIdx]['durationMinutes'] = serverVerifiedDuration;
                      
                      final rangeEnd = targetFullDateTime.add(Duration(minutes: serverVerifiedDuration));
                      mockAppointments[targetIdx]['rawEndTime'] = rangeEnd; 
                      
                      mockAppointments[targetIdx]['time'] = 
                          "${targetFullDateTime.hour.toString().padLeft(2, '0')}:${targetFullDateTime.minute.toString().padLeft(2, '0')} - ${rangeEnd.hour.toString().padLeft(2, '0')}:${rangeEnd.minute.toString().padLeft(2, '0')}";
                    }
                  });

                  Navigator.pop(context);
                },
                child: const Text('Commit Changes'),
              )
            ],
          );
        },
      ),
    );
  }

  void _showAddServiceMatrixDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String selectedCoat = 'SHORT';
    String selectedSize = 'M';
    int selectedDuration = 45;
    final List<String> coatOptions = ['SHORT', 'LONG_CURLY', 'DOUBLE_A', 'DOUBLE_B'];
    final List<String> sizeOptions = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
    final List<int> durationOptions = [15, 30, 45, 60, 75, 90, 105, 120];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_business_outlined, color: Color(0xFF0F172A)),
                SizedBox(width: 10),
                Text('Provision Pricing Matrix Tier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Service Matrix Name Line Label Identifier', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    const Text('Target Coat Attribute Configuration Variant Matrix Layer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: selectedCoat,
                      isExpanded: true,
                      items: coatOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setModalState(() => selectedCoat = v!),
                    ),
                    const SizedBox(height: 16),
                    const Text('Target Weight Profile Tier Matrix Layer Filter Option Type Descriptor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: selectedSize,
                      isExpanded: true,
                      items: sizeOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setModalState(() => selectedSize = v!),
                    ),
                    const SizedBox(height: 16),
                    const Text('Allocated Operational Handling Execution Window Span Duration Minutes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 6,
                      children: durationOptions.map((d) {
                        return ChoiceChip(
                          label: Text('$d min'),
                          selected: selectedDuration == d,
                          onSelected: (bool selected) {
                            if (selected) {
                              setModalState(() => selectedDuration = d);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Price Target Rate (\$ AUD)', prefixText: '\$ ', border: OutlineInputBorder())
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: _isServiceLoading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                onPressed: _isServiceLoading ? null : () async {
                  if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                  final double parsedPrice = double.tryParse(priceCtrl.text) ?? 0.0;
                  final int calculatedCents = (parsedPrice * 100).round();
                  final String finalName = nameCtrl.text.trim();
                  Navigator.pop(context);
                  await _createServiceMatrixTier(
                    name: finalName,
                    coatType: selectedCoat,
                    weightTier: selectedSize,
                    duration: selectedDuration,
                    priceCents: calculatedCents,
                  );
                },
                child: _isServiceLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Confirm Provision'),
              )
            ],
          );
        }
      ),
    );
  }

  void _confirmActionGuard({required String title, required String body, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abort')),
          ElevatedButton(onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          }, child: const Text('Confirm')),
        ],
      ),
    );
  }

  Widget _buildManagementDrawer(Color themeColor) {
    return Drawer(
      width: 450,
      child: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _drawerTabController,
              labelColor: themeColor,
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: themeColor,
              tabs: [
                const Tab(icon: Icon(Icons.tune), text: 'UI Text Config'),
                if (widget.isAdmin) ...[
                  const Tab(icon: Icon(Icons.schedule_rounded), text: 'Hours'),
                  const Tab(icon: Icon(Icons.badge_outlined), text: 'Team Members'),
                  const Tab(icon: Icon(Icons.pets), text: 'Customers'),
                ]
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _drawerTabController,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('UI Localization Dictionary Controls', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 16),
                          TextField(controller: _btnBookController, decoration: const InputDecoration(labelText: 'Manual Booking Button Text', border: OutlineInputBorder())),
                          const SizedBox(height: 16),
                          TextField(controller: _btnCancelController, decoration: const InputDecoration(labelText: 'Cancel Button Text', border: OutlineInputBorder())),
                          const SizedBox(height: 16),
                          TextField(controller: _btnEditController, decoration: const InputDecoration(labelText: 'Reschedule Button Text', border: OutlineInputBorder())),
                          const SizedBox(height: 16),
                          TextField(controller: _txtRevenueController, decoration: const InputDecoration(labelText: 'Revenue Metric Label Title', border: OutlineInputBorder())),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white),
                              onPressed: _saveUiTextConfigToDatabase,
                              child: const Text('Save Text Formats'),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  if (widget.isAdmin) ...[
                    ManageHoursPanel(
                      config: widget.config,
                      authToken: widget.authToken,
                    ),
                    ManageTeamPanel(
                      config: widget.config, 
                      authToken: widget.authToken,
                    ),
                    CustomerInfoPanel(
                      config: widget.config,
                      authToken: widget.authToken,
                      baseUrl: _baseUrl,
                      themeColor: themeColor,
                    ),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

extension ColorDarken on Color {
  Color darken([double amount = .3]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}