import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Added for platform-aware URL handling style
import 'dart:io' show Platform; // Added for platform-aware URL handling style
import 'package:http/http.dart' as http;
import '../../models/merchant_config.dart';
import 'customer_layout.dart';
import '/config/app_config.dart';

class CustomerCareerPage extends StatefulWidget {
  final MerchantConfig config;

  const CustomerCareerPage({super.key, required this.config});

  @override
  State<CustomerCareerPage> createState() => _CustomerCareerPageState();
}

class _CustomerCareerPageState extends State<CustomerCareerPage> {
  static const Color primaryGreen = Color(0xFF5E6D55);
  static const Color darkTextColor = Color(0xFF2C352E);

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSubmitting = false;

  final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  // 🌐 Dynamic base URL provider parsing layout rules by runtime target (Matches Contact Page style)
  String get _baseUrl => AppConfig.baseUrl;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Combines dynamic base target URLs safely with backend routing metrics matching Contact Page style
      final Uri url = Uri.parse("$_baseUrl/api/v1/customers/career");
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'merchantId': widget.config.merchantId ?? '', 
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'message': _messageController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully! Our hiring managers will be in touch.'),
            backgroundColor: primaryGreen,
          ),
        );
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _messageController.clear();
        _formKey.currentState?.reset();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed submission error code discovered.');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration() {
    return const InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      errorStyle: TextStyle(color: Colors.red, fontSize: 12),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: darkTextColor, width: 1.0),
        borderRadius: BorderRadius.zero,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: darkTextColor, width: 1.5),
        borderRadius: BorderRadius.zero,
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.0),
        borderRadius: BorderRadius.zero,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.5),
        borderRadius: BorderRadius.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;

    return CustomerLayoutWrapper(
      config: widget.config,
      activeTab: CustomerTab.career,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- SECTION 1: HERO TEXT BANNER ---
            Container(
              color: primaryGreen,
              padding: EdgeInsets.symmetric(
                vertical: isDesktop ? 64.0 : 32.0,
                horizontal: isDesktop ? 48.0 : 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Career in Pawpawrazi Pet",
                    style: TextStyle(
                      fontSize: isDesktop ? 36 : 28,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
                      children: [
                        TextSpan(text: "Join our team as a "),
                        TextSpan(
                          text: "Pet Groomer",
                          style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w500),
                        ),
                        TextSpan(text: " extraordinaire!"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.white, height: 1.6),
                      children: [
                        TextSpan(
                          text: "At Pawpawrazi Pet, we believe that grooming is an art form, and our groomers are the "
                              "talented artists who bring it to life. We are searching for a creative and dedicated individual "
                              "to join our team as a Pet Groomer. If you have a ",
                        ),
                        TextSpan(
                          text: "love for animals",
                          style: TextStyle(decoration: TextDecoration.underline),
                        ),
                        TextSpan(text: ", an "),
                        TextSpan(
                          text: "eye for style",
                          style: TextStyle(decoration: TextDecoration.underline),
                        ),
                        TextSpan(text: ", and a "),
                        TextSpan(
                          text: "desire to create a truly paw-some experience",
                          style: TextStyle(decoration: TextDecoration.underline),
                        ),
                        TextSpan(text: " for our furry clients, then this is the job for you."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "If you're interested in this position and have grooming experience, we'd love to chat with you!",
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // --- SECTION 2: APPLICATION FORM ---
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 48.0,
                horizontal: isDesktop ? 48.0 : 24.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Let’s Work Together",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: darkTextColor),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Get in touch so we can start working together.",
                      style: TextStyle(fontSize: 16, color: darkTextColor),
                    ),
                    const SizedBox(height: 32),
                    
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 700) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _FormFieldWrapper(
                                      label: "First Name",
                                      child: TextFormField(
                                        controller: _firstNameController,
                                        enabled: !_isSubmitting,
                                        decoration: _inputDecoration(),
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                        style: const TextStyle(color: darkTextColor),
                                        validator: (val) => (val == null || val.trim().isEmpty) ? "This field is required" : null,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _FormFieldWrapper(
                                      label: "Last Name",
                                      child: TextFormField(
                                        controller: _lastNameController,
                                        enabled: !_isSubmitting,
                                        decoration: _inputDecoration(),
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                        style: const TextStyle(color: darkTextColor),
                                        validator: (val) => (val == null || val.trim().isEmpty) ? "This field is required" : null,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _FormFieldWrapper(
                                      label: "Email *",
                                      child: TextFormField(
                                        controller: _emailController,
                                        enabled: !_isSubmitting,
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: _inputDecoration(),
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                        style: const TextStyle(color: darkTextColor),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return "This field is required";
                                          if (!_emailRegex.hasMatch(val.trim())) return "Please enter a valid email address";
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: _FormFieldWrapper(
                                  label: "Message",
                                  child: TextFormField(
                                    controller: _messageController,
                                    enabled: !_isSubmitting,
                                    maxLines: 8,
                                    decoration: _inputDecoration(),
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    style: const TextStyle(color: darkTextColor),
                                    validator: (val) => (val == null || val.trim().isEmpty) ? "This field is required" : null,
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _FormFieldWrapper(
                                label: "First Name",
                                child: TextFormField(
                                  controller: _firstNameController,
                                  enabled: !_isSubmitting,
                                  decoration: _inputDecoration(),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  style: const TextStyle(color: darkTextColor),
                                  validator: (val) => (val == null || val.trim().isEmpty) ? "This field is required" : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _FormFieldWrapper(
                                label: "Last Name",
                                child: TextFormField(
                                  controller: _lastNameController,
                                  enabled: !_isSubmitting,
                                  decoration: _inputDecoration(),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  style: const TextStyle(color: darkTextColor),
                                  validator: (val) => (val == null || val.trim().isEmpty) ? "This field is required" : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _FormFieldWrapper(
                                label: "Email *",
                                child: TextFormField(
                                  controller: _emailController,
                                  enabled: !_isSubmitting,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _inputDecoration(),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  style: const TextStyle(color: darkTextColor),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return "This field is required";
                                    if (!_emailRegex.hasMatch(val.trim())) return "Please enter a valid email address";
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              _FormFieldWrapper(
                                label: "Message",
                                child: TextFormField(
                                  controller: _messageController,
                                  enabled: !_isSubmitting,
                                  maxLines: 6,
                                  decoration: _inputDecoration(),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  style: const TextStyle(color: darkTextColor),
                                  validator: (val) => (val == null || val.trim().isEmpty) ? "This field is required" : null,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    Align(
                      alignment: isDesktop ? Alignment.centerRight : Alignment.centerLeft,
                      child: SizedBox(
                        width: isDesktop ? 160 : double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitApplication,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            elevation: 0,
                          ),
                          child: _isSubmitting 
                            ? const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("Send", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
          style: const TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.w400, 
            color: _CustomerCareerPageState.darkTextColor,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}