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

CI выбирает Xcode 26.3 и симулятор iPhone 16 с iOS 18.6, что соответствует deployment target приложения. SwiftLint и SwiftFormat в проекте не настроены.

## Высокоуровневая архитектура

- `SceneDelegate` создаёт `RootViewController`; `AppDelegate` настраивает сервис для UI-тестов. По аргументу запуска `UITests` приложение включает `APIMockManager`; mock читает JSON-файлы из bundle.
- `RootViewController` слушает `.didChangeAuthStatus` и выбирает экран авторизации или `MainTabbarViewController`. `AuthManager` хранит токен в Keychain, состояние входа в `UserDefaults` и проверяет токен через `APIManager.auth(by:)`.
- `APIManager` работает с Qase API v1 и передаёт токен в заголовке `Token`. Маршруты перечислены в `API.Operation`, а модели ответов находятся в `Data/Models/`.
- Сеть, кеш и контекст сессии передаются моделям через init. Демо-сервис выбирается до создания экранов; глобального сетевого экземпляра нет.
- `RealmDB.swift` и `EntitiesRO.swift` кэшируют проекты, наборы, кейсы и детали кейса. Модели API лежат в `Data/Models/`.
- Контроллеры UIKit напрямую используют view models. `ProjectsViewModel` загружает и удаляет проекты, `TestEntitiesViewModel` управляет списком наборов и кейсов, `DetailTabbarControllerViewModel` загружает и обновляет детали кейса.
- Основные вкладки: Home, Repository, Work и Settings. Главная и иерархический Repository написаны на SwiftUI внутри UIKit-навигации. Каждый уровень имеет immutable `RepositoryLocation`; формы и детали кейса остаются UIKit. Общие компоненты находятся в `Views/`, токены — в `AppTheme.swift`.
- Unit-тесты используют Swift Testing и `APIMockManager`; UI-тесты используют XCTest и page objects из `QaseAPIProjUITests/Screens.swift`.

## Внешние зависимости

Проект использует SnapKit и Realm Swift через Swift Package Manager. Ограничения версий заданы в `project.pbxproj`, а точные ревизии сохранены в `QaseAPIProj.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.


## Важные замечания для изменений

- Не добавлять реальные API-токены в код. Текущий демонстрационный вход из `AuthViewController` следует проверять отдельно от авторизации пользователя.
- При изменениях auth/root flow проверять связку `AuthManager` → `.didChangeAuthStatus` → `RootViewController`.
- При изменениях network/cache flow проверять и real API path, и mock path (`UITests`/`APIMockManager`), потому что тесты зависят от локальных JSON fixtures.
- Во всех запросах, навигации и кеше передавать явный projectCode/reference. Глобального `PROJECT_NAME` нет. Ключи кеша включают владельца, проект и тип сущности; корневой родитель — nil. Частичные поисковые страницы не удаляют другие записи.
