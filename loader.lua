-- Crack the Geode! loader v2. Validates downloads before replacing the cached hub.
if not game:IsLoaded()then game.Loaded:Wait()end
if game.GameId~=10770110947 then warn("[Geode Hub] This loader is for Crack the Geode!");return end
local path="GeodeHub/main.lua"
local backup="GeodeHub/main.backup.lua"
local url="https://raw.githubusercontent.com/sceneton/geode/main/main.lua"
local function validateGeodeHubSource(source)
    if type(source)~="string"or #source<4000 then return nil,"empty or incomplete source"end
    for _,marker in ipairs({"-- Beyy Geode Hub | Crack the Geode!","createNativeUI","Auto Geode Pickup","return Hub"})do
        if not source:find(marker,1,true)then return nil,"hub marker missing: "..marker end
    end
    local fn,err=loadstring(source)
    if not fn then return nil,"compile failed: "..tostring(err)end
    return fn
end
local function readSource(file)
    local ok,source=pcall(readfile,file)
    if not ok then return nil end
    return source
end
local onlineOK,online=pcall(function()return game:HttpGet(url.."?refresh="..tostring(os.time()))end)
local compiled,reason=validateGeodeHubSource(onlineOK and online or nil)
local source,origin
if compiled then
    source=online;origin="online"
    pcall(function()
        if not isfolder("GeodeHub")then makefolder("GeodeHub")end
        local old=readSource(path)
        if validateGeodeHubSource(old)then writefile(backup,old)
        elseif not validateGeodeHubSource(readSource(backup))then writefile(backup,source)end
        writefile(path,source)
    end)
else
    source=readSource(path);compiled=validateGeodeHubSource(source);origin="cache"
    if not compiled then
        source=readSource(backup);compiled=validateGeodeHubSource(source);origin="backup"
        if compiled then pcall(writefile,path,source)end
    end
end
if not compiled then warn("[Geode Hub] No valid online, cached or backup hub. Online source: "..tostring(reason));return end
print("[Geode Hub] Loading "..origin.." source ("..#source.." bytes)")
local ok,result=pcall(compiled)
if not ok then warn("[Geode Hub] Startup failed: "..tostring(result));return end
if type(result)~="table"or result.Running~=true then warn("[Geode Hub] Startup returned without a running hub; check module-load messages.")end
return result