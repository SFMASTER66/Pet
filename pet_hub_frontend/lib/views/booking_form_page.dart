import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/merchant_config.dart';

class BookingFormPage extends StatefulWidget {
  final String serviceName;
  final List<Map<String, dynamic>> variantsMatrix;
  final Color themeColor;
  final MerchantConfig config;

  const BookingFormPage({
    super.key,
    required this.serviceName,
    required this.variantsMatrix,
    required this.themeColor,
    required this.config,
  });

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Owner Form Controllers
  final _ownerNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();

  // Dog Form Controllers & Selections
  final _dogNameCtrl = TextEditingController();
  final _dogBreedCtrl = TextEditingController();
  final _dogTagsCtrl = TextEditingController();
  
  DateTime? _selectedDate;
  String? _selectedTimeSlot; 
  String? _selectedSex;
  String? _selectedDesexed;
  DateTime? _dogDob;

  // Pricing Matrix Selection Elements (Driven exclusively by DB records)
  String? _selectedWeightTier;
  String? _selectedCoatType;

  // Predefined salon operational appointment time choices
  final List<String> _availableTimeSlots = [
    '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM',
    '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM',
    '04:00 PM', '05:00 PM'
  ];

  // Dynamically pull weight tiers that exist in the DB records[cite: 4]
  List<String> _getAvailableWeightTiers() {
    return widget.variantsMatrix
        .map((v) => (v['weightTier'] ?? '').toString())
        .where((w) => w.isNotEmpty)
        .toSet()
        .toList();
  }

  // Dynamically pull coat types that exist in the DB records[cite: 4]
  List<String> _getAvailableCoatTypes() {
    return widget.variantsMatrix
        .map((v) => (v['coatType'] ?? '').toString())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
  }

