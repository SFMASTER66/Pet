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

  // Parses operational hours from data array and splits dynamically into 1-hour interval segments
  void _calculateAvailableTimeSlots(DateTime date) {
    // DateTime weekday: 1 = Monday, 7 = Sunday. Matches backend database format perfectly.
    final int targetDay = date.weekday;
    
    final dayConfig = _merchantHours.firstWhere(
      (h) => h['dayOfWeek'] == targetDay,
      orElse: () => null,
    );

    if (dayConfig == null || dayConfig['isClosed'] == true) {
      setState(() {
        _dynamicAvailableSlots = [];
        _selectedTimeSlot = "SHOP_CLOSED"; // Set to a concrete dummy string value so it matches the dropdown item
        _isDayClosed = true; // Mark this day explicitly as closed
      });
      return;
    }

    final String openStr = dayConfig['openTime'] ?? '09:00';
    final String closeStr = dayConfig['closeTime'] ?? '17:00';

    // Extract numerical hour components from structural string 'HH:mm'
    final int startHour = int.parse(openStr.split(':')[0]);
    final int endHour = int.parse(closeStr.split(':')[0]);

    final List<String> generatedSlots = [];
    
    // Generate full hourly slots based on the gap parameters layout rule
    for (int hour = startHour; hour < endHour; hour++) {
      final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final String amPm = hour >= 12 ? 'PM' : 'AM';
      final String paddedHour = displayHour.toString().padLeft(2, '0');
      
      generatedSlots.add('$paddedHour:00 $amPm');
    }

    setState(() {
      _dynamicAvailableSlots = generatedSlots;
      _selectedTimeSlot = null; // Clear chosen time slot choice when calendar parameters alter
      _isDayClosed = false; // Store is open, hourly options are populated
    });
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

  void _submitBooking() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTimeSlot == null || _selectedTimeSlot == "SHOP_CLOSED" || _dogDob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an open booking date and valid time slot.')),
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
                    // Re-fetch dynamic time slots if the variant duration drops or shifts
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
                    // Re-fetch dynamic time slots if the variant duration drops or shifts
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
                  key: ValueKey('${_dynamicAvailableSlots.length}_${_isDayClosed}_$_selectedTimeSlot'), // Complete unique state recalculation key
                  decoration: InputDecoration(
                    labelText: 'Select Appointment Time *', 
                    prefixIcon: const Icon(Icons.access_time, size: 20),
                    border: const OutlineInputBorder(),
                    errorStyle: const TextStyle(color: Colors.redAccent),
                  ),
                  value: _selectedTimeSlot,
                  // When the day is closed, we inject an explicit disabled option tied to "SHOP_CLOSED"
                  items: _isDayClosed
                      ? [
                          const DropdownMenuItem<String>(
                            value: 'SHOP_CLOSED',
                            enabled: false, // Prevents them from picking it
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