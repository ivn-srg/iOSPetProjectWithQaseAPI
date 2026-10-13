# Запросы генерации форм

Режим: встроенный imagegen. Варианты v1 требуют правок по REVIEW.md; слова final/approved в технических именах итераций не означают приёмку пользователем.

## Общий стиль

Use case: ui-mockup. Create a polished, HIGH RESOLUTION iOS form design sheet, native SF Pro/San Francisco typography and SF Symbols, flat full screenshots not phone hardware. Every full phone viewport has EXACT aspect402:874, same scale. Aim for large portrait sheet1536x2560 for4–6fullscreens with room for labeled small state-detail panels. Neutral gray outside board, full native statusbar time1:04, safearea, compact44pt navigationbar SINGLE centered title17pt, screen margins20pt, grouped card corners16pt, internal padding16pt, section gaps16–24pt. Inherited LIGHT and DARK themes, no theme switch UI.
DARK: canvas#000000, groupcard#1C1C1F, editing focus surface#2C2C2D, primary#F7F7F8,secondary#A5A7AE,border#34343A,purple#8577FF,red#FF6B6B,blue#5AA2FF. LIGHT: whitecanvas,groupcard#F4F5F7,focus#ECEEF2,primary#111113,secondary#6F7179,border#E6E7EB,purple#6757F5,red#D92D20,blue#0B5FCC.
Persistent small13pt field captions, regular17pt editable values, no huge bold labels, no heavy gray frames. Text areas grow naturally. Input fields are borderless rows in grouped cards with subtle dividers and permanent small captions ABOVE value/placeholder, purple outline only focused row. Dropdown/select rows are distinct: left17pt label,rightvalue13–15pt,smallgraychevron, minimumheight52pt. Section labels13–15pt. Title only required, label "Название *"; empty/whitespace title disablesprimaryaction, nofakevalidemptyfield. Maximum existing text fields500characters; no long sample beyond500. Same exact data/scroll positions in theme pairs. Exact readable Cyrillic; no watermark, code, personal data or new app features. References: app settings board only STYLE of its new after-light/dark screens; old form screenshot only starting design context, DON'T reproduce original columns or screenshot text in the new board.

## suite-create

Референсы: /Users/ivn_srg/Desktop/Screenshot iPhone 17 Pro 08. 10. 2026 at 01.04.27.png, /Users/ivn_srg/Desktop/iOSDev/iOSPetProjectWithQaseAPI/Design/Concepts/ScreenHeaders/settings-profile-v2.png

Use case: ui-mockup. Create a polished, HIGH RESOLUTION iOS form design sheet, native SF Pro/San Francisco typography and SF Symbols, flat full screenshots not phone hardware. Every full phone viewport has EXACT aspect402:874, same scale. Aim for large portrait sheet1536x2560 for4–6fullscreens with room for labeled small state-detail panels. Neutral gray outside board, full native statusbar time1:04, safearea, compact44pt navigationbar SINGLE centered title17pt, screen margins20pt, grouped card corners16pt, internal padding16pt, section gaps16–24pt. Inherited LIGHT and DARK themes, no theme switch UI.
DARK: canvas#000000, groupcard#1C1C1F, editing focus surface#2C2C2D, primary#F7F7F8,secondary#A5A7AE,border#34343A,purple#8577FF,red#FF6B6B,blue#5AA2FF. LIGHT: whitecanvas,groupcard#F4F5F7,focus#ECEEF2,primary#111113,secondary#6F7179,border#E6E7EB,purple#6757F5,red#D92D20,blue#0B5FCC.
Persistent small13pt field captions, regular17pt editable values, no huge bold labels, no heavy gray frames. Text areas grow naturally. Input fields are borderless rows in grouped cards with subtle dividers and permanent small captions ABOVE value/placeholder, purple outline only focused row. Dropdown/select rows are distinct: left17pt label,rightvalue13–15pt,smallgraychevron, minimumheight52pt. Section labels13–15pt. Title only required, label "Название *"; empty/whitespace title disablesprimaryaction, nofakevalidemptyfield. Maximum existing text fields500characters; no long sample beyond500. Same exact data/scroll positions in theme pairs. Exact readable Cyrillic; no watermark, code, personal data or new app features. References: app settings board only STYLE of its new after-light/dark screens; old form screenshot only starting design context, DON'T reproduce original columns or screenshot text in the new board.
Board outside title"Создание набора". TWO columns light LEFT dark RIGHT. TWO rows fullscreens: row1label"Пустая форма", row2label"Заполненная форма". All4phones same402:874ratio. BELOW fullscreens, two small labeled detail panels"Фокус и клавиатура" and"Закрытие с черновиками" (includeboth themes compactly).
Fullphone toolbar: Xcloseleft, single title"Создание"center, "Создать"right disabledgrayrow1 and enabledpurplerow2. Below just ONE segmentedcontrol "Набор" selected / "Кейс" notselected, height44pt with balanced native appearance. Small readonlyprojectcontext"Demo Project", noextra big header.
Allsuite fields ONLY: Maincardsection"Основные данные" contains caption"Название *" above placeholder"Например, Авторизация" row1, actualvalue"Авторизация"row2; insetdivider; caption"Описание" above placeholder"Что проверяет этот набор"row1, actual"Проверки входа и восстановления доступа."row2 multiline. Nextsection"Условия", one growing textfield caption"Предусловия", placeholder"Необязательно"row1, actual"Пользователь зарегистрирован."row2. Nextsection"Расположение", one selectorrow"Родительский набор", value"Корень проекта", chevron. NO postconditions, testproperties, steps, actual entity ID, fake checkboxes or extra textfields for suite. NOpagetabbar in creation screens. End before homeindicator. Emptyfield initial requiredhint gray"Название обязательно", no rederror beforeediting.
State panelfocuskeyboard: show cropped focused multiline Description withpurpleoutline, realistic Russian keyboard below, toolbarCreate reachable, no app tabs abovekeyboard. Stateclose: native alertoverform titled"Отменить изменения?" with readable message"Есть изменения в формах набора и кейса." and exactly2actions"Продолжить редактирование"(purple) and"Отменить изменения"(red). Do NOT offer creating both entities, autosave orSaveAll. State panels are crops clearly outside primary screens, not added controls.

