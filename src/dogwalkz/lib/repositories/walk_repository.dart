import 'package:dogwalkz/models/customer.dart';
import 'package:dogwalkz/models/walk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/walker.dart';
import '../models/dog.dart';

class WalkRepository {
  final SupabaseClient _supabase;
  static const double platformCommissionRate = 0.10;

  WalkRepository() : _supabase = Supabase.instance.client;

  /// Fetches available walkers based on the provided criteria.
  /// Returns a list of `Walker` objects that match the criteria.
  Future<List<Walker>> getAvailableWalkers({
    required String city,
    required DateTime startTime,
    required DateTime endTime,
    required bool needsLargeDogWalker,
    required bool needsDangerousBreedCertification,
    String? excludeUserId,
  }) async {
    try {
      final query = _supabase
          .from('users')
          .select('*, walker_profiles(*), address')
          .eq('is_walker', true)
          .eq('is_verified', true)
          .neq('id', excludeUserId ?? '')
          .textSearch('address->>city', city);

      final response = await query;
      List<Walker> walkers =
          (response as List)
              .where((json) {
                final profile = json['walker_profiles'];
                if (needsLargeDogWalker &&
                    !(profile['can_walk_large'] as bool)) {
                  return false;
                }
                if (needsDangerousBreedCertification &&
                    !(profile['has_dangerous_breed_certification'] as bool)) {
                  return false;
                }
                return true;
              })
              .map((json) {
                final address = json['address'] as Map<String, dynamic>?;
                final city = address?['city'] as String? ?? '';

                return Walker.fromJson({
                  ...json,
                  ...json['walker_profiles'],
                  'city': city,
                });
              })
              .toList();

      return walkers;
    } catch (e) {
      throw Exception('Failed to fetch walkers: $e');
    }
  }

  /// Fetches all dogs owned by a specific user.
  /// Returns a list of `Dog` objects owned by the user.
  Future<List<Dog>> getUserDogs(String userId) async {
    try {
      final response = await _supabase
          .from('dogs')
          .select()
          .eq('owner_id', userId);

      return (response as List).map((json) => Dog.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user dogs: $e');
    }
  }

  /// Fetches the wallet balance for a specific user.
  /// Returns the balance as a double.
  Future<double> getWalletBalance(String userId) async {
    try {
      final response =
          await _supabase
              .from('wallets')
              .select('balance')
              .eq('user_id', userId)
              .single();

      return (response['balance'] as num).toDouble();
    } catch (e) {
      throw Exception('Failed to get wallet balance: $e');
    }
  }

  /// Fetches all walks for a specific user.
  /// Returns a list of `Walk` objects associated with the user.
  Future<List<Walk>> getUserWalks(String userId) async {
    try {
      var response = await _supabase
          .from('walks')
          .select('''
          *,
          walk_dogs!fk_walk_dogs_walk(
            dogs!fk_walk_dogs_dog(*)
          ),
          walkers:users!fk_walks_walker(
            *,
            walker_profiles!fk_walker_profiles_user(*)
          ),
           customers:users!fk_walks_customer(*),
           review:reviews!fk_reviews_walk(*)
        ''')
          .or('customer_id.eq.$userId,walker_id.eq.$userId')
          .order('scheduled_start', ascending: true);

      print("Response: $response"); // Log response for debugging error

      if (response.isEmpty) {
        return []; // Return an empty list if no walks found
      }

      return (response as List).map((walkJson) {
        // Parse dogs through walk_dogs relationship
        List<Dog> walkDogs = [];
        if (walkJson['walk_dogs'] != null) {
          walkDogs =
              (walkJson['walk_dogs'] as List)
                  .map((wd) {
                    if (wd['dogs'] != null) {
                      return Dog.fromJson(wd['dogs']);
                    }
                    return null;
                  })
                  .whereType<Dog>()
                  .toList();
        }

        // Parse walker information
        Walker? walker;
        final walkerJson = walkJson['walkers'];
        if (walkerJson != null) {
          walker = Walker.fromJson({
            ...walkerJson,
            ...walkerJson['walker_profiles'] ?? {},
          });
        }

        // Parse review
        int? rating;
        String? reviewComment;

        if (walkJson['review'] != null && walkJson['review'] is Map) {
          rating = walkJson['review']['rating'] as int?;
          reviewComment = walkJson['review']['comment'] as String?;
        }

        final customerJson = walkJson['customers'];
        Customer? customer;
        if (customerJson != null) {
          customer = Customer.fromJson(customerJson);
        }

        // Return Walk model with parsed data
        return Walk.fromJson({
          ...walkJson,
          'dogs': walkDogs,
          'walker': walker,
          'customer': customer,
          'rating': rating,
          'reviewComment': reviewComment,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch user walks: $e');
    }
  }

  /// Schedules a new walk for a customer.
  /// Returns the ID of the newly created walk.
  Future<String> scheduleWalk({
    required String customerId,
    required String? walkerId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required double totalPrice,
    required List<String> dogIds,
    required String location,
    required String city,
  }) async {
    try {
      final platformCommission = totalPrice * platformCommissionRate;
      final walkerEarnings = totalPrice - platformCommission;

      final walkResponse =
          await _supabase
              .from('walks')
              .insert({
                'customer_id': customerId,
                'walker_id': walkerId,
                'scheduled_start': scheduledStart.toIso8601String(),
                'scheduled_end': scheduledEnd.toIso8601String(),
                'price': totalPrice,
                'platform_commission': platformCommission,
                'walker_earnings': walkerEarnings,
                'status': 'requested',
                'payment_status': 'pending',
                'city': city,
              })
              .select('id')
              .single();

      if (walkResponse.isEmpty) throw Exception('Failed to create walk');

      final walkId = walkResponse['id'] as String;

      for (final dogId in dogIds) {
        await _supabase.from('walk_dogs').insert({
          'walk_id': walkId,
          'dog_id': dogId,
        });
      }

      await _supabase.rpc(
        'process_walk_payment',
        params: {
          'p_customer_id': customerId,
          'p_walk_id': walkId,
          'p_amount': totalPrice,
        },
      );
      return walkId;
    } catch (e) {
      throw Exception('Failed to schedule walk: $e');
    }
  }

  /// Track walker's location during a walk
  Future<void> trackWalkerLocation({
    required String walkId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Check if location already exists
      final existingLocation =
          await _supabase
              .from('walk_locations')
              .select()
              .eq('walk_id', walkId)
              .maybeSingle();

      if (existingLocation == null) {
        // Insert new location
        await _supabase.from('walk_locations').insert({
          'walk_id': walkId,
          'latitude': latitude,
          'longitude': longitude,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Update existing location
        await _supabase
            .from('walk_locations')
            .update({
              'latitude': latitude,
              'longitude': longitude,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('walk_id', walkId);
      }
    } catch (e) {
      throw Exception('Failed to track walker location: $e');
    }
  }

  /// Get current walker location for a walk
  Future<Map<String, dynamic>?> getWalkerLocation(String walkId) async {
    try {
      final response =
          await _supabase
              .from('walk_locations')
              .select()
              .eq('walk_id', walkId)
              .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get walker location: $e');
    }
  }

  Future<bool> checkWalkersExistInCity(String city) async {
    final response =
        await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('is_walker', true)
            .eq('is_verified', true)
            .ilike('address->>city', city)
            .limit(1)
            .maybeSingle();

    return response != null;
  }
}
