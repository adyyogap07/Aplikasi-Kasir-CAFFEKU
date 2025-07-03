import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class PrinterManagerPage extends StatefulWidget {
  const PrinterManagerPage({super.key});

  @override
  State<PrinterManagerPage> createState() => _PrinterManagerPageState();
}

class _PrinterManagerPageState extends State<PrinterManagerPage> {
  // Instance dari package bluetooth
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  // List untuk menampung perangkat yang sudah di-pairing
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isLoading = false;
  bool _isConnected = false;
  bool _isBluetoothEnabled = false;
  String _connectionStatus = 'Tidak Terhubung';

  @override
  void initState() {
    super.initState();
    _initializePrinter();
  }

  // Fungsi untuk inisialisasi printer
  Future<void> _initializePrinter() async {
    try {
      // Cek status koneksi saat halaman dibuka
      bool? isConnected = await bluetooth.isConnected;
      setState(() {
        _isConnected = isConnected ?? false;
        _connectionStatus = _isConnected ? 'Terhubung' : 'Tidak Terhubung';
      });

      // Jika sudah terhubung, coba dapatkan device yang terhubung
      if (_isConnected) {
        await _getConnectedDevice();
      }
      
      // Cek status Bluetooth setelah inisialisasi
      await _checkBluetoothStatus();
    } catch (e) {
      setState(() {
        _isBluetoothEnabled = false;
      });
      _showSnackBar('Error saat inisialisasi: $e', isError: true);
    }
  }

  // Fungsi untuk mengecek status Bluetooth
  Future<void> _checkBluetoothStatus() async {
    try {
      // Coba akses Bluetooth untuk mengecek apakah aktif
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      setState(() {
        _isBluetoothEnabled = true;
      });
    } catch (e) {
      setState(() {
        _isBluetoothEnabled = false;
      });
      // Tidak perlu show snackbar di sini karena ini hanya pengecekan awal
    }
  }

  // Fungsi untuk mendapatkan device yang sedang terhubung
  Future<void> _getConnectedDevice() async {
    try {
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      // Coba cari device yang sedang terhubung
      for (var device in devices) {
        try {
          // Cek apakah device ini yang sedang terhubung
          bool? isConnected = await bluetooth.isConnected;
          if (isConnected == true) {
            setState(() {
              _selectedDevice = device;
            });
            break;
          }
        } catch (e) {
          // Lanjut ke device berikutnya
          continue;
        }
      }
    } catch (e) {
      print('Error getting connected device: $e');
    }
  }

  // Fungsi untuk mendapatkan daftar perangkat yang sudah di-pairing
  Future<void> _getDevices() async {
    if (!_isBluetoothEnabled) {
      _showSnackBar('Bluetooth belum diaktifkan. Silakan aktifkan Bluetooth terlebih dahulu.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      setState(() {
        _devices = devices;
      });
      
      if (devices.isEmpty) {
        _showSnackBar('Tidak ada printer yang ter-pairing. Silakan pairing printer terlebih dahulu.', isError: true);
      } else {
        _showSnackBar('Ditemukan ${devices.length} perangkat ter-pairing');
      }
    } catch (e) {
      setState(() {
        _isBluetoothEnabled = false;
      });
      _showSnackBar('Error: Gagal mendapatkan perangkat. Pastikan Bluetooth aktif. $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Fungsi untuk menghubungkan ke perangkat yang dipilih
  Future<void> _connect() async {
    if (_selectedDevice == null) {
      _showSnackBar('Pilih perangkat terlebih dahulu', isError: true);
      return;
    }
    
    if (!_isBluetoothEnabled) {
      _showSnackBar('Bluetooth belum diaktifkan', isError: true);
      return;
    }
    
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Menghubungkan...';
    });

    try {
      await bluetooth.connect(_selectedDevice!);
      
      // Tunggu sebentar untuk memastikan koneksi berhasil
      await Future.delayed(const Duration(seconds: 2));
      
      bool? isConnected = await bluetooth.isConnected;
      setState(() {
        _isConnected = isConnected ?? false;
        _connectionStatus = _isConnected ? 'Terhubung' : 'Gagal Terhubung';
      });
      
      if (_isConnected) {
        _showSnackBar('Berhasil terhubung ke ${_selectedDevice!.name}');
      } else {
        _showSnackBar('Gagal terhubung ke ${_selectedDevice!.name}', isError: true);
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Error Koneksi';
      });
      _showSnackBar('Error: Gagal terhubung. $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Fungsi untuk memutuskan koneksi
  Future<void> _disconnect() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Memutuskan...';
    });

