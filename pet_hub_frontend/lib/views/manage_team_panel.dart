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

  Future<void> _fetchStaffList() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/merchant/staff'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
        },
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _invitedStaff = responseData['data'] ?? [];
        });
      }
    } catch (e) {
      _showSnackBar('Could not reload staff directory context.', Colors.red);
    }
  }

  Future<void> _createStaffAccount() async {
    if (_staffNameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/merchant/staff'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}', 
        },
        body: jsonEncode({
          'name': _staffNameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackBar('Staff profile created successfully!', Colors.green);
        _staffNameController.clear();
        _passwordController.clear();
        _fetchStaffList(); // Reload live list configuration frame
      } else {
        _showSnackBar(responseData['message'] ?? 'Failed to create staff.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Could not connect to backend server.', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStaff(String staffId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/v1/merchant/staff/$staffId'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
        },
      );
      if (response.statusCode == 200) {
        _showSnackBar('Staff access credential removed.', Colors.blueGrey);
        _fetchStaffList();
      } else {
        _showSnackBar('Failed to remove staff profile.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error communication context pipeline.', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _staffNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Staff Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a credentials block for team members using the workspace email layout.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 20),

                const Text('Staff Member Name', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _staffNameController,
                  decoration: const InputDecoration(hintText: 'e.g. Sam Groomer', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                const Text('Shared Login Email', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'info@business.com', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                const Text('Assign Staff Password', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Assign a separate pass for this staff profile', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.config.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : _createStaffAccount,
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save & Authorize Staff Member', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        return ListTile(
                          title: Text(staff['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(staff['email'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteStaff(staff['id']),
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