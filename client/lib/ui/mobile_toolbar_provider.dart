import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Контекстные кнопки для верхней панели на мобильной ориентации.
final mobileToolbarLeadingProvider = StateProvider<Widget?>((ref) => null);

/// Текущий путь — обновляется shell, экраны смотрят и ставят toolbar только при совпадении.
final currentRoutePathProvider = StateProvider<String>((ref) => '');

/// Инкремент при тапе по вкладке «Профиль» — выйти из режима редактирования.
final profileExitEditTickProvider = StateProvider<int>((ref) => 0);

/// Инкремент при тапе по вкладке «Друзья» — сброс поиска и переход на таб «Друзья».
final friendsNavTapTickProvider = StateProvider<int>((ref) => 0);

/// Схлопнуть bottom nav (heightFactor=0, виджет остаётся в дереве),
/// чтобы на iOS Safari он не висел блоком над клавиатурой при поиске.
/// Нельзя убирать nav из дерева — иначе сбрасывается фокус TextField.
final collapseMobileBottomNavProvider = StateProvider<bool>((ref) => false);

/// Редактор профиля: поле открыто — схлопнуть хром в альбоме до прихода inset.
final profileEditFieldOpenProvider = StateProvider<bool>((ref) => false);
