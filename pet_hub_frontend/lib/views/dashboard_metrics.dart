import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/merchant_config.dart';

class DashboardMetrics extends StatelessWidget {
  final bool isAdmin;
  final MerchantConfig config;
  final double todayRevenue;
  final List<Map<String, dynamic>> appointments;
  final DateTime? selectedDay;
  final String activeScheduleView;
  final ValueChanged<String> onViewChanged;

  const DashboardMetrics({
    super.key,
    required this.isAdmin,
    required this.config,
    required this.todayRevenue,
    required this.appointments,
    required this.selectedDay,
    required this.activeScheduleView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final targetDate = selectedDay ?? DateTime.now();
    final targetedCount = appointments.where((app) => isSameDay(app['rawStartTime'], targetDate)).length;
    final themeColor = config.primaryColor;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (isAdmin) ...[
                    _buildCard(config.getTxt('txt_revenue', 'Today Forecast Revenue'), '\$${todayRevenue.toStringAsFixed(2)} AUD', Icons.payments_outlined, Colors.green),
                    const SizedBox(width: 16),
                  ],
                  _buildCard('Total Booked Pets', '$targetedCount Active Profiles', Icons.pets_outlined, Colors.indigo),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: activeScheduleView,
                  items: ['Daily List View', 'Daily Timeline Grid', 'One Week Grid Summary'].map((val) {
                    return DropdownMenuItem<String>(value: val, child: Text(val));
                  }).toList(),
                  onChanged: (newVal) => onViewChanged(newVal!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              const Text('Traits: ', style: TextStyle(fontWeight: FontWeight.w600)),
              Wrap(
                spacing: 8,
                children: config.tags.map((t) => Chip(label: Text(t, style: TextStyle(color: themeColor)))).toList(),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildCard(String title, String val, IconData icon, Color col) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), color: col.withAlpha(20), child: Icon(icon, color: col)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}