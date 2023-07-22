import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:luffy/api/anime.dart";
import "package:luffy/screens/details_sources.dart";

class SearchScreenSources extends StatefulWidget {
  const SearchScreenSources({super.key});

  @override
  State<SearchScreenSources> createState() => _SearchScreenSourcesState();
}

class _SearchScreenSourcesState extends State<SearchScreenSources>
    with AutomaticKeepAliveClientMixin {
  Future<Map<String, List<Anime>>>? _searchResultsFuture;
  final List<bool> _resultsExpanded =
      List.generate(sources.length, (index) => true);

  Future<Map<String, List<Anime>>> _search(String query) async {
    final results = <String, List<Anime>>{};

    // Iterate through every source and add an entry into the map for its results.
    for (final source in sources) {
      final sourceResults = await source.search(query);

      results[source.name] = sourceResults;
    }

    return results;
  }

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

        return SingleChildScrollView(
          child: ExpansionPanelList(
            elevation: 1,
            expandedHeaderPadding: EdgeInsets.zero,
            expansionCallback: (index, isExpanded) {
              setState(() {
                _resultsExpanded[index] = !isExpanded;
              });
            },
            children: searchResults.keys.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final source = entry.value;
              final isExpanded = _resultsExpanded[index];

              return ExpansionPanel(
                headerBuilder: (context, isExpanded) {
                  return ListTile(
                    title: Text("$source (${searchResults[source]?.length})"),
                  );
                },
                body: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: searchResults[source]?.length ?? 0,
                  itemBuilder: (context, index) {
                    final anime = searchResults[source]![index];
                    final extractor = sources.firstWhere(
                      (element) => element.name == source,
                    );

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        splashColor: Colors.grey,
                        splashFactory: InkRipple.splashFactory,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsScreenSources(
                                animeId: "$source-${anime.url}",
                                imageUrl: anime.imageUrl,
                                title: anime.title,
                                extractor: extractor,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              CachedNetworkImage(
                                imageUrl: anime.imageUrl,
                                errorWidget: (context, url, error) => Container(
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                                height: 100,
                                width: 100,
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      anime.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
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
                isExpanded: isExpanded,
              );
            }).toList(),
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
          title: const Text("Search Sources"),
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
                    _searchResultsFuture = _search(value);
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