  Map<String, dynamic>? _lookupMatchedVariant() {
    if (_selectedWeightTier == null || _selectedCoatType == null) return null;
    
    try {
      return widget.variantsMatrix.firstWhere((variant) {
        final vWeight = (variant['weightTier'] ?? '').toString().toUpperCase();
        final vCoat = (variant['coatType'] ?? '').toString().toUpperCase();
        return vWeight == _selectedWeightTier!.toUpperCase() && vCoat == _selectedCoatType!.toUpperCase();
      });
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    _dogNameCtrl.dispose();
    _dogBreedCtrl.dispose();
    _dogTagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBookingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickDogDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 7300)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dogDob = picked);
    }
  }

  void _submitBooking() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTimeSlot == null || _dogDob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill out booking date, time dropdown, and dog birthday.')),
        );
        return;
      }

      final matchedRecord = _lookupMatchedVariant();
      final double cleanPrice = matchedRecord != null 
          ? ((matchedRecord['priceCentsAud'] ?? matchedRecord['priceCents'] ?? 0) / 100) 
          : 0.00;

      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Reservation Logged'),
            ],
          ),
          content: Text(
            'Successfully registered appointment for ${_dogNameCtrl.text}.\n'
            'Selected Plan: ${widget.serviceName}\n'
            'Scheduled Time: $_selectedTimeSlot\n'
            'Calculated Price: \$${cleanPrice.toStringAsFixed(2)} AUD\n'
            'Waiting for store merchant approval.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Acknowledged'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final weightTiers = _getAvailableWeightTiers();
    final coatTypes = _getAvailableCoatTypes();
    final matchedVariant = _lookupMatchedVariant();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.serviceName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  _buildSectionHeader('1. Pricing Matrix Factors'),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Dog Weight Tier *', border: OutlineInputBorder()),
                    value: _selectedWeightTier,
                    items: weightTiers.map((t) {
                      return DropdownMenuItem<String>(value: t, child: Text(t));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedWeightTier = val),
                    validator: (v) => v == null ? 'Weight Tier is required' : null,
                  ),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Coat Category *', border: OutlineInputBorder()),
                    value: _selectedCoatType,
                    items: coatTypes.map((c) {
                      return DropdownMenuItem<String>(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCoatType = val),
                    validator: (v) => v == null ? 'Coat Category is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Displays Duration and Pricing together when a complete matrix match occurs[cite: 4]
                  if (matchedVariant != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: widget.themeColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: widget.themeColor, width: 1)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Est. Duration', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                              Text('${matchedVariant['durationMinutes'] ?? 0} Mins', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Matrix Base Fee', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                              Text(
                                '\$${((matchedVariant['priceCentsAud'] ?? matchedVariant['priceCents'] ?? 0) / 100).toStringAsFixed(2)} AUD', 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.themeColor)
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildSectionHeader('2. Appointment Schedule Time'),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      alignment: Alignment.centerLeft,
                      side: BorderSide(color: Colors.grey.shade400)
                    ),
                    onPressed: _pickBookingDate,
                    icon: const Icon(Icons.calendar_month, size: 20),
                    label: Text(
                      _selectedDate == null 
                          ? 'Select Appointment Date *' 
                          : 'Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Appointment Time *', 
                      prefixIcon: Icon(Icons.access_time, size: 20),
                      border: OutlineInputBorder()
                    ),
                    value: _selectedTimeSlot,
                    items: _availableTimeSlots.map((timeSlot) {
                      return DropdownMenuItem<String>(value: timeSlot, child: Text(timeSlot));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedTimeSlot = val),
                    validator: (v) => v == null ? 'Please choose an operational time slot' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildSectionHeader('3. Owner Contact Profile Details'),
                  TextFormField(
                    controller: _ownerNameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Owner Name *', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Owner Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ownerEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email Address *', border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email Address is required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Enter valid email formatting';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // CHANGED: Limits input length to 10 digits and strictly enforces standard Australian phone length
                  TextFormField(
                    controller: _ownerPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Australian Contact Number *', 
                      hintText: 'e.g. 0412345678', 
                      border: OutlineInputBorder(),
                      counterText: "", // Hides the default counter string UI
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Contact details required';
                      if (v.length < 8 || v.length > 10) return 'Enter a valid Australian number (max 10 digits)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildSectionHeader('4. Companion Dog Information'),
                  TextFormField(
                    controller: _dogNameCtrl,
                    decoration: const InputDecoration(labelText: 'Dog Name *', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Dog Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54), 
                      alignment: Alignment.centerLeft,
                      side: BorderSide(color: Colors.grey.shade400)
                    ),
                    onPressed: _pickDogDob,
                    icon: const Icon(Icons.cake, size: 18),
                    label: Text(
                      _dogDob == null 
                          ? 'Dog Date of Birth *' 
                          : 'DOB: ${_dogDob!.day}/${_dogDob!.month}/${_dogDob!.year}',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Biological Sex *', border: OutlineInputBorder()),
                    value: _selectedSex,
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female'))
                    ],
                    onChanged: (val) => setState(() => _selectedSex = val),
                    validator: (v) => v == null ? 'Required Field' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dogBreedCtrl,
                    decoration: const InputDecoration(labelText: 'Dog Breed Category *', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Breed specification required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Desexed Status *', border: OutlineInputBorder()),
                    value: _selectedDesexed,
                    items: const [
                      DropdownMenuItem(value: 'Yes', child: Text('Yes (Neutered / Spayed)')),
                      DropdownMenuItem(value: 'No', child: Text('No (Intact)'))
                    ],
                    onChanged: (val) => setState(() => _selectedDesexed = val),
                    validator: (v) => v == null ? 'Required Field' : null,
                  ),
                  const SizedBox(height: 12),
                  
                  // CHANGED: Form field is no longer marked with an asterisk (*) and its validator is removed (Optional field)
                  TextFormField(
                    controller: _dogTagsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Special Medical / Behavior Tags', 
                      hintText: 'e.g. None, Aggressive, Sensitive Skin',
                      border: OutlineInputBorder()
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4, offset: const Offset(0, -2))],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitBooking,
                  child: const Text('Confirm Booking Appointment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String headingText) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10, top: 8),
      child: Text(
        headingText,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }
}