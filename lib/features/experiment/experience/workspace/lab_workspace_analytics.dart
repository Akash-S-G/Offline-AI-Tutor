class LabWorkspaceAnalytics {
  int focusModeUses = 0;
  int measurementCaptures = 0;
  int graphViews = 0;
  int controlInteractions = 0;
  int workspaceSessions = 0;
  double visibleCanvasPercentage = 0;

  Map<String, dynamic> toJson() {
    return {
      'focusModeUses': focusModeUses,
      'measurementCaptures': measurementCaptures,
      'graphViews': graphViews,
      'controlInteractions': controlInteractions,
      'workspaceSessions': workspaceSessions,
      'visibleCanvasPercentage': visibleCanvasPercentage,
    };
  }
}
