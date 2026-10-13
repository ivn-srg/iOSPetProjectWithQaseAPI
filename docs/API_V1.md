# Каталог Qase TestOps API v1

Каталог описывает маршруты, объявленные в [API.Operation](../QaseAPIProj/Data/APIManager.swift), и доступные [модели запросов и ответов](../QaseAPIProj/Data/Models/QaseAPIModels.swift). В исходниках перечислены **89 операций и 50 шаблонов пути**. Это покрытие сетевого клиента; наличие операции не означает, что для неё есть пользовательский экран или что запрос проверен на сервере.

## Сеть и пользовательские сценарии

По текущим исходникам интерфейс подключает проекты, иерархию suites/cases, поиск по названию, создание проекта/suite/case, удаление project/suite/case и редактирование case. Выбор родительского набора реализован. Шаги кейса показываются для чтения; отдельный редактор существующего suite ещё не подключён.

В Home и Work есть чтение списка и деталей runs/defects, переход к кейсу из run, а также последние просмотренные кейсы. Создание и выполнение run, отправка result, создание defect из failed result, планы, загрузка evidence, QQL, shared/custom/system fields остаются направлениями [roadmap](ROADMAP.md). Маршруты этих операций уже описаны сетевым слоем. Подключение экранов находится в [FeatureScreenFactory](../QaseAPIProj/Classes/FeatureScreenFactory.swift).

`API.makeURL` подставляет параметры пути, `NetworkManager.performRequest` отправляет JSON и декодирует модель, которую задаёт вызывающий код. Multipart-вложения отправляются через `performMultipartRequest`. Оба метода используют заголовок `Token` с текущими credentials; проверка нового токена передаёт candidate отдельно.

