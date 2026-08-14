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
import 'customer_info_panel.dart';
import 'staff_scheduling_page.dart';

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
  
  List<dynamic> _businessHoursConfig = [];

  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  List<Map<String, dynamic>>? _invitedStaff;

  String _activeScheduleView = 'Daily List View'; 
  final List<String> _scheduleViewOptions = [
    'Daily List View', 
    'Daily Timeline Grid', 
    'One Week Grid Summary'
  ];

  bool _isServiceMatrixVisible = true;
  bool _isServiceLoading = false; 
  bool _isAppointmentsLoading = false;

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    return Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }

  TabController? _drawerTabController;
  List<Map<String, dynamic>> mockAppointments = []; 
  List<Map<String, dynamic>> liveServiceMatrices = [];

  @override
  void initState() {
    super.initState();
    if (widget.isAdmin) {
      _initDrawerController();
    }
    _fetchServiceMatrices(); 
    _fetchDashboardAppointments();
    _fetchBusinessHours(); 
  }
  void _initDrawerController() {
    _drawerTabController = TabController(length: 4, vsync: this);
    _drawerTabController!.addListener(() {
      // Index 3 is the Roster Tab
      if (_drawerTabController!.index == 3 && !_drawerTabController!.indexIsChanging) {
        // 1. Revert index back to the first tab so the drawer doesn't look broken if reopened
        _drawerTabController!.index = 0;
        
        // 2. Close the slide-out management drawer
        Navigator.pop(context);
        
        // 3. Open the Roster page as a full responsive page!
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StaffSchedulingPage(
              config: widget.config,
              authToken: widget.authToken,
              businessHoursConfig: _businessHoursConfig,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _drawerTabController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UnifiedMerchantDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAdmin != oldWidget.isAdmin) {
      _drawerTabController?.dispose();
      if (widget.isAdmin) {
        _initDrawerController();
      } else {
        _drawerTabController = null;
      }
    }
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
        _showSnackBar('❌ Failed to fetch backend service options matrix.');
      }
    } catch (_) {
      _showSnackBar('❌ Transport layer connection fault.');
    } finally {
      if (mounted) setState(() => _isServiceLoading = false);
    }
  }

  Future<void> _fetchBusinessHours() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/merchant/${widget.config.merchantId}/hours'),
        headers: {'Content-Type': 'application/json'},
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
              'groomerId': item['groomerId'] ?? ''
            });
          }

          setState(() {
            mockAppointments = parsedLiveList;
          });
        }
      } else {
        _showSnackBar('❌ Failed to fetch appointment records.');
      }
    } catch (_) {
      _showSnackBar('❌ Connection error querying dashboard data.');
    } finally {
      if (mounted) setState(() => _isAppointmentsLoading = false);
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

  Future<void> _createServiceMatrixTier({
    required String name,
    required String coatType,
    required String weightTier,
    required int duration,
    required int priceCents,
    required int depositCents,
  }) async {
    setState(() => _isServiceLoading = true);
    final Map<String, dynamic> payload = {
      'merchantId': widget.config.merchantId, 
      'name': name,    
      'speciesId': 1,                     
      'coatType': coatType,
      'weightTier': weightTier,
      'durationMinutes': duration,
      'priceCentsAud': priceCents,
      'depositCentsAud': depositCents,
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
        _showSnackBar('🚀 New pricing matrix synchronized.');
      } else {
        _showSnackBar('❌ Sync failed: ${responseData['message'] ?? 'Error'}');
      }
    } catch (_) {
      _showSnackBar('❌ Transport Layer Failure.');
    } finally {
      if (mounted) setState(() => _isServiceLoading = false);
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

  Future<void> _showCreateBookingDialog() async {
      try { 
        await _fetchStaffList();
        final dogNameCtrl = TextEditingController();
        final dogBreedCtrl = TextEditingController();
        final dogWeightCtrl = TextEditingController();
        final ownerNameCtrl = TextEditingController();
        final ownerPhoneCtrl = TextEditingController();
        final ownerEmailCtrl = TextEditingController();
        final dogDescCtrl = TextEditingController();

        Map<String, dynamic>? selectedMatrixRow = liveServiceMatrices.isNotEmpty ? liveServiceMatrices.first : null;
        String selectedGender = 'MALE';
        bool isDesexed = false;
        DateTime? selectedDogDob;
        
        DateTime selectedBookingDate = _selectedDay ?? DateTime.now();
        bool isDayClosed = _checkIsDayClosed(selectedBookingDate);
        
        List<String> operationalHoursTimeOptions = [];
        String? selectedOperationalTime;
        bool isLoadingSlots = false;
        bool hasFetchedInitialSlots = false;

        // Track if we are fetching staff inside the modal instance
        bool isLoadingStaff = _invitedStaff == null; 
        dynamic selectedGroomerId; 

        showDialog(
          context: context,
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isMobileDialog = screenWidth < 600;

            return AlertDialog(
              insetPadding: const EdgeInsets.all(16),
              title: const Row(
                children: [
                  Icon(Icons.add_task_outlined, color: Colors.blueAccent),
                  SizedBox(width: 10),
                  Expanded(child: Text('Create New Booking Instance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                ],
              ),
              content: SizedBox(
                width: isMobileDialog ? screenWidth : 600,
                child: StatefulBuilder(
                  builder: (context, setDialogState) {
                    
                    // Helper to fetch staff and refresh the modal layout state concurrently
                    Future<void> loadStaffDataForDialog() async {
                      await _fetchStaffList();
                      if (context.mounted) {
                        setDialogState(() {
                          isLoadingStaff = false;
                          // Auto-select the first available groomer if the list populated successfully
                          final active = (_invitedStaff ?? []).where((s) => s['isActive'] == true).toList();
                          if (active.isNotEmpty) {
                            selectedGroomerId = active.first['id'];
                          }
                        });
                      }
                    }

                    // Run the API call immediately when the dialog opens if data isn't cached yet
                    if (isLoadingStaff) {
                      loadStaffDataForDialog();
                    }

                    Future<void> updateCapacityAvailableSlots() async {
                      if (selectedMatrixRow == null || isDayClosed) return;
                      
                      setDialogState(() => isLoadingSlots = true);

                      try {
                        final String formattedDate = "${selectedBookingDate.year}-"
                            "${selectedBookingDate.month.toString().padLeft(2, '0')}-"
                            "${selectedBookingDate.day.toString().padLeft(2, '0')}";
                        
                        final int durationMinutes = selectedMatrixRow?['durationMinutes'] ?? 60;

                        final String targetUrl = '$_baseUrl/api/v1/bookings/available-slots'
                            '?merchantId=${widget.config.merchantId}'
                            '&date=$formattedDate'
                            '&duration=$durationMinutes';
                        
                        final response = await http.get(
                          Uri.parse(targetUrl),
                          headers: {'Content-Type': 'application/json'},
                        );

                        if (response.statusCode == 200) {
                          final Map<String, dynamic> parsedBody = json.decode(response.body);
                          if (parsedBody['success'] == true && parsedBody['data'] is List) {
                            final List<dynamic> backendSlots = parsedBody['data'];

                            setDialogState(() {
                              if (backendSlots.isNotEmpty) {
                                isDayClosed = false;
                                operationalHoursTimeOptions = backendSlots.map<String>((slot) {
                                  final parts = slot.toString().split(':');
                                  final int hour = int.parse(parts[0]);
                                  final String minute = parts[1];
                                  
                                  final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                                  final String amPm = hour >= 12 ? 'PM' : 'AM';
                                  final String paddedHour = displayHour.toString().padLeft(2, '0');
                                  
                                  return '$paddedHour:$minute $amPm';
                                }).toList();
                              } else {
                                isDayClosed = true;
                                operationalHoursTimeOptions = [];
                              }

                              selectedOperationalTime = operationalHoursTimeOptions.isNotEmpty ? operationalHoursTimeOptions.first : null;
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

                    Future<void> updateAdminCapacityAvailableSlots() async {
                      if (selectedMatrixRow == null || isDayClosed) return;
                      
                      setDialogState(() => isLoadingSlots = true);

                      try {
                        final String formattedDate = "${selectedBookingDate.year}-"
                            "${selectedBookingDate.month.toString().padLeft(2, '0')}-"
                            "${selectedBookingDate.day.toString().padLeft(2, '0')}";
                        
                        //final int durationMinutes = selectedMatrixRow?['durationMinutes'] ?? 60;

                        final String targetUrl = '$_baseUrl/api/v1/bookings/admin/available-slots'
                            '?merchantId=${widget.config.merchantId}'
                            '&date=$formattedDate';
                        
                        final response = await http.get(
                          Uri.parse(targetUrl),
                          headers: {'Content-Type': 'application/json'},
                        );

                        if (response.statusCode == 200) {
                          final Map<String, dynamic> parsedBody = json.decode(response.body);
                          if (parsedBody['success'] == true && parsedBody['data'] is List) {
                            final List<dynamic> backendSlots = parsedBody['data'];

                            setDialogState(() {
                              if (backendSlots.isNotEmpty) {
                                isDayClosed = false;
                                
                                // 🟢 UPDATED: Converting backend's 24-hour strings ("HH:mm") to 12-hour AM/PM format
                                operationalHoursTimeOptions = backendSlots.map<String>((slot) {
                                  final parts = slot.toString().split(':');
                                  final int hour = int.parse(parts[0]);
                                  final String minute = parts[1];
                                  
                                  final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                                  final String amPm = hour >= 12 ? 'PM' : 'AM';
                                  final String paddedHour = displayHour.toString().padLeft(2, '0');
                                  
                                  return '$paddedHour:$minute $amPm';
                                }).toList();
                                
                              } else {
                                isDayClosed = true;
                                operationalHoursTimeOptions = [];
                              }

                              selectedOperationalTime = operationalHoursTimeOptions.isNotEmpty 
                                  ? operationalHoursTimeOptions.first 
                                  : null;
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
                        Future.delayed(Duration.zero, () => updateAdminCapacityAvailableSlots());
                      }
                    }

                    // Extract and filter active members safely out of the class list variable
                    final activeGroomers = (_invitedStaff ?? [])
                        .where((staff) => staff['isActive'] == true)
                        .toList();

                    // Fallback safety check: If state updated but no ID was initially selected, point to the first item
                    if (selectedGroomerId == null && activeGroomers.isNotEmpty) {
                      selectedGroomerId = activeGroomers.first['id'];
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
                                      items: liveServiceMatrices
                                          .where((matrix) => matrix['isActive'] == true)
                                          .map((matrix) {
                                            return DropdownMenuItem<Map<String, dynamic>>(
                                              value: matrix,
                                              child: Text(
                                                '${matrix['name']} (${matrix['weightTier']} / ${matrix['coatType']}) - \$${((matrix['priceCentsAud'] ?? 0) / 100).toStringAsFixed(2)}',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (val) {
                                        setDialogState(() => selectedMatrixRow = val);
                                        updateAdminCapacityAvailableSlots(); 
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                const Text('Appointment Date & Time Selection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                                const SizedBox(height: 6),
                                
                                isMobileDialog
                                    ? Column(
                                        children: [
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                                            icon: const Icon(Icons.calendar_today, size: 16),
                                            label: Text('Date: ${selectedBookingDate.day}/${selectedBookingDate.month}/${selectedBookingDate.year}'),
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
                                                  isDayClosed = _checkIsDayClosed(pickedDate);
                                                  isLoadingSlots = true;
                                                });
                                                updateAdminCapacityAvailableSlots();
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          _buildTimeSlotDropdown(isDayClosed, isLoadingSlots, operationalHoursTimeOptions, selectedOperationalTime, (val) => setDialogState(() => selectedOperationalTime = val)),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              icon: const Icon(Icons.calendar_today, size: 16),
                                              label: Text('Date: ${selectedBookingDate.day}/${selectedBookingDate.month}/${selectedBookingDate.year}'),
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
                                                    isDayClosed = _checkIsDayClosed(pickedDate);
                                                    isLoadingSlots = true;
                                                  });
                                                  updateAdminCapacityAvailableSlots();
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildTimeSlotDropdown(isDayClosed, isLoadingSlots, operationalHoursTimeOptions, selectedOperationalTime, (val) => setDialogState(() => selectedOperationalTime = val)),
                                          ),
                                        ],
                                      ),
                                const SizedBox(height: 16),

                                // --- Updated Mandatory Groomer Dropdown ---
                                const Text('Assign Groomer Staff member *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                                  child: DropdownButtonHideUnderline(
                                    child: isLoadingStaff 
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 12.0),
                                          child: Row(
                                            children: [
                                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                              SizedBox(width: 12),
                                              Text('Syncing active staff...', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                            ],
                                          ),
                                        )
                                      : activeGroomers.isEmpty
                                          ? const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 12.0),
                                              child: Text(
                                                'No active staff members available',
                                                style: TextStyle(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.w500),
                                              ),
                                            )
                                          : DropdownButton<dynamic>(
                                              isExpanded: true,
                                              value: selectedGroomerId,
                                              hint: const Text('Select an assigned professional'),
                                              items: activeGroomers.map((groomer) {
                                                return DropdownMenuItem<dynamic>(
                                                  value: groomer['id'],
                                                  child: Text('${groomer['name']}'),
                                                );
                                              }).toList(),
                                              onChanged: (val) {
                                                setDialogState(() => selectedGroomerId = val);
                                              },
                                            ),
                                  ),
                                ),

                                const Divider(height: 32),

                                if (isMobileDialog) ...[
                                  TextField(controller: dogNameCtrl, decoration: const InputDecoration(labelText: 'Dog Name *', border: OutlineInputBorder())),
                                  const SizedBox(height: 12),
                                  TextField(controller: dogBreedCtrl, decoration: const InputDecoration(labelText: 'Dog Breed Variant *', border: OutlineInputBorder())),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
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
                                      if (pickedDob != null) setDialogState(() => selectedDogDob = pickedDob);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: dogWeightCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                    decoration: const InputDecoration(labelText: 'Dog Weight (kg) *', border: OutlineInputBorder(), hintText: 'e.g., 14.5'),
                                  ),
                                ] else ...[
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
                                            if (pickedDob != null) setDialogState(() => selectedDogDob = pickedDob);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: dogWeightCtrl,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                          decoration: const InputDecoration(labelText: 'Dog Weight (kg) *', border: OutlineInputBorder(), hintText: 'e.g., 14.5'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                                        Checkbox(value: isDesexed, onChanged: (v) => setDialogState(() => isDesexed = v!)),
                                        const Text('Desexed', style: TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextField(controller: ownerNameCtrl, decoration: const InputDecoration(labelText: 'Owner Full Name *', border: OutlineInputBorder())),
                                const SizedBox(height: 16),
                                
                                isMobileDialog
                                    ? Column(
                                        children: [
                                          TextField(
                                            controller: ownerPhoneCtrl, 
                                            keyboardType: TextInputType.number, 
                                            maxLength: 10, 
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                                            decoration: const InputDecoration(labelText: 'Owner Phone * (04..)', hintText: '0412345678', counterText: '', border: OutlineInputBorder())
                                          ),
                                          const SizedBox(height: 12),
                                          TextField(
                                            controller: ownerEmailCtrl, 
                                            keyboardType: TextInputType.emailAddress,
                                            decoration: const InputDecoration(labelText: 'Owner Email *', hintText: 'example@domain.com', border: OutlineInputBorder())
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: ownerPhoneCtrl, 
                                              keyboardType: TextInputType.number, 
                                              maxLength: 10, 
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                                              decoration: const InputDecoration(labelText: 'Owner Phone * (04..)', hintText: '0412345678', counterText: '', border: OutlineInputBorder())
                                            )
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextField(
                                              controller: ownerEmailCtrl, 
                                              keyboardType: TextInputType.emailAddress,
                                              decoration: const InputDecoration(labelText: 'Owner Email *', hintText: 'example@domain.com', border: OutlineInputBorder())
                                            )
                                          ),
                                        ],
                                      ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: dogDescCtrl,
                                  maxLines: 2,
                                  decoration: const InputDecoration(labelText: 'Dog Special Notes / Requests', alignLabelWithHint: true, border: OutlineInputBorder()),
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

                                // Block validation if no groomer is selected
                                if (selectedGroomerId == null) {
                                  _showSnackBar('⚠️ A valid active groomer staff member must be assigned.');
                                  return;
                                }

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

                                final parts = selectedOperationalTime!.split(' ');
                                final timeParts = parts[0].split(':');
                                int hour = int.parse(timeParts[0]);
                                final int minute = int.parse(timeParts[1]);
                                final String amPm = parts[1];

                                if (amPm == 'PM' && hour < 12) {
                                  hour += 12;
                                } else if (amPm == 'AM' && hour == 12) {
                                  hour = 0;
                                }

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
                                  'dogWeight': parsedWeight,
                                  'dogDob': selectedDogDob!.toIso8601String(),
                                  'ownerName': ownerNameCtrl.text.trim(),
                                  'ownerPhone': digitsOnlyPhone, 
                                  'ownerEmail': cleanEmail,
                                  'serviceTime': targetDateTime.toIso8601String(),
                                  'groomerId': selectedGroomerId, 
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
            );
          },
        );
        }
        catch (error) {
          _showSnackBar("Failed to fetch staff list before opening dialog:");
        }
  }

  Widget _buildTimeSlotDropdown(bool isClosed, bool isLoading, List<String> options, String? selected, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: isClosed ? Colors.red.shade300 : Colors.grey.shade300), 
        borderRadius: BorderRadius.circular(4),
        color: isClosed ? Colors.red.shade50 : (isLoading ? Colors.grey.shade100 : Colors.white),
      ),
      child: DropdownButtonHideUnderline(
        child: isClosed 
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text('SHOP CLOSED', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent)),
              )
            : (isLoading
                ? const SizedBox(height: 20, width: 20, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('No available slots', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                    value: selected,
                    items: options.map((time) => DropdownMenuItem<String>(value: time, child: Text(time))).toList(),
                    onChanged: onChanged,
                  )),
      ),
    );
  }

  void _showSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.config.primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF1F5F9), 
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        centerTitle: false, 
        titleSpacing: 16,   
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: themeColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.config.logoIcon,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.config.businessName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = MediaQuery.of(context).size.width < 600;

              if (isCompact) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.launch, size: 20),
                      tooltip: 'Customer Portal',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerPortalPage(
                            config: widget.config,
                            activeServices: liveServiceMatrices,
                            baseUrl: _baseUrl,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: themeColor, size: 22),
                      tooltip: 'Manual Booking',
                      onPressed: _showCreateBookingDialog,
                    ),
                    if (widget.isAdmin)
                      IconButton(
                        icon: const Icon(
                          Icons.manage_accounts_outlined,
                          color: Color(0xFF475569),
                        ),
                        tooltip: 'Management Drawer',
                        onPressed: () {
                          _scaffoldKey.currentState!.openEndDrawer();
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      onPressed: widget.onLogout,
                    ),
                  ],
                );
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.launch, size: 16),
                    label: const Text('Customer Portal'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerPortalPage(
                          config: widget.config,
                          activeServices: liveServiceMatrices,
                          baseUrl: _baseUrl,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Manual Booking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _showCreateBookingDialog,
                  ),
                  if (widget.isAdmin)
                    IconButton(
                      icon: const Icon(
                        Icons.manage_accounts_outlined,
                        color: Color(0xFF475569),
                      ),
                      tooltip: 'Management Drawer',
                      onPressed: () {
                        _scaffoldKey.currentState!.openEndDrawer();
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    onPressed: widget.onLogout,
                  ),
                  const SizedBox(width: 12),
                ],
              );
            },
          ),
        ],
      ),
      endDrawer: widget.isAdmin ? _buildManagementDrawer(themeColor) : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return RefreshIndicator(
              onRefresh: _fetchDashboardAppointments,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildMetricHeaderSection(isMobile: true),
                    const SizedBox(height: 16),
                    _buildCalendarCard(themeColor),
                    const SizedBox(height: 16),
                    _buildScheduleDropdownView(),
                    const SizedBox(height: 16),
                    _buildActiveScheduleSection(themeColor),
                    const SizedBox(height: 16),
                    _buildBrandIdentitySection(themeColor),
                    const SizedBox(height: 16),
                    _buildToggleableServiceCatalogSection(themeColor),
                  ],
                ),
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: double.infinity,
                  decoration: const BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: Color(0xFFE2E8F0)))),
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
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _buildMetricHeaderSection(isMobile: false),
                                    ),
                                    const SizedBox(width: 16),
                                    _buildScheduleDropdownView(),
                                  ],
                                ),
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
          );
        },
      ),
    );
  }

  Widget _buildScheduleDropdownView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _activeScheduleView,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF475569)),
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          items: _scheduleViewOptions.map((String val) => DropdownMenuItem<String>(value: val, child: Text(val))).toList(),
          onChanged: (newVal) => setState(() => _activeScheduleView = newVal!),
        ),
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

  Widget _buildMetricHeaderSection({bool isMobile = false}) {
    final targetDate = _selectedDay ?? DateTime.now();
    final targetedCount = mockAppointments.where((app) => isSameDay(app['rawStartTime'], targetDate)).length;

    if (isMobile) {
      return Column(
        children: [
          if (widget.isAdmin) ...[
            _buildMetricCard('Today Forecast Revenue', '\$${todayRevenue.toStringAsFixed(2)} AUD', Icons.payments_outlined, Colors.green),
            const SizedBox(height: 12),
          ],
          _buildMetricCard('Total Booked Pets', '$targetedCount Active Profiles', Icons.pets_outlined, Colors.indigo),
        ],
      );
    }

    return Row(
      children: [
        if (widget.isAdmin) ...[
          Expanded(
            child: _buildMetricCard('Today Forecast Revenue', '\$${todayRevenue.toStringAsFixed(2)} AUD', Icons.payments_outlined, Colors.green),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: _buildMetricCard('Total Booked Pets', '$targetedCount Active Profiles', Icons.pets_outlined, Colors.indigo),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color col) {
    return Container(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
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
          Expanded(
            child: Wrap(
              spacing: 8, 
              runSpacing: 4,
              children: widget.config.tags.map((t) => Chip(
                backgroundColor: col.withAlpha(15), 
                side: BorderSide.none,
                label: Text(t, style: TextStyle(color: col, fontWeight: FontWeight.w500, fontSize: 12))
              )).toList(),
            ),
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
        body: jsonEncode({'isActive': !currentStatus}),
      );

      if (response.statusCode == 200) {
        await _fetchServiceMatrices();
        _showSnackBar('🔄 Service status updated.');
      } else {
        _showSnackBar('❌ Failed to update status.');
      }
    } catch (_) {
      _showSnackBar('❌ Transport Layer Error.');
    } finally {
      if (mounted) setState(() => _isServiceLoading = false);
    }
  }
  Future<void> _fetchStaffList() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/merchant/staff'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> rawList = responseData['data'];
          
          // Map across items to safely extract user.employee.isActive into user.isActive
          final flattenedList = rawList.map((user) {
            bool extractedStatus = false;
            
            if (user['employee'] != null && user['employee']['isActive'] != null) {
              extractedStatus = user['employee']['isActive'] as bool;
            } else if (user['isActive'] != null) {
              extractedStatus = user['isActive'] as bool;
            }

            return {
              'id': user['id'],
              'name': user['name'],
              'email': user['email'],
              'role': user['role'],
              'isActive': extractedStatus,
            };
          }).toList();

          setState(() {
            _invitedStaff = flattenedList;
          });
        }
      }
    } catch (_) {
      // Gracefully catch background framework transport network drops
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
                  Expanded(
                    child: Row(
                      children: [
                        Icon(_isServiceMatrixVisible ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded, color: const Color(0xFF475569)),
                        const SizedBox(width: 8),
                        const Flexible(child: Text('Service Pricing Configuration Matrix', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  if (widget.isAdmin && _isServiceMatrixVisible)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_business_outlined, size: 16),
                      label: const Text('Add Entry'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                      onPressed: () => _showAddServiceMatrixDialog(context),
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
                child: Text('No pricing profiles defined.', style: TextStyle(color: Colors.grey)),
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
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(matrix['name'] ?? 'Unnamed Template', style: TextStyle(fontWeight: FontWeight.w600, color: active ? const Color(0xFF1E293B) : Colors.grey)),
                              const SizedBox(height: 4),
                              Text('Weight: ${matrix['weightTier']} • Coat: ${matrix['coatType']} • Duration: ${matrix['durationMinutes']}m', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Text('\$${((matrix['priceCentsAud'] ?? 0) / 100).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: active ? const Color(0xFF0F172A) : Colors.grey)),
                        if (widget.isAdmin) ...[
                          const SizedBox(width: 12),
                          Switch(value: active, activeColor: col, onChanged: (v) => _toggleServiceActiveStatus(matrix['id'], active)),
                        ],
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
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
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
              ? const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No active scheduled booking instances.')))
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dog Name: ${app['petName']} (${app['breed']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                            const SizedBox(height: 4),
                            Text('Service: ${app['service']} • Time: ${app['time']}', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
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

  // Create a staff lookup map for efficient ID-to-Name mapping
  final Map<String, String> staffLookup = {};
  if (_invitedStaff != null) {
    for (var staff in _invitedStaff!) {
      if (staff['id'] != null && staff['name'] != null) {
        staffLookup[staff['id'].toString()] = staff['name'].toString();
      }
    }
  }

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

  const double slotHeight = 70.0;
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
            
            Expanded(
              child: SizedBox(
                height: totalHours * slotHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    
                    final sortedApps = List.from(dailyFilteredApps)
                      ..sort((a, b) => a['rawStartTime'].compareTo(b['rawStartTime']));

                    List<List<Map<String, dynamic>>> columns = [];
                    for (var app in sortedApps) {
                      bool placed = false;
                      for (var column in columns) {
                        final lastApp = column.last;
                        final lastStart = lastApp['rawStartTime'] as DateTime;
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

                        ...List.generate(columns.length, (colIndex) {
                          final currentColumnApps = columns[colIndex];
                          return currentColumnApps.map((app) {
                            final start = app['rawStartTime'] as DateTime;
                            final end = app['rawEndTime'] as DateTime? ?? start.add(const Duration(hours: 2));

                            final double startMinutes = (start.hour - startHour) * 60.0 + start.minute;
                            final double endMinutes = (end.hour - startHour) * 60.0 + end.minute;

                            final double topPosition = (startMinutes / 60.0) * slotHeight;
                            final double blockHeight = ((endMinutes - startMinutes) / 60.0) * slotHeight;
                            
                            final cardColor = _getPastelColor(app['breed'] ?? '');

                            // Lookup the staff name based on the groomerId
                            final String currentGroomerId = app['groomerId']?.toString() ?? '';
                            final String staffName = staffLookup[currentGroomerId] ?? 'No Staff Assigned';

                            return Positioned(
                              top: topPosition,
                              left: colIndex * itemWidth,
                              width: itemWidth - 4,
                              height: blockHeight - 2, 
                              child: Tooltip(
                                richMessage: TextSpan(
                                  style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                                  children: [
                                    TextSpan(text: '🐾 Dog: ${app['petName']} (${app['breed']})\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: '👤 Owner: ${app['ownerName'] ?? 'Unknown Owner'}\n'),
                                    TextSpan(text: '📞 Phone: ${app['ownerPhone'] ?? 'No Phone'}\n'),
                                    TextSpan(text: '✉️ Email: ${app['ownerEmail'] ?? 'No Email'}\n'),
                                    TextSpan(text: '✂️ Staff: $staffName'),
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
                                waitDuration: const Duration(milliseconds: 200),
                                child: GestureDetector(
                                  onTap: () => _showUpdateBookingOptionsDialog(app),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cardColor.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: cardColor, width: 1.5),
                                    ),
                                    child: SingleChildScrollView(
                                      physics: const NeverScrollableScrollPhysics(),
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
                                          const SizedBox(height: 2),
                                          Text(
                                            '✂️ Staff: $staffName',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade800,
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

  Color _getPastelColor(String seed) {
    final int hash = seed.hashCode;
    final List<Color> colors = [Colors.green.shade600, Colors.purple.shade400, Colors.orange.shade600, Colors.blue.shade600];
    return colors[hash.abs() % colors.length];
  }

  Widget _buildWeeklyScheduleGrid(Color col) {
    final targetDate = _selectedDay ?? DateTime.now();
    final DateTime mondayOfTargetWeek = targetDate.subtract(Duration(days: targetDate.weekday - 1));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'One Week Aggregate Density', 
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(7, (index) {
              final DateTime dayOfRow = mondayOfTargetWeek.add(Duration(days: index));
              final count = mockAppointments.where((a) => isSameDay(a['rawStartTime'], dayOfRow)).length;
              final bool isCurrentSelected = isSameDay(_selectedDay, dayOfRow);

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isCurrentSelected ? col.withAlpha(25) : Colors.blueGrey.shade50, 
                    border: isCurrentSelected ? Border.all(color: col, width: 1.5) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() {
                      _selectedDay = dayOfRow;
                      _focusedDay = dayOfRow;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${dayOfRow.day}/${dayOfRow.month}', 
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$count Grooms', 
                            style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
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

  void _confirmActionGuard({
    required String title,
    required String body,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(body, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateBookingOptionsDialog(Map<String, dynamic> app) async {
  try {
    await _fetchStaffList();
    bool isCheckedIn = app['isCheckedIn'] ?? false;
    bool depositPaid = app['isDepositPaid'] ?? false;
    bool isReadyForPickup = app['isReadyForPickup'] ?? false;
    bool isLoyaltyWaived = app['isLoyaltyWaived'] ?? false;
    String currentStatus = app['status'] ?? 'PENDING';

    final tagsController = TextEditingController(
      text: (app['staffTags'] as List? ?? []).join(', '),
    );

    DateTime updatedBookingDate = app['rawStartTime'] is DateTime
        ? app['rawStartTime']
        : (DateTime.tryParse(app['rawStartTime']?.toString() ?? '') ?? DateTime.now());

    // Helper: Convert a DateTime to "hh:mm AM/PM"
    String formatTo12Hour(DateTime dt) {
      final int hour = dt.hour;
      final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final String amPm = hour >= 12 ? 'PM' : 'AM';
      final String paddedHour = displayHour.toString().padLeft(2, '0');
      final String paddedMinute = dt.minute.toString().padLeft(2, '0');
      return '$paddedHour:$paddedMinute $amPm';
    }

    // Helper: Safely parse dynamic slot strings to "hh:mm AM/PM"
    String parseSlotTo12Hour(String rawSlot) {
      final cleaned = rawSlot.trim();
      
      // If it's already in 12-hour format
      if (cleaned.toUpperCase().contains('AM') || cleaned.toUpperCase().contains('PM')) {
        return cleaned;
      }

      // If it's in 24-hour format (e.g., "14:30" or "14:30:00")
      final parts = cleaned.split(':');
      if (parts.length >= 2) {
        final int hour = int.tryParse(parts[0]) ?? 0;
        final int minute = int.tryParse(parts[1].substring(0, 2)) ?? 0;

        final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        final String amPm = hour >= 12 ? 'PM' : 'AM';
        final String paddedHour = displayHour.toString().padLeft(2, '0');
        final String paddedMinute = minute.toString().padLeft(2, '0');

        return '$paddedHour:$paddedMinute $amPm';
      }

      return cleaned;
    }

    // Helper: Convert "hh:mm AM/PM" string back into DateTime on save
    DateTime parseSelectedSlotToDateTime(DateTime date, String slotStr) {
      try {
        final parts = slotStr.trim().split(' ');
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        final int minute = int.parse(timeParts[1]);

        if (parts.length > 1) {
          final isPM = parts[1].toUpperCase() == 'PM';
          if (isPM && hour < 12) hour += 12;
          if (!isPM && hour == 12) hour = 0;
        }

        return DateTime(date.year, date.month, date.day, hour, minute);
      } catch (_) {
        return date;
      }
    }

    String updatedBookingTimeSlot = formatTo12Hour(updatedBookingDate);
    List<String> operationalHoursTimeOptions = [updatedBookingTimeSlot];

    bool isLoadingSlots = false;
    bool isDayClosed = false;
    bool hasInitialFetched = false;

    // Track staff selection states inside the modal instance
    bool isLoadingStaff = _invitedStaff == null;
    dynamic selectedGroomerId = app['groomerId'];

    Future<void> loadInitialSlots(StateSetter setModalState) async {
      if (hasInitialFetched) return;
      hasInitialFetched = true;

      setModalState(() {
        isLoadingSlots = true;
        isDayClosed = false;
      });

      try {
        final String formattedDate = "${updatedBookingDate.year}-"
            "${updatedBookingDate.month.toString().padLeft(2, '0')}-"
            "${updatedBookingDate.day.toString().padLeft(2, '0')}";

        //final int durationMinutes = app['durationMinutes'] ?? 60;
        final String targetUrl = '$_baseUrl/api/v1/bookings/admin/available-slots'
            '?merchantId=${widget.config.merchantId}'
            '&date=$formattedDate';

        final response = await http.get(
          Uri.parse(targetUrl),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> parsedBody = json.decode(response.body);
          if (parsedBody['success'] == true && parsedBody['data'] is List) {
            final List<dynamic> backendSlots = parsedBody['data'];

            setModalState(() {
              isLoadingSlots = false;
              if (backendSlots.isNotEmpty) {
                isDayClosed = false;

                // Safely convert all returned slots into "hh:mm AM/PM" format
                operationalHoursTimeOptions = backendSlots
                    .map<String>((slot) => parseSlotTo12Hour(slot.toString()))
                    .toList();

                if (!operationalHoursTimeOptions.contains(updatedBookingTimeSlot)) {
                  updatedBookingTimeSlot = operationalHoursTimeOptions.first;
                }
              } else {
                isDayClosed = true;
                operationalHoursTimeOptions = [];
              }
            });
            return;
          }
        }
        setModalState(() => isLoadingSlots = false);
      } catch (e) {
        setModalState(() => isLoadingSlots = false);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 600;

        return StatefulBuilder(
          builder: (context, setModalState) {
            // Async helper to pull the staff list records down and rebuild layout state
            Future<void> loadStaffDataForDialog() async {
              await _fetchStaffList();
              if (context.mounted) {
                setModalState(() {
                  isLoadingStaff = false;
                  final active = (_invitedStaff ?? []).where((s) => s['isActive'] == true).toList();
                  if (selectedGroomerId == null && active.isNotEmpty) {
                    selectedGroomerId = active.first['id'];
                  }
                });
              }
            }

            if (isLoadingStaff) {
              loadStaffDataForDialog();
            }

            if (!hasInitialFetched) {
              Future.delayed(Duration.zero, () => loadInitialSlots(setModalState));
            }

            final activeGroomers = (_invitedStaff ?? [])
                .where((staff) => staff['isActive'] == true)
                .toList();

            if (selectedGroomerId == null && activeGroomers.isNotEmpty) {
              selectedGroomerId = activeGroomers.first['id'];
            }

            return AlertDialog(
              insetPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  const Icon(Icons.edit_calendar, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Manage Booking: Dog Name: ${app['petName']} (Breed: ${app['breed']})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: isCompact ? screenWidth : 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Owner Account: ${app['ownerName']} (${app['ownerPhone']})',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.layers_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Service: ${app['service'] ?? 'General'} [${app['time']}]',
                              style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Reschedule Date & Time Layout',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),

                      isCompact
                          ? Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.calendar_today, size: 14),
                                    label: Text(
                                        '${updatedBookingDate.day}/${updatedBookingDate.month}/${updatedBookingDate.year}'),
                                    onPressed: () async {
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: updatedBookingDate,
                                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                                      );
                                      if (pickedDate != null) {
                                        setModalState(() {
                                          updatedBookingDate = pickedDate;
                                          hasInitialFetched = false;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildTimeSlotDropdown(
                                    isDayClosed,
                                    isLoadingSlots,
                                    operationalHoursTimeOptions,
                                    updatedBookingTimeSlot,
                                    (val) => setModalState(() => updatedBookingTimeSlot = val!)),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.calendar_today, size: 14),
                                    label: Text(
                                        '${updatedBookingDate.day}/${updatedBookingDate.month}/${updatedBookingDate.year}'),
                                    onPressed: () async {
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: updatedBookingDate,
                                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                                      );
                                      if (pickedDate != null) {
                                        setModalState(() {
                                          updatedBookingDate = pickedDate;
                                          hasInitialFetched = false;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTimeSlotDropdown(
                                      isDayClosed,
                                      isLoadingSlots,
                                      operationalHoursTimeOptions,
                                      updatedBookingTimeSlot,
                                      (val) => setModalState(() => updatedBookingTimeSlot = val!)),
                                ),
                              ],
                            ),
                      const SizedBox(height: 16),

                      // --- New Selection Dropdown of Staff ---
                      const Text(
                        'Assigned Staff Member *',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4)),
                        child: DropdownButtonHideUnderline(
                          child: isLoadingStaff
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2)),
                                      SizedBox(width: 12),
                                      Text('Syncing active staff...',
                                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                                    ],
                                  ),
                                )
                              : activeGroomers.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12.0),
                                      child: Text(
                                        'No active staff members available',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    )
                                  : (() {
                                      final dynamic effectiveSelectedId = (selectedGroomerId == null || selectedGroomerId == '')
                                          ? null
                                          : (activeGroomers.any((g) => g['id'] == selectedGroomerId) ? selectedGroomerId : null);

                                      return DropdownButton<dynamic>(
                                        isExpanded: true,
                                        value: effectiveSelectedId,
                                        hint: const Text('Select an assigned professional'),
                                        items: activeGroomers.map((groomer) {
                                          return DropdownMenuItem<dynamic>(
                                            value: groomer['id'],
                                            child: Text('${groomer['name']}'),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setModalState(() => selectedGroomerId = val);
                                        },
                                      );
                                    }()),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Administrative Pipeline Status ---
                      const Text(
                        'Administrative Pipeline Status',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: currentStatus,
                            items: const [
                              DropdownMenuItem(value: 'PENDING', child: Text('Pending Approval')),
                              DropdownMenuItem(value: 'PAID', child: Text('Paid / Settled')),
                              DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                              DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                              DropdownMenuItem(value: 'NOSHOW', child: Text('No Show')),
                            ],
                            onChanged: (v) => setModalState(() => currentStatus = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Pet Checked In', style: TextStyle(fontSize: 14)),
                        value: isCheckedIn,
                        onChanged: (val) => setModalState(() => isCheckedIn = val!),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Deposit Amount Paid', style: TextStyle(fontSize: 14)),
                        value: depositPaid,
                        onChanged: (val) => setModalState(() => depositPaid = val!),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ready For Pickup', style: TextStyle(fontSize: 14)),
                        value: isReadyForPickup,
                        onChanged: (val) => setModalState(() => isReadyForPickup = val!),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Loyalty Fee Waived', style: TextStyle(fontSize: 14)),
                        value: isLoyaltyWaived,
                        onChanged: (val) => setModalState(() => isLoyaltyWaived = val!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Internal Staff Flow Tags (comma separated)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.isAdmin)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                              icon: const Icon(Icons.delete_forever_outlined, size: 16),
                              label: const Text('Delete'),
                              onPressed: () {
                                _confirmActionGuard(
                                  title: 'Purge Booking Instance?',
                                  body: 'This action completely erases this booking records.',
                                  onConfirm: () async {
                                    try {
                                      final res = await http.delete(
                                        Uri.parse('$_baseUrl/api/v1/bookings/${app['id']}'),
                                        headers: {
                                          'Authorization': 'Bearer ${widget.authToken}',
                                        },
                                      );
                                      if (res.statusCode == 200) {
                                        Navigator.pop(context);
                                        _showSnackBar('🗑️ Booking successfully purged.');
                                        _fetchDashboardAppointments();
                                      }
                                    } catch (_) {}
                                  },
                                );
                              },
                            )
                          else
                            const SizedBox.shrink(),
                          Row(
                            children: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel')),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.config.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  if (selectedGroomerId == null) {
                                    _showSnackBar('⚠️ A valid active staff member must be assigned.');
                                    return;
                                  }

                                  // Convert 12-hour formatted selection safely back to DateTime
                                  final targetDateTime = parseSelectedSlotToDateTime(
                                    updatedBookingDate,
                                    updatedBookingTimeSlot,
                                  );

                                  final cleanTags = tagsController.text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();

                                  final payload = {
                                    'status': currentStatus,
                                    'startTime': targetDateTime.toIso8601String(),
                                    'isCheckedIn': isCheckedIn,
                                    'depositPaid': depositPaid,
                                    'isReadyToPickup': isReadyForPickup,
                                    'isLoyaltyWaived': isLoyaltyWaived,
                                    'groomerId': selectedGroomerId,
                                    'internalTags': cleanTags,
                                  };

                                  try {
                                    final response = await http.put(
                                      Uri.parse('$_baseUrl/api/v1/bookings/update/${app['id']}'),
                                      headers: {
                                        'Content-Type': 'application/json',
                                        'Authorization': 'Bearer ${widget.authToken}',
                                      },
                                      body: jsonEncode(payload),
                                    );

                                    if (response.statusCode == 200) {
                                      Navigator.pop(context);
                                      _showSnackBar('🎉 Booking details successfully updated.');
                                      _fetchDashboardAppointments();
                                    } else {
                                      _showSnackBar('❌ Failed to save pipeline parameters.');
                                    }
                                  } catch (_) {
                                    _showSnackBar('❌ Network failure syncing data elements.');
                                  }
                                },
                                child: const Text('Save Changes'),
                              ),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  } catch (error) {
    _showSnackBar("Failed to fetch staff list before opening dialog:");
  }
}

  void _showAddServiceMatrixDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final depositController = TextEditingController();

    String selectedCoat = 'SHORT';
    String selectedWeight = 'M';
    int selectedDuration = 45;

    final List<int> durationOptions = [15, 30, 45, 60, 75, 90, 105, 120];

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final isWebMobile = MediaQuery.of(context).size.width < 600;

            return Dialog(
              backgroundColor: const Color(0xFFEFEBF2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isWebMobile ? 16 : 40,
                vertical: 24,
              ),
              child: Container(
                width: isWebMobile ? double.infinity : 520,
                padding: const EdgeInsets.all(28.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.store_outlined, size: 28, color: Color(0xFF1E293B)),
                          SizedBox(width: 12),
                          Text(
                            'Provision Pricing Matrix Tier',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Service Matrix Name Line Label Identifier',
                          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                          filled: true,
                          fillColor: const Color(0xFFE8E3EE),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Target Coat Attribute Configuration Variant Matrix Layer',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD3CEDC),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCoat,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                            items: ['SHORT', 'LONG_CURLY', 'DOUBLE_COAT']
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setStateDialog(() => selectedCoat = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Target Weight Profile Tier Matrix Layer Filter Option Type Descriptor',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedWeight,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                            items: ['S', 'M', 'L', 'XL']
                                .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setStateDialog(() => selectedWeight = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Allocated Operational Handling Execution Window Span Duration Minutes',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: durationOptions.map((mins) {
                          final isSelected = mins == selectedDuration;
                          return InkWell(
                            onTap: () => setStateDialog(() => selectedDuration = mins),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFDDD2EB) : Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF7E22CE) : Colors.grey.shade400,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    const Icon(Icons.check, size: 16, color: Color(0xFF4C1D95)),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    '$mins min',
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Price Target Rate (\$ AUD)',
                          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                          filled: true,
                          fillColor: const Color(0xFFE8E3EE),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: depositController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Deposit Amount (\$ AUD)',
                          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                          filled: true,
                          fillColor: const Color(0xFFE8E3EE),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              nameController.dispose();
                              priceController.dispose();
                              depositController.dispose();
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFF6B21A8), fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                              final deposit = double.tryParse(depositController.text.trim()) ?? 0.0;

                              if (name.isEmpty) {
                                _showSnackBar('⚠️ Please specify a matrix tier name.');
                                return;
                              }

                              nameController.dispose();
                              priceController.dispose();
                              depositController.dispose();
                              Navigator.pop(context);

                              await _createServiceMatrixTier(
                                name: name,
                                coatType: selectedCoat,
                                weightTier: selectedWeight,
                                duration: selectedDuration,
                                priceCents: (price * 100).round(),
                                depositCents: (deposit * 100).round(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              'Confirm Provision',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildManagementDrawer(Color themeColor) {
    return Drawer(
      width: kIsWeb ? 450 : MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _drawerTabController,
              labelColor: themeColor,
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: themeColor,
              tabs: const [
                Tab(icon: Icon(Icons.schedule), text: 'Hours'),
                Tab(icon: Icon(Icons.group), text: 'Team'),
                Tab(icon: Icon(Icons.people), text: 'Clients'),
                Tab(icon: Icon(Icons.calendar_month), text: 'Roster'), 
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _drawerTabController,
                children: [
                  ManageHoursPanel(config: widget.config, authToken: widget.authToken),
                  ManageTeamPanel(config: widget.config, authToken: widget.authToken),
                  CustomerInfoPanel(config: widget.config, authToken: widget.authToken, baseUrl: _baseUrl, themeColor: themeColor),
                  // Replaced with a placeholder container since navigation is now handled explicitly by the listener
                  const Center(child: CircularProgressIndicator()), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}