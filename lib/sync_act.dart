import 'package:hive/hive.dart';

part 'sync_act.g.dart';

@HiveType(typeId: 1)
class SyncAction {
  @HiveField(0)
  final String actionType; // Typ akcji, np. "add" lub "remove".
  
  @HiveField(1)
  final String dogId; // Id psa.
  
  @HiveField(2)
  final DateTime timestamp; // Czas utworzenia akcji.

  SyncAction({
    required this.actionType,
    required this.dogId,
    required this.timestamp,
  });

  // Serializacja do mapy
  Map<String, dynamic> toMap() {
    return {
      'actionType': actionType,
      'dogId': dogId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Deserializacja z mapy
  factory SyncAction.fromMap(Map<String, dynamic> map) {
    return SyncAction(
      actionType: map['actionType'] as String,
      dogId: map['dogId'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
