import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';

class ExcelService {
  static String _fmt(double amount) {
    return 'Rp ${NumberFormat('#,###', 'id_ID').format(amount)}';
  }

  static Future<void> exportTransactionsToExcel(
    List<TransactionModel> transactions,
    String periodLabel,
  ) async {
    final excel = Excel.createExcel();

    // Hapus sheet default
    if (excel.tables.keys.contains('Sheet1')) {
      excel.delete('Sheet1');
    }

    // ── Sheet 1: Ringkasan ────────────────────────────────────
    final sheet = excel['Laporan Penjualan'];
    excel.setDefaultSheet('Laporan Penjualan');

    final hGreen = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#2ECC71'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final hBlue = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#2980B9'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final hDark = CellStyle(
      bold: true,
      fontSize: 14,
      backgroundColorHex: ExcelColor.fromHexString('#2C3E50'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final altRow = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#EBF5FB'));
    final greenBold = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#2ECC71'),
      horizontalAlign: HorizontalAlign.Right,
    );

    // Title
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('H1'));
    final t1 = sheet.cell(CellIndex.indexByString('A1'));
    t1.value = TextCellValue('LAPORAN KEUANGAN - KASIRKU');
    t1.cellStyle = hDark;

    // Periode & Tanggal cetak
    sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('H2'));
    final t2 = sheet.cell(CellIndex.indexByString('A2'));
    t2.value = TextCellValue('Periode: $periodLabel');
    t2.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#2ECC71'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center);

    sheet.merge(CellIndex.indexByString('A3'), CellIndex.indexByString('H3'));
    final t3 = sheet.cell(CellIndex.indexByString('A3'));
    t3.value = TextCellValue(
        'Dicetak: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now())}');
    t3.cellStyle = CellStyle(
        italic: true, horizontalAlign: HorizontalAlign.Center);

    // Ringkasan
    sheet.cell(CellIndex.indexByString('A5')).value =
        TextCellValue('RINGKASAN');
    sheet.cell(CellIndex.indexByString('A5')).cellStyle = hBlue;

    final totalSales =
        transactions.fold<double>(0, (s, t) => s + t.totalAmount);
    final totalItems =
        transactions.fold<int>(0, (s, t) => s + t.items.length);

    final summaryData = [
      ['Periode', periodLabel],
      ['Total Transaksi', '${transactions.length} transaksi'],
      ['Total Item Terjual', '$totalItems item'],
      ['Total Penjualan', _fmt(totalSales)],
    ];
    
    for (int i = 0; i < summaryData.length; i++) {
      final row = 6 + i;
      final labelCell = sheet.cell(CellIndex.indexByString('A$row'));
      labelCell.value = TextCellValue(summaryData[i][0]);
      labelCell.cellStyle = CellStyle(bold: true);
      final valCell = sheet.cell(CellIndex.indexByString('B$row'));
      valCell.value = TextCellValue(summaryData[i][1]);
      if (i == 3) valCell.cellStyle = greenBold;
    }

    // ── Header tabel transaksi ────────────────────────────────
    const headers = [
      'No', 'ID Transaksi', 'Tanggal', 'Bulan', 'Tahun',
      'Metode Bayar', 'Item', 'Total'
    ];
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 11));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = hGreen;
    }

    // ── Data transaksi ────────────────────────────────────────
    for (int i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      final rowIndex = 12 + i;
      final useAlt = i % 2 == 1;

      final itemNames = t.items.isNotEmpty
          ? t.items
              .map((e) => '${e.product.name} x${e.quantity}')
              .join(', ')
          : '-';

      final rowData = [
        IntCellValue(i + 1),
        TextCellValue(t.id),
        TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(t.date)),
        TextCellValue(DateFormat('MMMM', 'id_ID').format(t.date)),
        TextCellValue(DateFormat('yyyy').format(t.date)),           
        TextCellValue(t.paymentMethod),
        TextCellValue(itemNames),
        TextCellValue(_fmt(t.totalAmount)), // Teks Rupiah, atau ubah ke DoubleCellValue jika ingin diformat angka Excel
      ];

      for (int col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
        cell.value = rowData[col];
        if (col == 7) {
          cell.cellStyle = CellStyle(
            backgroundColorHex: useAlt
                ? ExcelColor.fromHexString('#EBF5FB')
                : ExcelColor.fromHexString('#FFFFFF'),
            bold: true,
            fontColorHex: ExcelColor.fromHexString('#2ECC71'),
            horizontalAlign: HorizontalAlign.Right,
          );
        } else {
          cell.cellStyle = useAlt ? altRow : CellStyle();
        }
      }
    }

    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 14);
    sheet.setColumnWidth(4, 8);
    sheet.setColumnWidth(5, 14);
    sheet.setColumnWidth(6, 35);
    sheet.setColumnWidth(7, 18);

    // ── Sheet 2: Detail Item ──────────────────────────────────
    final detail = excel['Detail Item'];
    const dHeaders = [
      'No', 'ID Transaksi', 'Tanggal', 'Bulan', 'Tahun',
      'Nama Produk', 'Qty', 'Harga Satuan', 'Subtotal'
    ];
    for (int col = 0; col < dHeaders.length; col++) {
      final cell = detail.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(dHeaders[col]);
      cell.cellStyle = hGreen;
    }

    int dr = 1;
    int no = 1;
    for (final t in transactions) {
      for (final item in t.items) {
        final useAlt = dr % 2 == 1;
        final rowData = [
          IntCellValue(no++),
          TextCellValue(t.id),
          TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(t.date)),
          TextCellValue(DateFormat('MMMM', 'id_ID').format(t.date)),
          TextCellValue(DateFormat('yyyy').format(t.date)),
          TextCellValue(item.product.name),
          IntCellValue(item.quantity),
          TextCellValue(_fmt(item.product.price)),
          TextCellValue(_fmt(item.total)),
        ];
        for (int col = 0; col < rowData.length; col++) {
          final cell = detail.cell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: dr));
          cell.value = rowData[col];
          if (col == 8) {
            cell.cellStyle = CellStyle(
              backgroundColorHex: useAlt
                  ? ExcelColor.fromHexString('#EBF5FB')
                  : ExcelColor.fromHexString('#FFFFFF'),
              bold: true,
              fontColorHex: ExcelColor.fromHexString('#2ECC71'),
              horizontalAlign: HorizontalAlign.Right,
            );
          } else {
            cell.cellStyle = useAlt ? altRow : CellStyle();
          }
        }
        dr++;
      }
    }

    detail.setColumnWidth(0, 5);
    detail.setColumnWidth(1, 22);
    detail.setColumnWidth(2, 20);
    detail.setColumnWidth(3, 14);
    detail.setColumnWidth(4, 8);
    detail.setColumnWidth(5, 22);
    detail.setColumnWidth(6, 6);
    detail.setColumnWidth(7, 16);
    detail.setColumnWidth(8, 18);

    // ── Generate & Download Otomatis (Web/Desktop/Mobile) ─────────────
    final fileBytes = excel.save();
    if (fileBytes == null) throw Exception('Gagal generate file Excel');

    // Catatan: Pada FileSaver, jangan memasukkan ekstensi (.xlsx) ke dalam nama string,
    // FileSaver akan menambahkannya secara otomatis.
    final fileName = 'Laporan_KasirKu_${periodLabel.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';

    // Proses Download Universal
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(fileBytes),
      ext: "xlsx",
      mimeType: MimeType.microsoftExcel,
    );
  }
}