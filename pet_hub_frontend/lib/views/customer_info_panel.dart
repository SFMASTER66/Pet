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

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
      _currentCustomerPage = 1; 
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
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
          child: Card(
            elevation: 2,
            child: TextField(
              controller: _searchController,
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

        Expanded(
          child: _isCustomersLoading
              ? const Center(child: CircularProgressIndicator())
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
                        // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                        // 🚀 CHANGE: RENDER LOOP READS THE OWNER RECORD OBJECTS
                        // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                        final owner = _customerPetList[idx];
                        final List<dynamic> pets = owner['pets'] ?? [];

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
                                    
                                    // LOOP DYNAMICALLY THROUGH ALL PETS BELONGING TO THIS OWNER
                                    if (pets.isEmpty)
                                      const Text('No registered pets.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12))
                                    else
                                      ...pets.map((item) {
                                        final lastApp = item['lastAppointment'];
                                        String lastServiceText = 'No prior appointments';
                                        
                                        if (lastApp != null && lastApp is Map && lastApp['startTime'] != null) {
                                          try {
                                            final parsedDate = DateTime.parse(lastApp['startTime'].toString()).toLocal();
                                            final formattedDate = "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
                                            final serviceName = lastApp['serviceName'] ?? 'Service';
                                            lastServiceText = '$serviceName on $formattedDate';
                                          } catch (_) {
                                            lastServiceText = 'Invalid date format';
                                          }
                                        }

                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12.0),
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Pet Name: ${item['name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                              Text('Breed Type: ${item['breed'] ?? 'N/A'}'),
                                              Text('Status: ${item['gender'] ?? 'MALE'} (${item['isDesexed'] == true ? 'Desexed' : 'Intact'})'),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.shade50,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.calendar_month, size: 14, color: Colors.blue),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Total: ${item['appointmentCount'] ?? 0}',
                                                          style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.purple.shade50,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.history, size: 14, color: Colors.purple),
                                                          const SizedBox(width: 4),
                                                          Flexible(
                                                            child: Text(
                                                              'Last Service: $lastServiceText',
                                                              style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (item['notes'] != null) ...[
                                                const SizedBox(height: 6),
                                                Text('Special Guidelines: ${item['notes']}', style: const TextStyle(fontSize: 12)),
                                              ],
                                            ],
                                          ),
                                        );
                                      }),
                                    // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
        ),

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