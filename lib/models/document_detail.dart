class DocumentDetail {
  final String id;
  final String titre;
  final String theme;
  final String source;
  final String lien;
  final String texte;
  final String aRetenir;
  final String sommaire;
  final String description;
  final String datePublication;
  final String titreVideo;
  final String lienVideo;
  final String nomChaine;
  final String vues;
  final int nbConsultation;
  final int nbEvaluationPositive;

  DocumentDetail({
    required this.id,
    required this.titre,
    required this.theme,
    required this.source,
    required this.lien,
    required this.texte,
    required this.aRetenir,
    required this.sommaire,
    required this.description,
    required this.datePublication,
    required this.titreVideo,
    required this.lienVideo,
    required this.nomChaine,
    required this.vues,
    required this.nbConsultation,
    required this.nbEvaluationPositive,
  });

  factory DocumentDetail.fromJson(Map<String, dynamic> json) {
    return DocumentDetail(
      id: json["_id"],
      titre: json["titre"] ?? "Titre inconnu",
      theme: json["theme"] ?? "Thème inconnu",
      source: json["source"] ?? "Source inconnue",
      lien: json["lien"] ?? "",
      texte: json["texte"] ?? "",
      aRetenir: json["A_retenir"] ?? "",
      sommaire: json["Sommaire"] ?? "",
      description: json["Description"] ?? "",
      datePublication: json["Date_publication"] ?? "Non spécifiée",
      titreVideo: json["Titre_video"] ?? "",
      lienVideo: json["Lien_video"] ?? "",
      nomChaine: json["Nom_chaine"] ?? "",
      vues: json["Vues"] ?? "",
      nbConsultation: json["Nb_consultation"] is int
          ? json["Nb_consultation"]
          : int.tryParse(json["Nb_consultation"] ?? "0") ?? 0,
      nbEvaluationPositive: json["Nb_evaluation_positive"] ?? 0,
    );
  }
}
