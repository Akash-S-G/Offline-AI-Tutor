class ClassroomStartupValidator {
  const ClassroomStartupValidator();

  bool isReady({required bool backendReady, required bool classroomReady}) {
    return backendReady && classroomReady;
  }
}
