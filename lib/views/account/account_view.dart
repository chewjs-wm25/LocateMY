import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../generated/app_localizations.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  bool _defaultLocationEnabled = false;

  void _showLogoutDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Perform logout logic here
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountCenter)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            BentoCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primaryContainer,
                        child: Icon(Icons.person_rounded, size: 32, color: AppColors.primaryBase),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'user@example.com',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            StatusBadge(
                              label: l10n.verifiedUser,
                              type: StatusType.success,
                              icon: Icons.verified_user_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history_rounded, color: AppColors.primaryBase),
                    title: Text(l10n.relocationHistory),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preferences
            BentoCard(
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.primaryBase),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.defaultLocation,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: _defaultLocationEnabled,
                    onChanged: (v) {
                      setState(() {
                        _defaultLocationEnabled = v;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Saved Comparisons
            Text(
              l10n.savedComparisons,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            BentoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildComparisonItem(context, '吉隆坡', '槟城', '2023-10-25'),
                  const Divider(height: 1, color: AppColors.borderLight),
                  _buildComparisonItem(context, '新山', '怡保', '2023-10-20'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Interactive Sections
            Row(
              children: [
                Expanded(
                  child: BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.myComments, style: const TextStyle(color: AppColors.textSecondaryLight)),
                        const SizedBox(height: 8),
                        const Text('3', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBase)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.likedAreas, style: const TextStyle(color: AppColors.textSecondaryLight)),
                        const SizedBox(height: 8),
                        const Text('12', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBase)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                label: Text(l10n.logout, style: const TextStyle(color: AppColors.danger)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonItem(BuildContext context, String from, String to, String date) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      title: Text('$from vs $to', style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(l10n.assessmentDate(date), style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: () {},
    );
  }
}
