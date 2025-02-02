import 'package:flutter/material.dart';
import 'package:buildai/models/search_result.dart';
import 'package:buildai/screens/detail_screen.dart';
import 'package:buildai/services/api_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<SearchResult> searchResults = [];
  bool isLoading = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _textFocusNode = FocusNode(); // Pour empêcher le clavier de s'ouvrir

  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  late Timer _animationTimer;
  List<double> barHeights = [5, 10, 5];

  int currentPage = 1;
  int totalResults = 0;
  static const int resultsPerPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFocusNode.unfocus(); // Désactive le focus au chargement
    });
  }

  @override
  void dispose() {
    _animationTimer.cancel();
    _textFocusNode.dispose();
    super.dispose();
  }

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
    _textFocusNode.unfocus(); // Désactive le clavier avant de naviguer
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetailScreen(result: result, documentId: ''),
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

  void startListening() async {
    bool available = await speech.initialize(
      onStatus: (status) {
        if (status == "done") {
          setState(() {
            isListening = false;
            _animationTimer.cancel();
            search();
          });
        }
      },
      onError: (error) {
        setState(() {
          isListening = false;
          _animationTimer.cancel();
        });
      },
    );

    if (available) {
      setState(() => isListening = true);

      _animationTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
        setState(() {
          barHeights = List.generate(3, (_) => (5 + (20 * (0.5 + 0.5 * (0.5 - 0.5 * (DateTime.now().millisecond % 100) / 100)))));
        });
      });

      speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
      );
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _textFocusNode, // Désactive le focus au retour
                      decoration: InputDecoration(
                        hintText: "Rechercher un document...",
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => search(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.blue),
                    onPressed: search,
                  ),
                  GestureDetector(
                    onTap: startListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isListening ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: isListening
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: barHeights.map((height) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 5,
                                  height: height,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }).toList(),
                            )
                          : const Icon(Icons.mic, color: Colors.white),
                    ),
                  ),
                ],
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
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
