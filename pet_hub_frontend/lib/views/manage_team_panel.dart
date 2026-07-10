import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../models/merchant_config.dart';

class ManageTeamPanel extends StatefulWidget {
  final MerchantConfig config;
  final String authToken; 

  const ManageTeamPanel({
    super.key, 
    required this.config, 
    required this.authToken
  });

  @override
  State<ManageTeamPanel> createState() => _ManageTeamPanelState();
}

class _ManageTeamPanelState extends State<ManageTeamPanel> {
  final _staffNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _invitedStaff = [];

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    return Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }

  @override
  void initState() {
    super.initState();
    _emailController.text = "${widget.config.businessName?.replaceAll(' ', '').toLowerCase() ?? 'staff'}@example.com"; 
    _fetchStaffList();
  }

  @override
  void dispose() {
    _staffNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ========================================================================
  // 🔥 UPDATED TO SAFELY FLATTEN THE NESTED PRISMA 'employee.isActive' VALUE
  // ========================================================================
  Future<void> _fetchStaffList() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/merchant/staff'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> rawList = responseData['data'];
          
          // Map across items to safely extract user.employee.isActive into user.isActive
          final flattenedList = rawList.map((user) {
            bool extractedStatus = false;
            
            if (user['employee'] != null && user['employee']['isActive'] != null) {
              extractedStatus = user['employee']['isActive'] as bool;
            } else if (user['isActive'] != null) {
              extractedStatus = user['isActive'] as bool;
            }

            return {
              'id': user['id'],
              'name': user['name'],
              'email': user['email'],
              'role': user['role'],
              'isActive': extractedStatus,
            };
          }).toList();

          setState(() {
            _invitedStaff = flattenedList;
          });
        }
      }
    } catch (_) {
      // Gracefully catch background framework transport network drops
    }
  }

  Future<void> _addStaffAccount() async {
    if (_staffNameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ All staff onboarding fields are mandatory.'))
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/merchant/staff'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _staffNameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        _staffNameController.clear();
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🚀 Team member registered successfully.'))
        );
        _fetchStaffList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${responseData['message'] ?? 'Validation failed.'}'))
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Network transport failure provisioning team member.'))
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStaffStatus(int index, String staffId, bool newStatus) async {
    // Instantly update UI toggle state locally for zero latency feedback
    setState(() {
      _invitedStaff[index]['isActive'] = newStatus;
    });

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/v1/merchant/staff/$staffId'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'isActive': newStatus,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus 
              ? '✅ Staff profile enabled successfully.' 
              : '⏸️ Staff profile disabled successfully.'
            ),
            duration: const Duration(seconds: 1),
          ),
        );
        _fetchStaffList();
      } else {
        // Revert toggle state locally if endpoint errors out
        setState(() {
          _invitedStaff[index]['isActive'] = !newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${responseData['message'] ?? 'Failed to alter status.'}'))
        );
      }
    } catch (_) {
      // Revert toggle state locally if HTTP connection cuts out
      setState(() {
        _invitedStaff[index]['isActive'] = !newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Network transport failure altering profile access status.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Onboard New Team Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _staffNameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Temporary Password', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  icon: _isLoading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Provision Account'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _addStaffAccount,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Active Team Workspace Roster', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _invitedStaff.isEmpty 
                  ? const Text('No active staff profiles found for this workspace.', style: TextStyle(color: Colors.grey))
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _invitedStaff.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final staff = _invitedStaff[index];
                        final bool isActive = staff['isActive'] ?? false;

                        return ListTile(
                          title: Text(
                            staff['name'] ?? '', 
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.black : Colors.grey,
                            ),
                          ),
                          subtitle: Text(
                            staff['email'] ?? '',
                            style: TextStyle(
                              color: isActive ? Colors.black54 : Colors.grey,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? Colors.green : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: isActive,
                                activeColor: const Color(0xFF0F172A),
                                onChanged: (bool value) => _toggleStaffStatus(index, staff['id'], value),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ],
            ),
          ),
        )
      ],
    );
  }
}