# Flutter Production Readiness Audit — Senior Developer Review

You are acting as a **Senior Flutter/Dart Engineer, Software Architect, Security Reviewer, QA Engineer, and Production Readiness Reviewer**.

I have an existing Flutter application that I want to release to real users in production.

Your job is to **deeply inspect the entire codebase before making any changes** and create a comprehensive production-readiness audit.

Do NOT assume that the current implementation is correct just because the application builds or runs.

---

## PRIMARY OBJECTIVE

Analyze the complete Flutter project and identify:

- Bugs
- Potential runtime crashes
- Logic errors
- Architecture problems
- Bad coding practices
- Performance problems
- Memory leaks
- UI/UX problems
- Responsive-layout problems
- Android-specific issues
- Windows/Desktop-specific issues if applicable
- State-management problems
- Async/concurrency problems
- Navigation problems
- Error-handling weaknesses
- Security vulnerabilities
- Data-loss risks
- Offline/online handling problems
- Dependency problems
- Configuration problems
- Build/release problems
- Testing gaps
- Maintainability problems
- Scalability problems
- Production-readiness issues
- Anything else that could cause problems after release

The objective is not merely to make the code "look clean".

The objective is:

> **Would this application be safe, stable, maintainable, performant, and reliable enough to release to real users?**

---

# IMPORTANT RULES

### 1. Inspect before modifying

DO NOT modify the code during the initial audit.

First inspect and understand the project.

You must analyze the actual codebase rather than giving generic Flutter advice.

---

### 2. Review the entire repository

Inspect all relevant files and directories, including where applicable:

- `lib/`
- `test/`
- `integration_test/`
- `android/`
- `ios/`
- `windows/`
- `macos/`
- `linux/`
- `web/`
- `assets/`
- `pubspec.yaml`
- `pubspec.lock`
- `analysis_options.yaml`
- Build configuration
- Gradle configuration
- AndroidManifest
- ProGuard/R8 configuration
- App permissions
- Environment/configuration files
- CI/CD configuration
- Localization files
- Database/storage code
- API/networking code
- Authentication/authorization code
- Logging code
- Error-reporting code

Do not limit the review to the `lib/` directory.

---

# STEP 1 — UNDERSTAND THE APPLICATION

Before judging the implementation, determine:

1. What the application does
2. Main features
3. Application architecture
4. State-management approach
5. Navigation approach
6. Data-storage approach
7. Networking/API architecture
8. Authentication system
9. Dependency structure
10. Supported platforms
11. Important user flows
12. Major business logic
13. External services
14. Any assumptions made by the application

Create a short **Architecture Overview** explaining what you discovered.

If something cannot be determined from the codebase, explicitly say:

> "Unable to determine from the repository."

Do not invent assumptions.

---

# STEP 2 — CODE QUALITY REVIEW

Inspect the Dart/Flutter code for:

- Duplicate code
- Dead code
- Unused code
- Unnecessary complexity
- Very large files
- Very large widgets
- Very large methods
- Poor naming
- Incorrect naming conventions
- Tight coupling
- Poor separation of concerns
- Business logic inside UI widgets
- Improper abstraction
- Excessive abstraction
- Magic numbers
- Magic strings
- Hard-coded configuration
- Global mutable state
- Incorrect use of static variables
- Improper dependency management
- Incorrect null-safety usage
- Dangerous `!` operators
- Excessive `dynamic`
- Unsafe type casting
- Ignored return values
- Poor exception handling
- Swallowed exceptions
- `print()`/debug logging left in production code
- TODO/FIXME items that matter
- Commented-out code
- Inconsistent coding patterns

For every important finding, explain:

- File
- Location/line if available
- Problem
- Why it matters
- Recommended solution

---

# STEP 3 — FLUTTER-SPECIFIC REVIEW

Check for common Flutter problems including:

### Widget architecture

- Excessive widget rebuilds
- Incorrect widget lifecycle usage
- Incorrect `BuildContext` usage
- Using context after async gaps
- Missing `mounted` checks where required
- Controllers not disposed
- Animation controllers not disposed
- Focus nodes not disposed
- Text editing controllers not disposed
- Streams not cancelled
- Timers not cancelled
- Listeners not removed
- Providers/blocs/controllers incorrectly scoped

### UI

Check for:

