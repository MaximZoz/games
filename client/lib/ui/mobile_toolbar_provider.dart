import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Контекстные кнопки для верхней панели на мобильной ориентации.
final mobileToolbarLeadingProvider = StateProvider<Widget?>((ref) => null);

/// Текущий путь — обновляется shell, экраны смотрят и ставят toolbar только при совпадении.
final currentRoutePathProvider = StateProvider<String>((ref) => '');
