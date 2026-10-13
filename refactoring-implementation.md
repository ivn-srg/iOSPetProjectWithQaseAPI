# Реализация проверенного плана

Дата: 12 октября 2026. Работу выполнил один агент без реализации через подагентов. Существующие незакоммиченные дизайн-материалы сохранены. Новые зависимости и endpoints не добавлены; UIKit, SwiftUI, SnapKit и Realm сохранены.

## Выполненные этапы

1. Реестр исходников и исходники регрессионных проверок обновлены. До поведенческих исправлений добавлены проверки numeric Codable, nested-step equality и request payload.
2. Четыре traitCollectionDidChange заменены targeted observations с первоначальным render. Deprecated UIBarButtonItem.Style.done заменён на plain / prominent с iOS 26 availability. Project deployment согласован с targets: iOS 18.6; Swift language mode 5 сохранён. Кешированный frame LaunchScreen согласован с aspect constraint.
3. AppCompositionRoot создаёт app dependencies; authenticated graph создаётся после activate, пересоздаётся при смене token и освобождается при logout. Router и factory разделены; MainTabbar не собирает сервисы/модели. Добавлены узкие repository/cache/auth contracts, typed form values, screen loading states и actor-safe HTTPTransport. Old repositories/Home/paged models не могут обслуживать новую сессию.
4. Общие tokens переиспользованы, локальная геометрия вынесена в Layout, политики — в AppPolicies. AppTab заменяет индексы; AppImages/AppSymbol являются общими ресурсами UIKit/SwiftUI. Удалены дубли изображений и старые theme aliases.
5. AccessibilityID — один Foundation-only исходник app + UITests; unit target импортирует его через приложение. Динамические IDs не собираются в представлении. Неактивный draft исключён из accessibility hierarchy. Home actions имеют стабильные ключи; UI-тесты явно задают язык и Dynamic Type.
6. Исправлены нижние viewport/insets Home и редактора, компактные поля проекта/набора/кейса, intrinsic badge шагов, summary Repository и расстояние 4 pt в чипах. Создание проекта использует общую форму и нативную навигацию.
7. Structural Equatable/Hashable шагов и integer Codable семи enum реализованы; request/Realm не зависят от menuItem. Suite catalog/marker записываются атомарно; ошибки кеша обрабатываются явно. Пагинация без total продолжает чтение полных страниц; повторная страница не считается завершённым каталогом. Persisted имена и Realm schema 5 сохранены.
8. Форматирование всех 97 Swift-файлов выполнено через установленный SwiftFormat; конфигурация сохранена в .swiftformat. Обновлены registration, локализация, CLAUDE.md и дизайн-контракт.

## Упрощения и изменения интерфейсов

- Удалены LoadingIndicator и неиспользуемые Dropdown, Tiles, ButtonWithLeadingImage, Search/TestRuns placeholders, исключённый SuiteAndCaseData и резервный ~HEAD. PropertiesPickerTextField заменён прямым использованием CustomSelectableView.
- DetailTabbarControllerViewModel → TestCaseEditorViewModel; CreateSuiteOrCaseViewModel → EntityCreationViewModel.
- Feature init требуют готовые dependencies; UI-компоненты передают FormFieldValue, не выполняют casts к конкретной creation model.
- Сеть получает HTTPTransport и источник актуального token; проверка candidate не меняет действующие credentials. Login/logout сохраняют исходную сессию при ошибке записи/удаления credentials.
- В ProjectTableViewCell hierarchy/constraints создаются один раз. Глобальные loader и mock service locator удалены.
- Дублирующее включение Ext+UIColor в unit и Ext+String в UITests удалено.

## Исправления после валидации

- Свежие кейсы показываются при отказе кеша. Repository записывает страницы один раз; модель отдельно сообщает об ошибке атомарного сохранения полного списка и снимка, сохраняя данные на экране. Частичная загрузка не удаляет ранее сохранённые записи.
- Загрузка редактора отменяется при уходе с экрана и инвалидировании его сессии. Задача не удерживает контроллер во время сетевого ожидания; повторное появление незагруженного экрана запускает загрузку заново. Отменённый поздний ответ не публикуется и не попадает в кеш или историю.
- У поля ввода совпадают отступы placeholder и текста. Accessibility hint использует текущий лимит политики; неиспользуемая строка с фиксированным числом удалена.
- Добавлены исходники регрессионных проверок отказа кеша, частичной пагинации, атомарной записи, освобождения редактора, отмены сессии и позднего успешного ответа; дополнены проверки поля ввода. Эти тесты не запускались.

## Собранная статическая проверка

- SwiftFormat: проверка форматирования всех app/unit/UI исходников.
- SwiftLint: duplicate imports, force cast/try, trailing semicolon/whitespace, unused closure parameter/optional binding, unneeded override, duplicate enum cases, incompatible concurrency annotation. Это выбранные source rules, не полный compiler warning baseline.
- Project/plist/JSON/XML: структура и ссылки проверены без Xcode compiler.
- Source checks: 76 app + 17 unit + 4 UI файла зарегистрированы; shared ID source включён в app и UITests по одному разу, отсутствует в unit Sources. Нет старых callbacks, SF/ID строк вне каталогов, retired symbols, пропущенных обязательных dependency labels и прямой сборки сервисов/моделей в presentation.
- Исходники проверок: token headers JSON/multipart, graph lifecycle, credential failure ordering, cache isolation, enum encoding/fallback/request/Realm, nested steps, IDs, реальное изменение traits и badge geometry. Тесты не запускались.

