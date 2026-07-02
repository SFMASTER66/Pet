import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

class MerchantAuthWrapper extends StatelessWidget {
  final bool isRegisterMode; 
  final Future<void> Function(String token, String role, Map<String, dynamic> configPayload) onUpdateAuth;
  
  const MerchantAuthWrapper({
    super.key, 
    this.isRegisterMode = false, 
    required this.onUpdateAuth,
  });

  @override
  Widget build(BuildContext context) {
    return MerchantRegisterLoginPage(
      initialRegisterMode: isRegisterMode, 
      onAuthSuccess: (responseData) async {
        final String token = responseData['token'] ?? '';
        final String role = responseData['role'] ?? 
            (responseData['user'] != null ? responseData['user']['role'] : 'MERCHANT_STAFF');
        final configPayload = responseData['config'] ?? responseData;
        
        await onUpdateAuth(token, role, configPayload);
      },
    );
  }
}

class MerchantRegisterLoginPage extends StatefulWidget {
  final bool initialRegisterMode;
  final AsyncCallbackWithPayload onAuthSuccess; 
  
  const MerchantRegisterLoginPage({
    super.key, 
    required this.onAuthSuccess,
    required this.initialRegisterMode,
  });

  @override
  State<MerchantRegisterLoginPage> createState() => _MerchantRegisterLoginPageState();
}

typedef AsyncCallbackWithPayload = Future<void> Function(Map<String, dynamic> data);

class _MerchantRegisterLoginPageState extends State<MerchantRegisterLoginPage> {
  late bool _isLoginMode;
  bool _isLoading = false; 

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminNameController = TextEditingController(); 
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  
  final String _selectedRole = 'MERCHANT_ADMIN'; 
  String _selectedLogo = '💼'; 
  Color _selectedColor = const Color(0xFF1E293B); 

  final List<String> _availableLogos = ['💼', '🛒', '🏪', '💇', '🏋️', '☕', '🍽️', '🎨'];
  final List<Color> _availableColors = [
    const Color(0xFF1E293B), const Color(0xFF0F766E), const Color(0xFF1E3A8A), 
    const Color(0xFF7C3AED), const Color(0xFFDC2626), const Color(0xFF059669),
  ];

  @override
  void initState() {
    super.initState();
    _isLoginMode = !widget.initialRegisterMode;
  }

  @override
  void didUpdateWidget(covariant MerchantRegisterLoginPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRegisterMode != oldWidget.initialRegisterMode) {
      setState(() {
        _isLoginMode = !widget.initialRegisterMode;
      });
    }
  }

  Future<void> _submitAuth() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('Please fill in email and password fields.');
      return;
    }

    if (!_isLoginMode && (_adminNameController.text.trim().isEmpty || _nameController.text.trim().isEmpty)) {
      _showErrorSnackBar('Please complete all initialization fields.');
      return;
    }

    setState(() => _isLoading = true);

    String baseUrl = 'http://127.0.0.1:3000'; 
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        baseUrl = 'http://10.0.2.2:3000'; 
      } else if (Platform.isIOS) {
        baseUrl = 'http://127.0.0.1:3000'; 
      }
    }

    final String endpoint = _isLoginMode 
        ? '$baseUrl/api/v1/login'     
        : '$baseUrl/api/v1/register';  

    final Map<String, dynamic> payload = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
    };

    if (!_isLoginMode) {
      List<String> parsedTags = _tagController.text
          .split(RegExp(r'[,，]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      payload.addAll({
        'role': _selectedRole,
        'adminName': _adminNameController.text.trim(),
        'businessName': _nameController.text.trim(),
        'logoIcon': _selectedLogo,
        'primaryColor': _selectedColor.toARGB32(),
        'tags': parsedTags.isEmpty ? ['General'] : parsedTags,
      });
    }

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await widget.onAuthSuccess(responseData);
      } else {
        _showErrorSnackBar(responseData['message'] ?? 'Authentication failed');
      }
    } catch (e) {
      _showErrorSnackBar('Could not connect to backend server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _adminNameController.dispose();
    _nameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(40),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), 
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoginMode ? 'Sign In' : 'Register Workspace',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode ? 'Access your workspace control panel' : 'Set up your system custom branding configuration',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                
                const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController, 
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'info@business.com', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 16),
                
                const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController, 
                  obscureText: true, 
                  decoration: const InputDecoration(hintText: '••••••••', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                ),
                
                if (!_isLoginMode) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Custom System Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 16),
                  
                  const Text('Administrator Full Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _adminNameController,
                    decoration: const InputDecoration(hintText: 'e.g. Alex Morgan', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 16),

                  const Text('Business Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'e.g. Petcloud Grooming', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
                  ),
                  const SizedBox(height: 16),

                  const Text('Select UI Icon', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _availableLogos.map((logo) {
                      return ChoiceChip(
                        label: Text(logo, style: const TextStyle(fontSize: 18)),
                        selected: _selectedLogo == logo,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedLogo = logo);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  const Text('Theme Palette Color', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: _availableColors.map((color) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == color ? Colors.black : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  const Text('Service Tags (Comma Separated)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(hintText: 'e.g. Grooming, Daycare', border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_offer_outlined)),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoginMode ? const Color(0xFF1E293B) : _selectedColor, 
                      foregroundColor: Colors.white, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _submitAuth, 
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isLoginMode ? 'Log In' : 'Register & Initialize Instance', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                
                Center(
                  child: TextButton(
                    onPressed: () {
                      // FIXED: Toggle mode context instead of executing submission
                      setState(() => _isLoginMode = !_isLoginMode);
                    },
                    child: Text(_isLoginMode ? "Don't have an account? Register Tenant" : 'Already registered? Log In Directly'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}