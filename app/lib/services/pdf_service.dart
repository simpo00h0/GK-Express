import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/parcel.dart';

class PdfService {
  // Ouvrir le dialogue d'impression système
  static Future<void> generateAndPrintParcelPdf(
    Parcel parcel,
    BuildContext context,
  ) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF9C27B0)),
                  SizedBox(height: 16),
                  Text('Préparation du PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      final pdf = await _generateParcelPdf(parcel);

      // Fermer l'indicateur de chargement
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Obtenir la liste des imprimantes disponibles
      final printers = await Printing.listPrinters();

      debugPrint('Imprimantes trouvées: ${printers.length}');
      for (var p in printers) {
        debugPrint('  - ${p.name} (default: ${p.isDefault})');
      }

      if (printers.isEmpty) {
        // Aucune imprimante trouvée - utiliser l'aperçu système
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Aucune imprimante détectée. Ouverture de l\'aperçu...',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          // Ouvrir l'aperçu d'impression système
          await Printing.layoutPdf(onLayout: (format) async => pdf);
        }
        return;
      }

      // Afficher le dialogue de sélection d'imprimante
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.print, color: Color(0xFF9C27B0)),
                SizedBox(width: 12),
                Text('Choisir une imprimante'),
              ],
            ),
            content: SizedBox(
              width: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: printers.length,
                itemBuilder: (context, index) {
                  final printer = printers[index];
                  return ListTile(
                    leading: Icon(
                      printer.isDefault ? Icons.print : Icons.print_outlined,
                      color: printer.isDefault
                          ? const Color(0xFF9C27B0)
                          : Colors.grey,
                    ),
                    title: Text(printer.name),
                    subtitle: printer.isDefault
                        ? const Text('Par défaut')
                        : null,
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await _printToPrinter(pdf, printer, context);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  // Utiliser l'aperçu d'impression système
                  await Printing.layoutPdf(onLayout: (format) async => pdf);
                },
                icon: const Icon(Icons.preview),
                label: const Text('Aperçu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Fermer le dialogue de chargement si ouvert
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la préparation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Erreur PDF: $e');
    }
  }

  // Imprimer directement vers une imprimante
  static Future<void> _printToPrinter(
    Uint8List pdf,
    Printer printer,
    BuildContext context,
  ) async {
    try {
      final result = await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) async => pdf,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result
                  ? 'Impression envoyée à ${printer.name}'
                  : 'Échec de l\'impression',
            ),
            backgroundColor: result ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Sauvegarder le PDF dans un fichier
  static Future<String?> _savePdfToFile(Uint8List pdf, Parcel parcel) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'GK_Express_${parcel.id.substring(0, 8).toUpperCase()}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdf);
      return file.path;
    } catch (e) {
      return null;
    }
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
