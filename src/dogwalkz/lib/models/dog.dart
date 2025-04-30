class Dog {
  final String id;
  final String ownerId;
  final String name;
  final String breed;
  final int? age;
  final String size;
  final bool isDangerousBreed;
  final bool isSociable;
  final String? specialInstructions;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Dog({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.breed,
    this.age,
    required this.size,
    this.isDangerousBreed = false,
    this.isSociable = true,
    this.specialInstructions,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor that creates a `Dog` instance from a JSON map.
  ///
  /// The [json] parameter is a `Map<String, dynamic>` that contains the
  /// key-value pairs representing the properties of a `Dog` object.
  ///
  /// Returns a `Dog` instance populated with the data from the JSON map.
  factory Dog.fromJson(Map<String, dynamic> json) {
    return Dog(
      id: json['id'] ?? '', // Handle null values
      ownerId: json['owner_id'] ?? '',
      name: json['name'] ?? 'Unknown Dog',
      breed: json['breed'] ?? 'Unknown Breed',
      age: json['age'] as int?,
      size: json['size'] ?? 'medium',
      isDangerousBreed: json['is_dangerous_breed'] as bool? ?? false,
      isSociable: json['is_sociable'] as bool? ?? true,
      specialInstructions: json['special_instructions'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime.now(),
    );
  }

  /// Converts this `Dog` instance into a JSON-compatible `Map<String, dynamic>`.
  ///
  /// The resulting map contains the key-value pairs representing the properties
  /// of the `Dog` object.
  ///
  /// Returns a JSON-compatible `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'breed': breed,
      'age': age,
      'size': size,
      'is_dangerous_breed': isDangerousBreed,
      'is_sociable': isSociable,
      'special_instructions': specialInstructions,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
