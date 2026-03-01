import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../domain/entities/entry.dart';
import '../providers/customer_provider.dart';
import '../providers/entry_provider.dart';
import '../providers/theme_provider.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _getBalance(String customerId, List<Entry> entries) {
    return entries
        .where((e) => e.customerId == customerId)
        .fold(0.0, (sum, e) => e.type == 'gave' ? sum + e.amount : sum - e.amount);
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final entriesAsync = ref.watch(entriesProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Customers', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/add-customer'),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1035), const Color(0xFF0D1B2A)]
                : [const Color(0xFF6C63FF), const Color(0xFF00BCD4)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search customers...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              Expanded(
                child: customersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
                  data: (customers) => entriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                    error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
                    data: (entries) {
                      final filtered = customers
                          .where((c) => c.name.toLowerCase().contains(_searchQuery) ||
                              c.phone.toLowerCase().contains(_searchQuery))
                          .toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 180,
                                child: _buildLottie('assets/animations/empty.json'),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty ? 'No customers yet' : 'No customers found',
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                              if (_searchQuery.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Tap + to add your first customer',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final customer = filtered[index];
                          final balance = _getBalance(customer.id, entries);
                          final custEntries = entries.where((e) => e.customerId == customer.id).toList();
                          final lastActivity = custEntries.isNotEmpty
                              ? custEntries.first.date
                              : customer.createdAt;

                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 10),
                            onTap: () => context.go('/customers/${customer.id}'),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.primary.withValues(alpha: 0.4),
                                  child: Text(
                                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (customer.phone.isNotEmpty)
                                        Text(
                                          customer.phone,
                                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                                        ),
                                      Text(
                                        'Last: ${DateFormat('d MMM yyyy').format(lastActivity)}',
                                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${NumberFormat('#,##,###.##').format(balance.abs())}',
                                      style: TextStyle(
                                        color: balance >= 0 ? Colors.greenAccent : Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      balance > 0 ? 'To receive' : balance < 0 ? 'To pay' : 'Settled',
                                      style: TextStyle(
                                        color: balance >= 0 ? Colors.green[300] : Colors.red[300],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLottie(String assetPath) {
    try {
      return Lottie.asset(
        assetPath,
        repeat: true,
        errorBuilder: (context, error, stackTrace) => _fallbackEmpty(),
      );
    } catch (_) {
      return _fallbackEmpty();
    }
  }

  Widget _fallbackEmpty() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline, size: 64, color: Colors.white.withValues(alpha: 0.5)),
      ],
    );
  }
}
