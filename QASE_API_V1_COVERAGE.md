# Qase TestOps API v1

`API.Operation` lists the supported method and path pairs. `API.makeURL` fills in path parameters; `NetworkManager.performRequest` sends JSON and decodes the response type supplied by the caller. Attachment uploads use `performMultipartRequest`. Both request methods send the existing `Token` header.

The [Qase v1 OpenAPI specification](https://github.com/qase-tms/specs/tree/master/testops-api/v1) and [API reference](https://developers.qase.io/reference/introduction-to-the-qase-api) define the request fields, limits, and response shapes. Pass query parameters as `URLQueryItem` values to preserve repeated keys and bracket notation. Supply each path parameter named in the route (`code`, `id`, or `hash`).

## Operation catalog

| Resource | Method and path | Additional input | Success response |
| --- | --- | --- | --- |
| Attachments | `GET /attachment` | Query: limit, offset | `QaseAPIResponse<QaseAPIListResult<QaseAPIAttachmentDTO>>` |
| Attachments | `GET /attachment/{hash}` | Path: hash | `QaseAPIResponse<QaseAPIAttachmentDTO>` |
| Attachments | `DELETE /attachment/{hash}` | Path: hash | Qase result envelope |
| Attachments | `POST /attachment/{code}` | Multipart `file[]`; max 20 files, 32 MB each, 128 MB per request | Upload result envelope |
| Authors | `GET /author` | Query: search, type, limit, offset | `QaseAPIResponse<QaseAPIListResult<QaseAPIAuthorDTO>>` |
| Authors | `GET /author/{id}` | Path: id | `QaseAPIResponse<QaseAPIAuthorDTO>` |
| Cases | `GET /case/{code}` | Query: search, milestone_id, suite_id, severity, priority, type, behavior, automation, status, `external_issues[type]`, repeated `external_issues[ids][]`, include, limit, offset | `QaseAPIResponse<QaseAPIListResult<TestCaseEntity>>` |
| Cases | `POST /case/{code}` | `EncodableTestCase` JSON body | `QaseAPIResponse<QaseAPIIDResult>` |
| Cases | `GET /case/{code}/{id}` | Query: include | `QaseAPIResponse<TestCaseEntity>` |
| Cases | `PATCH /case/{code}/{id}` | `EncodableTestCase` JSON body | `QaseAPIResponse<QaseAPIIDResult>` |
| Cases | `DELETE /case/{code}/{id}` | — | `QaseAPIResponse<QaseAPIIDResult>` |
| Cases | `POST /case/{code}/bulk` | `QaseAPIBulkCasesRequest` JSON body | `QaseAPIResponse<QaseAPIIDsResult>` |
| Cases | `POST /case/{code}/external-issue/attach` | `QaseAPIExternalIssueRequest` JSON body (`type`, `links`) | Qase result envelope |
| Cases | `POST /case/{code}/external-issue/detach` | `QaseAPIExternalIssueRequest` JSON body (`type`, `links`) | Qase result envelope |
| Configurations | `GET /configuration/{code}` | Path: code | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Configurations | `POST /configuration/{code}` | `QaseAPIConfigurationRequest` JSON body | Qase result envelope |
| Configurations | `POST /configuration/{code}/group` | `QaseAPIConfigurationGroupRequest` JSON body | Qase result envelope |
| Custom fields | `GET /custom_field` | Query parameters per OpenAPI | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Custom fields | `POST /custom_field` | `QaseAPICustomFieldCreateRequest` JSON body | Qase result envelope |
| Custom fields | `GET /custom_field/{id}` | Path: id | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Custom fields | `PATCH /custom_field/{id}` | `QaseAPICustomFieldUpdateRequest` JSON body | Qase result envelope |
| Custom fields | `DELETE /custom_field/{id}` | Path: id | Qase result envelope |
| System fields | `GET /system_field` | Query parameters per OpenAPI | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Defects | `GET /defect/{code}` | Query: status, limit, offset | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Defects | `POST /defect/{code}` | `QaseAPIDefectCreateRequest` JSON body | `QaseAPIResponse<QaseAPIIDResult>` |
| Defects | `GET /defect/{code}/{id}` | Path: code, id | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Defects | `PATCH /defect/{code}/{id}` | `QaseAPIDefectUpdateRequest` JSON body | Qase result envelope |
| Defects | `DELETE /defect/{code}/{id}` | Path: code, id | Qase result envelope |
| Defects | `PATCH /defect/{code}/resolve/{id}` | Path: code, id | Qase result envelope |
| Defects | `PATCH /defect/{code}/status/{id}` | `QaseAPIDefectStatusRequest` JSON body | Qase result envelope |
| Environments | `GET /environment/{code}` | Query: limit, offset | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Environments | `POST /environment/{code}` | `QaseAPIEnvironmentCreateRequest` JSON body | `QaseAPIResponse<QaseAPIIDResult>` |
| Environments | `GET /environment/{code}/{id}` | Path: code, id | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Environments | `PATCH /environment/{code}/{id}` | `QaseAPIEnvironmentUpdateRequest` JSON body | Qase result envelope |
| Environments | `DELETE /environment/{code}/{id}` | Path: code, id | Qase result envelope |
| Milestones | `GET /milestone/{code}` | Query parameters per OpenAPI | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Milestones | `POST /milestone/{code}` | `QaseAPIMilestoneCreateRequest` JSON body | `QaseAPIResponse<QaseAPIIDResult>` |
| Milestones | `GET /milestone/{code}/{id}` | Path: code, id | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Milestones | `PATCH /milestone/{code}/{id}` | `QaseAPIMilestoneUpdateRequest` JSON body | Qase result envelope |
| Milestones | `DELETE /milestone/{code}/{id}` | Path: code, id | Qase result envelope |
| Plans | `GET /plan/{code}` | Query parameters per OpenAPI | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Plans | `POST /plan/{code}` | `QaseAPIPlanCreateRequest` JSON body | `QaseAPIResponse<QaseAPIIDResult>` |
| Plans | `GET /plan/{code}/{id}` | Path: code, id | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Plans | `PATCH /plan/{code}/{id}` | `QaseAPIPlanUpdateRequest` JSON body | Qase result envelope |
| Plans | `DELETE /plan/{code}/{id}` | Path: code, id | Qase result envelope |
| Projects | `GET /project` | Query: search, limit, offset | Existing `ProjectDataModel` or `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Projects | `POST /project` | `QaseAPIProjectCreateRequest` JSON body (title, code required; access may require group) | `QaseAPIResponse<QaseAPIProjectCodeResult>` |
| Projects | `GET /project/{code}` | Path: code | `QaseAPIResponse<Project>` |
| Projects | `DELETE /project/{code}` | Path: code | Qase result envelope |
| Projects | `POST /project/{code}/access` | `QaseAPIProjectAccessRequest` JSON body (`member_id`) | `QaseAPIResponse<QaseAPIEmptyResult>` |
| Projects | `DELETE /project/{code}/access` | Path: code; access identifiers per OpenAPI | Qase result envelope |
| Results | `GET /result/{code}` | Query: status, run, case_id, member, api, from_end_time, to_end_time, limit, offset | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Results | `POST /result/{code}/{id}` | `QaseAPIResultCreateRequest` JSON body (`status` required) | Result response envelope |
| Results | `POST /result/{code}/{id}/bulk` | `QaseAPIResultBulkRequest` JSON body | Bulk result envelope |
| Results | `GET /result/{code}/{hash}` | Path: code, hash | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Results | `PATCH /result/{code}/{id}/{hash}` | `QaseAPIResultUpdateRequest` JSON body | Result response envelope |
| Results | `DELETE /result/{code}/{id}/{hash}` | Path: code, id, hash | Qase result envelope |
| Reviews | `GET /review/{code}` | Query parameters per OpenAPI | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Reviews | `POST /review/{code}` | `QaseAPIReviewRequest` JSON body | Qase result envelope |
| Reviews | `GET /review/{code}/{id}` | Path: code, id | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Reviews | `PATCH /review/{code}/{id}` | `QaseAPIReviewRequest` JSON body | Qase result envelope |
| Reviews | `DELETE /review/{code}/{id}` | Path: code, id | Qase result envelope |
| Reviews | `POST /review/{code}/bulk` | `QaseAPIReviewBulkRequest` JSON body | Bulk result envelope |
| Runs | `GET /run/{code}` | Query: search, status, milestone, environment, from_start_time, to_start_time, limit, offset, include | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Runs | `POST /run/{code}` | `QaseAPIRunCreateRequest` JSON body (`title` required) | `QaseAPIResponse<QaseAPIIDResult>` |
| Runs | `GET /run/{code}/{id}` | Query: include | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Runs | `PATCH /run/{code}/{id}` | `QaseAPIRunUpdateRequest` JSON body | Qase result envelope |
| Runs | `DELETE /run/{code}/{id}` | Path: code, id | Qase result envelope |
| Runs | `POST /run/{code}/{id}/complete` | Path: code, id | Qase result envelope |
| Runs | `PATCH /run/{code}/{id}/public` | `QaseAPIRunPublicRequest` JSON body (`status` required) | Qase result envelope |
| Runs | `POST /run/{code}/external-issue` | `QaseAPIRunExternalIssueRequest` JSON body (`type`, `links`) | Qase result envelope |
| Search | `GET /search` | Query: query/QQL and entity-specific filters per OpenAPI | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Shared parameters | `GET /shared_parameter` | Query parameters per OpenAPI | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Shared parameters | `POST /shared_parameter` | `QaseAPISharedParameterCreateRequest` JSON body (title, type, is_enabled_for_all_projects, and parameters required) | Shared parameter response envelope |
| Shared parameters | `GET /shared_parameter/{id}` | Path: id | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Shared parameters | `PATCH /shared_parameter/{id}` | `QaseAPISharedParameterUpdateRequest` JSON body | Shared parameter response envelope |
| Shared parameters | `DELETE /shared_parameter/{id}` | Path: id | Qase result envelope |
| Shared steps | `GET /shared_step/{code}` | Query parameters per OpenAPI | `QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>` |
| Shared steps | `POST /shared_step/{code}` | `QaseAPISharedStepCreateRequest` JSON body (`title` required) | Shared step response envelope |
| Shared steps | `GET /shared_step/{code}/{hash}` | Path: code, hash | `QaseAPIResponse<QaseAPIResourceDTO>` |
| Shared steps | `PATCH /shared_step/{code}/{hash}` | `QaseAPISharedStepUpdateRequest` JSON body | Shared step response envelope |
| Shared steps | `DELETE /shared_step/{code}/{hash}` | Path: code, hash | Qase result envelope |
| Suites | `GET /suite/{code}` | Query: search, limit, offset, parent_id | Existing `SuitesDataModel` or generic list response |
| Suites | `POST /suite/{code}` | `QaseAPISuiteCreateRequest` JSON body (`title` required) | `QaseAPIResponse<QaseAPIIDResult>` |
| Suites | `GET /suite/{code}/{id}` | Path: code, id | `QaseAPIResponse<TestListEntity>` |
| Suites | `PATCH /suite/{code}/{id}` | `QaseAPISuiteUpdateRequest` JSON body | `QaseAPIResponse<QaseAPIIDResult>` |
| Suites | `DELETE /suite/{code}/{id}` | Path: code, id | Qase result envelope |
| Users | `GET /user` | Query: limit, offset | `QaseAPIResponse<QaseAPIListResult<QaseAPIUserDTO>>` |
| Users | `GET /user/{id}` | Path: id | `QaseAPIResponse<QaseAPIUserDTO>` |

## Using the catalog

The catalog contains 89 operations across 50 path templates. For example, list the runs in a project with `performRequest(for: .getRuns, pathParameters: ["code": projectCode], queryItems: [API.QueryParams.status.item("in_progress")], with: nil, modelType: QaseAPIResponse<QaseAPIListResult<QaseAPIResourceDTO>>.self)`.

- Request DTOs use the existing snake-case JSON encoder. `QaseAPIObjectRequest` and `QaseAPIJSONValue` cover operation-specific fields and nested values. Create and update DTOs are separate where their required fields differ.
- `QaseAPIResourceDTO` holds common response fields and preserves the remaining properties in `fields`. `QaseAPIIdentifier` accepts numeric and string IDs. Existing project, suite, and test-case screens continue to use their established models.
- Attachment uploads use the `file[]` field. The client checks Qase's limits of 20 files, 32 MB per file, and 128 MB per request, and escapes filenames in multipart headers.
- Non-2xx responses become `API.NetError.httpError`. A numeric `Retry-After` value is available to callers handling rate limits.
- Use an operation-specific response model when the generic resource DTO does not describe the response. Check the OpenAPI specification for field requirements and nested schemas.
