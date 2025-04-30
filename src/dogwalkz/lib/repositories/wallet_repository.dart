import 'package:supabase_flutter/supabase_flutter.dart';

class WalletRepository {
  final SupabaseClient _supabase;

  WalletRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Retrieves the wallet information for a given user.
  Future<Map<String, dynamic>> getWallet(String userId) async {
    final response =
        await _supabase
            .from('wallets')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

    return response ?? {};
  }

  /// Retrieves the transaction history for a given wallet.
  Future<List<Map<String, dynamic>>> getTransactions(String walletId) async {
    final response = await _supabase
        .from('wallet_transactions')
        .select()
        .eq('wallet_id', walletId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  //// Adds funds to a given wallet and records the transaction.
  Future<void> addFunds({
    required String userId,
    required String walletId,
    required double amount,
    String description = 'Deposit',
  }) async {
    // Update wallet balance
    await _supabase
        .from('wallets')
        .update({
          'balance': await _getCurrentBalance(walletId) + amount,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', walletId);

    // Record transaction
    await _supabase.from('wallet_transactions').insert({
      'wallet_id': walletId,
      'amount': amount,
      'transaction_type': 'deposit',
      'status': 'completed',
      'description': description,
    });
  }

  /// Withdraws funds from a given wallet and records the transaction.
  Future<void> withdrawFunds({
    required String userId,
    required String walletId,
    required double amount,
    String description = 'Withdrawal',
  }) async {
    // Update wallet balance
    await _supabase
        .from('wallets')
        .update({
          'balance': await _getCurrentBalance(walletId) - amount,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', walletId);

    // Record transaction
    await _supabase.from('wallet_transactions').insert({
      'wallet_id': walletId,
      'amount': amount,
      'transaction_type': 'withdrawal',
      'status': 'completed',
      'description': description,
    });
  }

  /// Retrieves the current balance of a given wallet.
  ///
  /// This method queries the 'wallets' table to get the balance of the wallet
  /// with the specified ID. It returns the balance as a double.
  Future<double> _getCurrentBalance(String walletId) async {
    final response =
        await _supabase
            .from('wallets')
            .select('balance')
            .eq('id', walletId)
            .single();

    return (response['balance'] as num).toDouble();
  }

  /// Ensures that a wallet exists for a given user and returns its ID.
  Future<String> ensureWalletExists(String userId) async {
    final existingWallet = await getWallet(userId);
    if (existingWallet.isNotEmpty) {
      return existingWallet['id'] as String;
    }

    final newWallet =
        await _supabase.from('wallets').insert({
          'user_id': userId,
          'balance': 0.0,
        }).select();

    return newWallet.first['id'] as String;
  }
}
