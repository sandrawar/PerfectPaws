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
    return Dog(
      id: fields[0] as String,
      name: fields[1] as String,
      imageUrl: fields[3] as String,
      isSaved: fields[5] as bool,
      age: fields[6] as int,
      numberOfSaves: fields[7] as int,
      volunteer: fields[8] as String,
      description: fields[2] as String,
      location: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Dog obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.age)
      ..writeByte(7)
      ..write(obj.numberOfSaves)
      ..writeByte(8)
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
