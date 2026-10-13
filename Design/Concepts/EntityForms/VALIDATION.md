# Валидация кода: формы кейсов и наборов

Дата: 9 октября 2026.

**Проверено:** 30 актуальных изменённых/новых Swift-файлов, 4152 строки исходников и связанный контекст · **Осей:** 6 · **Способ:** независимые чтения компонентов/моделей и интеграции, затем заключительная проверка основным агентом без подагентов.

## Вердикт

**PASS по статической проверке.** Подтверждённые замечания исправлены. Это не подтверждение успешной компиляции, прохождения тестов или визуального совпадения приложения.

## Дефекты

Оставшихся подтверждённых дефектов в проверенном объёме не обнаружено.

## Исправленные замечания

1. **Критика плана — saving до dirty.** [ProjectNavigation.swift](../../../QaseAPIProj/Classes/ProjectNavigation.swift:77): занятость проверяется у всех участников до фильтрации dirty, после диалога и перед очередным сохранением. Повторные диалоги защищены флагом. Проверено чтением кода.
2. **Критика плана — отмена каталога и отсутствие счётчиков.** [SuiteCatalogLoader.swift](../../../QaseAPIProj/Data/SuiteCatalogLoader.swift:18): поколение/сессия/cancellation проверяются после await и перед кешем; без total/filtered читаются страницы до пустой/неполной, повторяющаяся полная страница не создаёт бесконечный цикл. Проверено чтением кода.
3. **Реальная несовместимость выбора.** [CreateSuiteOrCaseVIewModel.swift](../../../QaseAPIProj/ViewModel/CreateSuiteOrCaseVIewModel.swift:153): Int/MenuItem нормализуются к существующему ID; parentSuite меняет parentId или suiteId нужного черновика. Исправлены неверные ID последних трёх опций Types.dataSource без изменения Codable/enum-кодировки. Проверено чтением обеих сторон цепочки.
4. **[MAJOR, исправлено] Большая вставка текста.** [FormTextInputPolicy.swift](../../../QaseAPIProj/Views/Components/FormTextInputPolicy.swift:11): объём вставки предварительно ограничивается, большой clipboard не проходит цикл удаления по одному символу с пересчётом всей строки. Сохраняются суффикс и UTF-16 курсор. Проверено чтением кода; исходники регрессий добавлены, не запускались.
5. **[MINOR, исправлено] Счётчик и длинное загруженное поле.** [GeneralCaseTextField.swift](../../../QaseAPIProj/Views/Components/GeneralCaseTextField.swift:152): счётчик видим в фокусе; неизменённый текст с сервера не обрезается при простом фокусе/blur; составной ввод подтверждается перед уходом; placeholder растёт при крупном тексте. Проверено чтением кода; исходники проверок добавлены.
6. **[MAJOR, исправлено] Перенос маркера.** [CustomSelectableView.swift](../../../QaseAPIProj/Views/Components/CustomSelectableView.swift:105): при вертикальном расположении маркер остаётся у выбранного текста; стрелка и обновление trait используют ту же baseline. Проверено геометрией ограничений; фактический layout без запуска не подтверждён.
7. **Клавиатура создания.** [CreateSuiteOrCaseViewController.swift](../../../QaseAPIProj/ViewControllers/CreatingVC/CreateSuiteOrCaseViewController.swift:88): после появления/смены рамки клавиатуры повторяется раскрытие курсора; один keyboardLayoutGuide отвечает за нижнюю границу. Проверено чтением кода и документацией.
8. **Системное скрытие вкладок.** [TestCaseViewController.swift](../../../QaseAPIProj/ViewControllers/DetailCaseScreen/TestCaseViewController.swift:73): сохранение isTabBarHidden и системный setTabBarHidden вместо изменения только UIView.isHidden. Предыдущее состояние восстанавливается. Проверено чтением кода и документацией для iOS 18+, целевой target 18.6.
9. **Покрытие скрытого payload.** [FormDraftTests.swift](../../../QaseAPIProjTests/FormDraftTests.swift:118): добавлен захват фактического PATCH для полного fixture с вложенными шагами, вложениями, тегами и родителем; проверяется сохранность существующих полей и ID Types. Исходник прочитан, тест не запускался.

