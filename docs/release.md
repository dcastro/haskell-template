Release checklist:

- [ ] Update version in the cabal file
- [ ] Update changelog
- [ ] Add `@since` annotations to all new public API
- [ ] Review the `min-deps` command
- [ ] Update `tested-with`
- [ ] Create GitHub release & tag the commit
- [ ] `just upload-candidate ; just upload-candidate-docs`
- [ ] Publish candidate
- [ ] `just upload-final-docs`
