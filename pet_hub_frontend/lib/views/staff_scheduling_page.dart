import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../models/merchant_config.dart';

class EmployeeSummary {
  final String id;
  final String name;
  final String email;

  EmployeeSummary({required this.id, required this.name, required this.email});
}

class StaffSchedulingPage extends StatefulWidget {
  final MerchantConfig config;
  final String authToken;
  final List<dynamic> businessHoursConfig;

  const StaffSchedulingPage({
    super.key,
    required this.config,
    required this.authToken,
    required this.businessHoursConfig,
  });

  @override
  State<StaffSchedulingPage> createState() => _StaffSchedulingPageState();
}

class _StaffSchedulingPageState extends State<StaffSchedulingPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month; 
  
  // Roster assignments configured dynamically: Date -> List of Assigned Employee IDs
  final Map<DateTime, List<String>> _staffRosterAssignments = {};
  List<EmployeeSummary> _masterTeamMembersPool = [];

  bool _isSaving = false;
  bool _isLoadingStaff = true;
  
  // Configurable dynamic look-ahead days range setup
  int _rosterDaysLimit = 90;

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    return Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }

  @override
  void initState() {
    super.initState();
    _fetchStaffAndInitialize();
  }

  Future<void> _fetchStaffAndInitialize() async {
    setState(() => _isLoadingStaff = true);
    try {
      // 1. Fetch active staff pool
      final staffResponse = await http.get(
        Uri.parse('$_baseUrl/api/v1/merchant/staff'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (staffResponse.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(staffResponse.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> rawList = responseData['data'];
          
          final List<EmployeeSummary> loadedStaff = [];
          for (var item in rawList) {
            loadedStaff.add(EmployeeSummary(
              id: item['id'] ?? '',
              name: item['name'] ?? 'Unknown Practitioner',
              email: item['email'] ?? 'No Email Provided',
            ));
          }

          setState(() {
            _masterTeamMembersPool = loadedStaff;
          });
        }
      }

      // 🟢 2. Fetch existing scheduled shifts from the DB
      final shiftsResponse = await http.get(
        Uri.parse('$_baseUrl/api/v1/merchant/${widget.config.merchantId}/shifts'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      Map<DateTime, List<String>> existingShiftsMap = {};

      if (shiftsResponse.statusCode == 200) {
        final Map<String, dynamic> shiftsData = jsonDecode(shiftsResponse.body);
        if (shiftsData['success'] == true && shiftsData['data'] != null) {
          final List<dynamic> rawShifts = shiftsData['data'];

          for (var shift in rawShifts) {
            if (shift['date'] != null && shift['employeeId'] != null) {
              final parsedDate = DateTime.parse(shift['date']);
              final cleanDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
              
              existingShiftsMap.putIfAbsent(cleanDate, () => []);
              existingShiftsMap[cleanDate]!.add(shift['employeeId']);
            }
          }
        }
      }

      // 🟢 3. Pre-populate UI using DB shifts if available, or fall back to default active staff
      _prepopulateDefaultAssignments(existingShiftsMap);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error communicating with active staff directory: $e')),
      );
    } finally {
      setState(() => _isLoadingStaff = false);
    }
  }

  // 🟢 UPDATED: Pre-populate logic checks existing DB records first
  void _prepopulateDefaultAssignments([Map<DateTime, List<String>>? existingShiftsMap]) {
    if (_masterTeamMembersPool.isEmpty) return;
    
    _staffRosterAssignments.clear();
    
    final now = DateTime.now();
    DateTime loopDay = DateTime(now.year, now.month, now.day);
    
    int scheduledDaysCount = 0;

    while (scheduledDaysCount < _rosterDaysLimit) {
      final cleanNormalizedDay = DateTime(loopDay.year, loopDay.month, loopDay.day);
      
      if (!_checkIsDayClosed(cleanNormalizedDay)) {
        // 🟢 IF DB HAS SHIFTS FOR THIS DATE: Use them
        if (existingShiftsMap != null && existingShiftsMap.containsKey(cleanNormalizedDay)) {
          _staffRosterAssignments[cleanNormalizedDay] = List.from(existingShiftsMap[cleanNormalizedDay]!);
        } else {
          // 🟢 IF NO SHIFTS IN DB: Show all active staff by default
          _staffRosterAssignments[cleanNormalizedDay] = 
              _masterTeamMembersPool.map((e) => e.id).toList();
        }
        scheduledDaysCount++;
      }
      
      loopDay = loopDay.add(const Duration(days: 1));
    }
  }

  bool _checkIsDayClosed(DateTime date) {
    if (widget.businessHoursConfig.isEmpty) return false;
    final targetRecord = widget.businessHoursConfig.firstWhere(
      (element) => element['dayOfWeek'] == date.weekday,
      orElse: () => null,
    );
    return targetRecord != null && targetRecord['isClosed'] == true;
  }

  void _showStaffAllocationDialog(DateTime activeDate) {
    final normalizedDate = DateTime(activeDate.year, activeDate.month, activeDate.day);
    List<String> activeAssignments = List.from(_staffRosterAssignments[normalizedDate] ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(
              'Roster Matrix: ${normalizedDate.day}/${normalizedDate.month}/${normalizedDate.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 400,
              child: _masterTeamMembersPool.isEmpty
                  ? const Text('No active team members loaded.')
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _masterTeamMembersPool.map((employee) {
                        final bool isAssigned = activeAssignments.contains(employee.id);
                        return CheckboxListTile(
                          title: Text(employee.name),
                          subtitle: Text(employee.email),
                          value: isAssigned,
                          activeColor: widget.config.primaryColor,
                          onChanged: (bool? isChecked) {
                            setModalState(() {
                              if (isChecked == true) {
                                if (!activeAssignments.contains(employee.id)) activeAssignments.add(employee.id);
                              } else {
                                activeAssignments.remove(employee.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: widget.config.primaryColor),
                onPressed: () {
                  setState(() {
                    _staffRosterAssignments[normalizedDate] = List.from(activeAssignments);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save Allocations'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _commitRosterUpdatesToRemote() async {
    setState(() => _isSaving = true);
    List<Map<String, dynamic>> shiftPayload = [];
    
    final now = DateTime.now();
    DateTime loopDay = DateTime(now.year, now.month, now.day);
    
    int processedOpenDays = 0;

    // Iterates sequentially starting strictly from today onwards up to the chosen slider limit
    while (processedOpenDays < _rosterDaysLimit) {
      final dateKey = DateTime(loopDay.year, loopDay.month, loopDay.day);
      
      if (!_checkIsDayClosed(dateKey)) {
        final List<String> employeeIds = _staffRosterAssignments[dateKey] ?? [];
        
        final formattedDate = "${dateKey.year}-${dateKey.month.toString().padLeft(2, '0')}-${dateKey.day.toString().padLeft(2, '0')}";
        
        final targetHours = widget.businessHoursConfig.firstWhere(
          (element) => element['dayOfWeek'] == dateKey.weekday,
          orElse: () => null,
        );
        final startTime = targetHours != null ? targetHours['openTime'] : "09:00";
        final endTime = targetHours != null ? targetHours['closeTime'] : "17:00";

        for (String empId in employeeIds) {
          shiftPayload.add({
            "employeeId": empId,
            "date": formattedDate,
            "startTime": startTime, 
            "endTime": endTime
          });
        }
        
        processedOpenDays++;
      }
      
      loopDay = loopDay.add(const Duration(days: 1));
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/merchant/${widget.config.merchantId}/shifts/batch'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode({"shifts": shiftPayload}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🚀 Roster changes synchronized successfully with backend!'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Server rejected request architecture.');
      }
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Sync error: $err')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.config.primaryColor;
    final activeSelectedDay = _selectedDay ?? DateTime.now();
    final normalizedActiveDay = DateTime(activeSelectedDay.year, activeSelectedDay.month, activeSelectedDay.day);
    
    final bool isSelectedDayClosed = _checkIsDayClosed(normalizedActiveDay);
    final List<String> currentDayStaffIds = _staffRosterAssignments[normalizedActiveDay] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Staff Scheduling Management', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: ElevatedButton.icon(
              icon: _isSaving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.cloud_upload_outlined),
              label: const Text('Publish Changes'),
              style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white),
              onPressed: _isSaving || _isLoadingStaff ? null : _commitRosterUpdatesToRemote,
            ),
          )
        ],
      ),
      body: _isLoadingStaff
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Frontend configuration panel for scheduling look-ahead horizon settings
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.tune, color: Color(0xFF0F172A)),
                      const SizedBox(width: 12),
                      Text(
                        'Roster Horizon Configuration: ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      ),
                      Text(
                        '$_rosterDaysLimit Open Days',
                        style: TextStyle(fontWeight: FontWeight.bold, color: themeColor, fontSize: 16),
                      ),
                      Expanded(
                        child: Slider(
                          value: _rosterDaysLimit.toDouble(),
                          min: 30,
                          max: 365,
                          divisions: 67,
                          activeColor: themeColor,
                          label: '$_rosterDaysLimit Days',
                          onChanged: (double val) {
                            setState(() {
                              _rosterDaysLimit = val.toInt();
                              _prepopulateDefaultAssignments();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Container(
                          margin: const EdgeInsets.only(left: 24, right: 12, bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: TableCalendar(
                            firstDay: DateTime.utc(2026, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            
                            availableCalendarFormats: const {
                              CalendarFormat.month: 'Month',
                            },
                            onFormatChanged: (format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            },
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, events) {
                                final checkDay = DateTime(date.year, date.month, date.day);
                                final now = DateTime.now();
                                final todayMidnight = DateTime(now.year, now.month, now.day);
                                
                                // FIX: Fixed the recursive definition variable compile bug safely here
                                if (checkDay.isBefore(todayMidnight)) {
                                  return const SizedBox();
                                }

                                if (_checkIsDayClosed(checkDay)) return const SizedBox();
                                final staffCount = _staffRosterAssignments[checkDay]?.length ?? 0;
                                if (staffCount == 0) return const SizedBox();
                                
                                return Positioned(
                                  bottom: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: themeColor.withOpacity(0.15), 
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$staffCount Staff', 
                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: themeColor),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Container(
                          margin: const EdgeInsets.only(left: 12, right: 24, bottom: 24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Assignments for ${activeSelectedDay.day}/${activeSelectedDay.month}/${activeSelectedDay.year}', 
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  if (!isSelectedDayClosed && 
                                      !normalizedActiveDay.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0F172A), 
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => _showStaffAllocationDialog(normalizedActiveDay),
                                      child: const Text('Modify Shifts'),
                                    ),
                                ],
                              ),
                              const Divider(height: 32),
                              if (isSelectedDayClosed)
                                const Expanded(
                                  child: Center(
                                    child: Text(
                                      'Shop Closed', 
                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                )
                              else
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: currentDayStaffIds.length,
                                    itemBuilder: (context, idx) {
                                      final empId = currentDayStaffIds[idx];
                                      final employee = _masterTeamMembersPool.firstWhere(
                                        (e) => e.id == empId, 
                                        orElse: () => EmployeeSummary(id: '', name: 'Unknown', email: ''),
                                      );
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: themeColor.withOpacity(0.2),
                                          foregroundColor: themeColor,
                                          child: Text(employee.name.isNotEmpty ? employee.name.substring(0, 1) : '?'),
                                        ),
                                        title: Text(employee.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Text(employee.email), 
                                      );
                                    },
                                  ),
                                )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}