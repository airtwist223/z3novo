# История версий / Changelog

Новые версии сверху. T1, T2 и так далее — тестовые версии; 1.0 будет первой стабильной.
Newest first. T1, T2 and so on are test versions; 1.0 will be the first stable one.

## T2.0 — вторая тестовая версия

В T2.0 вошло всё, что исправлено в T1.1r и T1.2, и много нового.

### Что нового

**Загрузка и заставка**
- **Новая заставка.** Логотип Z3NOVO меньше и стоит выше середины экрана: кружок загрузки Windows его больше не задевает.
  Подсказки «[Del] Настройки  [F9] Меню загрузки» — отдельной строкой у нижнего края, на языке меню; перед запуском
  Windows или Linux они стираются.
- **F6 и F12 на заставке больше не открывают прошивальщик Biostar** (BIO-Flasher): нажатие просто пропускается. Del и F9
  работают как раньше.
- **F9 запускает диск сразу.** Windows Boot Manager и другие диски стартуют из меню загрузки без лишней перезагрузки, как
  флешки.
- **Родное меню Biostar больше не появляется само.** Если система не загрузилась (нет диска, загрузчик не запустился),
  открывается наше меню с окном «Система не загрузилась» и кнопкой «Меню загрузки»; страница Biostar и её жёлтые часы не
  мелькают. Если наше меню вдруг не запустится, на экране будет короткая подсказка, и компьютер перезагрузится. Окна
  пароля BIOS, Secure Boot и TPM — как раньше.
- **Родное меню BIOS — только в сервисном режиме:** флешка с файлом `\Z3NOVO\SERVICE.TXT` (содержимое любое), затем F1 в
  нашем меню и последняя строка окна «Клавиши». Файл ищется только на USB-флешке. Программы в Windows и Linux тоже больше
  не могут открыть родное меню в обход этого.
- **Включение быстрее** на Ryzen 2000, 2000G и 3000G: прошивка читает свою микросхему в быстром режиме и не ждёт лишнего.
  Меню хранится в прошивке в сжатом виде и по Del открывается быстрее; освободилось место для нового.
- **Меню не открывается раньше, чем прошивка загрузила свои настройки.** Раньше при очень раннем нажатии Del вкладка
  «Питание» могла оказаться пустой.
- **Ryzen без встроенной графики и без видеокарты:** если загрузиться не с чего, плата больше не перезагружается по кругу
  (раньше наше меню пыталось открыться без экрана и через 30 секунд перезапускало компьютер). 8 коротких сигналов при
  включении без видеокарты — обычное «нет изображения».

**Меню**
- **Строка F-клавиш внизу экрана.** В «Классике»: F1 Клавиши, F2 Язык, F6 Сбросить всё, F7 EZ, F9 Загрузка, F11 Отчёт,
  F12 Снимок и справа F10 Сохранить; на главном экране — свои. Кнопки нажимаются мышью и с клавиатуры.