## case-create

Референсы: /Users/ivn_srg/Desktop/iOSDev/iOSPetProjectWithQaseAPI/Design/Concepts/ScreenHeaders/settings-profile-v2.png, /Users/ivn_srg/Desktop/Screenshot iPhone 17 Pro 08. 10. 2026 at 01.04.27.png

Use case: ui-mockup. Create a polished, HIGH RESOLUTION iOS form design sheet, native SF Pro/San Francisco typography and SF Symbols, flat full screenshots not phone hardware. Every full phone viewport has EXACT aspect402:874, same scale. Aim for large portrait sheet1536x2560 for4–6fullscreens with room for labeled small state-detail panels. Neutral gray outside board, full native statusbar time1:04, safearea, compact44pt navigationbar SINGLE centered title17pt, screen margins20pt, grouped card corners16pt, internal padding16pt, section gaps16–24pt. Inherited LIGHT and DARK themes, no theme switch UI.
DARK: canvas#000000, groupcard#1C1C1F, editing focus surface#2C2C2D, primary#F7F7F8,secondary#A5A7AE,border#34343A,purple#8577FF,red#FF6B6B,blue#5AA2FF. LIGHT: whitecanvas,groupcard#F4F5F7,focus#ECEEF2,primary#111113,secondary#6F7179,border#E6E7EB,purple#6757F5,red#D92D20,blue#0B5FCC.
Persistent small13pt field captions, regular17pt editable values, no huge bold labels, no heavy gray frames. Text areas grow naturally. Input fields are borderless rows in grouped cards with subtle dividers and permanent small captions ABOVE value/placeholder, purple outline only focused row. Dropdown/select rows are distinct: left17pt label,rightvalue13–15pt,smallgraychevron, minimumheight52pt. Section labels13–15pt. Title only required, label "Название *"; empty/whitespace title disablesprimaryaction, nofakevalidemptyfield. Maximum existing text fields500characters; no long sample beyond500. Same exact data/scroll positions in theme pairs. Exact readable Cyrillic; no watermark, code, personal data or new app features. References: app settings board only STYLE of its new after-light/dark screens; old form screenshot only starting design context, DON'T reproduce original columns or screenshot text in the new board.
Board title"Создание кейса · единая форма". THREE columns fullscreens labeled"Основные поля","Классификация и тип","Автоматизация", TWO rows lighttop darkbottom. These are successive SCROLL SLICES of ONE form, NOT tabs or screen navigation. Eachfullscreen402:874. Matching data/scroll in light/dark.
Toolbar EVERY slice: Xcloseleft,"Создание"center,"Создать"purple right (filledvalidtitle). Below onefixed segmentedcontrol"Набор"/"Кейс" withКейсselected. NO furthersegmentedcontrols. Smallprojectcontext"Demo Project". NO bottomapp tabs.
COLUMN1:
section"Основные данные", fieldcaption"Название *", value"Авторизация с корректными данными"; fieldcaption"Описание", multilinevalue"Проверка входа с действующим логином и паролем.".
section"Условия", fieldcaption"Предусловия", value"Пользователь зарегистрирован."; fieldcaption"Постусловия",value"Пользователь вошёл в аккаунт.".
section"Расположение", selector"Родительский набор"right"Авторизация", chevron. All6fields shouldfit with naturalcompactspacing; samecolumn references futureparentpicker replacingmanualID. If no roomfor nextsection, contentcontinues below—not tinyfonts.
COLUMN2 fully readable groups:
"Классификация":3selectorrows "Серьёзность"right"Критичный"(redsmalldoubleuparrow optional), "Статус"right"Актуальный"(neutral), "Приоритет"right"Средний"(blue).
"Тип и уровень":3rows "Поведение"right"Деструктивный", "Тип"right"Регресс", "Слой"right"API"(smallblueAPIiconoptional).
Eachrowmin52pt, labels17pt normal not giantboldtitle; dropdownchevrons, insetdividers.
COLUMN3 section"Автоматизация": selector"Статус автоматизации"right"Ручной", then"Нестабильный тест"offnative switch. Readable gray supportingtext"Тест иногда проходит и падает без изменения условий." No steps section, no stepsbuttons, attachments, tags, additional params orlarge empty placeholders.
Below6fullscreens add SMALL clearly labeled state detail panels in boththemes: "Название обязательно" shows empty orwhitespace input withgray disabledСоздать; "Сохранение" shows disabledСоздать + smallspinner labeled"Создание…"; "Ошибка" shows neutral/red banner"Не удалось создать кейс. Повторите попытку." retaining enteredtitleandform. No pretendresultsuccess.

