import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/merchant_config.dart';

class ManageHoursPanel extends StatefulWidget {
  final MerchantConfig config;
  final String authToken;

  const ManageHoursPanel({
    super.key,
    required this.config,
    required this.authToken,
  });

  @override
  State<ManageHoursPanel> createState() => _ManageHoursPanelState();
}

class _ManageHoursPanelState extends State<ManageHoursPanel> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _businessHours = [];

  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // Simple preset time slots list for straightforward dropdown selection
  final List<String> _timeSlots = [
    '06:00', '06:30', '07:00', '07:30', '08:00', '08:30', '09:00', '09:30',
    '10:00', '10:30', '11:00', '11:30', '12:00', '12:30', '13:00', '13:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
    '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', '21:00', '22:00'
  ];

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    return Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }

  @override
  void initState() {
    super.initState();
    _fetchBusinessHours();
  }

  Future<void> _fetchBusinessHours() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/merchant/${widget.config.merchantId}/hours'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _businessHours = List<Map<String, dynamic>>.from(responseData['data']);
            _businessHours.sort((a, b) => (a['dayOfWeek'] as int).compareTo(b['dayOfWeek'] as int));
          });
        }
      } else {
        _generateFallbackDefaultHours();
      }
    } catch (e) {
      _generateFallbackDefaultHours();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _generateFallbackDefaultHours() {
    setState(() {
      _businessHours = List.generate(7, (index) {
        final dayNum = index + 1;
        return {
          'dayOfWeek': dayNum,
          'openTime': '09:00',
          'closeTime': '17:00',
          'isClosed': dayNum > 5, // Saturday & Sunday closed by default
        };
      });
    });
  }

  Future<void> _saveBusinessHoursDay(Map<String, dynamic> dayData) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/v1/merchant/${widget.config.merchantId}/hours'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode({
          'dayOfWeek': dayData['dayOfWeek'],
          'openTime': dayData['openTime'],
          'closeTime': dayData['closeTime'],
          'isClosed': dayData['isClosed'],
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('💾 Schedule updated successfully.'), behavior: SnackBarBehavior.floating),
        );
      } else {
        _fetchBusinessHours(); // Revert back on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Update rejected: ${responseData['message'] ?? "Error"}'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Network connection error.'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _businessHours.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Operational Hours',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Set opening and closing bounds for customer bookings.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _businessHours.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final dayData = _businessHours[index];
                final int dayIdx = dayData['dayOfWeek'] - 1;
                final String dayName = (dayIdx >= 0 && dayIdx < 7) ? _weekdays[dayIdx] : 'Unknown';
                final bool closed = dayData['isClosed'] ?? false;

                // Ensure initial strings match a value present inside our selection list safely
                String currentOpen = dayData['openTime'] ?? '09:00';
                String currentClose = dayData['closeTime'] ?? '17:00';

                if (!_timeSlots.contains(currentOpen)) currentOpen = '09:00';
                if (!_timeSlots.contains(currentClose)) currentClose = '17:00';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          dayName,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                      ),
                      Expanded(
                        child: closed
                            ? Text(
                                'Closed',
                                style: TextStyle(color: Colors.red.shade600, fontStyle: FontStyle.italic, fontSize: 13),
                              )
                            : Row(
                                children: [
                                  // Simple Opening Time Dropdown
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: currentOpen,
                                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w500),
                                        items: _timeSlots.map((time) {
                                          return DropdownMenuItem(value: time, child: Text(time));
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => dayData['openTime'] = val);
                                            _saveBusinessHoursDay(dayData);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                                    child: Text('to', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                  ),
                                  // Simple Closing Time Dropdown
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: currentClose,
                                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w500),
                                        items: _timeSlots.map((time) {
                                          return DropdownMenuItem(value: time, child: Text(time));
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => dayData['closeTime'] = val);
                                            _saveBusinessHoursDay(dayData);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      Switch(
                        value: !closed,
                        activeColor: widget.config.primaryColor,
                        onChanged: (bool isOpen) {
                          setState(() {
                            dayData['isClosed'] = !isOpen;
                          });
                          _saveBusinessHoursDay(dayData);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}