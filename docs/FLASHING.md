# Установка, обновление и возврат / Installing, updating and going back

> Устанавливая прошивку, вы принимаете [отказ от ответственности](../README.md#отказ-от-ответственности): всё делаете сами и на свой риск.

## Первая установка

**Сначала посмотрите ревизию платы.** Она напечатана на плате рядом с названием AM4P2MS (надпись вида «Ver 1.1»).
Прошивка проверена только на ревизии 1.1. На других ревизиях устанавливайте только на свой страх и риск и будьте готовы
вернуть родной BIOS программатором.

Родной BIOS Lenovo не даст поставить чужую прошивку обычным способом. Поэтому в первый раз её записывают
**программатором**: это небольшое USB-устройство, которое прищепкой цепляют прямо к микросхеме BIOS на плате.
Если вы никогда этого не делали, попросите помочь знакомого, который умеет.

### Что понадобится

- **Программатор CH341A** (или CH347) — продаётся в радиомагазинах и на маркетплейсах.
- **Переходник на 1,8 В — обязательно.** Микросхема BIOS на этой плате работает от 1,8 В, а программатор без переходника
  подаёт 3,3 В и может её сжечь.
- **Прищепка SOIC-8** — обычно продаётся в наборе с программатором.
- **Программа для записи.** Мы пользуемся flashrom (Linux); на Windows есть похожие программы, например AsProgrammer,
  но их мы не проверяли.

Микросхема: Winbond W25Q128FW, 16 МБ. На плате она подписана U53. В flashrom она называется `W25Q128.W`.

### Шаги

1. **Выключите компьютер и выньте шнур из розетки.** Пока прищепка подключена, питание на плату не подавайте.
   Читать и записывать микросхему можно на выключенной плате.
2. **Подключите прищепку к микросхеме U53.** Первая ножка микросхемы отмечена точкой на корпусе; к ней — первый
   провод прищепки (обычно красный).
3. **Сохраните свой родной BIOS.** Прочитайте микросхему два-три раза и сравните файлы, они должны совпасть:
   ```
   flashrom -p ch341a_spi -c W25Q128.W -r backup1.bin
   flashrom -p ch341a_spi -c W25Q128.W -r backup2.bin
   cmp backup1.bin backup2.bin
   ```
   Берегите эту копию: это ваш путь назад к родному BIOS. **В ней ваш серийный номер и ключ Windows — никому её
   не отправляйте.**
4. **Запишите Z3NOVO** (flashrom сам проверит запись):
   ```
   flashrom -p ch341a_spi -c W25Q128.W -w Z3NOVO_T2.1.bin
   ```
5. **Снимите прищепку, вставьте шнур, включите.** Первый раз компьютер может сам перезагрузиться 2–4 раза, пока
   прошивка готовит настройки и проверяет память. Это нормально, подождите.

Если программатор не видит микросхему, поправьте прищепку. Если две копии не совпадают — переподключите программатор к USB
и прочитайте ещё раз.

## Обновление

С версии T1 BIOS обновляется прямо из меню, без программатора. Ваши настройки, ключ Windows и данные TPM сохраняются.

1. Скачайте новый образ и его контрольную сумму (`.sha256`). Положите оба файла на флешку FAT32 в папку `Z3NOVO`
   (или в корень флешки).
2. Включите компьютер, нажмите **Del**, откройте **Классика → Безопасность → «Прошивка BIOS» → «Обновить прошивку»**.
3. Выберите файл. Меню проверит, что это образ Z3NOVO для этой платы и что файл цел (совпадает с `.sha256`), и покажет
   его версию и сколько блоков изменится. Чужие образы (родной BIOS Lenovo, AFOX, Biostar) меню записывать откажется.
4. Включите **копию микросхемы на флешку**: если что-то пойдёт не так, по ней всё можно вернуть программатором.
5. Подтвердите и дождитесь конца записи. **Не выключайте компьютер во время записи.** Сам он не перезагрузится —
   меню скажет, что запись закончена и проверена.
6. Перезагрузите компьютер и откройте меню: версия видна в его заголовке.

Ставить можно любую версию Z3NOVO — и новее, и старее нынешней. Вернуть родной BIOS Lenovo можно только
программатором (см. ниже).

**Перед обновлением с T2.0 или T1.x уберите с флешки старые копии.** Меню этих версий не увидит новый файл, если в папке
`\Z3NOVO` на флешке 24 и больше файлов `.BIN`: при каждом обновлении меню кладёт туда копию `Z3BACKUP-….BIN`, и они
копятся. Перенесите старые копии из `\Z3NOVO` на компьютер (последнюю лучше сохранить у себя) или возьмите флешку без
них. С T2.1 меню видит до 64 файлов, файлы из корня флешки показывает первыми, а копии — в конце.

### С T2.0 на T2.1

Обновляйтесь из меню, как описано выше. Что важно знать:

- **Настройки сохраняются.** Новое стоит на заводских значениях: «Минимум» у всех трёх вентиляторов — 20 %, у FAN2 и
  FAN3 режим тот же, что был. Новые «Тихо» вентилятора процессора и «Тихо»/«Авто» корпусных действуют сразу.
- **Своя кривая не меняется.** Если вы рисовали свою кривую вентилятора процессора по старому «Тихо», новое «Тихо» к
  ней само не придёт: выберите «Тихо» заново или перерисуйте кривую.
- **Коды устройств.** При первом запуске Windows может заново найти графику, USB-контроллеры и SATA чипсета (у них
  теперь код Lenovo): экран может мигнуть, разрешение — сброситься, может встать стандартный видеодрайвер — тогда переустановите драйвер AMD. Это один раз. Если перед прошивкой Windows выключали обычным «Завершением работы» (включён быстрый запуск), после прошивки она может восстановить прежний сеанс, и программы покажут старую версию BIOS и старые коды устройств: сделайте один раз «Перезагрузку». Сетевая карта и NVMe не меняются.
- **Перед обновлением** уберите с флешки старые копии `Z3BACKUP` — см. абзац выше: иначе меню T2.0 может не увидеть
  файл T2.1.
- **С T1.2 или T1.1r** — тем же путём; всё, что сказано в следующем разделе про переход на T2.0, относится и сюда.

### С T1.2 или T1.1r на T2.0

Обновляйтесь из меню, как описано выше. Что важно знать:

- **Первый запуск** на несколько секунд дольше: прошивка заново обучает память. Компьютер может один раз
  перезапуститься сам. Это один раз.
- **Настройки сохраняются.** Новое в T2.0 стоит на заводских значениях: «Защита от неудачного разгона» выключена,
  процессоры на 95–105 Вт ограничены классом 65 Вт, вентиляторы FAN2 и FAN3 — «Авто».
- **Новое имя компьютера.** Windows увидит компьютер как Z3NOVO Labs ThinkCentre M715s Reborn и может один раз попросить
  подтвердить активацию ([что делать](KNOWN_ISSUES.md)).
- **С T1.1 и T1** путь тот же, но переход сразу на T2.0 мы не проверяли.

Переход с T1.2 и T1.1r на T2.0 проверен расчётом на компьютере (тот же план записи, что строит меню); на плате автора —
обновление с T1.2 на раннюю пробную сборку T2.

## Возврат на прежнюю версию Z3NOVO

Тем же путём из меню: «Обновить прошивку» → файл прежней версии (например, `Z3NOVO_T2.0.bin` или `Z3NOVO_T1.2.bin` со
страниц выпусков [T2.0](https://github.com/airtwist223/z3novo/releases/tag/T2.0) и
[T1.2](https://github.com/airtwist223/z3novo/releases/tag/T1.2)). Перед возвратом с T2.x на T1.x:

- верните разгон процессора и графики на «Авто» и выключите «Свои пределы мощности (PBO)»: в T1.x нет ни защиты от
  неудачного разгона, ни ограничения процессоров на 95–105 Вт.

С T2.1 на T2.0: свои кривые FAN2 и FAN3 и «Минимум» T2.0 не знает и не видит. Если своя кривая вентилятора процессора
где-то опускается ниже 20 %, T2.0 сочтёт её неверной и возьмёт обычный режим — громче, а не тише. Коды устройств
вернутся к Biostar, и Windows может ещё раз заново найти устройства.

После возврата на T1.x компьютер снова называется именем платы Biostar. Возврат с T2.0 на T1.2 мы проверили только
расчётом на компьютере; на плате автора проверен возврат с последней пробной сборки T2 на предыдущую и обратно. Если после
записи меню не открывается, запишите программатором копию микросхемы, которую меню сохранило на флешку перед
обновлением.

## Возврат к родному BIOS

Тем же программатором запишите свою сохранённую копию (шаг 3):
```
flashrom -p ch341a_spi -c W25Q128.W -w backup1.bin
```

---

# Installing, updating and going back

> By installing the firmware you accept the [disclaimer](../README.md#disclaimer): you do everything yourself and at your own risk.

## First install

**Check the board revision first.** It is printed on the board next to the name AM4P2MS (something like "Ver 1.1").
The firmware has been tested only on revision 1.1. On other revisions install it only at your own risk, and be ready to
put Lenovo's BIOS back with the programmer.

Lenovo's BIOS will not let you install other firmware the usual way. So the first time it is written with a
**programmer**: a small USB device that clips straight onto the BIOS chip on the board. If you have never done this,
ask a friend who has.

### What you need

- **A CH341A programmer** (or CH347), sold in electronics shops and online.
- **A 1.8 V adapter — required.** The BIOS chip on this board runs at 1.8 V, and the programmer without the adapter puts
  out 3.3 V, which can burn it.
- **A SOIC-8 clip**, usually sold together with the programmer.
- **A program to write the chip.** We use flashrom (Linux); Windows has similar programs such as AsProgrammer, but we
  have not tested them.

The chip: Winbond W25Q128FW, 16 MB. It is marked U53 on the board. flashrom calls it `W25Q128.W`.

### Steps

1. **Shut the computer down and unplug the power cord.** Never power the board while the clip is attached. The chip can
   be read and written with the board unpowered.
2. **Clip onto the chip U53.** Pin 1 of the chip is marked with a dot on its body; the clip's first wire (usually red)
   goes there.
3. **Save your Lenovo BIOS.** Read the chip two or three times and compare the files; they must match:
   ```
   flashrom -p ch341a_spi -c W25Q128.W -r backup1.bin
   flashrom -p ch341a_spi -c W25Q128.W -r backup2.bin
   cmp backup1.bin backup2.bin
   ```
   Keep this copy: it is your way back to Lenovo's BIOS. **It holds your serial number and Windows key, so never send it
   to anyone.**
4. **Write Z3NOVO** (flashrom checks the write itself):
   ```
   flashrom -p ch341a_spi -c W25Q128.W -w Z3NOVO_T2.1.bin
   ```
5. **Remove the clip, plug the cord back in, power on.** The first time, the computer may restart by itself 2–4 times
   while the firmware prepares its settings and checks the memory. That is normal; wait.

If the programmer does not see the chip, reseat the clip. If the two copies differ, replug the programmer's USB and read
again.

## Updating

From T1 on, the BIOS is updated right from the menu, with no programmer. Your settings, Windows key and TPM data are kept.

1. Download the new image and its checksum (`.sha256`). Put both files on a FAT32 USB stick, in a `Z3NOVO` folder (or in
   the stick's root).
2. Power on, press **Del**, open **Classic → Security → BIOS firmware → Update firmware**.
3. Pick the file. The menu checks that it is a Z3NOVO image for this board and that the file is intact (matches the
   `.sha256`), and shows its version and how many blocks will change. It refuses other images (Lenovo's BIOS, AFOX,
   Biostar).
4. Turn on **a copy of the chip to the stick**: if anything goes wrong, everything can be put back from it with a
   programmer.
5. Confirm and wait for the write to finish. **Do not switch the computer off while it writes.** It does not restart by
   itself; the menu says when the write is done and checked.
6. Restart and open the menu: the version is shown in its header.

Any Z3NOVO version can be installed, newer or older than the current one. Lenovo's BIOS can only be put back with a
programmer (see below).

**Before updating from T2.0 or T1.x, clear the old copies off the stick.** The menu of these versions does not see the
new file when the stick's `\Z3NOVO` folder holds 24 or more `.BIN` files: at every update the menu puts a
`Z3BACKUP-….BIN` copy there, and they pile up. Move the old copies from `\Z3NOVO` to a computer (better keep the latest
one) or use a stick without them. From T2.1 the menu sees up to 64 files, shows the files in the stick's root first and
the copies last.

### From T2.0 to T2.1

Update from the menu as described above. What to know:

- **Settings are kept.** What is new starts at its factory values: the minimum of all three fans is 20 %, FAN2 and FAN3
  keep the mode they had. The processor fan's new Quiet and the case fans' new Quiet and Auto apply at once.
- **A custom curve does not change.** If you drew your own processor fan curve after the old Quiet, the new Quiet does
  not reach it by itself: pick Quiet again or redraw the curve.
- **Device IDs.** At the first start Windows may find the graphics, the USB controllers and the chipset's SATA anew (they
  now carry Lenovo's ID): the screen may blink, the resolution may reset, Windows may put in its standard display driver (then reinstall AMD's driver). That happens once. If Windows was turned off with a plain Shut down before flashing (Fast Startup on), after flashing it may bring back its old session, and programs will show the old BIOS version and the old device IDs: restart Windows once. The network card and NVMe
  do not change.
- **Before updating**, clear the old `Z3BACKUP` copies off the stick (see the paragraph above): otherwise T2.0's menu may
  not see the T2.1 file.
- **From T1.2 or T1.1r**, the same way; everything the next section says about going to T2.0 applies here too.

### From T1.2 or T1.1r to T2.0

Update from the menu as described above. What to know:

- **The first start** takes a few seconds longer: the firmware trains the memory anew. The computer may restart once by
  itself. That happens once.
- **Settings are kept.** What is new in T2.0 starts at its factory values: Failed overclock protection is off, 95–105 W
  processors are limited to the 65 W class, the FAN2 and FAN3 fans are on Auto.
- **A new computer name.** Windows will see the computer as a Z3NOVO Labs ThinkCentre M715s Reborn and may ask once to
  confirm activation ([what to do](KNOWN_ISSUES.md#known-issues)).
- **From T1.1 and T1** the way is the same, but we have not tested going straight to T2.0 from them.

Going from T1.2 and T1.1r to T2.0 has been checked by calculation on a computer (the same write plan the menu builds); on
the author's board, updating from T1.2 to an early T2 test build.

## Going back to an earlier Z3NOVO version

The same way, from the menu: Update firmware → the earlier version's file (for example `Z3NOVO_T2.0.bin` or
`Z3NOVO_T1.2.bin` from the [T2.0](https://github.com/airtwist223/z3novo/releases/tag/T2.0) and
[T1.2](https://github.com/airtwist223/z3novo/releases/tag/T1.2) release pages). Before going back from T2.x to T1.x:

- set the processor and graphics overclock back to Auto and turn "Own power limits (PBO)" off: T1.x has neither the
  protection against a failed overclock nor the limit on 95–105 W processors.

From T2.1 to T2.0: T2.0 does not know the FAN2 and FAN3 custom curves or the minimums and does not see them. If your
custom processor fan curve goes under 20 % anywhere, T2.0 takes it for a broken one and uses the usual mode: louder, not
quieter. The device IDs go back to Biostar's, and Windows may find the devices anew once more.

After going back to T1.x, the computer goes by the Biostar board's name again. Going back from T2.0 to T1.2 we have
checked only by calculation on a computer; on the author's board, going from the last T2 test build back to the previous one and
forward again has been tested. If the menu does not open after the write, write with a programmer the copy of the chip
the menu saved to the stick before the update.

## Going back to Lenovo's BIOS

Write your saved copy (step 3) with the same programmer:
```
flashrom -p ch341a_spi -c W25Q128.W -w backup1.bin
```
