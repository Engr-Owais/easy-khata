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

class CustomerLedgerScreen extends ConsumerStatefulWidget {
  final String customerId;
  const CustomerLedgerScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends ConsumerState<CustomerLedgerScreen> {
  String _filter = 'all';

  double _getBalance(List<Entry> entries) {
    return entries.fold(
        0.0, (sum, e) => e.type == 'gave' ? sum + e.amount : sum - e.amount);
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final entriesAsync = ref.watch(entriesProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: customersAsync.when(
          data: (customers) {
            final customer = customers.where((c) => c.id == widget.customerId).firstOrNull;
            return Text(customer?.name ?? 'Ledger', style: const TextStyle(fontWeight: FontWeight.bold));
          },
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Ledger'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/customers'),
        ),
        actions: [
          customersAsync.when(
            data: (customers) {
              final customer = customers.where((c) => c.id == widget.customerId).firstOrNull;
              if (customer == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/edit-customer/${widget.customerId}'),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/customers/${widget.customerId}/add-entry'),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
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
          child: entriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
            data: (allEntries) {
              final custEntries = allEntries
                  .where((e) => e.customerId == widget.customerId)
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

              final balance = _getBalance(custEntries);

              final filteredEntries = _filter == 'all'
                  ? custEntries
                  : custEntries.where((e) => e.type == _filter).toList();

              return Column(
                children: [
                  // Balance card
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GlassCard(
                      gradientColors: [
                        (balance >= 0 ? AppTheme.gave : AppTheme.received).withValues(alpha: 0.3),
                        (balance >= 0 ? AppTheme.gave : AppTheme.received).withValues(alpha: 0.1),
                      ],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Balance',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                balance >= 0 ? 'To Receive' : 'To Pay',
                                style: TextStyle(
                                  color: balance >= 0 ? Colors.greenAccent : Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₹${NumberFormat('#,##,###.##').format(balance.abs())}',
                            style: TextStyle(
                              color: balance >= 0 ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Filter chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          value: 'all',
                          selected: _filter == 'all',
                          onTap: () => setState(() => _filter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Gave',
                          value: 'gave',
                          selected: _filter == 'gave',
                          onTap: () => setState(() => _filter = 'gave'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Received',
                          value: 'received',
                          selected: _filter == 'received',
                          onTap: () => setState(() => _filter = 'received'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: filteredEntries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 160,
                                  child: _buildLottie('assets/animations/empty.json'),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No entries yet',
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                                const Text(
                                  'Tap + to add an entry',
                                  style: TextStyle(color: Colors.white54, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredEntries.length,
                            itemBuilder: (context, index) {
                              final entry = filteredEntries[index];
                              return Dismissible(
                                key: Key(entry.id),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) async {
                                  await ref.read(entriesProvider.notifier).delete(entry.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Entry deleted'),
                                        action: SnackBarAction(
                                          label: 'Undo',
                                          onPressed: () async {
                                            await ref.read(entriesProvider.notifier).add(entry);
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: GlassCard(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  gradientColors: [
                                    (entry.isGave ? AppTheme.gave : AppTheme.received).withValues(alpha: 0.2),
                                    (entry.isGave ? AppTheme.gave : AppTheme.received).withValues(alpha: 0.05),
                                  ],
                                  onTap: () => context.go('/entries/${entry.id}/edit'),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: (entry.isGave ? AppTheme.gave : AppTheme.received).withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          entry.isGave ? Icons.arrow_upward : Icons.arrow_downward,
                                          color: entry.isGave ? Colors.greenAccent : Colors.redAccent,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.isGave ? 'Gave' : 'Received',
                                              style: TextStyle(
                                                color: entry.isGave ? Colors.greenAccent : Colors.redAccent,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (entry.note.isNotEmpty)
                                              Text(
                                                entry.note,
                                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            Text(
                                              DateFormat('d MMM yyyy').format(entry.date),
                                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₹${NumberFormat('#,##,###.##').format(entry.amount)}',
                                        style: TextStyle(
                                          color: entry.isGave ? Colors.greenAccent : Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
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
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white.withValues(alpha: 0.5)),
      );
    } catch (_) {
      return Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white.withValues(alpha: 0.5));
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
