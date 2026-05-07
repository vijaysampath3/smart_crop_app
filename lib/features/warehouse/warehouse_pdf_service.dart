import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'warehouse_plan_model.dart';

class WarehousePdfService {
  static Future<void> generateAndSavePdf(WarehousePlanResult plan, BuildContext context) async {
    try {
      final pdf = pw.Document();

      // Add a page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Text('Smart Crop Assistant', style: pw.TextStyle(color: PdfColors.green800, fontSize: 12)),
            );
          },
          build: (pw.Context context) => [
            // Title
            pw.Header(
              level: 0,
              child: pw.Text('Warehouse Storage Plan', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
            ),
            pw.SizedBox(height: 20),

            // Recommended Type
            _buildSectionTitle('Recommended Type'),
            pw.Text(plan.type, style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 16),

            // Capacity & Budget
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBox('Total Capacity', plan.capacity),
                _buildInfoBox('Estimated Budget', plan.budget),
              ],
            ),
            pw.SizedBox(height: 16),

            // Dimensions
            _buildSectionTitle('Dimensions'),
            pw.Text('Length: ${plan.dimensions.length}', style: pw.TextStyle(fontSize: 14)),
            pw.Text('Width: ${plan.dimensions.width}', style: pw.TextStyle(fontSize: 14)),
            pw.Text('Height: ${plan.dimensions.height}', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 16),

            // Construction Steps
            _buildSectionTitle('Construction Steps'),
            ...plan.steps.map((step) => pw.Bullet(text: step, bulletSize: 4, style: pw.TextStyle(fontSize: 14))),
            pw.SizedBox(height: 16),

            // Storage Tips
            _buildSectionTitle('Storage Tips'),
            ...plan.tips.map((tip) => pw.Bullet(text: tip, bulletSize: 4, style: pw.TextStyle(fontSize: 14))),
          ],
        ),
      );

      // Get appropriate directory depending on OS constraints
      final directory = await getApplicationDocumentsDirectory();
      
      // Save PDF locally
      final file = File('${directory.path}/storage_plan.pdf');
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      // Show success message and option to open/share
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved successfully to: ${file.path}'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Share/Open',
              textColor: Colors.white,
              onPressed: () {
                Printing.sharePdf(bytes: pdfBytes, filename: 'storage_plan.pdf');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey700,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoBox(String title, String value) {
    return pw.Container(
      width: 220,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 10, color: PdfColors.green800)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
        ],
      ),
    );
  }
}
