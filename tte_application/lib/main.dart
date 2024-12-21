import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:signature/signature.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(PdfSignatureApp());
}

class PdfSignatureApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PdfSignatureScreen(),
    );
  }
}

class PdfSignatureScreen extends StatefulWidget {
  @override
  _PdfSignatureScreenState createState() => _PdfSignatureScreenState();
}

class _PdfSignatureScreenState extends State<PdfSignatureScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  File? _selectedPdf;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedPdf = File(result.files.single.path!);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF berhasil diunggah')),
      );
    }
  }

  Future<void> _addSignatureAndShare() async {
    if (_selectedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih file PDF terlebih dahulu')),
      );
      return;
    }

    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tanda tangan masih kosong')),
      );
      return;
    }

    // Konversi tanda tangan menjadi PNG bytes
    Uint8List? signatureBytes = await _signatureController.toPngBytes();
    if (signatureBytes == null) return;

    // Baca file PDF asli
    final pdf = pw.Document();
    final pdfBytes = await _selectedPdf!.readAsBytes();
    final pdfImage = pw.MemoryImage(signatureBytes);

    // Tambahkan tanda tangan ke PDF
    pdf.addPage(pw.Page(
      build: (context) {
        return pw.Stack(
          children: [
            pw.Image(pw.MemoryImage(pdfBytes), fit: pw.BoxFit.cover),
            pw.Positioned(
              bottom: 50, // Posisi tanda tangan
              left: 50,
              child: pw.Image(pdfImage, width: 100, height: 50),
            ),
          ],
        );
      },
    ));

    // Simpan PDF baru ke direktori sementara
    final tempDir = await getTemporaryDirectory();
    final signedPdfPath = '${tempDir.path}/signed_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final signedPdfFile = File(signedPdfPath);
    await signedPdfFile.writeAsBytes(await pdf.save());

    // Bagikan file PDF
    Share.shareXFiles([XFile(signedPdfFile.path)], text: 'PDF yang sudah ditandatangani');
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tanda Tangan PDF'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: _selectedPdf == null
                ? Center(child: Text('Belum ada PDF yang dipilih'))
                : SfPdfViewer.file(_selectedPdf!), // Tampilan PDF dengan scrolling
          ),
          SizedBox(height: 10),
          Container(
            color: Colors.grey[200],
            height: 200,
            child: Signature(
              controller: _signatureController,
              backgroundColor: Colors.white,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: _pickPdf,
                child: Text('Pilih PDF'),
              ),
              ElevatedButton(
                onPressed: () => _signatureController.clear(),
                child: Text('Bersihkan TTD'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              ),
              ElevatedButton(
                onPressed: _addSignatureAndShare,
                child: Text('Tandatangani & Bagikan'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