## case-edit

Референсы: /Users/ivn_srg/Desktop/Screenshot iPhone 17 Pro 08. 10. 2026 at 01.04.16.png, /Users/ivn_srg/Desktop/Screenshot iPhone 17 Pro 08. 10. 2026 at 01.04.21.png, /Users/ivn_srg/Desktop/iOSDev/iOSPetProjectWithQaseAPI/Design/Concepts/ScreenHeaders/settings-profile-v2.png

Use case: ui-mockup. Create a polished, HIGH RESOLUTION iOS form design sheet, native SF Pro/San Francisco typography and SF Symbols, flat full screenshots not phone hardware. Every full phone viewport has EXACT aspect402:874, same scale. Aim for large portrait sheet1536x2560 for4–6fullscreens with room for labeled small state-detail panels. Neutral gray outside board, full native statusbar time1:04, safearea, compact44pt navigationbar SINGLE centered title17pt, screen margins20pt, grouped card corners16pt, internal padding16pt, section gaps16–24pt. Inherited LIGHT and DARK themes, no theme switch UI.
DARK: canvas#000000, groupcard#1C1C1F, editing focus surface#2C2C2D, primary#F7F7F8,secondary#A5A7AE,border#34343A,purple#8577FF,red#FF6B6B,blue#5AA2FF. LIGHT: whitecanvas,groupcard#F4F5F7,focus#ECEEF2,primary#111113,secondary#6F7179,border#E6E7EB,purple#6757F5,red#D92D20,blue#0B5FCC.
Persistent small13pt field captions, regular17pt editable values, no huge bold labels, no heavy gray frames. Text areas grow naturally. Input fields are borderless rows in grouped cards with subtle dividers and permanent small captions ABOVE value/placeholder, purple outline only focused row. Dropdown/select rows are distinct: left17pt label,rightvalue13–15pt,smallgraychevron, minimumheight52pt. Section labels13–15pt. Title only required, label "Название *"; empty/whitespace title disablesprimaryaction, nofakevalidemptyfield. Maximum existing text fields500characters; no long sample beyond500. Same exact data/scroll positions in theme pairs. Exact readable Cyrillic; no watermark, code, personal data or new app features. References: app settings board only STYLE of its new after-light/dark screens; old form screenshot only starting design context, DON'T reproduce original columns or screenshot text in the new board.
Board title"Редактор кейса · единая форма". THREE columns matching fullscreen SCROLL SLICES labeled"Основные поля","Параметры","Шаги"; TWO rows LIGHTtop DARKbottom. All6viewports402:874ratio. This is ONE scrollingeditor, NOT segmented screens: DO NOT draw General/Properties controls, tabs, thin blackslider orswitchbar undernavbar.
Everyphone native Backleft, single centered"DEMO-11", purple"Сохранить"right (changeddraft). Smallreadonlycontext"Demo Project · Авторизация". Bottomnativefloating appbar4tabs"Главная","Репозиторий","Работа","Настройки" withРепозиторийselectedpurple, safelybelowcontent. No extra parentselector ormove-caseaction.
COLUMN1 sectionsMain+Conditions:
"Основные данные":caption"Название *"and value"Авторизация с корректными данными"; caption"Описание"and multiline"Проверка входа с действующим логином и паролем.".
"Условия":caption"Предусловия", "Пользователь зарегистрирован."; caption"Постусловия","Пользователь вошёл в аккаунт.".
Subtle13ptstatus"Есть несохранённые изменения". No massive borderedtextboxes; readablecompact cards.
COLUMN2 ALL8properties visible in3groups, no unshownproperty:
"Классификация": "Серьёзность"→"Критичный"(smallredicon), "Статус"→"Актуальный", "Приоритет"→"Средний"(blue).
"Тип и уровень": "Поведение"→"Деструктивный", "Тип"→"Регресс", "Слой"→"API".
"Автоматизация": "Статус автоматизации"→"Ручной"; "Нестабильный тест"OFFswitch.
Nochangeactualmeaning egActualnotPassed. No parentfield.
COLUMN3 read-only"Шаги": numberedcards withexact captions"Действие"and"Ожидаемый результат":
1action"Открыть экран входа", expected"Отображается форма авторизации".
2actionMULTILINE"Введите действующий логин и пароль, затем нажмите «Войти».", expected"Открывается главная страница.".
3action"Закрыть приложение", expectedgray"Ожидаемый результат не задан".
Keep textsreadable, cardheightgrows. NO add/edit/delete/reorder/pencil/grips on steps. Viewonlycards.
Below6screens smallstatepanelsboth themes: "Нет шагов": quietcard"Шагов пока нет", NOCTA; "Без изменений": navbarSavegraydisabled, not extra button; "Ошибка сохранения": banner"Не удалось сохранить изменения. Повторите попытку." with existingenteredfieldsretained. Don't draw fake autosave.

