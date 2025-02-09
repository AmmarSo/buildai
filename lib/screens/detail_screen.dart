import 'package:flutter/material.dart';
import 'package:buildai/models/search_result.dart';
import 'package:buildai/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailScreen extends StatefulWidget {
  final SearchResult result;

  const DetailScreen({Key? key, required this.result, required String documentId}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isLoading = true;
  String documentText = "Chargement...";
  String? aRetenir;
  String? thematique;
  String? externalDescription;

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
        documentText = documentDetail.texte != "N/A" ? documentDetail.texte! : externalDescription ?? "Aucune information disponible.";
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      String response = await ApiService.askLLM("Peux-tu générer un cours sur le thème suivant : ${widget.result.titre} ?");
      if (!mounted) return;
      Navigator.of(context).pop(); // Ferme la fenêtre de chargement

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Cours généré"),
            content: SingleChildScrollView(
              child: Text(response),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Fermer"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Ferme la fenêtre de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Erreur lors de la génération du cours."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
              const SizedBox(height: 16),
              Text(
                "Source : ${widget.result.source}",
                style: const TextStyle(fontSize: 14, color: textColor),
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
                const SizedBox(height: 24),
              ],
              const Text(
                "📄 Contenu du document",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        documentText,
                        style: const TextStyle(fontSize: 16, color: textColor),
                      ),
                    ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: generateCourse,
                icon: const Icon(Icons.school),
                label: const Text("Générer un cours"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
