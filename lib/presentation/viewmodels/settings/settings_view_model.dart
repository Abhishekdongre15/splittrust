import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings_state.dart';

class SettingsViewModel extends Cubit<SettingsState> {
  SettingsViewModel() : super(const SettingsState());

  void toggleLock(bool enabled) {
    emit(state.copyWith(lockEnabled: enabled));
  }

  void changeLanguage(String language) {
    emit(state.copyWith(language: language));
  }

  void changeTheme(AppThemePreference preference) {
    emit(state.copyWith(theme: preference));
  }
}
