# flutter_project

Flutter-проект с поддержкой iOS, Android и macOS.

## Запуск

Перейдите в папку проекта и выполните команды **по одной** (не копируйте весь блок целиком):

Список доступных устройств:

```
flutter devices
```

Запуск на macOS:

```
flutter run -d macos
```

Запуск на iOS: сначала откройте приложение Simulator (чтобы симулятор появился в списке), затем укажите **имя или id** устройства из `flutter devices`, например:

```
flutter run -d "iPhone Air"
```

Или просто (если симулятор один): `flutter run -d ios` — но если Flutter пишет «no devices matching 'ios'», используйте имя из списка, как выше.

Запуск на Android (нужен эмулятор или устройство):

```
flutter run -d android
```

Сейчас у вас доступны: **macOS** и **Chrome**. Для iOS/Android установите Xcode (симулятор iOS) или Android Studio (эмулятор Android) и при необходимости выполните `flutter doctor`.

## «No supported devices found» для iOS/Android

Flutter показывает только **уже запущенные** симуляторы и эмуляторы. Пока симулятор не запущен, его нет в `flutter devices`, поэтому `flutter run -d ios` пишет, что устройств нет.

**iOS — что сделать по шагам:**

1. Запустите приложение **Симулятор** (Simulator) на Mac (Spotlight: `Simulator` или в Xcode: **Xcode → Open Developer Tool → Simulator**).
2. Дождитесь загрузки симулятора (появится окно с iPhone).
3. В терминале снова выполните:

```
flutter devices
```

В списке должен появиться iPhone (например, «iPhone 16»).
4. Затем:

```
flutter run -d ios
```

**Какие эмуляторы есть у системы:**

```
flutter emulators
```

Оттуда можно запустить эмулятор, например: `flutter emulators --launch <id>`.

## Ошибка «device's data is no longer present» / «Unable to boot device»

Так бывает, когда папка с данными симулятора удалена (очистка диска, обновление Xcode), а запись об устройстве осталась. Нужно удалить эту запись.

Удалить конкретный «битый» симулятор (подставьте свой UUID из сообщения об ошибке):

```
xcrun simctl delete DDA2842E-3AC1-4AC4-BD4D-3F56FD6E6265
```

Удалить все недоступные (unavailable) симуляторы:

```
xcrun simctl delete unavailable
```

После этого откройте Simulator снова — будут только рабочие устройства.

## Если не запускается (macOS / iOS)

**1. Принять лицензию Xcode** (обязательно, иначе ни macOS, ни iOS не соберутся):

```
sudo xcodebuild -license
```

Введите пароль Mac, прокрутите до конца (пробел), введите `agree` и Enter.

**2. После этого запуск на macOS должен заработать:**

```
flutter run -d macos
```

**3. Симулятор iOS:** после принятия лицензии симуляторы обычно уже есть в Xcode. Посмотреть список:

```
xcrun simctl list devices available
```

Запуск на первом доступном симуляторе:

```
flutter run -d ios
```

Если симуляторов нет — откройте **Xcode → Settings → Platforms** и установите нужную версию iOS.

**4. Пока настраиваете — можно запустить в браузере:**

```
flutter run -d chrome
```

## Android

Нужны Android Studio и эмулятор (AVD): установите [Android Studio](https://developer.android.com/studio), откройте **Tools → Device Manager**, создайте виртуальное устройство. После этого появится в `flutter devices`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
