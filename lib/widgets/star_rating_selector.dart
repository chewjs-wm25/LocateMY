import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class StarRatingSelector extends StatelessWidget {
  final String label;
  final int rating;
  final Function(int) onRatingChanged;

  const StarRatingSelector({
    super.key,
    required this.label,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: AppColors.textPrimaryLight),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => onRatingChanged(index + 1),
                child: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: index < rating ? Colors.amber : Colors.grey,
                  size: 28,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
