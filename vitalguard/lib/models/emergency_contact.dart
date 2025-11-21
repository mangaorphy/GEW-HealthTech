enum AlertMethod { whatsapp, sms, phoneCall, whatsappCall }

class EmergencyContact {
  final String name;
  final String phoneNumber;
  final bool isEmergencyServices;
  final AlertMethod alertMethod;

  EmergencyContact({
    required this.name,
    required this.phoneNumber,
    this.isEmergencyServices = false,
    AlertMethod? alertMethod,
  }) : alertMethod = alertMethod ?? AlertMethod.whatsapp;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'isEmergencyServices': isEmergencyServices,
      'alertMethod': alertMethod.toString(),
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    AlertMethod method;

    if (json['alertMethod'] != null) {
      method = AlertMethod.values.firstWhere(
        (e) => e.toString() == json['alertMethod'],
        orElse: () => AlertMethod.whatsapp,
      );
    } else if (json['alertMethods'] != null) {
      // Backward compatibility: take first method from old list format
      final methods = json['alertMethods'] as List;
      if (methods.isNotEmpty) {
        method = AlertMethod.values.firstWhere(
          (e) => e.toString() == methods[0],
          orElse: () => AlertMethod.whatsapp,
        );
      } else {
        method = AlertMethod.whatsapp;
      }
    } else if (json['useWhatsApp'] == true) {
      method = AlertMethod.whatsapp;
    } else {
      method = AlertMethod.sms;
    }

    return EmergencyContact(
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      isEmergencyServices: json['isEmergencyServices'] ?? false,
      alertMethod: method,
    );
  }
}
