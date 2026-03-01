import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../domain/entities/entry.dart';
import '../providers/entry_provider.dart';
import '../providers/theme_provider.dart';

class AddEditEntryScreen extends ConsumerStatefulWidget {
  final String? customerId;
  final String? entryId;

  const AddEditEntryScreen({super.key, this.customerId, this.entryId});

  @override
  ConsumerState<AddEditEntryScreen> createState() => _AddEditEntryScreenState();
}

class _AddEditEntryScreenState extends ConsumerState<AddEditEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = 'gave';
  DateTime _date = DateTime.now();
  bool _isLoading = false;
  bool _showSuccess = false;
  bool _initialized = false;
  String? _resolvedCustomerId;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _initFromEntry(Entry entry) {
    if (!_initialized) {
      _type = entry.type;
      _amountController.text = entry.amount.toString();
      _noteController.text = entry.note;
      _date = entry.date;
      _resolvedCustomerId = entry.customerId;
      _initialized = true;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final custId = widget.customerId ?? _resolvedCustomerId;
    if (custId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer not found')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.trim());
      final isEdit = widget.entryId != null;

      if (isEdit) {
        final entries = ref.read(entriesProvider).valueOrNull ?? [];
        final existing = entries.firstWhere((e) => e.id == widget.entryId!);
        final updated = existing.copyWith(
          type: _type,
          amount: amount,
          note: _noteController.text.trim(),
          date: _date,
        );
        await ref.read(entriesProvider.notifier).update(updated);
      } else {
        final entry = Entry(
          id: const Uuid().v4(),
          customerId: custId,
          type: _type,
          amount: amount,
          note: _noteController.text.trim(),
          date: _date,
        );
        await ref.read(entriesProvider.notifier).add(entry);
      }

      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/customers/$custId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final isEdit = widget.entryId != null;

    if (isEdit) {
      entriesAsync.whenData((entries) {
        final entry = entries.where((e) => e.id == widget.entryId).firstOrNull;
        if (entry != null) _initFromEntry(entry);
      });
    }

    if (_showSuccess) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1A1035), const Color(0xFF0D1B2A)]
                  : [const Color(0xFF6C63FF), const Color(0xFF00BCD4)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200,
                  child: _buildSuccessLottie(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Entry Saved!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Entry' : 'Add Entry',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final custId = widget.customerId ?? _resolvedCustomerId;
            if (custId != null) {
              context.go('/customers/$custId');
            } else {
              context.go('/customers');
            }
          },
        ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Type Toggle
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Entry Type',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _type = 'gave'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: _type == 'gave'
                                        ? AppTheme.gave.withValues(alpha: 0.7)
                                        : Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _type == 'gave' ? AppTheme.gave : Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        color: _type == 'gave' ? Colors.white : Colors.white54,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Gave',
                                        style: TextStyle(
                                          color: _type == 'gave' ? Colors.white : Colors.white54,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _type = 'received'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: _type == 'received'
                                        ? AppTheme.received.withValues(alpha: 0.7)
                                        : Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _type == 'received' ? AppTheme.received : Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.arrow_downward,
                                        color: _type == 'received' ? Colors.white : Colors.white54,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Received',
                                        style: TextStyle(
                                          color: _type == 'received' ? Colors.white : Colors.white54,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Entry Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Amount is required';
                            if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                            if (double.parse(v.trim()) <= 0) return 'Amount must be greater than 0';
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Amount *',
                            hintText: '0.00',
                            labelStyle: const TextStyle(color: Colors.white70),
                            hintStyle: const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(Icons.currency_rupee, color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.white, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.redAccent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Date', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text(
                                      DateFormat('d MMMM yyyy').format(_date),
                                      style: const TextStyle(color: Colors.white, fontSize: 15),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right, color: Colors.white54),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _noteController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Note (optional)',
                            hintText: 'Add a note...',
                            labelStyle: const TextStyle(color: Colors.white70),
                            hintStyle: const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(Icons.note_alt, color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: GlassButton(
                      label: isEdit ? 'Update Entry' : 'Save Entry',
                      icon: Icons.save,
                      onPressed: _save,
                      isLoading: _isLoading,
                      color: _type == 'gave' ? AppTheme.gave : AppTheme.received,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessLottie() {
    try {
      return Lottie.asset(
        'assets/animations/success.json',
        repeat: false,
        errorBuilder: (context, error, stackTrace) => _successFallback(),
      );
    } catch (_) {
      return _successFallback();
    }
  }

  Widget _successFallback() {
    return const Icon(Icons.check_circle, color: Colors.greenAccent, size: 80);
  }
}
