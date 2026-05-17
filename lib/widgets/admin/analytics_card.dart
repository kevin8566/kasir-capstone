import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend; // Contoh: "+12%"
  final bool isPositive;

  const AnalyticsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend = '',
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (trend.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }
}