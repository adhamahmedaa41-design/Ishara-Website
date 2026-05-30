/// Multi-contact emergency repository (server-backed via /api/users/emergency-contacts).
///
/// Cached locally for offline read so the SOS coordinator can still send via
/// device-side SMS when there's no internet.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_provider.dart';

class EmergencyContactDto {
  EmergencyContactDto({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.relationship = '',
    this.app = 'all',
    this.priority = 0,
    this.telegramChatId = '',
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String relationship;
  final String app;
  final int priority;
  final String telegramChatId;

  factory EmergencyContactDto.fromJson(Map<String, dynamic> j) => EmergencyContactDto(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        relationship: (j['relationship'] ?? '').toString(),
        app: (j['app'] ?? 'all').toString(),
        priority: j['priority'] is int ? j['priority'] as int : 0,
        telegramChatId: (j['telegramChatId'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'relationship': relationship,
        'app': app,
        'priority': priority,
        'telegramChatId': telegramChatId,
      };

  EmergencyContactDto copyWith({
    String? name,
    String? phone,
    String? email,
    String? relationship,
    String? app,
    int? priority,
    String? telegramChatId,
  }) =>
      EmergencyContactDto(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        relationship: relationship ?? this.relationship,
        app: app ?? this.app,
        priority: priority ?? this.priority,
        telegramChatId: telegramChatId ?? this.telegramChatId,
      );
}

class ContactsRepository {
  ContactsRepository(this._api, this._prefs);
  final ApiClient _api;
  final SharedPreferences _prefs;
  static const _cacheKey = 'cache_emergency_contacts_v1';

  Future<List<EmergencyContactDto>> list({bool forceRefresh = false}) async {
    final cached = _readCache();
    if (!forceRefresh && cached.isNotEmpty) return cached;
    try {
      final r = await _api.get('/api/users/emergency-contacts');
      // Server returns either 'data' or 'contacts' depending on version
      final raw = (r.data['data'] ?? r.data['contacts'] ?? const []) as List;
      final fromServer = raw
          .map((e) => EmergencyContactDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      // Merge: keep any local-only contacts (id starts with 'local_') that
      // haven't been synced to the server yet, so SOS doesn't lose them.
      final localOnly = cached.where((c) => c.id.startsWith('local_')).toList();
      final merged = [...fromServer, ...localOnly];
      await _writeCache(merged);
      return merged;
    } catch (_) {
      return cached;
    }
  }

  Future<EmergencyContactDto?> add(EmergencyContactDto c) async {
    try {
      final r = await _api.post('/api/users/emergency-contacts', data: c.toJson());
      // Server may return the contact under 'data' or 'contact' key
      final raw = r.data['data'] ?? r.data['contact'];
      final out = EmergencyContactDto.fromJson(Map<String, dynamic>.from(raw as Map));
      await list(forceRefresh: true);
      return out;
    } catch (_) {
      // Server unreachable — still persist locally so SOS can use the contact
      // offline. Generates a temp id; will reconcile on next successful sync.
      final local = EmergencyContactDto(
        id: c.id.isNotEmpty ? c.id : 'local_${DateTime.now().microsecondsSinceEpoch}',
        name: c.name,
        phone: c.phone,
        email: c.email,
        relationship: c.relationship,
        app: c.app,
        priority: c.priority,
        telegramChatId: c.telegramChatId,
      );
      final current = _readCache();
      await _writeCache([...current, local]);
      return local;
    }
  }

  Future<EmergencyContactDto?> update(EmergencyContactDto c) async {
    try {
      final r = await _api.put('/api/users/emergency-contacts/${c.id}', data: c.toJson());
      // Server may return the contact under 'data' or 'contact' key
      final raw = r.data['data'] ?? r.data['contact'];
      final out = EmergencyContactDto.fromJson(Map<String, dynamic>.from(raw as Map));
      await list(forceRefresh: true);
      return out;
    } catch (_) {
      // Update local cache only — preserves edits made offline.
      final current = _readCache();
      final idx = current.indexWhere((e) => e.id == c.id);
      if (idx != -1) {
        current[idx] = c;
        await _writeCache(current);
      }
      return c;
    }
  }

  Future<bool> remove(String id) async {
    try {
      await _api.delete('/api/users/emergency-contacts/$id');
      await list(forceRefresh: true);
      return true;
    } catch (_) {
      // Remove from local cache only.
      final current = _readCache();
      current.removeWhere((e) => e.id == id);
      await _writeCache(current);
      return true;
    }
  }

  /// Synchronous read of the local cache — useful for guards that can't await.
  List<EmergencyContactDto> cachedNow() => _readCache();

  List<EmergencyContactDto> _readCache() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => EmergencyContactDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeCache(List<EmergencyContactDto> list) async {
    await _prefs.setString(_cacheKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return ContactsRepository(api, prefs);
});

final contactsListProvider = FutureProvider<List<EmergencyContactDto>>((ref) async {
  final repo = ref.watch(contactsRepositoryProvider);
  return repo.list();
});
