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

  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  late TabController _drawerTabController;

  // Mock appointments matching database links
  List<Map<String, dynamic>> mockAppointments = [
    {
      'id': 'app-1', 
      'time': '09:00 - 10:30', 
      'petName': 'Max', 
      'breed': 'Golden Retriever', 
      'ownerName': 'Alex Zhang', 
      'service': 'Signature Full Style Grooming', 
      'price': 120.0, 
      'status': 'CONFIRMED'
    },
    {
      'id': 'app-2', 
      'time': '11:00 - 11:30', 
      'petName': 'Cookie', 
      'breed': 'Ragdoll Cat', 
      'ownerName': 'Emma Li', 
      'service': 'Ultrasonic Deep Teeth Cleaning', 
      'price': 50.0, 
      'status': 'CONFIRMED'
    }
  ];

  // 🗂️ Unified Live Catalog State (Shared down into Customer Portal)
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
      'description': 'Advanced calculus removal safely without general sedation techniques. Refreshes oral breath cycles.',
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
              decoration: BoxDecoration(
                color: themeColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(widget.config.logoIcon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Text(
              widget.config.businessName, 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18)
            ),
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
                builder: (_) => CustomerPortalPage(
                  config: widget.config,
                  activeServices: liveServiceMatrices, // Sync state array reference directly down
                )
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
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), 
            onPressed: widget.onLogout
          ),
          const SizedBox(width: 16),
        ],
      ),
      endDrawer: _buildManagementDrawer(themeColor),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetricHeaderSection(),
                  const SizedBox(height: 24),
                  _buildBrandIdentitySection(themeColor),
                  const SizedBox(height: 24),
                  _buildServiceCatalogSection(themeColor), 
                  const SizedBox(height: 24),
                  _buildAppointmentListCard(themeColor),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Operational Outlook', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))
                  ),
                  const SizedBox(height: 16),
                  _buildCalendarCard(themeColor),
                ],
              ),
            ),
          )
        ],
      ),
    );
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: col.withAlpha(20), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: col, size: 24),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBrandIdentitySection(Color col) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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

  Widget _buildServiceCatalogSection(Color col) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Service Matrix Configurator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Manage custom tiered business configurations and rules overrides.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))
                  ],
                ),
                // 🛑 Access Rules Guard: Visible/Accessible only to Admin roles
                if (widget.isAdmin)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_business_outlined, size: 16),
                    label: const Text('Add Service Entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                    ),
                    onPressed: _showAddServiceMatrixDialog,
                  )
              ],
            ),
          ),
          const Divider(height: 1),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade50),
                children: const [
                  Padding(padding: EdgeInsets.all(12), child: Text('Service Identifier / Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Target Tier Set', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Book Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                ]
              ),
              ...liveServiceMatrices.map((matrix) {
                final displayTitle = matrix['title'];
                final String ruleSet = '${matrix['species'] ?? 'All'} • ${matrix['weightTier'] ?? 'Flat Price'}';
                final displayPrice = (matrix['priceCentsAud'] / 100).toStringAsFixed(2);
                
                return TableRow(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12), 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                          Text('Code Slug: ${matrix['slug']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      )
                    ),
                    Padding(padding: const EdgeInsets.all(12), child: Text(ruleSet, style: const TextStyle(fontSize: 13))),
                    Padding(padding: const EdgeInsets.all(12), child: Text('${matrix['durationMinutes']} mins', style: const TextStyle(fontSize: 13))),
                    Padding(padding: const EdgeInsets.all(12), child: Text('\$$displayPrice AUD', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green))),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: widget.isAdmin 
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () => _confirmActionGuard(
                                title: 'Purge Service Definition',
                                body: 'Are you sure you want to completely erase "$displayTitle" from the marketplace array? Customers will instantly lose checkout capabilities.',
                                onConfirm: () {
                                  setState(() => liveServiceMatrices.removeWhere((item) => item['id'] == matrix['id']));
                                  _showSnackBar('🗑️ Service record dropped from live configurations.');
                                }
                              ),
                            )
                          : const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text('Read-Only', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ),
                    )
                  ]
                );
              }),
            ],
          )
        ],
      ),
    );
  }

  void _showAddServiceMatrixDialog() {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final priceCentsCtrl = TextEditingController();
    String selectSpecies = 'Dog';
    String selectWeight = 'MEDIUM';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Provision New Corporate Pricing Matrix Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Global Service Item Name', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: slugCtrl, decoration: const InputDecoration(labelText: 'System Code Slug (e.g., TEETH_CLEAN)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Client Description', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectSpecies,
                          decoration: const InputDecoration(labelText: 'Species Restriction Rule', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'Dog', child: Text('Dog profiles')),
                            DropdownMenuItem(value: 'Cat', child: Text('Cat profiles')),
                          ],
                          onChanged: (v) => setModalState(() => selectSpecies = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectWeight,
                          decoration: const InputDecoration(labelText: 'Weight Matrix Tier', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'SMALL', child: Text('Small Tier')),
                            DropdownMenuItem(value: 'MEDIUM', child: Text('Medium Tier')),
                            DropdownMenuItem(value: 'LARGE', child: Text('Large Tier')),
                            DropdownMenuItem(value: 'FLAT_RATE', child: Text('Flat Price')),
                          ],
                          onChanged: (v) => setModalState(() => selectWeight = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: durationCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (Minutes)', border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: priceCentsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Base Price (Cents AUD)', border: OutlineInputBorder()))),
                    ],
                  )
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel Request')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () {
                if (nameCtrl.text.isEmpty || slugCtrl.text.isEmpty || priceCentsCtrl.text.isEmpty) return;
                setState(() {
                  liveServiceMatrices.add({
                    'id': DateTime.now().millisecondsSinceEpoch,
                    'title': nameCtrl.text,
                    'slug': slugCtrl.text.toUpperCase(),
                    'description': descCtrl.text.isEmpty ? 'Premium automated cluster service plan.' : descCtrl.text,
                    'species': selectSpecies,
                    'weightTier': selectWeight,
                    'durationMinutes': int.tryParse(durationCtrl.text) ?? 45,
                    'priceCentsAud': int.tryParse(priceCentsCtrl.text) ?? 7500,
                    'icon': Icons.star_border_outlined
                  });
                });
                Navigator.pop(context);
                _showSnackBar('🚀 Successfully mapped entry into operational cluster pricing matrix!');
              }, 
              child: const Text('Push Live Config')
            )
          ],
        ),
      ),
    );
  }

  // ✨ FAIL-SAFE PROTECTION SYSTEM: Explicit Double Confirmation Guard
  void _confirmActionGuard({required String title, required String body, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(body, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abort Workflow')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Confirm Execution'),
          )
        ],
      ),
    );
  }

  Widget _buildCalendarCard(Color col) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2026, 1, 1), 
        lastDay: DateTime.utc(2030, 12, 31), 
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat, 
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onFormatChanged: (f) => setState(() => _calendarFormat = f),
        onDaySelected: (sd, fd) => setState(() { _selectedDay = sd; _focusedDay = fd; }),
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(color: col, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: col.withAlpha(70), shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildAppointmentListCard(Color col) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Live Manifest Operations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mockAppointments.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final app = mockAppointments[i];
              final bool isCancelled = app['status'] == 'CANCELLED';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                leading: CircleAvatar(
                  backgroundColor: isCancelled ? Colors.grey.shade100 : col.withAlpha(20),
                  child: Icon(Icons.calendar_today, color: isCancelled ? Colors.grey : col, size: 18),
                ),
                title: Text(
                  '${app['petName']} (${app['breed']})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: isCancelled ? Colors.grey : const Color(0xFF1E293B),
                    decoration: isCancelled ? TextDecoration.lineThrough : null
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '${app['ownerName']} • ${app['service']} • \$${app['price']} AUD',
                    style: TextStyle(color: isCancelled ? Colors.grey : const Color(0xFF64748B), fontSize: 13),
                  ),
                ),
                trailing: isCancelled 
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                        child: const Text('Voided', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF0284C7), size: 20),
                            tooltip: widget.config.getTxt('btn_edit', 'Reschedule Slot'),
                            onPressed: () => _showEditDialog(app),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            tooltip: widget.config.getTxt('btn_cancel', 'Revoke Appointment'),
                            onPressed: () => _confirmActionGuard(
                              title: 'Revoke Appointment Booking',
                              body: 'Are you absolutely sure you want to flag the scheduled app record for "${app['petName']}" as CANCELLED? This change cannot be automatically reversed.',
                              onConfirm: () => setState(() => app['status'] = 'CANCELLED')
                            ),
                          ),
                        ],
                      ),
              );
            },
          ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 💡 Fixed: Corrected alignment assignment syntax
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
              tabs: [
                const Tab(text: 'UI Dictionary'),
                if (widget.isAdmin) const Tab(text: 'Staff Matrix'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _drawerTabController,
                children: [
                  _buildUiDictionaryTab(),
                  if (widget.isAdmin)
                    Container(
                      color: const Color(0xFFF8FAFC),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: ManageTeamPanel(config: widget.config, authToken: widget.authToken),
                      ),
                    ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A), 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: _saveUiTextConfigToDatabase,
              child: const Text('Commit & Cascade Modifications', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInputField(String lbl, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(lbl, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl, 
            decoration: const InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCBD5E1))),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF64748B), width: 1.5)),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)
            )
          )
        ],
      ),
    );
  }

  void _showCreateBookingDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.config.getTxt('btn_book', 'Manual Booking')),
        content: const Column(
          mainAxisSize: MainAxisSize.min, 
          children: [TextField(decoration: InputDecoration(labelText: 'Pet Identity Manifest Tag'))]
        ),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Execute Dispatch'))],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> app) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Re-route Client ${app['petName']}'),
        content: Text(widget.config.getTxt('btn_edit', 'Proceed execution alterations to timeline slots')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dismiss'))],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }
}