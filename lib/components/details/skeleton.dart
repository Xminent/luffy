import "package:flutter/material.dart";
import "package:skeletons/skeletons.dart";

class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: SkeletonItem(
        child: Column(
          children: [
            const Expanded(
              child: SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    // full-width cover image
                    Positioned.fill(
                      child: SkeletonAvatar(
                        style: SkeletonAvatarStyle(
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                    // anime picture centered on top of the cover image
                    Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SkeletonAvatar(
                          style: SkeletonAvatarStyle(
                            width: 100,
                            height: 140,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Flexible(
              child: SizedBox(
                height: 8,
              ),
            ),
            Expanded(
              child: SkeletonLine(
                style: SkeletonLineStyle(
                  alignment: AlignmentDirectional.center,
                  width: MediaQuery.of(context).size.width / 3,
                  height: 24,
                ),
              ),
            ),
            const Flexible(
              child: SizedBox(
                height: 8,
              ),
            ),
            Expanded(
              child: SkeletonLine(
                style: SkeletonLineStyle(
                  alignment: AlignmentDirectional.center,
                  width: MediaQuery.of(context).size.width / 3,
                  height: 16,
                ),
              ),
            ),
            const Flexible(
              child: SizedBox(
                height: 8,
              ),
            ),
            Expanded(
              child: SkeletonLine(
                style: SkeletonLineStyle(
                  alignment: AlignmentDirectional.center,
                  width: MediaQuery.of(context).size.width / 4,
                  height: 16,
                ),
              ),
            ),
            const Flexible(
              child: SizedBox(
                height: 8,
              ),
            ),
            SkeletonParagraph(
              style: SkeletonParagraphStyle(
                spacing: 6,
                lineStyle: SkeletonLineStyle(
                  randomLength: true,
                  height: 16,
                  minLength: MediaQuery.of(context).size.width / 2,
                  alignment: AlignmentDirectional.center,
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            const Expanded(
              child: SkeletonAvatar(
                style: SkeletonAvatarStyle(
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            const Flexible(
              child: SizedBox(
                height: 8,
              ),
            ),
            const Expanded(
              child: SkeletonAvatar(
                style: SkeletonAvatarStyle(
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
