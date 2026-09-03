import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class BentoCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? height;
  final CrossAxisAlignment crossAxisAlignment;

  const BentoCard({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.backgroundColor,
    this.height,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderLight,
          width: 1.0,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          // 如果外部提供了高度（比如在 Grid 或 Row 中被 Expanded 嵌套），
          // 我们使用 MainAxisSize.max 以允许内部 Spacer 工作。
          mainAxisSize: height != null ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            if (title != null) ...[
              Text(
                title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
              ),
              const SizedBox(height: 16),
            ],
            // 使用 Flexible 而非强制包裹，增强对各种父容器的适应性
            height != null ? Expanded(child: child) : child,
          ],
        ),
      ),
    );
  }
}
