# Установка, обновление, откат / Installing, updating, going back

## Первая установка — только программатором

Заводская прошивка Lenovo не примет чужой образ, поэтому первый раз Z3NOVO пишется программатором прямо в микросхему.

**Микросхема BIOS — Winbond W25Q128FW, 16 МБ, питание 1,8 В.** Обычный программатор CH341A без переходника на 1,8 В может
её испортить. Нужны:

- программатор CH341A или CH347 (с CH347 работает `flashrom -p ch347_spi`);
- **переходник на 1,8 В** (обязательно);
- прищепка SOIC-8;
- flashrom 1.4 или новее (имя микросхемы в flashrom — `W25Q128.W`).

Шаги:

1. Выключите компьютер и выньте шнур питания из розетки. **Никогда не подавайте питание на плату, пока подключены
   прищепка и переходник.** Читать и писать микросхему можно на обесточенной плате.
2. Найдите микросхему BIOS (обозначение на плате — U53, надпись 25Q128FW). Ножка 1 отмечена точкой на корпусе:
   к ней — провод 1 прищепки (обычно красный).
3. **Сначала сохраните свою прошивку.** Прочитайте микросхему два-три раза и сравните файлы — они должны совпасть:
   ```
   flashrom -p ch341a_spi -c W25Q128.W -r backup1.bin
   flashrom -p ch341a_spi -c W25Q128.W -r backup2.bin
   cmp backup1.bin backup2.bin
   ```
   Храните эту копию: это ваш путь назад к прошивке Lenovo. **В ней ваш серийный номер и ключ Windows — никому её
   не отправляйте.**
4. Запишите образ Z3NOVO (flashrom проверит запись сам):
   ```
   flashrom -p ch341a_spi -c W25Q128.W -w Z3NOVO_T1.bin
   ```
5. Снимите прищепку, вставьте шнур, включите. **Первый запуск после записи может сам перезапуститься 2–4 раза**:
   прошивка готовит настройки и тренирует память. Это нормально.

Если программатор не видит микросхему (ID из одних FF или 00), поправьте прищепку. Если ID читается сдвинутым или
файлы не совпадают, переподключите программатор к USB.

## Обновление

Начиная с T1 — из приложения настроек: «Обновить прошивку», файл с USB-флешки (в работе; инструкция будет здесь,
когда функцию проверят на плате). Настройки, ключи и данные платы при таком обновлении сохраняются.

## Откат

На заводскую прошивку Lenovo — программатором, записью своей сохранённой копии (шаг 3):
```
flashrom -p ch341a_spi -c W25Q128.W -w backup1.bin
```

---

# Installing, updating, going back

## First install: programmer only

Lenovo's firmware does not accept a foreign image, so the first install of Z3NOVO is written straight into the chip
with a programmer.

**The BIOS chip is a Winbond W25Q128FW, 16 MB, powered at 1.8 V.** A plain CH341A programmer without a 1.8 V adapter
can damage it. You need:

- a CH341A or CH347 programmer (with the CH347 use `flashrom -p ch347_spi`);
- **a 1.8 V adapter** (required);
- a SOIC-8 clip;
- flashrom 1.4 or newer (the chip is called `W25Q128.W` in flashrom).

Steps:

1. Shut the computer down and unplug the power cord. **Never power the board while the clip and adapter are
   connected.** The chip can be read and written with the board unpowered.
2. Find the BIOS chip (marked U53 on the board, labelled 25Q128FW). Pin 1 is marked with a dot on the chip: wire 1 of
   the clip (usually red) goes there.
3. **Save your own firmware first.** Read the chip two or three times and compare the files; they must match:
   ```
   flashrom -p ch341a_spi -c W25Q128.W -r backup1.bin
   flashrom -p ch341a_spi -c W25Q128.W -r backup2.bin
   cmp backup1.bin backup2.bin
   ```
   Keep this copy: it is your way back to Lenovo's firmware. **It holds your serial number and Windows key, so never
   send it to anyone.**
4. Write the Z3NOVO image (flashrom verifies the write itself):
   ```
   flashrom -p ch341a_spi -c W25Q128.W -w Z3NOVO_T1.bin
   ```
5. Remove the clip, plug the cord back in and power on. **The first start after a write may restart by itself 2–4
   times** while the firmware prepares its settings and trains the memory. That is normal.

If the programmer does not see the chip (an ID of all FF or 00), reseat the clip. If the ID reads shifted or the files
differ, replug the programmer's USB.

## Updating

From T1 on: from the settings app, "Update firmware", with the file on a USB stick (in progress; the instructions will
be here once the feature has been tested on a board). Settings, keys and board data are kept by such an update.

## Going back

To Lenovo's firmware: with the programmer, by writing your saved copy (step 3):
```
flashrom -p ch341a_spi -c W25Q128.W -w backup1.bin
```
