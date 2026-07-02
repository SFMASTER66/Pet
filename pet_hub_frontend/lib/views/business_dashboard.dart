import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/merchant_config.dart';
import 'customer_portal.dart';
import 'manage_team_panel.dart';

class UnifiedMerchantDashboard extends StatefulWidget {
  final MerchantConfig config;
  final String authToken; 
  final bool isAdmin; // 👈 Explicit control flag passed down from routing security
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

  List<Map<String, dynamic>> mockAppointments = [
    {'id': 'app-1', 'time': '09:00 - 10:30', 'petName': 'Max', 'breed': 'Golden Retriever', 'ownerName': 'Alex Zhang', 'service': 'Full Grooming & Styling Package', 'price': 120.0, 'status': 'CONFIRMED'},
    {'id': 'app-2', 'time': '11:00 - 11:30', 'petName': 'Cookie', 'breed': 'Ragdoll Cat', 'ownerName': 'Emma Li', 'service': 'Ultrasonic Teeth Cleaning', 'price': 50.0, 'status': 'CONFIRMED'}
  ];

  Map<String, dynamic>? selectedAppointmentDetail;

  @override
  void initState() {
    super.initState();
    // 🛠️ DYNAMIC STRUCTURAL TAB COUNT: Staff members only have 1 tab (UI Dictionary), Admins have 2.
    _drawerTabController = TabController(length: widget.isAdmin ? 2 : 1, vsync: this);
    selectedAppointmentDetail = mockAppointments.first;
    _syncControllers();
  }

  void _syncControllers() {
    _btnBookController.text = widget.config.getTxt('btn_book', 'Walk-in Booking');
    _btnCancelController.text = widget.config.getTxt('btn_cancel', 'Cancel Booking');
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
    _showSnackBar('💾 UI Strings pushed to DB and synced across systems globally!');
  }