- Pixel overflow
- Render overflow
- Unbounded constraints
- Nested scrolling problems
- Incorrect use of `Expanded`
- Incorrect use of `Flexible`
- Incorrect use of `ListView`
- Incorrect use of `SingleChildScrollView`
- Incorrect `Column`/`Row` layouts
- Hard-coded dimensions
- Device-size assumptions
- Orientation issues
- Keyboard issues
- Safe-area problems
- Notches/status-bar problems
- Bottom navigation overlap
- Dialog overflow
- Small-screen problems
- Large-screen problems
- Desktop window sizing issues

### Responsive design

Check the application on the conceptual level for:

- Small Android phones
- Large Android phones
- Tablets
- Different aspect ratios
- Landscape orientation
- Desktop/window resizing where applicable

Identify layouts that are likely to break.

---

# STEP 4 — STATE MANAGEMENT

Identify the state-management architecture being used.

Review it for:

- Incorrect state ownership
- Unnecessary rebuilds
- Race conditions
- Stale state
- State synchronization problems
- Improper lifecycle handling
- Memory leaks
- Duplicate state
- State mutation problems
- Async state problems
- Loading-state problems
- Error-state problems
- Empty-state problems

Determine whether the current approach is appropriate for the size and complexity of the application.

Do NOT recommend changing state-management technology merely because another technology is popular.

Only recommend migration if there is a concrete technical reason.

---

# STEP 5 — ASYNC / CONCURRENCY REVIEW

Look carefully for:

- Race conditions
- Multiple simultaneous API calls
- Duplicate requests
- Unhandled Futures
- Missing `await`
- Async initialization problems
- Context usage after `await`
- State updates after disposal
- Incorrect loading states
- Request cancellation problems
- Retry problems
- Timeout problems
- Concurrent database operations
- Background task problems

Pay special attention to code that performs:

```dart
await ...
```

followed by UI/state updates.

---

# STEP 6 — NETWORK/API REVIEW

If the application communicates with APIs, inspect:

- API architecture
- HTTP client usage
- Timeout handling
- Retry handling
- Error handling
- HTTP status handling
- JSON parsing
- Null/missing fields
- Unexpected API responses
- API versioning assumptions
- Request duplication
- Authentication token handling
- Token expiration
- Refresh-token handling
- Network disconnect handling
- Slow-network behavior
- Offline behavior
- Response caching
- Request cancellation
- Sensitive data in requests
- Sensitive data in responses
- Logging of API data

Check whether API failures can crash the application or leave the UI in an inconsistent state.

---

# STEP 7 — DATABASE / LOCAL STORAGE REVIEW

If local storage/database is used, inspect:

- Database architecture
- Schema
- Migrations
- Version upgrades
- Data integrity
- Transactions
- Concurrent access
- Query efficiency
- Indexing
- Large datasets
- Pagination
- Data corruption scenarios
- Error recovery
- Backup/recovery considerations
- Cache invalidation
- Sensitive data storage

Check what happens when:

- Database initialization fails
- Database schema changes
- The application updates
- Data is missing
- Data is corrupted
- Storage is full
- The user force-closes the application during a write

---

# STEP 8 — SECURITY AUDIT

Perform a serious security review.

Look for:

- API keys inside source code
- Secrets inside source code
- Passwords inside source code
- Tokens stored insecurely
- Sensitive data stored insecurely
- Sensitive information in logs
- Insecure local storage
- Weak authentication handling
- Missing authorization checks
- Improper certificate/HTTPS handling
- Insecure HTTP connections
- Excessive permissions
- Debug configuration in release
- Sensitive information exposed through errors
- Backup exposure
- Export/share vulnerabilities
- Unsafe file handling
- Path traversal risks where applicable
- WebView security issues where applicable
- Deep-link security issues
- Intent handling problems on Android

Clearly distinguish:

- Confirmed vulnerability
- Potential vulnerability
- Security hardening recommendation

Do not call something a vulnerability unless the code provides evidence.

---

# STEP 9 — PERFORMANCE AUDIT

Analyze potential performance problems.

Check:

- Unnecessary widget rebuilds
- Expensive work inside `build()`
- Large lists
- Missing lazy loading
- Missing pagination
- Large image handling
- Image decoding
- Memory usage
- Expensive JSON parsing
- Expensive database queries
- Synchronous heavy operations
- Excessive animations
- Excessive network requests
- Repeated calculations
- Unnecessary object creation
- Large assets
- Startup performance
- App initialization
- Background processing

Identify anything likely to become a problem as the number of users or amount of data grows.

---

# STEP 10 — ERROR HANDLING & RESILIENCE

Determine whether the application behaves correctly when things go wrong.

Check scenarios such as:

