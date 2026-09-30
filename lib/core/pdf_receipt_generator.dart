import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/formatters.dart';
import '../models/sale.dart';
import '../models/store_settings.dart';

class PdfReceiptGenerator {
  static Future<void> printReceipt(Sale sale, StoreSettings settings) async {
    final fontData = await rootBundle
        .load('fonts/NotoSansArabic-Regular.ttf')
        .catchError((_) => ByteData(0));
    final pw.Font? ttf = fontData.lengthInBytes > 0
        ? pw.Font.ttf(fontData)
        : null;
    final fallback = await PdfGoogleFonts.cairoRegular();

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                settings.storeName,
                style: pw.TextStyle(
                  font: ttf,
                  fontFallback: [fallback],
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              if (settings.phone.isNotEmpty)
                pw.Text(
                  settings.phone,
                  style: pw.TextStyle(
                    font: ttf,
                    fontFallback: [fallback],
                    fontSize: 12,
                  ),
                ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Date:',
                    style: pw.TextStyle(
                      font: ttf,
                      fontFallback: [fallback],
                      fontSize: 10,
                    ),
                  ),
                  pw.Text(
                    Formatters.dateTime(sale.createdAt),
                    style: pw.TextStyle(
                      font: ttf,
                      fontFallback: [fallback],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Invoice:',
                    style: pw.TextStyle(
                      font: ttf,
                      fontFallback: [fallback],
                      fontSize: 10,
                    ),
                  ),
                  pw.Text(
                    sale.id,
                    style: pw.TextStyle(
                      font: ttf,
                      fontFallback: [fallback],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Cashier:',
                    style: pw.TextStyle(
                      font: ttf,
                      fontFallback: [fallback],
                      fontSize: 10,
                    ),
                  ),
                  pw.Text(
                    sale.cashierName,
                    style: pw.TextStyle(
                      font: ttf,
                      fontFallback: [fallback],
                      fontSize: 10,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'Item',
                        style: pw.TextStyle(
                          font: ttf,
                          fontFallback: [fallback],
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Qty',
                        style: pw.TextStyle(
                          font: ttf,
                          fontFallback: [fallback],
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'Total',
                        style: pw.TextStyle(
                          font: ttf,
                          fontFallback: [fallback],
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ],
                  ),
                  ...sale.items.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Text(
                          item.name,
                          style: pw.TextStyle(
                            font: ttf,
                            fontFallback: [fallback],
                            fontSize: 10,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          Formatters.quantity(item.quantity),
                          style: pw.TextStyle(
                            font: ttf,
                            fontFallback: [fallback],
                            fontSize: 10,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          Formatters.money(item.total),
                          style: pw.TextStyle(
                            font: ttf,
                            fontFallback: [fallback],
                            fontSize: 10,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total:',
                    style: pw.TextStyle(
                      font: ttf,
                      fontFallback: [fallback],
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    Formatters.money(sale.total),
                    style: pw.TextStyle(
                      font: ttf,
                      fontFallback: [fallback],
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              if (settings.receiptFooter.isNotEmpty)
                pw.Text(
                  settings.receiptFooter,
                  style: pw.TextStyle(
                    font: ttf,
                    fontFallback: [fallback],
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                  textAlign: pw.TextAlign.center,
                  textDirection: pw.TextDirection.rtl,
                ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Receipt_${sale.id}',
    );
  }
}
