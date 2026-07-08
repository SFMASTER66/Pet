import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ScheduleViews extends StatelessWidget {
  final String activeView;
  final DateTime? selectedDay;
  final List<Map<String, dynamic>> appointments;
  final Color themeColor;
  final VoidCallback onAppointmentUpdated;
  final ValueChanged<DateTime> onViewDateChanged;
  final Function(Map<String, dynamic>) onUpdateDialogRequested;

  const ScheduleViews({
    super.key,
    required this.activeView,
    required this.selectedDay,
    required this.appointments,
    required this.themeColor,
    required this.onAppointmentUpdated,
    required this.onViewDateChanged,
    required this.onUpdateDialogRequested,
  });

  @override
  Widget build(BuildContext context) {
    final targetDate = selectedDay ?? DateTime.now();
    final dailyFiltered = appointments.where((app) => isSameDay(app['rawStartTime'], targetDate)).toList();

    if (activeView == 'Daily Timeline Grid') {
      return _buildTimelineGrid(context, dailyFiltered);
    } else if (activeView == 'One Week Grid Summary') {
      return _buildWeeklyGrid(targetDate);
    }
    return _buildListView(dailyFiltered);
  }

  Widget _buildListView(List<Map<String, dynamic>> dailyFiltered) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Schedule Overview', style: TextStyle(fontWeight: FontWeight.bold)),
          dailyFiltered.isEmpty 
            ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No active scheduled instances.')))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dailyFiltered.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, idx) {
                  final app = dailyFiltered[idx];
                  return ListTile(
                    title: Text('${app['petName']} (${app['breed']})'),
                    subtitle: Text('${app['service']} • ${app['time']}'),
                    trailing: Text(app['status']),
                    onTap: () => onUpdateDialogRequested(app),
                  );
                },
              )
        ],
      ),
    );
  }

  Widget _buildTimelineGrid(BuildContext context, List<Map<String, dynamic>> dailyFiltered) {
    final slots = ['08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: slots.map((hourStr) {
          final int hour = int.parse(hourStr.split(':')[0]);
          final matches = dailyFiltered.where((a) => a['rawStartTime'].hour == hour).toList();
          return Row(
            children: [
              Text(hourStr),
              const SizedBox(width: 20),
              Expanded(
                child: matches.isEmpty 
                  ? const Text('Slot Available', style: TextStyle(color: Colors.grey))
                  : Wrap(children: matches.map((m) => ActionChip(label: Text(m['petName']), onPressed: () => onUpdateDialogRequested(m))).toList()),
              )
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeeklyGrid(DateTime targetDate) {
    final DateTime monday = targetDate.subtract(Duration(days: targetDate.weekday - 1));
    return Row(
      children: List.generate(7, (idx) {
        final day = monday.add(Duration(days: idx));
        final count = appointments.where((a) => isSameDay(a['rawStartTime'], day)).length;
        return Expanded(
          child: InkWell(
            onTap: () => onViewDateChanged(day),
            child: Container(
              padding: const EdgeInsets.all(10),
              color: isSameDay(selectedDay, day) ? themeColor.withAlpha(30) : Colors.grey.shade100,
              child: Column(
                children: [
                  Text('${day.day}/${day.month}'),
                  Text('$count Grooms'),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}