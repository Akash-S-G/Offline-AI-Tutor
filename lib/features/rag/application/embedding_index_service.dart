import '../data/local/embedding_index_repository.dart';
import '../data/local/rag_repository.dart';

class EmbeddingIndexProgress {
  const EmbeddingIndexProgress({
    required this.total,
    required this.processed,
    required this.indexed,
    required this.done,
  });

  final int total;
  final int processed;
  final int indexed;
  final bool done;
}

class EmbeddingIndexService {
  EmbeddingIndexService({
    required RagRepository ragRepository,
    required EmbeddingIndexRepository embeddingRepository,
  })  : _ragRepository = ragRepository,
        _embeddingRepository = embeddingRepository;

  final RagRepository _ragRepository;
  final EmbeddingIndexRepository _embeddingRepository;

  Stream<EmbeddingIndexProgress> indexChapter({
    required String chapterId,
    String modelName = 'local-embedding-v1',
    int dimension = 384,
  }) async* {
    final chunkIds = await _ragRepository.getChunkIdsForChapter(chapterId);
    final total = chunkIds.length;

    if (total == 0) {
      yield const EmbeddingIndexProgress(
        total: 0,
        processed: 0,
        indexed: 0,
        done: true,
      );
      return;
    }

    var processed = 0;
    var indexed = await _embeddingRepository.getIndexedCountForChapter(
      chapterId: chapterId,
    );

    yield EmbeddingIndexProgress(
      total: total,
      processed: processed,
      indexed: indexed,
      done: false,
    );

    for (final chunkId in chunkIds) {
      final alreadyIndexed = await _embeddingRepository.isChunkIndexed(
        chunkId: chunkId,
      );

      if (!alreadyIndexed) {
        await _embeddingRepository.upsertEmbeddingMetadata(
          chunkId: chunkId,
          modelName: modelName,
          dimension: dimension,
        );
      }

      processed += 1;
      indexed = await _embeddingRepository.getIndexedCountForChapter(
        chapterId: chapterId,
      );

      yield EmbeddingIndexProgress(
        total: total,
        processed: processed,
        indexed: indexed,
        done: processed >= total,
      );
    }
  }
}
