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
  
  final Map<DateTime, List<String>> _staffRosterAssignments = {};
  List<EmployeeSummary> _masterTeamMembersPool = [];

  bool _isSaving = false;
  bool _isLoadingStaff = true;
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

      _prepopulateDefaultAssignments(existingShiftsMap);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error communicating with active staff directory: $e')),
      );
    } finally {
      setState(() => _isLoadingStaff = false);
    }
  }

  void _prepopulateDefaultAssignments([Map<DateTime, List<String>>? existingShiftsMap]) {
    if (_masterTeamMembersPool.isEmpty) return;
    
    if (existingShiftsMap != null) {
      _staffRosterAssignments.clear();
      _staffRosterAssignments.addAll(existingShiftsMap);
    }
    
    final now = DateTime.now();
    DateTime loopDay = DateTime(now.year, now.month, now.day);
    int scheduledDaysCount = 0;

    while (scheduledDaysCount < _rosterDaysLimit) {
      final cleanNormalizedDay = DateTime(loopDay.year, loopDay.month, loopDay.day);
      if (!_checkIsDayClosed(cleanNormalizedDay)) {
        if (!_staffRosterAssignments.containsKey(cleanNormalizedDay)) {
          _staffRosterAssignments[cleanNormalizedDay] = 
              _masterTeamMembersPool.map((e) => e.id).toList();
        }
        scheduledDaysCount++;
      }
      loopDay = loopDay.add(const Duration(days: 1));
    }
  }

  bool _isWithinOpenDaysLimit(DateTime date) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    if (date.isBefore(start)) return false;

    int openDaysCount = 0;
    DateTime temp = start;

    while (openDaysCount < _rosterDaysLimit) {
      final cleanTemp = DateTime(temp.year, temp.month, temp.day);
      if (!_checkIsDayClosed(cleanTemp)) {
        if (cleanTemp.isAtSameMomentAs(date)) {
          return true;
        }
        openDaysCount++;
      }
      if (cleanTemp.isAfter(date)) {
        return false;
      }
      temp = temp.add(const Duration(days: 1));
    }
    return false;
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
          // Responsive width for dialog matching screen sizes
          final screenWidth = MediaQuery.of(context).size.width;
          return AlertDialog(
            title: Text(
              'Roster Matrix: ${normalizedDate.day}/${normalizedDate.month}/${normalizedDate.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: screenWidth > 500 ? 400 : screenWidth * 0.85,
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
        title: const Text(
          'Staff Scheduling Management', 
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: ElevatedButton.icon(
              icon: _isSaving 
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.cloud_upload_outlined, size: 16),
              label: const Text('Publish', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white),
              onPressed: _isSaving || _isLoadingStaff ? null : _commitRosterUpdatesToRemote,
            ),
          )
        ],
      ),
      body: _isLoadingStaff
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                // Breakpoint evaluation: Mobile vs Tablet/Desktop
                final bool isMobile = constraints.maxWidth < 768;
                
                // Adaptive layout configuration
                final contentWidgets = [
                  // 1. Horizon Setting Configuration Element
                  _buildHorizonConfigPanel(themeColor, isMobile),
                  
                  // 2. Main content panels (stacked or side-by-side depending on viewport)
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildCalendarCard(themeColor),
                            const SizedBox(height: 16),
                            _buildAssignmentsCard(themeColor, activeSelectedDay, normalizedActiveDay, isSelectedDayClosed, currentDayStaffIds, isMobile),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _buildCalendarCard(themeColor),
                            ),
                            Expanded(
                              flex: 6,
                              child: _buildAssignmentsCard(themeColor, activeSelectedDay, normalizedActiveDay, isSelectedDayClosed, currentDayStaffIds, isMobile),
                            ),
                          ],
                        )
                ];

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: contentWidgets,
                  ),
                );
              },
            ),
    );
  }

  // --- HELPER LAYOUT REFACTORING BLOCKS ---

  Widget _buildHorizonConfigPanel(Color themeColor, bool isMobile) {
    final titleWidget = Text(
      'Roster Horizon Configuration: ',
      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 13),
    );
    final valueWidget = Text(
      '$_rosterDaysLimit Open Days',
      style: TextStyle(fontWeight: FontWeight.bold, color: themeColor, fontSize: 14),
    );
    final sliderWidget = Slider(
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
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: isMobile 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, color: Color(0xFF0F172A), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Wrap(runSpacing: 4, children: [titleWidget, valueWidget])),
                  ],
                ),
                sliderWidget,
              ],
            )
          : Row(
              children: [
                const Icon(Icons.tune, color: Color(0xFF0F172A)),
                const SizedBox(width: 12),
                titleWidget,
                valueWidget,
                Expanded(child: sliderWidget),
              ],
            ),
    );
  }

  Widget _buildCalendarCard(Color themeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TableCalendar(
        firstDay: DateTime.utc(2026, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        rowHeight: 52, // Secure text/elements bounds spacing heights 
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
            
            if (checkDay.isBefore(todayMidnight)) return const SizedBox();
            if (_checkIsDayClosed(checkDay)) return const SizedBox();
            if (!_isWithinOpenDaysLimit(checkDay)) return const SizedBox();

            final staffCount = _staffRosterAssignments[checkDay]?.length ?? 0;
            if (staffCount == 0) return const SizedBox();
            
            return Positioned(
              bottom: 2,
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
    );
  }

  Widget _buildAssignmentsCard(
    Color themeColor, 
    DateTime activeSelectedDay, 
    DateTime normalizedActiveDay, 
    bool isSelectedDayClosed, 
    List<String> currentDayStaffIds,
    bool isMobile,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Responsive configuration inside content updates card header
          isMobile 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assignments for ${activeSelectedDay.day}/${activeSelectedDay.month}/${activeSelectedDay.year}', 
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (!isSelectedDayClosed && !normalizedActiveDay.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                          onPressed: () => _showStaffAllocationDialog(normalizedActiveDay),
                          child: const Text('Modify Shifts'),
                        ),
                      ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Assignments for ${activeSelectedDay.day}/${activeSelectedDay.month}/${activeSelectedDay.year}', 
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    if (!isSelectedDayClosed && !normalizedActiveDay.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                        onPressed: () => _showStaffAllocationDialog(normalizedActiveDay),
                        child: const Text('Modify Shifts'),
                      ),
                  ],
                ),
          const Divider(height: 24),
          if (isSelectedDayClosed)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Shop Closed', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            )
          else if (currentDayStaffIds.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No Staff Allocated', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            )
          else
            // Changed list pattern from Expanded to standard ListView with fixed constraints inside structural layout parameters
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentDayStaffIds.length,
              itemBuilder: (context, idx) {
                final empId = currentDayStaffIds[idx];
                final employee = _masterTeamMembersPool.firstWhere(
                  (e) => e.id == empId, 
                  orElse: () => EmployeeSummary(id: '', name: 'Unknown', email: ''),
                );
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: themeColor.withOpacity(0.2),
                    foregroundColor: themeColor,
                    child: Text(employee.name.isNotEmpty ? employee.name.substring(0, 1) : '?'),
                  ),
                  title: Text(employee.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(employee.email, style: const TextStyle(fontSize: 12)), 
                );
              },
            )
        ],
      ),
    );
  }
}