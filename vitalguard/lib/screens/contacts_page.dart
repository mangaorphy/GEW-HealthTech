import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/emergency_service.dart';
import '../models/emergency_contact.dart';
import '../utils/app_theme.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  AlertMethod _selectedAlertMethod =
      AlertMethod.whatsapp; // Track selected method

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showAddContactDialog(BuildContext context) {
    _nameController.clear();
    _phoneController.clear();
    _selectedAlertMethod = AlertMethod.whatsapp; // Reset to default

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Emergency Contact'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g., Mom, Dad, Spouse',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+250792957530',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    if (!value.contains(RegExp(r'^\+?[0-9]{10,15}$'))) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Alert Method',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // WhatsApp Option
                RadioListTile<AlertMethod>(
                  value: AlertMethod.whatsapp,
                  groupValue: _selectedAlertMethod,
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedAlertMethod = value!;
                    });
                  },
                  title: const Row(
                    children: [
                      Icon(Icons.chat, color: AppTheme.successGreen, size: 20),
                      SizedBox(width: 8),
                      Text('WhatsApp Message'),
                    ],
                  ),
                  dense: true,
                ),
                // SMS Option
                RadioListTile<AlertMethod>(
                  value: AlertMethod.sms,
                  groupValue: _selectedAlertMethod,
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedAlertMethod = value!;
                    });
                  },
                  title: const Row(
                    children: [
                      Icon(
                        Icons.message,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text('SMS Text Message'),
                    ],
                  ),
                  dense: true,
                ),
                // Phone Call Option
                RadioListTile<AlertMethod>(
                  value: AlertMethod.phoneCall,
                  groupValue: _selectedAlertMethod,
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedAlertMethod = value!;
                    });
                  },
                  title: const Row(
                    children: [
                      Icon(Icons.phone, color: AppTheme.warningRed, size: 20),
                      SizedBox(width: 8),
                      Text('Regular Phone Call'),
                    ],
                  ),
                  dense: true,
                ),
                // WhatsApp Call Option
                RadioListTile<AlertMethod>(
                  value: AlertMethod.whatsappCall,
                  groupValue: _selectedAlertMethod,
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedAlertMethod = value!;
                    });
                  },
                  title: const Row(
                    children: [
                      Icon(
                        Icons.video_call,
                        color: AppTheme.successGreen,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text('WhatsApp Voice Call'),
                    ],
                  ),
                  dense: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final emergencyService = Provider.of<EmergencyService>(
                    context,
                    listen: false,
                  );
                  emergencyService.addContact(
                    EmergencyContact(
                      name: _nameController.text.trim(),
                      phoneNumber: _phoneController.text.trim(),
                      alertMethod: _selectedAlertMethod,
                    ),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact added successfully'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
              child: const Text('Add Contact'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text(
          'Are you sure you want to remove $name from your emergency contacts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final emergencyService = Provider.of<EmergencyService>(
                context,
                listen: false,
              );
              emergencyService.removeContact(index);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact removed'),
                  backgroundColor: AppTheme.warningRed,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue.withOpacity(0.02),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Emergency Contacts',
              style: TextStyle(
                color: AppTheme.darkText,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Manage your contacts',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.primaryBlue.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: Consumer<EmergencyService>(
        builder: (context, emergencyService, child) {
          final contacts = emergencyService.contacts;

          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contacts_outlined,
                    size: 100,
                    color: AppTheme.greyText.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Emergency Contacts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add contacts who will be notified\nin case of an emergency',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppTheme.greyText),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _showAddContactDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Contact'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: contact.isEmergencyServices
                          ? AppTheme.warningRed.withOpacity(0.1)
                          : AppTheme.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      contact.isEmergencyServices
                          ? Icons.local_hospital
                          : Icons.person,
                      color: contact.isEmergencyServices
                          ? AppTheme.warningRed
                          : AppTheme.primaryBlue,
                    ),
                  ),
                  title: Text(
                    contact.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              contact.alertMethod == AlertMethod.whatsapp
                                  ? Icons.chat
                                  : contact.alertMethod == AlertMethod.sms
                                  ? Icons.message
                                  : contact.alertMethod ==
                                        AlertMethod.whatsappCall
                                  ? Icons.video_call
                                  : Icons.phone,
                              size: 14,
                              color: contact.alertMethod == AlertMethod.whatsapp
                                  ? AppTheme.successGreen
                                  : contact.alertMethod == AlertMethod.sms
                                  ? AppTheme.primaryBlue
                                  : contact.alertMethod ==
                                        AlertMethod.whatsappCall
                                  ? AppTheme.successGreen
                                  : AppTheme.warningRed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              contact.phoneNumber,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.greyText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact.alertMethod == AlertMethod.whatsapp
                              ? 'WhatsApp Message'
                              : contact.alertMethod == AlertMethod.sms
                              ? 'SMS Alert'
                              : contact.alertMethod == AlertMethod.whatsappCall
                              ? 'WhatsApp Call'
                              : 'Phone Call Alert',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyText.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppTheme.warningRed,
                    ),
                    onPressed: () =>
                        _confirmDelete(context, index, contact.name),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactDialog(context),
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
      ),
    );
  }
}
