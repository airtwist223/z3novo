#!/usr/bin/env python3
"""Attach an ISO image to a computer with a Realtek DASH network card (Lenovo ThinkCentre M715s with Z3NOVO) over the network.

The computer sees the image as a USB CD/DVD drive. This script serves the file over HTTP from this computer and tells the
card to use it; Ctrl+C detaches it again. Python 3 only, nothing to install; works on Windows, Linux and macOS.

    python3 dash_iso.py CARD_IP IMAGE.iso [--listen THIS_PC_IP] [--port 8080] [--user Administrator] [--password Realtek]

Why a server of its own: the card checks that the file is an ISO by looking for "CD001" in the FIRST network packet of the
reply. Ordinary web servers (Python's http.server among them) often send the headers and the start of the file in two
packets; the card then decides the file is not an ISO and gives up. This server sends each reply in one piece.
"""
import argparse
import hashlib
import http.client
import os
import re
import socket
import socketserver
import sys
import threading
import time
import uuid

CIM = "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/"
NS = ('xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" '
      'xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd" xmlns:wsen="http://schemas.xmlsoap.org/ws/2004/09/enumeration"')


# ---------- the card: WS-Management with digest sign-in ----------

class Card:
    def __init__(self, host, user, password, port=623):
        self.url = f"http://{host}:{port}/wsman"
        self.host, self.port, self.user, self.password = host, port, user, password

    def call(self, uri, action, body, selectors=""):
        env = (f'<?xml version="1.0" encoding="UTF-8"?><s:Envelope {NS}><s:Header><wsa:To>{self.url}</wsa:To>'
               f'<wsman:ResourceURI s:mustUnderstand="true">{uri}</wsman:ResourceURI>'
               '<wsa:ReplyTo><wsa:Address>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:Address></wsa:ReplyTo>'
               f'<wsa:Action s:mustUnderstand="true">{action}</wsa:Action><wsa:MessageID>uuid:{uuid.uuid4()}</wsa:MessageID>'
               f'{selectors}</s:Header><s:Body>{body}</s:Body></s:Envelope>').encode()
        hdr = {"Content-Type": "application/soap+xml;charset=UTF-8"}
        for attempt in range(2):
            c = http.client.HTTPConnection(self.host, self.port, timeout=20)
            c.request("POST", "/wsman", env, hdr)
            r = c.getresponse()
            data = r.read().decode("utf-8", "replace")
            if r.status != 401 or attempt:
                if r.status != 200:
                    raise RuntimeError(f"the card answered HTTP {r.status}" + (" (wrong user or password?)" if r.status == 401 else ""))
                return data
            ch = ",".join(v for k, v in r.getheaders() if k.lower() == "www-authenticate" and v.startswith("Digest"))
            f = dict(re.findall(r'(\w+)\s*="?([^",]*)"?', ch))
            h = lambda x: hashlib.md5(x.encode()).hexdigest()
            cn = uuid.uuid4().hex[:16]
            resp = h(f"{h(self.user + ':' + f['realm'] + ':' + self.password)}:{f['nonce']}:00000001:{cn}:auth:{h('POST:/wsman')}")
            hdr["Authorization"] = (f'Digest username="{self.user}", realm="{f["realm"]}", nonce="{f["nonce"]}", uri="/wsman", '
                                    f'qop=auth, nc=00000001, cnonce="{cn}", response="{resp}"' + (f', opaque="{f["opaque"]}"' if "opaque" in f else ""))
        return data

    def instances(self, cls):
        uri = CIM + cls
        r = self.call(uri, "http://schemas.xmlsoap.org/ws/2004/09/enumeration/Enumerate", "<wsen:Enumerate/>")
        out = []
        ctx = re.search(r"EnumerationContext>([^<]*)<", r)
        while ctx:
            r = self.call(uri, "http://schemas.xmlsoap.org/ws/2004/09/enumeration/Pull",
                          f"<wsen:Pull><wsen:EnumerationContext>{ctx.group(1)}</wsen:EnumerationContext><wsen:MaxElements>20</wsen:MaxElements></wsen:Pull>")
            for m in re.finditer(r"<(\w+:)?%s[ >](.*?)</(\w+:)?%s>" % (cls, cls), r, re.S):
                out.append(dict((k, v) for _, k, v in re.findall(r"<(\w+:)?(\w+)>([^<]*)</", m.group(2))))
            if "EndOfSequence" in r or "Fault" in r:
                break
            ctx = re.search(r"EnumerationContext>([^<]*)<", r)
        return out

    @staticmethod
    def selectors(props):
        keys = ("CreationClassName", "Name", "SystemCreationClassName", "SystemName", "DeviceID", "InstanceID")
        return "<wsman:SelectorSet>" + "".join(f'<wsman:Selector Name="{k}">{props[k]}</wsman:Selector>' for k in keys if k in props) + "</wsman:SelectorSet>"

    def state(self, cls, value, index=None):
        insts = self.instances(cls)
        if index is not None:
            insts = insts[index:index + 1]
        if not insts:
            raise RuntimeError(f"{cls}: the card has no such service (is DASH on and the address right?)")
        for i in insts:
            body = f'<p:RequestStateChange_INPUT xmlns:p="{CIM + cls}"><p:RequestedState>{value}</p:RequestedState></p:RequestStateChange_INPUT>'
            r = self.call(CIM + cls, CIM + cls + "/RequestStateChange", body, self.selectors(i))
            m = re.search(r"ReturnValue>(\d+)<", r)
            if not m or m.group(1) not in ("0", "4096"):
                raise RuntimeError(f"{cls}: the card refused the change ({m.group(1) if m else 'no answer'})")

    def put(self, cls, prop, value):
        insts = self.instances(cls)
        if len(insts) != 1:
            raise RuntimeError(f"{cls}: expected one instance, found {len(insts)}")
        i = dict(insts[0])
        i[prop] = value
        props = "".join(f"<p:{k}>{v}</p:{k}>" for k, v in i.items())
        self.call(CIM + cls, "http://schemas.xmlsoap.org/ws/2004/09/transfer/Put", f'<p:{cls} xmlns:p="{CIM + cls}">{props}</p:{cls}>', self.selectors(insts[0]))


