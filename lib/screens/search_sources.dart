import "package:cached_network_image/cached_network_image.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:luffy/api/anime.dart";
import "package:luffy/screens/details_sources.dart";
import "package:luffy/util.dart";

class SearchScreenSources extends StatefulWidget {
  const SearchScreenSources({super.key});

  @override
  State<SearchScreenSources> createState() => _SearchScreenSourcesState();
}

class _SearchScreenSourcesState extends State<SearchScreenSources>
    with AutomaticKeepAliveClientMixin {
  Stream<Map<String, List<Anime>>>? _searchResultsStream;

  Stream<Map<String, List<Anime>>> _search(String query) async* {
    final results = <String, List<Anime>>{};

    for (final source in sources) {
      prints("Searching ${source.name} for $query");
      final sourceResults = await source.search(query);
      prints("Found ${sourceResults.length} results for ${source.name}");

      results[source.name] = sourceResults;

      yield results;
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Search Sources"),
        ),
        body: Container(
          color: Theme.of(context).colorScheme.background,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: "search for an anime e.g one piece",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (value) {
                    setState(() {
                      _searchResultsStream = _search(value);
                    });
                  },
                ),
                const SizedBox(height: 16),
                StreamBuilder(
                  stream: _searchResultsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.none) {
                      return Container();
                    }

                    final searchResults = snapshot.data;

                    if (snapshot.connectionState != ConnectionState.active &&
                        searchResults?.length != sources.length) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (searchResults == null) {
                      return const Center(
                        child: Text("No results found"),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: searchResults.entries
                          .map(
                            (entry) {
                              final source = entry.key;
                              final results = entry.value;

                              return [
                                Text(
                                  source,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  "Found ${results.length} results",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                if (results.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 200,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: results.length,
                                      itemBuilder: (context, idx) {
                                        final anime = results[idx];
                                        final extractor = sources.firstWhere(
                                          (element) => element.name == source,
                                        );

                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailsScreenSources(
                                                  anime: anime,
                                                  animeId: null,
                                                  showId:
                                                      "$source-${anime.url}",
                                                  imageUrl: anime.imageUrl,
                                                  title: anime.title,
                                                  extractor: extractor,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            children: [
                                              CachedNetworkImage(
                                                imageUrl: results[idx].imageUrl,
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Container(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surface,
                                                ),
                                                height: 100,
                                                width: 100,
                                              ),
                                              const SizedBox(
                                                width: 8,
                                              ),
                                              Text(results[idx].title),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                              ];
                            },
                          )
                          .flattened
                          .toList(),
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
