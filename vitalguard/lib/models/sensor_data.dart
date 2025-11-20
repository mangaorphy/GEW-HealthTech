class SensorData {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  SensorData({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  double get magnitude => _calculateMagnitude();

  double _calculateMagnitude() {
    return (x * x + y * y + z * z);
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'z': z, 'timestamp': timestamp.toIso8601String()};
  }
}
