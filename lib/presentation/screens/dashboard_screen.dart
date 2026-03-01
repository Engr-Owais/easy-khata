import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/entry_model.dart';
import '../../domain/entities/entry.dart';
import '../providers/customer_provider.dart';
import '../providers/entry_provider.dart';
import '../providers/theme_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  double _getBalance(String customerId, List<Entry> entries) {
    return entries
        .where((e) => e.customerId == customerId)
        .fold(0.0, (sum, e) => e.type == 'gave' ? sum + e.amount : sum - e.amount);
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final customers = ref.read(customersProvider).valueOrNull ?? [];
      final entries = ref.read(entriesProvider).valueOrNull ?? [];

      final data = {
        'customers': customers
            .map((c) => CustomerModel.fromEntity(c).toMap())
            .toList(),
        'entries': entries
            .map((e) => EntryModel.fromEntity(e).toMap())
            .toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/easy_khata_backup.json');
      await file.writeAsString(jsonEncode(data));

      await Share.shareXFiles([XFile(file.path)], text: 'Easy Khata Backup');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final customers = (data['customers'] as List)
          .map((c) => CustomerModel.fromMap(c as Map<String, dynamic>))
          .toList();
      final entries = (data['entries'] as List)
          .map((e) => EntryModel.fromMap(e as Map<String, dynamic>))
          .toList();

      await ref.read(customersProvider.notifier).replaceAll(customers);
      await ref.read(entriesProvider.notifier).replaceAll(entries);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup imported successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final entriesAsync = ref.watch(entriesProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Easy Khata',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                key: ValueKey(isDark),
              ),
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'export') _exportBackup(context, ref);
              if (val == 'import') _importBackup(context, ref);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Export Backup')),
              PopupMenuItem(value: 'import', child: Text('Import Backup')),
            ],
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1035),
                    const Color(0xFF0D1B2A),
                    const Color(0xFF0A1628),
                  ]
                : [
                    const Color(0xFF6C63FF),
                    const Color(0xFF9C7FF7),
                    const Color(0xFF00BCD4),
                  ],
          ),
        ),
        child: SafeArea(
          child: customersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (customers) => entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                double totalToReceive = 0;
                double totalToPay = 0;

                for (final customer in customers) {
                  final bal = _getBalance(customer.id, entries);
                  if (bal > 0) totalToReceive += bal;
                  if (bal < 0) totalToPay += bal.abs();
                }

                final net = totalToReceive - totalToPay;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lottie Header
                      Center(
                        child: SizedBox(
                          height: 160,
                          child: _buildLottie('assets/animations/header.json'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Summary',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GlassCard(
                              gradientColors: [
                                AppTheme.gave.withValues(alpha: 0.3),
                                AppTheme.gave.withValues(alpha: 0.1),
                              ],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.arrow_upward, color: Colors.green, size: 28),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'To Receive',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${NumberFormat('#,##,###.##').format(totalToReceive)}',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassCard(
                              gradientColors: [
                                AppTheme.received.withValues(alpha: 0.3),
                                AppTheme.received.withValues(alpha: 0.1),
                              ],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.arrow_downward, color: Colors.redAccent, size: 28),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'To Pay',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${NumberFormat('#,##,###.##').format(totalToPay)}',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        gradientColors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Net Balance',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹${NumberFormat('#,##,###.##').format(net.abs())}',
                              style: TextStyle(
                                color: net >= 0 ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GlassCard(
                              onTap: () => context.go('/customers'),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.people, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Customers',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${customers.length} total',
                                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassCard(
                              onTap: () => context.go('/add-customer'),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondary.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.person_add, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Add Customer',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                  const Text(
                                    'New entry',
                                    style: TextStyle(color: Colors.white60, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (customers.isNotEmpty) ...[
                        Text(
                          'Recent Customers',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...customers.take(5).map((customer) {
                          final balance = _getBalance(customer.id, entries);
                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 8),
                            onTap: () => context.go('/customers/${customer.id}'),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primary.withValues(alpha: 0.4),
                                  child: Text(
                                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    customer.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  '₹${NumberFormat('#,##,###.##').format(balance.abs())}',
                                  style: TextStyle(
                                    color: balance >= 0 ? Colors.greenAccent : Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
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
        errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
      );
    } catch (_) {
      return _fallbackIcon();
    }
  }

  Widget _fallbackIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.account_balance_wallet, size: 60, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(height: 8),
        Text(
          'Easy Khata',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
