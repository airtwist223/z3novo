# Подключение ISO через DASH / Attaching an ISO over DASH

Скрипт `dash_iso.py` подключает образ ISO к компьютеру с картой DASH (Lenovo M715s с Z3NOVO) по сети. Компьютер видит
его как USB-привод CD/DVD: с него можно, например, поставить систему, не подходя к компьютеру.

**Что нужно**
- В нашем меню включён DASH и задан его адрес (Классика → Устройства → DASH).
- Второй компьютер в той же сети, на нём Python 3 (Windows, Linux или macOS).
- Образ в формате ISO.

**Как**
```
python3 dash_iso.py 192.168.1.50 install.iso
```
`192.168.1.50` — адрес карты DASH. Пока скрипт работает, образ подключён; **Ctrl+C** отключает его.
Если у карты свой логин и пароль: `--user` и `--password` (по умолчанию заводские Administrator / Realtek).
Если брандмауэр спросит про Python — разрешите (скрипт раздаёт образ на порту 8080, сменить: `--port`).

**Почему не обычный веб-сервер.** Карта проверяет, что файл — ISO, только по первому сетевому пакету ответа. Обычные
серверы (в том числе `python3 -m http.server`) часто шлют заголовки и начало файла двумя пакетами, и карта бросает
подключение. Этот скрипт шлёт каждый ответ одним куском.

Образ читается по сети, поэтому установка системы идёт медленнее, чем с флешки.

---

`dash_iso.py` attaches an ISO image over the network to a computer with a DASH card (a Lenovo M715s with Z3NOVO). The
computer sees it as a USB CD/DVD drive: you can, for example, install a system without going to the computer.

**You need**
- DASH turned on in our menu and its address set (Classic → Devices → DASH).
- A second computer on the same network with Python 3 (Windows, Linux or macOS).
- An ISO image.

**How**
```
python3 dash_iso.py 192.168.1.50 install.iso
```
`192.168.1.50` is the DASH card's address. The image stays attached while the script runs; **Ctrl+C** detaches it.
If the card has its own sign-in: `--user` and `--password` (factory default Administrator / Realtek).
If the firewall asks about Python, allow it (the script serves the image on port 8080; change it with `--port`).

**Why not an ordinary web server.** The card checks that the file is an ISO only in the first network packet of the
reply. Ordinary servers (`python3 -m http.server` among them) often send the headers and the start of the file in two
packets, and the card gives up. This script sends each reply in one piece.

The image is read over the network, so installing a system is slower than from a USB stick.
