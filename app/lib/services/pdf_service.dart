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

  // Ouvrir le PDF avec le visualiseur par défaut de Windows
  static Future<void> generateAndOpenPdf(
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
                  Text('Génération du PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      final pdf = await _generateParcelPdf(parcel);

      // Sauvegarder le fichier
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'GK_Express_${parcel.id.substring(0, 8).toUpperCase()}.pdf';
      final filePath = '${directory.path}\\$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdf);

      // Fermer l'indicateur de chargement
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Ouvrir le fichier avec l'application par défaut
      await Process.run('cmd', ['/c', 'start', '', filePath]);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
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
    final invoiceNumber = 'FAC-$shortId-${DateFormat('yyyyMMdd').format(parcel.createdAt)}';
    final invoiceDate = DateFormat('dd/MM/yyyy').format(parcel.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête professionnel avec logo et informations entreprise
              _buildProfessionalHeader(invoiceNumber, invoiceDate),
              pw.SizedBox(height: 25),

              // Informations client et expéditeur
              _buildClientAndSenderSection(parcel),
              pw.SizedBox(height: 25),

              // Tableau détaillé des services
              _buildServicesTable(parcel, shortId),
              pw.SizedBox(height: 20),

              // Totaux et paiement
              _buildTotalsSection(parcel),
              pw.SizedBox(height: 25),

              // QR Code et code-barres pour suivi
              _buildTrackingSection(parcel, shortId),
              pw.SizedBox(height: 20),

              // Conditions et mentions légales
              _buildTermsAndConditions(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // En-tête professionnel de facture
  static pw.Widget _buildProfessionalHeader(String invoiceNumber, String invoiceDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(25),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#1A1A1A'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Logo et informations entreprise
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo sur fond blanc (comme l'original)
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    children: [
                      _buildGKLogo(),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Row(
                            children: [
                              pw.Text(
                                'EX',
                                style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('#E53935'),
                                ),
                              ),
                              pw.Text(
                                'press',
                                style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('#1A1A1A'),
                                ),
                              ),
                            ],
                          ),
                          pw.Text(
                            'DELIVERY',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#E53935'),
                              letterSpacing: 2,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Simple, rapide et efficace!',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontStyle: pw.FontStyle.italic,
                              color: PdfColor.fromHex('#1A1A1A'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Text(
                  'Service de livraison express',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey300,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Email: contact@gkexpress.com',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey400,
                  ),
                ),
                pw.Text(
                  'Téléphone: +33 1 XX XX XX XX',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey400,
                  ),
                ),
                pw.Text(
                  'Site web: www.gkexpress.com',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey400,
                  ),
                ),
              ],
            ),
          ),
          // Numéro de facture et date
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#E53935'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'FACTURE',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'N° $invoiceNumber',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Date: $invoiceDate',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Draw the GK logo for PDF (speedometer with G and K)
  static pw.Widget _buildGKLogo() {
    return pw.Container(
      width: 55,
      height: 55,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColor.fromHex('#1A1A1A'), width: 4),
        shape: pw.BoxShape.circle,
      ),
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          // G and K letters
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'G',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#E53935'),
                ),
              ),
              pw.Text(
                'K',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1A1A1A'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Section de suivi avec QR code et code-barres
  static pw.Widget _buildTrackingSection(Parcel parcel, String shortId) {
    final qrData = _generateQrData(parcel, shortId);
    
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // QR Code
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 1),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.BarcodeWidget(
                data: qrData,
                barcode: Barcode.qrCode(),
                width: 120,
                height: 120,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Scannez pour suivre',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        // Code-barres et informations de suivi
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SUIVI EN LIGNE',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1A1A1A'),
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Numéro de suivi:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      shortId,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#9C27B0'),
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.BarcodeWidget(
                      data: shortId,
                      barcode: Barcode.code128(),
                      width: 200,
                      height: 50,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'www.gkexpress.com/track/$shortId',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor.fromHex('#9C27B0'),
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
Prix: ${parcel.price.toStringAsFixed(0)} CFA ($paymentStatus)
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

  // Tableau détaillé des services
  static pw.Widget _buildServicesTable(Parcel parcel, String shortId) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Table(
        border: pw.TableBorder(
          verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 1),
          horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1.5),
        },
        children: [
          // En-tête du tableau
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1A1A1A'),
            ),
            children: [
              _buildTableCell('N°', isHeader: true),
              _buildTableCell('Description', isHeader: true),
              _buildTableCell('Statut', isHeader: true),
              _buildTableCell('Montant (FCFA)', isHeader: true, align: pw.TextAlign.right),
            ],
          ),
          // Ligne de service
          pw.TableRow(
            children: [
              _buildTableCell('#$shortId'),
              _buildTableCell(
                'Service de livraison express\n'
                'De: ${parcel.senderName}\n'
                'Vers: ${parcel.receiverName}\n'
                'Destination: ${parcel.destination}'
                '${_getPaymentInfo(parcel) != null ? '\nPaiement: ${_getPaymentInfo(parcel)}' : ''}',
              ),
              _buildTableCell(
                _getStatusText(parcel.status),
                statusColor: _getStatusColor(parcel.status),
              ),
              _buildTableCell(
                parcel.price.toStringAsFixed(0),
                align: pw.TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    PdfColor? statusColor,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader
              ? PdfColors.white
              : (statusColor != null ? PdfColors.white : PdfColor.fromHex('#1A1A1A')),
        ),
      ),
      decoration: statusColor != null
          ? pw.BoxDecoration(
              color: statusColor,
              borderRadius: pw.BorderRadius.circular(4),
            )
          : null,
    );
  }

  // Déterminer qui a payé (seulement si payé)
  static String? _getPaymentInfo(Parcel parcel) {
    if (parcel.isPaid) {
      if (parcel.paidAtOfficeId == parcel.originOfficeId) {
        return 'Payé par l\'expéditeur';
      } else if (parcel.paidAtOfficeId == parcel.destinationOfficeId) {
        return 'Payé par le destinataire';
      } else {
        return 'Payé';
      }
    }
    // Si non payé, ne rien retourner
    return null;
  }

  // Section des totaux
  static pw.Widget _buildTotalsSection(Parcel parcel) {
    final subtotal = parcel.price;
    final tva = subtotal * 0.18; // TVA de 18%
    final total = subtotal + tva;
    final paymentInfo = _getPaymentInfo(parcel);

    return pw.Row(
      children: [
        pw.Spacer(),
        pw.Container(
          width: 300,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildTotalRow('Sous-total HT', subtotal),
              pw.SizedBox(height: 8),
              _buildTotalRow('TVA (18%)', tva),
              pw.Divider(color: PdfColors.grey400, height: 20),
              _buildTotalRow(
                'TOTAL TTC',
                total,
                isTotal: true,
              ),
              pw.SizedBox(height: 15),
              // Statut de paiement
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: parcel.isPaid
                      ? PdfColor.fromHex('#10B981')
                      : PdfColor.fromHex('#EF4444'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      parcel.isPaid ? '✓ PAYÉ' : '⚠ NON PAYÉ',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    // Afficher qui a payé seulement si payé
                    if (paymentInfo != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        paymentInfo,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isTotal ? 13 : 11,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColor.fromHex('#1A1A1A'),
          ),
        ),
        pw.Text(
          '${amount.toStringAsFixed(0)} FCFA',
          style: pw.TextStyle(
            fontSize: isTotal ? 16 : 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1A1A1A'),
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

  // Section client et expéditeur
  static pw.Widget _buildClientAndSenderSection(Parcel parcel) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Client (Destinataire)
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FACTURÉ À',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  parcel.receiverName,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1A1A1A'),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Téléphone: ${parcel.receiverPhone}',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Destination: ${parcel.destination}',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 20),
        // Expéditeur
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'EXPÉDITEUR',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  parcel.senderName,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1A1A1A'),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Téléphone: ${parcel.senderPhone}',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Conditions et mentions légales
  static pw.Widget _buildTermsAndConditions() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CONDITIONS DE PAIEMENT',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1A1A'),
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '• Paiement possible à l\'envoi (par l\'expéditeur) ou à la réception (par le destinataire)\n'
            '• Paiement en espèces ou par carte bancaire\n'
            '• Si non payé à l\'envoi, le destinataire doit payer à la réception\n'
            '• Délai de paiement: 30 jours pour les clients professionnels\n'
            '• En cas de retard de paiement, des intérêts de 3% par mois seront appliqués',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
              height: 1.5,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'MENTIONS LÉGALES',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1A1A'),
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '• Cette facture est générée automatiquement par le système GK Express\n'
            '• En cas de réclamation, contactez-nous à contact@gkexpress.com\n'
            '• Les conditions générales de vente sont disponibles sur www.gkexpress.com/cgv\n'
            '• Numéro SIRET: [À compléter]\n'
            '• TVA Intracommunautaire: [À compléter]',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
              height: 1.5,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Document généré automatiquement',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
              pw.Text(
                'GK Express - Simple, rapide et efficace!',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
