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

  // 🗓️ Permanent Full Month View Configuration for Left Side Panel
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  // 🔄 Right Side Panel Schedule View Modes Selector Switch State
  String _activeScheduleView = 'Daily List View'; 
  final List<String> _scheduleViewOptions = [
    'Daily List View', 
    'Daily Timeline Grid', 
    'One Week Grid Summary'
  ];

  // 👁️ Toggle Variable for Hiding / Showing the Service Matrix Component
  bool _isServiceMatrixVisible = true;

  late TabController _drawerTabController;

  // 🐾 Expanded Appointment Schema holding overlapping/simultaneous bookings
  late List<Map<String, dynamic>> mockAppointments;

  // 🗂️ Unified Live Catalog State
  final List<Map<String, dynamic>> liveServiceMatrices = [
    {
      'id': 1,
      'title': 'Signature Full Style Grooming',
      'slug': 'FULL_GROOM',
      'description': 'Includes specialized bath, complete clipping style, hair treatment, nail file, and ear irrigation care.',
      'species': 'Dog',
      'weightTier': 'LARGE',
      'durationMinutes': 90,
      'priceCentsAud': 12000,
      'icon': Icons.cut_outlined
    },
    {
      'id': 2,
      'title': 'Ultrasonic Deep Teeth Cleaning',
      'slug': 'TEETH_CLEANING',
      'description': 'Advanced calculus removal safely without general sedation techniques.',
      'species': 'Cat',
      'weightTier': 'FLAT_RATE',
      'durationMinutes': 30,
      'priceCentsAud': 5000,
      'icon': Icons.clean_hands_outlined
    },
    {
      'id': 3,
      'title': 'Hydrotherapy Mineral Treatment Bath',
      'slug': 'HYDRO_BATH',
      'description': 'Soothing warm water skin bubble treatment infused with natural essential oil remedies.',
      'species': 'Dog',
      'weightTier': 'MEDIUM',
      'durationMinutes': 45,
      'priceCentsAud': 6500,
      'icon': Icons.waves
    }
  ];

  @override
  void initState() {
    super.initState();
    _drawerTabController = TabController(length: widget.isAdmin ? 2 : 1, vsync: this);
    _syncControllers();
    
    // Configured rich overlapping timeslots to test both Multi-Week and Day Timeline configurations safely
    mockAppointments = [
      {
        'id': 'app-1', 
        'time': '09:00 - 10:30', 
        'weekdayIndex': 1, // Monday
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
        'staffTags': ['High Energy', 'Loyal Customer'],
      },
      {
        'id': 'app-1-simultaneous', 
        'time': '09:00 - 10:30', 
        'weekdayIndex': 1, // Monday
        'petName': 'Bella', 
        'breed': 'Poodle', 
        'ownerName': 'Marcus Aurelius', 
        'ownerEmail': 'marcus@philosophy.io',
        'ownerPhone': '+61 411 222 333',
        'pastMerchantVisitsCount': 8, 
        'service': 'Signature Full Style Grooming', 
        'price': 120.0, 
        'status': 'CONFIRMED',
        'isCheckedIn': false,
        'isDepositPaid': true,
        'isReadyForPickup': false,
        'staffTags': ['Bites when brushed'],
      },
      {
        'id': 'app-2', 
        'time': '11:00 - 11:30', 
        'weekdayIndex': 3, // Wednesday
        'petName': 'Cookie', 
        'breed': 'Chihuahua', 
        'ownerName': 'Emma Li', 
        'ownerEmail': 'emma.li@outlook.com',
        'ownerPhone': '+61 498 765 432',
        'pastMerchantVisitsCount': 2,
        'service': 'Ultrasonic Deep Teeth Cleaning', 
        'price': 50.0, 
        'status': 'CONFIRMED',
        'isCheckedIn': false,
        'isDepositPaid': false,
        'isReadyForPickup': false,
        'staffTags': ['Anxious'],
      },
      {
        'id': 'app-3', 
        'time': '14:00 - 15:00', 
        'weekdayIndex': 5, // Friday
        'petName': 'Rocky', 
        'breed': 'French Bulldog', 
        'ownerName': 'Sam Wilson', 
        'ownerEmail': 'sam.w@example.com',
        'ownerPhone': '+61 423 999 888',
        'pastMerchantVisitsCount': 1,
        'service': 'Hydrotherapy Mineral Treatment Bath', 
        'price': 65.0, 
        'status': 'CONFIRMED',
        'isCheckedIn': false,
        'isDepositPaid': true,
        'isReadyForPickup': true,
        'staffTags': ['Skin Sensitive'],
      },
      {
        'id': 'app-3-parallel', 
        'time': '14:00 - 15:00', 
        'weekdayIndex': 5, // Friday
        'petName': 'Luna', 
        'breed': 'Ragdoll Cat', 
        'ownerName': 'Chloe Bennet', 
        'ownerEmail': 'chloe@marvel.org',
        'ownerPhone': '+61 455 666 777',
        'pastMerchantVisitsCount': 3, 
        'service': 'Ultrasonic Deep Teeth Cleaning', 
        'price': 50.0, 
        'status': 'CONFIRMED',
        'isCheckedIn': true,
        'isDepositPaid': true,
        'isReadyForPickup': true,
        'staffTags': ['Sheds Heavily'],
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

  void _saveUiTextConfigToDatabase() {
    MerchantConfig updated = MerchantConfig(
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
          // 🗓️ LEFT SIDE BAR: Master Calendar Full Month Mode Panel 
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
          
          // 💻 RIGHT PANEL: Controls, Multi-View Schedules, and Bottom Services Matrix Configurator
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
                  
                  // 1️⃣ UPPER SECTION: Routing Engine rendering Daily List vs Daily Timeline vs Weekly Grid dynamically
                  _buildActiveScheduleSection(themeColor),
                  
                  const SizedBox(height: 24),

                  // 2️⃣ LOWER SECTION: Toggleable Service Matrix Configurator (Relocated under schedules)
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
                          Text('Manage custom tiered business offerings. Click header to expand/collapse.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))
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
            Table(
              columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1.5), 3: FlexColumnWidth(1.5), 4: FlexColumnWidth(1.5)},
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade50),
                  children: const [
                    Padding(padding: EdgeInsets.all(12), child: Text('Service Identifier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                    Padding(padding: EdgeInsets.all(12), child: Text('Target Tier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                    Padding(padding: EdgeInsets.all(12), child: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                    Padding(padding: EdgeInsets.all(12), child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                    Padding(padding: EdgeInsets.all(12), child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                  ]
                ),
                ...liveServiceMatrices.map((matrix) {
                  final displayTitle = matrix['title'];
                  final String ruleSet = '${matrix['species'] ?? 'All'} • ${matrix['weightTier'] ?? 'Flat Price'}';
                  return TableRow(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12), 
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))), Text('Code: ${matrix['slug']}', style: const TextStyle(fontSize: 11, color: Colors.grey))])
                      ),
                      Padding(padding: const EdgeInsets.all(12), child: Text(ruleSet, style: const TextStyle(fontSize: 13))),
                      Padding(padding: const EdgeInsets.all(12), child: Text('${matrix['durationMinutes']} mins', style: const TextStyle(fontSize: 13))),
                      Padding(padding: const EdgeInsets.all(12), child: Text('\$${(matrix['priceCentsAud'] / 100).toStringAsFixed(2)} AUD', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green))),
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

  // 📋 OPERATION VIEW A: Daily High-Density List Layout Manifest View
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
            child: Text('Live Manifest Operations (Daily List View Breakdown)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A).withAlpha(230))),
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
                                        child: Text('Merchant Bookings: ${app['pastMerchantVisitsCount']}', style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Service: ${app['service']} • TimeSlot: ${app['time']}', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                                  Text('Owner Profile: ${app['ownerName']} | ${app['ownerEmail']} | ${app['ownerPhone']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _buildStatusBadge(app['isCheckedIn'] ? 'Checked In' : 'Not Checked In', app['isCheckedIn'] ? Colors.green : Colors.amber),
                                      _buildStatusBadge(app['isDepositPaid'] ? 'Deposit Paid' : 'No Deposit', app['isDepositPaid'] ? Colors.blue : Colors.deepOrange),
                                      _buildStatusBadge(app['isReadyForPickup'] ? 'Ready For Pickup' : 'Processing', app['isReadyForPickup'] ? Colors.purple : Colors.blueGrey),
                                      ...(app['staffTags'] as List<String>).map((tag) => _buildStatusBadge('#$tag', Colors.grey, isTag: true)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            if (!isCancelled)
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                                onPressed: () => _confirmActionGuard(
                                  title: 'Revoke Booking',
                                  body: 'Are you sure you want to cancel ${app['petName']}\'s booking?',
                                  onConfirm: () => setState(() => app['status'] = 'CANCELLED')
                                ),
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

  // 🕒 NEW OPERATION VIEW B: Daily Calendar Timeline view broken down hour by hour
  Widget _buildDailyTimelineGrid(Color col) {
    final targetWeekday = _selectedDay?.weekday ?? DateTime.now().weekday;
    final dailyFilteredApps = mockAppointments.where((app) => app['weekdayIndex'] == targetWeekday).toList();

    // Definitions for business operating timeline blocks
    final List<String> operationalHoursSlots = [
      '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00'
    ];

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Calendar Timeline Grid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A).withAlpha(230))),
                const SizedBox(height: 4),
                const Text('Hour-by-hour operational distribution board for the currently selected master day block.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: operationalHoursSlots.length,
            itemBuilder: (context, hourIdx) {
              final currentHourLabel = operationalHoursSlots[hourIdx];

              // Identifies specific items falling inside this particular hour window
              final slotBookings = dailyFilteredApps.where((app) {
                final String timeStr = app['time'] as String;
                return timeStr.startsWith(currentHourLabel.substring(0, 2));
              }).toList();

              return Container(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Label Block Column
                    Container(
                      width: 85,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                      color: const Color(0xFFF8FAFC),
                      child: Text(
                        currentHourLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    // Stacked parallel layout channel area matching appointments
                    Expanded(
                      child: slotBookings.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              child: Text('No operational allocations active', style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontStyle: FontStyle.italic)),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: slotBookings.map((singleApp) {
                                  final bool isAppCancelled = singleApp['status'] == 'CANCELLED';

                                  return InkWell(
                                    onTap: isAppCancelled ? null : () => _showUpdateBookingOptionsDialog(singleApp),
                                    child: Container(
                                      width: 260,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isAppCancelled ? Colors.grey.shade100 : col.withAlpha(15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isAppCancelled ? Colors.grey.shade300 : col.withAlpha(50)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '🐾 ${singleApp['petName']} (${singleApp['breed']})',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isAppCancelled ? Colors.grey : const Color(0xFF0F172A), decoration: isAppCancelled ? TextDecoration.lineThrough : null),
                                                ),
                                              ),
                                              Text('\$${singleApp['price']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Slot: ${singleApp['time']}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                          Text(singleApp['service'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                          const Divider(height: 12),
                                          Row(
                                            children: [
                                              Icon(Icons.check_circle, size: 11, color: singleApp['isCheckedIn'] ? Colors.green : Colors.grey),
                                              const SizedBox(width: 4),
                                              Icon(Icons.monetization_on, size: 11, color: singleApp['isDepositPaid'] ? Colors.blue : Colors.orange),
                                              const SizedBox(width: 4),
                                              Icon(Icons.shopping_bag, size: 11, color: singleApp['isReadyForPickup'] ? Colors.purple : Colors.grey),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  // 📅 OPERATION VIEW C: Complete Comprehensive Weekly Schedule Board Matrix Planner Grid
  Widget _buildWeeklyScheduleGrid(Color col) {
    final List<String> weekDaysLabels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Weekly Micro-Planning Schedule Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A).withAlpha(220))),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, 
            crossAxisSpacing: 8, 
            mainAxisSpacing: 8,
            childAspectRatio: 0.42, 
          ),
          itemCount: 7,
          itemBuilder: (context, dayIndex) {
            final weekdayTarget = dayIndex + 1;
            final matchingApps = mockAppointments.where((app) => app['weekdayIndex'] == weekdayTarget).toList();

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Text(
                      weekDaysLabels[dayIndex],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF334155)),
                    ),
                  ),
                  Expanded(
                    child: matchingApps.isEmpty
                        ? const Center(child: Text('No Entries', style: TextStyle(color: Colors.grey, fontSize: 11)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(6),
                            itemCount: matchingApps.length,
                            itemBuilder: (context, appIdx) {
                              final singleApp = matchingApps[appIdx];
                              final bool isAppCancelled = singleApp['status'] == 'CANCELLED';

                              return InkWell(
                                onTap: isAppCancelled ? null : () => _showUpdateBookingOptionsDialog(singleApp),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isAppCancelled ? Colors.grey.shade100 : col.withAlpha(15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isAppCancelled ? Colors.grey.shade300 : col.withAlpha(50)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '🐾 ${singleApp['petName']}',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isAppCancelled ? Colors.grey : const Color(0xFF0F172A), decoration: isAppCancelled ? TextDecoration.lineThrough : null),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(singleApp['time'], style: const TextStyle(fontSize: 9, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                                      Text(singleApp['service'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.check_circle, size: 10, color: singleApp['isCheckedIn'] ? Colors.green : Colors.grey),
                                          const SizedBox(width: 3),
                                          Icon(Icons.monetization_on, size: 10, color: singleApp['isDepositPaid'] ? Colors.blue : Colors.orange),
                                          const SizedBox(width: 3),
                                          Icon(Icons.shopping_bag, size: 10, color: singleApp['isReadyForPickup'] ? Colors.purple : Colors.grey),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color col, {bool isTag = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: col.withAlpha(24), borderRadius: BorderRadius.circular(4), border: Border.all(color: col.withAlpha(90), width: 0.5)),
      child: Text(text, style: TextStyle(color: col.darken(), fontSize: 10, fontWeight: isTag ? FontWeight.normal : FontWeight.bold)),
    );
  }

  void _showUpdateBookingOptionsDialog(Map<String, dynamic> app) {
    final tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit_calendar_outlined, color: Colors.indigo),
                const SizedBox(width: 8),
                Text('Update Dispatch: ${app['petName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Check-In Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(app['isCheckedIn'] ? 'Arrived at facilities' : 'Pending arrival'),
                      value: app['isCheckedIn'],
                      activeColor: Colors.green,
                      onChanged: (val) {
                        setState(() => app['isCheckedIn'] = val);
                        setModalState(() {});
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Deposit Balance Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(app['isDepositPaid'] ? 'Payment cleared' : 'Outstanding allocation'),
                      value: app['isDepositPaid'],
                      activeColor: Colors.blue,
                      onChanged: (val) {
                        setState(() => app['isDepositPaid'] = val);
                        setModalState(() {});
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Ready for Collection', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(app['isReadyForPickup'] ? 'Ready to pick up' : 'In Service Pipeline'),
                      value: app['isReadyForPickup'],
                      activeColor: Colors.purple,
                      onChanged: (val) {
                        setState(() => app['isReadyForPickup'] = val);
                        setModalState(() {});
                      },
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                      child: Align(alignment: Alignment.centerLeft, child: Text('Internal Staff Tags (Hidden from customer)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 6,
                          children: (app['staffTags'] as List<String>).map((t) => Chip(
                            label: Text(t, style: const TextStyle(fontSize: 11)),
                            onDeleted: () {
                              setState(() => (app['staffTags'] as List<String>).remove(t));
                              setModalState(() {});
                            },
                          )).toList(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: TextField(controller: tagController, decoration: const InputDecoration(hintText: 'Add internal metadata flag', contentPadding: EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder()))),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (tagController.text.trim().isNotEmpty) {
                                setState(() => (app['staffTags'] as List<String>).add(tagController.text.trim()));
                                tagController.clear();
                                setModalState(() {});
                              }
                            },
                            child: const Text('Add'),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save Changes'))],
          );
        }
      ),
    );
  }

  void _showAddServiceMatrixDialog() {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final priceCentsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Provision Pricing Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Service Item Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: slugCtrl, decoration: const InputDecoration(labelText: 'System Slug', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: priceCentsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Base Price (Cents AUD)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty || priceCentsCtrl.text.isEmpty) return;
              setState(() {
                liveServiceMatrices.add({
                  'id': DateTime.now().millisecondsSinceEpoch,
                  'title': nameCtrl.text,
                  'slug': slugCtrl.text.toUpperCase(),
                  'species': 'Dog',
                  'weightTier': 'FLAT_RATE',
                  'durationMinutes': 45,
                  'priceCentsAud': int.tryParse(priceCentsCtrl.text) ?? 7500,
                });
              });
              Navigator.pop(context);
            }, 
            child: const Text('Push')
          )
        ],
      ),
    );
  }

  void _confirmActionGuard({required String title, required String body, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abort')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), onPressed: () { Navigator.pop(ctx); onConfirm(); }, child: const Text('Confirm')),
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
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Enterprise Console', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                ],
              ),
            ),
            TabBar(
              controller: _drawerTabController,
              labelColor: themeColor,
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: themeColor,
              tabs: [const Tab(text: 'UI Dictionary'), if (widget.isAdmin) const Tab(text: 'Staff Matrix')],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _drawerTabController,
                children: [
                  _buildUiDictionaryTab(),
                  if (widget.isAdmin) Container(color: const Color(0xFFF8FAFC), child: SingleChildScrollView(padding: const EdgeInsets.all(24.0), child: ManageTeamPanel(config: widget.config, authToken: widget.authToken))),
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
      color: Colors.white,
      child: Column(
        children: [
          _buildInputField('Booking Action Matrix Key (btn_book)', _btnBookController),
          _buildInputField('Cancellation Dynamic Matrix Key (btn_cancel)', _btnCancelController),
          _buildInputField('Modification Workflow Reference Key (btn_edit)', _btnEditController),
          _buildInputField('Financial Manifest Header Key (txt_revenue)', _txtRevenueController),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: _saveUiTextConfigToDatabase,
              child: const Text('Commit modifications', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInputField(String lbl, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(lbl, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        TextField(controller: ctrl, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)))
      ]),
    );
  }

  void _showCreateBookingDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.config.getTxt('btn_book', 'Manual Booking')),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [TextField(decoration: InputDecoration(labelText: 'Pet Identity Manifest Tag'))]),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Execute Dispatch'))],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }
}

extension ColorDarken on Color {
  Color darken([double amount = .3]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}