## Что реализовано

| Область | Файлы и результат |
|---|---|
| Общие строки | CustomSelectableView, PropertiesPickerTextField: выбранный текст → точка 6 pt → стрелка; API без значка, целая строка открывает прежнее меню |
| Текст и toggle | GeneralCaseTextField, SwitcherWithTitle, FormTextInputPolicy: отдельный режим entityForm, лимит 500, Unicode, фокус и растущая высота; legacy-оформление проекта сохранено |
| Создание | CreateSuiteOrCaseViewController/CreateSuiteView/CreateTestCaseView, MainTabbarViewController: одна компактная навигация и скролл, два независимых черновика |
| Редактор | TestCaseViewController, GeneralDetailCaseViewController, CasePropertiesFormView, TestCaseStepView: единая форма, все параметры и многострочные read-only шаги |
| Родитель | SuitePickerViewController/Model, SuiteCatalogLoader: текущий проект, корень nil, путь, поиск, выбор/отмена, loading/error/retry/empty |
| Сохранение/уход | Две VM, ProjectNavigation, MainTabbarViewController: busy, подтверждение ухода, partial success без дубликата, stale response guard |
| Сборка проекта | 11 новых исходников зарегистрированы ровно по одному в правильных app/test targets; старый PropertiesDetailCaseViewController удалён после проверки отсутствия вызовов |
| Проверки | 29 новых определений тестов в трёх Form*Tests, отдельная busy-проверка в ProjectSwitchTests, page objects в Screens.swift |

## Статические свидетельства

- plutil проверил синтаксис project.pbxproj; дополнительное чтение конфигурации подтвердило правильные target/source phases.
- Ключи интерфейса проверены в RU/EN: 47 ключей; для существующих EN-записей без явной локализации используется штатный sourceLanguage=en fallback. Is Flaky — «Нестабильный тест».
- git diff --check через RTK завершился без ошибок.
- Старые внутренние страницы, свайпы их переключения и вызовы удалённого контроллера не найдены.
- DTO/Realm-схемы, сетевые endpoints, зависимости и основные четыре вкладки не перестраивались.
- Подагенты остановлены по просьбе пользователя; заключительная сверка выполнена основным агентом.

## Требует пользовательской проверки

После самостоятельной сборки: 402 × 874/320 pt, оба языка и темы, крупный шрифт/VoiceOver, курсор и клавиатура, перенос значения с точкой, root/длинные/одинаковые названия, сохранение/ошибка/частичный успех, Back/жест/смена вкладки/продолжение второго черновика, три шага выше вкладок и прежнее оформление создания проекта.

Сборка, компиляция, swift-parse, LSP-диагностика, тестовые прогоны и CI не запускались. Совпадение с макетами без актуальных скриншотов приложения не заявляется. Редактор набора по-прежнему отдельная будущая задача.

## Источники и ограничения

AGENTS.md и CLAUDE.md проекта, глобальные правила, выбранные макеты/контракт; Docs/RuleBase.md и Docs/ClassExtensions отсутствуют, номера несуществующих правил не цитировались. SocratiCode/Qdrant недоступен, использованы rg и целевые чтения; индексация повторно не запускалась.

Apple через sosumi: [keyboardLayoutGuide](https://sosumi.ai/documentation/uikit/uiview/keyboardlayoutguide), [markedTextRange](https://sosumi.ai/documentation/uikit/uitextinput/markedtextrange), [setTabBarHidden](https://sosumi.ai/documentation/uikit/uitabbarcontroller/settabbarhidden(_:animated:)), [isTabBarHidden](https://sosumi.ai/documentation/uikit/uitabbarcontroller/istabbarhidden).

**Pattern compliance: PASS | checked=UIKit/SnapKit, MainActor VM, явные project/session, локализация .localized, существующие меню/ID и cache helpers, KISS/DRY, отмена/ошибка без потери ввода.** Ограничение: только чтение кода/документации и проверка ресурсов/метаданных.
