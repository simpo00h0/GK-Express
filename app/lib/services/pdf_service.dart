import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart';
import 'package:intl/intl.dart';
import '../models/parcel.dart';

class PdfService {
  static Future<void> generateAndPrintParcelPdf(Parcel parcel) async {
    final pdf = await _generateParcelPdf(parcel);
    await Printing.layoutPdf(onLayout: (format) async => pdf);
  }

  static Future<void> generateAndShareParcelPdf(Parcel parcel) async {
    final pdf = await _generateParcelPdf(parcel);
    await Printing.sharePdf(
      bytes: pdf,
      filename: 'GK_Express_${parcel.id.substring(0, 8).toUpperCase()}.pdf',
    );
  }

  static Future<Uint8List> _generateParcelPdf(Parcel parcel) async {
    final pdf = pw.Document();
    final shortId = parcel.id.substring(0, 8).toUpperCase();
    final date = DateFormat('dd/MM/yyyy HH:mm').format(parcel.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(shortId),
              pw.SizedBox(height: 30),

              // QR Code and Info Row
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // QR Code
                  _buildQrCodeSection(parcel, shortId),
                  pw.SizedBox(width: 40),
                  // Info
                  pw.Expanded(child: _buildInfoSection(parcel, date)),
                ],
              ),
              pw.SizedBox(height: 30),

              // Sender and Receiver
              _buildContactsSection(parcel),
              pw.SizedBox(height: 30),

              // Footer
              _buildFooter(shortId),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String shortId) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#9C27B0'),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'GK EXPRESS',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'Transport International de Colis',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              '#$shortId',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#9C27B0'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildQrCodeSection(Parcel parcel, String shortId) {
    final qrData = _generateQrData(parcel, shortId);
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 2),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.BarcodeWidget(
            data: qrData,
            barcode: Barcode.qrCode(),
            width: 150,
            height: 150,
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Scannez pour les details',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static String _generateQrData(Parcel parcel, String shortId) {
    final date = DateFormat('dd/MM/yyyy HH:mm').format(parcel.createdAt);
    final statusText = _getStatusText(parcel.status);
    final paymentStatus = parcel.isPaid ? 'Paye' : 'Non paye';

    return '''GK EXPRESS - Colis #$shortId
Expediteur: ${parcel.senderName} (${parcel.senderPhone})
Destinataire: ${parcel.receiverName} (${parcel.receiverPhone})
Destination: ${parcel.destination}
Statut: $statusText
Prix: ${parcel.price.toStringAsFixed(2)} EUR ($paymentStatus)
Date: $date
Suivi: gkexpress.com/track/$shortId''';
  }

  static String _getStatusText(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.created:
        return 'Cree';
      case ParcelStatus.inTransit:
        return 'En Transit';
      case ParcelStatus.arrived:
        return 'Arrive';
      case ParcelStatus.delivered:
        return 'Livre';
      case ParcelStatus.issue:
        return 'Probleme';
    }
  }

  static pw.Widget _buildInfoSection(Parcel parcel, String date) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'Destination',
            parcel.destination,
            PdfColor.fromHex('#4FACFE'),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow(
            'Statut',
            _getStatusText(parcel.status),
            _getStatusColor(parcel.status),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow(
            'Prix',
            '${parcel.price.toStringAsFixed(2)} EUR',
            PdfColor.fromHex('#10B981'),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow(
            'Paiement',
            parcel.isPaid ? 'Paye' : 'Non paye',
            parcel.isPaid
                ? PdfColor.fromHex('#10B981')
                : PdfColor.fromHex('#EF4444'),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow('Date de creation', date, PdfColors.grey700),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, PdfColor color) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
      ],
    );
  }

  static PdfColor _getStatusColor(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.created:
        return PdfColor.fromHex('#6366F1');
      case ParcelStatus.inTransit:
        return PdfColor.fromHex('#F59E0B');
      case ParcelStatus.arrived:
        return PdfColor.fromHex('#3B82F6');
      case ParcelStatus.delivered:
        return PdfColor.fromHex('#10B981');
      case ParcelStatus.issue:
        return PdfColor.fromHex('#EF4444');
    }
  }

  static pw.Widget _buildContactsSection(Parcel parcel) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _buildContactCard(
            'EXPEDITEUR',
            parcel.senderName,
            parcel.senderPhone,
            PdfColor.fromHex('#667EEA'),
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: _buildContactCard(
            'DESTINATAIRE',
            parcel.receiverName,
            parcel.receiverPhone,
            PdfColor.fromHex('#F093FB'),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildContactCard(
    String title,
    String name,
    String phone,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            name,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            phone,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(String shortId) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Suivi en ligne:',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'gkexpress.com/track/$shortId',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#9C27B0'),
                ),
              ),
            ],
          ),
          pw.Text(
            'GK Express - Document genere automatiquement',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }
}
