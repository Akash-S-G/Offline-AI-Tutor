class DeploymentDiagnosticsCoordinator {
  String summarize({required bool backendReady, required bool classroomReady}) {
    return 'backend=$backendReady classroom=$classroomReady';
  }
}
