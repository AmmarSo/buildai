
class SearchResult {
  final String id;
  final String titre;
  final String lien;
  final String source;
  final String theme;
  final double score;

  SearchResult({
    required this.id,
    required this.titre,
    required this.lien,
    required this.source,
    required this.theme,
    required this.score,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    String id = json["payload"]["mongo_id"] ?? ""; // Assurez-vous qu'on récupère bien `mongo_id`

    if (id.length != 24) {
      print("⚠️ Erreur: ID MongoDB invalide détecté -> $id");
    }

    return SearchResult(
      id: id,
      titre: json["payload"]["titre"] ?? "Titre inconnu",
      lien: json["payload"]["lien"] ?? "",
      source: _formatSource(json["payload"]["source"] ?? ""),
      theme: json["payload"]["theme"] ?? "Non spécifié",
      score: (json["score"] ?? 0).toDouble(),
    );
  }

  static String _formatSource(String rawSource) {
    switch (rawSource) {
      case "site1":
        return "tpdemain.com";
      case "site2":
        return "dispositif-rexbp.com";
      case "site3":
        return "proreno.fr";
      case "site4":
        return "amaco.org";
      case "site6":
        return "mooc-batiment-durable.fr";
      default:
        return rawSource;
    }
  }
}
