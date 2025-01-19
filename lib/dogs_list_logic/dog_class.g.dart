// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dog_class.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DogAdapter extends TypeAdapter<Dog> {
  @override
  final int typeId = 0;

  @override
  Dog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Sprawdzanie null dla pól typu String
    String? id = fields[0] as String?;
    String? name = fields[1] as String?;
    String? description = fields[2] as String?;
    String? imageUrl = fields[3] as String?;
    String? location = fields[4] as String?;
    String? volunteer = fields[9] as String?;

    // Jeśli wartości są null, ustawiamy domyślne wartości
    id ??= ''; 
    name ??= '';
    description ??= '';
    imageUrl ??= '';
    location ??= '';
    volunteer ??= '';

    // Weryfikacja typu dla 'numberOfSaves' i poprawna konwersja
    int numberOfSaves = 0;
    if (fields[8] is String) {
      numberOfSaves = int.tryParse(fields[8] as String) ?? 0;
    } else if (fields[8] is int) {
      numberOfSaves = fields[8] as int;
    }

    // Weryfikacja dla 'birthDate' oraz 'isEstimatedBirthDate'
    int birthDateInMillis;
    if (fields[6] is String) {
      birthDateInMillis = int.tryParse(fields[6] as String) ?? 0;
    } else if (fields[6] is int) {
      birthDateInMillis = fields[6] as int;
    } else {
      birthDateInMillis = 0;
    }

    bool isEstimatedBirthDate = false;
    if (fields[7] is bool) {
      isEstimatedBirthDate = fields[7] as bool;
    } else if (fields[7] is int) {
      isEstimatedBirthDate = fields[7] == 1;
    }

    return Dog(
      id: id,
      name: name,
      imageUrl: imageUrl,
      isSaved: fields[5] as bool,
      birthDate: Timestamp.fromMicrosecondsSinceEpoch(birthDateInMillis),
      isEstimatedBirthDate: isEstimatedBirthDate,
      numberOfSaves: numberOfSaves,
      volunteer: volunteer,
      description: description,
      location: location,
    );
  }

  @override
  void write(BinaryWriter writer, Dog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.isSaved)
      ..writeByte(6)
      ..write(obj.birthDate.millisecondsSinceEpoch)
      ..writeByte(7)
      ..write(obj.isEstimatedBirthDate ? 1 : 0)
      ..writeByte(8)
      ..write(obj.numberOfSaves)
      ..writeByte(9)
      ..write(obj.volunteer);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
