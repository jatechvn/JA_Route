# JA_Route verification fixes

Updated: 2026-09-23

## Completed

- OTA backup/apply includes Flutter data (app.so and bundled assets). Root runtime config files and data/search_history.json are excluded by full source path; bundled config.json assets remain included.
- Auto performance mode applies the detected hardware tier without overriding it to Ultra.
- The header shows STANDBY while idle and FIXING... while running. It does not infer live connectivity from configured gateway strings.
- Theme changes persist through RouteFixerLogic.saveConfig. Config changes also synchronize back to ThemeProvider.
- Existing widget tests now use temporary config files and disable native networking and startup OTA checks.
- Added six regression tests, including actual Windows robocopy backup/apply/rollback of synthetic payloads in paths containing spaces.

## Checks

- Direct Dart SDK analyze: no issues.
- dart format . completed.
- Full Flutter test suite via flutter_tools.snapshot: 12 passed.
- Flutter requires access to SDK cache lockfile; tests ran with approved escalation.

## Remaining validation

- Live Windows UI and real network state were not tested.
- SMB authentication, complete OTA installer process handoff, app restart and packaged release validation remain untested.
- No commit or release was requested. The repository currently has no base commit.
- Next: build and smoke-test the Windows package, then validate OTA end to end using a disposable installation.

## White Release window investigation (2026-09-23)

- User confirmed `build/windows/x64/runner/Release/ja_route.exe` remains white even with Run as administrator; screenshot shows a native frame with an empty white client area.
- Removed the two 1-pixel Windows 10 theme resizes in favor of non-client frame recalculation without resizing the Flutter surface. This is a candidate fix, not a confirmed root cause.
- Await the theme MethodChannel future so asynchronous platform errors are actually caught.
- Added `startup_diagnostics.log` beside the executable with startup milestones, error types and stack traces; it deliberately excludes exception messages and configuration values.
- Analyze passed, format changed 0 of 48 files, all 12 tests passed.
- Flutter cannot launch the existing executable directly: its CMake linker options require Administrator (`ProcessException: The requested operation requires elevation`). This is a diagnostic limitation, not evidence that elevation causes the white screen.
- Saved old executable and app.so only to `%TEMP%/ja_route_startup_backup_20260923_105841`; no runtime configuration or credentials copied.
- Release rebuild succeeded (exe timestamp 10:59:41). Launched the new binary via RunAs (PID 24816). At 11:00:05 the log recorded all stages through `First Flutter frame completed` with no recorded framework/async errors. This proves the Dart frame pipeline reached its callback, not that pixels displayed correctly. Native visual confirmation remains pending; if still white, investigate the Windows/GPU surface rendering path.

## Manual network Verify audit (2026-09-24)

- Independently inspected the supplied implementation report. The initial API 503 is a tool-service failure, not evidence about JA_Route correctness.
- Fixed Auto Quick Fix choosing LAN for public Internet targets; service now requires admin, a confirmed misroute and valid IPv4 destination/gateway before adding a route. Removed persistent-route suggestions based solely on failed connectivity.
- Fixed unreachable ICMP replies being counted as success; retain reported partial loss. TCP/HTTP targets now require their own probe to succeed rather than passing on ping alone. HTTP requests have bounded waits, disable redirects, and always close the client.
- Unknown route or packet loss reports warning, with a distinct VI/EN/ZH warning label. HTTP error responses are described as service failures.
- Removed unsafe route-print fallback which could interpret header/interface lines as a route. Find-NetRoute remains the authoritative query; unavailable results stay unknown.
- Validate malformed IPv4/host/port input and reject credential-bearing URLs. Verification logs avoid raw URL paths/query strings.
- Guard Quick Fix completion against disposed widgets and native exceptions.
- Verification: direct Dart analyze passed; dart format . completed; all 29 Flutter tests passed (7 new regressions, including real loopback HTTP 503/closed TCP port). Windows Debug build passed.
- No real route modifications performed. Windows native route query, LAN, macOS/Linux and native visual rendering remain unverified. Previous white-window issue is not proven fixed by this audit.
- Report overclaims full localization: service logs/root-cause recommendations and some UI text remain hardcoded Vietnamese. Auto classification still uses private-address heuristics; arbitrary VPN/custom routes and IPv6 need further coverage. HTTP hostname resolution may select a different address than the route/TCP probe on multi-address hosts. These limits prevent a claim of complete verification across all networks.
- Debug executable rebuilt; Release was not rebuilt in this audit. No commit/push/release requested.
