import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Pastikan semua path impor ini benar sesuai struktur proyek Anda
import '../product/presentation/product_page.dart';
import '../kasir/presentation/kasir_page.dart';
import '../sales/presentation/sales_page.dart';
import '../sales/presentation/sales_report_provider.dart';
import '../sales/presentation/sales_order_provider.dart';
import '../../../providers/global_provider.dart';
import '../auth/presentation/login_page.dart';
import '../../settings/presentation/printer_manager_page.dart';

//--- WIDGET GRAFIK PENJUALAN YANG DIDESAİN ULANG ---
class SalesReportChart extends ConsumerWidget {
  const SalesReportChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(dailySalesReportProvider);
    final Color primaryColor = Theme.of(context).primaryColor;
    final List<Color> gradientColors = [
      primaryColor,
      Colors.cyan.shade300,
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pendapatan 7 Hari Terakhir',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: reportState.when(
                data: (sales) {
                  if (sales.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Belum ada data penjualan', 
                               style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    );
                  }
                  
                  final spots = sales.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.total);
                  }).toList();

                  return LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= sales.length) return const SizedBox();
                              final label = sales[value.toInt()].label;
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(label,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    )),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: LinearGradient(colors: gradientColors),
                          barWidth: 5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: gradientColors.map((color) => color.withOpacity(0.3)).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Memuat data...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text('Gagal memuat grafik:\n$error', 
                             style: const TextStyle(color: Colors.red), 
                             textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//--- WIDGET STATISTIK HARI INI ---
class TodayStatistics extends ConsumerWidget {
  const TodayStatistics({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOrdersState = ref.watch(allSalesOrdersProvider);
    
    return allOrdersState.when(
      data: (orders) {
        final today = DateTime.now();
        final todayOrders = orders.where((order) {
          final orderDate = order.createdAt;
          return orderDate.year == today.year &&
                 orderDate.month == today.month &&
                 orderDate.day == today.day;
        }).toList();
        
        final todayTransactions = todayOrders.length;
        final todayRevenue = todayOrders.fold<int>(0, (sum, order) => sum + order.totalPrice);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik Hari Ini',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.shopping_cart,
                    label: 'Transaksi',
                    value: todayTransactions.toString(),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.attach_money,
                    label: 'Pendapatan',
                    value: NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(todayRevenue),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Hari Ini',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(context, icon: Icons.shopping_cart, label: 'Transaksi', value: '...', color: Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, icon: Icons.attach_money, label: 'Pendapatan', value: '...', color: Colors.green)),
            ],
          ),
        ],
      ),
      error: (error, stack) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Hari Ini',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(context, icon: Icons.shopping_cart, label: 'Transaksi', value: 'Error', color: Colors.red)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, icon: Icons.attach_money, label: 'Pendapatan', value: 'Error', color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//--- HALAMAN UTAMA ---
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late PageController _pageController;
  int _currentPage = 0;
  
  // Daftar halaman yang bisa di-swipe
  final List<Widget> _pages = [
    const KasirPage(),
    const ProductPage(),
    const SalesPage(),
    const PrinterManagerPage(),
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _pageController = PageController();
    
    // Refresh data dan mulai animasi
    Future.microtask(() => ref.refresh(dailySalesReportProvider));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // PERBAIKAN: Fungsi untuk navigasi dengan animasi geser
  void _navigateToPageWithSlide(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // Fungsi untuk menangani perubahan halaman
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  // Fungsi untuk navigasi ke halaman tertentu
  void _navigateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    void logout() {
      ref.read(authTokenProvider.notifier).state = null;
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => const LoginPage()), 
        (route) => false
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: _buildBottomNavBar(context),
      body: Column(
        children: [
          // AppBar tetap
          Container(
            color: primaryColor,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Text(
                      'Kasir Pintar', 
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 20, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white), 
                      onPressed: logout, 
                      tooltip: 'Logout'
                    ),
                  ],
                ),
              ),
            ),
          ),
          // PageView untuk swipe navigation
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                // Halaman Home (Dashboard)
                RefreshIndicator(
                  onRefresh: () => ref.refresh(dailySalesReportProvider.future),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24), 
                              bottomRight: Radius.circular(24)
                            ),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Datang!', 
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold
                                )
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Semoga harimu menyenangkan!', 
                                style: TextStyle(
                                  color: Colors.white70, 
                                  fontSize: 16
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: const SalesReportChart(),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                children: [
                                  const SizedBox(height: 16),
                                  _buildQuickActions(context),
                                  const SizedBox(height: 16),
                                  const TodayStatistics(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                ),
                // Halaman lainnya
                ..._pages,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context, 
            icon: Icons.home_outlined, 
            label: 'Home', 
            isSelected: _currentPage == 0,
            onTap: () => _navigateToPage(0),
          ),
          _buildNavItem(
            context, 
            icon: Icons.point_of_sale_outlined, 
            label: 'Kasir', 
            isSelected: _currentPage == 1,
            onTap: () => _navigateToPage(1),
          ),
          _buildNavItem(
            context, 
            icon: Icons.inventory_2_outlined, 
            label: 'Produk', 
            isSelected: _currentPage == 2,
            onTap: () => _navigateToPage(2),
          ),
          _buildNavItem(
            context, 
            icon: Icons.analytics_outlined, 
            label: 'Laporan', 
            isSelected: _currentPage == 3,
            onTap: () => _navigateToPage(3),
          ),
          _buildNavItem(
            context, 
            icon: Icons.print_outlined, 
            label: 'Printer', 
            isSelected: _currentPage == 4,
            onTap: () => _navigateToPage(4),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700], 
              size: 24
            ),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(
                fontSize: 10, 
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aksi Cepat',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionItem(
                    context,
                    icon: Icons.add_shopping_cart,
                    label: 'Transaksi Baru',
                    color: Colors.blue,
                    onTap: () => _navigateToPage(1), // Navigate ke Kasir
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionItem(
                    context,
                    icon: Icons.add_box,
                    label: 'Tambah Produk',
                    color: Colors.green,
                    onTap: () => _navigateToPage(2), // Navigate ke Produk
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