## suite-create-v2

Референсы: /Users/ivn_srg/.codex/generated_images/01a11580-8501-7a82-aa30-7e9db1afd8b5/exec-cd6e1682-7086-4a09-b035-5070cccd05ea.png

Edit this existing design sheet, preserving exact Russian text, palette, typography, all4mainforms and bottomkeyboard/unsaved-alertstatepanels. Fix the PHONE VIEWPORT GEOMETRY only.
Output must be a VERY TALL portrait sheet, around1024pxwide by2560pxhigh (aspect0.4), NOT1024x1536. The4MAIN screenshots are2columns x2rows, each viewport approximately402pxwide by874pxtall, EXACT phoneaspect402:874. Keep title/nav/form text at native13/17pt scale relative to width402; do not shrink fonts or squash screenshots. Extend EMPTY SPACE BELOW each form until its true screenbottom, and add native homeindicator atbottom, rather than ending the screen at the last field. Suggested firstscreen row y100–974, secondscreen row y1030–1904,2columns x80 andx542. Move existing state-detail panels tofooter y2000–2490. Main forms no app tabbar.
Toprowempty,title/star/hint and disabledСоздать unchanged. Bottomrowfilled values unchanged; enabledСоздать. Keep exactlysuitefields Name/Description/Preconditions/Parent, noextra fields. Keep native one type segment Наборselected. Footer four SMALL state-detail crops preserve bothlight/dark keyboards + close-confirmalertexactactions"Продолжить редактирование","Отменить изменения", messagementionsbothdrafts. Alltext must stay legible. Long tallpaper outsidegray, no hardware, watermark or newcontrols.

## case-create-v2

Референсы: /Users/ivn_srg/.codex/generated_images/01a11580-8501-7a82-aa30-7e9db1afd8b5/exec-15eb8f17-a024-4732-8bc7-bdcb6d5d7e8c.png

Edit existing case-creation design sheet only to correct FULL PHONE aspect and improve layout-space. Preserve allRussianwords, data, groups, palette, typography and bottomstatepanels. Need VERY TALL portraitboard around1536x2560px, not1024x1536.
SIX MAIN fullscreens3columns x2rows eachapproximately440pxwide by956pxtall (EXACT402:874phoneaspect). Allmatchingscale. Columnlabels"Основные поля","Классификация и тип","Автоматизация"; topLIGHTrow bottomDARKrow. Native compactСоздание/X/Создать plus ONE Набор/КейсsegmentКейсselected. Add ordinaryemptyspacebelowcontent andhomeindicators; DO NOT endphoneatlastfield. NO app tabs orsteps.
Do not change fields orproperties meanings. Keep namedata and conditions/suite choice. BothLIGHTandDARK "Приоритет"blue label value"Средний", neverreplacewithnumberrating. "Нестабильный тест" OFF inBOTHthemes: thumbLEFT ongraytrack. No compressionoftextfonts below17ptvalues/13ptcaptions.
Mainfullscreensfinishabovefooter; below show6SMALL crops3columns x2themes, labels"Название обязательно","Сохранение","Ошибка". Emptyname disablesСоздать, saving disablesСоздать +spinner, errorbanner"Не удалось создать кейс. Повторите попытку." AND retainedtypedtitle "Авторизация с корректными данными" visiblebeneath. Cropdetailsneednotfullphoneaspect but mustbe clearlylabeled as states. AllCyrillic complete, no overlaps.

