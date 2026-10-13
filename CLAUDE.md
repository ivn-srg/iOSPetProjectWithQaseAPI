# CLAUDE.md

Обязательные ограничения для агентов: `AGENTS.md`. Команды сборки и тестов ниже предназначены для самостоятельного запуска пользователем.

Рабочие заметки для разработки приложения. Перед изменением сетевого слоя или навигации проверьте связанные тесты и mock-данные.

## Проект

UIKit-приложение для Qase TMS: авторизация по API-токену, проекты, наборы и тест-кейсы, создание сущностей и редактирование кейса. Демо-режим описан в `README.md`; он запускается долгим нажатием на логотип на экране авторизации.

## Команды разработки

Откройте проект и проверьте доступные симуляторы:

```bash
open QaseAPIProj.xcodeproj
xcrun simctl list devices available
```

Список схем:

```bash
xcodebuild -list -project QaseAPIProj.xcodeproj
```

Сборка без привязки к устройству:

```bash
xcodebuild build \
  -project QaseAPIProj.xcodeproj \
  -scheme QaseAPIProj \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

Unit-тесты на установленном симуляторе с iOS не ниже 18.6:

```bash
xcodebuild test \
  -project QaseAPIProj.xcodeproj \
  -scheme QaseAPIProj \
  -destination 'platform=iOS Simulator,name=iPhone 14,OS=18.6' \
  -only-testing:QaseAPIProjTests
```

Для UI-тестов замените последний аргумент на `-only-testing:QaseAPIProjUITests`. Для отдельного unit-теста используйте `-only-testing:QaseAPIProjTests/QaseAPIProjTests/checkValidURL`.

CI выбирает Xcode 26.3 и симулятор iPhone 16 с iOS 18.6, что соответствует deployment target приложения. SwiftFormat настроен в `.swiftformat`. SwiftLint проверяется отдельно выбранными статическими правилами без сборки.

## Высокоуровневая архитектура

- `AppDelegate` создаёт `AppCompositionRoot`; `SceneDelegate` получает из него root и настройки окна. Конкретные auth, credential storage, transport, cache и settings создаются в composition root.
- `RootViewController` выполняет containment и слушает события своего `SessionContext`. Authenticated graph создаётся после restore/activate, пересоздаётся после token replacement и освобождается при logout. Selection/repositories/router/factory не переживают исходную сессию.
- `ApplicationRouter` управляет переходами и получает weak UI-host после сборки. `FeatureScreenFactory` собирает экраны с готовыми моделями и узкими repository/cache/auth interfaces; `MainTabbarViewController` управляет UI вкладок и guarded departure.
- `APIManager` получает источник актуальных credentials и `HTTPTransport`. JSON и multipart запросы читают токен при создании каждого запроса; auth-кандидат проверяется явно переданным токеном. `APIMockManager` создаётся отдельно для каждого окружения; demo/UI-test Realm не используют production cache.
- `RealmManager` сохраняет schema 5 и owner/project/entity keys. Suite catalog и completeness marker записываются одной транзакцией; полный список кейсов и снимок уровня также сохраняются атомарно. Запись после session-stamp проверки не содержит await. Частичные страницы и результаты поиска не удаляют полный кеш. Страницы кейсов кеширует repository; отказ кеша не блокирует показ свежих данных.
- Создание использует `EntityCreationViewModel` и `CreatingProjectViewModel`; единый редактор — `TestCaseEditorViewModel`. Input values типизированы; модели не управляют глобальным loader. Loading/saving отображаются экраном.
- Home, Repository, Work и Settings используют SwiftUI внутри UIKit-навигации; формы остаются UIKit/SnapKit. Общие tokens находятся в `AppTheme`; локальные размеры — в `Layout`, политики — в `AppPolicies`, symbols и UIKit images — в `AppImages`.
- `AccessibilityID` — один Foundation-only исходник для app и UITests. Unit target получает его через `@testable import`; динамические ключи формируются только внутри enum.
- Тесты используют отдельные mocks и test factories. Регрессионные исходники покрывают graph lifetime, token headers, numeric Codable, Realm steps, traits и layout; агент их не запускает.

## Внешние зависимости

Проект использует SnapKit и Realm Swift через Swift Package Manager. Ограничения версий заданы в `project.pbxproj`, а точные ревизии сохранены в `QaseAPIProj.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.


## Важные замечания для изменений

- Не добавлять реальные API-токены в код. Текущий демонстрационный вход из `AuthViewController` следует проверять отдельно от авторизации пользователя.
- При изменениях auth/root flow проверять связку `AuthManager` → `.didChangeAuthStatus` → `RootViewController`.
- При изменениях network/cache flow проверять и real API path, и mock path (`UITests`/`APIMockManager`), потому что тесты зависят от локальных JSON fixtures.
- Во всех запросах, навигации и кеше передавать явный projectCode/reference. Глобального `PROJECT_NAME` нет. Ключи кеша включают владельца, проект и тип сущности; корневой родитель — nil. Частичные поисковые страницы не удаляют другие записи.
