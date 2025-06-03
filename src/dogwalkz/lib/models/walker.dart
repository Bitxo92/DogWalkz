class Walker {
  final String userId;
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;
  final double rating;
  final int totalWalks;
  final String? bio;
  final int? experienceYears;
  final bool canWalkSmall;
  final bool canWalkMedium;
  final bool canWalkLarge;
  final bool hasDangerousBreedCertification;
  final double baseRatePerHour;
  final String city;
  final String? phone;

  Walker({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.profilePictureUrl,
    required this.rating,
    required this.totalWalks,
    this.bio,
    this.experienceYears,
    required this.canWalkSmall,
    required this.canWalkMedium,
    required this.canWalkLarge,
    required this.hasDangerousBreedCertification,
    required this.baseRatePerHour,
    required this.city,
    this.phone,
  });

  factory Walker.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;
    return Walker(
      userId: json['user_id'] ?? json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profilePictureUrl: json['profile_picture_url'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalWalks: json['total_walks'] as int? ?? 0,
      bio: json['bio'],
      experienceYears: json['experience_years'] as int?,
      canWalkSmall: json['can_walk_small'] as bool? ?? false,
      canWalkMedium: json['can_walk_medium'] as bool? ?? true,
      canWalkLarge: json['can_walk_large'] as bool? ?? false,
      hasDangerousBreedCertification:
          json['has_dangerous_breed_certification'] as bool? ?? false,
      baseRatePerHour: (json['base_rate_per_hour'] as num?)?.toDouble() ?? 8.0,
      city: address?['city'] ?? '',
      phone: json['phone'],
    );
  }

  String get fullName => '$firstName $lastName';
}
