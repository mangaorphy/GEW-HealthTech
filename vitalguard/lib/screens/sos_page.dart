import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/emergency_service.dart';
import '../models/emergency_contact.dart';
import '../utils/app_theme.dart';

class SOSPage extends StatefulWidget {
  const SOSPage({super.key});

  @override
  State<SOSPage> createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency SOS'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Emergency SOS',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  'Press and hold to alert emergency services',
                  style: TextStyle(fontSize: 16, color: AppTheme.greyText),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // Emergency Service Consumer
                Consumer<EmergencyService>(
                  builder: (context, emergencyService, child) {
                    if (emergencyService.isAlertActive) {
                      return _buildCountdownWidget(
                        emergencyService.countdown,
                        emergencyService,
                      );
                    }

                    return _buildSOSButton(emergencyService);
                  },
                ),

                const SizedBox(height: 60),

                // Emergency Contacts
                const Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),

                const SizedBox(height: 20),

                Consumer<EmergencyService>(
                  builder: (context, emergencyService, child) {
                    if (emergencyService.contacts.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.contact_phone_outlined,
                              size: 64,
                              color: AppTheme.greyText.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No emergency contacts added',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.greyText,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/contacts');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Contacts'),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: emergencyService.contacts
                          .map((contact) => _buildContactCard(contact))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSOSButton(EmergencyService emergencyService) {
    return Center(
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
        },
        onLongPress: () {
          emergencyService.manualSOS();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.warningRed,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.warningRed.withOpacity(0.3),
                blurRadius: _isPressed ? 40 : 20,
                spreadRadius: _isPressed ? 10 : 0,
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone, color: Colors.white, size: 48),
              SizedBox(height: 12),
              Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownWidget(
    int countdown,
    EmergencyService emergencyService,
  ) {
    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.warningRed,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              countdown.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Sending emergency alert...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),

        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: () {
            emergencyService.cancelAlert();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.greyText,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('Cancel Alert'),
        ),
      ],
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: contact.isEmergencyServices
            ? AppTheme.warningRed.withOpacity(0.1)
            : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: contact.isEmergencyServices
              ? AppTheme.warningRed.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            contact.isEmergencyServices ? Icons.local_hospital : Icons.person,
            color: contact.isEmergencyServices
                ? AppTheme.warningRed
                : AppTheme.primaryBlue,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact.phoneNumber,
                  style: TextStyle(fontSize: 14, color: AppTheme.greyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
