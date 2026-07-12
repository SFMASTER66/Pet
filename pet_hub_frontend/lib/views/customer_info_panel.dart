import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/merchant_config.dart';

class CustomerInfoPanel extends StatefulWidget {
  final MerchantConfig config;
  final String authToken;
  final String baseUrl;
  final Color themeColor;

  const CustomerInfoPanel({
    super.key,
    required this.config,
    required this.authToken,
    required this.baseUrl,
    required this.themeColor,
  });

  @override
  State<CustomerInfoPanel> createState() => _CustomerInfoPanelState();
}

class _CustomerInfoPanelState extends State<CustomerInfoPanel> {
  bool _isCustomersLoading = false;
  List<dynamic> _customerPetList = [];
  int _currentCustomerPage = 1;
  int _totalCustomerPages = 1;
  final int _customerLimitPerPage = 10;
  
  // Search controllers and state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPaginatedCustomerPetData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPaginatedCustomerPetData() async {
    if (!mounted) return;
    setState(() => _isCustomersLoading = true);
    
    try {
      // Build the URL dynamically including the search parameter if active
      String url = '${widget.baseUrl}/api/v1/merchant/${widget.config.merchantId}/customers'
          '?page=$_currentCustomerPage&limit=$_customerLimitPerPage';
      
      if (_searchQuery.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(_searchQuery)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _customerPetList = responseData['data']['records'] ?? [];
            _totalCustomerPages = responseData['data']['totalPages'] ?? 1;
          });
        }
      } else {
        _showSnackBar('❌ Failed to retrieve paginated customer metadata profiles.');
      }
    } catch (e) {
      _showSnackBar('❌ Connection error querying pet relation schema records.');
    } finally {
      if (mounted) {
        setState(() => _isCustomersLoading = false);
      }
    }
  }

  // ==========================================
  // 🔥 UPDATED: TRIGGER SEARCH INSTANTLY ON CHANGE
  // ==========================================
  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
      _currentCustomerPage = 1; // Reset to page 1 for new search results
    });
    _fetchPaginatedCustomerPetData();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _currentCustomerPage = 1;
    });
    _fetchPaginatedCustomerPetData();
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar UI
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
          child: Card(
            elevation: 2,
            child: TextField(
              controller: _searchController,
              // ========================================================
              // 🔥 HIGHLIGHT: Swapped 'onSubmitted' with 'onChanged' 
              // ========================================================
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search dog or owner details...',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: Icon(Icons.search, color: widget.themeColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
        ),

        // Main content area handling loading, empty state, or list rendering
        Expanded(
          child: _isCustomersLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _customerPetList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _searchQuery.isEmpty 
                              ? 'No customers found matching database relations profiles.'
                              : 'No results found matching "$_searchQuery".',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _customerPetList.length,
                      itemBuilder: (context, idx) {
                        final item = _customerPetList[idx];
                        final owner = item['owner'] ?? {};
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ExpansionTile(
                            leading: Icon(Icons.assignment_ind, color: widget.themeColor),
                            title: Text(
                              owner['name'] ?? 'Unknown Owner',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              owner['email'] ?? 'No contact email listed',
                              style: const TextStyle(fontSize: 12),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Phone Profile: ${owner['phone'] ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                                    const Divider(),
                                    const Text(
                                      'Associated Pet Profiles:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Pet Name: ${item['name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('Breed Type: ${item['breed'] ?? 'N/A'}'),
                                    Text('Status: ${item['gender'] ?? 'MALE'} (${item['isDesexed'] == true ? 'Desexed' : 'Intact'})'),
                                    if (item['notes'] != null) Text('Special Handling Guidelines: ${item['notes']}'),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
        ),

        // Pagination controls footer
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                onPressed: _currentCustomerPage > 1 && !_isCustomersLoading
                    ? () {
                        setState(() => _currentCustomerPage--);
                        _fetchPaginatedCustomerPetData();
                      }
                    : null,
              ),
              Text(
                'Page $_currentCustomerPage of $_totalCustomerPages',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: _currentCustomerPage < _totalCustomerPages && !_isCustomersLoading
                    ? () {
                        setState(() => _currentCustomerPage++);
                        _fetchPaginatedCustomerPetData();
                      }
                    : null,
              ),
            ],
          ),
        )
      ],
    );
  }
}