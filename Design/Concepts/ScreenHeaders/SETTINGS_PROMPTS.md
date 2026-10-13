# Дополнительные макеты полноценных настроек

Использован встроенный imagegen. Итоговые изображения: settings-profile-v2.png, settings-theme-token.png и settings-cache-about.png. Значения на листах — демонстрационные; приложение получает режим из авторизации, версию и сборку из Bundle.

## settings-profile-v2

```text
Use case: ui-mockup. Polish actual iOS17+ test management app, native San Francisco type, crisp accurate Russian text. Exact full phone viewport aspect402:874, equal scales, complete statusbar12:52, safearea and native four-item floating capsule tabbar at bottom, labels "Главная", "Репозиторий", "Работа", "Настройки", gear Settings selected in purple. Dark palette canvas#000000,card#1C1C1F,tile#2C2C2D,text#F7F7F8,secondary#A5A7AE,purple#8577FF; light canvas#FFFFFF,card#F4F5F7,tile#ECEEF2,text#111113,secondary#6F7179,purple#6757F5. Screen margins20pt,card corners16pt,leading icons modest20pt inside calm tiles, rowheight52pt minimum,body17pt,secondary13pt. No device frames,perspective,watermarks,code,imaginary personal identity or notification functions. Neutral outside comparison board. Same content in both themes. Match existing AFTER screens from style reference.
Create one3column readable comparison: original supplied Settings screenshot faithfully on LEFT under outside label"До"; redesigned DARK middle label"После · тёмная"; redesigned LIGHT right label"После · светлая". Wide board; all3complete viewports equal402:874aspect and size.
NEW Settings screens have ONLY ONE large left34pt bold title"Настройки", near native top safearea. Below compact account card with person-circle avatar44pt on soft purple background, title17pt"Аккаунт Qase", gray subtitle"Демо-режим", no chevron/no fake name/email/photo.
Then grouped sections, compact yet readable, normal17pt titles, muted13pt values:
Section"Оформление", one card2rows: half-circle icon "Тема" right value"Как в системе" and smallchevron; globeicon"Язык" right"Русский"chevron.
Small gray footer under this group exact"Язык меняется в настройках iOS".
Section"Подключение и данные", card2rows: keyicon"API-токен", right masked"••••••••"chevron; storageicon"Управление кешем", smallchevron.
Section"Приложение", card1row: infoicon"О приложении", right value"1.0"chevron.
Separate neutral card with red exiticon and red text"Выйти из аккаунта", NO chevron, NO purple border.
Use inside dividers, calm thin section labels, gaps16–20pt, account card around64pt. Main content should fit above selected Settings bottom tabbar (first title around104pt; last logoutcard ending before770pt). No huge avatar/hero, no toggle switches, no profile heading duplicate. Balanced attractive grouped native settings, not a sparse singlebutton screen.
```

## settings-theme-token

```text
Use case: ui-mockup. Polish actual iOS17+ test management app, native San Francisco type, crisp accurate Russian text. Exact full phone viewport aspect402:874, equal scales, complete statusbar12:52, safearea and native four-item floating capsule tabbar at bottom, labels "Главная", "Репозиторий", "Работа", "Настройки", gear Settings selected in purple. Dark palette canvas#000000,card#1C1C1F,tile#2C2C2D,text#F7F7F8,secondary#A5A7AE,purple#8577FF; light canvas#FFFFFF,card#F4F5F7,tile#ECEEF2,text#111113,secondary#6F7179,purple#6757F5. Screen margins20pt,card corners16pt,leading icons modest20pt inside calm tiles, rowheight52pt minimum,body17pt,secondary13pt. No device frames,perspective,watermarks,code,imaginary personal identity or notification functions. Neutral outside comparison board. Same content in both themes. Match existing AFTER screens from style reference.
Create a portrait tall4screen sheet in2columns x2rows. Every phone viewport402:874ratio, LEFT light RIGHT dark. Row1outside label"Выбор темы"; row2label"Замена API-токена". Small columnlabels"Светлая тема","Тёмная тема".
TOP theme screens: native backchevron and single INLINE centered title"Тема". Grouped card3rows near top below navigation:"Как в системе" checked purple; "Светлая"; "Тёмная". Small symbols halfcircle,sun,moon. Standard native selection list, no extra Save button because applies immediately. Gray footer"Настройка применяется ко всему приложению." Remaining background empty; Settings tabselected.
BOTTOM token screens: native modal navbar Cancel"Отмена"left, centered single title"API-токен", "Сохранить"right purple. No large duplicate. Intro smalltext"Новый токен проверяется перед заменой текущего.". One neutral rounded input group with keyicon and SECURE input placeholder exact"Введите новый API-токен", no visible secret, no prefilled realtoken. Below smalltext"При ошибке текущая авторизация сохранится.". Screen state is idle not error not spinner, Save dimmed because empty. NO invented existingtoken/username. Modal can show Settings bottomtabbar as reference context only if native presentation leaves it visible; better full-screen token form WITHOUT bottom tabs and with safe homeindicator, keep boththemes same. Do not draw keyboard. Text legible, generous calm layout.
```

## settings-cache-about

```text
Use case: ui-mockup. Polish actual iOS17+ test management app, native San Francisco type, crisp accurate Russian text. Exact full phone viewport aspect402:874, equal scales, complete statusbar12:52, safearea and native four-item floating capsule tabbar at bottom, labels "Главная", "Репозиторий", "Работа", "Настройки", gear Settings selected in purple. Dark palette canvas#000000,card#1C1C1F,tile#2C2C2D,text#F7F7F8,secondary#A5A7AE,purple#8577FF; light canvas#FFFFFF,card#F4F5F7,tile#ECEEF2,text#111113,secondary#6F7179,purple#6757F5. Screen margins20pt,card corners16pt,leading icons modest20pt inside calm tiles, rowheight52pt minimum,body17pt,secondary13pt. No device frames,perspective,watermarks,code,imaginary personal identity or notification functions. Neutral outside comparison board. Same content in both themes. Match existing AFTER screens from style reference.
Create a portrait tall4screen sheet2columns x2rows. Each fullphone402:874ratio. LEFT light RIGHT dark. Row1outside label"Управление кешем"; row2"О приложении". Smalltheme columnlabels.
TOP cache screens: native backchevron, single INLINE title"Управление кешем". Below grouped info card header"Сохранённые данные", value"Есть данные"; small readable description"Локальные копии проектов, наборов, кейсов и сводок.". Separate normal-width neutral card/action row redtrashicon and redtext"Очистить кеш". Below gray footer EXACT"Авторизация, выбранный проект и история просмотров сохранятся.". Do not invent cache size in megabytes, progress, toggles, or clear-history action. Confirmation is triggered on tap but not shown in this idle screen. Settings bottomtabbar selected.
BOTTOM about screens: native backchevron, single INLINE title"О приложении". Small compact appicon/person-document or neutral existing Qase-stylepurpleicon; appname"QaseAPIProj"17pt semibold. Grouped information card2rows "Версия"right"1.0", "Сборка"right"1". Gray supportingtext"Клиент для управления тестированием в Qase.". No invented developer identity,email,links,ratings,legal sections,notifications. Settings bottomtabbar selected. Emptyspace allowed. Keep section hierarchy and text accurate in boththemes.
```

