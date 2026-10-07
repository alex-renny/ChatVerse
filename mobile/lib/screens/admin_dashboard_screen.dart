import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/password_prompt_dialog.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _overview;
  bool _loading = false;
  String? _error;

  Future<void> _unlock() async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PasswordPromptDialog(
        title: 'Admin verification',
        hint: 'Enter your ReSender password',
        confirmLabel: 'View dashboard',
      ),
    );
    if (password == null || password.isEmpty || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService.getAdminOverview(password);
      if (mounted) setState(() => _overview = result);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _overview;
    final users = data?['users'] as Map<String, dynamic>?;
    final cloudinary = data?['cloudinary'] as Map<String, dynamic>?;
    final atlas = data?['atlas'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Admin dashboard')),
      body: data == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined,
                        size: 56, color: Color(0xFFFF7A00)),
                    const SizedBox(height: 12),
                    const Text('Sensitive project information',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      'Confirm your account password to view storage usage and account details.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _loading ? null : _unlock,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.lock_open),
                      label: Text(_loading ? 'Checking…' : 'Verify password'),
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A00)),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _unlock,
              color: const Color(0xFFFF7A00),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _metricCard(
                    icon: Icons.cloud_outlined,
                    title: 'Cloudinary storage',
                    used: cloudinary?['storageUsedBytes'],
                    limit: cloudinary?['storageLimitBytes'],
                    remaining: cloudinary?['storageRemainingBytes'],
                    unavailable: cloudinary?['available'] != true,
                    detail: cloudinary?['resources'] == null
                        ? null
                        : '${cloudinary!['resources']} media resources',
                  ),
                  const SizedBox(height: 12),
                  _metricCard(
                    icon: Icons.storage_outlined,
                    title: 'MongoDB Atlas · ${atlas?['databaseName'] ?? 'database'}',
                    used: atlas?['storageUsedBytes'],
                    limit: atlas?['storageLimitBytes'],
                    remaining: atlas?['storageRemainingBytes'],
                    detail:
                        '${_formatBytes(_asInt(atlas?['dataBytes']))} data · ${_formatBytes(_asInt(atlas?['indexBytes']))} indexes · ${atlas?['collections'] ?? '—'} collections · ${atlas?['documents'] ?? '—'} documents',
                    setupHint: atlas?['storageLimitBytes'] == null
                        ? 'Add ATLAS_STORAGE_LIMIT_GB to the server environment to show remaining storage.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.people_outline,
                                color: Color(0xFFFF7A00)),
                            const SizedBox(width: 8),
                            const Expanded(
                                child: Text('App accounts',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700))),
                            Text('${users?['count'] ?? 0}',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF7A00))),
                          ]),
                          const Divider(height: 24),
                          const Text('Usernames and email addresses',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54)),
                          const SizedBox(height: 6),
                          for (final entry in
                              (users?['accounts'] as List<dynamic>? ?? const []))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFFFF0E4),
                                  child: Icon(Icons.person_outline,
                                      color: Color(0xFFFF7A00))),
                              title: Text(entry['name']?.toString() ?? 'User'),
                              subtitle: Text(entry['email']?.toString() ?? ''),
                              dense: true,
                            ),
                          if ((users?['count'] as int? ?? 0) >
                              ((users?['accounts'] as List<dynamic>?)?.length ?? 0))
                            const Text('The list is capped at 5,000 accounts.',
                                style: TextStyle(color: Colors.black54)),
                          const SizedBox(height: 8),
                          const Text(
                            'Passwords are never shown. ReSender stores password hashes, which cannot be used to recover the original passwords.',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Updated ${data['generatedAt'] ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required dynamic used,
    required dynamic limit,
    required dynamic remaining,
    String? detail,
    String? setupHint,
    bool unavailable = false,
  }) {
    final usedBytes = _asInt(used);
    final limitBytes = _asInt(limit);
    final remainingBytes = _asInt(remaining);
    final percent = usedBytes != null && limitBytes != null && limitBytes > 0
        ? (usedBytes / limitBytes).clamp(0.0, 1.0).toDouble()
        : null;
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: const Color(0xFFFF7A00)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 14),
          Text(unavailable
              ? 'Usage report unavailable'
              : 'Used: ${_formatBytes(usedBytes)}'),
          const SizedBox(height: 4),
          Text('Limit: ${_formatBytes(limitBytes)}'),
          Text('Remaining: ${_formatBytes(remainingBytes)}'),
          if (percent != null) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: percent,
              color: const Color(0xFFFF7A00),
              backgroundColor: const Color(0xFFFFE0C7),
              borderRadius: BorderRadius.circular(8),
            ),
          ],
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(detail, style: const TextStyle(color: Colors.black54)),
          ],
          if (setupHint != null) ...[
            const SizedBox(height: 8),
            Text(setupHint,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ]),
      ),
    );
  }

  int? _asInt(dynamic value) => value is num ? value.toInt() : null;

  String _formatBytes(int? bytes) {
    if (bytes == null) return 'Not available';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var amount = bytes.toDouble();
    var unit = 0;
    while (amount >= 1024 && unit < units.length - 1) {
      amount /= 1024;
      unit++;
    }
    return '${amount.toStringAsFixed(unit == 0 ? 0 : 2)} ${units[unit]}';
  }
}
