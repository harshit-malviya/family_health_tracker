import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/health_providers.dart';

class BackupRestoreService {
  /// Prompts the user with a security warning regarding unencrypted PHI,
  /// exports all app data into a structured .json file, opens the share sheet,
  /// and promptly removes the unencrypted file from the device cache upon completion.
  static Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final warningTitle = l10n?.backupSecurityWarningTitle ?? 'Security Notice: Unencrypted Backup';
    final warningMessage = l10n?.backupSecurityWarningMessage ??
        'This export creates an unencrypted JSON file containing sensitive personal health records (names, dates of birth, blood pressure, and blood sugar readings). Ensure you store or share this file securely.';
    final cancelText = l10n?.backupCancel ?? 'Cancel';
    final exportAnywayText = l10n?.backupExportAnyway ?? 'Export Anyway';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                warningTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          warningMessage,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(cancelText),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.lock_open_rounded, size: 18),
            label: Text(exportAnywayText),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    File? tempBackupFile;
    try {
      final tempDir = await getTemporaryDirectory();

      // Pre-export safety sweep: delete any existing orphaned backup files in cache
      try {
        final entries = tempDir.listSync();
        for (final entry in entries) {
          if (entry is File &&
              entry.path.contains('health_tracker_backup_') &&
              entry.path.endsWith('.json')) {
            await entry.delete();
          }
        }
      } catch (_) {}

      final repo = ref.read(healthRepositoryProvider);
      final jsonString = await repo.exportBackupJson();

      final nowFormatted = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'health_tracker_backup_$nowFormatted.json';
      tempBackupFile = File('${tempDir.path}/$fileName');

      await tempBackupFile.writeAsString(jsonString);

      if (!context.mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempBackupFile.path, mimeType: 'application/json')],
          subject: 'Health Tracker Backup ($nowFormatted)',
          text: 'Health Tracker JSON Backup File ($fileName)',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export backup: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      // Clean up unencrypted health backup from temporary cache
      if (tempBackupFile != null && await tempBackupFile.exists()) {
        try {
          await tempBackupFile.delete();
        } catch (_) {}
      }
    }
  }

  /// Opens the system file selector to pick a .json file, validates it,
  /// displays a preview confirmation dialog, and restores data.
  static Future<void> restoreBackupFromFile(
    BuildContext context,
    WidgetRef ref, {
    VoidCallback? onSuccess,
  }) async {
    try {
      final pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      // User cancelled picker
      if (pickedFile == null) {
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      final jsonContent = utf8.decode(bytes);

      if (jsonContent.trim().isEmpty) {
        if (!context.mounted) return;
        _showErrorSnackBar(context, 'The selected file is empty.');
        return;
      }

      // Parse and validate JSON structure
      final Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(jsonContent);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Expected JSON object at root');
        }
        data = decoded;
      } catch (e) {
        if (!context.mounted) return;
        _showErrorSnackBar(context, 'Invalid JSON format. Please pick a valid backup file.');
        return;
      }

      final membersList = data['family_members'] as List? ?? [];
      final bpList = data['bp_readings'] as List? ?? [];
      final glucoseList = data['glucose_readings'] as List? ?? [];

      if (!data.containsKey('family_members') &&
          !data.containsKey('bp_readings') &&
          !data.containsKey('glucose_readings')) {
        if (!context.mounted) return;
        _showErrorSnackBar(context, 'Selected file is not a valid Health Tracker backup.');
        return;
      }

      DateTime? exportedAt;
      if (data['exportedAt'] != null) {
        try {
          exportedAt = DateTime.parse(data['exportedAt']);
        } catch (_) {}
      }

      if (!context.mounted) return;

      // Show summary confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Icon(Icons.settings_backup_restore, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Confirm Restore',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File: ${pickedFile.name}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              if (exportedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Created: ${DateFormat('MMM d, yyyy • h:mm a').format(exportedAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    _buildPreviewRow(
                      Icons.people_alt_rounded,
                      'Family Profiles',
                      '${membersList.length}',
                      AppColors.primary,
                    ),
                    const Divider(height: 16),
                    _buildPreviewRow(
                      Icons.favorite_rounded,
                      'BP Readings',
                      '${bpList.length}',
                      AppColors.bpNormal,
                    ),
                    const Divider(height: 16),
                    _buildPreviewRow(
                      Icons.water_drop_rounded,
                      'Blood Sugar Readings',
                      '${glucoseList.length}',
                      AppColors.glucoseNormal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Existing data with matching records will be updated, and new records will be added safely.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Restore Now'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final repo = ref.read(healthRepositoryProvider);
      final success = await repo.importBackupJson(jsonContent);

      if (!context.mounted) return;

      if (success) {
        // Refresh all providers
        ref.read(familyMembersProvider.notifier).loadMembers();
        ref.read(bpReadingsProvider.notifier).loadReadings();
        ref.read(glucoseReadingsProvider.notifier).loadReadings();

        // Ensure onboarding is marked completed if restored
        ref.read(onboardingCompletedProvider.notifier).complete();

        onSuccess?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Data restored successfully!')),
              ],
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showErrorSnackBar(context, 'Failed to import backup into the database.');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, 'Error selecting backup: $e');
    }
  }

  static Widget _buildPreviewRow(
    IconData icon,
    String label,
    String count,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
