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
  final int age;

  @HiveField(7)
  int numberOfSaves;

  @HiveField(8)
  final String volunteer;

  Dog({
    this.id = '',
    required this.name,
    required this.imageUrl,
    this.isSaved = false,
    required this.age,
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
      'age': age,
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
      age: map['age'],
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
    int? age,
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
      age: age ?? this.age,
      numberOfSaves: numberOfSaves ?? this.numberOfSaves,
      volunteer: volunteer ?? this.volunteer,
      description: description ?? this.description,
      location: location ?? this.location,
    );
  }
}
