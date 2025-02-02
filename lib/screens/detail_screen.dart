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
      final documentDetail =
          await ApiService.getDocumentDetail(widget.result.id);

      // Si le texte n'est pas disponible, récupère une description externe
      if (documentDetail.texte == "N/A" || documentDetail.texte == null) {
        externalDescription =
            await ApiService.fetchExternalDescription(widget.result.titre);
      }

      if (!mounted) return;
      setState(() {
        documentText = documentDetail.texte != "N/A"
            ? documentDetail.texte!
            : externalDescription ?? "Aucune information disponible.";
        aRetenir =
            documentDetail.aRetenir != "N/A" ? documentDetail.aRetenir : null;
        thematique =
            documentDetail.theme != "N/A" ? documentDetail.theme : null;
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

  @override
  Widget build(BuildContext context) {
    // Palette minimaliste
    const backgroundColor = Colors.white;
    const accentColor = Color(0xFF1A73E8);
    const textColor = Color(0xFF202124);
    const chipBackground = Color(0xFFE8F0FE);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 1,
        automaticallyImplyLeading: true,
        // Pas de titre dans l'AppBar, le titre est affiché dans le corps
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre du document (affiché dans le corps)
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
              // Thématiques sous forme de Chips (si disponibles)
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
              // Affichage de la source
              Text(
                "Source : ${widget.result.source}",
                style: const TextStyle(fontSize: 14, color: textColor),
              ),
              const SizedBox(height: 24),
              // Section "À retenir" (si disponible)
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    aRetenir!,
                    style: const TextStyle(fontSize: 16, color: textColor),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Section "Contenu du document"
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        documentText,
                        style:
                            const TextStyle(fontSize: 16, color: textColor),
                      ),
                    ),
              const SizedBox(height: 32),
              // Bouton "Voir la source" stylisé
              if (widget.result.lien.isNotEmpty)
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () async {
                          final uri = Uri.parse(widget.result.lien);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.open_in_browser,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "🔗 Voir la source",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
