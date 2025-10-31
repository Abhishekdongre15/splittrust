import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.lockEnabled = false,
    this.language = 'en',
    this.theme = AppThemePreference.system,
  });

  final bool lockEnabled;
  final String language;
  final AppThemePreference theme;

  SettingsState copyWith({
    bool? lockEnabled,
    String? language,
    AppThemePreference? theme,
  }) {
    return SettingsState(
      lockEnabled: lockEnabled ?? this.lockEnabled,
      language: language ?? this.language,
      theme: theme ?? this.theme,
    );
  }

  @override
  List<Object?> get props => [lockEnabled, language, theme];
}

enum AppThemePreference { light, dark, system }
