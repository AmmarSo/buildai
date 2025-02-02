import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buildai/models/search_result.dart';
import 'package:buildai/models/document_detail.dart';

class ApiService {
  static const String baseUrl = "http://192.168.137.1:5001"; // Ton IP locale

  // Fonction pour effectuer une recherche avec un mot-clé
  static Future<List<SearchResult>> search(String query) async {
    final response = await http.get(Uri.parse("$baseUrl/search?q=$query&similarity=0.3"));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> results = data["results"];
      return results.map((json) => SearchResult.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des résultats");
    }
  }

  // Fonction pour récupérer les détails d'un document par son ID
  static Future<DocumentDetail> getDocumentDetail(String id) async {
    final response = await http.get(Uri.parse("$baseUrl/document/$id"));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return DocumentDetail.fromJson(data);
    } else {
      throw Exception("Erreur lors de la récupération du détail du document");
    }
  }

  // 🚀 Fonction pour récupérer une description externe depuis Wikidata
  static Future<String?> fetchExternalDescription(String query) async {
    try {
      final response = await http.get(Uri.parse(
          "https://www.wikidata.org/w/api.php?action=wbsearchentities&search=$query&language=fr&format=json"));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey("search") && data["search"].isNotEmpty) {
          return data["search"][0]["description"];
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