## Проверка пользователем и ограничения

Сборки, компиляция, тесты, анализ через сборочную систему и CI не запускались по AGENTS.md. Статическая проверка не подтверждает typecheck, выполнение тестов или визуальный результат. Полное устранение compiler/SDK/dependency warnings подтверждается только диагностикой пользовательской сборки.

После сборки проверить RU/EN, light/dark, ширины 320/402 pt, accessibility text/VoiceOver, Home с OfflineBanner, последний элемент редактора, клавиатуру/interactive dismissal, самостоятельное создание проекта, отмену/сохранение двух drafts, смену token/project и stale responses.

## Реестр текущих исходников

- `QaseAPIProj/AppDelegate.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Classes/AppCompositionRoot.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Classes/AppPolicies.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Classes/ApplicationRouter.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Classes/Constants.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Classes/DataContracts.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Classes/FeatureScreenFactory.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Classes/ProjectNavigation.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Classes/Protocols.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Classes/TestCaseFieldEnums.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/APIManager.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/AppSettingsStore.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/AuthManager.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/Database/EntitiesRO.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/Database/RealmDB.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/HTTPTransport.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/HomeRepository.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/Models/HomeData.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/Models/ProjectDataModel.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/Models/QaseAPIModels.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/Models/RepositoryModels.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/Models/SharedResponseModel.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/Models/SuitesDataModel.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/Models/TestCasesModel.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/SelectedProjectStore.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/SessionContext.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Data/SuiteCatalogLoader.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Extensions/Ext+NotificationName.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Extensions/Ext+String.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Extensions/Ext+UIAlertController.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Extensions/Ext+UIColor.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Extensions/Ext+UIViewController.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Resources/AccessibilityID.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Resources/AppImages.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Resources/AppTheme.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/SceneDelegate.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewControllers/AuthViewController.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewControllers/CreatingVC/CreateSuiteOrCaseViewController.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewControllers/CreatingVC/CreateSuiteView.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewControllers/CreatingVC/CreateTestCaseView.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewControllers/CreatingVC/CreatingProjectViewController.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewControllers/CreatingVC/SuitePickerViewController.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewControllers/DetailCaseScreen/GeneralDetailCaseViewController.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewControllers/DetailCaseScreen/TestCaseViewController.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewControllers/HomeViewController.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewControllers/MainTabbarViewController.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewControllers/ProjectsViewController.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewControllers/RepositoryViewController.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewControllers/RootViewController.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewControllers/SettingsViewController.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewModel/CreatingProjectViewModel.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewModel/EntityCreationViewModel.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewModel/HomeViewModel.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewModel/ProjectReadViewModels.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewModel/ProjectsViewModel.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewModel/SettingsViewModel.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewModel/SuitePickerViewModel.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewModel/TestCaseEditorViewModel.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/ViewModel/TestEntitiesViewModel.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/Components/CasePropertiesFormView.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/Components/CustomSelectableView.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/Components/EmptyListLabel.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/Components/FormMessageView.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/Components/FormParentButton.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/Components/FormSectionView.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/Components/FormTextInputPolicy.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/Components/GeneralCaseTextField.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/Components/SwitcherWithTitle.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/Components/TextFieldWithPadding.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/HomeComponents.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/HomeView.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/ProjectReadViews.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/ProjectTableViewCell.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/RepositoryView.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/SettingsView.swift` — приложение; зарегистрирован в target.
- `QaseAPIProj/Views/TestCaseStepsCell.swift` — приложение; зарегистрирован в target.
- `QaseAPIProjTests/AppSettingsTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/ArchitectureRegressionTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/CacheManagementTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/DesignTokenTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/FormComponentTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/FormDraftTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/FormParentPickerTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/HomeDataTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/HomeViewModelTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/IdentityCacheTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/PagedReadViewModelTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/ProjectLifecycleTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/ProjectSwitchTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/QaseAPIProjTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/RepositoryRefinementTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/TestDependencies.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjTests/TokenReplacementTests.swift` — unit — не запускался; зарегистрирован в target.
- `QaseAPIProjUITests/HomeScreenUITests.swift` — UI — не запускался; зарегистрирован в target.
- `QaseAPIProjUITests/QaseAPIProjUITests.swift` — UI — не запускался; зарегистрирован в target.
- `QaseAPIProjUITests/QaseAPIProjUITestsLaunchTests.swift` — UI — не запускался; зарегистрирован в target.
- `QaseAPIProjUITests/Screens.swift` — UI — не запускался; зарегистрирован в target.

## Прочие изменённые файлы

- `.swiftformat`.
- `QaseAPIProj.xcodeproj/project.pbxproj`.
- `QaseAPIProj/Resources/Localizable.xcstrings`.
- `QaseAPIProj/Resources/Base.lproj/LaunchScreen.storyboard`.
- `CLAUDE.md`.
- `Design/DESIGN_SYSTEM.md`.
