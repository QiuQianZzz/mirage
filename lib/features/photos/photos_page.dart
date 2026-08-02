import 'package:flutter/material.dart';

import '../../core/routes/sections.dart';
import '../../data/content_repository.dart';
import '../../data/models/photo.dart';
import '../../widgets/page_title.dart';
import '../../widgets/photo_lightbox.dart';

class PhotosPage extends StatelessWidget {
  final ContentRepository repository;

  const PhotosPage({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Photo>>(
      future: repository.loadPhotos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final photos = snapshot.data!;

        if (photos.isEmpty) {
          return Center(
            child: Text(
              '暂无图片',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageTitle(english: Sections.photos.watermark),
                  for (final photo in photos)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => showPhotoLightbox(context, photo),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: photo.isNetwork
                                    ? Image.network(
                                        photo.url,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          height: 200,
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          child: const Center(child: Icon(Icons.broken_image_outlined)),
                                        ),
                                      )
                                    : Image.asset(
                                        photo.url,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          height: 200,
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          child: const Center(child: Icon(Icons.broken_image_outlined)),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          if (photo.caption.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              photo.caption,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
