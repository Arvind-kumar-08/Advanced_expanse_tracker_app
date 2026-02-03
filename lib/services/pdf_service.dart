import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/transaction_model.dart';
import '../core/utils/date_formatter.dart';
import 'package:intl/intl.dart';

/// Service for generating PDF reports
class PDFService {
  /// Generate monthly report PDF
  Future<void> generateMonthlyReport({
    required List<TransactionModel> transactions,
    required int month,
    required int year,
  }) async {
    try {
      final pdf = pw.Document();
      final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

      // Calculate totals
      final income = transactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);

      final expense = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      final balance = income - expense;

      // Build PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Text(
                'Monthly Expense Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 10),

            // Month and Year
            pw.Text(
              '${DateFormatter.getMonthName(month)} $year',
              style: const pw.TextStyle(fontSize: 16),
            ),

            pw.SizedBox(height: 10),

            // Generated Date
            pw.Text(
              'Generated on: ${DateFormatter.formatDate(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),

            pw.Divider(),

            pw.SizedBox(height: 20),

            // Summary Section
            pw.Text(
              'Summary',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            _buildSummaryTable(income, expense, balance, currencyFormatter),

            pw.SizedBox(height: 30),

            // Transactions Section
            pw.Text(
              'Transactions',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            _buildTransactionsTable(transactions, currencyFormatter),
          ],
        ),
      );

      // Save and open PDF
      await _savePDF(pdf, 'expense_report_${month}_$year.pdf');
    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
  }

  /// Build summary table
  pw.Widget _buildSummaryTable(
      double income,
      double expense,
      double balance,
      NumberFormat formatter,
      ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        _buildTableRow('Total Income', formatter.format(income), PdfColors.green),
        _buildTableRow('Total Expense', formatter.format(expense), PdfColors.red),
        _buildTableRow('Balance', formatter.format(balance), PdfColors.blue),
      ],
    );
  }

  /// Build table row
  pw.TableRow _buildTableRow(String label, String value, PdfColor color) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// Build transactions table
  pw.Widget _buildTransactionsTable(
      List<TransactionModel> transactions,
      NumberFormat formatter,
      ) {
    // Sort by date descending
    final sortedTransactions = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableHeader('Date'),
            _buildTableHeader('Category'),
            _buildTableHeader('Type'),
            _buildTableHeader('Amount'),
          ],
        ),

        // Rows
        ...sortedTransactions.map((transaction) {
          final isIncome = transaction.type == TransactionType.income;
          return pw.TableRow(
            children: [
              _buildTableCell(DateFormatter.formatDate(transaction.date)),
              _buildTableCell(transaction.category),
              _buildTableCell(isIncome ? 'Income' : 'Expense'),
              _buildTableCell(
                '${isIncome ? '+' : '-'} ${formatter.format(transaction.amount)}',
                color: isIncome ? PdfColors.green : PdfColors.red,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Build table header cell
  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  /// Build table cell
  pw.Widget _buildTableCell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: color),
      ),
    );
  }

  /// Save and open PDF
  Future<void> _savePDF(pw.Document pdf, String filename) async {
    // For mobile: Save to Downloads and share
    if (Platform.isAndroid || Platform.isIOS) {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: filename,
      );
    } else {
      // For desktop: Save to Documents
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/$filename');
      await file.writeAsBytes(await pdf.save());
      print('PDF saved to: ${file.path}');
    }
  }
}