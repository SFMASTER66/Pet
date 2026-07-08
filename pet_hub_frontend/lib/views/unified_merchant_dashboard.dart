import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

import '../models/merchant_config.dart';
import 'customer_portal.dart';
import 'manage_team_panel.dart';
import 'dashboard_metrics.dart';
import 'schedule_views.dart';
import 'service_matrix_table.dart';
import 'booking_dialogs.dart';

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

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  String _activeScheduleView = 'Daily List View';

  bool _isServiceMatrixVisible = true;
  bool _isServiceLoading = false;
  bool _isAppointmentsLoading = false;

  late TabController _drawerTabController;
  List<Map<String, dynamic>> mockAppointments = [];
  List<Map<String, dynamic>> liveServiceMatrices = [];

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    return Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }

  @override
  void initState() {
    super.initState();
    _drawerTabController = TabController(length: widget.isAdmin ? 2 : 1, vsync: this);
    _syncControllers();
    _fetchServiceMatrices();
    _fetchDashboardAppointments();
  }

  @override
  void didUpdateWidget(covariant UnifiedMerchantDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAdmin != oldWidget.isAdmin) {
      _drawerTabController.dispose();
      _drawerTabController = TabController(length: widget.isAdmin ? 2 : 1, vsync: this);
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
    } catch (_) {
      _showSnackBar('❌ Transport layer connection fault during background matrix synchronization.');
    } finally {
      setState(() => _isServiceLoading = false);
    }
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
          setState(() => mockAppointments = parsedLiveList);
        }
      } else {
        _showSnackBar('❌ Failed to fetch real-time production appointment records.');
      }
    } catch (_) {
      _showSnackBar('❌ Connection error querying core administrative dashboard data.');
    } finally {
      setState(() => _isAppointmentsLoading = false);
    }
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
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/matrix'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode({
          'merchantId': widget.config.merchantId,
          'name': name,
          'speciesId': 1,
          'coatType': coatType,
          'weightTier': weightTier,
          'durationMinutes': duration,
          'priceCentsAud': priceCents,
        }),
      );
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && responseData['success'] == true) {
        await _fetchServiceMatrices();
        _showSnackBar('🚀 New pricing matrix synchronized with backend production database.');
      } else {
        _showSnackBar('❌ Sync failed: ${responseData['message'] ?? 'Unknown controller validation error.'}');
      }
    } catch (_) {
      _showSnackBar('❌ Transport Layer Failure: Unable to locate target backend API cluster routes.');
    } finally {
      setState(() => _isServiceLoading = false);
    }
  }

  double get todayRevenue {
    final targetDate = _selectedDay ?? DateTime.now();
    return mockAppointments
        .where((app) => isSameDay(app['rawStartTime'], targetDate))
        .where((app) => ['CONFIRMED', 'PAID', 'PENDING', 'COMPLETED'].contains(app['status']))
        .map((app) => app['price'] as double)
        .fold(0, (p, e) => p + e);
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  void dispose() {
    _btnBookController.dispose();
    _btnCancelController.dispose();
    _btnEditController.dispose();
    _txtRevenueController.dispose();
    _drawerTabController.dispose();
    super.dispose();
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CustomerPortalPage(config: widget.config, activeServices: liveServiceMatrices))
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: Text(widget.config.getTxt('btn_book', 'Manual Booking')),
            style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white),
            onPressed: () => BookingDialogs.showCreateBooking(context, widget.config, widget.authToken, _baseUrl, _selectedDay, liveServiceMatrices, _fetchDashboardAppointments, _showSnackBar),
          ),
          if (widget.isAdmin) ...[
            const SizedBox(width: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.group_outlined, size: 16),
              label: const Text('Manage Team'),
              onPressed: () {
                setState(() => _drawerTabController.index = 1);
                _scaffoldKey.currentState!.openEndDrawer();
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              setState(() => _drawerTabController.index = 0);
              _scaffoldKey.currentState!.openEndDrawer();
            },
          ),
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: widget.onLogout),
        ],
      ),
      endDrawer: _buildManagementDrawer(themeColor),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: TableCalendar(
                firstDay: DateTime.utc(2026, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (sd, fd) => setState(() { _selectedDay = sd; _focusedDay = fd; }),
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
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          DashboardMetrics(
                            isAdmin: widget.isAdmin,
                            config: widget.config,
                            todayRevenue: todayRevenue,
                            appointments: mockAppointments,
                            selectedDay: _selectedDay,
                            activeScheduleView: _activeScheduleView,
                            onViewChanged: (val) => setState(() => _activeScheduleView = val),
                          ),
                          const SizedBox(height: 24),
                          ScheduleViews(
                            activeView: _activeScheduleView,
                            selectedDay: _selectedDay,
                            appointments: mockAppointments,
                            themeColor: themeColor,
                            onAppointmentUpdated: () => _fetchDashboardAppointments(),
                            onViewDateChanged: (day) => setState(() { _selectedDay = day; _focusedDay = day; }),
                            onUpdateDialogRequested: (app) => BookingDialogs.showUpdateBooking(context, app, widget.authToken, _baseUrl, _showSnackBar, (mutatedList) => setState(() => mockAppointments = mutatedList), mockAppointments),
                          ),
                          const SizedBox(height: 24),
                          ServiceMatrixTable(
                            isAdmin: widget.isAdmin,
                            isLoading: _isServiceLoading,
                            isVisible: _isServiceMatrixVisible,
                            matrices: liveServiceMatrices,
                            onToggleVisibility: () => setState(() => _isServiceMatrixVisible = !_isServiceMatrixVisible),
                            onAddRequested: () => BookingDialogs.showAddServiceMatrix(context, _isServiceLoading, _createServiceMatrixTier),
                            onDeleteRequested: (id) => setState(() => liveServiceMatrices.removeWhere((item) => item['id'] == id)),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
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
              tabs: [
                const Tab(icon: Icon(Icons.tune), text: 'UI Text Config'),
                if (widget.isAdmin) const Tab(icon: Icon(Icons.badge_outlined), text: 'Team Members'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _drawerTabController,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        TextField(controller: _btnBookController, decoration: const InputDecoration(labelText: 'Manual Booking')),
                        TextField(controller: _btnCancelController, decoration: const InputDecoration(labelText: 'Cancel')),
                        TextField(controller: _btnEditController, decoration: const InputDecoration(labelText: 'Reschedule')),
                        TextField(controller: _txtRevenueController, decoration: const InputDecoration(labelText: 'Revenue Metric Title')),
                        const SizedBox(height: 24),
                        ElevatedButton(onPressed: _saveUiTextConfigToDatabase, child: const Text('Save Text Formats')),
                      ],
                    ),
                  ),
                  if (widget.isAdmin) ManageTeamPanel(config: widget.config, authToken: widget.authToken),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}