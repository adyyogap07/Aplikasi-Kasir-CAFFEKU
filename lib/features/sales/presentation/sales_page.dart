import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart' hide Border; // Atasi impor ambigu
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
// PERBAIKAN: Menggunakan package open_file_plus yang lebih modern
import 'package:open_file/open_file.dart'; 
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

import '../../../config/api_config.dart';
import '../../../providers/global_provider.dart';
import '../domain/sales_order_simple_model.dart';
import '../presentation/sales_order_provider.dart';
import '../../checkout/utils/receipt_printer.dart';


//--- DEFINISI PROVIDER ---
final dateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  return DateTimeRange(start: startOfMonth, end: now);
});

final filteredSalesProvider = Provider<List<SimpleOrder>>((ref) {
  final dateRange = ref.watch(dateRangeProvider);
  final allOrdersState = ref.watch(allSalesOrdersProvider);

  return allOrdersState.when(
    data: (orders) => orders.where((order) {
      final orderDate = order.createdAt.toLocal();
      final startDate = dateRange.start;
      final endDate = dateRange.end;
      final cleanOrderDate = DateTime(orderDate.year, orderDate.month, orderDate.day);
      final cleanStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final cleanEndDate = DateTime(endDate.year, endDate.month, endDate.day);
      return !cleanOrderDate.isBefore(cleanStartDate) && !cleanOrderDate.isAfter(cleanEndDate);
    }).toList(),
    loading: () => [],
    error: (e, st) => [],
  );
});

// Provider ini bertugas mengambil SEMUA data order sekali saja.
final allSalesOrdersProvider = FutureProvider<List<SimpleOrder>>((ref) async {
  return ref.watch(salesOrderProvider.future);
});


//--- UI WIDGETS ---

class SalesPage extends ConsumerWidget {
  const SalesPage({super.key});

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final initialRange = ref.read(dateRangeProvider);
    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initialRange,
      locale: const Locale('id', 'ID'),
    );
    if (newRange != null) {
      ref.read(dateRangeProvider.notifier).state = newRange;
    }
  }
  
  void _showExportOptions(BuildContext context, List<SimpleOrder> orders, DateTimeRange range) {
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk diekspor.')));
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Ekspor ke PDF'),
            onTap: () {
              Navigator.pop(ctx);
              _exportToPdf(context, orders, range);
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Ekspor ke Excel'),
            onTap: () {
              Navigator.pop(ctx);
              _exportToExcel(context, orders, range);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(dateRangeProvider);
    final filteredOrders = ref.watch(filteredSalesProvider);
    final allOrdersState = ref.watch(allSalesOrdersProvider);
    
    final totalPendapatan = filteredOrders.fold<double>(0, (sum, order) => sum + order.totalPrice);
    final totalTransaksi = filteredOrders.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportOptions(context, filteredOrders, dateRange),
            tooltip: 'Ekspor Laporan',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(allSalesOrdersProvider.future),
        child: Column(
          children: [
            InkWell(
              onTap: () => _selectDateRange(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('d MMM y', 'id_ID').format(dateRange.start)} - ${DateFormat('d MMM y', 'id_ID').format(dateRange.end)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildSummaryCard('Total Pendapatan', NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(totalPendapatan)),
                  const SizedBox(width: 16),
                  _buildSummaryCard('Total Transaksi', totalTransaksi.toString()),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: allOrdersState.when(
                data: (_) {
                  if (filteredOrders.isEmpty) {
                    return const Center(child: Text('Tidak ada transaksi pada rentang tanggal ini.'));
                  }
                  return ListView.separated(
                    itemCount: filteredOrders.length,
                    separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return ListTile(
                        title: Text('Order #${order.id} - ${order.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('d MMM y, HH:mm', 'id_ID').format(order.createdAt.toLocal())),
                        trailing: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(order.totalPrice)),
                        onTap: () => _showOrderDetail(context, order),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard(String title, String value) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showOrderDetail(BuildContext context, SimpleOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Order #${order.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pelanggan: ${order.name}'),
            Text('Tanggal: ${DateFormat('d MMM y, HH:mm', 'id_ID').format(order.createdAt)}'),
            Text('Metode Bayar: ${order.paymentMethod.name}'),
            Text('Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(order.totalPrice)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // --- LOGIKA EKSPOR ---

  Future<void> _exportToPdf(BuildContext context, List<SimpleOrder> orders, DateTimeRange range) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('d MMM yyyy', 'id_ID');
      final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text('Laporan Penjualan - ${dateFormat.format(range.start)} s/d ${dateFormat.format(range.end)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)
              )
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Tanggal', 'No. Order', 'Pelanggan', 'Metode Bayar', 'Total'],
              data: orders.map((order) => [
                DateFormat('d/M/y').format(order.createdAt),
                '#${order.id}',
                order.name,
                order.paymentMethod.name,
                currencyFormat.format(order.totalPrice),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total Pendapatan: ${currencyFormat.format(orders.fold(0.0, (sum, item) => sum + item.totalPrice))}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)
              )
            )
          ],
        ),
      );
      
      final bytes = await pdf.save();
      await _saveAndOpenFile(context, bytes, 'Laporan-Penjualan-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf');
    } catch (e) {
      print("Error saat membuat PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat PDF: $e'))
      );
    }
  }

  Future<void> _exportToExcel(BuildContext context, List<SimpleOrder> orders, DateTimeRange range) async {
    try {
      final excel = Excel.createExcel();
      final Sheet sheet = excel[excel.getDefaultSheet()!];
      
      sheet.appendRow([TextCellValue('Laporan Penjualan')]);
      sheet.appendRow([TextCellValue('${DateFormat('d MMMM yyyy', 'id_ID').format(range.start)} - ${DateFormat('d MMMM yyyy', 'id_ID').format(range.end)}')]);
      sheet.appendRow([]); 

      sheet.appendRow([
        TextCellValue('Tanggal'), TextCellValue('No. Order'), TextCellValue('Pelanggan'),
        TextCellValue('Metode Bayar'), TextCellValue('Total'),
      ]);
      
      for (var order in orders) {
        sheet.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt)), 
          TextCellValue('#${order.id}'),
          TextCellValue(order.name), 
          TextCellValue(order.paymentMethod.name),
          DoubleCellValue(order.totalPrice.toDouble()),
        ]);
      }
      
      final fileBytes = excel.save();
      if (fileBytes != null) {
        await _saveAndOpenFile(context, fileBytes, 'Laporan-Penjualan-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.xlsx');
      } else {
        throw Exception('Gagal membuat file Excel');
      }
    } catch (e) {
      print("Error saat membuat Excel: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat Excel: $e'))
      );
    }
  }

  Future<void> _saveAndOpenFile(BuildContext context, List<int> bytes, String fileName) async {
    try {
      Directory? directory;
      
      if (Platform.isAndroid) {
        // Coba gunakan getApplicationDocumentsDirectory() dulu
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory == null) {
        throw Exception('Tidak dapat mengakses direktori penyimpanan');
      }
      
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      
      // Tampilkan snackbar sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File berhasil disimpan: $fileName'))
      );
      
      // Buka file
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        print("Error membuka file: ${result.message}");
      }
    } catch(e) {
      print("Error saat menyimpan file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan file: $e'))
      );
    }
  }
}
