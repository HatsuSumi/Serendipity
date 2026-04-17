import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/membership_provider.dart';
import '../../../models/enums.dart';
import '../../../models/user.dart';

class ProfileUserCardSection extends StatelessWidget {
  final User? user;
  final MembershipInfo? membershipInfo;
  final VoidCallback onMembershipTap;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditDisplayNameTap;

  const ProfileUserCardSection({
    super.key,
    required this.user,
    required this.membershipInfo,
    required this.onMembershipTap,
    required this.onLoginTap,
    required this.onRegisterTap,
    required this.onAvatarTap,
    required this.onEditDisplayNameTap,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return _LoggedOutUserCard(
        membershipInfo: membershipInfo,
        onMembershipTap: onMembershipTap,
        onLoginTap: onLoginTap,
        onRegisterTap: onRegisterTap,
      );
    }

    return _LoggedInUserCard(
      user: user!,
      membershipInfo: membershipInfo,
      onMembershipTap: onMembershipTap,
      onAvatarTap: onAvatarTap,
      onEditDisplayNameTap: onEditDisplayNameTap,
    );
  }
}

class _LoggedInUserCard extends StatelessWidget {
  final User user;
  final MembershipInfo? membershipInfo;
  final VoidCallback onMembershipTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditDisplayNameTap;

  const _LoggedInUserCard({
    required this.user,
    required this.membershipInfo,
    required this.onMembershipTap,
    required this.onAvatarTap,
    required this.onEditDisplayNameTap,
  });

  @override
  Widget build(BuildContext context) {
    final membershipLabel =
        membershipInfo?.isPremium == true ? '会员有效中' : '免费版';
    final membershipColor = membershipInfo?.isPremium == true
        ? Colors.amber.shade700
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final canEditProfile = AppConfig.serverType == ServerType.customServer;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: canEditProfile ? onAvatarTap : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.displayName
                                    ?.substring(0, 1)
                                    .toUpperCase() ??
                                user.email
                                    ?.substring(0, 1)
                                    .toUpperCase() ??
                                user.phoneNumber?.substring(
                                      user.phoneNumber!.length - 4,
                                    ) ??
                                '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  if (canEditProfile)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 11,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: canEditProfile ? onEditDisplayNameTap : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName ??
                                user.email ??
                                user.phoneNumber ??
                                '用户',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (canEditProfile) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.authProvider == AuthProvider.email
                        ? '邮箱登录'
                        : '手机号登录',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onMembershipTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            size: 16,
                            color: membershipColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            membershipLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: membershipColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: membershipColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoggedOutUserCard extends StatelessWidget {
  final MembershipInfo? membershipInfo;
  final VoidCallback onMembershipTap;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  const _LoggedOutUserCard({
    required this.membershipInfo,
    required this.onMembershipTap,
    required this.onLoginTap,
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.person_outline,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '未登录',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '登录后可同步数据到云端，也可随时查看会员权益',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onMembershipTap,
              icon: const Icon(Icons.workspace_premium_outlined),
              label: Text(
                membershipInfo?.isPremium == true ? '查看会员' : '查看会员权益',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: onLoginTap,
                  child: const Text('登录'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: onRegisterTap,
                  child: const Text('注册'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

