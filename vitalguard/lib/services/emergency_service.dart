import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/emergency_contact.dart';
import '../models/event_log.dart';
import 'dart:async';

class EmergencyService extends ChangeNotifier {
  List<EmergencyContact> _contacts = [];
  bool _isAlertActive = false;
  int _countdown = 15;
  Timer? _countdownTimer;
  EventType? _currentEventType; // Track the event type that triggered the alert

  bool get isAlertActive => _isAlertActive;
  int get countdown => _countdown;
  List<EmergencyContact> get contacts => _contacts;
  EventType? get currentEventType => _currentEventType; // Getter for event type

  EmergencyService() {
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString('emergency_contacts');

      if (contactsJson != null) {
        final List<dynamic> decoded = json.decode(contactsJson);
        _contacts = decoded
            .map((item) => EmergencyContact.fromJson(item))
            .toList();
        debugPrint('✅ Loaded ${_contacts.length} emergency contacts:');
        for (var contact in _contacts) {
          debugPrint(
            '   📞 ${contact.name} - ${contact.phoneNumber} (${contact.alertMethod})',
          );
        }
      } else {
        _contacts = [];
        debugPrint(
          '⚠️ No emergency contacts found - please add contacts first!',
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading contacts: $e');
      _contacts = [];
    }
  }

  Future<void> addContact(EmergencyContact contact) async {
    _contacts.add(contact);
    await _saveContacts();
    notifyListeners();
  }

  Future<void> removeContact(int index) async {
    _contacts.removeAt(index);
    await _saveContacts();
    notifyListeners();
  }

  Future<void> _saveContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = json.encode(
        _contacts.map((contact) => contact.toJson()).toList(),
      );
      await prefs.setString('emergency_contacts', contactsJson);
      debugPrint('Saved ${_contacts.length} emergency contacts');
    } catch (e) {
      debugPrint('Error saving contacts: $e');
    }
  }

  Future<void> triggerEmergencyAlert(EventType eventType) async {
    if (_isAlertActive) {
      debugPrint('⚠️ Alert already active, ignoring duplicate trigger');
      return;
    }

    debugPrint('🚨 TRIGGERING EMERGENCY ALERT: $eventType');
    debugPrint('📋 Number of contacts: ${_contacts.length}');

    if (_contacts.isEmpty) {
      debugPrint('⚠️ WARNING: No emergency contacts configured!');
    } else {
      debugPrint('📞 Will alert these contacts:');
      for (var contact in _contacts) {
        debugPrint(
          '   - ${contact.name} (${contact.phoneNumber}) via ${contact.alertMethod}',
        );
      }
    }

    _isAlertActive = true;
    _currentEventType = eventType; // Store the event type
    _countdown = 15;
    notifyListeners();

    // Start countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdown--;
      notifyListeners();

      if (_countdown <= 0) {
        timer.cancel();
        _sendEmergencyAlerts(eventType);
      }
    });
  }

  void cancelAlert() {
    _countdownTimer?.cancel();
    _isAlertActive = false;
    _currentEventType = null; // Clear event type
    _countdown = 15;
    notifyListeners();
  }

  Future<void> _sendEmergencyAlerts(EventType eventType) async {
    try {
      // Get current location
      String? location = await _getCurrentLocation();

      // Create event log
      final event = EventLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: eventType,
        timestamp: DateTime.now(),
        location: location,
        alertSent: true,
      );

      // Send alerts to all contacts
      for (var contact in _contacts) {
        await _sendAlert(contact, event);
      }

      debugPrint('Emergency alerts sent successfully');
    } catch (e) {
      debugPrint('Error sending emergency alerts: $e');
    } finally {
      _isAlertActive = false;
      notifyListeners();
    }
  }

  Future<String?> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return '${position.latitude},${position.longitude}';
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  Future<void> _sendAlert(EmergencyContact contact, EventLog event) async {
    try {
      String message = _buildAlertMessage(event);

      // Choose alert method based on contact preference
      if (contact.isEmergencyServices ||
          contact.alertMethod == AlertMethod.phoneCall) {
        // Direct phone call
        await _makePhoneCall(contact.phoneNumber);
        debugPrint('📞 Phone call initiated to ${contact.name}');
      } else if (contact.alertMethod == AlertMethod.whatsappCall) {
        // WhatsApp voice call
        await _makeWhatsAppCall(contact.phoneNumber);
        debugPrint('📞💬 WhatsApp call initiated to ${contact.name}');
      } else if (contact.alertMethod == AlertMethod.whatsapp) {
        // WhatsApp message
        await sendWhatsAppAlert(contact.phoneNumber, message);
        debugPrint('💬 WhatsApp alert sent to ${contact.name}');
      } else if (contact.alertMethod == AlertMethod.sms) {
        // SMS text message
        await _sendSMS(contact.phoneNumber, message);
        debugPrint('📱 SMS sent to ${contact.name}');
      }
    } catch (e) {
      debugPrint('Error sending alert to ${contact.name}: $e');
    }
  }

  String _buildAlertMessage(EventLog event) {
    String eventTypeStr = event.type == EventType.fall
        ? 'FALL DETECTED'
        : event.type == EventType.cardiacEvent
        ? 'CARDIAC EVENT'
        : 'EMERGENCY';

    String message = '🚨 VitalGuard Alert: $eventTypeStr\n';
    message += 'Time: ${event.timestamp.toString()}\n';

    if (event.location != null) {
      message += 'Location: https://maps.google.com/?q=${event.location}\n';
    }

    message = 'Please check on the user immediately!';

    return message;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _makeWhatsAppCall(String phoneNumber) async {
    try {
      // Format phone number for WhatsApp (remove all non-digits)
      String formattedNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      // Ensure number starts with country code
      if (!formattedNumber.startsWith('250') && formattedNumber.length == 9) {
        formattedNumber = '250$formattedNumber';
      }

      debugPrint('Initiating WhatsApp call to: $formattedNumber');

      // WhatsApp voice call URI scheme (correct format)
      // Use the standard WhatsApp send URL which opens chat, then user can call
      // Or use intent-based approach for direct calling
      final Uri whatsappCallUri = Uri.parse('https://wa.me/$formattedNumber');

      bool canLaunch = await canLaunchUrl(whatsappCallUri);

      if (canLaunch) {
        await launchUrl(whatsappCallUri, mode: LaunchMode.externalApplication);
        debugPrint('✅ WhatsApp opened for contact $formattedNumber');
      } else {
        debugPrint('⚠️ WhatsApp not installed, falling back to regular call');
        // Fallback to regular phone call if WhatsApp not available
        await _makePhoneCall(phoneNumber);
      }
    } catch (e) {
      debugPrint('Error initiating WhatsApp call: $e');
      // Fallback to regular phone call on error
      await _makePhoneCall(phoneNumber);
    }
  }

  Future<void> _sendSMS(String phoneNumber, String message) async {
    try {
      // Android-compatible SMS URI format
      // Remove any spaces or special characters except +
      String cleanNumber = phoneNumber.replaceAll(' ', '').replaceAll('-', '');

      final Uri smsUri = Uri.parse(
        'sms:$cleanNumber?body=${Uri.encodeComponent(message)}',
      );

      debugPrint('Sending SMS to: $cleanNumber');

      if (await canLaunchUrl(smsUri)) {
        // Force SMS app directly without app chooser
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        debugPrint('SMS app opened successfully');
      } else {
        debugPrint('Cannot open SMS app');
      }
    } catch (e) {
      debugPrint('Error opening SMS app: $e');
    }
  }

  // Send via WhatsApp using direct intent scheme
  Future<void> sendWhatsAppAlert(String phoneNumber, String message) async {
    try {
      // Format phone number for WhatsApp (remove all non-digits)
      String formattedNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      // Ensure number starts with country code
      if (!formattedNumber.startsWith('250') && formattedNumber.length == 9) {
        formattedNumber = '250$formattedNumber';
      }

      debugPrint('Sending WhatsApp to: $formattedNumber');

      // Try WhatsApp-specific URI scheme first (works better on Android)
      final Uri whatsappUri = Uri.parse(
        'whatsapp://send?phone=$formattedNumber&text=${Uri.encodeComponent(message)}',
      );

      bool canLaunch = await canLaunchUrl(whatsappUri);

      if (canLaunch) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        debugPrint('✅ WhatsApp opened successfully');
      } else {
        // Fallback to web-based WhatsApp URL
        debugPrint('Trying web-based WhatsApp...');
        final Uri webWhatsappUri = Uri.parse(
          'https://wa.me/$formattedNumber?text=${Uri.encodeComponent(message)}',
        );

        if (await canLaunchUrl(webWhatsappUri)) {
          await launchUrl(webWhatsappUri, mode: LaunchMode.externalApplication);
          debugPrint('✅ Web WhatsApp opened successfully');
        } else {
          debugPrint('⚠️ WhatsApp not available, falling back to SMS');
          await _sendSMS(phoneNumber, message);
        }
      }
    } catch (e) {
      debugPrint('❌ Error sending WhatsApp: $e');
      // Fallback to SMS on any error
      await _sendSMS(phoneNumber, message);
    }
  }

  Future<void> manualSOS() async {
    await triggerEmergencyAlert(EventType.manualSOS);
    // For manual SOS, skip countdown and send immediately
    _countdownTimer?.cancel();
    _countdown = 0;
    await _sendEmergencyAlerts(EventType.manualSOS);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
