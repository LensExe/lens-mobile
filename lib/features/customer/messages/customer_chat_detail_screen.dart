import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';

class CustomerChatDetailScreen extends StatelessWidget {
  final String conversationId;

  const CustomerChatDetailScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customer_home/messages');
            }
          },
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.obsidian),
        ),
        title: Text(
          'Tin nhắn',
          style: AppTypography.titleMd(color: AppColors.obsidian),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.pageHorizontal),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.snow,
              borderRadius: BorderRadius.circular(AppTokens.cardRadius),
              border: Border.all(color: AppColors.pebble),
              boxShadow: const [AppTokens.surfaceShadow],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.messageSquareText,
                  size: 32,
                  color: AppColors.steel,
                ),
                const SizedBox(height: 16),
                Text(
                  'Không thể mở cuộc trò chuyện',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMd(color: AppColors.obsidian),
                ),
                const SizedBox(height: 8),
                Text(
                  'Backend hiện chưa cung cấp API tải hoặc gửi tin nhắn. '
                  'Cuộc trò chuyện $conversationId chưa được tạo và không có tin nhắn giả được lưu.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm(color: AppColors.steel)
                      .copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
