import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../kasir/presentation/kasir_controller.dart';
import '../../../providers/global_provider.dart';
import '../presentation/checkout_service.dart';
import '../domain/payment_method_model.dart';
import '../utils/receipt_printer.dart';
import '../../kasir/domain/order_item_model.dart'; // Pastikan path ini benar
import '../../../settings/presentation/printer_manager_page.dart';
import '../../sales/presentation/sales_order_provider.dart';
import '../../sales/presentation/sales_report_provider.dart';
import '../../sales/presentation/sales_page.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _paymentAmountController = TextEditingController();
  int _changeAmount = 0;

  int? _selectedPaymentMethod;
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = false;
  bool _isLoadingPaymentMethods = false;
  bool _isPrinterConnected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _loadPaymentMethods();
      _checkPrinterStatus();
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }

  String? _getValidToken() {
    try {
      final token = ref.read(authTokenProvider);
      if (token == null || token.isEmpty) throw Exception('Token tidak ditemukan.');
      return token.trim();
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoadingPaymentMethods = true;
      _errorMessage = null;
    });
    try {
      final token = _getValidToken();
      if (token == null) throw Exception('Token tidak tersedia. Silakan login ulang.');

      final result = await CheckoutService.fetchPaymentMethods(token);
      final filtered = result.where((e) => e.deletedAt == null).toList();

      if (mounted) {
        setState(() {
          _paymentMethods = filtered;
          if (filtered.isNotEmpty && _selectedPaymentMethod == null) {
            _selectedPaymentMethod = filtered.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingPaymentMethods = false);
    }
  }
  
  Future<void> _submitOrder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
       _showErrorSnackBar('Keranjang belanja Anda kosong.');
       return;
    }
    
    setState(() => _isLoading = true);
    
    final token = _getValidToken();
    if (token == null) {
      _showErrorSnackBar('Sesi Anda telah berakhir, silakan login kembali.');
      setState(() => _isLoading = false);
      return;
    }

    final totalPrice = ref.read(cartProvider.notifier).totalPrice;
    final paymentAmount = int.tryParse(_paymentAmountController.text) ?? 0;
    
    try {
      await CheckoutService.submitOrder(
        token: token,
        name: _nameController.text.trim(),
        paymentMethodId: _selectedPaymentMethod!,
        cart: cart,
        totalPrice: totalPrice,
        paymentAmount: paymentAmount,
      );
      
      final selectedMethod = _paymentMethods.firstWhere((m) => m.id == _selectedPaymentMethod);
      final receiptData = ReceiptData(
        customerName: _nameController.text.trim(),
        items: cart, // cart sudah berisi List<OrderItem>
        totalPrice: totalPrice,
        paymentAmount: paymentAmount,
        changeAmount: _changeAmount,
        paymentMethod: selectedMethod.name,
      );

      if (mounted) _showSuccessAndPrintDialog(receiptData);

    } catch (e) {
      _showErrorSnackBar('Gagal mengirim pesanan: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent)
    );
  }

  // Fungsi untuk refresh semua data yang terkait dengan transaksi
  void _refreshTransactionData() {
    // Refresh sales order data
    ref.invalidate(salesOrderProvider);
    ref.invalidate(allSalesOrdersProvider);
    
    // Refresh sales report data untuk grafik
    ref.invalidate(dailySalesReportProvider);
    ref.invalidate(salesReportProvider('daily'));
    ref.invalidate(salesReportProvider('monthly'));
    ref.invalidate(salesReportProvider('yearly'));
  }

  void _showSuccessAndPrintDialog(ReceiptData receiptData) async {
    bool isPrinterConnected = _isPrinterConnected;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.green.withOpacity(0.1),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Transaksi Berhasil!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(receiptData.totalPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Pelanggan: ${receiptData.customerName}', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  Text('Metode: ${receiptData.paymentMethod}', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isPrinterConnected ? Icons.print : Icons.print_disabled,
                  color: isPrinterConnected ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPrinterConnected ? 'Printer terhubung' : 'Printer tidak terhubung',
                    style: TextStyle(
                      color: isPrinterConnected ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          if (isPrinterConnected)
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await ReceiptPrinter.printReceipt(receiptData);
                  if (mounted) {
                    Navigator.of(context).pop();
                    ref.read(cartProvider.notifier).clearCart();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Struk berhasil dicetak'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _refreshTransactionData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Gagal mencetak: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.print),
              label: const Text('Cetak Struk'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrinterManagerPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Atur Printer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref.read(cartProvider.notifier).clearCart();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      _refreshTransactionData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Transaksi selesai tanpa struk'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Tanpa Struk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final totalPrice = cartNotifier.totalPrice;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        actions: [
          // Indikator status printer
          GestureDetector(
            onTap: _checkPrinterStatus,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isPrinterConnected ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPrinterConnected ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPrinterConnected ? Icons.print : Icons.print_disabled,
                    color: _isPrinterConnected ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isPrinterConnected ? 'Printer' : 'No Printer',
                    style: TextStyle(
                      color: _isPrinterConnected ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionCard(
              title: 'Informasi Pelanggan',
              child: TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Nama Pelanggan', Icons.person_outline),
                validator: (value) => (value == null || value.isEmpty) ? 'Nama tidak boleh kosong' : null,
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Ringkasan Pesanan',
              child: _buildOrderSummary(cart),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Metode Pembayaran',
              child: _buildPaymentMethodSelector(),
            ),
             const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Detail Pembayaran',
              child: Column(
                children: [
                   TextFormField(
                    controller: _paymentAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _inputDecoration('Jumlah Uang Diterima', Icons.money_outlined),
                    onChanged: (value) {
                      final paid = int.tryParse(value) ?? 0;
                      setState(() => _changeAmount = paid - totalPrice);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    'Total Belanja', 
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(totalPrice),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Uang Kembali', 
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(_changeAmount < 0 ? 0 : _changeAmount),
                    isHighlight: true
                  ),
                ],
              ),
            ),
             const SizedBox(height: 80), // Memberi ruang untuk bottom bar
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(totalPrice, theme),
    );
  }

  // --- WIDGET BUILDER HELPERS ---

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
  
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
  
  Widget _buildOrderSummary(List<OrderItem> cart) {
    if (cart.isEmpty) return const Text('Keranjang kosong.');
    return Column(
      children: cart.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('${item.quantity}x ${item.product.name}')),
            Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(item.product.price * item.quantity)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPaymentMethodSelector() {
    if (_isLoadingPaymentMethods) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red));

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _paymentMethods.map((method) {
        final isSelected = _selectedPaymentMethod == method.id;
        return ChoiceChip(
          label: Text(method.name),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedPaymentMethod = method.id);
            }
          },
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
          selectedColor: Theme.of(context).primaryColor,
          checkmarkColor: Colors.white,
        );
      }).toList(),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isHighlight = false}) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
      color: isHighlight ? Theme.of(context).primaryColor : null,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: style),
        Text(value, style: style),
      ],
    );
  }
  
  Widget _buildBottomBar(int totalPrice, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : const Text('Bayar Sekarang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // Fungsi untuk mengecek status printer
  Future<void> _checkPrinterStatus() async {
    try {
      bool isConnected = await ReceiptPrinter.isPrinterConnected();
      if (mounted) {
        setState(() {
          _isPrinterConnected = isConnected;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPrinterConnected = false;
        });
      }
    }
  }
}
