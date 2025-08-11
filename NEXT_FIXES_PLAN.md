# Next Fixes Plan - FlashCode App

## Priority 1: Critical State Management Fix 🚨
**Issue**: StudySessionProvider setState() errors during build
**Impact**: Console errors, potential crashes
**Timeline**: 1-2 hours

### Tasks:
1. **Fix StudySessionProvider async state updates**
   - Move setState calls out of build cycle
   - Use `WidgetsBinding.instance.addPostFrameCallback()` for async updates
   - Wrap loading state changes in proper async context

2. **File to modify**: `lib/providers/study_session_provider.dart`
   - Fix `_setLoading()` method timing
   - Ensure `startSession()` doesn't trigger setState during build

## Priority 2: Study Flow UX Improvements 📱
**Issue**: Unclear study session workflow
**Impact**: User confusion after rating difficulty
**Timeline**: 2-3 hours

### Tasks:
1. **Clarify "Complete" button behavior**
   - Add clear labeling: "Complete & Next" or "Finish Session"
   - Show progress indicator during multi-card sessions
   - Add session summary screen

2. **Improve study session flow**
   - Show "1 of 1" for single mode
   - Add "Return to Explore" after completion
   - Clear session state properly

3. **Files to modify**:
   - `lib/screens/study/study_screen.dart`
   - `lib/screens/study/flashcard_viewer.dart`

## Priority 3: Dashboard Data Connection 📊
**Issue**: Dashboard shows mock/hardcoded data
**Impact**: Inaccurate progress tracking
**Timeline**: 3-4 hours

### Tasks:
1. **Connect dashboard statistics to real data**
   - Replace hardcoded values with actual study session data
   - Update Grind75 completion count (0/169 not 0/75)
   - Connect category progress to real flashcard completion

2. **Implement study session recording**
   - Save difficulty ratings to database
   - Track time spent per problem
   - Update user progress properly

3. **Files to modify**:
   - `lib/screens/home/home_screen.dart` (DashboardView)
   - `lib/providers/flashcard_provider.dart`
   - `lib/models/user.dart`

## Priority 4: Syntax Highlighting Enhancement 🎨
**Issue**: Poor code syntax highlighting
**Impact**: Reduced readability
**Timeline**: 1-2 hours

### Tasks:
1. **Improve syntax highlighting theme**
   - Use better color scheme for variables, strings, comments
   - Ensure good contrast for readability
   - Test across different code snippets

2. **Files to modify**:
   - `lib/screens/study/flashcard_viewer.dart`
   - Consider adding custom theme for flutter_highlight

## Priority 5: Documentation & Testing 📝
**Timeline**: 1 hour

### Tasks:
1. **Update README.md**
   - Current status after database cleanup
   - Working features list
   - Known issues and workarounds

2. **Update memory bank**
   - Mark completed fixes
   - Update current status
   - Document next steps

## Implementation Order:

### Week 1:
- [ ] Fix StudySessionProvider setState errors
- [ ] Improve study flow UX (Complete button clarity)
- [ ] Update dashboard statistics to use real data

### Week 2:
- [ ] Implement study session recording
- [ ] Enhance syntax highlighting
- [ ] Add session summary screens

### Week 3:
- [ ] Polish and testing
- [ ] Documentation updates
- [ ] Performance optimizations

## Success Criteria:
✅ No console errors during study sessions
✅ Clear user flow from Explore → Study → Completion
✅ Dashboard shows accurate progress (0/169 completion)
✅ Study sessions properly saved to database
✅ Better code readability with improved highlighting

## Technical Debt to Address:
- Provider state management patterns
- Error handling throughout app
- Loading states consistency
- Navigation state management
- Database query optimization

## Future Enhancements (Post-Fix):
- Search functionality in Library
- Advanced filtering options
- Detailed analytics
- Social features
- Offline sync improvements
