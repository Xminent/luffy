import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:luffy/api/anilist.dart";
import "package:luffy/screens/details.dart";

class RelationCard extends StatelessWidget {
  const RelationCard({super.key, required this.relation});

  final Relation relation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              width: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: relation.coverImage,
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 150,
              child: Text(
                relation.titleUserPreferred,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DetailsScreen(
            animeId: relation.id,
            title: relation.titleUserPreferred,
            imageUrl: relation.coverImage,
            bannerImageUrl: relation.bannerImage,
            score: relation.meanScore,
          ),
        ),
      ),
    );
  }
}
