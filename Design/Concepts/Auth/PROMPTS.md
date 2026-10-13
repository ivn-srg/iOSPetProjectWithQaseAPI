# Запросы генерации

## Лист состояний — правка v2

Edit target: `auth-interaction-states-v1.png`. Встроенный imagegen, `transparent_background: false`. Результат сохранён отдельным v2; пиксели вручную не редактировались.

```text
Use case: precise-object-edit. Edit the attached Qase iOS auth design board. Make ONLY this change in ALL FOUR phone screens: REMOVE the two-line caption underneath "Попробовать демо" that says "Без API-токена, на демонстрационных данных". Erase that text completely and fill the area with the matching native white or black screen background. Keep the demo button itself and all other text, logo, input fields, eye icons, button gradients, loading spinner, errors, status bars, home indicators, keyboard if present, external captions and the 2x2 grid unchanged. No replacement footer, no explanation or new text underneath buttons. Keep Russian copy perfectly legible. Retain the original screen geometry; the freed space below the last button simply belongs to the screen background. Do not move or redraw other components. Return the complete full-resolution board.
```

## Основной лист — правка v2

Edit target: `auth-light-dark-v1.png`. Встроенный imagegen, `transparent_background: false`. Результат сохранён отдельным v2; пиксели вручную не редактировались.

```text
Use case: precise-object-edit. Edit the attached Qase iOS auth design board. Make ONLY this change in ALL FOUR phone screens: REMOVE the two-line caption underneath "Попробовать демо" that says "Без API-токена, на демонстрационных данных". Erase that text completely and fill the area with the matching native white or black screen background. Keep the demo button itself and all other text, logo, input fields, eye icons, button gradients, loading spinner, errors, status bars, home indicators, keyboard if present, external captions and the 2x2 grid unchanged. No replacement footer, no explanation or new text underneath buttons. Keep Russian copy perfectly legible. Retain the original screen geometry; the freed space below the last button simply belongs to the screen background. Do not move or redraw other components. Return the complete full-resolution board.
```

Инструмент: встроенный `image_gen.imagegen`, без CLI/API fallback. Исходные изображения используются только как референсы; пиксели результатов не редактируются вручную.

## Основной лист — v1

Референсы в порядке передачи:

1. `Design/Concepts/EntityForms/suite-create-v2.png` — поверхности и типографика новых форм.
2. `Design/Concepts/ScreenHeaders/settings-theme-token.png` — светлая/тёмная темы и поле токена.
3. `QaseAPIProj/Resources/Assets.xcassets/FullLogo.imageset/FullLogo.png` — существующий логотип.

`transparent_background: false`.

```text
Use case: ui-mockup.
Create a polished high-fidelity native iOS design board for the existing Qase mobile application authorization screen, Russian language.
Input image 1 is a visual style reference for the existing new forms, NOT a screen to copy; input image 2 is a visual style reference for Settings and API-token input; input image 3 is the EXISTING Qase wordmark: preserve its exact distinctive Q mark and letterforms, scale it down appropriately, do not invent a logo.
Deliver one large sharp portrait board with FOUR complete equally sized flat iPhone screen artboards in a precise 2x2 grid, minimal neutral gray board background, generous gutters, NO physical phone hardware, NO perspective. Artboards nominal 402x874 logical points. Screen captions OUTSIDE phones: top-left "Пустое поле · Светлая", top-right "Пустое поле · Тёмная", bottom-left "Токен введён · Светлая", bottom-right "Токен введён · Тёмная". All four screens must show the SAME pixel-aligned layout and exact same text except placeholder vs mask, and disabled vs enabled primary button. Large output, crisp Cyrillic.

Within each screen: native 9:41 status bar and bottom safe-area home indicator only. White canvas #FFFFFF for light and pure black #000000 for dark. No navigation bar, back button, close button or tab bar. A single calm compact vertical group positioned a little above the screen center, not hugging the top. Nominal group from y=200 to y=620. Centered existing purple Qase wordmark ~136pt wide, then 24pt gap. Centered 28pt bold SF Pro title EXACT "Войти в Qase". Centered secondary 15pt description EXACT "Введите API-токен для доступа к вашим проектам" in two lines. Then 32pt gap to left-aligned permanent 13pt label EXACT "API-токен". Below label 8pt gap to a single input field, 52pt high, horizontal screen insets 20pt, 12pt radius, soft #F4F5F7 light / #2C2C2D dark surface, subtle border, leading simple SF Symbol key and trailing eye.slash icon. Trailing eye icon has intended 44pt touch area. Empty fields have exact placeholder "Введите API-токен" in readable secondary gray. Filled fields show ONLY 12 black/white bullet dots, NEVER any token letters or real secret, same key and eye.slash.
Then 16pt gap to full-width 52pt high primary button, 12pt radius, centered 17pt medium EXACT "Войти". EMPTY screens: visibly disabled neutral gray button with muted gray label, no active purple. FILLED screens: active purple gradient #6757F5 to #8068FF with 12% black contrast overlay, white label, no glow.
Then 12pt gap to full-width secondary 48pt action EXACT "Попробовать демо", purple 17pt medium text on a very subtle neutral secondary surface, 12pt radius. Below 8pt gap centered secondary 13pt caption EXACT "Без API-токена, на демонстрационных данных" in two lines, readable not tiny.
Typography SF Pro-like native iOS, text light primary #111113 dark #F7F7F8, secondary #6F7179 / #A5A7AE, links accent #6757F5 / #8577FF. Clean restrained flat soft surfaces consistent with reference forms, absolutely NO outer glass card, NO decorative illustration, NO glow, NO marketing slogans, NO social sign-in, registration, passwords, help links or unrelated controls.
Priority: exact Russian copy and wordmark, consistent layout across 4 screens, obvious active/disabled hierarchy, generous readable sizes. This is the idle state board, no keyboards, loading or errors.
```

