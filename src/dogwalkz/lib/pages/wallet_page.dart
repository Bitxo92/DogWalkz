import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/wallet_repository.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  /// button's text.import 'package:font_awesome_flutter/font_awesome_flutter.dart';
  void _showAddFundsDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isAddingFunds,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.addFunds,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                                fontSize: 20,
                              ),
                            ),
                            Padding(padding: const EdgeInsets.only(left: 8)),
                            Icon(
                              FontAwesomeIcons.piggyBank,
                              color: Colors.brown,
                              size: 20,
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.addFundsDialog,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.amount,
                            prefixIcon: Icon(
                              FontAwesomeIcons.dollarSign,
                              color: Colors.brown,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.brown),
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed:
                            _isAddingFunds
                                ? null
                                : () => Navigator.of(context).pop(),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            _isAddingFunds
                                ? null
                                : () async {
                                  setState(() => _isAddingFunds = true);
                                  await _addFunds();
                                  setState(() => _isAddingFunds = false);
                                  Navigator.of(context).pop();
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(AppLocalizations.of(context)!.add),
                      ),
                    ],
                  ),

                  if (_isAddingFunds)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black38,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.brown),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
    );
  }

  /// Shows a dialog to withdraw funds from the user's wallet.
  void _showWithdrawFundsDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_iswithdrawingFunds,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.withdraw,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade700,
                                fontSize: 20,
                              ),
                            ),
                            Padding(padding: const EdgeInsets.only(left: 8)),
                            Icon(
                              FontAwesomeIcons.moneyBillTransfer,
                              color: Colors.brown.shade700,
                              size: 20,
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.withdrawFundsDialog,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.amount,
                            prefixIcon: Icon(
                              FontAwesomeIcons.dollarSign,
                              color: Colors.brown,
                              size: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.brown,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed:
                            _iswithdrawingFunds
                                ? null
                                : () => Navigator.of(context).pop(),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            _iswithdrawingFunds
                                ? null
                                : () async {
                                  setState(() => _iswithdrawingFunds = true);
                                  await _withdrawFunds();
                                  setState(() => _iswithdrawingFunds = false);
                                  Navigator.of(context).pop();
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(AppLocalizations.of(context)!.withdraw),
                      ),
                    ],
                  ),

                  if (_iswithdrawingFunds)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black38,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.brown),
                        ),
                      ),
                    ),
                ],
              );
            },
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

  /// Returns an Icon based on the transaction type.
  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'deposit':
        return FontAwesomeIcons.piggyBank;
      case 'withdrawal':
        return FontAwesomeIcons.moneyBillTransfer;
      case 'payment':
        return FontAwesomeIcons.moneyBill1Wave;
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
        body: Center(child: CircularProgressIndicator(color: Colors.brown)),
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
        child: Container(
          padding: const EdgeInsets.all(16),
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
                    Padding(
                      padding: const EdgeInsets.only(right: 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _showAddFundsDialog,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    FontAwesomeIcons.piggyBank,
                                    color: Colors.brown,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(context)!.addFunds,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _showWithdrawFundsDialog,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    FontAwesomeIcons.moneyBillTransfer,
                                    color: Colors.brown,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(context)!.withdraw,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

              Expanded(
                child:
                    _filteredTransactions.isEmpty
                        ? _buildEmptyState()
                        : _buildTransactionsList(),
              ),
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
        shrinkWrap: false,
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: _filteredTransactions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final transaction = _filteredTransactions[index];
          final amount = (transaction['amount'] as num).toDouble();
          final type = transaction['transaction_type'] as String;
          final date = DateTime.parse(transaction['created_at'] as String);
          final description = _getTransactionDescription(transaction);

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
            trailing: SizedBox(
              height: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${type == 'deposit' || type == 'refund' || type == 'payment' ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getTransactionColor(type),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: transaction['id'].toString()),
                      );
                    },
                    child: Icon(
                      Icons.copy,
                      size: 16,
                      color: Colors.brown.shade300,
                    ),
                  ),
                ],
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

  /// Returns a string description in the corresponding language based on the transactions type.
  String _getTransactionDescription(Map<String, dynamic> transaction) {
    switch (transaction['transaction_type']) {
      case 'deposit':
        return '${AppLocalizations.of(context)!.deposit} ${transaction['id'].toString()}';
      case 'withdrawal':
        return '${AppLocalizations.of(context)!.withdrawal} ${transaction['id'].toString()}';
      case 'payment':
        return '${AppLocalizations.of(context)!.payment} ${transaction['id'].toString()}';
      case 'refund':
        return '${AppLocalizations.of(context)!.cancelationRefund} ${transaction['id'].toString()}';
      case 'charge':
        return '${AppLocalizations.of(context)!.charge} ${transaction['id'].toString()}';
      default:
        return AppLocalizations.of(context)!.transaction;
    }
  }
}