## case-edit-v2

Референсы: /Users/ivn_srg/.codex/generated_images/01a11580-8501-7a82-aa30-7e9db1afd8b5/exec-cdb287ad-8f90-45f5-9bd6-76b97b9dcbf2.png

Edit existing unified case-editor design sheet preserving exact data, labels, palette,6screens, groups, readonlysteps, tabbars. Make a TALL portraitboardaround1536x2560px. SIX MAIN viewports3columns x2rows, each440x956px (EXACT402:874phoneaspect), topLIGHT bottomDARK, samepositionsscroll/data perpair. NativeDEMO-11/Back/Сохранить, NO General/Propertiessegment and NO parentselector. Keep bottom4app tabs eachfullphone, selectedРепозиторий, allcontentabovethem. Addneededemptyspacebelowcardsratherthanwideningorsquashingviewports.
Column1 main/conditions; column2 ALL8existingproperties; column3 ALL3readonlystepcards EXACTexistingaction/expectedtexts including"Ожидаемый результат не задан." No edit/add/reorderbuttons. "Нестабильный тест" OFF both: thumbLEFT graytrack.
Replacecurrent3one-themefooterstates with SIX crops in3columns x2rows, lightupper darklower. Eachstate inBOTHthemes:
"Нет шагов": quiet "Шагов пока нет", noCTA.
"Без изменений": Сохранитьgraydisabled, no extraactions.
"Ошибка сохранения": safe redbanner"Не удалось сохранить изменения. Повторите попытку." plus retainedfield "Авторизация с корректными данными" clearly visible. These are SMALL labeled state-detail panels, notextra entirephones. Keep maintexts17pt/captions13pt legible, enlargeoutput notshrinktype, neveroverlapappbar.

## suite-edit

Референсы: /Users/ivn_srg/.codex/generated_images/01a11580-8501-7a82-aa30-7e9db1afd8b5/exec-cd6e1682-7086-4a09-b035-5070cccd05ea.png

Use case: ui-mockup. Create a polished, HIGH RESOLUTION iOS form design sheet, native SF Pro/San Francisco typography and SF Symbols, flat full screenshots not phone hardware. Every full phone viewport has EXACT aspect402:874, same scale. Aim for large portrait sheet1536x2560 for4–6fullscreens with room for labeled small state-detail panels. Neutral gray outside board, full native statusbar time1:04, safearea, compact44pt navigationbar SINGLE centered title17pt, screen margins20pt, grouped card corners16pt, internal padding16pt, section gaps16–24pt. Inherited LIGHT and DARK themes, no theme switch UI.
DARK: canvas#000000, groupcard#1C1C1F, editing focus surface#2C2C2D, primary#F7F7F8,secondary#A5A7AE,border#34343A,purple#8577FF,red#FF6B6B,blue#5AA2FF. LIGHT: whitecanvas,groupcard#F4F5F7,focus#ECEEF2,primary#111113,secondary#6F7179,border#E6E7EB,purple#6757F5,red#D92D20,blue#0B5FCC.
Persistent small13pt field captions, regular17pt editable values, no huge bold labels, no heavy gray frames. Text areas grow naturally. Input fields are borderless rows in grouped cards with subtle dividers and permanent small captions ABOVE value/placeholder, purple outline only focused row. Dropdown/select rows are distinct: left17pt label,rightvalue13–15pt,smallgraychevron, minimumheight52pt. Section labels13–15pt. Title only required, label "Название *"; empty/whitespace title disablesprimaryaction, nofakevalidemptyfield. Maximum existing text fields500characters; no long sample beyond500. Same exact data/scroll positions in theme pairs. Exact readable Cyrillic; no watermark, code, personal data or new app features. References: app settings board only STYLE of its new after-light/dark screens; old form screenshot only starting design context, DON'T reproduce original columns or screenshot text in the new board.
NEW design sheet for FUTURE suite editor, not an existing screenshot. Topoutsideheader exact"Редактор набора · концепт будущего экрана".
Twoequal fullscreens lightLEFT darkRIGHT withtrue402:874ratio, tall portraitsheetaround1024x1536, eachfullscreen420x913pixels. Bothnative Backleft, singlecentered"DEMO-S1", purple"Сохранить"right. NO creationtype switch orGeneral/Propertiescontrols. Smallreadonlyprojectcontext"Demo Project".
Samegroupedforms:
"Основные данные": caption"Название *"value"Авторизация"; caption"Описание"value"Проверки входа и восстановления доступа." multiline.
"Условия": caption"Предусловия"value"Пользователь зарегистрирован.".
"Расположение": selectorrow"Родительский набор", rightvalue"Корень проекта", chevron. This opens futureparentpicker. No postconditions, caseproperties, steps, APIbuttons orparentIDinput.
Graycaption"Есть несохранённые изменения". Mainbottomnativefloating4tabs"Главная","Репозиторий","Работа","Настройки", Репозиторийselectedpurple, neveroverlapform.
BelowtwoMAINscreens compactstatecrops inBOTHthemes: "Без изменений" withСохранитьdisabled; "Ошибка сохранения" withbanner"Не удалось сохранить набор. Повторите попытку." and unchangednameАвторизация visible. Labelconcept ONLYoutsidephone, no implementationwarninginsideproduct. Emptyspaceokay; screenheightnotcroppedatthelastfield.