    try {
      await bluetooth.disconnect();
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Tidak Terhubung';
        _selectedDevice = null;
      });
      _showSnackBar('Koneksi berhasil diputuskan');
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error';
      });
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // Fungsi untuk melakukan tes cetak
  Future<void> _testPrint() async {
    if (!_isConnected) {
      _showSnackBar('Printer tidak terhubung', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Test print dengan format yang lebih lengkap
      bluetooth.printCustom("=== TES CETAK ===", 2, 1); // Size 3 (Besar), Align 1 (Tengah)
      bluetooth.printNewLine();
      bluetooth.printCustom("Aplikasi Kasir Pintar", 1, 1); // Size 2 (Sedang), Align 1 (Tengah)
      bluetooth.printNewLine();
      bluetooth.printCustom("Tanggal: ${DateTime.now().toString().substring(0, 19)}", 1, 0); // Size 1 (Kecil), Align 0 (Kiri)
      bluetooth.printNewLine();
      bluetooth.printCustom("Status: Printer Terhubung", 1, 0);
      bluetooth.printNewLine();
      bluetooth.printCustom("Device: ${_selectedDevice?.name ?? 'Unknown'}", 1, 0);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.printCustom("=== SELESAI ===", 2, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();
      
      _showSnackBar('Test cetak berhasil dikirim ke printer');
    } catch (e) {
      _showSnackBar('Error saat test cetak: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Fungsi helper untuk menampilkan snackbar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  // Fungsi untuk refresh status Bluetooth
  Future<void> _refreshBluetoothStatus() async {
    setState(() => _isLoading = true);
    try {
      // Coba akses Bluetooth untuk mengecek status
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      setState(() {
        _isBluetoothEnabled = true;
      });
      _showSnackBar('Bluetooth siap digunakan');
    } catch (e) {
      setState(() {
        _isBluetoothEnabled = false;
      });
      _showSnackBar('Bluetooth tidak tersedia atau belum diaktifkan: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tambahkan judul custom
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: const Text(
                'Pengaturan Printer',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header status printer
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            _isConnected ? Icons.print : Icons.print_disabled,
                            color: _isConnected ? Colors.green : Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isConnected ? 'Printer Terhubung' : 'Printer Tidak Terhubung',
                            style: TextStyle(
                              color: _isConnected ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedDevice?.name ?? '-',
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                          if (_selectedDevice != null)
                            Text(
                              _selectedDevice!.address ?? '',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            'Status: $_connectionStatus',
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Status Bluetooth
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            _isBluetoothEnabled ? Icons.bluetooth : Icons.bluetooth_disabled,
                            color: _isBluetoothEnabled ? Colors.blue : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bluetooth',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  _isBluetoothEnabled ? 'Siap Digunakan' : 'Belum Diaktifkan',
                                  style: TextStyle(
                                    color: _isBluetoothEnabled ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _isLoading ? null : _refreshBluetoothStatus,
                            icon: _isLoading 
                              ? const SizedBox(
                                  width: 16, 
                                  height: 16, 
                                  child: CircularProgressIndicator(strokeWidth: 2)
                                )
                              : const Icon(Icons.refresh),
                            tooltip: 'Refresh Status Bluetooth',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tombol Cari Perangkat
                  ElevatedButton.icon(
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('Cari Printer Terpasang'),
                    onPressed: _isLoading ? null : _getDevices,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Daftar printer
                  if (_isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_devices.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pilih Printer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<BluetoothDevice>(
                              value: _selectedDevice,
                              hint: const Text('Pilih Printer'),
                              onChanged: (device) {
                                setState(() {
                                  _selectedDevice = device;
                                });
                              },
                              items: _devices.map((device) {
                                return DropdownMenuItem(
                                  value: device,
                                  child: Text(device.name ?? 'Unknown Device'),
                                );
                              }).toList(),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Tombol aksi koneksi
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedDevice == null || _isLoading || !_isBluetoothEnabled ? null : _connect,
                          icon: const Icon(Icons.link),
                          label: const Text('Hubungkan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isConnected && !_isLoading ? _disconnect : null,
                          icon: const Icon(Icons.link_off),
                          label: const Text('Putuskan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Tombol Test Cetak
                  ElevatedButton.icon(
                    onPressed: _isConnected && !_isLoading ? _testPrint : null,
                    icon: const Icon(Icons.print),
                    label: const Text('Tes Cetak'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