  double get todayRevenue => mockAppointments.where((app) => app['status'] == 'CONFIRMED').map((app) => app['price'] as double).fold(0, (p, e) => p + e);

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.white, child: Text(widget.config.logoIcon, style: const TextStyle(fontSize: 22))),
            const SizedBox(width: 12),
            Text(widget.config.businessName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.visibility),
            label: const Text('Open Customer View Portal'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerPortalPage(config: widget.config)));
            },
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: Text(widget.config.getTxt('btn_book', 'Manual Booking')),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: _showCreateBookingDialog,
          ),
          
          // 🛑 STAFF RULE: Completely omit the "Manage Team" action button if the user is staff.
          if (widget.isAdmin) ...[
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Manage Team'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(51), 
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () {
                setState(() => _drawerTabController.index = 1); 
                _scaffoldKey.currentState!.openEndDrawer();
              },
            ),
          ],
          
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Configure UI Text'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: themeColor),
            onPressed: () {
              setState(() => _drawerTabController.index = 0); 
              _scaffoldKey.currentState!.openEndDrawer();
            },
          ),
          const SizedBox(width: 4),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: widget.onLogout),
          const SizedBox(width: 16),
        ],
      ),
      
      endDrawer: Drawer(
        width: 460, 
        child: SafeArea(
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Workspace Panel', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                      ],
                    ),
                    TabBar(
                      controller: _drawerTabController,
                      labelColor: themeColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: themeColor,
                      tabs: [
                        const Tab(icon: Icon(Icons.translate), text: 'UI Dictionary'),
                        // 🛑 STAFF RULE: The tab item completely disappears from the layout structure
                        if (widget.isAdmin) const Tab(icon: Icon(Icons.badge_outlined), text: 'Staff Members'),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              Expanded(
                child: TabBarView(
                  controller: _drawerTabController,
                  children: [
                    // Tab Content 1: UI Dictionary Custom Fields
                    Container(
                      padding: const EdgeInsets.all(24),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Modifying items alters customer buttons instantly.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const Divider(height: 30),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildInputField('Booking Action Text Key: btn_book', _btnBookController),
                                  _buildInputField('Cancel Action Text Key: btn_cancel', _btnCancelController),
                                  _buildInputField('Edit Action Text Key: btn_edit', _btnEditController),
                                  _buildInputField('Revenue Title Text Key: txt_revenue', _txtRevenueController),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700, 
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _saveUiTextConfigToDatabase,
                              child: const Text('Save Changes & Sync DB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          )
                        ],
                      ),
                    ),
                    
                    // 🛑 STAFF RULE: The viewport container is blocked structural-wide from compiling into runtime lists
                    if (widget.isAdmin)
                      Container(
                        color: const Color(0xFFF8FAFC),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: ManageTeamPanel(
                            config: widget.config,
                            authToken: widget.authToken,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(children: [
              // 🛑 STAFF RULE: Clear the Financial Data Card completely out of view metric limits
              if (widget.isAdmin) ...[
                _buildMetricCard(widget.config.getTxt('txt_revenue', 'Today Forecast Revenue'), '\$$todayRevenue AUD', Icons.attach_money, Colors.green),
                const SizedBox(width: 20),
              ],
              _buildMetricCard('Total Booked Pets', '${mockAppointments.length} Active', Icons.pets, themeColor),
            ]),
            const SizedBox(height: 20),
            _buildTagsCard(themeColor),
            const SizedBox(height: 20),
            _buildCalendarCard(themeColor),
            const SizedBox(height: 20),
            _buildAppointmentListCard(themeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color col) {
    return Expanded(
      child: Card(
        elevation: 0, color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            CircleAvatar(backgroundColor: col.withAlpha(25), child: Icon(icon, color: col)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ])
          ]),
        ),
      ),
    );
  }

  Widget _buildTagsCard(Color col) {
    return Card(
      elevation: 0, color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const Text('Brand Identity Traits: ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Wrap(spacing: 8, children: widget.config.tags.map((t) => Chip(backgroundColor: col.withAlpha(25), label: Text(t, style: TextStyle(color: col)))).toList())
        ]),
      ),
    );
  }

  Widget _buildCalendarCard(Color col) {
    return Card(
      elevation: 0, color: Colors.white,
      child: TableCalendar(
        firstDay: DateTime.utc(2026, 1, 1), lastDay: DateTime.utc(2030, 12, 31), focusedDay: _focusedDay,
        calendarFormat: _calendarFormat, selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onFormatChanged: (f) => setState(() => _calendarFormat = f),
        onDaySelected: (sd, fd) => setState(() { _selectedDay = sd; _focusedDay = fd; }),
        calendarStyle: CalendarStyle(selectedDecoration: BoxDecoration(color: col, shape: BoxShape.circle)),
      ),
    );
  }

  Widget _buildAppointmentListCard(Color col) {
    return Expanded(
      child: Card(
        elevation: 0, color: Colors.white,
        child: ListView.separated(
          itemCount: mockAppointments.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final app = mockAppointments[i];
            return ListTile(
              leading: Icon(Icons.access_time, color: col),
              title: Text('${app['petName']} (${app['breed']}) - ${app['ownerName']}'),
              subtitle: Text('${app['service']} | \$${app['price']} AUD'),
              trailing: app['status'] == 'CANCELLED' 
                  ? const Text('Cancelled', style: TextStyle(color: Colors.grey))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_calendar, color: Colors.blue),
                          tooltip: widget.config.getTxt('btn_edit', 'Reschedule'),
                          onPressed: () => _showEditDialog(app),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                          tooltip: widget.config.getTxt('btn_cancel', 'Cancel'),
                          onPressed: () => setState(() => app['status'] = 'CANCELLED'),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputField(String lbl, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(lbl, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: ctrl, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)))
      ]),
    );
  }

  void _showCreateBookingDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.config.getTxt('btn_book', 'Manual Booking')),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [TextField(decoration: InputDecoration(labelText: 'Pet Identity Name'))]),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Execute'))],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> app) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reschedule ${app['petName']}'),
        content: Text(widget.config.getTxt('btn_edit', 'Proceed adjustments to timeline slots')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dismiss'))],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }
}