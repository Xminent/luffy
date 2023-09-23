import "package:flutter/material.dart";
import "package:luffy/api/mal.dart";
import "package:luffy/components/search_bar_result.dart";

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  Future<List<SearchResult>?>? _searchResultsFuture;

  Widget _buildResults() {
    return FutureBuilder(
      future: _searchResultsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.none) {
          return Container();
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final searchResults = snapshot.data;

        if (searchResults == null) {
          return const Center(
            child: Text("Could not connect with MyAnimeList."),
          );
        }

        return Container(
          color: Theme.of(context).colorScheme.background,
          child: ListView.builder(
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final anime = searchResults[index];
              final score = anime.score;
              final type = anime.type;
              final toShow = <Widget>[];

              if (score != null) {
                toShow.add(
                  Text(
                    "Score: $score",
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              }

              if (type.isNotEmpty) {
                if (toShow.isNotEmpty) {
                  toShow.add(
                    const SizedBox(
                      width: 8,
                    ),
                  );
                }

                toShow.add(
                  Text(
                    type,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              }

              return SearchResultComponent(
                anime: anime,
                score: score,
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Search"),
        ),
        body: Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.background,
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: "search for an anime e.g one piece",
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (value) {
                  setState(() {
                    _searchResultsFuture = MalService.search(value);
                  });
                },
              ),
              Expanded(
                child: _buildResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