## parent-picker

Референсы: /Users/ivn_srg/.codex/generated_images/01a11580-8501-7a82-aa30-7e9db1afd8b5/exec-cd6e1682-7086-4a09-b035-5070cccd05ea.png

Use case: ui-mockup. Create a polished, HIGH RESOLUTION iOS form design sheet, native SF Pro/San Francisco typography and SF Symbols, flat full screenshots not phone hardware. Every full phone viewport has EXACT aspect402:874, same scale. Aim for large portrait sheet1536x2560 for4–6fullscreens with room for labeled small state-detail panels. Neutral gray outside board, full native statusbar time1:04, safearea, compact44pt navigationbar SINGLE centered title17pt, screen margins20pt, grouped card corners16pt, internal padding16pt, section gaps16–24pt. Inherited LIGHT and DARK themes, no theme switch UI.
DARK: canvas#000000, groupcard#1C1C1F, editing focus surface#2C2C2D, primary#F7F7F8,secondary#A5A7AE,border#34343A,purple#8577FF,red#FF6B6B,blue#5AA2FF. LIGHT: whitecanvas,groupcard#F4F5F7,focus#ECEEF2,primary#111113,secondary#6F7179,border#E6E7EB,purple#6757F5,red#D92D20,blue#0B5FCC.
Persistent small13pt field captions, regular17pt editable values, no huge bold labels, no heavy gray frames. Text areas grow naturally. Input fields are borderless rows in grouped cards with subtle dividers and permanent small captions ABOVE value/placeholder, purple outline only focused row. Dropdown/select rows are distinct: left17pt label,rightvalue13–15pt,smallgraychevron, minimumheight52pt. Section labels13–15pt. Title only required, label "Название *"; empty/whitespace title disablesprimaryaction, nofakevalidemptyfield. Maximum existing text fields500characters; no long sample beyond500. Same exact data/scroll positions in theme pairs. Exact readable Cyrillic; no watermark, code, personal data or new app features. References: app settings board only STYLE of its new after-light/dark screens; old form screenshot only starting design context, DON'T reproduce original columns or screenshot text in the new board.
NEW sheet outside title"Выбор родительского набора · будущий интерфейс". TwoMAINfullscreens lightLEFT darkRIGHT, tallportraitboard around1024x2048. Eachfullphone402:874ratio around420x913pixels; mainrowfirst, mini-statesbelow. SameUI/datainboththemes, no appbar because fullheightmodal.
Singlecompactnavbar Xcloseleft, centeredtitle"Родительский набор", NO Done/Save/secondtitle. Underreadonly"Demo Project"13pt,44ptsearchfield"Поиск наборов". PINNEDrootoptionrow"Корень проекта" withfolderoutline min52pt beforeotherresults; NOTselectedinthisexample.
Groupedrows title17pt/fullpath13pt/neutralfoldericon/checkmark:
"Авторизация" / "Demo Project › Авторизация", selectedpurplecheckmark.
"Smoke" / "Demo Project › Авторизация › Smoke", notselected.
"Smoke" / "Demo Project › Платежи › Smoke", notselected.
"Регрессия мобильного приложения" (wrap ifneeded) / "Demo Project › Мобильное приложение › Авторизация › Регрессия", fullpathwrapsovermultiplelines, noellipsis/clipping. Exactlyonecheckmark. Paths distinguishduplicatenames. Alloptionssameproject; no contextdropdown forotherprojects.
Underfullscreens small outsidecaption "Тап выбирает и закрывает. Закрытие сохраняет прежний выбор." Notanappcontrol. No currentmoving-suite/destinationinvalidoptions inthiscreationexample.
BelowMAINscreens show3SMALL statecolumns withLIGHTandDARKcrops stacked:
"Загрузка": pinnedroot+quiet3rowskeletons+label"Загрузка наборов…".
"Ошибка": pinnedroot+message"Не удалось загрузить наборы."+button"Повторить".
"Нет результатов": searchquery"Неизвестный набор", pinnedrootstillvisible, gray"Наборы не найдены", clearsearchX.
Do not invent networkstats, counts, topactionCreate, longpress/editortrash. Futureeditingflowexcludesself/descendants but expressONLY smalloutsidefooter"При перемещении набора он сам и его потомки исключаются.", notastoggleinsideUI. Fullpaths,textsreadable,nodataoverlappingbottomhomeindicator.