- **F1 — окно «Клавиши»:** все клавиши меню в одном окне; строку можно нажать мышью или Enter — она сделает то же, что
  клавиша. Внизу окна — QR-коды Telegram-бота [@z3novo_bot](https://t.me/z3novo_bot) и страницы проекта на GitHub.
- **F6 — «Сбросить всё на заводские»** (то же — Классика → Безопасность). Сначала окно скажет, что изменится и что нет,
  «Показать изменения» откроет список, а записывается всё только по «Сохранить и перезагрузить». Не меняются пароли,
  безопасная загрузка и её ключи, модуль TPM, порядок загрузки, язык и настройки самих устройств (например, DASH в
  сетевой карте). Передумали — «Назад», Esc или правая кнопка мыши: всё остаётся как было до F6, вместе с вашими
  несохранёнными изменениями.
- **F12 — снимок экрана на флешку** (`\Z3NOVO\SCREEN-дата-время.PNG`) на любом экране меню, в том числе в меню загрузки.
- **Backspace (или Delete) сбрасывает пункт** — то же, что кнопка «Сбросить» справа.
- **Окно «Состояние»** вместо прежней страницы: Классика → Питание → «Датчики и обороты» или щелчок по температуре
  вверху. Процессор и каждый вентилятор, у которого есть сигнал, — своя дорожка с числом и графиком за минуту; ниже —
  воздух на входе, батарейка CMOS, частота, память, версия BIOS и какие разъёмы вентиляторов пусты. Под оборотами — ШИМ.
  F3 в этом окне показывает подробности: напряжения и регистры. Всё помещается без прокрутки от 800×600 до 1920×1080.
- **Вкладка «Другое»** (была «Все»): настройки AMD CBS/PBS и страницы устройств (NVMe, SATA, сетевая карта, платы
  расширения) в том же виде, что остальные вкладки. Сырые страницы родного меню Biostar оттуда убраны — всё нужное из них
  есть на других вкладках. У пунктов AMD CBS — описания простыми словами; 37 пунктов, которые на этой плате только вредят
  или ничего не делают (тестовые режимы PCIe, отладка, режим для жидкого азота и подобные), убраны.
- **Esc на главном экране** открывает окно «Выйти?» с кнопками «Остаться» и «Загрузить».
- **Главный экран после ручного разгона** пишет у частоты «вручную» и показывает заданное значение, а не заводской буст.
- **Меню открывается в том виде, который выбран последним** — главный экран или «Классика».
- **F3 работает только в окне «Состояние».** Общего режима с техническими названиями больше нет.
- **Окно ввода числа говорит единицами пункта:** напряжение — в вольтах (раньше «0x18, 0x28…»), и «+» его повышает;
  обороты — в процентах, «Авто» — словом. Значение можно набрать: «1,3» или «1300» — это 1,300 В.
- **У рискованных пунктов — своё предупреждение**, что будет, если компьютер не запустится: откат после трёх неудачных
  запусков, возврат памяти на обычную скорость или как сбросить CMOS.
- **Перезагрузка, когда она нужна.** После включения «Защиты от неудачного разгона» или смены ключей Secure Boot меню
  предлагает «Перезагрузить», а не уходит сразу в систему.
- **Флешки exFAT читаются** (файл обновления, загрузка с флешки, программы UEFI). Только чтение: отчёт F11, снимок экрана
  и копию прошивки на exFAT не записать — меню так и скажет; для записи нужна флешка FAT32.
- **Платы расширения** со своими настройками (RAID-контроллеры, сетевые карты): их страницы во вкладке «Другое» работают
  через драйвер самой платы.

**Процессор и питание**
- **Разгон процессора с защитой:** своя частота и напряжение ядер на Ryzen 2000G, 3000G и 4000G, а на 2000G и 3000G — ещё
  и встроенной графики (Классика → Процессор). Открывается только после включения **«Защиты от неудачного разгона»**:
  если после разгона компьютер 3 раза подряд не дойдёт до загрузки системы, прошивка сама вернёт заводские значения.
  Пределы для разных процессоров — в [ограничениях платы](docs/LIMITS.md#6-разгон-процессора).
- **Разгон встроенной графики на Ryzen 4000G и 5000G:** от заводской частоты модели до 2400 МГц, напряжение 1,10–1,25 В.
  **Athlon 200GE–3150G** — разгон графики, как у Ryzen 2000G/3000G. Только при «Защите от неудачного разгона». Частота
  графики задаётся постоянной, как на других платах; прибавка в играх небольшая.
- **Curve Optimizer на Ryzen 5000 (5000G и 5000 без G):** снижение напряжения всех ядер на 1–30 ступеней; буст и пределы
  мощности остаются заводскими. Только при «Защите от неудачного разгона» и только если сама AMD даёт его этому
  процессору.
- «Защита от неудачного разгона» возвращает теперь и настройки AMD Overclocking (Curve Optimizer, ручные частоты AMD) и
  включается раньше в запуске.
- **Процессоры на 95–105 Вт** (2700X, 3900X, 5800X, 5950X и подобные) по умолчанию ограничены классом 65 Вт (88 Вт): на
  это рассчитана плата. Полную мощность можно включить на свой риск: Классика → Процессор → «Свои пределы мощности (PBO)».
  Меню показывает ограничение пометкой в «Классике» и строкой на главном экране.
- **«Свои пределы мощности (PBO)»** (для всех Ryzen): свои PPT/TDC/EDC, множитель PBO и прибавка буста до +200 МГц (где их
  поддерживает прошивка AMD). Включается только вместе с «Защитой от неудачного разгона»; при сохранении — предупреждение
  и галочка «Я понимаю риск»; три неудачных запуска подряд вернут заводские значения.
- **Предел температуры на Ryzen 3000 и 5000 без графики:** Классика → Процессор → «Предел температуры» (Авто, 85°, 80°,
  75°).
- **«Режим мощности» на 65-ваттных Ryzen 4000G и 5000G:** «Эко» (до 60 Вт) и «Обычный». «Повышенного» у них нет: 88 Вт —
  уже их заводской предел и предел платы.
- **Пределы тока — этой платы, а не платы-донора:** прошивка сообщает процессору числа Lenovo для M715s. На Ryzen 2000G
  и 3000G ток графики и контроллера памяти ограничен 40 А, как у Lenovo.
- **Напряжение графики на Ryzen 2000G и 3000G — не ниже 1,10 В:** от этой же линии питается контроллер памяти.
- **Точное управление частотой (CPPC) на Ryzen 4000G и 5000G теперь по умолчанию включено:** Windows и Linux (драйвер
  amd-pstate) сами быстро выбирают частоту каждого ядра. Пункт Классика → Процессор → «Точное управление частотой».

**Память**
- **Ручная частота и XMP без лишней перезагрузки** перед каждым запуском системы. Компьютер перезапускается сам один раз
  только сразу после сохранения новых настроек памяти или после обновления прошивки.
- **«Авто» с двумя разными планками** ставит частоту по более медленной (раньше — по последней найденной).
- **Задержки памяти снова видны.** На настоящей плате меню не узнавало их названий, и с T1 в Классика → Память были
  только «Подача команд», «Gear Down» и ODT. Теперь там все главные задержки и новая свёрнутая группа «Тонкие задержки»:
  ещё 24 задержки и сопротивление ODT процессора, с понятными названиями и пределами AMD. Своё значение — это разгон
  памяти: подбирайте его только с долгой проверкой памяти.
- **Ryzen 3000 без G, 4000G, 5000 и 5000G:** пункты «Контроллер памяти 1:1» и «Частота Infinity Fabric» (открываются
  только при своей скорости памяти).
- **Ryzen 4000G и 5000G: две настройки памяти — как у других плат с этими процессорами.** После обновления прошивки (в
  том числе с T1.x) первый запуск один раз заново обучит память — это несколько секунд.
- **«Память для графики» — своё число в гигабайтах.** На Ryzen 4000G и 5000G — от 1 ГБ до «вся память минус 3 ГБ», шаг
  1 ГБ; если системе остаётся меньше 8 ГБ, меню предупредит. На Ryzen 2000G и 3000G — от 512 МБ до 16 ГБ, кроме 3, 6 и
  12 ГБ. Больше 2 ГБ — только с выключенным CSM. Сохранённые раньше значения остаются как были.
- «Авто» больше не оставляет в списке изменений спрятанное значение (например, частоту памяти при «Режиме памяти: Авто»).

**Экран**
- **Второй разъём DisplayPort можно переключить в «HDMI»** (Классика → Устройства → «Второй разъём DisplayPort») — для
  пассивного переходника DP→HDMI: с ним доступна частота кадров до 144 Гц. Монитор DisplayPort в этом разъёме тогда
  ничего не покажет. На Ryzen 4000G и 5000G после переключения компьютер один раз перезапустится сам.

**Вентиляторы и датчики**
- **Все три вентилятора управляются.** Кроме вентилятора процессора прошивка ведёт по температуре процессора и
  вентиляторы на разъёмах FAN2 и FAN3: раньше они крутились на постоянных средних оборотах. В Классика → Питание у
  каждого свой режим «Тихо / Авто / Макс».
- **Вентилятор на старте спокойнее:** больше не поднимается до половины оборотов после логотипа, а на Ryzen 2000G, 3000G
  и Athlon не уходит на несколько секунд на полные.
- **«Импульсов за оборот» 2 или 4** для вентилятора процессора — если меню показывает обороты вдвое больше настоящих.
- **Напряжения в окне «Состояние» и в отчёте F11:** питание +3,3 В, дежурное +3,3 В и батарейка CMOS (ниже 2,7 В меню
  подскажет её заменить). +12 В и +5 В на этой плате не измеряются вовсе: эти входы микросхемы датчиков не подключены,
  поэтому AIDA64, HWiNFO и родной BIOS показывали там бессмыслицу — блок питания ни при чём
  ([подробнее](docs/DIAGNOSTICS.md#напряжения-aida64-и-hwinfo)).

**Имя компьютера**
- **Компьютер называется своим именем.** Windows, AIDA64 и другие программы видят его как Z3NOVO Labs ThinkCentre M715s
  Reborn (плата AM4P2MS Unlocked), а не Biostar X470GTA; в строке версии BIOS — Z3NOVO и номер версии. Серийный номер и
  модель конкретной машины прошивка не выдумывает: эти поля пустые. Программы Lenovo (Vantage, System Update) эту машину не
  узнают и ничего для неё не предлагают. Windows может один раз попросить подтвердить активацию
  ([что делать](docs/KNOWN_ISSUES.md)).

**Безопасность**
- **Пароль BIOS задаётся в нашем меню:** Классика → Безопасность → «Пароль на настройки» и «Пароль на включение», от 3 до
  20 знаков. Пароль спрашивается один раз. Забытый пароль снимает только сброс CMOS, а с ним сбрасываются все настройки.
- **«Очистить TPM»** (сначала сохраните ключ восстановления BitLocker) и под ним строка «Платформенная иерархия TPM» —
  обычно включена, трогать её не нужно.
- **«Ключи Secure Boot»:** записать ключи по умолчанию, включить и выключить безопасную загрузку, удалить все ключи.
  Включённая безопасная загрузка теперь сохраняется (раньше было окно «Сохранено не всё»). Как включать по шагам — в
  [DIAGNOSTICS.md](docs/DIAGNOSTICS.md#secure-boot-по-шагам).

**DASH**
- **Наше меню в консоли DASH:** Del или F9, нажатые в текстовой консоли DASH, открывают наше меню текстом (пункт «Консоль
  BIOS через DASH»). По-русски — если терминал в UTF-8, иначе по-английски. F5–F12 доходят и из обычных терминалов
  (telnet, xterm, PuTTY). Окна, которые есть только на экране (кривая вентилятора, обновление прошивки и подобные), в
  консоли не открываются.
- **DASH включает компьютер и после выдёргивания шнура.** Раньше после пропадания питания команда «включить» не доходила.
  Теперь, если DASH включён и «Автовключение» стоит «Не включаться», после возвращения питания компьютер сам включается
  на несколько секунд, готовит DASH и выключается; дальше «включить» по DASH работает. С «Включиться» он просто
  загружается, и DASH тоже готов.
- **DASH больше не замолкает до выдёргивания шнура:** если управляющий процессор сетевой карты перестал отвечать (бывало
  после удалённого сброса или зависания), прошивка при следующем включении перезапускает его.
- **Удалённое питание в Linux без параметра ядра:** когда DASH включён, прошивка сама прячет от Linux шину, по которой
  карта передаёт команды питания.

**Отчёт F11**
- **Куда отправить отчёт:** после F11 окно показывает QR-коды Telegram-бота @z3novo_bot и GitHub; адреса — и в начале
  файла отчёта.
- Новые строки: планка стоит, но не используется (на главном экране меню тогда тоже есть такая строка); память
  восстановлена из сохранённого или обучена заново; за сколько открылось меню; напряжения; обороты и выходы всех
  вентиляторов, сырые счёты тахометров и версия программы в микросхеме вентиляторов; что умеет защита от неудачного
  разгона. Выход из сна больше не отмечается как незавершённый запуск. Про флешку только для чтения отчёт пишет прямо, а
  не «флешка не найдена».

**Исправления**
- **Сон на Ryzen 4000G и 5000G.** Компьютер засыпал, но не просыпался: экран чёрный, лампочка горит, помогало только
  выдернуть шнур. При пробуждении процессор проверяет, что копия прошивки в памяти не изменилась, а прошивка писала в эту
  копию свои заметки. Теперь перед запуском системы и перед выходом из сна копия возвращается в исходный вид. **На таких
  процессорах это ещё не проверено** — просьба к тем, у кого такой процессор, — в [известных проблемах](docs/KNOWN_ISSUES.md).
- **Ryzen 2000G, 3000G и Athlon: обмен с микросхемой, которая ведёт вентиляторы, датчики и сторожевой таймер, больше не
  теряет данные.** Раньше терялось около 10 % обращений, теперь — ни одного из 20 000.
- **Встроенная графика больше не может выключиться сама после зависания при старте.** Журнал запусков мог записать в CMOS
  значение, которое прошивка AMD читает как «выключить встроенную графику»: на Ryzen с графикой и без видеокарты тогда не
  было изображения до 15 запусков подряд. Теперь журнал этот байт не трогает, а если такое значение там уже есть, прошивка
  его стирает.
- **Linux больше не пишет «irq 7: nobody cared»:** неиспользуемый контроллер GPIO снова скрыт, как у Lenovo.
- **Слот M.2:** тактовый сигнал накопителя NVMe теперь всегда включён, как в родном BIOS Lenovo.
- **Сохранение настроек:** если прошивка отказывается записать один пункт (например, «Безопасную загрузку»), остальные
  изменения всё равно записываются, а следующее сохранение не натыкается на ту же ошибку. Раньше после такого отказа
  каждое сохранение заканчивалось окном «Сохранено не всё», и часть изменений (вентиляторы, DASH) не записывалась.
- При экране 800×600 всплывающее сообщение в «Классике» больше не ложится на строки списка.
- Исправлена скрытая ошибка меню: при каждом запуске оно писало за пределы отведённой памяти. Проявлений не видели.

**Как обновиться**
- С T1.2 или T1.1r — из меню с флешки, как обычно ([по шагам](docs/FLASHING.md#с-t12-или-t11r-на-t20)). Настройки
  сохраняются. Первый запуск после обновления на несколько секунд дольше: прошивка заново обучает память. С T1.1 и T1 путь
  тот же, но его мы не проверяли.

### Ограничения
- Напряжение памяти всегда 1,2 В — так устроена плата ([подробнее](docs/LIMITS.md)).
- Своя частота ядер закрыта на Ryzen без встроенной графики, на Ryzen 5000 (вместо неё — Curve Optimizer) и на Athlon,
  кроме 3000G. Напряжение ядер задаётся как постоянное, без смещения: схема питания на плате смещений не умеет. Curve
  Optimizer — только общий для всех ядер и только в минус ([подробнее](docs/LIMITS.md#6-разгон-процессора)).
- «Защита от неудачного разгона» ловит только запуски, которые не дошли до системы, и возвращает заводские значения, а не
  последние удачные. Если после разгона сбоит уже Windows (например, в играх), нажмите Del при включении и верните «Авто».
- Разгон встроенной графики делает её частоту постоянной, и драйвер об этом не знает. На Ryzen 3 2200G автора уже при
  1200 МГц (1,200 В) компьютер зависал под нагрузкой на графику, а в Linux драйвер amdgpu после такого разгона сбоит.
  Такие сбои защита не ловит.
- «Подача команд» (Cmd2T) и «Gear Down» можно менять и при скорости памяти «Авто», но тогда встроенная защита AMD («Memory
  OC fail») их не прикрывает: если память с ними не заведётся, поможет только сброс CMOS.
- Когда DASH выключен, по сети компьютер не включить и не перезапустить. С DASH и «Автовключение: Как было» компьютер,
  который был выключен, когда пропало питание, по DASH не включится, пока его хоть раз не включат кнопкой или по сети
  (Wake-on-LAN).
- С включённой безопасной загрузкой не запускаются неподписанные флешки, в том числе тест-флешка.
- [Известные проблемы](docs/KNOWN_ISSUES.md).

### Что проверено
На плате автора (AM4P2MS ревизии 1.1, Ryzen 3 2200G, две планки по 8 ГБ DDR4-2666), на двух последних пробных сборках
(последняя отличается от T2.0 только номером версии):
- обновление из меню с предыдущей пробной сборки, возврат на неё из меню и снова вперёд;
- запуск, Windows и Linux, сон и пробуждение, вход в наше меню из Windows («Параметры встроенного ПО UEFI»);
- заставка: логотип, подсказки Del/F9 по-русски и по-английски, кружок загрузки Windows их не задевает, перед системой
  подсказки стираются; F6 и F12 на заставке ничего не открывают;
- F6 «Сбросить всё на заводские»: список изменений без настроек устройств, сброс с перезагрузкой (настройки DASH в
  сетевой карте целы), отмена кнопкой «Назад», Esc и правой кнопкой мыши;
- вкладка «Другое» и поиск, «Платформенная иерархия TPM», строка F-клавиш, окно F1 «Клавиши» и QR-коды (открывают бота и
  GitHub), сервисный режим (родное меню через `SERVICE.TXT`), снимки экрана F12, запоминание вида, Esc на главном экране,
  Backspace на пункте;
- окно «Состояние» (дорожки, ШИМ, подробности по F3) и отчёт F11 с QR-кодами;
- DASH: включение по сети после выключения и после выдёргивания шнура.

На плате автора, на более ранних пробных сборках T2 (на последних не повторяли):
- обновление из меню с T1.2;
- разгон ядер: 3900 МГц при 1,375 В — 10 минут под нагрузкой без ошибок (4000 МГц этот экземпляр не держит при любом
  напряжении); откат после трёх неудачных запусков сработал. С тех пор защиту доработали (Curve Optimizer, более ранний
  запуск) — в нынешнем виде на плате её ещё не проверяли;
- разгон графики 1200 МГц / 1,200 В применяется, но под нагрузкой на графику компьютер зависал;
- обмен с микросхемой IT8738: 0 ошибок на 20 000 обращений; ускоренное чтение микросхемы BIOS;
- новое имя компьютера (в Linux), нет строки «irq 7: nobody cared»;
- наше меню в консоли DASH: Del, F9, переходы по меню и изменение пунктов (сохранение из консоли не проверяли);
- «Память для графики» 11 ГБ при 16 ГБ памяти: Linux видит 11 ГБ видеопамяти.

Тестеры T2.0 ещё не проверяли; их проверки T1.2 — в [списке проверенного](docs/TESTED.md).

### Что ещё не проверено
- **Сон на Ryzen 4000G и 5000G с исправлением** — ждём от владельцев таких процессоров
  ([как помочь](docs/KNOWN_ISSUES.md)).
- Всё, что на Ryzen 3 2200G не проверить: разгон графики Ryzen 4000G/5000G и Athlon, разгон ядер Ryzen 4000G, Curve
  Optimizer, ограничение процессоров на 95–105 Вт и «Свои пределы мощности (PBO)», предел температуры, «Режим мощности» и
  CPPC на 4000G/5000G, «Контроллер памяти 1:1» и «Частота Infinity Fabric», настройки памяти 4000G/5000G, «Память для
  графики» больше 16 ГБ.
- Защита от неудачного разгона в нынешнем виде.
- Обновление с T1.2 и T1.1r на сам T2.0 и возврат с T2.0 на T1.2 — на плате (проверены только расчётом на компьютере);
  обновление с T1.1 и T1.
- F9 → запуск диска без перезагрузки, окно «Система не загрузилась», пароль BIOS, Secure Boot, очистка TPM.
- Вентиляторы FAN2 и FAN3 (на плате автора они не подключены), «Импульсов за оборот», вентилятор на старте.
- Задержки памяти в «Классике» и «Тонкие задержки», ручная частота и XMP без лишней перезагрузки, «Авто» с двумя разными
  планками.
- Второй DisplayPort в режиме HDMI, такт M.2 с накопителем NVMe, страницы плат расширения, флешки exFAT.
- Напряжения в «Состоянии» против мультиметра; активация Windows после смены имени компьютера.
- DASH: удалённое выключение и перезагрузка в Linux без параметра ядра, перезапуск замолчавшего DASH, сохранение
  настроек из консоли.
- Ryzen без встроенной графики без видеокарты (после исправления).

## T2.0 — second test version

T2.0 has everything fixed in T1.1r and T1.2, and a lot that is new.

### What is new

**Start-up and the boot screen**
- **A new boot screen.** The Z3NOVO logo is smaller and sits above the middle of the screen, so the Windows loading
  circle no longer touches it. The "[Del] Setup  [F9] Boot menu" hints are a line of their own near the bottom edge, in
  the menu's language; they are wiped before Windows or Linux starts.
- **F6 and F12 at the boot screen no longer open Biostar's flasher** (BIO-Flasher): the key is simply skipped. Del and F9
  work as before.
- **F9 starts a disk at once.** Windows Boot Manager and other disks start from the boot menu without an extra restart,
  just like USB sticks.
- **The stock Biostar menu no longer shows up by itself.** If the system did not start (no disk, or the boot loader did
  not run), our menu opens with a "The system did not start" window and a "Boot menu" button; the Biostar page and its
  yellow clock do not flash up. Should our menu ever fail to start, a short note appears and the computer restarts. The
  BIOS password, Secure Boot and TPM windows show as before.
- **The stock BIOS menu only in service mode:** a USB stick with the file `\Z3NOVO\SERVICE.TXT` (any content), then F1 in
  our menu and the last line of the Keys window. The file is looked for on USB sticks only. Programs in Windows and Linux
  can no longer open the stock menu around this either.
- **Faster power-on** on the Ryzen 2000, 2000G and 3000G: the firmware reads its chip in fast mode and no longer waits for
  nothing. The menu is stored compressed in the firmware and opens faster on Del; this freed room for new things.
- **The menu does not open before the firmware has loaded its settings.** Before, a very early Del could leave the Power
  tab empty.
- **A Ryzen without built-in graphics and no graphics card:** when there is nothing to boot, the board no longer restarts
  in a loop (before, our menu tried to open without a screen and restarted the computer after 30 seconds). Eight short
  beeps at power-on without a graphics card are the usual "no picture".

**Menu**
- **A line of F keys at the bottom.** In Classic: F1 Keys, F2 Language, F6 Reset all, F7 EZ, F9 Boot, F11 Report,
  F12 Screenshot and, on the right, F10 Save; the home screen has its own. The buttons work with the mouse and the
  keyboard.
- **F1 opens the Keys window:** every key of the menu in one window; a line clicked or Enter does what the key does. At
  the bottom of the window: QR codes for the Telegram bot [@z3novo_bot](https://t.me/z3novo_bot) and the project's GitHub
  page.
- **F6: "Reset all to factory"** (also Classic → Security). A window first says what changes and what stays, "Show the
  changes" opens the list, and nothing is written until "Save and restart". The passwords, Secure Boot and its keys, the
  TPM, the boot order, the language and the devices' own settings (DASH in the network card, for example) stay as they
  are. Changed your mind? "Back", Esc or a right click leaves everything as it was before F6, your own unsaved changes
  included.
- **F12 saves a screenshot to a USB stick** (`\Z3NOVO\SCREEN-date-time.PNG`) on any screen of the menu, the boot menu
  included.
- **Backspace (or Delete) resets an item**, the same as the "Reset" button on the right.
- **The Health window** replaces the old page: Classic → Power → "Sensors and fan speeds", or a click on the temperature
  at the top. The processor and every fan that gives a signal get a lane of their own with the number and a one-minute
  graph; below are the inlet air, the CMOS battery, the clock, the memory, the BIOS version and which fan headers are
  empty. Under the fan speed is the PWM. F3 in this window shows the details: voltages and registers. It all fits without
  scrolling from 800×600 to 1920×1080.
- **The "Other" tab** ("All" before): the AMD CBS/PBS settings and the devices' pages (NVMe, SATA, the network card,
  add-in cards) look the same as the other tabs. The raw pages of Biostar's stock menu are gone from it; everything needed
  from them is on the other tabs. AMD CBS items have plain-word descriptions; 37 items that only do harm or nothing on this
  board (PCIe test modes, debugging, a liquid-nitrogen mode and the like) are gone.
- **Esc on the home screen** opens a "Leave?" window with "Stay" and "Boot".
- **The home screen after a manual overclock** shows "manual" next to the clock and the value you set, not the factory
  boost.
- **The menu opens in the view chosen last**, the home screen or Classic.
- **F3 works only in the Health window.** The general mode with technical names is gone.
- **The number box speaks the item's units:** voltage in volts (it used to show "0x18, 0x28…"), and + raises it; fan
  speed in per cent, Auto as a word. You can type a value: "1.3" or "1300" means 1.300 V.
- **Risky items have a warning of their own** about what happens if the computer does not start: the rollback after three
  failed starts, memory going back to the normal speed, or how to clear CMOS.
- **A restart when one is needed.** After you turn on "Failed overclock protection" or change the Secure Boot keys, the
  menu offers "Restart" instead of going straight on to the system.
- **exFAT USB sticks can be read** (an update file, booting from a stick, UEFI programs). Read only: the F11 report, a
  screenshot and a firmware copy cannot be written to exFAT, and the menu says so; writing needs a FAT32 stick.
- **Add-in cards** with their own settings (RAID controllers, network cards): their pages on the "Other" tab work through
  the card's own driver.

**Processor and power**
- **Processor overclocking with protection:** your own core clock and voltage on the Ryzen 2000G, 3000G and 4000G, and on
  the 2000G and 3000G the built-in graphics too (Classic → Processor). It opens only after you turn on **"Failed overclock
  protection"**: if after an overclock the computer fails to reach the system 3 times in a row, the firmware puts the
  factory values back by itself. Limits for each processor: [board limits](docs/LIMITS.md#6-processor-overclocking).
- **Built-in graphics overclocking on the Ryzen 4000G and 5000G:** from the model's own clock up to 2400 MHz, at
  1.10–1.25 V. **Athlon 200GE–3150G:** graphics overclocking as on the Ryzen 2000G/3000G. Only with Failed overclock
  protection on. The graphics clock is fixed, as on other boards; the gain in games is small.
- **Curve Optimizer on the Ryzen 5000 (5000G and 5000 without G):** lowers every core's voltage by 1–30 steps; the boost
  and the power limits stay as made. Only with Failed overclock protection on, and only where AMD itself offers it for the
  processor.
- Failed overclock protection now also puts AMD Overclocking settings back (Curve Optimizer, AMD's manual clocks) and
  starts earlier in the boot.
- **95–105 W processors** (2700X, 3900X, 5800X, 5950X and the like) are limited to the 65 W class (88 W) by default: that
  is what the board is built for. Full power can be turned on at your own risk: Classic → Processor → "Own power limits
  (PBO)". The menu shows the limit with a note in Classic and a line on the home screen.
- **"Own power limits (PBO)"** (every Ryzen): your own PPT/TDC/EDC, the PBO scalar and a boost override up to +200 MHz
  (where AMD's firmware supports them). It goes on only together with Failed overclock protection; saving warns and asks
  you to tick "I understand the risk"; three failed starts in a row bring the factory values back.
- **Temperature limit on the Ryzen 3000 and 5000 without graphics:** Classic → Processor → "Temperature limit" (Auto, 85°,
  80°, 75°).
- **Power mode on the 65 W Ryzen 4000G and 5000G:** Eco (up to 60 W) and Normal. They have no Boosted: 88 W is already
  their own limit and the board's.
- **Current limits of this board, not the donor's:** the firmware gives the processor Lenovo's numbers for the M715s. On
  the Ryzen 2000G and 3000G the current of the graphics and the memory controller is capped at 40 A, as Lenovo does.
- **Graphics voltage on the Ryzen 2000G and 3000G is now 1.10 V at the lowest:** the memory controller runs off the same
  line.
- **Fine clock control (CPPC) on the Ryzen 4000G and 5000G is now on by default:** Windows and Linux (the amd-pstate
  driver) pick each core's clock quickly themselves. The item: Classic → Processor → "Fine clock control".

**Memory**
- **Manual speed and XMP without the extra restart** before every start of the system. The computer restarts by itself
  once only right after you save new memory settings or after a firmware update.
- **Auto with two different sticks** sets the speed by the slower one (before, by the last one found).
- **The memory delays show again.** On the real board the menu did not recognise their names, and since T1 Classic →
  Memory had only the command rate, Gear Down and ODT. Now it has all the main delays and a new folded group, Fine delays:
  24 more delays and the processor's ODT resistance, with plain names and AMD's limits. A value of your own is a memory
  overclock: tune it only with a long memory test.
- **Ryzen 3000 without G, 4000G, 5000 and 5000G:** "Memory controller 1:1" and "Infinity Fabric clock" (they open only
  with a memory speed of your own).
- **Ryzen 4000G and 5000G: two memory settings as on other boards with these processors.** After the firmware update
  (from T1.x as well) the first start trains the memory once more; it takes a few seconds.
- **"Memory for graphics" is a number of your own, in gigabytes.** On the Ryzen 4000G and 5000G it goes from 1 GB up to
  all the memory less 3 GB, in steps of 1 GB; if the system is left with less than 8 GB, the menu warns you. On the Ryzen
  2000G and 3000G it is 512 MB to 16 GB, except 3, 6 and 12 GB. Over 2 GB needs CSM off. Values saved before stay as they
  were.
- Auto no longer leaves a hidden value in the list of changes (for example the memory speed with "Memory mode: Auto").

**Screen**
- **The second DisplayPort socket can be switched to "HDMI"** (Classic → Devices → "Second DisplayPort socket") for a
  passive DP→HDMI adapter: with it a refresh rate of up to 144 Hz is available. A DisplayPort monitor on that socket then
  shows nothing. On the Ryzen 4000G and 5000G the computer restarts once by itself after the switch.

**Fans and sensors**
- **All three fans are controlled.** Besides the processor fan, the firmware now drives the fans on the FAN2 and FAN3
  headers by the processor's temperature: before, they ran at a fixed medium speed. In Classic → Power each has its own
  Quiet / Auto / Max mode.
- **A calmer fan at start-up:** it no longer runs at half speed after the logo, and on the Ryzen 2000G, 3000G and Athlon it
  no longer goes to full speed for a few seconds.
- **"Pulses per revolution" 2 or 4** for the processor fan, if the menu shows twice the real speed.
- **Voltages in the Health window and in the F11 report:** the +3.3 V supply, the +3.3 V standby and the CMOS battery
  (below 2.7 V the menu suggests replacing it). +12 V and +5 V are not measured on this board at all: those inputs of the
  sensor chip are not connected, which is why AIDA64, HWiNFO and the stock BIOS showed nonsense there — the power supply
  is fine ([details](docs/DIAGNOSTICS.md#voltages-aida64-and-hwinfo)).

**Computer name**
- **The computer goes by its own name.** Windows, AIDA64 and other programs see it as a Z3NOVO Labs ThinkCentre M715s
  Reborn (board AM4P2MS Unlocked) instead of a Biostar X470GTA; the BIOS version line reads Z3NOVO and the version. The
  firmware does not make up a machine's serial number or model: those fields are blank. Lenovo's tools (Vantage, System
  Update) do not recognise the machine and offer nothing for it. Windows may ask once to confirm activation
  ([what to do](docs/KNOWN_ISSUES.md#known-issues)).

**Security**
- **The BIOS password is set in our menu:** Classic → Security → "Settings password" and "Power-on password", 3 to 20
  characters. The password is asked once. A forgotten password can only be removed by clearing CMOS, which resets all
  settings too.
- **"Clear the TPM"** (save your BitLocker recovery key first), with the "TPM platform hierarchy" line under it: it is
  normally on and needs no touching.
- **"Secure Boot keys":** install the default keys, turn Secure Boot on and off, delete all keys. Secure Boot turned on is
  now saved (before, a "Not everything was saved" window came up). Step by step:
  [DIAGNOSTICS.md](docs/DIAGNOSTICS.md#secure-boot-step-by-step).

**DASH**
- **Our menu in the DASH console:** Del or F9 pressed in the DASH text console opens our menu as text (the "BIOS console
  over DASH" item). It writes Russian when the terminal is set to UTF-8 and English otherwise. F5–F12 now get through from
  ordinary terminals too (telnet, xterm, PuTTY). Windows that only the screen has (the fan curve, the firmware update and
  the like) do not open in the console.
- **DASH turns the computer on after the power cord was out, too.** Before, after a power loss the "power on" command went
  nowhere. Now, with DASH on and Auto power-on at Stay off, the computer turns on by itself for a few seconds when power
  comes back, gets DASH ready and turns off again; after that "power on" over DASH works. With Turn on it simply boots, and
  DASH is ready as well.
- **DASH no longer goes silent until the power cord is pulled:** if the network card's management processor stops
  answering (seen after a remote reset or a hang), the firmware restarts it at the next power-on.
- **Remote power on Linux without the kernel parameter:** while DASH is on, the firmware hides from Linux the bus the card
  sends its power commands over.

**F11 report**
- **Where to send the report:** after F11 the window shows QR codes for the Telegram bot @z3novo_bot and GitHub; the
  addresses are at the top of the report file too.
- New lines: a stick in place but not in use (the menu's home screen then has such a line too); memory restored from the
  saved setup or trained anew; how long the menu took to open; voltages; the speeds and outputs of all fans, the raw
  tachometer counts and the version of the program in the fan chip; what the overclock protection covers. Waking from
  sleep is no longer marked as an unfinished start. A read-only stick is named as such instead of "no stick".

**Fixes**
- **Sleep on the Ryzen 4000G and 5000G.** The computer went to sleep but did not wake up: black screen, power light on,
  only pulling the plug helped. On waking the processor checks that the firmware's copy in memory has not changed, and the
  firmware wrote its notes into that copy. Now the copy is put back as it was before the system starts and before
  returning from sleep. **Not yet tested on these processors**; a request to their owners is in the
  [known issues](docs/KNOWN_ISSUES.md#known-issues).
- **Ryzen 2000G, 3000G and Athlon: talking to the chip that runs the fans, the sensors and the watchdog no longer loses
  data.** Before, about 10 % of the exchanges were lost; now none in 20,000.
- **The built-in graphics can no longer switch itself off after a start that hung.** The boot log could write into CMOS a
  value that AMD's firmware reads as "turn the built-in graphics off": on a Ryzen with graphics and no graphics card there
  was then no picture for up to 15 starts in a row. Now the log leaves that byte alone, and if that value is already
  there, the firmware clears it.
- **Linux no longer reports "irq 7: nobody cared":** the unused GPIO controller is hidden again, as Lenovo has it.
- **M.2 slot:** the NVMe drive's reference clock now stays on all the time, as in Lenovo's own BIOS.
- **Saving settings:** when the firmware refuses to write one item (Secure Boot, for example), the other changes are still
  written, and the next save does not run into the same error. Before, after such a refusal every save ended with "Not
  everything was saved", and some changes (fans, DASH) were never written.
- On an 800×600 screen a pop-up message in Classic no longer lands on the rows of the list.
- Fixed a hidden menu bug: every time the menu started it wrote past the memory set aside for it. No effects were seen.

**How to update**
- From T1.2 or T1.1r: from the menu with a USB stick, as usual ([step by step](docs/FLASHING.md#from-t12-or-t11r-to-t20)).
  Settings are kept. The first start after the update takes a few seconds longer: the firmware trains the memory anew.
  From T1.1 and T1 the way is the same, but we have not tested it.

### Limits
- The memory voltage is always 1.2 V, that is how the board is built ([details](docs/LIMITS.md)).
- A core clock of your own is locked on Ryzen without built-in graphics, on the Ryzen 5000 (they get Curve Optimizer
  instead) and on the Athlon except the 3000G. The core voltage is set as a fixed value with no offset: the board's power
  circuit cannot do offsets. Curve Optimizer is one value for all cores, and negative only
  ([details](docs/LIMITS.md#6-processor-overclocking)).
- Failed overclock protection only catches starts that did not reach the system, and it puts back the factory values, not
  the last good ones. If Windows itself fails after an overclock (in games, for example), press Del at power-on and set
  Auto again.
- A graphics overclock fixes the graphics clock, and the driver does not know it. On the author's Ryzen 3 2200G, already at
  1200 MHz (1.200 V) the computer froze under graphics load, and on Linux the amdgpu driver misbehaves after such an
  overclock. The protection does not catch such failures.
- Command rate (Cmd2T) and Gear Down can be changed with the memory speed on Auto too, but then AMD's built-in protection
  ("Memory OC fail") does not cover them: if the memory does not start with them, only clearing CMOS helps.
- With DASH off, the computer cannot be turned on or restarted over the network. With DASH on and Auto power-on at As it
  was, a computer that was off when the power went cannot be turned on over DASH until it has been turned on once with the
  button or over the network (Wake-on-LAN).
- With Secure Boot on, unsigned USB sticks do not start, the test stick among them.
- [Known issues](docs/KNOWN_ISSUES.md#known-issues).

### Tested
On the author's board (AM4P2MS revision 1.1, Ryzen 3 2200G, two 8 GB sticks of DDR4-2666), on the last two test builds
(the last one differs from T2.0 only in its version number):
- updating from the menu from the previous test build, going back to it from the menu and forward again;
- start-up, Windows and Linux, sleep and wake, opening our menu from Windows ("UEFI Firmware Settings");
- the boot screen: the logo, the Del/F9 hints in Russian and English, the Windows loading circle does not touch them, the
  hints are wiped before the system; F6 and F12 at the boot screen open nothing;
- F6 "Reset all to factory": the list of changes without the devices' settings, the reset with a restart (the DASH
  settings in the network card intact), cancelling with "Back", Esc and a right click;
- the "Other" tab and search, "TPM platform hierarchy", the F-key line, the F1 Keys window and the QR codes (they open the
  bot and GitHub), service mode (the stock menu through `SERVICE.TXT`), F12 screenshots, the remembered view, Esc on the
  home screen, Backspace on an item;
- the Health window (lanes, PWM, details on F3) and the F11 report with QR codes;
- DASH: power-on over the network after a shutdown and after the power cord was out.

On the author's board, on earlier T2 test builds (not repeated on the last ones):
- updating from the menu from T1.2;
- core overclocking: 3900 MHz at 1.375 V for 10 minutes under load without errors (this sample does not hold 4000 MHz at
  any voltage); the rollback after three failed starts worked. The protection has been reworked since (Curve Optimizer, an
  earlier start), and in its current form it has not been tested on the board yet;
- a graphics overclock of 1200 MHz / 1.200 V is applied, but the computer froze under graphics load;
- talking to the IT8738 chip: 0 errors in 20,000 exchanges; faster reading of the BIOS chip;
- the new computer name (on Linux), no "irq 7: nobody cared" line;
- our menu in the DASH console: Del, F9, moving through the menu and changing items (saving from the console not tested);
- "Memory for graphics" at 11 GB with 16 GB of memory: Linux sees 11 GB of video memory.

Testers have not tried T2.0 yet; what they checked on T1.2 is in [the tested list](docs/TESTED.md#what-has-been-tested).

### Not tested yet
- **Sleep on the Ryzen 4000G and 5000G with the fix**: we are waiting for owners of these processors
  ([how to help](docs/KNOWN_ISSUES.md#known-issues)).
- Everything that cannot be tried on a Ryzen 3 2200G: graphics overclocking on the Ryzen 4000G/5000G and Athlon, core
  overclocking on the Ryzen 4000G, Curve Optimizer, the limit on 95–105 W processors and "Own power limits (PBO)", the
  temperature limit, power mode and CPPC on the 4000G/5000G, "Memory controller 1:1" and "Infinity Fabric clock", the
  memory settings of the 4000G/5000G, "Memory for graphics" over 16 GB.
- Failed overclock protection in its current form.
- Updating from T1.2 and T1.1r to T2.0 itself and going back from T2.0 to T1.2, on the board (checked only by calculation
  on a computer); updating from T1.1 and T1.
- F9 → starting a disk without a restart, the "The system did not start" window, the BIOS password, Secure Boot, clearing
  the TPM.
- The FAN2 and FAN3 fans (not connected on the author's board), "Pulses per revolution", the fan at start-up.
- The memory delays in Classic and Fine delays, manual speed and XMP without the extra restart, Auto with two different
  sticks.
- The second DisplayPort socket in HDMI mode, the M.2 clock with an NVMe drive, add-in card pages, exFAT sticks.
- The Health window's voltages against a multimeter; Windows activation after the name change.
- DASH: remote power-off and restart on Linux without the kernel parameter, restarting a DASH that went silent, saving
  settings from the console.
- A Ryzen without built-in graphics and no graphics card (after the fix).

## T1.2 — служебные байты CMOS

- **Прошивка больше не верит мусору в памяти CMOS.** Память CMOS (та, что держится на батарейке) хранит и служебные
  байты нашей прошивки: журнал запусков, отметки для отчёта F11 и несколько тестовых команд для разработки. Если плата
  пришла с остатками другой прошивки, случайное значение могло совпасть с такой командой. На одной плате из-за этого
  при каждом включении было три перезапуска подряд, а передние USB и два задних под сетевым разъёмом не работали.
  Теперь прошивка помечает свои байты подписью и при первом запуске, если подписи нет, один раз их стирает.
- После установки журнал запусков в отчёте F11 начнётся заново — это нормально, один раз.
- Больше ничего не менялось: всё остальное как в T1.1r.
- Обновление с T1.1r, T1.1 или T1: из меню с флешки, как обычно ([как обновить](docs/FLASHING.md#обновление)).
  Настройки сохраняются.

## T1.2 — CMOS service bytes

- **The firmware no longer trusts leftovers in CMOS memory.** The battery-backed CMOS memory also holds our firmware's
  service bytes: the boot log, marks for the F11 report and a few test commands for development. When a board came with
  another firmware's leftovers, a random value could match such a command. On one board that meant three restarts in a
  row at every power-on, and the front USB sockets and the two rear ones under the network socket did not work. Now the
  firmware marks its bytes with a signature and, at the first start without one, clears them once.
- After installing, the boot log in the F11 report starts over — that is normal, once.
- Nothing else changed: everything else is as in T1.1r.
- Updating from T1.1r, T1.1 or T1: from the menu with a USB stick, as usual ([how to update](docs/FLASHING.md#updating)).
  Settings are kept.

## T1.1r — перезагрузка на Ryzen 4000G и 5000G

- **Перезагрузка теперь полная на всех процессорах, кроме Ryzen 2000G/3000G и Athlon 200GE/3000G.** В T1.1 она была
  «мягкой», как у Lenovo: процессор сбрасывался не полностью. Ryzen 4000G и 5000G к такому не готовы: на 5000G
  перезагрузка из Windows зависала, а на 4600G после неё Windows тормозила и показывала «Время работы» около 10675199
  дней. Теперь перезагрузка на них полная, как в BIOS Biostar. Для Ryzen 2000G/3000G и Athlon всё осталось как в T1.1.
- Больше ничего не менялось.
- Обновление с T1.1 или T1: из меню с флешки, как обычно ([как обновить](docs/FLASHING.md#обновление)). Настройки
  сохраняются.

## T1.1r — restarts on Ryzen 4000G and 5000G

- **A restart is now a full one on every processor except the Ryzen 2000G/3000G and Athlon 200GE/3000G.** In T1.1 it
  was a "soft" one, as Lenovo has it: the processor was not reset all the way. The Ryzen 4000G and 5000G are not made for
  that: on a 5000G a restart from Windows hung, and on a 4600G Windows slowed down after it and showed an uptime of about
  10675199 days. Now these processors get a full restart, as in Biostar's BIOS. On the Ryzen 2000G/3000G and Athlon
  nothing changed from T1.1.
- Nothing else changed.
- Updating from T1.1 or T1: from the menu with a USB stick, as usual ([how to update](docs/FLASHING.md#updating)).
  Settings are kept.

## T1.1 — исправления к T1

- **Windows снова загружается.** На T1 Windows падала при загрузке с синим экраном ACPI_BIOS_ERROR, а следующий старт
  зависал до выключения кнопкой. Причина — наша правка термозоны ACPI: прошивка превращала её в устройство без
  названия, а Windows такое не принимает. Теперь термозона остаётся термозоной, но не обращается к микросхеме датчиков и
  всегда показывает 0 °C (это заглушка, температуру процессора смотрите по датчику процессора).
- **Контроллер GPIO снова виден системе** (в T1 он был скрыт). В Linux при загрузке снова появляется безвредная строка
  `irq 7: nobody cared`.
- **Меню загрузки F9 запускает флешку сразу**, без перезагрузки, даже если у прошивки ещё нет для неё записи загрузки.
- **«Параметры встроенного ПО UEFI» в Windows** (и `systemctl reboot --firmware-setup` в Linux) открывают наше меню, а не
  родное меню BIOS.
- Обновление с T1: из меню с флешки, как обычно ([как обновить](docs/FLASHING.md#обновление)). Настройки сохраняются.

## T1.1 — fixes for T1

- **Windows boots again.** On T1 Windows stopped at boot with the blue screen ACPI_BIOS_ERROR, and the next start hung
  until the power button was held. The cause was our change to the ACPI thermal zone: the firmware turned it into a
  device with no name, which Windows does not accept. Now the thermal zone stays a thermal zone, but it no longer touches
  the sensor chip and always reads 0 °C (a placeholder; read the processor temperature from the processor's own sensor).
- **The GPIO controller is visible to the system again** (T1 hid it). Linux shows the harmless line
  `irq 7: nobody cared` at boot again.
- **The F9 boot menu starts a USB stick right away**, without a restart, even when the firmware has no boot entry for it
  yet.
- **"UEFI Firmware Settings" in Windows** (and `systemctl reboot --firmware-setup` on Linux) open our menu, not the stock
  BIOS menu.
- Updating from T1: from the menu with a USB stick, as usual ([how to update](docs/FLASHING.md#updating)). Settings are
  kept.

## T1 — первая тестовая версия

### Что нового по сравнению с родным BIOS Lenovo
- Можно ставить процессоры Ryzen вплоть до 5000-й серии (AMD AGESA 1.2.0.F).
- Новое меню настроек (клавиша Del): мышь, русский и английский, поиск, простой режим. Меню выбора загрузки (F9).
- **Обновление BIOS с флешки прямо из меню** (Классика → Безопасность → «Прошивка BIOS»). Ваши настройки, ключ Windows
  и данные TPM сохраняются; перед записью можно сохранить копию всей микросхемы на флешку.
  [Как обновить](docs/FLASHING.md#обновление).
- **Отчёт для диагностики** по клавише F11 — файл на флешке, который прикладывают к сообщению о проблеме.
- **Резервные копии настроек:** видно, на какой версии прошивки снята копия и что именно вернётся.
- Тихий вентилятор с плавными оборотами и своим графиком.
- **Разгон памяти:** частота до DDR4-3200 (Ryzen 1000, 2000, 2000G, 3000G) или до DDR4-3600 (Ryzen 3000, 4000G, 5000,
  5000G), основные задержки, XMP при одинаковых планках с профилем. Если память не заработает, компьютер сам запустится
  на обычной скорости, а меню предложит вернуть «Авто».
- **Режим мощности** для Ryzen 2200G, 2400G, 3200G и 3400G: «Эко» (35 Вт), «Обычный», «Повышенный» (до 88 Вт).
- **Resizable BAR** — один переключатель в меню.
- Включение после пропадания света, сон, включение по будильнику и по сети.
- Видеовыходы настроены как у Lenovo: оба разъёма DisplayPort работают как DisplayPort.
- Исправлены зависания при включении и перезагрузке с Ryzen 3 2200G.
- Загрузка по сети (UEFI).
- **DASH** — удалённое управление (по умолчанию выключено): веб-страница карты, текстовая консоль по сети, настройки сети
  DASH прямо в меню, удалённое включение, выключение и перезагрузка. В Linux для удалённого питания нужен параметр ядра
  `module_blacklist=i2c_piix4` ([подробнее](docs/KNOWN_ISSUES.md)).
- Скрипты для Windows и Linux, которые собирают отчёт о сбоях ([как пользоваться](tools/report/README.md)).

### Ограничения
- Напряжение памяти всегда 1,2 В — так устроена плата ([подробнее](docs/LIMITS.md)).
- Разгон процессора и графики (своя частота и напряжение) закрыт.
- Пароль BIOS пока задаётся только в родном меню (в нашем меню F1 → Security); установка из нашего меню — в следующей
  версии.
- [Известные проблемы](docs/KNOWN_ISSUES.md).

### Что проверено
На плате автора: AM4P2MS ревизии 1.1, Ryzen 3 2200G, две планки по 8 ГБ DDR4-2666.
- Первая установка программатором; обновление из меню туда и обратно с сохранением настроек; копия микросхемы перед
  записью.
- Серии перезагрузок без зависаний, сон и пробуждение по будильнику, включение по будильнику и по сети.
- Оба разъёма DisplayPort (кабель DP→HDMI), заставка и система.
- Отчёт F11, вентилятор под нагрузкой, сеть 1 Гбит/с, USB 3.0.
- DASH: веб-страница, консоль в обе стороны, адрес из меню, удалённые перезагрузка, выключение и включение.

### Что ещё не проверено
- Другие процессоры, четыре планки памяти, XMP, разгон памяти, режимы мощности под нагрузкой, Resizable BAR, видеокарта,
  M.2, Windows.

## T1 — first test version

### What is new compared with Lenovo's BIOS
- Ryzen processors up to the 5000 series can be fitted (AMD AGESA 1.2.0.F).
- A new settings menu (the Del key): mouse, English and Russian, search, a simple view. A boot menu (F9).
- **BIOS updates from a USB stick right from the menu** (Classic → Security → BIOS firmware). Your settings, Windows key
  and TPM data are kept; before writing, a copy of the whole chip can be saved to the stick.
  [How to update](docs/FLASHING.md#updating).
- **Diagnostics report** with the F11 key: a file on a USB stick to attach to a problem report.
- **Settings backups:** shows which firmware version a backup was taken on and exactly what will come back.
- A quiet fan with smooth speed changes and a curve of your own.
- **Memory overclocking:** speed up to DDR4-3200 (Ryzen 1000, 2000, 2000G, 3000G) or DDR4-3600 (Ryzen 3000, 4000G, 5000,
  5000G), the main timings, XMP when all sticks are identical and have a profile. If the memory does not start, the
  computer comes up at the normal speed by itself and the menu offers to go back to Auto.
- **Power mode** for the Ryzen 2200G, 2400G, 3200G and 3400G: Eco (35 W), Normal, Boosted (up to 88 W).
- **Resizable BAR** as a single switch in the menu.
- Power on after a power cut, sleep, power on by alarm and over the network.
- Video outputs set up as Lenovo has them: both DisplayPort sockets work as DisplayPort.
- Fixes for hangs at power-on and reboot with the Ryzen 3 2200G.
- Network boot (UEFI).
- **DASH** remote management (off by default): the card's web page, a text console over the network, DASH network
  settings right in the menu, remote power on, power off and restart. On Linux, remote power needs the kernel parameter
  `module_blacklist=i2c_piix4` ([details](docs/KNOWN_ISSUES.md)).
- Scripts for Windows and Linux that collect a crash report ([how to use them](tools/report/README.md)).

### Limits
- The memory voltage is always 1.2 V, that is how the board is built ([details](docs/LIMITS.md)).
- Processor and graphics overclocking (your own clock and voltage) is closed.
- The BIOS password can so far be set only in the stock menu (F1 → Security from our menu); setting it from our menu comes
  in the next version.
- [Known issues](docs/KNOWN_ISSUES.md).

### Tested
On the author's board: AM4P2MS revision 1.1, Ryzen 3 2200G, two 8 GB DDR4-2666 sticks.
- First install with a programmer; updating from the menu both ways with settings kept; a copy of the chip before writing.
- Series of reboots without hangs, sleep and wake by alarm, power on by alarm and over the network.
- Both DisplayPort sockets (DP→HDMI cable), the boot logo and the system.
- The F11 report, the fan under load, 1 Gbit/s network, USB 3.0.
- DASH: web page, console both ways, address from the menu, remote restart, power off and power on.

### Not tested yet
- Other processors, four memory sticks, XMP, memory overclocking, power modes under load, Resizable BAR, a graphics card,
  M.2, Windows.
