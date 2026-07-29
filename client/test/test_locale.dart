import 'package:flutter/material.dart';
import 'package:multigames_client/core/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Виджет-тесты ожидают русские строки (как в продукте по умолчанию для RU).
void setUpTestLocaleRu() {
  SharedPreferences.setMockInitialValues({'app_locale': 'ru'});
  LocaleService.setLocale(const Locale('ru'));
}
