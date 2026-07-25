import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/merchant_config.dart';

class BookingFormPage extends StatefulWidget {
  final String serviceName;
  final List<Map<String, dynamic>> variantsMatrix;
  final Color themeColor;
  final MerchantConfig config;
  final String baseUrl; // Added to standardise network domains with customer_info_panel.dart

  const BookingFormPage({
    super.key,
    required this.serviceName,
    required this.variantsMatrix,
    required this.themeColor,
    required this.config,
    required this.baseUrl, // Ingest URL dynamically
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
  final _dogWeightCtrl = TextEditingController(); // Added Dog Weight Controller
  final _dogTagsCtrl = TextEditingController();
  
  DateTime? _selectedDate;
  String? _selectedTimeSlot; 
  String? _selectedSex;
  String? _selectedDesexed;
  DateTime? _dogDob;

  // Pricing Matrix Selection Elements
  String? _selectedWeightTier;
  String? _selectedCoatType;

  // Live operational hours fetched from the backend API database records
  List<dynamic> _merchantHours = [];
  List<String> _dynamicAvailableSlots = [];
  bool _isLoadingHours = true;
  bool _isDayClosed = false; // Track if the selected date falls on a closed business day
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLiveOperationalHours();
  }

  // Live backend database fetch execution
  Future<void> _fetchLiveOperationalHours() async {
    if (!mounted) return;
    setState(() {
      _isLoadingHours = true;
      _errorMessage = null;
    });

    // Safeguard check: If no date is selected yet (e.g., during initState), 
    // we drop down into a resting state until the user picks a date.
    if (_selectedDate == null) {
      setState(() {
        _isLoadingHours = false;
        _dynamicAvailableSlots = [];
        _selectedTimeSlot = null;
      });
      return;
    }

    try {
      // 1. Format the selected date to YYYY-MM-DD string required by the backend
      final String formattedDate = "${_selectedDate!.year}-"
          "${_selectedDate!.month.toString().padLeft(2, '0')}-"
          "${_selectedDate!.day.toString().padLeft(2, '0')}";
      
      // 2. Dynamic duration value (Fallback to 60 if your state/matrix selection isn't loaded yet)
      final matchedVariant = _lookupMatchedVariant();
      final int durationMinutes = matchedVariant?['durationMinutes'] ?? 60;

      // 3. Updated URL targeting the new bookings slots endpoint with query parameters
      final String targetUrl = '${widget.baseUrl}/api/v1/bookings/available-slots'
          '?merchantId=${widget.config.merchantId}'
          '&date=$formattedDate'
          '&duration=$durationMinutes';
      
      final response = await http.get(
        Uri.parse(targetUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> parsedBody = json.decode(response.body);
        if (parsedBody['success'] == true && parsedBody['data'] is List) {
          final List<dynamic> backendSlots = parsedBody['data'];

          setState(() {
            if (backendSlots.isNotEmpty) {
              _isDayClosed = false;
              
              // 4. Map the 24h backend slots (e.g., "14:30") into the "02:30 PM" UI display format
              _dynamicAvailableSlots = backendSlots.map<String>((slot) {
                final parts = slot.toString().split(':');
                final int hour = int.parse(parts[0]);
                final String minute = parts[1]; // Dynamically preserves :00 or :30 from backend
                
                final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                final String amPm = hour >= 12 ? 'PM' : 'AM';
                final String paddedHour = displayHour.toString().padLeft(2, '0');
                
                return '$paddedHour:$minute $amPm';
              }).toList();
            } else {
              // If no slots are returned, the merchant is either closed or completely fully booked
              _isDayClosed = true;
              _dynamicAvailableSlots = [];
            }

            // Assign initial default selection value safely
            if (_dynamicAvailableSlots.isNotEmpty) {
              _selectedTimeSlot = _dynamicAvailableSlots.first;
            } else {
              _selectedTimeSlot = _isDayClosed ? "SHOP_CLOSED" : null;
            }
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to download updated business operating hours from servers.';
          _dynamicAvailableSlots = [];
          _selectedTimeSlot = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Network connection failed: Unable to fetch live scheduling rules.';
        _dynamicAvailableSlots = [];
        _selectedTimeSlot = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHours = false;
        });
      }
    }
  }

  List<String> _getAvailableWeightTiers() {
    return widget.variantsMatrix
        .map((v) => (v['weightTier'] ?? '').toString())
        .where((w) => w.isNotEmpty)
        .toSet()
        .toList();
  }

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
    _dogWeightCtrl.dispose(); // Clean up weight controller
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
      // Trigger live updates directly using your updated async fetch logic
      _fetchLiveOperationalHours();
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

  // =========================================================================
  // Async HTTP Booking Submission aligned with UnifiedMerchantDashboard
  // =========================================================================
  Future<void> _submitBooking() async {
    if (_formKey.currentState!.validate()) {
      // Check 1: Booking Date
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an appointment date.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Check 2: Time Slot / Closed Day
      if (_selectedTimeSlot == null || _selectedTimeSlot == "SHOP_CLOSED") {
        final String message = _selectedTimeSlot == "SHOP_CLOSED"
            ? 'The store is closed on the selected date. Please pick another day.'
            : 'Please select a valid appointment time slot.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Check 3: Dog Date of Birth
      if (_dogDob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your dog\'s date of birth.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final matchedRecord = _lookupMatchedVariant();

      // Parse 12h display time (e.g. "02:30 PM") into 24h DateTime values
      final parts = _selectedTimeSlot!.split(' '); // ["02:30", "PM"]
      final timeParts = parts[0].split(':');        // ["02", "30"]
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final String amPm = parts.length > 1 ? parts[1] : 'AM';

      if (amPm == 'PM' && hour < 12) {
        hour += 12;
      } else if (amPm == 'AM' && hour == 12) {
        hour = 0;
      }

      final targetDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        hour,
        minute,
      );

      final payload = {
        'merchantId': widget.config.merchantId,
        'bookedById': widget.config.userId,
        'servicePricingMatrixId': matchedRecord?['id'],
        'dogName': _dogNameCtrl.text.trim(),
        'dogBreed': _dogBreedCtrl.text.trim(),
        'dogWeight': double.tryParse(_dogWeightCtrl.text.trim()) ?? 0.0, // Included dog weight in payload
        'dogGender': (_selectedSex ?? 'MALE').toUpperCase(),
        'isDesexed': _selectedDesexed == 'Yes',
        'dogDob': _dogDob!.toIso8601String(),
        'ownerName': _ownerNameCtrl.text.trim(),
        'ownerPhone': _ownerPhoneCtrl.text.trim(),
        'ownerEmail': _ownerEmailCtrl.text.trim(),
        'serviceTime': targetDateTime.toIso8601String(),
        'groomerId': null,
        'note': _dogTagsCtrl.text.trim(),
      };

      try {
        final response = await http.post(
          Uri.parse('${widget.baseUrl}/api/v1/bookings/add'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        );

        final responseData = jsonDecode(response.body);
        if (!mounted) return;

        if (response.statusCode == 200 || response.statusCode == 201) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚀 Administrative appointment successfully recorded.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Submission Rejected: ${responseData['message'] ?? 'Check input parameters.'}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error: Could not connect to target administrative cluster route.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
      body: _buildPageBody(weightTiers, coatTypes, matchedVariant),
    );
  }

  Widget _buildPageBody(List<String> weightTiers, List<String> coatTypes, Map<String, dynamic>? matchedVariant) {
    if (_isLoadingHours) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchLiveOperationalHours,
                child: const Text('Retry Connection'),
              )
            ],
          ),
        ),
      );
    }

    return Form(
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
                  onChanged: (val) {
                    setState(() => _selectedWeightTier = val);
                    if (_selectedDate != null) _fetchLiveOperationalHours();
                  },
                  validator: (v) => v == null ? 'Weight Tier is required' : null,
                ),
                const SizedBox(height: 12),
                
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Coat Category *', border: OutlineInputBorder()),
                  value: _selectedCoatType,
                  items: coatTypes.map((c) {
                    return DropdownMenuItem<String>(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedCoatType = val);
                    if (_selectedDate != null) _fetchLiveOperationalHours();
                  },
                  validator: (v) => v == null ? 'Coat Category is required' : null,
                ),
                const SizedBox(height: 16),

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
                  key: ValueKey('${_dynamicAvailableSlots.length}_${_isDayClosed}_$_selectedTimeSlot'),
                  decoration: const InputDecoration(
                    labelText: 'Select Appointment Time *', 
                    prefixIcon: Icon(Icons.access_time, size: 20),
                    border: OutlineInputBorder(),
                    errorStyle: TextStyle(color: Colors.redAccent),
                  ),
                  value: _selectedTimeSlot,
                  items: _isDayClosed
                      ? [
                          const DropdownMenuItem<String>(
                            value: 'SHOP_CLOSED',
                            enabled: false,
                            child: Text(
                              'Closed on this day',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ]
                      : (_dynamicAvailableSlots.isEmpty
                          ? [
                              DropdownMenuItem<String>(
                                value: null,
                                enabled: false,
                                child: Text(
                                  _selectedDate == null ? 'Please select a date first' : 'No available slots found',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              )
                            ]
                          : _dynamicAvailableSlots.map((timeSlot) {
                              return DropdownMenuItem<String>(value: timeSlot, child: Text(timeSlot));
                            }).toList()),
                  onChanged: (_isDayClosed || _dynamicAvailableSlots.isEmpty) ? null : (val) => setState(() => _selectedTimeSlot = val),
                  validator: (v) {
                    if (_isDayClosed || v == 'SHOP_CLOSED') {
                      return 'Store is closed on this date. Please pick another day.';
                    }
                    if (_selectedTimeSlot == null && _selectedDate != null) {
                      return 'Please choose an operational hour slot';
                    }
                    if (_selectedDate == null) {
                      return 'Please pick a booking date first';
                    }
                    return null;
                  },
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
                TextFormField(
                  controller: _ownerPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Australian Contact Number *', 
                    hintText: 'e.g. 0412345678', 
                    border: OutlineInputBorder(),
                    counterText: "",
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Contact details required';
                    if (v.length < 8 || v.length > 10) return 'Enter a valid Australian number (8-10 digits)';
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
                
                // Added Dog Weight Field
                TextFormField(
                  controller: _dogWeightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    // Permits integers or numbers with up to 2 decimal places (e.g. 14, 14.5, 14.52)
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Dog Weight (kg) *',
                    hintText: 'e.g. 12.5',
                    suffixText: 'kg',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Dog weight is required';
                    final parsed = double.tryParse(v.trim());
                    if (parsed == null || parsed <= 0) return 'Enter a valid weight in kg';
                    return null;
                  },
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