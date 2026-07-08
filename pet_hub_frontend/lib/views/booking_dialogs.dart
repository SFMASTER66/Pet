import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/merchant_config.dart';

class BookingDialogs {
  static final List<String> _timePresetSlots = [
    '08:00', '08:15', '08:30', '08:45', '09:00', '09:15', '09:30', '09:45',
    '10:00', '10:15', '10:30', '10:45', '11:00', '11:15', '11:30', '11:45',
    '12:00', '12:15', '12:30', '12:45', '13:00', '13:15', '13:30', '13:45',
    '14:00', '14:15', '14:30', '14:45', '15:00', '15:15', '15:30', '15:45', '16:00'
  ];

  static void showCreateBooking(
    BuildContext context, 
    MerchantConfig config, 
    String token, 
    String baseUrl, 
    DateTime? selectedDay, 
    List<Map<String, dynamic>> matrices,
    VoidCallback onSuccess,
    Function(String) showBar
  ) {
    final dogNameCtrl = TextEditingController();
    final dogBreedCtrl = TextEditingController();
    final ownerNameCtrl = TextEditingController();
    final ownerPhoneCtrl = TextEditingController();
    final ownerEmailCtrl = TextEditingController();
    Map<String, dynamic>? selectedMatrix = matrices.isNotEmpty ? matrices.first : null;
    DateTime bookingDate = selectedDay ?? DateTime.now();
    String bookingTime = '09:00';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Booking'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              children: [
                DropdownButton<Map<String, dynamic>>(
                  value: selectedMatrix,
                  items: matrices.map((m) => DropdownMenuItem(value: m, child: Text(m['name']))).toList(),
                  onChanged: (val) => setDialogState(() => selectedMatrix = val),
                ),
                TextField(controller: dogNameCtrl, decoration: const InputDecoration(labelText: 'Dog Name *')),
                TextField(controller: dogBreedCtrl, decoration: const InputDecoration(labelText: 'Breed *')),
                TextField(controller: ownerNameCtrl, decoration: const InputDecoration(labelText: 'Owner Name *')),
                TextField(
                  controller: ownerPhoneCtrl, 
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Phone (04..) *')
                ),
                TextField(controller: ownerEmailCtrl, decoration: const InputDecoration(labelText: 'Email *')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abort')),
          ElevatedButton(
            onPressed: () async {
              if (dogNameCtrl.text.isEmpty || ownerPhoneCtrl.text.length != 10) {
                showBar('⚠️ Check input rules.');
                return;
              }
              final timeParts = bookingTime.split(':');
              final targetDateTime = DateTime(bookingDate.year, bookingDate.month, bookingDate.day, int.parse(timeParts[0]), int.parse(timeParts[1]));
              
              final res = await http.post(
                Uri.parse('$baseUrl/api/v1/bookings/add'),
                headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                body: jsonEncode({
                  'merchantId': config.merchantId,
                  'bookedById': config.userId,
                  'dogName': dogNameCtrl.text.trim(),
                  'ownerPhone': ownerPhoneCtrl.text.trim(),
                  'ownerEmail': ownerEmailCtrl.text.trim(),
                  'serviceTime': targetDateTime.toIso8601String(),
                }),
              );
              if (res.statusCode == 200 || res.statusCode == 201) {
                Navigator.pop(ctx);
                onSuccess();
              }
            },
            child: const Text('Place Booking'),
          )
        ],
      ),
    );
  }

  static void showUpdateBooking(
    BuildContext context, 
    Map<String, dynamic> app, 
    String token, 
    String baseUrl,
    Function(String) showBar,
    Function(List<Map<String, dynamic>>) onLocalStateMutated,
    List<Map<String, dynamic>> currentAppointments
  ) {
    bool isCheckedIn = app['isCheckedIn'] ?? false;
    String status = app['status'] ?? 'PENDING';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Manage: ${app['petName']}'),
        content: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Checked In'),
                value: isCheckedIn, 
                onChanged: (v) => setModalState(() => isCheckedIn = v)
              ),
              DropdownButton<String>(
                value: status,
                items: ['PENDING', 'PAID', 'COMPLETED', 'CANCELLED'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setModalState(() => status = v!),
              )
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final idx = currentAppointments.indexWhere((element) => element['id'] == app['id']);
              if (idx != -1) {
                currentAppointments[idx]['isCheckedIn'] = isCheckedIn;
                currentAppointments[idx]['status'] = status;
              }
              onLocalStateMutated([...currentAppointments]);
              Navigator.pop(ctx);
              showBar('🚀 Schema mutated successfully.');
            }, 
            child: const Text('Commit Changes')
          )
        ],
      ),
    );
  }

  static void showAddServiceMatrix(BuildContext context, bool isLoading, Function({required String name, required String coatType, required String weightTier, required int duration, required int priceCents}) onConfirm) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Provision Pricing Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Service Name')),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price (\$ AUD)')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final double parsedPrice = double.tryParse(priceCtrl.text) ?? 0.0;
              onConfirm(
                name: nameCtrl.text.trim(),
                coatType: 'SHORT',
                weightTier: 'M',
                duration: 45,
                priceCents: (parsedPrice * 100).round()
              );
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Provision'),
          )
        ],
      ),
    );
  }
}