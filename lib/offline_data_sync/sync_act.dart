import 'package:hive/hive.dart';

part 'sync_act.g.dart';

@HiveType(typeId: 1)
class SyncAction {
  @HiveField(0)
  final String actionType;

  @HiveField(1)
  final String dogId;

  @HiveField(2)
  final DateTime timestamp;

  SyncAction({
    required this.actionType,
    required this.dogId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'actionType': actionType,
      'dogId': dogId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SyncAction.fromMap(Map<String, dynamic> map) {
    return SyncAction(
      actionType: map['actionType'] as String,
      dogId: map['dogId'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