## Лист состояний — v1

Референсы в порядке передачи:

1. `auth-light-dark-v1.png` — композиция основного листа (в инструмент передан исходный результат генерации).
2. `Design/Concepts/EntityForms/suite-create-v2.png` — поверхности новых форм.
3. `QaseAPIProj/Resources/Assets.xcassets/FullLogo.imageset/FullLogo.png` — существующий логотип.

`transparent_background: false`.

```text
Use case: ui-mockup.
Create the SECOND high-fidelity native iOS design board for Qase authorization: interaction states. Input image 1 is the approved main auth design board: MATCH its logo, layout, colors, field, button styling, text and sizing closely. Input image 2 is the new forms visual reference. Input image 3 is the original existing Qase wordmark to preserve, not reinterpret.
One large sharp portrait board, FOUR equally sized complete flat iPhone app screen artboards, precise 2x2 grid, neutral gray external canvas and generous gutters, no hardware, no perspective. Screen baseline is nominal 402x874 logical points. Captions OUTSIDE screens: top-left "Ввод · Светлая", top-right "Проверка · Тёмная", bottom-left "Неверный токен · Светлая", bottom-right "Нет соединения · Тёмная". Sharp highly readable exact Cyrillic, polished SF Pro-like type.

Common screen structure matches approved input image 1: native 9:41 status bar and bottom home indicator; white / pure black app canvas; original purple Qase wordmark ~136pt wide; centered bold 28pt "Войти в Qase"; centered two-line secondary description "Введите API-токен для доступа к вашим проектам"; persistent left-aligned 13pt label "API-токен"; single soft input field 52pt high, 12pt corners, left key icon, right eye.slash, value ONLY 12 bullet dots. Screen insets 20pt; light input #F4F5F7 and dark #2C2C2D. Primary 52pt button purple gradient #6757F5 to #8068FF with 12% black overlay and white 17pt medium label. Secondary 48pt button "Попробовать демо", neutral soft surface and purple text, followed by centered 13pt two-line caption "Без API-токена, на демонстрационных данных". No outer card, no glass, no glow, no tab bar, no navbar or back/close buttons.

Four precise state differences:
1 TOP LEFT light INPUT WITH KEYBOARD: compact the vertical gaps and scroll the form upward so logo ~y100, title ~y170, description ~y210, label ~y270, focused field ~y300, primary "Войти" ~y370, demo action ~y430, caption ~y490. All those elements should fit ABOVE a native iOS English ASCII keyboard occupying ONLY the bottom ~300pt from y~574 to y874; keyboard includes a system Done accessory "Готово" above the keys. A caret after the MASKED bullets and purple input border, no visible token letters. The focused input and primary button must be fully unobscured. Keep plausible actual keyboard key layout, return label "Войти". Native keyboard gray with QWERTY keys and home indicator. Do not draw a keyboard in any of the other three screens.
2 TOP RIGHT dark CHECKING TOKEN: retain the idle slightly-above-center layout; input masked, muted controls. The primary button contains ONE visible small white ring spinner LEFT of exact white text "Проверяем…", optically centered as one group. Secondary demo button is muted gray and disabled during verification; caption remains unchanged.
3 BOTTOM LEFT light INVALID TOKEN: retain logo, title and description. Field remains masked with eye.slash and key but has restrained red border. Immediately BELOW the input show red warning outline icon and EXACT readable error "Неверный API-токен. Проверьте его и попробуйте снова." over two or three natural lines at 13pt. Reserve space and move primary and demo buttons DOWN sufficiently so error never overlaps. Active primary exact "Войти", secondary exact "Попробовать демо", unchanged caption.
4 BOTTOM RIGHT dark CONNECTION ERROR: same masked field with NORMAL neutral border, not red (network failure is not bad input). Immediately below the input a small warning/message icon and EXACT readable error "Не удалось подключиться. Проверьте интернет и попробуйте снова." in accessible muted warm orange #FF9F43 over two or three natural lines. Active primary "Войти" for retry, secondary "Попробовать демо", unchanged caption. The message has no extra card and no separate retry button; same field value stays retained.
Text light primary #111113 dark #F7F7F8; secondary #6F7179 / #A5A7AE; active links #6757F5 / #8577FF; light validation error #D92D20. Eye touch intent44pt, key icon22pt.
Constraints: exact Russian strings, no real or invented visible token, no passwords/registration/social login, no extra help links, no modal alerts, no decoration. Match approved main sheet's calm flat component design; proper spacing for error messages, keyboard must not cover field or primary CTA. Render all four complete screens without cropping.
```
