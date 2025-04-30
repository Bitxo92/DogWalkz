class Customer {
  final String id;

  final String? firstName;
  final String? lastName;

  final String? profilePictureUrl;
  final String? phone;

  Customer({
    required this.id,

    required this.firstName,
    required this.lastName,

    this.profilePictureUrl,
    this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',

      profilePictureUrl: json['profile_picture_url'] as String?,
      phone: json['phone'] as String?,
    );
  }
  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'profile_picture_url': profilePictureUrl,
      'phone': phone,
    };
  }
}
