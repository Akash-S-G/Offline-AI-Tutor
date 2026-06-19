import 'visual_focus_request.dart';

class VisualFocusPolicy {
  const VisualFocusPolicy();

  VisualFocusRequest forTaskReference({
    required String referencedId,
    required String category,
    required String taskText,
  }) {
    return VisualFocusRequest(
      targetId: referencedId,
      targetCategory: category,
      reason: taskText,
    );
  }
}
