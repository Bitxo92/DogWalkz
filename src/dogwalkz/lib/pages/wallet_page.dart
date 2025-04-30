import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/wallet_repository.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final _walletRepository = WalletRepository();
  final _amountController = TextEditingController();
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  double _balance = 0.0;
  bool _isLoading = true;
  bool _isAddingFunds = false;
  bool _iswithdrawingFunds = false;
  String? _walletId;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  /// Loads the user's wallet data and updates the state with the balance and
  /// transactions.
  ///
  /// This method loads the user's wallet data from the database and updates the
  /// state with the balance and transactions. It also applies the currently
  /// selected filter to the transactions.
  Future<void> _loadWalletData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      _walletId = await _walletRepository.ensureWalletExists(userId);

      final wallet = await _walletRepository.getWallet(userId);
      final transactions = await _walletRepository.getTransactions(_walletId!);

      setState(() {
        _balance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;
        _transactions = transactions;
        _applyFilter();
      });
    } catch (e) {
      debugPrint('Error loading wallet data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Applies the selected date filter to the list of transactions.
  ///
  /// This method updates the `_filteredTransactions` list by filtering
  /// `_transactions` based on the `_selectedFilter` value. The available
  /// filters are:
  ///
  /// - 'week': Includes transactions from the last 7 days.
  /// - 'month': Includes transactions from the last 30 days.
  /// - 'halfYear': Includes transactions from the last 180 days.
  /// - 'all': Includes all transactions regardless of the date.
  ///
  /// The method uses the current date to determine the filtering
  /// criteria and updates the state to reflect the changes.

  void _applyFilter() {
    final now = DateTime.now();
    final beginningOfWeek = now.subtract(
      Duration(days: now.weekday % 7),
    ); // Sunday as start of the week

    setState(() {
      _filteredTransactions =
          _transactions.where((transaction) {
            final date = DateTime.parse(transaction['created_at'] as String);

            switch (_selectedFilter) {
              case 'week':
                return date.isAfter(beginningOfWeek);
              case 'month':
                return date.isAfter(DateTime(now.year, now.month - 1, now.day));
              case 'halfYear':
                return date.isAfter(DateTime(now.year, now.month - 6, now.day));
              case 'all':
              default:
                return true;
            }
          }).toList();
    });
  }

  /// Adds the specified amount of funds to the user's wallet.
  /// Parses the text in the [_amountController] to a double. If the parsing
  /// Then sets the [_isAddingFunds] state variable to true and calls the
  /// [_walletRepository.addFunds] method to add the funds to the wallet.
  ///
  /// If the call succeeds, it reloads the wallet data by calling
  /// [_loadWalletData] and pops the dialog.
  ///
  /// If the call fails, it prints the error message.
  /// Finally, it sets the [_isAddingFunds] state variable back to false.
  Future<void> _addFunds() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      debugPrint('Invalid amount: $amount');

      return;
    }

    setState(() => _isAddingFunds = true);
    try {
      await _walletRepository.addFunds(
        userId: Supabase.instance.client.auth.currentUser!.id,
        walletId: _walletId!,
        amount: amount,
      );

      await _loadWalletData();
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error adding funds: $e');
    } finally {
      setState(() => _isAddingFunds = false);
    }
  }

  /// Withdraws the specified amount of funds from the user's wallet.
  Future<void> _withdrawFunds() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount > _balance || amount <= 0) {
      debugPrint('Invalid amount: $amount');

      return;
    }

    setState(() => _iswithdrawingFunds = true);
    try {
      await _walletRepository.withdrawFunds(
        userId: Supabase.instance.client.auth.currentUser!.id,
        walletId: _walletId!,
        amount: amount,
      );

      await _loadWalletData();
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error withdrawing funds: $e');
    } finally {
      setState(() => _iswithdrawingFunds = false);
    }
  }

  /// Shows a dialog to add funds to the user's wallet.
  ///
  /// The dialog contains a text field to input the amount of funds to add,
  /// a cancel button, and an add button. When the add button is pressed,
  /// the [_addFunds] method is called to add the funds to the wallet.
  ///
  /// If the [_isAddingFunds] state variable is true, the add button is
  /// disabled and a circular progress indicator is shown instead of the
  /// button's text.
  void _showAddFundsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.addFundsDialog),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.amount,
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: _isAddingFunds ? null : _addFunds,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child:
                    _isAddingFunds
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(AppLocalizations.of(context)!.add),
              ),
            ],
          ),
    );
  }

  /// Shows a dialog to withdraw funds from the user's wallet.
  void _showWithdrawFundsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.withdrawFundsDialog),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.amount,
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: _iswithdrawingFunds ? null : _withdrawFunds,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child:
                    _iswithdrawingFunds
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(AppLocalizations.of(context)!.withdraw),
              ),
            ],
          ),
    );
  }

  /// Returns a [Color] based on the transaction type.
  ///
  /// This method interprets the transaction type and returns a specific color:
  /// - Green for 'deposit' and 'refund'.
  /// - Red for 'withdrawal' and 'payment'.
  /// - Brown as default for other transaction types.

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'deposit':
      case 'refund':
      case 'payment':
        return Colors.green;
      case 'withdrawal':
      case 'charge':
        return Colors.red;
      default:
        return Colors.brown;
    }
  }

  /// Returns an [IconData] based on the transaction type.
  ///
  /// This method interprets the transaction type and returns a specific icon:
  /// - [Ionicons.add_outline] for 'deposit'.
  /// - [Ionicons.remove_outline] for 'withdrawal'.
  /// - [Ionicons.walk_outline] for 'payment'.
  /// - [Ionicons.arrow_undo_outline] for 'refund'.
  /// - [Ionicons.business_outline] for 'commission'.
  /// - [Ionicons.wallet_outline] for other transaction types.
  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'deposit':
        return Ionicons.add_outline;
      case 'withdrawal':
        return Ionicons.remove_outline;
      case 'payment':
        return Ionicons.walk_outline;
      case 'refund':
        return Ionicons.arrow_undo_outline;
      case 'commission':
        return Ionicons.business_outline;
      default:
        return Ionicons.wallet_outline;
    }
  }

  /// Builds the widget tree for the wallet page.
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5E9D9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5E9D9),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.wallet,
          style: TextStyle(
            fontFamily: GoogleFonts.comicNeue().fontFamily,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown,
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back_outline),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Ionicons.wallet_outline,
                      size: 40,
                      color: Colors.brown,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.walletBalance,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '\$${_balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 100,
                          child: TextButton(
                            onPressed: _showAddFundsDialog,
                            child: Text(
                              AppLocalizations.of(context)!.addFunds,
                              style: TextStyle(color: Colors.brown),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: TextButton(
                            onPressed: _showWithdrawFundsDialog,
                            child: Text(
                              AppLocalizations.of(context)!.withdraw,
                              style: TextStyle(color: Colors.brown),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.recentTransactions,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_transactions.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(AppLocalizations.of(context)!.all),
                        selected: _selectedFilter == 'all',
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = 'all';
                            _applyFilter();
                          });
                        },
                        selectedColor: Colors.brown.withOpacity(0.2),
                        checkmarkColor: Colors.brown,
                        labelStyle: TextStyle(
                          color:
                              _selectedFilter == 'all'
                                  ? Colors.brown
                                  : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(AppLocalizations.of(context)!.thisWeek),
                        selected: _selectedFilter == 'week',
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = 'week';
                            _applyFilter();
                          });
                        },
                        selectedColor: Colors.brown.withOpacity(0.2),
                        checkmarkColor: Colors.brown,
                        labelStyle: TextStyle(
                          color:
                              _selectedFilter == 'week'
                                  ? Colors.brown
                                  : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(AppLocalizations.of(context)!.thisMonth),
                        selected: _selectedFilter == 'month',
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = 'month';
                            _applyFilter();
                          });
                        },
                        selectedColor: Colors.brown.withOpacity(0.2),
                        checkmarkColor: Colors.brown,
                        labelStyle: TextStyle(
                          color:
                              _selectedFilter == 'month'
                                  ? Colors.brown
                                  : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(AppLocalizations.of(context)!.last6Months),
                        selected: _selectedFilter == 'halfYear',
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = 'halfYear';
                            _applyFilter();
                          });
                        },
                        selectedColor: Colors.brown.withOpacity(0.2),
                        checkmarkColor: Colors.brown,
                        labelStyle: TextStyle(
                          color:
                              _selectedFilter == 'halfYear'
                                  ? Colors.brown
                                  : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),

              if (_filteredTransactions.isEmpty)
                _buildEmptyState()
              else
                _buildTransactionsList(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns a widget that displays a message when no transactions are found
  /// that match the selected filter.
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Ionicons.wallet_outline, size: 60, color: Colors.brown.shade200),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noTransactionsFound,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// Builds a widget that displays a list of filtered transactions.
  Widget _buildTransactionsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredTransactions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final transaction = _filteredTransactions[index];
          final amount = (transaction['amount'] as num).toDouble();
          final type = transaction['transaction_type'] as String;
          final date = DateTime.parse(transaction['created_at'] as String);
          final description =
              transaction['description'] as String? ??
              AppLocalizations.of(context)!.transaction;

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTransactionColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getTransactionIcon(type),
                color: _getTransactionColor(type),
              ),
            ),
            title: Text(
              description,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.brown.shade800,
              ),
            ),
            subtitle: Text(
              '${date.day}/${date.month}/${date.year}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: Text(
              '${type == 'deposit' || type == 'refund' || type == 'payment' ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getTransactionColor(type),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Releases the resources used by the [_amountController],
  /// and calls super.dispose().
  ///
  /// This method should be called when this object is no longer needed.
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
