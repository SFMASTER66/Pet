import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'booking_form_page.dart';

enum PaymentMethodType { creditCard, applePay }

class CardPaymentPage extends StatefulWidget {
  final CardCheckoutPayload checkoutPayload;

  const CardPaymentPage({
    super.key,
    required this.checkoutPayload,
  });

  @override
  State<CardPaymentPage> createState() => _CardPaymentPageState();
}

class _CardPaymentPageState extends State<CardPaymentPage> {
  final _formKey = GlobalKey<FormState>();

  PaymentMethodType _selectedMethod = PaymentMethodType.creditCard;

  // Billing address fields
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _promoCodeCtrl = TextEditingController();

  String _selectedCountry = 'Australia';
  bool _isSubmitting = false;
  bool _showOrderDetails = false;

  final List<String> _countries = ['Australia', 'New Zealand', 'United States', 'United Kingdom', 'Canada'];

  final Map<String, String> _countryIsoCodes = {
    'Australia': 'AU',
    'New Zealand': 'NZ',
    'United States': 'US',
    'United Kingdom': 'GB',
    'Canada': 'CA',
  };

  @override
  void initState() {
    super.initState();
    final nameParts = widget.checkoutPayload.ownerName.trim().split(' ');
    _firstNameCtrl.text = nameParts.isNotEmpty ? nameParts.first : '';
    _lastNameCtrl.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    _phoneCtrl.text = widget.checkoutPayload.ownerPhone;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _promoCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitCardPayment() async {
    if (_selectedMethod == PaymentMethodType.creditCard && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final int depositCents = (widget.checkoutPayload.depositAmount * 100).round();
      final fullName = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';
      final phone = _phoneCtrl.text.trim();
      final countryIso = _countryIsoCodes[_selectedCountry] ?? 'AU';

      // 1. Create PaymentIntent passing customer info to backend
      final intentResponse = await http.post(
        Uri.parse('${widget.checkoutPayload.baseUrl}/api/v1/payments/create-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amountCents': depositCents,
          'currency': 'aud',
          'customerEmail': widget.checkoutPayload.ownerEmail,
          'customerName': fullName,
          'customerPhone': phone,
          'customerCountry': _selectedCountry,
          'merchantId': widget.checkoutPayload.merchantId,
          'appointmentId': widget.checkoutPayload.appointmentId,
        }),
      );

      final intentData = jsonDecode(intentResponse.body);
      if (intentResponse.statusCode != 200 || intentData['success'] != true) {
        throw Exception(intentData['message'] ?? 'Failed to initialize payment intent.');
      }

      final String clientSecret = intentData['clientSecret'];

      final String paymentIntentId = intentData['paymentIntentId'] ?? intentData['id'] ?? '';

      final billingDetails = BillingDetails(
        name: fullName,
        phone: phone,
        email: widget.checkoutPayload.ownerEmail,
        address: Address(
          country: countryIso,
          city: '',
          line1: '',
          line2: '',
          postalCode: '',
          state: '',
        ),
      );

      if (kIsWeb) {
        // Web flow
        await Stripe.instance.confirmPayment(
          paymentIntentClientSecret: clientSecret,
          data: PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(
              billingDetails: billingDetails,
            ),
          ),
        );
      } else {
        // Native Mobile flow
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: widget.checkoutPayload.businessName,
            style: ThemeMode.light,
            appearance: const PaymentSheetAppearance(
              colors: PaymentSheetAppearanceColors(primary: Colors.black),
            ),
            billingDetails: billingDetails,
          ),
        );

