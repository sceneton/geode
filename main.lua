-- Beyy Geode Hub | Crack the Geode! | native menu and range-limited pickup
if not game:IsLoaded()then game.Loaded:Wait()end
if game.GameId~=10770110947 then warn("[Geode Hub] This script is for Crack the Geode!");return end
local env=getgenv()
-- Claim startup before module initialization can yield. The shared instance also
-- covers queued chunks whose executor globals are isolated from one another.
local geodeVersion="1.4.2"
local geodePlayer=game:GetService("Players").LocalPlayer
if not geodePlayer then error("Local player unavailable")end
local geodeGui=geodePlayer:WaitForChild("PlayerGui",15)
assert(geodeGui,"PlayerGui did not load")
local boot=geodeGui:FindFirstChild("GeodeHubSession")
if boot and boot:GetAttribute("JobId")==game.JobId then
    if boot:GetAttribute("Stage")=="Ready"and boot:GetAttribute("Version")==geodeVersion then
        return env.GeodeHub or {Running=true,Reused=true}
    end
    if boot:GetAttribute("Stage")=="Starting"and os.clock()-(boot:GetAttribute("StartedAt")or 0)<60 then
        return {Pending=true}
    end
    local stop=boot:FindFirstChild("Unload")
    if stop and stop:IsA("BindableFunction")then pcall(function()stop:Invoke()end)end