## case-edit-final

Референсы: /Users/ivn_srg/.codex/generated_images/01a11580-8501-7a82-aa30-7e9db1afd8b5/exec-feb02bfa-5a73-452b-9604-353b0d315b9d.png

Precise correction of this existing design sheet. Preserve all6mainphonepositions, allgroups, all other data and colors. Keep whole sheet highresolution and no critical text cutoff. Change ONLY these issues:
1. BOTTOM DARK MAIN PHONE, THIRD COLUMN "Шаги", must show EXACTLY THREE readonlycards matching the light phone above, same sequence:
Card1 badge"1", Действие "Открыть экран входа", Ожидаемый результат "Отображается форма авторизации."
Card2 badge"2", Действие "Введите действующий логин и пароль, затем нажмите «Войти».", Ожидаемый результат "Открывается главная страница."
Card3 badge"3", Действие "Закрыть приложение", Ожидаемый результат gray "Ожидаемый результат не задан."
All3cards must fit above darkphone's tabbar. Use same17ptbody/13ptcaptions and natural multiline heights as lightcolumn; reduce irrelevant spacing, NEVER omitcard3, numbercard2as3, oraddstepactions.
2. Enlarge the FOOTER gallery/canvas downward so BOTHtheme rows of3statepanels are entirely visible. States "Нет шагов", "Без изменений", "Ошибка сохранения", with LIGHTrowandDARKrow. Error crop in eachtheme includes SAME retained full title "Авторизация с корректными данными" below errorbanner. No text or bottompanel cut off by imageedge. This footer is a labeleddetailgallery, not mainphonestates.
Do not change savedata, mainnames, properties, selectorvalues, disabledSave/activeSave semantics, bottom4tabicons or any othercontent.

## suite-edit-final

Референсы: /Users/ivn_srg/.codex/generated_images/01a11580-8501-7a82-aa30-7e9db1afd8b5/exec-c7c04381-6be3-436a-92bf-10470f63eced.png

Correct only two issues in this existing future-suite-editor sheet; retain allforms, words, colors, viewportpositions, IDDEMO-S1, readonlycontext and conceptcaption.
1. In EVERY fullphone and mini-statephone restore CURRENT APP bottom floating capsule tabbar, SAME as earlier appmockups: exactly4items "Главная","Репозиторий","Работа","Настройки". Icons: nativehouse, internaldrive/server-drive symbol forRepository (NOTdatabasecylinder), play-circle-outline forWork (NOTbriefcase), gearshape forSettings. ActiveRepository has purpleicon+text on calmselectedcapsule. Barfloats with roundedcapsulecorners and paddingabovehomeindicator. No flatrectangulartabbar ornewicons.
2. In BOTH mini-panels titled"Без изменений (кнопка сохранения неактивна)" change footer status "Есть несохранённые изменения" to "Все изменения сохранены" (oromitstatus entirely). Keep SaveGRAYDISABLED inthose2panels. Mainfullforms stillunsaved/enabledSave; errorpanels retainunsaved/enabledSave andtypedАвторизация.
NO otherchanges. Keep accurateCyrillicand readabletype.

## case-create-final

Референсы: /Users/ivn_srg/.codex/generated_images/01a11580-8501-7a82-aa30-7e9db1afd8b5/exec-90a23dfe-15d2-4ba0-b31c-6b4f97878ef4.png