# ---------- the HTTP server: ranges, one send per reply ----------

def make_handler(path, quiet):
    name = os.path.basename(path)
    size = os.path.getsize(path)
    sent = [0]

    class Handler(socketserver.BaseRequestHandler):
        def handle(self):
            s = self.request
            s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            buf = b""
            while True:
                try:
                    while b"\r\n\r\n" not in buf:
                        d = s.recv(65536)
                        if not d:
                            return
                        buf += d
                except OSError:
                    return
                head, buf = buf.split(b"\r\n\r\n", 1)
                lines = head.decode("latin-1").split("\r\n")
                parts = lines[0].split()
                hdr = {k.strip().lower(): v.strip() for k, v in (ln.split(":", 1) for ln in lines[1:] if ":" in ln)}
                if len(parts) < 2 or parts[0] not in ("GET", "HEAD") or os.path.basename(parts[1].split("?")[0]) != name:
                    s.sendall(b"HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n")
                    continue
                m = re.match(r"bytes=(\d*)-(\d*)$", hdr.get("range", ""))
                if m and (m.group(1) or m.group(2)):
                    a = int(m.group(1)) if m.group(1) else max(0, size - int(m.group(2)))
                    b = min(int(m.group(2)) if m.group(1) and m.group(2) else size - 1, size - 1)
                    if a > b:
                        s.sendall(b"HTTP/1.1 416 Range Not Satisfiable\r\nContent-Length: 0\r\n\r\n")
                        continue
                    status, extra = "206 Partial Content", "Content-Range: bytes %d-%d/%d\r\n" % (a, b, size)
                else:
                    a, b, status, extra = 0, size - 1, "200 OK", ""
                body = b""
                if parts[0] == "GET":
                    with open(path, "rb") as f:
                        f.seek(a)
                        body = f.read(b - a + 1)
                keep = hdr.get("connection", "").lower() != "close"
                out = ("HTTP/1.1 %s\r\n%sAccept-Ranges: bytes\r\nContent-Type: application/octet-stream\r\nContent-Length: %d\r\n"
                       "Connection: %s\r\n\r\n" % (status, extra, b - a + 1, "keep-alive" if keep else "close")).encode()
                s.sendall(out + body)  # headers and data together: the card's ISO check reads only the first packet
                sent[0] += len(body)
                if not keep:
                    return

    return Handler, sent


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def local_address(card):
    """This computer's address on the way to the card."""
    u = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        u.connect((card, 623))
        return u.getsockname()[0]
    finally:
        u.close()


def main():
    ap = argparse.ArgumentParser(description="Attach an ISO image over DASH (Realtek RTL8111EP, Lenovo M715s with Z3NOVO).")
    ap.add_argument("card", help="the DASH card's IP address")
    ap.add_argument("iso", help="the ISO image to attach")
    ap.add_argument("--listen", help="this computer's IP address as the card should reach it (found by itself if left out)")
    ap.add_argument("--port", type=int, default=8080, help="the port to serve the image on (default 8080)")
    ap.add_argument("--user", default="Administrator")
    ap.add_argument("--password", default="Realtek")
    o = ap.parse_args()
    if not os.path.isfile(o.iso):
        sys.exit(f"no such file: {o.iso}")
    with open(o.iso, "rb") as f:
        f.seek(0x8001)
        if f.read(5) != b"CD001":
            sys.exit("this file is not an ISO 9660 image (no CD001 at 0x8001); the card only attaches ISO images")
    me = o.listen or local_address(o.card)
    handler, sent = make_handler(os.path.abspath(o.iso), False)
    srv = Server((me, o.port), handler)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    url = f"http://{me}:{o.port}/{os.path.basename(o.iso)}"
    card = Card(o.card, o.user, o.password)
    print(f"serving {url}")
    card.put("CIM_RemoteServiceAccessPoint", "AccessInfo", url)
    card.state("CIM_USBRedirectionService", 2)
    card.state("CIM_USBRedirectionSAP", 2, index=0)
    print("attached: the computer should now see a USB CD/DVD drive. Ctrl+C detaches the image.")
    try:
        while True:
            time.sleep(5)
            print(f"\r  read by the card so far: {sent[0] / (1024 * 1024):.1f} MB ", end="", flush=True)
    except KeyboardInterrupt:
        print()
    finally:
        try:
            card.state("CIM_USBRedirectionSAP", 3, index=0)
            print("detached")
        except Exception as e:
            print(f"could not detach: {e}")
        srv.shutdown()


if __name__ == "__main__":
    main()
