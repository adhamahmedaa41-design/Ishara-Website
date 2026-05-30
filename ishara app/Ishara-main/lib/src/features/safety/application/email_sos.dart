/// Email-based SOS dispatch.
///
/// POSTs to `/api/sos` on the Ishara backend, which uses Nodemailer + Gmail
/// SMTP to deliver the message **immediately and silently** — no mail app
/// opens on the user's phone. This matches how the website's contact form
/// and OTP emails work.
library;

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/api/api_client.dart';
import '../data/contacts_repository.dart';

class EmailSosResult {
  EmailSosResult({
    required this.success,
    required this.totalContacts,
    required this.contactsWithEmail,
    this.sent = 0,
    this.error,
  });

  final bool success;
  final int totalContacts;
  final int contactsWithEmail;
  final int sent;
  final String? error;
}

class EmailSos {
  static Future<EmailSosResult> dispatch({
    required ApiClient api,
    required List<EmergencyContactDto> contacts,
    required String senderName,
    String senderPhone = '',
    Position? location,
  }) async {
    if (contacts.isEmpty) {
      return EmailSosResult(
        success: false,
        totalContacts: 0,
        contactsWithEmail: 0,
        error: 'No emergency contacts saved.',
      );
    }

    final emails = contacts
        .map((c) => c.email.trim())
        .where((e) => e.isNotEmpty && e.contains('@'))
        .toList();

    if (emails.isEmpty) {
      return EmailSosResult(
        success: false,
        totalContacts: contacts.length,
        contactsWithEmail: 0,
        error: 'None of your emergency contacts have an email saved. '
            'Open the contact and add an email address.',
      );
    }

    try {
      final response = await api.post('/api/sos', data: {
        'to': emails,
        'senderName': senderName.isEmpty ? 'Ishara user' : senderName,
        'senderPhone': senderPhone,
        if (location != null)
          'location': {
            'lat': location.latitude,
            'lng': location.longitude,
          },
      });

      final data = response.data is Map ? response.data as Map : const {};
      final success = data['success'] == true;
      final sent = (data['sent'] is int) ? data['sent'] as int : 0;

      return EmailSosResult(
        success: success,
        totalContacts: contacts.length,
        contactsWithEmail: emails.length,
        sent: sent,
        error: success ? null : (data['message']?.toString() ?? 'Send failed'),
      );
    } on DioException catch (e) {
      return EmailSosResult(
        success: false,
        totalContacts: contacts.length,
        contactsWithEmail: emails.length,
        error: 'Could not reach server: ${e.message ?? e.type.name}',
      );
    } catch (e) {
      return EmailSosResult(
        success: false,
        totalContacts: contacts.length,
        contactsWithEmail: emails.length,
        error: 'Send failed: $e',
      );
    }
  }
}
