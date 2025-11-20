enum AlertMethod { whatsapp, sms, phoneCall, whatsappCall }

class EmergencyContact {
  final String name;
  final String phoneNumber;
  final bool isEmergencyServices;
  final AlertMethod alertMethod; // Changed from useWhatsApp to alertMethod

  EmergencyContact({
    required this.name,
    required this.phoneNumber,
    this.isEmergencyServices = false,
    this.alertMethod = AlertMethod.whatsapp, // Default to WhatsApp
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'isEmergencyServices': isEmergencyServices,
      'alertMethod': alertMethod.toString(),
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    // Handle migration from old useWhatsApp field
    AlertMethod method = AlertMethod.whatsapp;
    if (json['alertMethod'] != null) {
      method = AlertMethod.values.firstWhere(
        (e) => e.toString() == json['alertMethod'],
        orElse: () => AlertMethod.whatsapp,
      );
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
