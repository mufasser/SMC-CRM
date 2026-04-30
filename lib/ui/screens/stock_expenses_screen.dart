import 'package:flutter/material.dart';

import '../../data/models/stock_expense_model.dart';
import '../../data/services/crm_service.dart';
import '../widgets/uk_reg_plate.dart';

class StockExpensesScreen extends StatefulWidget {
  final String stockId;
  final String title;
  final String registration;

  const StockExpensesScreen({
    super.key,
    required this.stockId,
    required this.title,
    required this.registration,
  });

  @override
  State<StockExpensesScreen> createState() => _StockExpensesScreenState();
}

class _StockExpensesScreenState extends State<StockExpensesScreen> {
  final CRMService _crmService = CRMService();

  List<StockExpenseModel> _expenses = [];
  StockExpenseSummary _summary = const StockExpenseSummary(
    totalExpenseAmount: 0,
    expenseCount: 0,
    currencyCode: 'GBP',
  );
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = await _crmService.fetchStockExpenses(widget.stockId);

    if (!mounted) {
      return;
    }

    if (data == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load expenses right now.';
      });
      return;
    }

    setState(() {
      _expenses = data.expenses
        ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      _summary = data.summary;
      _isLoading = false;
    });
  }

  Future<void> _openExpenseSheet({StockExpenseModel? expense}) async {
    final result = await showModalBottomSheet<_ExpenseDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExpenseSheet(
        initialExpense: expense,
        currencyCode: _summary.currencyCode,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'title': result.title,
      'amount': result.amount,
      'currencyCode': result.currencyCode,
      'expenseDate': _formatApiDate(result.expenseDate),
    };

    final response = expense == null
        ? await _crmService.createStockExpense(
            stockId: widget.stockId,
            payload: payload,
          )
        : await _crmService.updateStockExpense(
            stockId: widget.stockId,
            expenseId: expense.id,
            payload: payload,
          );

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response['message']?.toString() ??
              (expense == null ? 'Expense added.' : 'Expense updated.'),
        ),
      ),
    );

    if (response['success'] == true) {
      _loadExpenses();
    }
  }

  Future<void> _deleteExpense(StockExpenseModel expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Remove "${expense.title}" from this stock item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    setState(() => _isSaving = true);

    final response = await _crmService.deleteStockExpense(
      stockId: widget.stockId,
      expenseId: expense.id,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response['message']?.toString() ?? 'Expense deleted successfully.',
        ),
      ),
    );

    if (response['success'] == true) {
      _loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandYellow = Color(0xFFFACC14);
    const brandBlack = Color(0xFF000000);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F1),
      appBar: AppBar(
        backgroundColor: brandYellow,
        foregroundColor: brandBlack,
        title: const Text(
          'Stock Expenses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : () => _openExpenseSheet(),
            icon: const Icon(Icons.add_shopping_cart_outlined),
            tooltip: 'Add Expense',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: brandYellow))
          : _errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _loadExpenses,
              color: Colors.black,
              backgroundColor: brandYellow,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        children: [
                          _buildHeaderCard(),
                          const SizedBox(height: 16),
                          _buildSummaryStrip(),
                          const SizedBox(height: 18),
                          _buildSectionHeader(),
                        ],
                      ),
                    ),
                  ),
                  if (_expenses.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverList.separated(
                        itemCount: _expenses.length,
                        itemBuilder: (context, index) {
                          final expense = _expenses[index];
                          return _ExpenseCard(
                            expense: expense,
                            currencySymbol: _currencySymbol(expense.currencyCode),
                            onEdit: () => _openExpenseSheet(expense: expense),
                            onDelete: () => _deleteExpense(expense),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Expense',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_currencySymbol(_summary.currencyCode)}${_summary.totalExpenseAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _openExpenseSheet(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlack,
                  foregroundColor: brandYellow,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: brandYellow,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(_isSaving ? 'Saving...' : 'Add Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    const brandYellow = Color(0xFFFACC14);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD84D),
            Color(0xFFF4BF18),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    UkRegPlate(reg: widget.registration, fontSize: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_summary.expenseCount} items',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Track repairs, prep costs, and profit-impacting spend for this vehicle.',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.shopping_cart_checkout_rounded,
              size: 34,
              color: brandYellow.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStrip() {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Expense Count',
            value: _summary.expenseCount.toString(),
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryTile(
            label: 'Currency',
            value: _currencySymbol(_summary.currencyCode),
            icon: Icons.currency_exchange_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Expense Basket',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Each entry updates the running cost of this stock item.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC14).withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 42,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No expenses added yet',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add the first cost for this stock item and it will appear here with the running total below.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], height: 1.5),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openExpenseSheet(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: const Color(0xFFFACC14),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add First Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        const Icon(Icons.receipt_long_outlined, size: 46, color: Colors.grey),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _errorMessage ?? 'Something went wrong',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: _loadExpenses,
            child: const Text('Try Again'),
          ),
        ),
      ],
    );
  }

  String _currencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'GBP':
        return '£';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return '$currencyCode ';
    }
  }

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _ExpenseCard extends StatelessWidget {
  final StockExpenseModel expense;
  final String currencySymbol;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.currencySymbol,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFACC14).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _displayDate(expense.expenseDate),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currencySymbol${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.redAccent,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _displayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}

class _ExpenseDraft {
  final String title;
  final double amount;
  final String currencyCode;
  final DateTime expenseDate;

  const _ExpenseDraft({
    required this.title,
    required this.amount,
    required this.currencyCode,
    required this.expenseDate,
  });
}

class _ExpenseSheet extends StatefulWidget {
  final StockExpenseModel? initialExpense;
  final String currencyCode;

  const _ExpenseSheet({
    required this.initialExpense,
    required this.currencyCode,
  });

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late DateTime _expenseDate;

  bool get _isEditMode => widget.initialExpense != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialExpense?.title ?? '',
    );
    _amountController = TextEditingController(
      text: widget.initialExpense?.amount.toStringAsFixed(2) ?? '',
    );
    _expenseDate = widget.initialExpense?.expenseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      _ExpenseDraft(
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        currencyCode: widget.currencyCode,
        expenseDate: _expenseDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _isEditMode ? 'Edit Expense' : 'Add Expense',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Title',
                      hintText: 'Wheel repair',
                    ),
                    validator: (value) {
                      if ((value?.trim() ?? '').isEmpty) {
                        return 'Expense title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: '95',
                      prefixText: _currencySymbol(widget.currencyCode),
                    ),
                    validator: (value) {
                      final amount = double.tryParse((value ?? '').trim());
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Expense Date',
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18),
                          const SizedBox(width: 10),
                          Text(_displayDate(_expenseDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isEditMode ? 'Save Changes' : 'Save Expense'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _currencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'GBP':
        return '£';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return '$currencyCode ';
    }
  }

  static String _displayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
