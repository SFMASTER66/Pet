import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform; // Safe conditional platform imports

import '../../models/merchant_config.dart';
import 'customer_layout.dart';
import '/config/app_config.dart';

class CustomerContactPage extends StatefulWidget {
  final MerchantConfig config;

  const CustomerContactPage({super.key, required this.config});

  @override
  State<CustomerContactPage> createState() => _CustomerContactPageState();
}

class _CustomerContactPageState extends State<CustomerContactPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isSubmitting = false;

  static const Color primaryGreen = Color(0xFF5E6D55);
  static const Color darkTextColor = Color(0xFF2C352E);

  // Hardcoded coordinates for Shop 64, 30 Lonsdale Street, Braddon ACT 2612
  static const double latitude = -35.2713;
  static const double longitude = 149.1332;
  static const latlong.LatLng mapCenter = latlong.LatLng(latitude, longitude);

  // Regex pattern for strict email validation
  final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  // 🌐 Dynamic base URL provider parsing layout rules by runtime target
  String get _baseUrl => AppConfig.baseUrl;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// 🌐 Performs the asynchronous POST transaction to the Express backend cluster
  Future<void> _submitContactForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    // Combines dynamic base target URLs safely with backend routing metrics
    final Uri url = Uri.parse("$_baseUrl/api/v1/customers/contact");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "merchantId": widget.config.merchantId, // Dynamically sourced from configuration models
          "firstName": _firstNameController.text,
          "lastName": _lastNameController.text,
          "email": _emailController.text,
          "message": _messageController.text,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));

      if (!mounted) return;

      if (response.statusCode == 201 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Message sent successfully! Email dispatched to our team."),
            backgroundColor: primaryGreen,
          ),
        );
        
        // Wipe local buffers on successful server acknowledgement
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _messageController.clear();
        _formKey.currentState?.reset();
      } else {
        final errorMessage = responseData['message'] ?? 'Unable to process inquiry form parameters.';
        _showErrorSnackBar(errorMessage);
      }
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar("Network connectivity error: Failed to reach processing server.");
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final mapHeight = screenWidth < 600 ? 320.0 : 450.0;

    return CustomerLayoutWrapper(
      config: widget.config,
      activeTab: CustomerTab.contact,
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header Section ---
                  const Text(
                    "Contact",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w400,
                      color: primaryGreen,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "* Have any questions or inquiries? contact or call 0493707378, we would be happy to answer your questions.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF555555),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // --- Responsive Main Layout (Grid / Column) ---
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 800;

                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildContactInfoList(),
                            const SizedBox(height: 48),
                            _buildContactForm(),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildContactInfoList(),
                          ),
                          const SizedBox(width: 48),
                          Expanded(
                            flex: 6,
                            child: _buildContactForm(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- Thin Horizontal Divider line above map ---
            const Divider(
              color: Color(0xFFE2E8F0),
              thickness: 1,
              height: 1,
            ),

            const SizedBox(height: 48),

            // --- Interactive Map (Hardcoded Location: Braddon ACT 2612) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: mapHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(4),
                ),
                clipBehavior: Clip.antiAlias,
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: mapCenter,
                    initialZoom: 15.0,
                    minZoom: 3.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.pawparazzi.app',
                    ),
                    const MarkerLayer(
                      markers: [
                        Marker(
                          point: mapCenter,
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFFD93737),
                            size: 44,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // --- Left Side: Hardcoded Contact Details ---
  Widget _buildContactInfoList() {
    return const Column(
      children: [
        _ContactInfoTile(
          icon: Icons.location_on_outlined,
          children: [
            Text(
              "Shop 64 30 Lonsdale Street",
              style: TextStyle(fontSize: 16, color: darkTextColor, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 4),
            Text(
              "Braddon ACT 2612",
              style: TextStyle(fontSize: 16, color: darkTextColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        SizedBox(height: 28),
        _ContactInfoTile(
          icon: Icons.phone_outlined,
          children: [
            Text(
              "0493707378",
              style: TextStyle(fontSize: 16, color: darkTextColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        SizedBox(height: 28),
        _ContactInfoTile(
          icon: Icons.mail_outline_rounded,
          children: [
            Text(
              "contact@pawparazzipet.com.au",
              style: TextStyle(fontSize: 16, color: darkTextColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        SizedBox(height: 28),
        _ContactInfoTile(
          icon: Icons.access_time_rounded,
          children: [
            Text(
              "Message Reply",
              style: TextStyle(fontSize: 16, color: darkTextColor, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 4),
            Text(
              "Mon - Fri  9:00 am to 5:00 pm",
              style: TextStyle(fontSize: 16, color: darkTextColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  // --- Right Side: Required Form Fields ---
  Widget _buildContactForm() {
    return Form(
      key: _formKey,
      // Global autovalidateMode removed to emulate career page isolation[cite: 2]
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 500;
              if (isSmallScreen) {
                return Column(
                  children: [
                    _FormFieldWrapper(
                      label: "First Name *",
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: _inputDecoration(),
                        enabled: !_isSubmitting,
                        autovalidateMode: AutovalidateMode.onUserInteraction, // Added isolation[cite: 2]
                        validator: (val) => (val == null || val.trim().isEmpty) ? "First name is required" : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FormFieldWrapper(
                      label: "Last Name *",
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: _inputDecoration(),
                        enabled: !_isSubmitting,
                        autovalidateMode: AutovalidateMode.onUserInteraction, // Added isolation[cite: 2]
                        validator: (val) => (val == null || val.trim().isEmpty) ? "Last name is required" : null,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FormFieldWrapper(
                      label: "First Name *",
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: _inputDecoration(),
                        enabled: !_isSubmitting,
                        autovalidateMode: AutovalidateMode.onUserInteraction, // Added isolation[cite: 2]
                        validator: (val) => (val == null || val.trim().isEmpty) ? "First name is required" : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _FormFieldWrapper(
                      label: "Last Name *",
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: _inputDecoration(),
                        enabled: !_isSubmitting,
                        autovalidateMode: AutovalidateMode.onUserInteraction, // Added isolation[cite: 2]
                        validator: (val) => (val == null || val.trim().isEmpty) ? "Last name is required" : null,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _FormFieldWrapper(
            label: "Email *",
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(),
              enabled: !_isSubmitting,
              autovalidateMode: AutovalidateMode.onUserInteraction, // Added isolation[cite: 2]
              validator: (val) {
                if (val == null || val.trim().isEmpty) return "Email is required";
                if (!_emailRegex.hasMatch(val.trim())) return "Please enter a valid email address";
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          _FormFieldWrapper(
            label: "Message *",
            child: TextFormField(
              controller: _messageController,
              maxLines: 5,
              decoration: _inputDecoration(),
              enabled: !_isSubmitting,
              autovalidateMode: AutovalidateMode.onUserInteraction, // Added isolation[cite: 2]
              validator: (val) => (val == null || val.trim().isEmpty) ? "Message cannot be empty" : null,
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 140,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: _isSubmitting ? null : _submitContactForm,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Text("Send", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return const InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.black87, width: 1)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.black87, width: 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: primaryGreen, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.redAccent, width: 1)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }
}

// --- Helper Components ---
class _ContactInfoTile extends StatelessWidget {
  final IconData icon;
  final List<Widget> children;

  const _ContactInfoTile({required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: const Color(0xFF4A5568)),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _FormFieldWrapper extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormFieldWrapper({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF333333)),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}