[Спецификация Qase v1](https://github.com/qase-tms/specs/tree/master/testops-api/v1) и [официальный API reference](https://developers.qase.io/reference/introduction-to-the-qase-api) — внешние источники для проверки схем и требований перед подключением новых функций. Их актуальность и совместимость всех операций с живым API в рамках очистки не проверялись. Параметры и модели таблицы отражают каталог проекта; generic DTO не заменяет проверку контракта конкретной операции.

## Операции

Для каждого placeholder маршрута передавайте соответствующий `code`, `id` или `hash`. Query-параметры задавайте массивом `URLQueryItem`: так сохраняются повторяющиеся ключи и bracket notation. Для строк с общим envelope выберите конкретную модель ответа по проверенному контракту операции.

| Ресурс | Метод и путь | Входные данные | Модель успешного ответа |
| --- | --- | --- | --- |
| Attachments | `GET /attachment` | Query: limit, offset | `QaseAPIResponse<QaseAPIListResult<QaseAPIAttachmentDTO>>` |
| Attachments | `GET /attachment/{hash}` | Path: hash | `QaseAPIResponse<QaseAPIAttachmentDTO>` |
| Attachments | `DELETE /attachment/{hash}` | Path: hash | Envelope результата Qase |
| Attachments | `POST /attachment/{code}` | Multipart `file[]`; max 20 files, 32 MB each, 128 MB per request | Envelope загрузки |
| Authors | `GET /author` | Query: search, type, limit, offset | `QaseAPIResponse<QaseAPIListResult<QaseAPIAuthorDTO>>` |
| Authors | `GET /author/{id}` | Path: id | `QaseAPIResponse<QaseAPIAuthorDTO>` |
| Cases | `GET /case/{code}` | Query: search, milestone_id, suite_id, severity, priority, type, behavior, automation, status, `external_issues[type]`, repeated `external_issues[ids][]`, include, limit, offset | `QaseAPIResponse<QaseAPIListResult<TestCaseEntity>>` |
| Cases | `POST /case/{code}` | `EncodableTestCase` JSON body | `QaseAPIResponse<QaseAPIIDResult>` |
| Cases | `GET /case/{code}/{id}` | Query: include | `QaseAPIResponse<TestCaseEntity>` |
| Cases | `PATCH /case/{code}/{id}` | `EncodableTestCase` JSON body | `QaseAPIResponse<QaseAPIIDResult>` |
| Cases | `DELETE /case/{code}/{id}` | — | `QaseAPIResponse<QaseAPIIDResult>` |
| Cases | `POST /case/{code}/bulk` | `QaseAPIBulkCasesRequest` JSON body | `QaseAPIResponse<QaseAPIIDsResult>` |
| Cases | `POST /case/{code}/external-issue/attach` | `QaseAPIExternalIssueRequest` JSON body (`type`, `links`) | Envelope результата Qase |
| Cases | `POST /case/{code}/external-issue/detach` | `QaseAPIExternalIssueRequest` JSON body (`type`, `links`) | Envelope результата Qase |
| Configurations | `GET /configuration/{code}` | Path: code | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Configurations | `POST /configuration/{code}` | `QaseAPIConfigurationRequest` JSON body | Envelope результата Qase |
| Configurations | `POST /configuration/{code}/group` | `QaseAPIConfigurationGroupRequest` JSON body | Envelope результата Qase |
| Custom fields | `GET /custom_field` | Query: уточнить поля по спецификации | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Custom fields | `POST /custom_field` | `QaseAPICustomFieldCreateRequest` JSON body | Envelope результата Qase |
| Custom fields | `GET /custom_field/{id}` | Path: id | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Custom fields | `PATCH /custom_field/{id}` | `QaseAPICustomFieldUpdateRequest` JSON body | Envelope результата Qase |
| Custom fields | `DELETE /custom_field/{id}` | Path: id | Envelope результата Qase |
| System fields | `GET /system_field` | Query: уточнить поля по спецификации | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Defects | `GET /defect/{code}` | Query: status, limit, offset | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Defects | `POST /defect/{code}` | `QaseAPIDefectCreateRequest` JSON body | `QaseAPIResponse<QaseAPIIDResult>` |
| Defects | `GET /defect/{code}/{id}` | Path: code, id | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Defects | `PATCH /defect/{code}/{id}` | `QaseAPIDefectUpdateRequest` JSON body | Envelope результата Qase |
| Defects | `DELETE /defect/{code}/{id}` | Path: code, id | Envelope результата Qase |
| Defects | `PATCH /defect/{code}/resolve/{id}` | Path: code, id | Envelope результата Qase |
| Defects | `PATCH /defect/{code}/status/{id}` | `QaseAPIDefectStatusRequest` JSON body | Envelope результата Qase |
| Environments | `GET /environment/{code}` | Query: limit, offset | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Environments | `POST /environment/{code}` | `QaseAPIEnvironmentCreateRequest` JSON body | `QaseAPIResponse<QaseAPIIDResult>` |
| Environments | `GET /environment/{code}/{id}` | Path: code, id | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Environments | `PATCH /environment/{code}/{id}` | `QaseAPIEnvironmentUpdateRequest` JSON body | Envelope результата Qase |
| Environments | `DELETE /environment/{code}/{id}` | Path: code, id | Envelope результата Qase |
| Milestones | `GET /milestone/{code}` | Query: уточнить поля по спецификации | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Milestones | `POST /milestone/{code}` | `QaseAPIMilestoneCreateRequest` JSON body | `QaseAPIResponse<QaseAPIIDResult>` |
| Milestones | `GET /milestone/{code}/{id}` | Path: code, id | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Milestones | `PATCH /milestone/{code}/{id}` | `QaseAPIMilestoneUpdateRequest` JSON body | Envelope результата Qase |
| Milestones | `DELETE /milestone/{code}/{id}` | Path: code, id | Envelope результата Qase |
| Plans | `GET /plan/{code}` | Query: уточнить поля по спецификации | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Plans | `POST /plan/{code}` | `QaseAPIPlanCreateRequest` JSON body | `QaseAPIResponse<QaseAPIIDResult>` |
| Plans | `GET /plan/{code}/{id}` | Path: code, id | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Plans | `PATCH /plan/{code}/{id}` | `QaseAPIPlanUpdateRequest` JSON body | Envelope результата Qase |
| Plans | `DELETE /plan/{code}/{id}` | Path: code, id | Envelope результата Qase |
| Projects | `GET /project` | Query: search, limit, offset | `ProjectDataModel` или `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Projects | `POST /project` | `QaseAPIProjectCreateRequest` JSON body (title, code required; access may require group) | `QaseAPIResponse<QaseAPIProjectCodeResult>` |
| Projects | `GET /project/{code}` | Path: code | `QaseAPIResponse<Project>` |
| Projects | `DELETE /project/{code}` | Path: code | Envelope результата Qase |
| Projects | `POST /project/{code}/access` | `QaseAPIProjectAccessRequest` JSON body (`member_id`) | `QaseAPIResponse<QaseAPIEmptyResult>` |
| Projects | `DELETE /project/{code}/access` | Path: code; идентификаторы доступа: уточнить по спецификации | Envelope результата Qase |
| Results | `GET /result/{code}` | Query: status, run, case_id, member, api, from_end_time, to_end_time, limit, offset | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Results | `POST /result/{code}/{id}` | `QaseAPIResultCreateRequest` JSON body (`status` required) | Envelope результата выполнения |
| Results | `POST /result/{code}/{id}/bulk` | `QaseAPIResultBulkRequest` JSON body | Envelope групповой операции |
| Results | `GET /result/{code}/{hash}` | Path: code, hash | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Results | `PATCH /result/{code}/{id}/{hash}` | `QaseAPIResultUpdateRequest` JSON body | Envelope результата выполнения |
| Results | `DELETE /result/{code}/{id}/{hash}` | Path: code, id, hash | Envelope результата Qase |
| Reviews | `GET /review/{code}` | Query: уточнить поля по спецификации | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Reviews | `POST /review/{code}` | `QaseAPIReviewRequest` JSON body | Envelope результата Qase |
| Reviews | `GET /review/{code}/{id}` | Path: code, id | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Reviews | `PATCH /review/{code}/{id}` | `QaseAPIReviewRequest` JSON body | Envelope результата Qase |
| Reviews | `DELETE /review/{code}/{id}` | Path: code, id | Envelope результата Qase |
| Reviews | `POST /review/{code}/bulk` | `QaseAPIReviewBulkRequest` JSON body | Envelope групповой операции |
| Runs | `GET /run/{code}` | Query: search, status, milestone, environment, from_start_time, to_start_time, limit, offset, include | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Runs | `POST /run/{code}` | `QaseAPIRunCreateRequest` JSON body (`title` required) | `QaseAPIResponse<QaseAPIIDResult>` |
| Runs | `GET /run/{code}/{id}` | Query: include | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Runs | `PATCH /run/{code}/{id}` | `QaseAPIRunUpdateRequest` JSON body | Envelope результата Qase |
| Runs | `DELETE /run/{code}/{id}` | Path: code, id | Envelope результата Qase |
| Runs | `POST /run/{code}/{id}/complete` | Path: code, id | Envelope результата Qase |
| Runs | `PATCH /run/{code}/{id}/public` | `QaseAPIRunPublicRequest` JSON body (`status` required) | Envelope результата Qase |
| Runs | `POST /run/{code}/external-issue` | `QaseAPIRunExternalIssueRequest` JSON body (`type`, `links`) | Envelope результата Qase |
| Search | `GET /search` | Query: query/QQL and entity-specific filters per OpenAPI | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Shared parameters | `GET /shared_parameter` | Query: уточнить поля по спецификации | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Shared parameters | `POST /shared_parameter` | `QaseAPISharedParameterCreateRequest` JSON body (title, type, is_enabled_for_all_projects, and parameters required) | Envelope общего параметра |
| Shared parameters | `GET /shared_parameter/{id}` | Path: id | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Shared parameters | `PATCH /shared_parameter/{id}` | `QaseAPISharedParameterUpdateRequest` JSON body | Envelope общего параметра |
| Shared parameters | `DELETE /shared_parameter/{id}` | Path: id | Envelope результата Qase |
| Shared steps | `GET /shared_step/{code}` | Query: уточнить поля по спецификации | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Shared steps | `POST /shared_step/{code}` | `QaseAPISharedStepCreateRequest` JSON body (`title` required) | Envelope общих шагов |
| Shared steps | `GET /shared_step/{code}/{hash}` | Path: code, hash | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Shared steps | `PATCH /shared_step/{code}/{hash}` | `QaseAPISharedStepUpdateRequest` JSON body | Envelope общих шагов |
| Shared steps | `DELETE /shared_step/{code}/{hash}` | Path: code, hash | Envelope результата Qase |
| Suites | `GET /suite/{code}` | Query: search, limit, offset, parent_id | `SuitesDataModel` или generic list response |
| Suites | `POST /suite/{code}` | `QaseAPISuiteCreateRequest` JSON body (`title` required) | `QaseAPIResponse<QaseAPIIDResult>` |
| Suites | `GET /suite/{code}/{id}` | Path: code, id | `QaseAPIResponse<TestListEntity>` |
| Suites | `PATCH /suite/{code}/{id}` | `QaseAPISuiteUpdateRequest` JSON body | `QaseAPIResponse<QaseAPIIDResult>` |
| Suites | `DELETE /suite/{code}/{id}` | Path: code, id | Envelope результата Qase |
| Users | `GET /user` | Query: limit, offset | `QaseAPIResponse<QaseAPIListResult<QaseAPIUserDTO>>` |
| Users | `GET /user/{id}` | Path: id | `QaseAPIResponse<QaseAPIUserDTO>` |


## Использование

Пример чтения runs выбранного проекта через `NetworkManager`:

```swift
let response = try await network.performRequest(
    for: .getRuns,
    pathParameters: ["code": projectCode],
    queryItems: [API.QueryParams.status.item("in_progress")],
    with: nil,
    modelType: QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>.self
)
```

- JSON-запросы используют encoder с `convertToSnakeCase`. `QaseAPIObjectRequest` и `QaseAPIJSONValue` позволяют передать дополнительные поля и вложенные значения. Create/update DTO разделены там, где отличаются обязательные поля.
- `QaseAPIResourceDTO` сохраняет общие поля и дополнительные свойства в `fields`; `QaseAPIIdentifier` принимает числовой или строковый ID. Действующие экраны проектов, suites и cases также используют специализированные модели проекта.
- Multipart использует `file[]`. В клиенте заданы ограничения: до 20 файлов, до 32 MiB на файл, до 128 MiB на multipart body вместе с заголовками и boundary. Проверяются MIME type и экранирование имени файла. Эти константы не являются подтверждением актуальных лимитов сервера.
- Non-2xx в обычных JSON/multipart запросах становятся `API.NetError.httpError`. Числовой `Retry-After` доступен вызывающему коду; автоматического повторения запроса этот клиент не выполняет.
- `APIManager.auth(by:)` возвращает `false` для пустого токена и HTTP 401. Остальные HTTP-отказы, включая 403, передаются ошибкой; транспортные ошибки также не превращаются в `false`. Проверка candidate не меняет действующие credentials.
- Для ответов, не описанных generic DTO, используйте отдельную модель. Не подключайте операцию к UI только на основании существования маршрута: нужны проверка прав, состояний ошибок и сценария сохранения.

Сборки, компиляция, тестовые прогоны и CI при подготовке документа не запускались. Порядок пользовательской проверки описан в [DEVELOPMENT](DEVELOPMENT.md), границы сессии и кеша — в [ARCHITECTURE](ARCHITECTURE.md).
