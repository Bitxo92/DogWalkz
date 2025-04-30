import 'package:dogwalkz/models/dog.dart';
import 'package:dogwalkz/models/walker.dart';
import 'customer.dart';

class Walk {
  final String id;
  final Customer? customer;
  final String customerId;
  final String? walkerId;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final double price;
  final double platformCommission;
  final double walkerEarnings;
  final String status;
  final String? paymentStatus;
  List<Dog> dogs;
  Walker? walker;
  final String location;
  final String city;

  Walk({
    required this.id,
    this.customer,
    required this.customerId,
    required this.walkerId,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.price,
    required this.platformCommission,
    required this.walkerEarnings,
    required this.status,
    this.paymentStatus,
    required this.dogs,
    this.walker,
    required this.location,
    required this.city,
  });

  factory Walk.fromJson(Map<String, dynamic> json) {
    // Parse dogs from walk_dogs relationship
    List<Dog> dogs = [];
    if (json['walk_dogs'] != null) {
      dogs =
          (json['walk_dogs'] as List)
              .map((wd) => Dog.fromJson(wd['dogs'] ?? {}))
              .toList();
    }

    // Parse customer
    Customer? customer =
        json['customers'] != null ? Customer.fromJson(json['customers']) : null;

    // Parse walker
    Walker? walker;
    if (json['walkers'] != null) {
      walker = Walker.fromJson({
        ...json['walkers'],
        ...?json['walkers']?['walker_profiles'],
      });
    }

    return Walk(
      id: json['id'],
      customer: customer,
      customerId: json['customer_id'],
      walkerId: json['walker_id'],
      scheduledStart: DateTime.parse(json['scheduled_start']),
      scheduledEnd: DateTime.parse(json['scheduled_end']),
      price: (json['price'] as num).toDouble(),
      platformCommission: (json['platform_commission'] as num).toDouble(),
      walkerEarnings: (json['walker_earnings'] as num).toDouble(),
      status: json['status'],
      paymentStatus: json['payment_status'],
      dogs: dogs,
      walker: walker,
      location: json['location'] ?? '',
      city: json['city'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'walker_id': walkerId,
      'scheduled_start': scheduledStart.toIso8601String(),
      'scheduled_end': scheduledEnd.toIso8601String(),
      'price': price,
      'platform_commission': platformCommission,
      'walker_earnings': walkerEarnings,
      'status': status,
      'payment_status': paymentStatus,
      'location': location,
      'city': city,
      'dogs': dogs.map((dog) => dog.toJson()).toList(),
      'walker': walker,
      'customer': customer?.toJson(),
    };
  }
}