- No internet
- Slow internet
- API unavailable
- API returns invalid data
- Authentication expires
- Database fails
- Storage fails
- File does not exist
- Permission denied
- User enters invalid data
- User rapidly taps buttons
- User navigates back during an operation
- Application is backgrounded
- Application is killed during an operation
- Device rotates
- App window is resized
- Unexpected exceptions occur

Identify places where the application could:

- Crash
- Freeze
- Show an infinite loader
- Show stale data
- Lose user data
- Enter an invalid state

---

# STEP 11 — ANDROID PRODUCTION REVIEW

Inspect Android configuration carefully.

Review:

- `AndroidManifest.xml`
- Gradle configuration
- Android Gradle Plugin
- Gradle version
- Kotlin version
- Compile SDK
- Target SDK
- Minimum SDK
- Application ID
- Permissions
- Exported components
- Deep links
- ProGuard/R8
- Release signing
- Debug/release differences
- Network security configuration
- Backup settings
- Cleartext traffic
- Notifications
- Foreground/background behavior
- App startup
- Android lifecycle handling

Identify anything that could cause Play Store release problems or runtime issues.

---

# STEP 12 — OTHER PLATFORM REVIEW

If the project supports:

- Windows
- iOS
- macOS
- Linux
- Web

review their platform-specific configuration and identify platform-specific problems.

Do not review platforms that are clearly not supported unless relevant.

---

# STEP 13 — DEPENDENCY AUDIT

Analyze `pubspec.yaml` and `pubspec.lock`.

For dependencies, identify:

- Outdated packages
- Unmaintained packages
- Deprecated packages
- Conflicting dependencies
- Unnecessary dependencies
- Duplicate functionality
- Platform compatibility issues
- Packages that introduce significant risk
- Packages that are inappropriate for production

Do NOT automatically recommend upgrading every dependency.

For each important dependency issue, explain:

- Current version
- Problem
- Risk
- Recommended action
- Whether the change is breaking

If internet access is available, verify important package information against the package's official source.

---

# STEP 14 — TESTING AUDIT

Inspect existing tests.

Determine:

- Unit test coverage
- Widget test coverage
- Integration test coverage
- Critical flows without tests
- Important business logic without tests
- Error scenarios without tests
- Regression risks

Identify the minimum test suite that should exist before production.

Prioritize tests based on risk rather than simply trying to maximize coverage percentage.

---

# STEP 15 — BUILD & RELEASE AUDIT

Review the project from the perspective of actually releasing it.

Check:

- Debug vs release configuration
- Versioning
- App signing
- Environment configuration
- Production API configuration
- Logging
- Crash reporting
- Analytics if applicable
- App icons
- Splash screen
- Permissions
- Build configuration
- Release artifacts
- Obfuscation
- Secrets
- CI/CD
- Store requirements

Identify anything that could cause a failed release or a production incident.

---

# STEP 16 — UX / PRODUCT RELIABILITY

Do not only inspect code quality.

Inspect important user flows and identify:

- Missing loading states
- Missing error states
- Missing empty states
- Confusing navigation
- Destructive actions without confirmation
- Forms that can lose entered data
- Buttons that can be accidentally triggered multiple times
- Poor feedback after actions
- Accessibility problems
- Text scaling problems
- Touch-target problems
- Keyboard/input issues

Focus on issues that affect real users.

---

# STEP 17 — ARCHITECTURE ASSESSMENT

Based on the actual codebase, explain:

1. Current architecture
2. What is working well
3. Architectural weaknesses
4. Technical debt
5. Scalability concerns
6. Maintainability concerns
7. Recommended architectural improvements

Do not recommend rewriting the entire application unless the existing architecture genuinely prevents production-quality development.

Prefer incremental improvements.

---

# STEP 18 — CREATE A PRIORITIZED ISSUE REPORT

Every important issue should receive a severity.

Use exactly these levels:

### P0 — BLOCKER
Must be fixed before production.

Examples:
- Data loss
- Security vulnerability
- Reliable crash
- Broken critical functionality
- Production build cannot work

### P1 — CRITICAL
Should be fixed before production unless there is a documented reason.

Examples:
- Major reliability problem
- Serious performance issue
- Authentication failure
- Important workflow failure

### P2 — HIGH
Should be fixed soon.

Examples:
- Significant maintainability issue
- Important UX problem
- Moderate performance problem
- Missing important error handling

### P3 — MEDIUM
Should be addressed but does not necessarily block release.

### P4 — LOW
Nice-to-have improvements, cleanup, or minor technical debt.

---

# REPORT FORMAT

Create a comprehensive report named:

`PRODUCTION_READINESS_REPORT.md`

Use the following structure:

# Flutter Production Readiness Report

