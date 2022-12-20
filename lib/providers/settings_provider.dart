import 'package:immersion_reader/data/settings/appearance_setting.dart';
import 'package:immersion_reader/data/settings/settings_data.dart';
import 'package:immersion_reader/dictionary/dictionary_options.dart';
import 'package:immersion_reader/storage/settings_storage.dart';

class SettingsProvider {
  SettingsStorage? settingsStorage;
  SettingsData? settingsCache;

  SettingsProvider._create() {
    // print("_create() (private constructor)");
  }

  static SettingsProvider create(SettingsStorage settingsStorage) {
    SettingsProvider provider = SettingsProvider._create();
    provider.settingsStorage = settingsStorage;
    provider.settingsCache = settingsStorage.settingsCache;
    return provider;
  }

  Future<void> toggleShowFrequencyTags(bool isShowFrequencyTags) async {
    if (settingsCache != null) {
      settingsCache!.appearanceSetting.showFrequencyTags =
          !settingsCache!.appearanceSetting.showFrequencyTags;
    }
    await settingsStorage!.changeConfigSettings(
        AppearanceSetting.showFrequencyTagsKey, isShowFrequencyTags ? "1" : "0",
        newSettingsCache: settingsCache);
  }

  Future<bool> getIsShowFrequencyTags() async {
    settingsCache ??= await settingsStorage!.getConfigSettings();
    return settingsCache!.appearanceSetting.showFrequencyTags;
  }

  Future<void> toggleEnableSlideAnimation(bool enableSlideAnimation) async {
    if (settingsCache != null) {
      settingsCache!.appearanceSetting.enableSlideAnimation =
          !settingsCache!.appearanceSetting.enableSlideAnimation;
    }
    await settingsStorage!.changeConfigSettings(
        AppearanceSetting.enableSlideAnimationKey, enableSlideAnimation ? "1" : "0",
        newSettingsCache: settingsCache);
  }

  Future<bool> getIsEnabledSlideAnimation() async {
    settingsCache ??= await settingsStorage!.getConfigSettings();
    return settingsCache!.appearanceSetting.enableSlideAnimation;
  }

  Future<void> updatePitchAccentStyle(
      PitchAccentDisplayStyle pitchAccentDisplayStyle) async {
    if (settingsCache != null) {
      settingsCache!.appearanceSetting.pitchAccentStyleString =
          pitchAccentDisplayStyle.name;
    }
    await settingsStorage!.changeConfigSettings(
        AppearanceSetting.pitchAccentStyleKey, pitchAccentDisplayStyle.name,
        newSettingsCache: settingsCache);
  }

  Future<PitchAccentDisplayStyle> getPitchAccentStyle() async {
    settingsCache ??= await settingsStorage!.getConfigSettings();
    String pitchAccentString =
        settingsCache!.appearanceSetting.pitchAccentStyleString;
    return PitchAccentDisplayStyle.values
        .firstWhere((e) => e.name == pitchAccentString);
  }

  Future<void> updatePopupDictionaryTheme(
      PopupDictionaryTheme popupDictionaryTheme) async {
    if (settingsCache != null) {
      settingsCache!.appearanceSetting.popupDictionaryThemeString =
          popupDictionaryTheme.name;
    }
    await settingsStorage!.changeConfigSettings(
        AppearanceSetting.popupDictionaryThemeKey, popupDictionaryTheme.name,
        newSettingsCache: settingsCache);
  }

  Future<PopupDictionaryTheme> getPopupDictionaryTheme() async {
    settingsCache ??= await settingsStorage!.getConfigSettings();
    String popupDictionaryThemeString =
        settingsCache!.appearanceSetting.popupDictionaryThemeString;
    return PopupDictionaryTheme.values
        .firstWhere((e) => e.name == popupDictionaryThemeString);
  }
}
