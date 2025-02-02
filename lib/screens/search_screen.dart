import 'package:flutter/material.dart';
import 'package:buildai/models/search_result.dart';
import 'package:buildai/screens/detail_screen.dart';
import 'package:buildai/services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<SearchResult> searchResults = [];
  bool isLoading = false;
  final TextEditingController _controller = TextEditingController();

  int currentPage = 1;
  int totalResults = 0;
  static const int resultsPerPage = 10;

  void search() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      isLoading = true;
      currentPage = 1;
    });

    try {
      final results = await ApiService.search(_controller.text);
      if (!mounted) return;

      setState(() {
        searchResults = results;
        totalResults = results.length;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Erreur lors de la recherche"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void navigateToDetail(BuildContext context, SearchResult result) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetailScreen(result: result, documentId: '',),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  void nextPage() {
    if ((currentPage * resultsPerPage) < totalResults) {
      setState(() => currentPage++);
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      setState(() => currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<SearchResult> paginatedResults = searchResults
        .skip((currentPage - 1) * resultsPerPage)
        .take(resultsPerPage)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("🔍 Recherche BuildAI")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "Rechercher un document...",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Colors.blue),
                    onPressed: search,
                  ),
                ),
                onSubmitted: (_) => search(),
              ),
            ),
            const SizedBox(height: 16),

            if (totalResults > 0)
              Text(
                totalResults > 190
                    ? "📊 Plus de 200 résultats trouvés"
                    : "📊 $totalResults résultats trouvés",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

            const SizedBox(height: 10),

            isLoading
                ? const CircularProgressIndicator()
                : paginatedResults.isEmpty
                    ? Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text(
                                "Aucun résultat trouvé",
                                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: paginatedResults.length,
                          itemBuilder: (context, index) {
                            final result = paginatedResults[index];

                            return GestureDetector(
                              onTap: () => navigateToDetail(context, result),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blue.shade100,
                                        child: const Icon(Icons.article, color: Colors.blue),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              result.titre,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "📌 ${result.theme}",
                                              style: const TextStyle(color: Colors.blue, fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "🔗 ${result.source}",
                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

            if (totalResults > resultsPerPage)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: currentPage > 1 ? previousPage : null,
                      icon: Icon(Icons.arrow_back, color: currentPage > 1 ? Colors.blue : Colors.grey),
                    ),
                    Text(
                      "Page $currentPage / ${((totalResults - 1) ~/ resultsPerPage) + 1}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: (currentPage * resultsPerPage) < totalResults ? nextPage : null,
                      icon: Icon(Icons.arrow_forward, color: (currentPage * resultsPerPage) < totalResults ? Colors.blue : Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
