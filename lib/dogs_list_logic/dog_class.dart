import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
part 'dog_class.g.dart';

@HiveType(typeId: 0)
class Dog {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String imageUrl;

  @HiveField(4)
  final String location;

  @HiveField(5)
  bool isSaved;

  @HiveField(6)
  final Timestamp birthDate;

  @HiveField(7)
  final bool isEstimatedBirthDate;

  @HiveField(8)
  int numberOfSaves;

  @HiveField(9)
  final String volunteer;

  Dog({
    this.id = '',
    required this.name,
    required this.imageUrl,
    this.isSaved = false,
    required this.birthDate,
    required this.isEstimatedBirthDate,
    this.numberOfSaves = 0,
    required this.volunteer,
    this.description = '',
    this.location = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'isSaved': isSaved,
      'birthDate': birthDate,
      'isEstimatedBirthDate': isEstimatedBirthDate,
      'numberOfSaves': numberOfSaves,
      'volunteer': volunteer,
      'description': description,
      'location': location,
    };
  }

  factory Dog.fromMap(Map<String, dynamic> map, {String? id}) {
    return Dog(
      id: id ?? '',
      name: map['name'],
      imageUrl: map['imageUrl'],
      isSaved: map['isSaved'] ?? false,
      birthDate: map['birthDate'],
      isEstimatedBirthDate: map['isEstimatedBirthDate'],
      numberOfSaves: map['numberOfSaves'] ?? 0,
      volunteer: map['volunteer'],
      description: map['description'] ?? '',
      location: map['location'] ?? '',
    );
  }

  Dog copyWith({
    String? id,
    String? name,
    String? imageUrl,
    bool? isSaved,
    Timestamp? birthDate,
    bool? isEstimatedBirthDate,
    int? numberOfSaves,
    String? volunteer,
    String? description,
    String? location,
  }) {
    return Dog(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      isSaved: isSaved ?? this.isSaved,
      birthDate: birthDate ?? this.birthDate,
      isEstimatedBirthDate: isEstimatedBirthDate ?? this.isEstimatedBirthDate,
      numberOfSaves: numberOfSaves ?? this.numberOfSaves,
      volunteer: volunteer ?? this.volunteer,
      description: description ?? this.description,
      location: location ?? this.location,
    );
  }
}
