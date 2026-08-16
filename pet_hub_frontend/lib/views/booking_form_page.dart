import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/merchant_config.dart';
import 'card_payment_page.dart';

class BookingFormPage extends StatefulWidget {
  final String serviceName;
  final List<Map<String, dynamic>> variantsMatrix;
  final Color themeColor;
  final MerchantConfig config;
  final String baseUrl;
  final String merchantId; // Required for API calls

  const BookingFormPage({
    super.key,
    required this.serviceName,
    required this.variantsMatrix,
    required this.themeColor,
    required this.config,
    required this.baseUrl,
    required this.merchantId,
  });

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _ownerNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();

  final _dogNameCtrl = TextEditingController();
  final _dogBreedCtrl = TextEditingController();
  final _dogWeightCtrl = TextEditingController();
  final _dogTagsCtrl = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String? _selectedSex;
  String? _selectedDesexed;
  DateTime? _dogDob;

  String? _selectedWeightTier;
  String? _selectedCoatType;

  // Checkbox state variables
  bool _acceptedTerms = false;
  bool _acceptedGroomingPolicy = false;
  bool _acceptedCancellationPolicy = false;

  List<String> _dynamicAvailableSlots = [];
  bool _isLoadingHours = false;
  bool _isCreatingBooking = false;
  bool _isDayClosed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLiveOperationalHours();
  }

  Future<void> _fetchLiveOperationalHours() async {
    if (!mounted) return;
    setState(() {
      _isLoadingHours = true;
      _errorMessage = null;
    });

    if (_selectedDate == null) {
      setState(() {
        _isLoadingHours = false;
        _dynamicAvailableSlots = [];
        _selectedTimeSlot = null;
      });
      return;
    }

    try {
      final String formattedDate = "${_selectedDate!.year}-"
          "${_selectedDate!.month.toString().padLeft(2, '0')}-"
          "${_selectedDate!.day.toString().padLeft(2, '0')}";

      final matchedVariant = _lookupMatchedVariant();
      final int durationMinutes = matchedVariant?['durationMinutes'] ?? 60;

      final String targetUrl = '${widget.baseUrl}/api/v1/bookings/available-slots'
          '?merchantId=${widget.merchantId}'
          '&date=$formattedDate'
          '&duration=$durationMinutes';

      final response = await http.get(
        Uri.parse(targetUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> parsedBody = json.decode(response.body);
        if (parsedBody['success'] == true && parsedBody['data'] is List) {
          final List<dynamic> backendSlots = parsedBody['data'];

          setState(() {
            if (backendSlots.isNotEmpty) {
              _isDayClosed = false;
              _dynamicAvailableSlots = backendSlots.map<String>((slot) {
                final parts = slot.toString().split(':');
                final int hour = int.parse(parts[0]);
                final String minute = parts[1];

                final int displayHour =
                    hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                final String amPm = hour >= 12 ? 'PM' : 'AM';
                final String paddedHour =
                    displayHour.toString().padLeft(2, '0');

                return '$paddedHour:$minute $amPm';
              }).toList();
            } else {
              _isDayClosed = true;
              _dynamicAvailableSlots = [];
            }

            if (_dynamicAvailableSlots.isNotEmpty) {
              _selectedTimeSlot = _dynamicAvailableSlots.first;
            } else {
              _selectedTimeSlot = _isDayClosed ? "SHOP_CLOSED" : null;
            }
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to download updated operational hours.';
          _dynamicAvailableSlots = [];
          _selectedTimeSlot = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Network connection failed.';
        _dynamicAvailableSlots = [];
        _selectedTimeSlot = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingHours = false);
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
        final vWeight =
            (variant['weightTier'] ?? '').toString().toUpperCase();
        final vCoat = (variant['coatType'] ?? '').toString().toUpperCase();
        return vWeight == _selectedWeightTier!.toUpperCase() &&
            vCoat == _selectedCoatType!.toUpperCase();
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
    _dogWeightCtrl.dispose();
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

  /// Redirects to /policy in a new tab safely on Flutter Web and Mobile
  void _openPolicyInNewTab() {
    final Uri baseUri = Uri.base;

    // Checks if current web app is using hash routing (/#/...)
    final bool hasHashRouting = kIsWeb && baseUri.fragment.isNotEmpty;
    
    final Uri policyUri = hasHashRouting
        ? Uri.parse('${baseUri.scheme}://${baseUri.host}:${baseUri.port}/#/policy')
        : Uri.parse('${baseUri.scheme}://${baseUri.host}:${baseUri.port}/policy');

    launchUrl(
      policyUri,
      webOnlyWindowName: '_blank',
    );
  }

  /// Redirects to /about-cancellation-policy in a new tab safely on Flutter Web and Mobile
  void _openCancellationPolicyInNewTab() {
    final Uri baseUri = Uri.base;

    // Checks if current web app is using hash routing (/#/...)
    final bool hasHashRouting = kIsWeb && baseUri.fragment.isNotEmpty;
    
    final Uri cancelPolicyUri = hasHashRouting
        ? Uri.parse('${baseUri.scheme}://${baseUri.host}:${baseUri.port}/#/about-cancellation-policy')
        : Uri.parse('${baseUri.scheme}://${baseUri.host}:${baseUri.port}/about-cancellation-policy');

    launchUrl(
      cancelPolicyUri,
      webOnlyWindowName: '_blank',
    );
  }

  Future<void> _createBookingAndGoToPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      _showSnackBar('Please select an appointment date.');
      return;
    }
    if (_selectedTimeSlot == null || _selectedTimeSlot == "SHOP_CLOSED") {
      _showSnackBar(_selectedTimeSlot == "SHOP_CLOSED"
          ? 'Store is closed on the selected date.'
          : 'Please select a valid time slot.');
      return;
    }
    if (_dogDob == null) {
      _showSnackBar('Please select your dog\'s date of birth.');
      return;
    }
    if (!_acceptedTerms || !_acceptedGroomingPolicy || !_acceptedCancellationPolicy) {
      _showSnackBar('Please accept all policies and terms to proceed.');
      return;
    }

    final matchedRecord = _lookupMatchedVariant();
    if (matchedRecord == null) {
      _showSnackBar('Selected variant combination is invalid.');
      return;
    }

    setState(() => _isCreatingBooking = true);

    try {
      final parts = _selectedTimeSlot!.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final String amPm = parts.length > 1 ? parts[1] : 'AM';

      if (amPm == 'PM' && hour < 12) hour += 12;
      if (amPm == 'AM' && hour == 12) hour = 0;

      final targetDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        hour,
        minute,
      );

      final bookingPayload = {
        'merchantId': widget.merchantId,
        'bookedById': widget.config.userId,
        'servicePricingMatrixId': matchedRecord['id'],
        'dogName': _dogNameCtrl.text.trim(),
        'dogBreed': _dogBreedCtrl.text.trim(),
        'dogWeight': double.tryParse(_dogWeightCtrl.text.trim()) ?? 0.0,
        'dogGender': (_selectedSex ?? 'MALE').toUpperCase(),
        'isDesexed': _selectedDesexed == 'Yes',
        'dogDob': _dogDob!.toIso8601String(),
        'ownerName': _ownerNameCtrl.text.trim(),
        'ownerPhone': _ownerPhoneCtrl.text.trim(),
        'ownerEmail': _ownerEmailCtrl.text.trim(),
        'serviceTime': targetDateTime.toIso8601String(),
        'note': _dogTagsCtrl.text.trim(),
        'termsAccepted': _acceptedTerms,
        'groomingPolicyAccepted': _acceptedGroomingPolicy,
        'cancellationPolicyAccepted': _acceptedCancellationPolicy,
      };

      final bookingResponse = await http.post(
        Uri.parse('${widget.baseUrl}/api/v1/bookings/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bookingPayload),
      );

      final bookingData = jsonDecode(bookingResponse.body);
      if (bookingResponse.statusCode != 200 && bookingResponse.statusCode != 201) {
        throw Exception(bookingData['message'] ?? 'Failed to register appointment.');
      }

      final String appointmentId = bookingData['data']['id'].toString();

      final int priceCents = matchedRecord['priceCentsAud'] ?? matchedRecord['priceCents'] ?? 0;
      final double totalAmount = (priceCents / 100).toDouble();

      final int depositCents = matchedRecord['depositCentsAud'] ?? matchedRecord['depositCentsAud'] ?? 3000;
      final double depositAmount = (depositCents / 100).toDouble();

      final payload = CardCheckoutPayload(
        appointmentId: appointmentId,
        serviceName: widget.serviceName,
        variantTitle: "$_selectedWeightTier, $_selectedCoatType dogs",
        totalAmount: totalAmount,
        depositAmount: depositAmount,
        serviceTime: targetDateTime,
        merchantId: widget.merchantId,
        ownerName: _ownerNameCtrl.text.trim(),
        ownerPhone: _ownerPhoneCtrl.text.trim(),
        ownerEmail: _ownerEmailCtrl.text.trim(),
        dogName: _dogNameCtrl.text.trim(),
        dogBreed: _dogBreedCtrl.text.trim(),
        baseUrl: widget.baseUrl,
        businessName: widget.config.businessName,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardPaymentPage(checkoutPayload: payload),
        ),
      );
    } catch (err) {
      if (!mounted) return;
      _showSnackBar('❌ Error: ${err.toString()}');
    } finally {
      if (mounted) setState(() => _isCreatingBooking = false);
    }
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
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
                  items: weightTiers.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
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
                  items: coatTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
                        border: Border.all(color: widget.themeColor, width: 1)),
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
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.themeColor)),
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
                      side: BorderSide(color: Colors.grey.shade400)),
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
                            child: Text('Closed on this day', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          )
                        ]
                      : (_dynamicAvailableSlots.isEmpty
                          ? [
                              DropdownMenuItem<String>(
                                value: null,
                                enabled: false,
                                child: Text(_selectedDate == null ? 'Please select a date first' : 'No available slots found', style: TextStyle(color: Colors.grey.shade500)),
                              )
                            ]
                          : _dynamicAvailableSlots.map((timeSlot) => DropdownMenuItem<String>(value: timeSlot, child: Text(timeSlot))).toList()),
                  onChanged: (_isDayClosed || _dynamicAvailableSlots.isEmpty) ? null : (val) => setState(() => _selectedTimeSlot = val),
                  validator: (v) {
                    if (_isDayClosed || v == 'SHOP_CLOSED') return 'Store is closed on this date.';
                    if (_selectedTimeSlot == null && _selectedDate != null) return 'Please choose an operational hour slot';
                    if (_selectedDate == null) return 'Please pick a booking date first';
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
                TextFormField(
                  controller: _dogWeightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
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
                      side: BorderSide(color: Colors.grey.shade400)),
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
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('5. Terms & Health Conditions'),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '1. All new clients must present proof of current vaccinations at the first visit. Dogs should receive an annual veterinary health check and up-to-date vaccinations.',
                        style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '2. Please inform us of any diagnosed serious conditions (e.g., heart disease, epilepsy, cancer) and provide relevant veterinary documentation. We reserve the right to decline services when grooming would, in our professional judgment, pose a health risk.',
                        style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FormField<bool>(
                  initialValue: _acceptedTerms,
                  validator: (value) => !_acceptedTerms ? 'You must accept the terms & conditions' : null,
                  builder: (state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'I have read and agree to the Terms & Health Conditions *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          value: _acceptedTerms,
                          onChanged: (val) {
                            setState(() => _acceptedTerms = val ?? false);
                            state.didChange(val);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: widget.themeColor,
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(state.errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                          ),
                      ],
                    );
                  },
                ),
                FormField<bool>(
                  initialValue: _acceptedGroomingPolicy,
                  validator: (value) => !_acceptedGroomingPolicy ? 'You must agree to the Grooming Policy' : null,
                  builder: (state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                              children: [
                                const TextSpan(text: 'I read and agree to Pawparazzi Pet '),
                                TextSpan(
                                  text: 'Grooming policy',
                                  style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _openPolicyInNewTab,
                                ),
                                const TextSpan(text: ' *'),
                              ],
                            ),
                          ),
                          value: _acceptedGroomingPolicy,
                          onChanged: (val) {
                            setState(() => _acceptedGroomingPolicy = val ?? false);
                            state.didChange(val);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: widget.themeColor,
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(state.errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                          ),
                      ],
                    );
                  },
                ),
                FormField<bool>(
                  initialValue: _acceptedCancellationPolicy,
                  validator: (value) => !_acceptedCancellationPolicy ? 'You must agree to the Cancellation Policy' : null,
                  builder: (state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                              children: [
                                const TextSpan(text: 'I agree to No cancellations or changes allowed within 24 hours of the appointment. '),
                                TextSpan(
                                  text: 'Cancellation Policy',
                                  style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _openCancellationPolicyInNewTab,
                                ),
                                const TextSpan(text: ' *'),
                              ],
                            ),
                          ),
                          value: _acceptedCancellationPolicy,
                          onChanged: (val) {
                            setState(() => _acceptedCancellationPolicy = val ?? false);
                            state.didChange(val);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: widget.themeColor,
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(state.errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                          ),
                      ],
                    );
                  },
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
                onPressed: _isCreatingBooking ? null : _createBookingAndGoToPayment,
                child: _isCreatingBooking
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Proceed to Card Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

class CardCheckoutPayload {
  final String appointmentId;
  final String serviceName;
  final String variantTitle;
  final double totalAmount;
  final double depositAmount;
  final DateTime serviceTime;

  final String merchantId;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String dogName;
  final String dogBreed;

  final String baseUrl;
  final String businessName;

  CardCheckoutPayload({
    required this.appointmentId,
    required this.serviceName,
    required this.variantTitle,
    required this.totalAmount,
    required this.depositAmount,
    required this.serviceTime,
    required this.merchantId,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.dogName,
    required this.dogBreed,
    required this.baseUrl,
    required this.businessName,
  });
}