end
if boot then boot:Destroy()end
if env.GeodeHub and type(env.GeodeHub.Unload)=="function"then pcall(env.GeodeHub.Unload)end
boot=Instance.new("Folder")
boot.Name="GeodeHubSession"
boot:SetAttribute("JobId",game.JobId)
boot:SetAttribute("Version",geodeVersion)
boot:SetAttribute("Stage","Starting")
boot:SetAttribute("StartedAt",os.clock())
boot.Parent=geodeGui
local stop=Instance.new("BindableFunction")
stop.Name="Unload"
stop.Parent=boot
-- Retire menus from releases predating the shared session marker. Invoke only
-- our own Unload Hub control so its workers and event connections stop as well.
local parents={geodeGui}
if type(gethui)=="function"then local ok,p=pcall(gethui);if ok and p then table.insert(parents,p)end end
pcall(function()table.insert(parents,game:GetService("CoreGui"))end)
local seen={}
for _,parent in ipairs(parents)do
    if not seen[parent]then
        seen[parent]=true
        for _,gui in ipairs(parent:GetChildren())do
            if gui.Name=="GeodeNativeHub"and gui:IsA("ScreenGui")then
                if type(getconnections)=="function"and debug and type(debug.getupvalues)=="function"then
                    for _,button in ipairs(gui:GetDescendants())do
                        if button:IsA("TextButton")and button.Text=="Unload Hub"then
                            pcall(function()
                                for _,connection in ipairs(getconnections(button.Activated))do
                                    if type(connection.Function)=="function"then
                                        for _,value in pairs(debug.getupvalues(connection.Function))do
                                            if type(value)=="table"and value.Title=="Unload Hub"and type(value.Callback)=="function"then pcall(value.Callback)end
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end
                gui:Destroy()
            end
        end
    end
end
local function releaseGeodeBoot()
    if boot.Parent then boot:Destroy()end
end

local success,result=pcall(function()
local geodeScripts=geodePlayer:WaitForChild("PlayerScripts",15)
assert(geodeScripts and geodeScripts:WaitForChild("MTGClient",15),"Game client did not load")
-- Beyy native UI. Embedded into each module; no remote UI dependency.
local function createNativeUI()
    local UI = {}
    local input = game:GetService("UserInputService")
    local run = game:GetService("RunService")
    local http = game:GetService("HttpService")
    local colors = {bg=Color3.fromRGB(20,22,27), row=Color3.fromRGB(32,35,42), text=Color3.fromRGB(231,234,240), accent=Color3.fromRGB(58,104,153)}
    local function node(class, parent, props)
        local obj = Instance.new(class)
        for k,v in pairs(props or {}) do obj[k]=v end
        obj.Parent=parent
        return obj
    end
    local function label(parent, text, height)
        return node("TextLabel", parent, {Size=UDim2.new(1,0,0,height or 24), BackgroundTransparency=1, Text=tostring(text or ""), TextColor3=colors.text, TextSize=14, Font=Enum.Font.SourceSans, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left})
    end
    local function button(parent,text,size,pos)
        return node("TextButton",parent,{Size=size or UDim2.new(1,0,0,28),Position=pos or UDim2.new(),BackgroundColor3=colors.row,BorderSizePixel=0,AutoButtonColor=false,Text=tostring(text or ""),TextColor3=colors.text,TextSize=14,Font=Enum.Font.SourceSans})
    end
    local function layout(parent)
        node("UIListLayout",parent,{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})
        node("UIPadding",parent,{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8)})
    end
    local function configManager(folder)
        local manager={Path="WindUI/"..folder.."/config/"}
        function manager:CreateConfig(name)
            assert(type(name)=="string"and name~=""and not name:find("[/\\]"),"Invalid config name")
            local cfg={Path=self.Path..name..".json",Elements={},Order={},CustomData={},Version=1.3}
            function cfg:Register(key,el)
                if not self.Elements[key]then table.insert(self.Order,key)end
                self.Elements[key]=el
            end
            function cfg:Read()
                if type(readfile)~="function"then return nil,"Config loading requires readfile"end
                local ok,data=pcall(function()return http:JSONDecode(readfile(self.Path))end)
                if not ok or type(data)~="table"or type(data.__elements)~="table"then return nil,"No readable saved config"end
                return data
            end
            function cfg:Save()
                local ok,result=pcall(function()
                    assert(type(writefile)=="function"and type(readfile)=="function","Config saving requires writefile/readfile")
                    for _,path in ipairs({"WindUI","WindUI/"..folder,manager.Path})do
                        if not isfolder(path)then makefolder(path)end
                    end
                    local saved={__version=self.Version,__elements={},__custom=self.CustomData}
                    for key,el in pairs(self.Elements)do
                        local value=el.__type=="Slider"and el.Value.Default or el.Value
                        saved.__elements[key]={__type=el.__type,value=value}
                    end
                    local encoded=http:JSONEncode(saved)
                    writefile(self.Path,encoded)
                    assert(readfile(self.Path)==encoded,"Saved config read-back did not match")
                    return saved
                end)
                if not ok then return false,tostring(result)end
                return result
            end
            function cfg:Load(startup,skipAutomation)
                local data,err=self:Read()
                if not data then return false,err end
                local auto=data.__elements.AutoLoadConfig
                if startup and auto and auto.value==false then return false,"Auto-load disabled"end
                -- Parameters and continuation settings precede automation toggles.
                local automation={AutoGeodePickup=true,AutoOpenHauntedEgg=true,AutoCrackAndSell=true,AutoUpgradeMagnet=true}
                for pass=1,2 do
                    for _,key in ipairs(self.Order)do
                        if (automation[key]==true)==(pass==2)and not(skipAutomation and automation[key])then
                            local el,entry=self.Elements[key],data.__elements[key]
                            if type(entry)=="table"and entry.__type==el.__type then
                                local value=entry.value
                                local valid=(el.__type=="Toggle"and type(value)=="boolean")or(el.__type=="Slider"and type(value)=="number"and value==value and math.abs(value)<math.huge)or(el.__type=="Keybind"and type(value)=="string"and Enum.KeyCode[value]~=nil)
                                if valid then el:Set(value)end
                            end
                        end
                    end
                end
                self.CustomData=type(data.__custom)=="table"and data.__custom or {}
                return self.CustomData
            end
            return cfg
        end
        return manager
    end

    function UI:Notify(options)
        if self.Window and not self.Window.Destroyed then self.Window.Notice.Text=tostring(options.Title or "Beyy")..": "..tostring(options.Content or "") end
    end
    function UI:CreateWindow(options)
        local w={Closed=false,Destroyed=false,Connections={},Tabs={},ToggleKey=Enum.KeyCode.RightControl}
        self.Window=w
        local parent=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        if type(gethui)=="function" then local ok,value=pcall(gethui); if ok and value then parent=value end end
        local gui=node("ScreenGui",parent,{Name="GeodeNativeHub",ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=10000,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
        w.Gui=gui
        local root=node("Frame",gui,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(640,480),BackgroundColor3=colors.bg,BorderSizePixel=0})
        node("UISizeConstraint",root,{MaxSize=Vector2.new(640,480),MinSize=Vector2.new(320,240)})
        -- UIScale keeps the fixed panel inside small screens, without layout animation.
        local scale=node("UIScale",root,{Scale=1})
        local function fit()
            local viewport=gui.AbsoluteSize
            scale.Scale=math.min(1,math.max(.1,(viewport.X-12)/640),math.max(.1,(viewport.Y-12)/480))
        end
        local function connect(signal,fn) local c=signal:Connect(fn); table.insert(w.Connections,c); return c end
        connect(gui:GetPropertyChangedSignal("AbsoluteSize"),fit); fit()
        local title=label(root,options.Title or "Beyy Hub",30); title.Position=UDim2.fromOffset(10,0); title.Size=UDim2.new(1,-48,0,30)
        title.Active=true
        local dragInput,dragX,dragY,dragPosition
        connect(title.InputBegan,function(event)
            if w.Closed or dragInput then return end
            if event.UserInputType==Enum.UserInputType.MouseButton1 or event.UserInputType==Enum.UserInputType.Touch then
                dragInput=event; dragX=event.Position.X; dragY=event.Position.Y; dragPosition=root.Position
            end
        end)
        connect(input.InputChanged,function(event)
            if not dragInput or w.Closed then return end
            local mouse=dragInput.UserInputType==Enum.UserInputType.MouseButton1
            if (mouse and event.UserInputType~=Enum.UserInputType.MouseMovement) or (not mouse and event~=dragInput) then return end
            local viewport=gui.AbsoluteSize
            local halfWidth,halfHeight=320*scale.Scale,240*scale.Scale
            local x=dragPosition.X.Scale*viewport.X+dragPosition.X.Offset+event.Position.X-dragX
            local y=dragPosition.Y.Scale*viewport.Y+dragPosition.Y.Offset+event.Position.Y-dragY
            x=math.clamp(x,halfWidth,math.max(halfWidth,viewport.X-halfWidth))
            y=math.clamp(y,halfHeight,math.max(halfHeight,viewport.Y-halfHeight))
            root.Position=UDim2.new(dragPosition.X.Scale,x-dragPosition.X.Scale*viewport.X,dragPosition.Y.Scale,y-dragPosition.Y.Scale*viewport.Y)
        end)
        connect(input.InputEnded,function(event)
            if event==dragInput or (dragInput and dragInput.UserInputType==Enum.UserInputType.MouseButton1 and event.UserInputType==Enum.UserInputType.MouseButton1) then dragInput=nil end
        end)
        local close=button(root,"X",UDim2.fromOffset(28,24),UDim2.new(1,-34,0,3))
        local sidebar=node("ScrollingFrame",root,{Position=UDim2.fromOffset(0,34),Size=UDim2.new(0,180,1,-72),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
        layout(sidebar)
        w.Notice=label(root,"",32); w.Notice.Position=UDim2.new(0,10,1,-34); w.Notice.Size=UDim2.new(1,-20,0,32)
        local bind="GeodeNativeCursor_"..tostring(game:GetService("Players").LocalPlayer.UserId)
        local previousBehavior,previousIcon,cursorBound
        local function releaseCursor()
            if cursorBound then return end
            previousBehavior,previousIcon=input.MouseBehavior,input.MouseIconEnabled
            cursorBound=true
            run:BindToRenderStep(bind,Enum.RenderPriority.Last.Value+100,function()
                input.MouseBehavior=Enum.MouseBehavior.Default; input.MouseIconEnabled=true
            end)
        end
        local function restoreCursor()
            if not cursorBound then return end
            run:UnbindFromRenderStep(bind); cursorBound=false
            input.MouseBehavior=previousBehavior; input.MouseIconEnabled=previousIcon
        end
        function w:Open() if self.Destroyed then return end; self.Closed=false; gui.Enabled=true; releaseCursor() end
        function w:Close() self.Closed=true; gui.Enabled=false; self.Capture=nil; dragInput=nil; restoreCursor() end
        function w:SetToggleKey(key) self.ToggleKey=typeof(key)=="EnumItem" and key or Enum.KeyCode[tostring(key)] or Enum.KeyCode.RightControl end
        function w:EditOpenButton() end
        function w:Destroy()
            if self.Destroyed then return end
            self:Close(); self.Destroyed=true
            for _,c in ipairs(self.Connections) do c:Disconnect() end
            table.clear(self.Connections); gui:Destroy()
        end
        connect(close.Activated,function() w:Close() end)
        connect(input.InputBegan,function(event,processed)
            if w.Capture and event.UserInputType==Enum.UserInputType.Keyboard and event.KeyCode~=Enum.KeyCode.Unknown then
                local capture=w.Capture; w.Capture=nil; capture:Set(event.KeyCode.Name); return
            end
            if not processed and not input:GetFocusedTextBox() and event.KeyCode==w.ToggleKey then if w.Closed then w:Open() else w:Close() end end
        end)
        w.ConfigManager=configManager(options.Folder or "GeodeHub")
        function w:Tab(opts)
            local tab={Window=self}
            local nav=button(sidebar,opts.Title)
            local page=node("ScrollingFrame",root,{Position=UDim2.fromOffset(184,34),Size=UDim2.new(1,-190,1,-72),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false})
            layout(page)
            tab.Page=page; tab.Nav=nav; table.insert(self.Tabs,tab)
            function tab:Select() for _,other in ipairs(w.Tabs) do other.Page.Visible=other==self; other.Nav.BackgroundColor3=other==self and colors.accent or colors.row end end
            connect(nav.Activated,function() tab:Select() end)
            if #self.Tabs==1 then tab:Select() end
            local function row(opts,height)
                local frame=node("Frame",page,{Size=UDim2.new(1,-2,0,height or 42),BackgroundColor3=colors.row,BorderSizePixel=0})
                local heading=label(frame,opts.Title,24); heading.Position=UDim2.fromOffset(8,2); heading.Size=UDim2.new(1,-160,0,24)
                return frame
            end
            local function control(kind,opts,value)
                local el={__type=kind,Value=value}
                function el:Callback(v)
                    if opts.Callback then local ok,err=pcall(opts.Callback,v); if not ok then UI:Notify({Title="Control error",Content=tostring(err)}) end end
                end
                return el
            end
            function tab:Section(opts) return label(page,opts.Title,26) end
            function tab:CollapsibleGroup(opts)
                local title=tostring(opts.Title or "Settings")
                local expanded=opts.Opened==true
                local trigger=button(page,"",UDim2.new(1,-2,0,30))
                local body=node("Frame",page,{
                    Size=UDim2.new(1,-2,0,0),
                    AutomaticSize=Enum.AutomaticSize.Y,
                    BackgroundTransparency=1,Visible=expanded
                })
                layout(body)
                local function redraw()
                    trigger.Text=(expanded and "▼ " or "▶ ")..title
                    body.Visible=expanded
                end
                connect(trigger.Activated,function()
                    expanded=not expanded
                    redraw()
                end)
                redraw()
                local group={}
                for _,kind in ipairs({"Section","Paragraph","Button","Toggle","Slider","Input","Keybind","Dropdown"}) do
                    group[kind]=function(_,options)
                        local existing={}
                        for _,child in ipairs(page:GetChildren()) do existing[child]=true end
                        local element=tab[kind](tab,options)
                        for _,child in ipairs(page:GetChildren()) do
                            if not existing[child] and child:IsA("GuiObject") then
                                child.Parent=body
                            end
                        end
                        return element
                    end
                end
                return group
            end

            function tab:Paragraph(opts)
                -- Static help paragraphs are omitted; live status panels remain.
                local live=opts.Title=="Session" or tostring(opts.Title):find("Status",1,true)~=nil
                if not live and opts.Title~="Configs unavailable" then
                    return {SetDesc=function() end,SetTitle=function() end}
                end
                local frame=node("Frame",page,{Size=UDim2.new(1,-2,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1})
                layout(frame)
                local heading=label(frame,opts.Title); heading.AutomaticSize=Enum.AutomaticSize.Y
                local desc=label(frame,live and opts.Desc or ""); desc.AutomaticSize=Enum.AutomaticSize.Y
                local el={}
                function el:SetDesc(v) desc.Text=tostring(v or "") end
                function el:SetTitle(v) heading.Text=tostring(v or "") end
                return el
            end
            function tab:Button(opts)
                local b=button(page,opts.Title)
                connect(b.Activated,function() if opts.Callback then local ok,err=pcall(opts.Callback); if not ok then UI:Notify({Title="Action error",Content=tostring(err)}) end end end)
                return b
            end
            function tab:Toggle(opts)
                local el=control("Toggle",opts,opts.Value==true)
                local frame=row(opts); local b=button(frame,"",UDim2.fromOffset(100,28),UDim2.new(1,-108,0,5))
                local function redraw() b.Text=el.Value and "ON" or "OFF"; b.BackgroundColor3=el.Value and colors.accent or colors.bg end
                function el:Set(v) self.Value=v==true; redraw(); self:Callback(self.Value) end
                connect(b.Activated,function() el:Set(not el.Value) end); redraw(); return el
            end
            function tab:Slider(opts)
                local spec=opts.Value or {}
                local el=control("Slider",opts,{Min=spec.Min or 0,Max=spec.Max or 100,Default=spec.Default or 0})
                local step=tonumber(opts.Step) or 1
                local fraction=tostring(step):match("%.(%d+)")
                local decimals=math.min(6,fraction and #fraction or 0)
                local function displayNumber(value)
                    local shown=string.format("%."..decimals.."f",value)
                    if decimals>0 then
                        shown=shown:gsub("0+$","")
                        shown=shown:gsub("%.$","")
                    end
                    return shown
                end
                local frame=row(opts)
                local field=node("TextBox",frame,{
                    Size=UDim2.fromOffset(64,28),Position=UDim2.new(1,-100,0,5),
                    Text=displayNumber(el.Value.Default),BackgroundColor3=colors.bg,
                    TextColor3=colors.text,TextSize=14,Font=Enum.Font.SourceSans,
                    ClearTextOnFocus=false
                })
                function el:Set(v)
                    local n=tonumber(v)
                    if not n or n~=n or n==math.huge or n==-math.huge then
                        field.Text=displayNumber(self.Value.Default)
                        return
                    end
                    if step>0 then n=self.Value.Min+math.round((n-self.Value.Min)/step)*step end
                    n=math.clamp(n,self.Value.Min,self.Value.Max)
                    local shown=displayNumber(n)
                    self.Value.Default=tonumber(shown) or n
                    field.Text=shown
                    self:Callback(self.Value.Default)
                end
                local minus=button(frame,"-",UDim2.fromOffset(26,28),UDim2.new(1,-130,0,5))
                local plus=button(frame,"+",UDim2.fromOffset(26,28),UDim2.new(1,-32,0,5))
                connect(minus.Activated,function() el:Set(el.Value.Default-step) end)
                connect(plus.Activated,function() el:Set(el.Value.Default+step) end)
                connect(field.FocusLost,function() el:Set(field.Text) end)
                return el
            end
            function tab:Input(opts)
                local el=control("Input",opts,tostring(opts.Value or "")); local frame=row(opts,70)
                local field=node("TextBox",frame,{Position=UDim2.fromOffset(8,32),Size=UDim2.new(1,-16,0,28),Text=el.Value,PlaceholderText=opts.Placeholder or "",BackgroundColor3=colors.bg,TextColor3=colors.text,TextSize=14,Font=Enum.Font.SourceSans,ClearTextOnFocus=false})
                function el:Set(v) self.Value=tostring(v or ""); field.Text=self.Value; self:Callback(self.Value) end
                connect(field.FocusLost,function() el:Set(field.Text) end); return el
            end
            function tab:Keybind(opts)
                local initial=opts.Value or "RightControl"; if typeof(initial)=="EnumItem" then initial=initial.Name end
                local el=control("Keybind",opts,initial); local frame=row(opts)
                local b=button(frame,initial,UDim2.fromOffset(140,28),UDim2.new(1,-148,0,5))
                function el:Set(v) self.Value=typeof(v)=="EnumItem" and v.Name or tostring(v); b.Text=self.Value; self:Callback(self.Value) end
                connect(b.Activated,function() w.Capture=el; b.Text="Press a key" end); return el
            end
            function tab:Dropdown(opts)
                local el=control("Dropdown",opts,opts.Value or (opts.Multi and {} or ""))
                local frame=row(opts); local b=button(frame,"",UDim2.fromOffset(140,28),UDim2.new(1,-148,0,5))
                local choices=node("ScrollingFrame",page,{Size=UDim2.new(1,-2,0,160),Visible=false,BackgroundColor3=colors.bg,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y}); layout(choices)
                local choiceButtons={}; local choiceConnections={}
                local function selected(value) if type(el.Value)~="table" then return el.Value==value end; for k,v in pairs(el.Value) do if v==value or (k==value and v==true) then return true end end; return false end
                local function redraw()
                    local values={}; if type(el.Value)=="table" then for k,v in pairs(el.Value) do table.insert(values,tostring(v==true and k or v)) end else table.insert(values,tostring(el.Value)) end
                    b.Text=#values>0 and table.concat(values,", ") or "Choose"
                    for value,cb in pairs(choiceButtons) do cb.Text=(selected(value) and "[x] " or "[ ] ")..tostring(value) end
                end
                function el:Select(v) self.Value=opts.Multi and (type(v)=="table" and table.clone(v) or {v}) or v; redraw(); self:Callback(self.Value) end
                el.Set=el.Select
                function el:Refresh(values)
                    for _,c in ipairs(choiceConnections) do
                        c:Disconnect()
                        local index=table.find(w.Connections,c)
                        if index then table.remove(w.Connections,index) end
                    end
                    table.clear(choiceConnections)
                    for _,cb in pairs(choiceButtons) do cb:Destroy() end; table.clear(choiceButtons)
                    for _,value in ipairs(values or {}) do
                        local cb=button(choices,tostring(value)); choiceButtons[value]=cb
                        local c=cb.Activated:Connect(function()
                            if opts.Multi then
                                local nextValues={}; for _,candidate in ipairs(values) do if (candidate==value and not selected(candidate)) or (candidate~=value and selected(candidate)) then table.insert(nextValues,candidate) end end
                                el:Select(nextValues)
                            else el:Select(value); choices.Visible=false end
                        end)
                        table.insert(choiceConnections,c); table.insert(w.Connections,c)
                    end
                    redraw()
                end
                connect(b.Activated,function() choices.Visible=not choices.Visible end); el:Refresh(opts.Values); return el
            end
            return tab
        end
        function w:Section(opts)
            label(sidebar,opts.Title,24)
            local group={}; function group:Tab(tabOpts) return w:Tab(tabOpts) end
            return group
        end
        w:Open()
        return w
    end
    return UI
end

local Pickup=(function()
-- Crack the Geode! Standalone range-limited pickup. No movement, camera writes, purchases or teleport queue.
local Players=game:GetService("Players")
local World=game:GetService("Workspace")
local Storage=game:GetService("ReplicatedStorage")
local H=game:GetService("HttpService")
local player=Players.LocalPlayer
local client=player and player:FindFirstChild("PlayerScripts") and player.PlayerScripts:FindFirstChild("MTGClient")
local mtg=Storage:FindFirstChild("MTG")
if not client or not mtg then warn("[Geode Pickup] Game modules are not available yet.");return end
local State=require(client.State)
local Render=require(client.MoundRender)
local HUD=require(client.RunHUD)
local Tools=require(client.Tools)
local Stats=require(mtg.Modules.Stats)
local Game=require(mtg.Config.Game)
local remote=mtg.Remotes:FindFirstChild("Pick")
if not remote then warn("[Geode Pickup] Pick remote unavailable.");return end
local env=getgenv()
if env.GeodeAutoPickup and type(env.GeodeAutoPickup.Unload)=="function"then env.GeodeAutoPickup.Unload()end
local api={Running=true,Enabled=false,MinRange=0,MaxRange=math.min(26,Game.Collect.Reach),Requests=0,Feedback=0,Items=0}
env.GeodeAutoPickup=api
local events,connections={},{}
local nextSend=0;local pending;local avoided={};local dirty=false;local deadline
local status="Paused"
local screen,statusLabel,toggle,rangeBox
local function log(kind,data)
    events[#events+1]={Kind=kind,At=os.clock(),WallTimeMs=DateTime.now().UnixTimestampMillis,Data=data}
    if #events>160 then table.remove(events,1)end
    dirty=true
    if kind~="BagChanged"then print("[Geode Pickup] "..kind.." "..H:JSONEncode(data or{}))end
end
local function setStatus(text)status=text;api.Status=text;if statusLabel then statusLabel.Text=text end end
function api.SetRange(minimum,maximum)
    minimum=tonumber(minimum);maximum=tonumber(maximum)
    if not minimum or not maximum or minimum~=minimum or maximum~=maximum then return false end
    local cap=math.min(26,Game.Collect.Reach)
    if minimum<0 or maximum>cap or minimum>maximum then return false end
    api.MinRange=minimum;api.MaxRange=maximum
    if rangeBox then rangeBox.Text=tostring(maximum)end
    log("RangeChanged",{Min=minimum,Max=maximum});return true
end
function api.Start(seconds)
    api.Enabled=true;deadline=seconds and(os.clock()+math.max(0,seconds))or nil
    if toggle then toggle.Text="Pause pickup"end
    log("Started",{Min=api.MinRange,Max=api.MaxRange,Duration=seconds});setStatus("Looking for nearby targets")
end
function api.Stop()
    api.Enabled=false;deadline=nil
    if toggle then toggle.Text="Start pickup"end
    log("Paused",{Requests=api.Requests,Feedback=api.Feedback,Items=api.Items});setStatus("Paused")
end
function api.Export()
    local report={Version=1,PlaceId=game.PlaceId,GameId=game.GameId,JobId=game.JobId,Enabled=api.Enabled,
        Range={Min=api.MinRange,Max=api.MaxRange},Requests=api.Requests,Feedback=api.Feedback,Items=api.Items,
        BagCount=player:GetAttribute("BagCount"),Status=status,Events=events,
        Note="Pick feedback identifies the player and item count, not a unique request. Manual clicks can also contribute."}
    local ok,err=pcall(function()
        if not isfolder("Geode")then makefolder("Geode")end
        writefile("Geode/auto_pickup_diagnostics.json",H:JSONEncode(report))
    end)
    if ok then dirty=false end
    return ok,err
end
function api.Unload()
    if not api.Running then return end
    api.Stop();api.Running=false
    for _,c in ipairs(connections)do c:Disconnect()end
    if screen then screen:Destroy()end
    api.Export()
end
local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.MaxParts=512
local rays=RaycastParams.new();rays.FilterType=Enum.RaycastFilterType.Include
local function targetFor(root)
    local folder=Render.Folder
    if not folder or not folder.Parent then return end
    overlap.FilterDescendantsInstances={folder};rays.FilterDescendantsInstances={folder}
    local candidates={}
    for _,part in ipairs(World:GetPartBoundsInRadius(root.Position,api.MaxRange,overlap))do
        if part.Transparency<1 and part.CanQuery then
            local col,id=Render.target(part)
            if col~=nil and id~=nil then
                local distance=(part.Position-root.Position).Magnitude
                if distance<=api.MaxRange then candidates[#candidates+1]={Part=part,Distance=distance}end
            end
        end
    end
    table.sort(candidates,function(a,b)return a.Distance<b.Distance end)
    local now=os.clock()
    for i=1,math.min(32,#candidates)do
        local direction=candidates[i].Part.Position-root.Position
        if direction.Magnitude>0.001 then
            local hit=World:Raycast(root.Position,direction*1.05,rays)
            if hit then
                local col,id=Render.target(hit.Instance)
                local distance=(hit.Position-root.Position).Magnitude
                local key=col~=nil and id~=nil and(tostring(col)..":"..tostring(id))
                if key and distance>=api.MinRange and distance<=api.MaxRange
                    and(not avoided[key]or avoided[key]<now)then
                    return {Col=col,Id=id,Position=hit.Position,Distance=distance,Key=key}
                end
            end
        end
    end
end
connections[#connections+1]=remote.OnClientEvent:Connect(function(userId,tool,packed,gems)
    if userId~=player.UserId then return end
    local count=typeof(packed)=="buffer"and math.floor(buffer.len(packed)/5)or 0
    -- Pets use the same remote; their collections must not confirm our tool request.
    if not pending or tool~=pending.Tool then
        if api.Enabled then log("OtherPickupFeedback",{Tool=tool,Items=count})end
        return
    end
    api.Feedback+=1;api.Items+=count
    log("ServerPickupFeedback",{Tool=tool,Items=count,Gems=gems,SinceRequestMs=pending and(os.clock()-pending.At)*1000,
        BagCount=player:GetAttribute("BagCount"),Target=pending and pending.Target.Key})
    if count>0 then pending=nil end
end)
connections[#connections+1]=player:GetAttributeChangedSignal("BagCount"):Connect(function()
    log("BagChanged",{Count=player:GetAttribute("BagCount")})
end)
task.spawn(function()
    local nextSave=0
    while api.Running and env.GeodeAutoPickup==api do
        local now=os.clock()
        if deadline and now>=deadline then api.Stop()end
        local ok,err=pcall(function()
            if pending and now-pending.At>1.5 then
                avoided[pending.Target.Key]=now+1
                log("NoConfirmation",{Target=pending.Target.Key,WaitMs=(now-pending.At)*1000});pending=nil
            end
            if not api.Enabled then return end
            if api.Suspended then setStatus("Auto Crack and Sell is active");return end
            local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if not root or not hum or hum.Health<=0 then setStatus("Waiting for character");return end
            if State.role()~="Game"or State.run("Phase")~="Mining"or State.run("MoundLocked",false)then setStatus("Waiting for mining phase");return end
            local cap=State.get("BagCap",0);local count=State.get("BagCount",0)
            if cap>=0 and count>=cap then setStatus("Bag full — deposit geodes");return end
            if pending or now<nextSend then return end
            local tool=HUD.equipped()
            if not tool or not State.set("Tools")[tool]then setStatus("Equip an owned mining tool");return end
            local stats=Stats.tool(State.ctx(),tool)
            local cooldown=math.max(0.05,stats.Cooldown*Tools.paceMult(tool))
            local target=targetFor(root)
            if not target then setStatus("No targets within "..api.MaxRange.." studs");nextSend=now+0.2;return end
            local origin=Render.origin()
            if typeof(origin)~="Vector3"then setStatus("Waiting for mound data");return end
            local offset=target.Position-origin
            -- Native argument order is tool, column, local X, local Z, local Y, cell ID.
            nextSend=now+cooldown
            pending={At=os.clock(),Target=target,Tool=tool}
            api.Requests+=1
            log("Request",{Tool=tool,Col=target.Col,Id=target.Id,Distance=target.Distance,Range=api.MaxRange,
                Cooldown=cooldown,BagBefore=count,Position={target.Position.X,target.Position.Y,target.Position.Z}})
            remote:FireServer(tool,target.Col,offset.X,offset.Z,offset.Y,target.Id)
            setStatus("Picking up | "..string.format("%.1f",target.Distance).." studs | received "..api.Items)
        end)
        if not ok then log("Error",{Message=tostring(err)});api.Stop();setStatus("Paused after error — see log")end
        if dirty and now>=nextSave then nextSave=now+2;api.Export()end
        task.wait(0.05)
    end
end)
log("Loaded",{Min=api.MinRange,Max=api.MaxRange,PlaceId=game.PlaceId})
api.Status="Paused"
return api

end)()
if not Pickup then return end
local function createHauntedEggController(options)
    local api={Running=true,Enabled=false,InFlight=false,Busy=false,Status="Paused",Requests=0,Opened=0,Accepted=0,BusyReplies=0}
    local nextRequest=0
    local function record(kind,data)if options.Record then pcall(options.Record,kind,data)end end
    function api.Start()
        if not api.Running then return end
        api.Enabled=true;api.Status="Checking candy and event availability"
        record("Started",{Batch=3})
    end
    function api.Stop(reason)
        api.Enabled=false;api.Status=reason or"Paused"
        record("Stopped",{Reason=api.Status})
    end
    function api.Unload()if not api.Running then return end;api.Stop();api.Running=false end
    function api.Tick()
        if not api.Running or not api.Enabled or api.InFlight or options.Now()<nextRequest then return end
        local context=options.Context()
        local price=tonumber(context.Price)
        api.Price=price and math.floor(price)*3 or nil
        api.Candy=tonumber(context.Candy)or 0
        if not context.Active then api.Stop("Halloween event is inactive");return end
        if not context.Unlocked then api.Status="Waiting for pets to unlock";return end
        if not api.Price or api.Price<=0 then api.Stop("Egg price unavailable");return end
        if context.Opening then api.Status="Waiting for the game's hatch animation";return end
        if api.Candy<api.Price then api.Status="Waiting for candy (need "..api.Price..")";return end
        local before=api.Candy
        api.InFlight=true;api.Requests+=1;api.Status="Opening 3 Haunted Eggs"
        record("Request",{Action="Open3",Egg="Haunted",CandyBefore=before,Price=api.Price})
        local started=options.Now()
        local ok,result=pcall(options.Invoke)
        api.InFlight=false
        local elapsed=(options.Now()-started)*1000
        if not ok then
            record("RequestError",{Error=tostring(result),ResponseMs=elapsed})
            api.Stop("Request failed; stopped to avoid an uncertain repeat purchase")
            return
        end
        if type(result)~="table"then api.Stop("Unexpected server response");return end
        api.Busy=result.Busy==true
        record("Response",{Result=result,ResponseMs=elapsed})
        -- The server has no separate readable Busy flag. Retry rejected Busy replies
        -- at the native client's 0.3s minimum, or the longer server-supplied Wait.
        local waitTime=tonumber(result.Wait)or 0
        if waitTime~=waitTime or waitTime==math.huge or waitTime==-math.huge then waitTime=0 end
        nextRequest=options.Now()+math.max(0.3,waitTime)
        if api.Busy then
            api.BusyReplies+=1
            if api.Enabled then api.Status="Server busy — waiting to retry"end
            return
        end
        if result.Ok~=true then api.Stop(tostring(result.Msg or"Server rejected egg opening"));return end
        local count=type(result.Results)=="table"and #result.Results or(result.Pet and 1 or 0)
        api.Accepted+=1;api.Opened+=count;api.LastResults=result.Results or{result}
        if tonumber(result.Candy)then api.Candy=tonumber(result.Candy)end
        if api.Enabled then api.Status="Opened "..count.." eggs — checking next batch"end
    end
    return api
end

local function createLiveHauntedEggs()
    local P=game:GetService("Players").LocalPlayer
    local H=game:GetService("HttpService")
    local MTG=game:GetService("ReplicatedStorage"):WaitForChild("MTG")
    local Event=require(MTG.Modules.Halloween)
    local Config=require(MTG.Config.HalloweenPets)
    local Pets=require(MTG.Config.Pets)
    local PetsUI=require(P.PlayerScripts.MTGClient.PetsUI)
    local remote=MTG.Remotes:WaitForChild("Pets")
    local events={};local dirty=false
    local api=createHauntedEggController({Now=os.clock,Context=function()
        return {Active=Event.active(),Unlocked=P:GetAttribute("UnlockPets")==true,
            Candy=P:GetAttribute("Candy"),Price=Config.Egg.Candy,Opening=PetsUI.isOpening and PetsUI.isOpening()}
    end,Invoke=function()return remote:InvokeServer("Open3","Haunted",nil)end,
    Record=function(kind,data)
        events[#events+1]={Kind=kind,WallTimeMs=DateTime.now().UnixTimestampMillis,Data=data}
        if #events>80 then table.remove(events,1)end
        dirty=true
    end})
    api.Price=math.floor(Config.Egg.Candy)*3;api.Candy=tonumber(P:GetAttribute("Candy"))or 0
    function api.Export()
        local report={Version=1,PlaceId=game.PlaceId,Enabled=api.Enabled,Requests=api.Requests,Accepted=api.Accepted,
            Opened=api.Opened,BusyReplies=api.BusyReplies,Candy=P:GetAttribute("Candy"),Batch=3,Price=api.Price,Status=api.Status,Events=events}
        local ok,err=pcall(function()
            if not isfolder("Geode")then makefolder("Geode")end
            writefile("Geode/haunted_egg_diagnostics.json",H:JSONEncode(report))
        end)
        if ok then dirty=false end
        return ok,err
    end
    function api.ResultText()
        local names={}
        for _,r in ipairs(api.LastResults or{})do
            local def=Pets.ById[tostring(r.Pet)]
            names[#names+1]=def and def.Name or tostring(r.Pet)
        end
        return #names>0 and table.concat(names,", ")or"No eggs opened this session"
    end
    local unload=api.Unload
    function api.Unload()unload();api.Export()end
    task.spawn(function()
        local nextSave=0
        while api.Running do
            local ok,err=pcall(api.Tick)
            if not ok then api.Stop("Hatch loop error: "..tostring(err))end
            if dirty and os.clock()>=nextSave then nextSave=os.clock()+2;api.Export()end
            task.wait(.05)
        end
    end)
    return api
end

local Eggs=createLiveHauntedEggs()
local function createCrackSellController(options)
    local api={Running=true,Enabled=false,Busy=false,Stage="Idle",Status="Paused",Interval=10,Cycles=0,Sales=0,CashGained=0}
    local armedAt;local lastBag;local observedIdentity
    local deadline=0;local readyAt=0;local identity;local cracked=false;local sold=false;local saleBefore=0
    local function record(kind,data)if options.Record then pcall(options.Record,kind,data)end end
    local function stage(name,status,timeout)
        api.Stage=name;api.Status=status;deadline=options.Now()+(timeout or 4)
        record("Stage",{Stage=name,Status=status})
    end
    local function finish(reason)
        if api.Busy then
            local ok,err=pcall(options.Finish)
            if not ok then record("CleanupError",{Error=tostring(err)})end
        end
        api.Busy=false;identity=nil;api.Stage="Idle";api.Status=reason or"Waiting for more geodes"
        armedAt=nil
    end
    function api.Start()
        if not api.Running or api.Enabled then return end
        local c=options.Context();lastBag=c.BagCount;observedIdentity=c.Identity
        api.Enabled=true;armedAt=nil;api.Status="Waiting for first bag count change"
    end
    function api.BagChanged(value)
        value=tonumber(value)or 0
        local changed=lastBag~=nil and lastBag~=value
        lastBag=value
        if api.Running and api.Enabled and not api.Busy and changed and not armedAt then
            armedAt=options.Now()
            record("CollectionWindowStarted",{BagCount=value,WaitSeconds=api.Interval})
        end
    end
    function api.Stop(reason)
        api.Enabled=false;finish(reason or"Paused")
        record("Stopped",{Reason=api.Status})
    end
    function api.Unload()if not api.Running then return end;api.Stop();api.Running=false end
    function api.SetInterval(value)
        value=tonumber(value)
        if value and value==value then api.Interval=math.clamp(value,2,60)end
    end
    function api.Notify(kind)
        if not api.Busy then return end
        if kind=="CrackAll"and api.Stage=="CrackWait"then cracked=true
        elseif kind=="Sold"and api.Stage=="SellWait"then sold=true end
    end
    local function hasBin(c)return c.BinCount>0 or c.BinValue>0 end
    local function approach(target)
        local ok,reason=options.MoveTo(target)
        if not ok then api.Stop(reason or("Could not approach "..target));return false end
        stage(target.."Approach","Approaching "..target:lower(),4)
        readyAt=options.Now()+0.5
        return true
    end
    local function proceed(c)
        if c.CrateCount>0 and c.CanCrack then
            approach("Station")
        elseif hasBin(c)then approach("Sell")
        elseif c.CrateCount>0 then api.Stop("Crack All pass or credits required")
        else finish("Nothing left to crack or sell")end
    end
    local function completed(c)
        api.Cycles+=1
        record("CycleComplete",{Cycles=api.Cycles,Cash=c.Cash})
        finish("Cycle complete — returned to pickup position")
    end
    function api.Tick()
        if not api.Running or not api.Enabled then return end
        local c=options.Context()
        if not c.Valid then
            if api.Busy then api.Stop("Cycle stopped: character or mining phase changed")else api.Status="Waiting for a mining run"end
            armedAt=nil;lastBag=c.BagCount
            return
        end
        if api.Busy and c.Identity~=identity then api.Stop("Cycle stopped: character or camp changed");return end
        if observedIdentity~=c.Identity then armedAt=nil;lastBag=c.BagCount;observedIdentity=c.Identity end
        api.BagChanged(c.BagCount)
        local now=options.Now()
        if api.Stage=="Idle"then
            if not armedAt then api.Status="Waiting for first bag count change";return end
            if now<armedAt+api.Interval then
                api.Status=string.format("Collecting — camp visit in %.1fs",armedAt+api.Interval-now)
                return
            end
            if c.Cracking then api.Status="Waiting for your manual station session to end";return end
            if c.BagCount<=0 and c.CrateCount<=0 and not hasBin(c)then armedAt=nil;api.Status="Waiting for geodes";return end
            if(c.BagCount>0 or c.CrateCount>0)and not c.CanCrack and not hasBin(c)then api.Status="Crack All pass or credits required";return end
            if(c.BagCount>0 or c.CrateCount>0)and not c.FreeStation then api.Status="Waiting for a free station";return end
            api.Busy=true;identity=c.Identity
            local ok,reason=options.Begin()
            if not ok then api.Stop(reason or"Could not start cycle");return end
            record("CycleBegin",{Bag=c.BagCount,Crate=c.CrateCount,Bin=c.BinCount,Cash=c.Cash})
            if c.BagCount>0 then approach("Deposit")else proceed(c)end
            return
        end
        if now>=deadline then api.Stop("Timed out during "..api.Stage);return end
        if api.Stage=="DepositApproach"and now>=readyAt then
            if c.BagCount<=0 then proceed(c);return end
            options.Deposit();stage("DepositWait","Waiting for deposit confirmation",4)
        elseif api.Stage=="DepositWait"then
            if c.BagCount<=0 then proceed(c)end
        elseif api.Stage=="StationApproach"and now>=readyAt then
            if not c.CanCrack then api.Stop("Crack All pass or credits required");return end
            if c.CrateCount<=0 then if hasBin(c)then approach("Sell")else completed(c)end;return end
            options.Enter();stage("EnterWait","Waiting for station entry",4)
        elseif api.Stage=="EnterWait"then
            if c.Cracking and c.StationOurs then
                if not c.CanCrack then api.Stop("Crack All entitlement changed");return end
                cracked=false;stage("CrackWait","Waiting for Crack All confirmation",8)
                options.Crack()
            end
        elseif api.Stage=="CrackWait"then
            if cracked or c.CrateCount<=0 then
                stage("LeaveWait","Leaving station",3);readyAt=now+0.3;options.Leave()
            end
        elseif api.Stage=="LeaveWait"then
            if not c.Cracking and now>=readyAt then
                if hasBin(c)then approach("Sell")else completed(c)end
            end
        elseif api.Stage=="SellApproach"and now>=readyAt then
            if not hasBin(c)then completed(c);return end
            saleBefore=c.Cash;sold=false;stage("SellWait","Waiting for sale confirmation",4)
            options.Sell()
        elseif api.Stage=="SellWait"then
            if sold or not hasBin(c)then
                stage("SaleSettle","Confirming sale balance",2);readyAt=now+0.2
            end
        elseif api.Stage=="SaleSettle"and now>=readyAt then
            api.Sales+=1;api.CashGained+=math.max(0,c.Cash-saleBefore)
            completed(c)
        end
    end
    return api
end

local function createLiveCrackSell(Pickup)
    local P=game:GetService("Players").LocalPlayer
    local H=game:GetService("HttpService")
    local MTG=game:GetService("ReplicatedStorage"):WaitForChild("MTG")
    local Bench=require(P.PlayerScripts.MTGClient.Bench)
    local remote=MTG.Remotes:WaitForChild("Bench")
    local camp,character,identity,station,entry,deposit,sell
    local savedPose,savedCharacter,savedCamp;local enteredByUs=false;local events={};local dirty=false;local generation=0
    local function root()return P.Character and P.Character:FindFirstChild("HumanoidRootPart")end
    local function refresh()
        local map=workspace:FindFirstChild("CaveMap")
        local current=map and map:FindFirstChild("Camp")
        if current~=camp or character~=P.Character then
            camp=current;character=P.Character;identity={}
            deposit=camp and camp:FindFirstChild("MTG_Deposit",true)
            sell=camp and camp:FindFirstChild("MTG_Sell",true)
        end
    end
    local function chooseStation()
        local stations=camp and camp:FindFirstChild("Stations")
        if not stations then return end
        for _,name in ipairs({"Station2","Station3","Station1","Station4"})do
            local s=stations:FindFirstChild(name);local prompt=s and s:FindFirstChild("MTG_Crack",true)
            if prompt and prompt.Enabled and(s:GetAttribute("Occupant")or 0)==0 then return s,prompt end
        end
    end
    local function canCrack()
        for pass in tostring(P:GetAttribute("Passes")or""):gmatch("[^,]+")do if pass=="CrackAll"then return true end end
        return(tonumber(P:GetAttribute("CrackAllCredits"))or 0)>0
    end
    local function valid()
        local state=MTG:FindFirstChild("State")
        local hum=P.Character and P.Character:FindFirstChildOfClass("Humanoid")
        return camp~=nil and root()~=nil and hum~=nil and hum.Health>0 and MTG:GetAttribute("Role")=="Game"
            and state~=nil and state:GetAttribute("Phase")=="Mining"
    end
    local function ownsStation()
        return station and station.Parent and station:GetAttribute("Occupant")==P.UserId
    end
    local function leave()
        if enteredByUs and ownsStation()and Bench.isCracking()then Bench._ui.doLeave()end
        enteredByUs=false
    end
    local function finish()
        local pendingEntry=enteredByUs and not Bench.isCracking()
        local pendingStation=station
        local pendingGeneration=generation
        local leaveOK,leaveError=pcall(leave)
        Pickup.Suspended=false
        -- An already-triggered station prompt may be acknowledged after Stop/Unload.
        if pendingEntry then task.spawn(function()
            local untilAt=os.clock()+4
            repeat
                if generation~=pendingGeneration then return end
                if pendingStation and pendingStation.Parent and pendingStation:GetAttribute("Occupant")==P.UserId and Bench.isCracking()then
                    Bench._ui.doLeave();return
                end
                task.wait(.05)
            until os.clock()>=untilAt
        end)end
        refresh()
        local r=root()
        local poseToRestore=savedPose and savedCharacter==P.Character and savedCamp==camp and valid()and r and savedPose
        savedPose=nil;savedCharacter=nil;savedCamp=nil
        if poseToRestore and leaveOK then r.CFrame=poseToRestore;r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero end
        if not leaveOK then error(leaveError)end
    end
    local function near(prompt,point)
        return prompt and prompt.Parent and prompt.Parent:IsA("BasePart")
            and(point-prompt.Parent.Position).Magnitude<=math.max(0,prompt.MaxActivationDistance-1)
    end
    local function moveTo(target)
        local r=root();if not r then return false,"Character unavailable"end
        local prompt=target=="Deposit"and deposit or(target=="Sell"and sell or entry)
        if target=="Station"and(not station or not station.Parent or(station:GetAttribute("Occupant")or 0)~=0)then
            station,entry=chooseStation();prompt=entry
        end
        if not prompt or not prompt.Parent or not prompt.Enabled then return false,target.." interaction unavailable"end
        if near(prompt,r.Position)then return true end
        local combined=entry and entry.Parent.Position+Vector3.new(-3.6,1.5,6)
        local point=combined and near(prompt,combined)and combined or prompt.Parent.Position+Vector3.new(-4,1.5,0)
        r.CFrame=CFrame.new(point)*r.CFrame.Rotation
        r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
        return true
    end
    local function trigger(prompt)
        if type(fireproximityprompt)~="function"then error("Executor prompt support unavailable")end
        local r=root()
        if not r or not prompt or not prompt.Enabled or not near(prompt,r.Position)then error("Interaction is disabled or out of range")end
        fireproximityprompt(prompt)
    end
    local api=createCrackSellController({Now=os.clock,Context=function()
        refresh()
        local free=chooseStation()
        return {Valid=valid(),Identity=identity,BagCount=tonumber(P:GetAttribute("BagCount"))or 0,
            CrateCount=camp and(tonumber(camp:GetAttribute("CrateCount"))or 0)or 0,
            BinCount=camp and(tonumber(camp:GetAttribute("BinCount"))or 0)or 0,
            BinValue=camp and(tonumber(camp:GetAttribute("BinValue"))or 0)or 0,
            Cash=tonumber(P:GetAttribute("Cash"))or 0,CanCrack=canCrack(),FreeStation=free~=nil,
            Cracking=Bench.isCracking(),StationOurs=ownsStation()and true or false}
    end,Begin=function()
        if type(fireproximityprompt)~="function"then return false,"Executor prompt support unavailable"end
        refresh();local r=root();if not r then return false,"Character unavailable"end
        generation+=1
        station,entry=chooseStation()
        savedPose=r.CFrame;savedCharacter=P.Character;savedCamp=camp;enteredByUs=false
        Pickup.Suspended=true
        return true
    end,MoveTo=moveTo,Deposit=function()trigger(deposit)end,Enter=function()enteredByUs=true;trigger(entry)end,
    Crack=function()remote:FireServer("CrackAll")end,Leave=leave,Sell=function()trigger(sell)end,Finish=finish,
    Record=function(kind,data)
        events[#events+1]={Kind=kind,WallTimeMs=DateTime.now().UnixTimestampMillis,Data=data}
        if #events>100 then table.remove(events,1)end
        dirty=true
    end})
    local connection=remote.OnClientEvent:Connect(function(data)
        if type(data)~="table"or not api.Busy then return end
        api.Notify(data.Type)
        local row={Type=data.Type};for k,v in pairs(data)do if type(v)=="number"or type(v)=="boolean"or type(v)=="string"then row[k]=v end end
        events[#events+1]={Kind="ServerEvent",WallTimeMs=DateTime.now().UnixTimestampMillis,Data=row}
        if #events>100 then table.remove(events,1)end;dirty=true
    end)
    local bagConnection=P:GetAttributeChangedSignal("BagCount"):Connect(function()
        api.BagChanged(P:GetAttribute("BagCount"))
    end)
    function api.Export()
        local ok,err=pcall(function()
            if not isfolder("Geode")then makefolder("Geode")end
            writefile("Geode/auto_crack_sell_diagnostics.json",H:JSONEncode({Version=1,Enabled=api.Enabled,Stage=api.Stage,
                Status=api.Status,Cycles=api.Cycles,Sales=api.Sales,CashGained=api.CashGained,Interval=api.Interval,Events=events}))
        end)
        if ok then dirty=false end
        return ok,err
    end
    local unload=api.Unload
    function api.Unload()if not api.Running then return end;unload();connection:Disconnect();bagConnection:Disconnect();api.Export()end
    task.spawn(function()
        local nextSave=0
        while api.Running do
            local ok,err=pcall(api.Tick)
            if not ok then api.Stop("Cycle error: "..tostring(err))end
            if dirty and os.clock()>=nextSave then nextSave=os.clock()+2;api.Export()end
            task.wait(.1)
        end
    end)
    return api
end

local CrackSell=createLiveCrackSell(Pickup)
local function createMagnetUpgradeController(options)
    local ids={"MagPower","MagSpeed"};local cursor=1;local pending;local nextRequest=0
    local api={Running=true,Enabled=false,InFlight=false,Status="Paused",Confirmed=0}
    local function record(kind,data)if options.Record then pcall(options.Record,kind,data)end end
    function api.Start()if not api.Running then return end;api.Enabled=true;api.Status="Checking GEO-MAG upgrades"end
    function api.Stop(reason)api.Enabled=false;api.Status=reason or"Paused";record("Stopped",{Reason=api.Status})end
    function api.Unload()if not api.Running then return end;api.Stop();api.Running=false end
    function api.Tick()
        if not api.Running or not api.Enabled or api.InFlight then return end
        local now=options.Now();local context=options.Context()
        if pending then
            if(context.Levels[pending.Id]or 0)>=pending.Level then
                api.Confirmed+=1;record("Confirmed",pending);cursor=pending.NextCursor;pending=nil
            elseif now>=pending.Deadline then api.Stop("Upgrade confirmation timed out");return
            else api.Status="Waiting for "..pending.Id.." confirmation";return end
        end
        if now<nextRequest then return end
        if not context.Allowed then api.Status="Waiting for mining and the camp cycle to finish";return end
        if not context.Owned then api.Status="Waiting for GEO-MAG 3000 ownership";return end
        local selected,maxed=nil,0
        for offset=0,1 do
            local id=ids[(cursor-1+offset)%2+1];local def=context.Tracks[id];local level=context.Levels[id]or 0
            if def and level>=def.Max then maxed+=1
            elseif def and def.Cost and def.Cost<=context.Cash and not selected then selected={Id=id,Level=level+1,Cost=def.Cost,NextCursor=((cursor-1+offset)%2+1)%2+1}end
        end
        if maxed==2 then api.Status="Both GEO-MAG upgrades are maxed";return end
        if not selected then api.Status="Waiting for enough cash";return end
        api.InFlight=true;record("Request",selected)
        local ok,result=pcall(options.Invoke,selected.Id)
        api.InFlight=false;nextRequest=options.Now()+0.15
        if not ok then record("Error",{Error=tostring(result)});api.Stop("Purchase request failed; check upgrade state before retrying");return end
        record("Response",{Id=selected.Id,Result=result})
        if type(result)~="table"then api.Stop("Unexpected upgrade response");return end
        if result.Ok then
            pending={Id=selected.Id,Level=tonumber(result.Level)or selected.Level,Cost=selected.Cost,NextCursor=selected.NextCursor,Deadline=options.Now()+3}
            api.Status="Waiting for "..selected.Id.." confirmation"
        elseif result.Busy or result.Msg=="Not enough cash"then
            nextRequest=options.Now()+math.max(1,tonumber(result.Wait)or 0);api.Status=tostring(result.Msg or"Shop busy")
        else api.Stop(tostring(result.Msg or"Upgrade rejected"))end
    end
    return api
end

local function createLiveMagnetUpgrades(CrackSell)
    local P=game:GetService("Players").LocalPlayer
    local H=game:GetService("HttpService")
    local MTG=game:GetService("ReplicatedStorage"):WaitForChild("MTG")
    local State=require(P.PlayerScripts.MTGClient.State)
    local Upgrades=require(MTG.Config.Upgrades)
    local Mode=require(MTG.Modules.Mode)
    local remote=MTG.Remotes:WaitForChild("Shop")
    local events={};local dirty=false
    local api=createMagnetUpgradeController({Now=os.clock,Context=function()
        local levels=State.ctx().Upg
        local tracks={}
        for _,id in ipairs({"MagPower","MagSpeed"})do
            local def=Upgrades.ById[id];local cost=def.Costs[(levels[id]or 0)+1]
            tracks[id]={Max=#def.Costs,Cost=cost and Mode.price(cost)}
        end
        return {Allowed=State.role()=="Game"and State.run("Phase")=="Mining"and not CrackSell.Busy,
            Owned=State.set("Tools").Magnet==true,Levels=levels,Tracks=tracks,Cash=tonumber(P:GetAttribute("Cash"))or 0}
    end,Invoke=function(id)return remote:InvokeServer("Upgrade",id)end,Record=function(kind,data)
        events[#events+1]={Kind=kind,WallTimeMs=DateTime.now().UnixTimestampMillis,Data=data}
        if #events>80 then table.remove(events,1)end;dirty=true
    end})
    function api.Export()
        local ok,err=pcall(function()
            if not isfolder("Geode")then makefolder("Geode")end
            writefile("Geode/magnet_upgrade_diagnostics.json",H:JSONEncode({Version=1,Enabled=api.Enabled,Status=api.Status,
                Confirmed=api.Confirmed,Levels=State.ctx().Upg,Cash=P:GetAttribute("Cash"),Events=events}))
        end)
        if ok then dirty=false end;return ok,err
    end
    local unload=api.Unload
    function api.Unload()unload();api.Export()end
    task.spawn(function()
        local nextSave=0
        while api.Running do
            local ok,err=pcall(api.Tick)
            if not ok then api.Stop("Upgrade loop error: "..tostring(err))end
            if dirty and os.clock()>=nextSave then nextSave=os.clock()+2;api.Export()end
            task.wait(.1)
        end
    end)
    return api
end

local MagnetUpgrades=createLiveMagnetUpgrades(CrackSell)
local function createGeodeTeleportContinuation(options)
    local api={Enabled=true,Running=true,Installed=false}
    function api.Save()
        if not api.Running or not api.Enabled then return false end
        local state=options.GetState()
        state.Schema=1;state.GameId=10770110947;state.SourceJobId=options.JobId;state.SavedAt=options.Now()
        return options.WriteState(state)
    end
    function api.SetEnabled(value)
        api.Enabled=value==true
        options.WriteEnabled(api.Enabled)
        if api.Enabled and api.Running then
            if not options.HasQueued()then
                local ok,result=pcall(options.Queue)
                api.Installed=ok and result~=false
                if api.Installed then options.MarkQueued()end
            else api.Installed=true end
            api.Save()
        end
    end
    function api.Stop()
        if not api.Running then return end
        api.SetEnabled(false);api.Running=false
    end
    api.SetEnabled(true)
    return api
end

local function createLiveGeodeTeleport(getState)
    local H=game:GetService("HttpService")
    local P=game:GetService("Players").LocalPlayer
    local env=getgenv()
    local previous=env.__GeodeTeleportContinuation
    if previous and type(previous.Stop)=="function"then previous.Stop()end
    local enabledPath="GeodeHub/teleport_enabled.txt"
    local statePath="GeodeHub/teleport_state.json"
    pcall(function()if not isfolder("GeodeHub")then makefolder("GeodeHub")end end)
    local payload=[==[
task.spawn(function()
    if not game:IsLoaded()then game.Loaded:Wait()end
    if game.GameId~=10770110947 then return end
    local env=getgenv()
    local enabledOK,enabled=pcall(function()return readfile("GeodeHub/teleport_enabled.txt")end)
    if not enabledOK or enabled~="true"then return end
    if env.__GeodeQueuedBootJob==game.JobId then return end
    env.__GeodeQueuedBootJob=game.JobId
    local stateOK,state=pcall(function()return game:GetService("HttpService"):JSONDecode(readfile("GeodeHub/teleport_state.json"))end)
    if stateOK and type(state)=="table"and state.GameId==game.GameId
        and state.SourceJobId~=game.JobId and type(state.SavedAt)=="number"
        and os.time()-state.SavedAt>=0 and os.time()-state.SavedAt<900 then
        env.__GeodeTeleportResume=state
    end
    local function compileSource(source,isLoader)
        if type(source)~="string"or #source<(isLoader and 500 or 4000)then return nil end
        if isLoader then
            if not source:find("Crack the Geode! loader v2",1,true)or not source:find("validateGeodeHubSource",1,true)then return nil end
        elseif not source:find("-- Beyy Geode Hub | Crack the Geode!",1,true)or not source:find("return Hub",1,true)
            or not source:find("createNativeUI",1,true)or not source:find("Auto Geode Pickup",1,true)then return nil end
        return loadstring(source)
    end
    local ok,source=pcall(function()return readfile("GeodeHub/loader.lua")end)
    local compiled=ok and compileSource(source,true)
    if not compiled then
        ok,source=pcall(function()return game:HttpGet("https://raw.githubusercontent.com/sceneton/geode/main/loader.lua?refresh="..tostring(os.time()))end)
        compiled=ok and compileSource(source,true)
    end
    if not compiled then
        ok,source=pcall(function()return readfile("GeodeHub/main.lua")end)
        compiled=ok and compileSource(source,false)
    end
    if not compiled then
        ok,source=pcall(function()return readfile("GeodeHub/main.backup.lua")end)
        compiled=ok and compileSource(source,false)
    end
    if compiled then
        local success,err=pcall(compiled)
        if not success then warn("[Geode Hub] Teleport reload failed: "..tostring(err))end
    else warn("[Geode Hub] Teleport reload could not find an online or cached hub")end
end)
]==]
    local queue=queue_on_teleport or queueonteleport or env.queue_on_teleport or env.queueonteleport
    if type(queue)~="function"and type(syn)=="table"then queue=syn.queue_on_teleport end
    local stamp=tostring(game.PlaceId)..":"..game.JobId
    local api=createGeodeTeleportContinuation({GetState=getState,JobId=game.JobId,Now=os.time,
        WriteEnabled=function(value)pcall(writefile,enabledPath,value and"true"or"false")end,
        WriteState=function(state)return pcall(writefile,statePath,H:JSONEncode(state))end,
        Queue=function()if type(queue)~="function"then return false end;return queue(payload)end,
        HasQueued=function()return env.__GeodeQueuedJob==stamp end,
        MarkQueued=function()env.__GeodeQueuedJob=stamp end})
    local connection=P.OnTeleport:Connect(function()api.Save()end)
    local stop=api.Stop
    function api.Stop()stop();connection:Disconnect()end
    env.__GeodeTeleportContinuation=api
    return api
end

local NativeUI=createNativeUI()
local Window=NativeUI:CreateWindow({Title="Beyy Hub | Crack the Geode!",Folder="GeodeHub"})
Window:SetToggleKey(Enum.KeyCode.RightControl)
local Hub={Running=true,Version="1.4.2",Window=Window,Pickup=Pickup,Eggs=Eggs,CrackSell=CrackSell,MagnetUpgrades=MagnetUpgrades}
Window.Gui:SetAttribute("GeodeSessionVersion",Hub.Version)
env.GeodeHub=Hub
function Hub.Unload()
    if not Hub.Running then return end
    Hub.Running=false
    if Hub.Teleport then Hub.Teleport.Stop()end
    MagnetUpgrades.Unload()
    CrackSell.Unload()
    Pickup.Unload()
    Eggs.Unload()
    Window:Destroy()
    releaseGeodeBoot()
end
stop.OnInvoke=Hub.Unload
local overview=Window:Section({Title="Overview"})
local main=overview:Tab({Title="Main"})
local eggs=overview:Tab({Title="Eggs"})
local settings=overview:Tab({Title="Configs & Settings"})
main:Section({Title="Geode Collection"})
local pickupToggle=main:Toggle({Title="Auto Geode Pickup",Value=false,Callback=function(value)
    if value then Pickup.Start()else Pickup.Stop()end
end})
local pickupRange=main:Slider({Title="Pickup Range (studs)",Step=1,Value={Min=1,Max=26,Default=26},Callback=function(value)
    Pickup.SetRange(0,value)
end})
local live=main:Paragraph({Title="Pickup Status",Desc="Paused — enable Auto Geode Pickup to begin."})
main:Button({Title="Export Pickup Diagnostics",Callback=function()
    local ok,err=Pickup.Export()
    NativeUI:Notify({Title="Diagnostics",Content=ok and"Saved to Geode/auto_pickup_diagnostics.json"or tostring(err)})
end})
main:Section({Title="Cracking & Selling"})
local crackToggle=main:Toggle({Title="Auto Crack and Sell",Value=false,Callback=function(value)
    if value then CrackSell.Start()else CrackSell.Stop()end
end})
local cycleInterval=main:Slider({Title="Wait After Bag Change (seconds)",Step=1,Value={Min=2,Max=60,Default=10},Callback=function(value)
    CrackSell.SetInterval(value)
end})
local crackStatus=main:Paragraph({Title="Crack & Sell Status",Desc="Paused — returns to your pickup position after each cycle."})
main:Button({Title="Export Crack & Sell Diagnostics",Callback=function()
    local ok,err=CrackSell.Export()
    NativeUI:Notify({Title="Crack & Sell Diagnostics",Content=ok and"Saved to Geode/auto_crack_sell_diagnostics.json"or tostring(err)})
end})
eggs:Section({Title="Candy Shop"})
main:Section({Title="GEO-MAG 3000 Upgrades"})
local upgradeToggle=main:Toggle({Title="Auto Upgrade GEO-MAG 3000",Value=false,Callback=function(value)
    if value then MagnetUpgrades.Start()else MagnetUpgrades.Stop()end
end})
local upgradeStatus=main:Paragraph({Title="Magnet Upgrade Status",Desc="Paused — buys Pull Power and Pulse Speed with cash."})
local eggToggle=eggs:Toggle({Title="Auto Open Haunted Egg",Value=false,Callback=function(value)
    if value then Eggs.Start()else Eggs.Stop()end
end})
local eggStatus=eggs:Paragraph({Title="Egg Status",Desc="Paused. Opens 3 eggs per batch for 180 candy."})
eggs:Button({Title="Export Egg Diagnostics",Callback=function()
    local ok,err=Eggs.Export()
    NativeUI:Notify({Title="Egg Diagnostics",Content=ok and"Saved to Geode/haunted_egg_diagnostics.json"or tostring(err)})
end})
settings:Section({Title="Configuration"})
local config=Window.ConfigManager:CreateConfig("default")
local autoLoad=settings:Toggle({Title="Auto-load Saved Config",Value=true,Callback=function()end})
config:Register("AutoLoadConfig",autoLoad)
config:Register("AutoGeodePickup",pickupToggle)
config:Register("PickupRange",pickupRange)
config:Register("AutoOpenHauntedEgg",eggToggle)
config:Register("AutoCrackAndSell",crackToggle)
config:Register("CrackSellBagDelay",cycleInterval)
config:Register("AutoUpgradeMagnet",upgradeToggle)
settings:Button({Title="Save Config",Callback=function()
    local result,err=config:Save()
    NativeUI:Notify({Title="Config",Content=result and"Saved default config"or("Save failed: "..tostring(err))})
end})
settings:Button({Title="Load Config",Callback=function()
    local result,err=config:Load()
    NativeUI:Notify({Title="Config",Content=result and"Loaded default config"or(err or"Could not load config")})
end})
settings:Section({Title="Menu"})
local menuKey=settings:Keybind({Title="Menu Toggle Key",Value="RightControl",Callback=function(value)Window:SetToggleKey(value)end})
config:Register("MenuToggleKey",menuKey)
local continuation
local queueToggle=settings:Toggle({Title="Queue on Teleport",Value=true,Callback=function(value)
    if continuation then continuation.SetEnabled(value)end
end})
config:Register("QueueOnTeleport",queueToggle)
continuation=createLiveGeodeTeleport(function()
    return {Pickup=Pickup.Enabled,Range=Pickup.MaxRange,Eggs=Eggs.Enabled,CrackSell=CrackSell.Enabled,
        BagDelay=CrackSell.Interval,MagnetUpgrades=MagnetUpgrades.Enabled,MenuKey=Window.ToggleKey.Name,MenuClosed=Window.Closed}
end)
Hub.Teleport=continuation
settings:Button({Title="Unload Hub",Callback=Hub.Unload})
local session=settings:Paragraph({Title="Session",Desc="Crack the Geode!"})
local resumed=env.__GeodeTeleportResume
env.__GeodeTeleportResume=nil
local loaded,loadError=config:Load(true,type(resumed)=="table"and resumed.GameId==10770110947)
if type(resumed)=="table"and resumed.GameId==10770110947 then
    pickupRange:Set(tonumber(resumed.Range)or 26)
    cycleInterval:Set(tonumber(resumed.BagDelay)or 10)
    if type(resumed.MenuKey)=="string"and Enum.KeyCode[resumed.MenuKey]then menuKey:Set(resumed.MenuKey)end
    pickupToggle:Set(resumed.Pickup==true)
    eggToggle:Set(resumed.Eggs==true)
    crackToggle:Set(resumed.CrackSell==true)
    upgradeToggle:Set(resumed.MagnetUpgrades==true)
    if resumed.MenuClosed then Window:Close()end
end
continuation.Save()
boot:SetAttribute("Stage","Ready")
NativeUI:Notify({Title="Geode Hub",Content=type(resumed)=="table"and"Previous options restored after teleport."or(loaded and"Default config restored. Right Ctrl opens or closes the menu."or("Right Ctrl opens or closes the menu. "..tostring(loadError)))})
task.spawn(function()
    while Hub.Running and env.GeodeHub==Hub and not Window.Destroyed do
        if pickupToggle.Value~=Pickup.Enabled then pickupToggle:Set(Pickup.Enabled)end
        if eggToggle.Value~=Eggs.Enabled then eggToggle:Set(Eggs.Enabled)end
        if crackToggle.Value~=CrackSell.Enabled then crackToggle:Set(CrackSell.Enabled)end
        if upgradeToggle.Value~=MagnetUpgrades.Enabled then upgradeToggle:Set(MagnetUpgrades.Enabled)end
        local player=game:GetService("Players").LocalPlayer
        local mtg=game:GetService("ReplicatedStorage"):FindFirstChild("MTG")
        local state=mtg and mtg:FindFirstChild("State")
        upgradeStatus:SetDesc(MagnetUpgrades.Status.."\nConfirmed upgrades this session: "..MagnetUpgrades.Confirmed)
        crackStatus:SetDesc(string.format("%s\nCompleted cycles: %d | Sales: %d | Cash gained: %.2f\nPickup pauses during camp visits; returns afterward.",
            CrackSell.Status,CrackSell.Cycles,CrackSell.Sales,CrackSell.CashGained))
        eggStatus:SetDesc(string.format("%s\n3 eggs per batch | Cost: %d candy | Balance: %s\nOpened: %d | Requests: %d | Busy replies: %d\nLast: %s",
            Eggs.Status,Eggs.Price or 180,tostring(player:GetAttribute("Candy")or 0),Eggs.Opened,Eggs.Requests,Eggs.BusyReplies,Eggs.ResultText()))
        live:SetDesc(string.format("%s\nRange: 0–%d studs | Requests: %d | Tool feedback: %d | Items: %d\nBag: %s / %s",
            Pickup.Status or"Paused",Pickup.MaxRange,Pickup.Requests,Pickup.Feedback,Pickup.Items,
            tostring(player:GetAttribute("BagCount")or 0),(player:GetAttribute("BagCap")==-1 and"Unlimited"or tostring(player:GetAttribute("BagCap")or"—"))))
        session:SetDesc("Role: "..tostring(mtg and mtg:GetAttribute("Role")or"Loading").." | Phase: "..tostring(state and state:GetAttribute("Phase")or"Lobby").."\nVersion "..Hub.Version.." | Teleport queue: "..(not continuation.Enabled and"Off"or(continuation.Installed and"Ready"or"Unavailable")))
        task.wait(0.5)
    end
    if Hub.Running then Hub.Unload()end
end)
print("[Geode Hub] Native menu loaded; RightControl toggles the menu. Teleport queue="..tostring(continuation.Installed))
return Hub

end)
if not success then
    if env.GeodeHub and env.GeodeHub.Window and env.GeodeHub.Window.Gui:GetAttribute("GeodeSessionVersion")==geodeVersion then pcall(env.GeodeHub.Unload)end
    releaseGeodeBoot()
    error(result)
end
if not result then releaseGeodeBoot()end
return result -- return Hub is inside the protected constructor

