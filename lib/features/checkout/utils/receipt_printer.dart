import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
// import 'package:blue_print_pos/blue_print_pos.dart'; // Removed
import '../../sales/domain/sales_order_simple_model.dart';
import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../kasir/domain/order_item_model.dart'; // Import OrderItem

class ReceiptPrinter {
  static final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  static Future<void> printOrder(
    SimpleOrder order, {
    String toko = 'Cafeku',
    String alamat = 'Jl. Mojoroto gang 5 barat',
    String telp = '081529620211',
    String linkSaran = 'olshopin.com/f/748488',
    int? bayar,
    int? kembali,
    String? nomorOrder,
  }) async {
    throw UnimplementedError('Receipt printing is not available.');
  }

  // Fungsi untuk mengecek status koneksi printer
  static Future<bool> isPrinterConnected() async {
    try {
      bool? isConnected = await _bluetooth.isConnected;
      return isConnected == true;
    } catch (e) {
      return false;
    }
  }

  // Fungsi untuk mencetak struk dengan pengecekan koneksi
  static Future<void> printReceipt(ReceiptData receiptData) async {
    // Cek koneksi printer terlebih dahulu
    bool isConnected = await isPrinterConnected();
    if (!isConnected) {
      throw Exception(
          'Printer tidak terhubung. Silakan hubungkan printer terlebih dahulu di menu Pengaturan Printer.');
    }

    try {
      final printer = BluetoothReceiptPrinter();
      await printer.printReceipt(receiptData);
    } catch (e) {
      throw Exception('Gagal mencetak struk: $e');
    }
  }
}

// Model untuk menampung data yang akan dicetak
@immutable
class ReceiptData {
  final String customerName;
  final List<OrderItem> items; // Ubah dari CartItem ke OrderItem
  final int totalPrice;
  final int paymentAmount;
  final int changeAmount;
  final String paymentMethod;
  final String cashierName; // Opsional, bisa diisi nama user yang login

  const ReceiptData({
    required this.customerName,
    required this.items,
    required this.totalPrice,
    required this.paymentAmount,
    required this.changeAmount,
    required this.paymentMethod,
    this.cashierName = 'Kasir',
  });
}

class BluetoothReceiptPrinter {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  // Fungsi untuk memformat angka menjadi format mata uang Rupiah
  String _formatCurrency(int amount) {
    final format =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  // Fungsi utama untuk mencetak struk
  Future<void> printReceipt(ReceiptData data) async {
    // Cek koneksi printer
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) {
      // Jika tidak terhubung, coba hubungkan ke perangkat pertama yang ditemukan
      // Dalam aplikasi nyata, Anda harus membuat UI untuk memilih printer
      try {
        List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
        if (devices.isNotEmpty) {
          await bluetooth.connect(devices.first);
        } else {
          throw Exception("Tidak ada printer Bluetooth yang ter-pairing.");
        }
      } catch (e) {
        throw Exception("Gagal terhubung ke printer: $e");
      }
    }

    // Mulai proses pencetakan
    // ESC/POS commands
    // 0: Normal, 1: Tebal, 2: Tinggi, 3: Tinggi & Tebal
    // 0: Kiri, 1: Tengah, 2: Kanan

    bluetooth.printCustom("CAFEEKUU", 3, 1);
    bluetooth.printCustom(
        "Jalan Mojorot No. 12 Gang 5 Barat, Kota Kediri", 1, 1);
    bluetooth.printCustom("Telp: 081234567890", 1, 1);
    bluetooth.printNewLine();

    // Informasi Transaksi
    String dateTime = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    bluetooth.printLeftRight("Waktu:", dateTime, 1);
    bluetooth.printLeftRight("Kasir:", data.cashierName, 1);
    bluetooth.printLeftRight("Pelanggan:", data.customerName, 1);
    bluetooth.printCustom("--------------------------------", 1, 1);

    // Daftar item
    for (var item in data.items) {
      String itemName = item.product.name;
      // Batasi panjang nama item agar tidak overflow
      if (itemName.length > 20) {
        itemName = itemName.substring(0, 20);
      }
      String itemPrice = _formatCurrency(item.product.price * item.quantity);
      String qty = '${item.quantity}x';

      bluetooth.printLeftRight("$qty $itemName", itemPrice, 1);
    }
    bluetooth.printCustom("--------------------------------", 1, 1);

    // Total
    bluetooth.printLeftRight("Total", _formatCurrency(data.totalPrice), 2);
    bluetooth.printLeftRight("Bayar (${data.paymentMethod})",
        _formatCurrency(data.paymentAmount), 1);
    bluetooth.printLeftRight("Kembali", _formatCurrency(data.changeAmount), 1);
    bluetooth.printNewLine();

    // Pesan penutup
    bluetooth.printCustom("Terima Kasih!", 2, 1);
    bluetooth.printCustom("Sudah Datang di Cafe kami", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();

    // Paper cut command (jika printer mendukung)
    bluetooth.paperCut();
  }
}
