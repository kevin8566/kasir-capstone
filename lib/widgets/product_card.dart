import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../core/theme.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  });

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Foto Produk ──────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 60,
                height: 60,
                child: product.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppTheme.lightBlue,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _defaultImage(),
                      )
                    : _defaultImage(),
              ),
            ),
            const SizedBox(width: 12),

            // ── Info Produk ──────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.category,
                    style: const TextStyle(
                        color: AppTheme.textGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(product.price),
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // ── Stok & Actions ───────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.stock > 5
                        ? AppTheme.primaryBlue.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Stok: ${product.stock}',
                    style: TextStyle(
                      color: product.stock > 5
                          ? AppTheme.primaryBlue
                          : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (showActions) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.edit,
                              size: 16, color: AppTheme.primaryBlue),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.delete,
                              size: 16, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultImage() {
    return Container(
      color: AppTheme.lightBlue,
      child: const Icon(Icons.inventory_2,
          color: AppTheme.primaryBlue, size: 28),
    );
  }
}