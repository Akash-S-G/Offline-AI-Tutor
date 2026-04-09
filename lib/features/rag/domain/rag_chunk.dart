class RagChunk {
  const RagChunk({
    required this.id,
    required this.chapterId,
    required this.sourceTitle,
    required this.chunkOrder,
    required this.content,
  });

  final String id;
  final String chapterId;
  final String sourceTitle;
  final int chunkOrder;
  final String content;
}
