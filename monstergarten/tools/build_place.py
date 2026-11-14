import os,sys,itertools
root=sys.argv[1]; out=sys.argv[2]
ref=itertools.count(1)
def esc(s): return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
def item(cls,name,props="",children=""):
    return f'<Item class="{cls}" referent="RBX{next(ref)}"><Properties><string name="Name">{esc(name)}</string>{props}</Properties>{children}</Item>\n'
def script(cls,name,path):
    src=open(path,encoding="utf-8").read()
    return f'<ProtectedString name="Source"><![CDATA[{src}]]></ProtectedString>'
def build_dir(path):
    # returns xml for children of a directory (Rojo rules)
    out=""
    for f in sorted(os.listdir(path)):
        p=os.path.join(path,f)
        if os.path.isdir(p):
            init=os.path.join(p,"init.lua")
            if os.path.exists(init):
                out+=item("ModuleScript",f,script("ModuleScript",f,init),build_dir_skip_init(p))
            else:
                out+=item("Folder",f,"",build_dir(p))
        elif f.endswith(".server.lua"):
            out+=item("Script",f[:-11],script("Script",f,p))
        elif f.endswith(".client.lua"):
            out+=item("LocalScript",f[:-11],script("LocalScript",f,p))
        elif f.endswith(".lua") and f!="init.lua":
            out+=item("ModuleScript",f[:-4],script("ModuleScript",f,p))
    return out
def build_dir_skip_init(p): return build_dir(p)
src=os.path.join(root,"src")
assets=item("Folder","Assets","",item("Folder","Babies")+item("Folder","Parents")+item("Folder","NPCs")+item("Folder","Icons"))
xml='<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">\n'
xml+=item("Workspace","Workspace",'<bool name="StreamingEnabled">true</bool><float name="Gravity">196.2</float>')
xml+=item("Lighting","Lighting",'<token name="Technology">4</token><float name="ClockTime">18.5</float>')
xml+=item("ReplicatedStorage","ReplicatedStorage","",item("Folder","Shared","",build_dir(os.path.join(src,"shared")))+assets)
xml+=item("ServerScriptService","ServerScriptService","",item("Folder","Server","",build_dir(os.path.join(src,"server"))))
xml+=item("ServerStorage","ServerStorage","",item("Folder","Maps"))
xml+=item("StarterPlayer","StarterPlayer",'<float name="CameraMaxZoomDistance">40</float><float name="CharacterWalkSpeed">16</float>',
          item("StarterPlayerScripts","StarterPlayerScripts","",item("Folder","Client","",build_dir(os.path.join(src,"client")))))
xml+=item("SoundService","SoundService",'<bool name="RespectFilteringEnabled">true</bool>')
xml+="</roblox>\n"
open(out,"w",encoding="utf-8").write(xml)
print("items:",next(ref)-1)
