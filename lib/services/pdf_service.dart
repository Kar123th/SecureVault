import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfService {
  static Future<File> generatePdfFromImage(File imageFile, String fileName) async {
    final pdf = pw.Document();
    
    final image = pw.MemoryImage(imageFile.readAsBytesSync());

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(image),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/$fileName.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> generatePdfFromText(String text, String fileName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Text(text),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/$fileName.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
