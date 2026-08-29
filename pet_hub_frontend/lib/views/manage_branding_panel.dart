import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../models/merchant_config.dart';

class ManageBrandingPanel extends StatefulWidget {
  final MerchantConfig config;
  final String authToken;
  final String baseUrl;
  final Function(MerchantConfig) onConfigChanged;

  const ManageBrandingPanel({
    super.key,
    required this.config,
    required this.authToken,
    required this.baseUrl,
    required this.onConfigChanged,
  });

  @override
  State<ManageBrandingPanel> createState() => _ManageBrandingPanelState();
}

class _ManageBrandingPanelState extends State<ManageBrandingPanel> {
  bool _isUploading = false;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  Future<void> _pickAndUploadLogo() async {
    // Compatible with file_picker versions that expose pickFiles via FilePicker.platform.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'svg', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() {
      _selectedFileBytes = file.bytes;
      _selectedFileName = file.name;
      _isUploading = true;
    });

    try {
      final uri = Uri.parse('${widget.baseUrl}/api/v1/merchant/${widget.config.merchantId}/logo');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer ${widget.authToken}'
        ..files.add(
          http.MultipartFile.fromBytes(
            'logo',
            _selectedFileBytes!,
            filename: _selectedFileName ?? 'logo.png',
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final updatedLogo = data['data']['logoIcon'] ?? widget.config.logoIcon;
          
          final newConfig = widget.config.copyWith(logoIcon: updatedLogo);
          widget.onConfigChanged(newConfig);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🚀 Logo uploaded and updated successfully!')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Upload failed: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Connection error uploading logo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBase64 = widget.config.logoIcon.startsWith('data:image');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 400;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Brand Identity & Assets',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload your local logo icon to display across the merchant app and client portal.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),

              // Preview Container
              Center(
                child: Container(
                  width: isMobile ? double.infinity : 220,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_selectedFileBytes != null)
                        Image.memory(
                          _selectedFileBytes!, 
                          height: 90, 
                          fit: BoxFit.contain,
                        )
                      else
                        Image.memory(
                          base64Decode(
                            widget.config.logoIcon.contains(',')
                                ? widget.config.logoIcon.split(',').last
                                : widget.config.logoIcon,
                          ),
                          height: 90,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFileName ?? 'Active Logo Preview',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Upload Box
              InkWell(
                onTap: _isUploading ? null : _pickAndUploadLogo,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: _isUploading
                        ? const Column(
                            children: [
                              CircularProgressIndicator(strokeWidth: 2),
                              SizedBox(height: 12),
                              Text('Uploading logo asset...', style: TextStyle(fontSize: 13, color: Colors.blue)),
                            ],
                          )
                        : Column(
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 36, color: widget.config.primaryColor),
                              const SizedBox(height: 8),
                              const Text(
                                'Click to browse image file from laptop',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Supports PNG, JPG, SVG, WEBP (Max 5MB)',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}