import 'dart:convert';
import 'dart:io' show Platform; 
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/merchant_config.dart';
import 'customer_portal.dart';
import 'manage_team_panel.dart';

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

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    return Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }

  late TabController _drawerTabController;
  late List<Map<String, dynamic>> mockAppointments;

  // Moved from static property to component reactive state list
  List<Map<String, dynamic>> liveServiceMatrices = [];

  @override
  void initState() {
    super.initState();
    _drawerTabController = TabController(length: widget.isAdmin ? 2 : 1, vsync: this);
    _syncControllers();
    _fetchServiceMatrices(); // Fetch live configurations from backend database clusters
    
    mockAppointments = [
      {
        'id': 'app-1', 
        'time': '09:00 - 10:30', 
        'weekdayIndex': 1, 
        'petName': 'Max', 
        'breed': 'Golden Retriever', 
        'ownerName': 'Alex Zhang', 
        'ownerEmail': 'alex.zhang@example.com',
        'ownerPhone': '+61 412 345 678',
        'pastMerchantVisitsCount': 4, 
        'service': 'Signature Full Style Grooming', 
        'price': 120.0, 
        'status': 'CONFIRMED',
        'isCheckedIn': true,
        'isDepositPaid': true,
        'isReadyForPickup': false,
        'staffTags': ['High Energy'],
      }
    ];
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

  // Fetch matrix records live from backend routes
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

  void _saveUiTextConfigToDatabase() {
    MerchantConfig updated = MerchantConfig(
      merchantId: widget.config.merchantId,
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
        // Fetch fresh up-to-date data directly from database to guarantee synchronization match
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

  double get todayRevenue => mockAppointments
      .where((app) => app['status'] == 'CONFIRMED')
      .map((app) => app['price'] as double)
      .fold(0, (p, e) => p + e);

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
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (_) => CustomerPortalPage(config: widget.config, activeServices: liveServiceMatrices)
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
              icon: const Icon(Icons.group_outlined, size: 16),
              label: const Text('Manage Team'),
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
            child: SingleChildScrollView(
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
    return Row(
      children: [
        if (widget.isAdmin) ...[
          _buildMetricCard(widget.config.getTxt('txt_revenue', 'Today Forecast Revenue'), '\$$todayRevenue AUD', Icons.payments_outlined, Colors.green),
          const SizedBox(width: 16),
        ],
        _buildMetricCard('Total Booked Pets', '${mockAppointments.length} Active Profiles', Icons.pets_outlined, Colors.indigo),
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
                      Icon(
                        _isServiceMatrixVisible ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                        color: const Color(0xFF475569),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Service Matrix Configurator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          Text('Manage custom tiered business offerings.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))
                        ],
                      ),
                    ],
                  ),
                  if (widget.isAdmin && _isServiceMatrixVisible)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_business_outlined, size: 16),
                      label: const Text('Add Entry'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                      onPressed: _showAddServiceMatrixDialog,
                    )
                ],
              ),
            ),
          ),
          if (_isServiceMatrixVisible) ...[
            const Divider(height: 1),
            _isServiceLoading && liveServiceMatrices.isEmpty
                ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                : Table(
                    columnWidths: const {0: FlexColumnWidth(3.5), 1: FlexColumnWidth(2.5), 2: FlexColumnWidth(1.2), 3: FlexColumnWidth(1.3), 4: FlexColumnWidth(1)},
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade50),
                        children: const [
                          Padding(padding: EdgeInsets.all(12), child: Text('Service Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                          Padding(padding: EdgeInsets.all(12), child: Text('Target Coat / Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                          Padding(padding: EdgeInsets.all(12), child: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                          Padding(padding: EdgeInsets.all(12), child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                          Padding(padding: EdgeInsets.all(12), child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                        ]
                      ),
                      ...liveServiceMatrices.map((matrix) {
                        final displayTitle = matrix['name'] ?? 'Unknown Service';
                        final String ruleSet = 'Coat: ${matrix['coatType'] ?? 'ANY'} • Size: ${matrix['weightTier'] ?? 'ANY'}';
                        return TableRow(
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12), 
                              child: Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))
                            ),
                            Padding(padding: const EdgeInsets.all(12), child: Text(ruleSet, style: const TextStyle(fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(12), child: Text('${matrix['durationMinutes']} mins', style: const TextStyle(fontSize: 13))),
                            Padding(padding: const EdgeInsets.all(12), child: Text('\$${((matrix['priceCentsAud'] ?? 0) / 100).toStringAsFixed(2)} AUD', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green))),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: widget.isAdmin 
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                      onPressed: () => _confirmActionGuard(
                                        title: 'Purge Service Definition',
                                        body: 'Are you sure you want to completely erase "$displayTitle"?',
                                        onConfirm: () => setState(() => liveServiceMatrices.removeWhere((item) => item['id'] == matrix['id']))
                                      ),
                                    )
                                  : const Padding(padding: EdgeInsets.all(12.0), child: Text('Read-Only', style: TextStyle(color: Colors.grey, fontSize: 12))),
                            )
                          ]
                        );
                      }),
                    ],
                  )
          ]
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
        onDaySelected: (sd, fd) => setState(() { _selectedDay = sd; _focusedDay = fd; }),
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, leftChevronIcon: Icon(Icons.chevron_left, size: 20), rightChevronIcon: Icon(Icons.chevron_right, size: 20)),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(color: col, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: col.withAlpha(70), shape: BoxShape.circle),
          outsideDaysVisible: false,
        ),
      ),
    );
  }

  Widget _buildDailyAppointmentListCard(Color col) {
    final targetWeekday = _selectedDay?.weekday ?? DateTime.now().weekday;
    final dailyFilteredApps = mockAppointments.where((app) => app['weekdayIndex'] == targetWeekday).toList();

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('Live Manifest Operations (Daily List View)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A).withAlpha(230))),
          ),
          const Divider(height: 1),
          dailyFilteredApps.isEmpty
              ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No bookings recorded for this calendar day target.', style: TextStyle(color: Colors.grey))))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dailyFilteredApps.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final app = dailyFilteredApps[i];
                    final bool isCancelled = app['status'] == 'CANCELLED';

                    return InkWell(
                      onTap: isCancelled ? null : () => _showUpdateBookingOptionsDialog(app),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isCancelled ? Colors.grey.shade100 : col.withAlpha(20),
                              child: Icon(Icons.pets, color: isCancelled ? Colors.grey : col, size: 18),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${app['petName']} (${app['breed']})',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: isCancelled ? Colors.grey : const Color(0xFF1E293B), decoration: isCancelled ? TextDecoration.lineThrough : null),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                        child: Text('Visits: ${app['pastMerchantVisitsCount']}', style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Service: ${app['service']} • TimeSlot: ${app['time']}', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _buildStatusBadge(app['isCheckedIn'] ? 'Checked In' : 'Not Checked In', app['isCheckedIn'] ? Colors.green : Colors.amber),
                                      _buildStatusBadge(app['isDepositPaid'] ? 'Deposit Paid' : 'No Deposit', app['isDepositPaid'] ? Colors.blue : Colors.deepOrange),
                                      _buildStatusBadge(app['isReadyForPickup'] ? 'Ready' : 'Processing', app['isReadyForPickup'] ? Colors.purple : Colors.blueGrey),
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
    final targetWeekday = _selectedDay?.weekday ?? DateTime.now().weekday;
    final dailyFilteredApps = mockAppointments.where((app) => app['weekdayIndex'] == targetWeekday).toList();
    final List<String> operationalHoursSlots = ['09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00'];

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: operationalHoursSlots.length,
        itemBuilder: (context, hourIdx) {
          final currentHourLabel = operationalHoursSlots[hourIdx];
          final slotBookings = dailyFilteredApps.where((app) => (app['time'] as String).startsWith(currentHourLabel.substring(0, 2))).toList();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 85,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                color: const Color(0xFFF8FAFC),
                child: Text(currentHourLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
              ),
              Expanded(
                child: slotBookings.isEmpty
                    ? Padding(padding: const EdgeInsets.all(20), child: Text('No operational allocations active', style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontStyle: FontStyle.italic)))
                    : Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Wrap(
                          spacing: 10,
                          children: slotBookings.map((singleApp) => Container(
                            width: 260,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: col.withAlpha(15), borderRadius: BorderRadius.circular(8)),
                            child: Text('🐾 ${singleApp['petName']} - ${singleApp['service']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          )).toList(),
                        ),
                      ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeeklyScheduleGrid(Color col) {
    final List<String> weekDaysLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 6, childAspectRatio: 0.5),
      itemCount: 7,
      itemBuilder: (context, dayIndex) {
        final weekdayTarget = dayIndex + 1;
        final matchingApps = mockAppointments.where((app) => app['weekdayIndex'] == weekdayTarget).toList();
        return Container(
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Container(padding: const EdgeInsets.all(6), color: const Color(0xFFF8FAFC), child: Center(child: Text(weekDaysLabels[dayIndex], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text('${matchingApps.length} Apps', style: const TextStyle(fontSize: 10, color: Colors.grey)))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String text, Color col, {bool isTag = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: col.withAlpha(24), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: col.darken(), fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showUpdateBookingOptionsDialog(Map<String, dynamic> app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Dispatch: ${app['petName']}'),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
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
                      decoration: const InputDecoration(
                        labelText: 'Service Name (e.g., Premium Full Groom)', 
                        border: OutlineInputBorder()
                      )
                    ),
                    const SizedBox(height: 20),
                    
                    const Text('Target Coat Type Specification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(selectedBackgroundColor: const Color(0xFF0F172A), selectedForegroundColor: Colors.white),
                        segments: coatOptions.map((c) => ButtonSegment<String>(value: c, label: Text(c, style: const TextStyle(fontSize: 10)))).toList(),
                        selected: {selectedCoat},
                        onSelectionChanged: (val) => setModalState(() => selectedCoat = val.first),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Target Breed Size Classification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(selectedBackgroundColor: const Color(0xFF0F172A), selectedForegroundColor: Colors.white),
                        segments: sizeOptions.map((s) => ButtonSegment<String>(value: s, label: Text(s, style: const TextStyle(fontSize: 11)))).toList(),
                        selected: {selectedSize},
                        onSelectionChanged: (val) => setModalState(() => selectedSize = val.first),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Maximum Duration Allocation Block', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: durationOptions.map((d) {
                          final bool isSelected = selectedDuration == d;
                          String label = '$d mins';
                          if (d == 60) label = '1 hr';
                          if (d == 120) label = '2 hrs';
                          
                          return ChoiceChip(
                            label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : const Color(0xFF0F172A))),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0F172A),
                            backgroundColor: Colors.grey.shade100,
                            showCheckmark: false,
                            onSelected: (bool selected) {
                              if (selected) {
                                setModalState(() => selectedDuration = d);
                              }
                            },
                          );
                        }).toList(),
                      ),
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
                onPressed: _isServiceLoading 
                    ? null 
                    : () async {
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
                child: _isServiceLoading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Provision'),
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
          ElevatedButton(onPressed: () { Navigator.pop(ctx); onConfirm(); }, child: const Text('Confirm')),
        ],
      ),
    );
  }

  Widget _buildManagementDrawer(Color themeColor) {
    return Drawer(
      width: 460, 
      child: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _drawerTabController,
              tabs: [const Tab(text: 'UI Dictionary'), if (widget.isAdmin) const Tab(text: 'Staff Matrix')],
            ),
            Expanded(
              child: TabBarView(
                controller: _drawerTabController,
                children: [
                  _buildUiDictionaryTab(),
                  if (widget.isAdmin) Container(child: ManageTeamPanel(config: widget.config, authToken: widget.authToken)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUiDictionaryTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildInputField('Booking Action Matrix Key (btn_book)', _btnBookController),
          ElevatedButton(onPressed: _saveUiTextConfigToDatabase, child: const Text('Commit modifications'))
        ],
      ),
    );
  }

  Widget _buildInputField(String lbl, TextEditingController ctrl) {
    return TextField(controller: ctrl, decoration: InputDecoration(labelText: lbl));
  }

  void _showCreateBookingDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create'),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }
}

extension ColorDarken on Color {
  Color darken([double amount = .3]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}