Preserve this unified case-creation sheet's SIX MAIN phones and allfields, property values, colors and creationnavbar/type segment. Do NOT change mainphonelayout, sampledata or addsteps/tabs.
Only expand the canvas/footer downward to include BOTHthemes of the three state-detail panels. Current footer showsLIGHTstates only. Finalfooterhas3columns "Название обязательно","Сохранение","Ошибка", with LIGHTrowthenDARKrow directlybelow. Makeeachpanelatleast200pxtall at currentimagewidth, andleaveoutermargin so no text clipped. Use a VERY TALL image ifneeded; don'tshrinktype.
State1both: emptyrequiredНазвание*, disabledgrayСоздать, helper"Название обязательно."
State2both: retain "Авторизация с корректными данными", Создатьdisabled+smallspinner/label"Создание…", no repeatedtap affordance.
State3both: redbanner"Не удалось создать кейс. Повторите попытку.", retain fullname "Авторизация с корректными данными" clearlyinsidepanel, Создатьavailableforretry. No successflag or fieldreset.
Statepanelscrops labeled as such; no app bottomtabs. Preserve exactsamecontentthemes. No changes to main6screens.

## parent-picker-final

Референсы: /Users/ivn_srg/.codex/generated_images/01a11580-8501-7a82-aa30-7e9db1afd8b5/exec-4f165450-d7fe-4757-aae0-95d1cff2f8d7.png

Make ONE precise palette correction in this existing parent-suite-picker sheet. Preserve ALL screenlocations,texts,paths,selections,checkboxes,folders,search,rootoption,loading/empty/detailstates and conceptfooter.
In BOTH error-state mini-panels under"Ошибка", recolor the "Повторить" button from brightblue to appPURPLE: lightbutton#6757F5 withwhite text, darkbutton#8577FF withhighcontrasttext. Match main app purpleaccent and do not introducebluetint. Keep restunchanged. No newactions, no reflow, no textchanges.

## case-edit-approved

Референсы: /Users/ivn_srg/.codex/generated_images/01a11580-8501-7a82-aa30-7e9db1afd8b5/exec-225c614c-e933-405c-862e-c9872bc10eee.png

Use case: ui-mockup. Edit target: supplied case editor sheet. Preserve all text and data, SIX MAIN PHONE VIEWS and SIX small state examples, current exact field order, light/dark palette. Primary change: re-layout this sheet so NOTHING is cropped. Use a taller 1024x2048 artboard with margin 48 all sides, or make the six main phones narrower to allow a full footer gallery within the image. Mainphones keep proportions 402:874 and pairs same scale. Title "Редактор кейса · единая форма", 3 columns "Основные поля","Параметры","Шаги"; LIGHT row, DARK row. Footer must contain SIX fully visible header/content crops with ample whitespace beneath them: light/dark pairs for "Нет шагов", "Без изменений", "Ошибка сохранения". No clipped dark footer row, no letter cropped by image edge. Keep all content exactly as input. Dark Steps still has1 "Открыть экран входа" expected "Отображается форма авторизации.",2 "Введите действующий логин и пароль, затем нажмите «Войти»." expected "Открывается главная страница.",3 "Закрыть приложение" expected "Ожидаемый результат не задан.". Allthree visibleabovefloatingtabs. Mainfieldtitles and conditions same. All8 parameters same. No General/Properties tabs or parentselector. Keep ONLY four bottomnavitems house/drive/play-circle/gear. Light purple accent #6757F5 notblue, dark #8577FF. Footercrops are labeled details, no need include wholephone or fullbottomtabs inthose; fullydraw headers and field/error/emptycontent without clipping. Error examples preserve entered "Авторизация с корректными данными". Без изменений gray Save; Нет шагов "Шагов пока нет" noCTA. Final board all footer content has safe margin.

## suite-edit-approved

Референсы: /Users/ivn_srg/.codex/generated_images/01a11580-8501-7a82-aa30-7e9db1afd8b5/exec-dd0603b4-97af-4586-aed7-d9f92bf8392b.png

Use case: ui-mockup. Edit target: supplied future suite editor concept. Change ONLY the Repository icon in all six tabbars. Keep entire design sheet otherwise pixel-identical: headings, text, fieldvalues, layout, mainforms, minis, Save statuses, themes, floatingcapsules, purple highlights. Repository icon is NOT a vertical server stack. Replace with SF Symbol internaldrive.fill style: a WIDE SHORT HORIZONTAL hard drive, trapezoid rounded sloping top cover and short horizontal front face with tiny slots. Width about twiceheight. It must visually match the repository device symbol from the app, not a databasecylinder, verticalstack, folder, papers, serverrack. Icons other threeitems unchanged house, play-circle,gear. Labels and4tabs unchanged. All6Repository icons horizontaldrive purple. Keep "Редактор набора · концепт будущего экрана" caption and all data/positions unchanged.