## 1. Executive Summary

Give a concise assessment of the current codebase.

Include:

- Overall production readiness
- Major risks
- Major strengths
- Biggest technical concerns
- Recommended immediate actions

Do NOT use a numerical score unless there is a meaningful objective basis.

---

## 2. Application Architecture

Describe:

- Architecture
- State management
- Navigation
- Data layer
- API layer
- Storage
- Major dependencies
- Platform support

Include a simple architecture diagram if useful.

---

## 3. Critical Issues

Create a table:

| ID | Severity | Area | File | Issue | Impact | Recommended Fix |
|----|----------|------|------|-------|--------|-----------------|

Only include genuine findings.

---

## 4. Detailed Findings

For every significant issue:

### [ID] Issue Title

**Severity:** P0/P1/P2/P3/P4

**Category:**

**File:**

**Location:**

**Problem:**

Explain exactly what is wrong.

**Why it matters:**

Explain the real-world impact.

**Evidence:**

Reference the relevant code.

**Recommended solution:**

Give a concrete recommendation.

**Risk of fixing:**

Mention whether the fix is low, medium, or high risk.

---

## 5. Security Findings

Separate:

- Confirmed vulnerabilities
- Potential vulnerabilities
- Security hardening recommendations

---

## 6. Performance Findings

Explain:

- Current problem
- Likely impact
- Conditions under which it becomes significant
- Recommended optimization

---

## 7. Flutter / UI Findings

Include:

- Layout problems
- Responsive issues
- Lifecycle problems
- Rebuild problems
- Memory/resource leaks
- Accessibility concerns

---

## 8. Architecture & Maintainability

Explain the largest architectural concerns and how to improve them incrementally.

---

## 9. Dependency Audit

List important dependency concerns.

Do not recommend upgrades without explaining why.

---

## 10. Testing Gaps

Create:

| Area | Current Testing | Risk | Recommended Test |
|------|-----------------|------|------------------|

Prioritize critical user flows.

---

## 11. Production Configuration Checklist

Create a checklist covering:

- [ ] Release build
- [ ] Signing
- [ ] Production environment
- [ ] Secrets
- [ ] API configuration
- [ ] Logging
- [ ] Crash reporting
- [ ] Permissions
- [ ] Android configuration
- [ ] Database migration
- [ ] Backup/recovery
- [ ] Testing
- [ ] Performance
- [ ] Security
- [ ] Store release requirements

Only mark an item complete when you have verified it from the repository.

---

## 12. Recommended Action Plan

Divide recommendations into:

### Before Production

P0/P1 issues and anything that could cause serious incidents.

### Shortly After Production

P2 issues and important technical debt.

### Future Improvements

P3/P4 improvements and architectural enhancements.

---

## 13. Final Production Gate

At the end provide:

### Must Fix Before Release

List the exact issues that should block production.

### Should Fix Before Release

List important issues that should ideally be resolved.

### Can Be Deferred

List issues that can reasonably be handled after launch.

### Unknowns Requiring Manual Verification

List anything that cannot be verified through source-code inspection.

Examples:

- Real-device behavior
- Backend configuration
- Production credentials
- Store configuration
- Server-side security
- Actual performance
- Network behavior
- Crash behavior on physical devices

---

# IMPORTANT REVIEW PRINCIPLES

Follow these principles throughout the audit:

1. **Evidence over assumptions.**
2. Do not invent problems.
3. Do not praise code merely because it follows common patterns.
4. Do not recommend rewrites without justification.
5. Prefer concrete findings over generic advice.
6. Distinguish confirmed issues from potential risks.
7. Consider real-world user behavior.
8. Consider production-scale data.
9. Consider failure scenarios.
10. Consider future maintainability.
11. Consider security separately from code quality.
12. Consider performance separately from architecture.
13. Do not change code during the audit.
14. Do not hide problems because fixing them may be difficult.
15. Do not report the same issue multiple times.
16. Prioritize issues by actual production impact.

---

# FINAL INSTRUCTION

After completing the audit:

1. Save the complete report as:

`PRODUCTION_READINESS_REPORT.md`

2. Do NOT modify application source code yet.

3. Show me a concise summary containing:

- Number of P0 issues
- Number of P1 issues
- Number of P2 issues
- Number of P3 issues
- Number of P4 issues
- Top 10 issues requiring attention
- Whether there are any obvious production blockers
- The first 5 fixes you recommend doing

Then wait for my instruction.

**Do not automatically start fixing anything.**

The first phase is strictly:

> **INSPECT → ANALYZE → REPORT → WAIT**