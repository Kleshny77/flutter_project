# Трекер витаминов

Мобильное приложение — персональный помощник по приёму витаминов: умные напоминания, расписание, рекомендации «с едой / натощак» и каталог популярных добавок. Платформы: **iOS**, **Android**, **macOS**.

Подробное описание продукта, проблем и ценностей — в [docs/PROJECT.md](docs/PROJECT.md).

---

## Быстрый старт

### 1. Требования

- [Flutter](https://docs.flutter.dev/get-started/install) (stable)
- Для iOS/macOS: Xcode, лицензия принята (`sudo xcodebuild -license`)
- Для Android: Android Studio или SDK + эмулятор/устройство

Проверка окружения:

```bash
flutter doctor
```

### 2. Клонирование и зависимости

```bash
git clone https://github.com/Kleshny77/flutter_project.git
cd flutter_project
flutter pub get
```

### 3. Настройка Firebase (обязательно для авторизации и каталога)

1. Установите [Firebase CLI](https://firebase.google.com/docs/cli) (например: `brew install firebase-cli`) и войдите: `firebase login`.
2. Установите FlutterFire CLI и выполните настройку в корне проекта:

```bash
dart pub global activate flutterfire_cli
export PATH="$PATH:$HOME/.pub-cache/bin"
flutterfire configure
```

В диалоге выберите проект Firebase и платформы (iOS, Android, macOS). Будет создан `lib/firebase_options.dart`.

3. В [Firebase Console](https://console.firebase.google.com) → ваш проект → **Authentication** → **Sign-in method** → включите **Email/Password**.

Без настройки приложение покажет экран с инструкцией вместо входа.

### 4. Запуск приложения

Узнать доступные устройства:

```bash
flutter devices
```

Запуск (выполняйте команды по одной):

```bash
# iOS (сначала откройте Simulator)
flutter run -d ios
# или, если несколько устройств: flutter run -d "iPhone Air"

# Android (эмулятор или устройство по USB)
flutter run -d android

# macOS
flutter run -d macos

# Браузер (для проверки)
flutter run -d chrome
```

---

## Сборка

```bash
flutter build ios
flutter build macos
```

Дальнейшая подпись и загрузка — через Xcode.

---

## Реализованные фичи

- **Авторизация:** приветствие, регистрация и вход по e-mail/паролю, восстановление пароля (Firebase Auth).
- **Профиль:** имя, фамилия, e-mail, аватар (Firestore + Storage).
- **Аптечка:** каталог топ-20 витаминов из Firestore; добавление своего витамина или из каталога (название, вид, доза, когда принимать); редактирование и удаление.
- **Расписание:** календарь, приёмы по дням, отметки «принято» / «пропущено», локальные уведомления.
- **Статистика:** месячная статистика по каждому напоминанию.
- **Онбординг:** подсказки при первом заходе.
- **Аналитика:** события Firebase (регистрация/вход — успех и ошибка).

---

## Качество кода и тесты

- **Линтер и формат:** `flutter_lints` в `pubspec.yaml` и `analysis_options.yaml`, код форматируется через `dart format`. Проверка: `flutter analyze`.
- **Тесты:** unit-тесты доменной логики авторизации, widget-тесты экранов и сценариев входа/регистрации. Запуск: `flutter test`.
- **Архитектура:** слоистая (Domain / Data / Presentation), зависимости собираются в `main.dart`, UI зависит от абстракций (например, `AuthRepository`).

---

## Частые проблемы

- **Нет устройств для iOS/Android** — запустите симулятор или эмулятор, затем снова `flutter devices`.
- **Ошибка симулятора (device's data is no longer present)** — удалите битый симулятор: `xcrun simctl delete unavailable`.

---

## Документация Flutter

- [Документация Flutter](https://docs.flutter.dev/)
- [Lab: первое приложение](https://docs.flutter.dev/get-started/codelab)
- [Cookbook](https://docs.flutter.dev/cookbook)