        await Stripe.instance.presentPaymentSheet();
      }

      final updateResponse = await http.put(
        Uri.parse('${widget.checkoutPayload.baseUrl}/api/v1/bookings/update/${widget.checkoutPayload.appointmentId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'paymentIntentId': paymentIntentId,
          'depositPaid': true,
          'status': 'PAID',
        }),
      );

      if (updateResponse.statusCode != 200) {
        final updateData = jsonDecode(updateResponse.body);
        throw Exception(updateData['message'] ?? 'Failed to update appointment payment status.');
      }

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚀 Payment successful & booking confirmed!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        _showSnackBar('Payment cancelled.');
      } else {
        _showSnackBar('❌ Payment Error: ${e.error.localizedMessage}');
      }
    } catch (err) {
      if (!mounted) return;
      _showSnackBar('❌ Error: ${err.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatFormattedDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return "${months[dt.month - 1]} ${dt.day}, ${dt.year}, ${hour.toString().padLeft(2, '0')}:$minuteStr $amPm";
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.checkoutPayload;
    final payLater = payload.totalAmount - payload.depositAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Checkout', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderSummaryCard(payload, payLater),
                const SizedBox(height: 20),
                _buildPaymentMethodSelector(),
                const SizedBox(height: 16),
                if (_selectedMethod == PaymentMethodType.creditCard) ...[
                  _buildCreditCardForm(),
                  const SizedBox(height: 24),
                  _buildBillingAddressForm(),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting ? null : _submitCardPayment,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Pay \$${payload.depositAmount.toStringAsFixed(2)} Now',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(CardCheckoutPayload payload, double payLater) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order summary (1 item)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 50,
                  height: 50,
                  color: Colors.amber.shade100,
                  child: const Icon(Icons.pets, color: Colors.brown, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display Service Name if available (e.g. payload.serviceTitle)
                    if (payload.serviceName != null && payload.serviceName!.isNotEmpty) ...[
                      Text(
                        payload.serviceName!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      payload.variantTitle,
                      style: TextStyle(
                        fontWeight: payload.serviceName != null ? FontWeight.w500 : FontWeight.w600,
                        fontSize: 14,
                        color: payload.serviceName != null ? Colors.grey.shade800 : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Deposit: \$${payload.depositAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    Text(_formatFormattedDate(payload.serviceTime), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    if (_showOrderDetails) ...[
                      const SizedBox(height: 4),
                      Text('Dog: ${payload.dogName} (${payload.dogBreed})', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      Text('Owner: ${payload.ownerName}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                    InkWell(
                      onTap: () => setState(() => _showOrderDetails = !_showOrderDetails),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Text(_showOrderDetails ? 'Show Less' : 'Show More', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            Icon(_showOrderDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade700),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text('\$${payload.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer_outlined, size: 18, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _promoCodeCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Enter a promo code',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: TextStyle(color: Colors.grey.shade700)),
              Text('\$${payload.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('\$${payload.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pay Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text('\$${payload.depositAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pay Later', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text('\$${payLater.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade300, width: 1.5),
      ),
      child: Column(
        children: [
          RadioListTile<PaymentMethodType>(
            value: PaymentMethodType.creditCard,
            groupValue: _selectedMethod,
            onChanged: (val) => setState(() => _selectedMethod = val!),
            activeColor: Colors.blue,
            title: Row(
              children: [
                const Icon(Icons.credit_card, size: 20),
                const SizedBox(width: 8),
                const Text('Credit/Debit Cards', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                Row(
                  children: [
                    _buildCardLogo('MC', Colors.red),
                    const SizedBox(width: 4),
                    _buildCardLogo('VISA', Colors.blue),
                    const SizedBox(width: 4),
                    _buildCardLogo('AMEX', Colors.cyan),
                  ],
                ),
              ],
            ),
          ),
          // Divider(height: 1, color: Colors.grey.shade200),
          // RadioListTile<PaymentMethodType>(
          //   value: PaymentMethodType.applePay,
          //   groupValue: _selectedMethod,
          //   onChanged: (val) => setState(() => _selectedMethod = val!),
          //   activeColor: Colors.blue,
          //   title: Row(
          //     children: [
          //       Container(
          //         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          //         decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
          //         child: const Text('Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          //       ),
          //       const SizedBox(width: 8),
          //       const Text('Apple Pay', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildCreditCardForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Card details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CardField(
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingAddressForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Billing address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('First name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _firstNameCtrl,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Last name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _lastNameCtrl,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Phone *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
        ),
        const SizedBox(height: 12),
        const Text('Country/Region *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedCountry,
          items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => setState(() => _selectedCountry = val!),
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCardLogo(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}