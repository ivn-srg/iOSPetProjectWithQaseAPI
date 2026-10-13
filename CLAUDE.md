# Памятка разработки

Обязательные правила проекта находятся в [AGENTS.md](AGENTS.md). Агентам запрещены сборка, компиляция, тестовые прогоны, анализ через сборочную систему и запуск CI. Все команды ниже предназначены **для самостоятельного запуска пользователем**.

## Архитектура

`AppDelegate` создаёт `AppCompositionRoot`; `SceneDelegate` получает root и настройки окна. Composition root собирает авторизацию, transport, Realm и настройки, а после входа — зависимости конкретной сессии. `RootViewController` обновляет содержимое по событиям своего `SessionContext`.

`ApplicationRouter` управляет переходами, `FeatureScreenFactory` собирает экраны с готовыми зависимостями. Основные разделы используют SwiftUI внутри UIKit-навигации; формы остаются UIKit/SnapKit. Создание использует `EntityCreationViewModel` и `CreatingProjectViewModel`, редактор кейса — `TestCaseEditorViewModel`.

`APIManager` получает актуальные credentials и `HTTPTransport`. `HomeRepository` и модели экранов согласуют загрузку с кешем и сессией. Realm сейчас сохраняет schema 5; миграция на SwiftData — план развития, а не текущая реализация.

Подробности и карта исходников: [архитектура](docs/ARCHITECTURE.md). Демо запускается кнопкой «Попробовать демо»; описание возможностей — в [README](README.md).

## Инварианты при изменениях

- Не добавлять реальные токены в код. Проверка кандидата токена не изменяет действующую сессию при отказе. В HTTP-проверке авторизации `401` означает неверный токен; остальные HTTP-отказы передаются типизированными ошибками.
- Передавать явный `projectCode` или reference. После смены токена/выхода старые модели и поздние ответы не обслуживают новую сессию.
- Ключи кеша включают владельца, проект и тип сущности; корневой родитель — `nil`. Частичные страницы и поиск не заменяют полный кеш. Полный каталог и маркер полноты сохраняются атомарно.
- Сохранять два независимых черновика создания, защиту ухода и повторного сохранения. Успешная часть операции не отправляется повторно после ошибки второй части; шаги редактора кейса остаются read-only.
- Для network/cache изменений учитывать реальные и mock-пути. Demo и UI-тесты не используют production-кеш; JSON fixtures нужны приложению и проверкам.
- Общие tokens — `AppTheme`, политики — `AppPolicies`, символы — `AppImages`, идентификаторы доступности — `AccessibilityID`. Размеры конкретного компонента остаются локальными.

## Справочные команды пользователя

Открытие проекта и выбор установленного симулятора:

```bash
open QaseAPIProj.xcodeproj
xcrun simctl list devices available
```

Сборка без привязки к устройству:

```bash
xcodebuild build \
  -project QaseAPIProj.xcodeproj \
  -scheme QaseAPIProj \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

Unit-проверки на установленном симуляторе с iOS не ниже 18.6:

```bash
xcodebuild test \
  -project QaseAPIProj.xcodeproj \
  -scheme QaseAPIProj \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -only-testing:QaseAPIProjTests
```

Замените имя/OS на установленный симулятор; для UI-проверок используйте `-only-testing:QaseAPIProjUITests`. Полные инструкции и список ручной приёмки — в [DEVELOPMENT](docs/DEVELOPMENT.md).

Зависимости: SnapKit и Realm Swift через SPM, точные ревизии — в [Package.resolved](QaseAPIProj.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved). Новые зависимости без отдельного запроса не добавлять. [API-каталог](docs/API_V1.md), [roadmap](docs/ROADMAP.md) и [дизайн-система](Design/DESIGN_SYSTEM.md) описывают соответствующие области без истории промежуточных работ.
