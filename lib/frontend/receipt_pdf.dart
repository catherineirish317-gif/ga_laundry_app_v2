import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds a PDF receipt and opens the phone's share / save sheet.
/// Works for both the customer receipt and the admin order record.
/// Note: the PDF uses "PHP" instead of the peso sign, because the built-in
/// PDF font does not contain that symbol.
Future<void> shareReceiptPdf({
  required String orderId,
  required String customerName,
  String? phone,
  required List<MapEntry<String, String>> details,
  required double total,
  required String paymentMethod,
  String? paymentStatus,
  String? dateText,
}) async {
  const PdfColor brand = PdfColor.fromInt(0xFF1FBFB0);
  const PdfColor ink = PdfColor.fromInt(0xFF10303F);
  const PdfColor muted = PdfColor.fromInt(0xFF5A7382);

  final String when = dateText ?? _formatNow();
  final String totalText = total == 0 ? 'Free Laundry' : 'PHP ${total.toStringAsFixed(2)}';

  pw.Widget row(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: muted)),
          pw.SizedBox(width: 12),
          pw.Flexible(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 10,
                color: ink,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => [
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text('G A LAUNDRY SHOP',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: brand)),
              pw.SizedBox(height: 3),
              pw.Text('Purok 3, Brgy. Bambang, Nagcarlan, Laguna',
                  style: pw.TextStyle(fontSize: 9, color: muted)),
              pw.Text('Contact: +63 928-188-6235', style: pw.TextStyle(fontSize: 9, color: muted)),
              pw.Text('Open Mon to Sat, 8 AM - 5 PM  |  Sundays: drop off only',
                  style: pw.TextStyle(fontSize: 8, color: muted)),
            ],
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          decoration: const pw.BoxDecoration(color: brand),
          child: pw.Center(
            child: pw.Text('DIGITAL RECEIPT',
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 1.5)),
          ),
        ),
        pw.SizedBox(height: 12),
        row('Order ID', orderId, bold: true),
        row('Date', when),
        row('Customer', customerName),
        if (phone != null && phone.trim().isNotEmpty) row('Phone', phone),
        pw.Divider(color: PdfColors.grey400),
        ...details.map((e) => row(e.key, e.value)),
        pw.Divider(color: PdfColors.grey400),
        row('Payment Method', paymentMethod),
        if (paymentStatus != null && paymentStatus.isNotEmpty) row('Payment Status', paymentStatus),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: brand, width: 1.2),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ink)),
              pw.Text(totalText, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: brand)),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Center(
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.code128(),
            data: orderId,
            width: 180,
            height: 44,
            drawText: false,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(child: pw.Text('Present this upon pickup / claiming', style: pw.TextStyle(fontSize: 8, color: muted))),
        pw.SizedBox(height: 14),
        pw.Center(
          child: pw.Text('Thank you for choosing G A Laundry Shop!',
              style: pw.TextStyle(fontSize: 10, color: brand, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    ),
  );

  final bytes = await doc.save();
  final safeId = orderId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
  await Printing.sharePdf(bytes: bytes, filename: 'receipt_$safeId.pdf');
}

String _formatNow() {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final d = DateTime.now();
  final int h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
  final String m = d.minute.toString().padLeft(2, '0');
  return '${months[d.month - 1]} ${d.day}, ${d.year}  $h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
}