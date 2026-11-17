#!/usr/bin/env python3
"""
Surenka visus src/ failus į vieną Roblox place failą CepelinuGamykla.rbxlx.

Failų pavadinimai:
  *.module.lua  -> ModuleScript
  *.server.lua  -> Script
  *.client.lua  -> LocalScript
  aplankas      -> Folder
Paleidimas:  python3 tools/build.py
"""
import os
import sys
from xml.sax.saxutils import escape

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src")
OUT = os.path.join(ROOT, "CepelinuGamykla.rbxlx")

REMOTE_EVENTS = [
    "Notify", "ItemSold", "MachineBuilt", "EventStarted", "EventEnded",
    "BigCepelinasBurst", "ChangeSetting", "OpenWindow", "TutorialDone", "RebirthDone", "Knockback",
    "QuizStart", "QuizAnswer", "QuizResult", "ContestUpdate", "ContestJoin",
]
REMOTE_FUNCTIONS = ["RequestRebirth", "ClaimDaily", "RadioControl"]

_ref = [0]


def ref():
    _ref[0] += 1
    return "RBX%d" % _ref[0]


def cdata(text):
    # "]]>" negali būti CDATA viduje – suskaldom
    return "<![CDATA[" + text.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def item(cls, name, children="", extra=""):
    return ('<Item class="%s" referent="%s"><Properties><string name="Name">%s</string>%s</Properties>%s</Item>\n'
            % (cls, ref(), escape(name), extra, children))


def script_item(path):
    base = os.path.basename(path)
    with open(path, encoding="utf-8") as f:
        source = f.read()
    for suffix, cls in ((".module.lua", "ModuleScript"), (".server.lua", "Script"), (".client.lua", "LocalScript")):
        if base.endswith(suffix):
            name = base[: -len(suffix)]
            return item(cls, name, extra='<ProtectedString name="Source">%s</ProtectedString>' % cdata(source))
    return ""


def folder_children(path):
    out = []
    for entry in sorted(os.listdir(path)):
        full = os.path.join(path, entry)
        if os.path.isdir(full):
            out.append(item("Folder", entry, folder_children(full)))
        elif entry.endswith(".lua"):
            out.append(script_item(full))
    return "".join(out)


def main():
    remotes = "".join(item("RemoteEvent", n) for n in REMOTE_EVENTS)
    remotes += "".join(item("RemoteFunction", n) for n in REMOTE_FUNCTIONS)

    rs_children = folder_children(os.path.join(SRC, "ReplicatedStorage")) + item("Folder", "Remotes", remotes)
    sss_children = folder_children(os.path.join(SRC, "ServerScriptService"))
    templates = item("Folder", "Templates", item("Model", "Plot") + item("Folder", "Machines") + item("Folder", "Items"))
    sps_children = folder_children(os.path.join(SRC, "StarterPlayer", "StarterPlayerScripts"))

    body = ""
    body += item("Workspace", "Workspace", extra='<bool name="StreamingEnabled">false</bool>')
    body += item("Lighting", "Lighting", extra='<float name="ClockTime">14.5</float><float name="Brightness">2</float>')
    body += item("ReplicatedStorage", "ReplicatedStorage", rs_children)
    body += item("ServerScriptService", "ServerScriptService", sss_children)
    body += item("ServerStorage", "ServerStorage", templates)
    body += item("StarterPlayer", "StarterPlayer", item("StarterPlayerScripts", "StarterPlayerScripts", sps_children))
    body += item("StarterGui", "StarterGui")
    body += item("TextChatService", "TextChatService", extra='<token name="ChatVersion">1</token>')

    xml = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
           'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
           'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">\n'
           + body + "</roblox>\n")
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(xml)
    print("Sukurta:", OUT, "(%d KB)" % (len(xml.encode("utf-8")) // 1024))


if __name__ == "__main__":
    sys.exit(main())
