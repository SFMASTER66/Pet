import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform; // Safe conditional platform imports

import '../../models/merchant_config.dart';
import 'customer_layout.dart';

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

  // Regex pattern for strict email validation[cite: 5]
  final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  /// 🌐 Dynamic base URL provider parsing layout rules by runtime target
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    return Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// 🌐 Performs the asynchronous POST transaction to the Express backend cluster[cite: 5]
  Future<void> _submitContactForm() async {
    if (!_formKey.currentState!.validate()) return; //[cite: 5]

    setState(() {
      _isSubmitting = true; //[cite: 5]
    });

    // Combines dynamic base target URLs safely with backend routing metrics[cite: 5]
    final Uri url = Uri.parse("$_baseUrl/api/v1/customers/contact");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "merchantId": widget.config.merchantId, // Dynamically sourced from configuration models[cite: 5]
          "firstName": _firstNameController.text, //[cite: 5]
          "lastName": _lastNameController.text, //[cite: 5]
          "email": _emailController.text, //[cite: 5]
          "message": _messageController.text, //[cite: 5]
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body); //[cite: 5]

      if (!mounted) return; //[cite: 5]

      if (response.statusCode == 201 && responseData['success'] == true) { //[cite: 5]
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Message sent successfully! Email dispatched to our team."), //[cite: 5]
            backgroundColor: primaryGreen, //[cite: 5]
          ),
        );
        
        // Wipe local buffers on successful server acknowledgement[cite: 5]
        _firstNameController.clear(); //[cite: 5]
        _lastNameController.clear(); //[cite: 5]
        _emailController.clear(); //[cite: 5]
        _messageController.clear(); //[cite: 5]
        _formKey.currentState?.reset(); //[cite: 5]
      } else {
        final errorMessage = responseData['message'] ?? 'Unable to process inquiry form parameters.'; //[cite: 5]
        _showErrorSnackBar(errorMessage); //[cite: 5]
      }
    } catch (error) {
      if (!mounted) return; //[cite: 5]
      _showErrorSnackBar("Network connectivity error: Failed to reach processing server."); //[cite: 5]
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false; //[cite: 5]
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), //[cite: 5]
        backgroundColor: Colors.redAccent, //[cite: 5]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; //[cite: 5]
    final mapHeight = screenWidth < 600 ? 320.0 : 450.0; //[cite: 5]

    return CustomerLayoutWrapper(
      config: widget.config, //[cite: 5]
      activeTab: CustomerTab.contact, //[cite: 5]
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0), //[cite: 5]
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
                  ), //[cite: 5]
                  const SizedBox(height: 12), //[cite: 5]
                  const Text(
                    "* Have any questions or inquiries? contact or call 0493707378, we would be happy to answer your questions.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF555555),
                      height: 1.4,
                    ),
                  ), //[cite: 5]
                  const SizedBox(height: 48), //[cite: 5]

                  // --- Responsive Main Layout (Grid / Column) ---
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 800; //[cite: 5]

                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildContactInfoList(), //[cite: 5]
                            const SizedBox(height: 48), //[cite: 5]
                            _buildContactForm(), //[cite: 5]
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildContactInfoList(), //[cite: 5]
                          ),
                          const SizedBox(width: 48), //[cite: 5]
                          Expanded(
                            flex: 6,
                            child: _buildContactForm(), //[cite: 5]
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32), //[cite: 5]

            // --- Thin Horizontal Divider line above map ---
            const Divider(
              color: Color(0xFFE2E8F0),
              thickness: 1,
              height: 1,
            ), //[cite: 5]

            const SizedBox(height: 48), //[cite: 5]

            // --- Interactive Map (Hardcoded Location: Braddon ACT 2612) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), //[cite: 5]
              child: Container(
                height: mapHeight, //[cite: 5]
                width: double.infinity, //[cite: 5]
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)), //[cite: 5]
                  borderRadius: BorderRadius.circular(4), //[cite: 5]
                ),
                clipBehavior: Clip.antiAlias, //[cite: 5]
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: mapCenter, //[cite: 5]
                    initialZoom: 15.0, //[cite: 5]
                    minZoom: 3.0, //[cite: 5]
                    maxZoom: 18.0, //[cite: 5]
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', //[cite: 5]
                      userAgentPackageName: 'com.pawparazzi.app', //[cite: 5]
                    ),
                    const MarkerLayer(
                      markers: [
                        Marker(
                          point: mapCenter, //[cite: 5]
                          width: 44, //[cite: 5]
                          height: 44, //[cite: 5]
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

            const SizedBox(height: 48), //[cite: 5]
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
        ), //[cite: 5]
        SizedBox(height: 28), //[cite: 5]
        _ContactInfoTile(
          icon: Icons.phone_outlined,
          children: [
            Text(
              "0493707378",
              style: TextStyle(fontSize: 16, color: darkTextColor, fontWeight: FontWeight.w500),
            ),
          ],
        ), //[cite: 5]
        SizedBox(height: 28), //[cite: 5]
        _ContactInfoTile(
          icon: Icons.mail_outline_rounded,
          children: [
            Text(
              "contact@pawparazzipet.com.au",
              style: TextStyle(fontSize: 16, color: darkTextColor, fontWeight: FontWeight.w500),
            ),
          ],
        ), //[cite: 5]
        SizedBox(height: 28), //[cite: 5]
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
    ); //[cite: 5]
  }

  // --- Right Side: Required Form Fields ---
  Widget _buildContactForm() {
    return Form(
      key: _formKey, //[cite: 5]
      autovalidateMode: AutovalidateMode.onUserInteraction, //[cite: 5]
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 500; //[cite: 5]
              if (isSmallScreen) {
                return Column(
                  children: [
                    _FormFieldWrapper(
                      label: "First Name *",
                      child: TextFormField(
                        controller: _firstNameController, //[cite: 5]
                        decoration: _inputDecoration(), //[cite: 5]
                        enabled: !_isSubmitting, //[cite: 5]
                        validator: (val) => (val == null || val.trim().isEmpty) ? "First name is required" : null, //[cite: 5]
                      ),
                    ),
                    const SizedBox(height: 20), //[cite: 5]
                    _FormFieldWrapper(
                      label: "Last Name *",
                      child: TextFormField(
                        controller: _lastNameController, //[cite: 5]
                        decoration: _inputDecoration(), //[cite: 5]
                        enabled: !_isSubmitting, //[cite: 5]
                        validator: (val) => (val == null || val.trim().isEmpty) ? "Last name is required" : null, //[cite: 5]
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
                        controller: _firstNameController, //[cite: 5]
                        decoration: _inputDecoration(), //[cite: 5]
                        enabled: !_isSubmitting, //[cite: 5]
                        validator: (val) => (val == null || val.trim().isEmpty) ? "First name is required" : null, //[cite: 5]
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), //[cite: 5]
                  Expanded(
                    child: _FormFieldWrapper(
                      label: "Last Name *",
                      child: TextFormField(
                        controller: _lastNameController, //[cite: 5]
                        decoration: _inputDecoration(), //[cite: 5]
                        enabled: !_isSubmitting, //[cite: 5]
                        validator: (val) => (val == null || val.trim().isEmpty) ? "Last name is required" : null, //[cite: 5]
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20), //[cite: 5]
          _FormFieldWrapper(
            label: "Email *",
            child: TextFormField(
              controller: _emailController, //[cite: 5]
              keyboardType: TextInputType.emailAddress, //[cite: 5]
              decoration: _inputDecoration(), //[cite: 5]
              enabled: !_isSubmitting, //[cite: 5]
              validator: (val) {
                if (val == null || val.trim().isEmpty) return "Email is required"; //[cite: 5]
                if (!_emailRegex.hasMatch(val.trim())) return "Please enter a valid email address"; //[cite: 5]
                return null; //[cite: 5]
              },
            ),
          ),
          const SizedBox(height: 20), //[cite: 5]
          _FormFieldWrapper(
            label: "Message *",
            child: TextFormField(
              controller: _messageController, //[cite: 5]
              maxLines: 5, //[cite: 5]
              decoration: _inputDecoration(), //[cite: 5]
              enabled: !_isSubmitting, //[cite: 5]
              validator: (val) => (val == null || val.trim().isEmpty) ? "Message cannot be empty" : null, //[cite: 5]
            ),
          ),
          const SizedBox(height: 24), //[cite: 5]
          Align(
            alignment: Alignment.centerRight, //[cite: 5]
            child: SizedBox(
              width: 140, //[cite: 5]
              height: 48, //[cite: 5]
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen, //[cite: 5]
                  foregroundColor: Colors.white, //[cite: 5]
                  elevation: 0, //[cite: 5]
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), //[cite: 5]
                ),
                onPressed: _isSubmitting ? null : _submitContactForm, //[cite: 5]
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      ) //[cite: 5]
                    : const Text("Send", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400)), //[cite: 5]
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
    ); //[cite: 5]
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
        Icon(icon, size: 28, color: const Color(0xFF4A5568)), //[cite: 5]
        const SizedBox(width: 24), //[cite: 5]
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children, //[cite: 5]
          ),
        ),
      ],
    ); //[cite: 5]
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
        ), //[cite: 5]
        const SizedBox(height: 6), //[cite: 5]
        child, //[cite: 5]
      ],
    );
  }
}