class Dog {
  String id;
  final String name;
  final String imageUrl;
  bool isSaved;
  final int age;
  int numberOfSaves;
  final String volunteer;
  final String description; 
  final String location; 

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
