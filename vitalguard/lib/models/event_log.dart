enum EventType { fall, cardiacEvent, breathingAbnormality, manualSOS }

class EventLog {
  final String id;
  final EventType type;
  final DateTime timestamp;
  final String? location;
  final bool alertSent;
  final bool userAcknowledged;

  EventLog({
    required this.id,
    required this.type,
    required this.timestamp,
    this.location,
    this.alertSent = false,
    this.userAcknowledged = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'alertSent': alertSent,
      'userAcknowledged': userAcknowledged,
    };
  }

  factory EventLog.fromJson(Map<String, dynamic> json) {
    return EventLog(
      id: json['id'],
      type: EventType.values.firstWhere((e) => e.toString() == json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'],
      alertSent: json['alertSent'] ?? false,
      userAcknowledged: json['userAcknowledged'] ?? false,
    );
  }
}
