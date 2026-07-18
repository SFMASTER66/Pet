import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import '../models/merchant_config.dart';

/// Lightweight data model representing relational properties from the Employee table
class EmployeeSummary {
  final String id;
  final String name;

  EmployeeSummary({required this.id, required this.name});
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
  
  /// Tracks structured database relation mapping: Date -> List of Unique Employee IDs
  final Map<DateTime, List<String>> _staffRosterAssignments = {};
  
  /// Simulates baseline data pulled directly from the Employee relation table[cite: 2]
  final List<EmployeeSummary> _masterTeamMembersPool = [
    EmployeeSummary(id: 'emp-uuid-1111', name: 'Sarah Jenkins'),
    EmployeeSummary(id: 'emp-uuid-2222', name: 'Michael Chang'),
    EmployeeSummary(id: 'emp-uuid-3333', name: 'Emma Rodriguez'),
    EmployeeSummary(id: 'emp-uuid-4444', name: 'David Fletcher'),
    EmployeeSummary(id: 'emp-uuid-5555', name: 'Chloe Watson'),
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _prepopulateDefaultAssignments();
  }

  /// Initial staging cycle validating active business hour indices[cite: 2]
  void _prepopulateDefaultAssignments() {
    final DateTime startRange = DateTime.now().subtract(const Duration(days: 30));
    for (int idx = 0; idx < 90; idx++) {
      final DateTime loopDay = startRange.add(Duration(days: idx));
      final cleanNormalizedDay = DateTime(loopDay.year, loopDay.month, loopDay.day);
      
      // Auto-populate open standard shifts across baseline available tracking ranges
      if (!_checkIsDayClosed(cleanNormalizedDay)) {
        _staffRosterAssignments[cleanNormalizedDay] = 
            _masterTeamMembersPool.map((e) => e.id).toList();
      }
    }
  }

  /// Evaluates weekday index markers against the Merchant BusinessHours array data[cite: 2]
  bool _checkIsDayClosed(DateTime date) {
    if (widget.businessHoursConfig.isEmpty) return false;
    final targetRecord = widget.businessHoursConfig.firstWhere(
      (element) => element['dayOfWeek'] == date.weekday,
      orElse: () => null,
    );
    return targetRecord != null && targetRecord['isClosed'] == true;
  }

  /// Custom interaction layout to control user task allocations on specific dates
  void _showStaffAllocationDialog(DateTime activeDate) {
    final normalizedDate = DateTime(activeDate.year, activeDate.month, activeDate.day);
    List<String> activeAssignments = List.from(_staffRosterAssignments[normalizedDate] ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.badge_outlined, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Roster Matrix: ${normalizedDate.day}/${normalizedDate.month}/${normalizedDate.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assign personnel designated for active workflow execution across this shift timeframe:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  ..._masterTeamMembersPool.map((employee) {
                    final bool isAssigned = activeAssignments.contains(employee.id);
                    return CheckboxListTile(
                      title: Text(employee.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      value: isAssigned,
                      dense: true,
                      activeColor: widget.config.primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? isChecked) {
                        setModalState(() {
                          if (isChecked == true) {
                            if (!activeAssignments.contains(employee.id)) {
                              activeAssignments.add(employee.id);
                            }
                          } else {
                            activeAssignments.remove(employee.id);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.config.primaryColor,
                  foregroundColor: Colors.white,
                ),
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

  /// Transforms the matrix to deliver flat JSON arrays matching the database schema
  Future<void> _commitRosterUpdatesToRemote() async {
    setState(() => _isSaving = true);
    
    List<Map<String, dynamic>> shiftPayload = [];

    _staffRosterAssignments.forEach((dateKey, employeeIds) {
      final formattedDate = "${dateKey.year}-${dateKey.month.toString().padLeft(2, '0')}-${dateKey.day.toString().padLeft(2, '0')}";
      
      for (String empId in employeeIds) {
        shiftPayload.add({
          "merchantId": widget.config.merchantId,
          "employeeId": empId,
          "date": formattedDate,
          "startTime": "09:00", 
          "endTime": "17:00"
        });
      }
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.yourproductiondomain.com/v1/merchants/${widget.config.merchantId}/shifts/batch'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode({"shifts": shiftPayload}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚀 Production roster adjustments successfully synchronized with cloud data clusters!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Server rejected request architecture.');
      }
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Transmission synchronization error: $err')),
      );
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
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Staff Scheduling Management System',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 17),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload_outlined, size: 16),
              label: const Text('Publish Roster Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: _isSaving ? null : _commitRosterUpdatesToRemote,
            ),
          )
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Frame Area: The interactive calendar tracking tool
          Expanded(
            flex: 4,
            child: Container(
              height: double.infinity,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Roster Timeline Matrix Picker',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    TableCalendar(
                      firstDay: DateTime.utc(2026, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
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
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Right Frame Area: Active schedule details panel view
          Expanded(
            flex: 6,
            child: Container(
              height: double.infinity,
              margin: const EdgeInsets.only(top: 24, bottom: 24, right: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shift Assignments for ${activeSelectedDay.day}/${activeSelectedDay.month}/${activeSelectedDay.year}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          const Text('Review configurations mapped to this timeframe instance', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        ],
                      ),
                      if (!isSelectedDayClosed)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit_note, size: 16),
                          label: const Text('Modify Roster Shifts'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => _showStaffAllocationDialog(normalizedActiveDay),
                        ),
                    ],
                  ),
                  const Divider(height: 32),
                  
                  if (isSelectedDayClosed)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_outlined, size: 48, color: Colors.red.shade300),
                            const SizedBox(height: 12),
                            const Text(
                              'Baseline Operations Shop Closed',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'The global calendar business hours parameters register this day variant as locked.',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      'Total Assigned Capacity: ${currentDayStaffIds.length} Members Online',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 14),
                    currentDayStaffIds.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: Text('⚠️ No staff currently allocated to run schedules over this date window.')),
                          )
                        : Expanded(
                            child: ListView.separated(
                              itemCount: currentDayStaffIds.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, sIdx) {
                                final assignedEmpId = currentDayStaffIds[sIdx];
                                
                                // Resolve details out of our master model array matching foreign keys
                                final employeeMeta = _masterTeamMembersPool.firstWhere(
                                  (e) => e.id == assignedEmpId,
                                  orElse: () => EmployeeSummary(id: 'unknown', name: 'Unknown Practitioner'),
                                );

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: themeColor.withOpacity(0.1),
                                        radius: 18,
                                        child: Text(
                                          employeeMeta.name.substring(0, 1),
                                          style: TextStyle(fontWeight: FontWeight.bold, color: themeColor, fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(employeeMeta.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                                            Text('Database ID: ${employeeMeta.id} • Active Professional', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                                        child: Text(
                                          'Active Shift',
                                          style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}