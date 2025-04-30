import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dog.dart';

class DogsRepository {
  final SupabaseClient _supabase;

  DogsRepository() : _supabase = Supabase.instance.client;

  /// Fetches all dogs from the database.
  /// Returns a list of `Dog` objects.
  Future<List<Dog>> getDogsByOwner(String ownerId) async {
    final response = await _supabase
        .from('dogs')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);

    return (response as List).map((dog) => Dog.fromJson(dog)).toList();
  }

  /// Adds a new dog to the database.
  Future<Dog> addDog(Dog dog) async {
    final response = await _supabase.from('dogs').insert(dog.toJson()).select();
    return Dog.fromJson(response.first);
  }

  /// Updates an existing dog in the database.
  ///
  /// Updates the dog with the given `id` with the provided `dog` data.
  Future<void> updateDog(Dog dog) async {
    final response = await _supabase
        .from('dogs')
        .update(dog.toJson())
        .eq('id', dog.id);

    if (response.error != null) {
      throw Exception('Failed to update dog: ${response.error!.message}');
    }
  }

  /// Deletes the dog with the given `dogId` from the database.
  Future<void> deleteDog(String dogId) async {
    await _supabase.from('dogs').delete().eq('id', dogId);
  }

  /// Uploads the given `image` to Supabase Storage under the `dog-photos`
  /// bucket, with the file name being the `dogId`, and returns the
  /// publicly-accessible URL of the uploaded image.
  Future<String?> uploadDogPhoto(String dogId, File image) async {
    try {
      final fileExt = image.path.split('.').last;
      final fileName = '$dogId.$fileExt';
      final fileBytes = await image.readAsBytes();

      await _supabase.storage
          .from('dog-photos')
          .upload(
            fileName,
            File(image.path),
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/${fileExt == 'jpg' ? 'jpeg' : fileExt}',
            ),
          );

      final imageUrl = _supabase.storage
          .from('dog-photos')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      print('Error uploading dog photo: $e');
      return null;
    }
  }
}
