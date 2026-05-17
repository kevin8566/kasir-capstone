class ExpenseModel {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String category; // 'Operasional', 'Bahan Baku', 'Gaji', dll.
  
  // [INTEGRASI HPP & STOK]
  final String? linkedProductId; // ID produk yang stoknya bertambah
  final int? addedStock;         // Berapa banyak stok yang ditambahkan
  final double? calculatedHPP;   // Hasil hitung: amount / addedStock

  ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.linkedProductId,
    this.addedStock,
    this.calculatedHPP,
  });
}