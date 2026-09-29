import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ja_route/modules/localization.dart';
import 'package:ja_route/modules/ui/theme/language_provider.dart';
import 'package:ja_route/modules/ui/theme/theme_provider.dart';
import 'package:ja_route/modules/ui/widgets/glass_dropdown.dart';

void main() {
  test('locale aliases match dictionary and provider', () {
    for (final entry in {
      'EN': 'en',
      'en-US': 'en',
      'GB': 'en',
      'zh_CN': 'zh',
      'CN': 'zh',
      'vi-VN': 'vi',
    }.entries) {
      expect(AppLocalizations.normalizeLanguageCode(entry.key), entry.value);
      expect(AppLanguage.fromCode(entry.key).code, entry.value);
    }
  });
  test('config synchronization notifies language consumers', () {
    final language = LanguageProvider(initialCode: 'vi');
    addTearDown(language.dispose);
    var count = 0;
    language.addListener(() => count++);
    language.syncWithConfig('en-US');
    language.syncWithConfig('EN');
    expect(count, 1);
    expect(language.currentLanguage, AppLanguage.en);
  });
  testWidgets('open dropdown reacts to language and theme changes', (
    tester,
  ) async {
    final language = LanguageProvider(initialCode: 'vi');
    final theme = ThemeProvider(initialMode: 'dark', cpuCoresOverride: 8);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: language),
          ChangeNotifierProvider.value(value: theme),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: GlassDropdown<int>(
                  items: List.generate(
                    6,
                    (i) => GlassDropdownItem(value: i, label: 'Item $i'),
                  ),
                  value: null,
                  onChanged: (_) {},
                  colors: theme.colors,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(GlassDropdown<int>));
    await tester.pumpAndSettle();
    String hint() =>
        tester.widget<TextField>(find.byType(TextField)).decoration!.hintText!;
    expect(
      hint(),
      AppLocalizations(
        'vi',
      ).getWithParams('dropdown_search_hint', {'count': '6'}),
    );
    language.setLanguageCode('en-US');
    await tester.pumpAndSettle();
    expect(
      hint(),
      AppLocalizations(
        'en',
      ).getWithParams('dropdown_search_hint', {'count': '6'}),
    );
    theme.setLiveGlassmorphism(dropdownOpacity: 0.99);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    language.dispose();
    theme.dispose();
  });
}
