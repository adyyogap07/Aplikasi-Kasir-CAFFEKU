import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Impor yang dibutuhkan
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/auth/presentation/login_page.dart';

void main() async {
  // Pastikan binding Flutter sudah siap sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi format tanggal untuk Bahasa Indonesia
  await initializeDateFormatting('id_ID', null); 
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Kasir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // --- PERBAIKAN: Menambahkan delegasi dan dukungan lokal ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Tambahkan dukungan untuk Bahasa Indonesia
      ],
      locale: const Locale('id', 'ID'), // Atur default locale
      //---------------------------------------------------------
      home: const LoginPage(),
    );
  }
}
