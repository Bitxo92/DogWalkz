import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WalletRepository {
  final SupabaseClient _supabase;
  final String _stripeSecretKey;
  final String _stripePublishableKey;

  WalletRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client,
      _stripeSecretKey = dotenv.env['STRIPE_SECRET_KEY'] ?? '',
      _stripePublishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '' {
    Stripe.publishableKey = _stripePublishableKey;
  }

  Future<Map<String, dynamic>> _createPaymentIntent(
    double amount,
    String currency,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).toStringAsFixed(0), // Amount in cents
          'currency': currency.toLowerCase(),
        },
      );

      return Map<String, dynamic>.from(json.decode(response.body));
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  /// Processes a Stripe payment and adds funds to the wallet
  Future<void> processStripePayment({
    required String userId,
    required String walletId,
    required double amount,
    required BuildContext context,
  }) async {
    try {
      // 1. Create payment intent on Stripe
      final paymentIntent = await _createPaymentIntent(amount, 'USD');

      // 2. Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'DogWalkz',
          style: ThemeMode.light,
        ),
      );

      // 3. Display payment sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. If payment is successful, add funds to wallet
      await addFunds(
        userId: userId,
        walletId: walletId,
        amount: amount,
        description: 'Stripe deposit',
      );
    } on StripeException catch (e) {
      throw Exception('Payment failed: ${e.error.localizedMessage}');
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }

  /// Creates a payout to user's bank account via Stripe
  Future<void> processWithdrawal({
    required String userId,
    required String walletId,
    required double amount,
    required String stripeAccountId, // User's connected Stripe account ID
  }) async {
    try {
      // 1. Verify sufficient balance
      final balance = await _getCurrentBalance(walletId);
      if (balance < amount) {
        throw Exception('Insufficient funds');
      }

      // 2. Create payout
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payouts'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).toStringAsFixed(0),
          'currency': 'usd',
          'destination': stripeAccountId,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create payout: ${response.body}');
      }

      // 3. If payout is successful, withdraw funds from wallet
      await withdrawFunds(
        userId: userId,
        walletId: walletId,
        amount: amount,
        description: 'Stripe withdrawal',
      );
    } catch (e) {
      throw Exception('Withdrawal failed: $e');
    }
  }

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
    isRefund = false,
    required double amount,
    String description = 'deposit',
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
      'transaction_type': isRefund ? 'refund' : 'deposit',
      'status': 'completed',
      'description': description,
    });
  }

  /// Withdraws funds from a given wallet and records the transaction.
  Future<void> withdrawFunds({
    required String userId,
    required String walletId,
    required double amount,
    String description = 'withdrawal',
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
