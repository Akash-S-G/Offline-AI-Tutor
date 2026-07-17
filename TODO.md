# Offline Tutor Debug TODO

- [ ] Reproduce offline “thinking forever” with a single question.
- [ ] Capture whether llama CLI tokens are emitted on **stdout** vs **stderr** during generation.
- [ ] Patch `LinuxTutorInferenceGateway` to log/forward stderr chunks during generation so UI can complete or at least show errors.
- [ ] Re-run offline mode after patch.
- [ ] Verify UI stops thinking and renders assistant response.

