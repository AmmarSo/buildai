import 'package:flutter/material.dart';
import 'package:buildai/models/search_result.dart';
import 'package:buildai/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lottie/lottie.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class DetailScreen extends StatefulWidget {
  final SearchResult result;

  const DetailScreen({Key? key, required this.result, required String documentId}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isLoading = true;
  bool isGeneratingCourse = false;
  String documentText = "Chargement...";
  String? aRetenir;
  String? thematique;
  String? externalDescription;
  String generatedCourse = "";
  final ScrollController _scrollController = ScrollController(); // Controller pour le scroll

  @override
  void initState() {
    super.initState();
    fetchDocumentDetails();
  }

  Future<void> fetchDocumentDetails() async {
    try {
      final documentDetail = await ApiService.getDocumentDetail(widget.result.id);

      if (documentDetail.texte == "N/A" || documentDetail.texte == null) {
        externalDescription = await ApiService.fetchExternalDescription(widget.result.titre);
      }

      if (!mounted) return;
      setState(() {
        documentText = documentDetail.texte != "N/A"
            ? documentDetail.texte!
            : externalDescription ?? "Aucune information disponible.";
        aRetenir = documentDetail.aRetenir != "N/A" ? documentDetail.aRetenir : null;
        thematique = documentDetail.theme != "N/A" ? documentDetail.theme : null;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        documentText = "❌ Impossible de charger les détails.";
        isLoading = false;
      });
    }
  }

  Future<void> generateCourse() async {
    setState(() {
      isGeneratingCourse = true;
      generatedCourse = "";
    });

    // Descendre jusqu'au chargement
    _scrollToBottom();

    try {
      String response = await ApiService.askLLM("Tu es un expert dans le domaine du batiment, tu enseigne, tu va créer un cours en commençant par le titre du cours. TU va le strucutrer de manière propre et complète. Peux-tu générer un cours sur le thème suivant : ${widget.result.titre} ?");
      if (!mounted) return;

      setState(() {
        isGeneratingCourse = false;
        generatedCourse = response;
      });

      // Descendre jusqu'au résultat
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => isGeneratingCourse = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Erreur lors de la génération du cours."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

Future<void> saveCourseAsPDF() async {
  // Charger la police depuis les assets
  final fontData = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
  final ttf = pw.Font.ttf(fontData);

  final pdf = pw.Document();

  // Utilisation de MultiPage avec pw.Paragraph qui supporte le débordement sur plusieurs pages
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return [
          pw.Paragraph(
            text: generatedCourse,
            style: pw.TextStyle(font: ttf, fontSize: 14),
          ),
        ];
      },
    ),
  );

  // Demande la permission pour écrire dans le dossier Téléchargements
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.storage.request();
  }

  try {
    final directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Dossier Téléchargements non trouvé."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Nettoyer le titre pour obtenir un nom de fichier valide
    String sanitizedTitle = widget.result.titre.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File("${directory.path}/$sanitizedTitle.pdf");

    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Cours enregistré en PDF dans le dossier Téléchargements."),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("❌ Erreur lors de l'enregistrement du PDF."),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Colors.white;
    const textColor = Color(0xFF202124);
    const chipBackground = Color(0xFFE8F0FE);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 1,
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: widget.result.id,
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    widget.result.titre,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (thematique != null && thematique!.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  children: thematique!.split(',').map((theme) {
                    return Chip(
                      backgroundColor: chipBackground,
                      label: Text(
                        theme.trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              if (aRetenir != null && aRetenir!.isNotEmpty) ...[
                const Text(
                  "📌 À retenir",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    aRetenir!,
                    style: const TextStyle(fontSize: 16, color: textColor),
                  ),
                ),
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onTap: isGeneratingCourse ? null : generateCourse,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color.fromARGB(255, 79, 166, 228), Color.fromARGB(255, 94, 9, 221)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Générer un cours",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (isGeneratingCourse)
                Center(
                  child: Column(
                    children: [
                      Lottie.asset('assets/loading.json', width: 150),
                      const SizedBox(height: 16),
                      const Text(
                        "Génération du cours en cours...",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              if (generatedCourse.isNotEmpty) ...[
                const Text(
                  "📝 Cours généré",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: chipBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: MarkdownBody(
                    data: generatedCourse,
                    selectable: true,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
  child: GestureDetector(
    onTap: saveCourseAsPDF,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6F61), Color(0xFFEF5350)], // Dégradé rouge
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Text(
            "Télécharger en PDF",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  ),
),

              ],
            ],
            ],
          ),
        ),
      ),
    );
  }
}
