local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()
local PlayerGui = Player:WaitForChild("PlayerGui")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")

-- Limpieza de interfaces previas para evitar que se amontonen
if PlayerGui:FindFirstChild("JuanHUB_MS") then PlayerGui.JuanHUB_MS:Destroy() end
if game.CoreGui:FindFirstChild("JuanEdgeScanner") then game.CoreGui.JuanEdgeScanner:Destroy() end

_G.CookingLoop = false
_G.DeleteMode = false
local DeletedObjects = {}

-- Borde Rojo para el borrador (Solo Piezas Individuales)
local selectionEdge = Instance.new("SelectionBox")
selectionEdge.Name = "JuanEdgeScanner"
selectionEdge.Color3 = Color3.fromRGB(255, 0, 0)
selectionEdge.LineThickness = 0.1
selectionEdge.Parent = game.CoreGui

-- --- LÓGICA DE BORRADO PROTEGIDA ---
local function getTarget(obj)
    if not obj or not obj:IsA("BasePart") or obj:IsA("Terrain") then return nil end
    local name = obj.Name:lower()
    
    -- Bloqueo de suelo y mapa
    if name:find("baseplate") or name:find("floor") or name:find("suelo") then 
        return nil 
    end
    
    -- BLOQUEO TOTAL DE JUGADORES (No permite borrar personajes ni NPCs)
    if obj:FindFirstAncestorOfClass("Model") and obj:FindFirstAncestorOfClass("Model"):FindFirstChildOfClass("Humanoid") then
        return nil
    end

    return obj
end

-- --- INTERFAZ (JuanXit V42) ---
local sg = Instance.new("ScreenGui", PlayerGui); 
sg.Name = "JuanHUB_MS"; 
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true -- Para que se vea bien en móviles

-- Botón Flotante para abrir/cerrar (Basado en tus preferencias de control)
local toggleBtn = Instance.new("TextButton", sg)
toggleBtn.Size, toggleBtn.Position = UDim2.new(0, 85, 0, 35), UDim2.new(0, 10, 0.45, 0)
toggleBtn.BackgroundColor3, toggleBtn.Text = Color3.fromRGB(0, 255, 255), "CERRAR"
toggleBtn.Font, toggleBtn.TextSize = Enum.Font.SourceSansBold, 14
toggleBtn.ZIndex = 10

local f = Instance.new("Frame", sg)
f.Size, f.Position = UDim2.new(0, 200, 0, 480), UDim2.new(0.1, 0, 0.2, 0)
f.BackgroundColor3, f.BorderColor3 = Color3.fromRGB(15, 15, 15), Color3.fromRGB(0, 255, 255)
f.Active, f.Draggable = true, true -- Panel movible

local function createL(txt, y, sz, col)
    local l = Instance.new("TextLabel", f)
    l.Size, l.Position = UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, y)
    l.BackgroundTransparency, l.TextColor3 = 1, col or Color3.new(1,1,1)
    l.Text, l.Font, l.TextSize = txt, Enum.Font.Code, sz; return l
end

local title = createL("PhantomxSB 🚷", 5, 15)
createL("[ MONEY COUNTER ]", 30, 13, Color3.new(0, 1, 0))
local moneyL = createL("$ 0", 50, 18, Color3.new(1, 1, 0))

createL("[ INGREDIENTES ]", 80, 13, Color3.new(0.5, 0.5, 1))
local watL = createL("Water: 0", 100, 12)
local sugL = createL("Sugar: 0", 120, 12)
local gelL = createL("Gelatin: 0", 140, 12)

createL("[ PRODUCTOS ]", 170, 13, Color3.new(1, 0.5, 0))
local lgL = createL("Large 4150: 0", 190, 12)
local mdL = createL("Medium 2840: 0", 210, 12)
local smL = createL("Small 1470: 0", 230, 12)

local function createB(txt, y, col)
    local b = Instance.new("TextButton", f)
    b.Size, b.Position = UDim2.new(0.9, 0, 0, 35), UDim2.new(0.05, 0, 0, y)
    b.Text, b.BackgroundColor3, b.TextColor3 = txt, col, Color3.new(1,1,1)
    b.Font, b.TextSize = Enum.Font.SourceSansBold, 15; return b
end

local bAuto = createB("AutoMS", 265, Color3.fromRGB(0, 100, 0))
local bStop = createB("PARAR", 305, Color3.fromRGB(150, 0, 0))
local bDel = createB("DELETE: OFF", 360, Color3.fromRGB(50, 50, 50))
local bRes = createB("RESTABLECER", 410, Color3.fromRGB(0, 80, 150))

-- --- FUNCIONES ---

bAuto.MouseButton1Click:Connect(function()
    if _G.CookingLoop then return end
    _G.CookingLoop = true; bAuto.Text = "COCINANDO..."
    task.spawn(function()
        while _G.CookingLoop do
            local function useTool(toolName, waitT)
                if not _G.CookingLoop then return end
                local tool = Player.Backpack:FindFirstChild(toolName) or Player.Character:FindFirstChild(toolName)
                if tool then
                    Player.Character.Humanoid:EquipTool(tool); task.wait(0.3)
                    VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.05)
                    VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    if waitT then task.wait(waitT) end
                end
            end
            useTool("Water", 20.5)
            useTool("Sugar Block Bag", 1.5)
            useTool("Gelatin", 45.5)
            useTool("Empty Bag", 2)
            task.wait(1)
        end
    end)
end)

bStop.MouseButton1Click:Connect(function() _G.CookingLoop = false; bAuto.Text = "AutoMS" end)

bDel.MouseButton1Click:Connect(function()
    _G.DeleteMode = not _G.DeleteMode
    bDel.Text = _G.DeleteMode and "DELETE: ON" or "DELETE: OFF"
    bDel.BackgroundColor3 = _G.DeleteMode and Color3.new(0.7, 0, 0) or Color3.fromRGB(50, 50, 50)
end)

bRes.MouseButton1Click:Connect(function()
    for _, d in pairs(DeletedObjects) do if d.inst then d.inst.Parent = d.parent end end
    DeletedObjects = {}
end)

-- Borrado por clic o tecla Z
local function doDelete()
    local target = getTarget(Mouse.Target)
    if target and _G.DeleteMode then
        table.insert(DeletedObjects, {inst = target, parent = target.Parent})
        target.Parent = nil
    end
end

UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.Z then doDelete() end
end)

Mouse.Button1Down:Connect(function()
    if _G.DeleteMode then doDelete() end
end)

-- --- BUCLES DE ACTUALIZACIÓN ---

task.spawn(function()
    while true do
        selectionEdge.Adornee = (_G.DeleteMode and Mouse.Target) and getTarget(Mouse.Target) or nil
        task.wait(0.03)
    end
end)

task.spawn(function()
    while true do
        local l, m, sm, w, s, g, total = 0, 0, 0, 0, 0, 0, 0
        local items = Player.Backpack:GetChildren()
        if Player.Character:FindFirstChildOfClass("Tool") then table.insert(items, Player.Character:FindFirstChildOfClass("Tool")) end
        
        for _, i in pairs(items) do
            local n = i.Name
            if n:find("Large") then l = l + 1; total = total + 4150
            elseif n:find("Medium") then m = m + 1; total = total + 2840
            elseif n:find("Small") then sm = sm + 1; total = total + 1470
            elseif n:find("Water") then w = w + 1
            elseif n:find("Sugar") then s = s + 1
            elseif n:find("Gelatin") then g = g + 1 end
        end
        
        moneyL.Text = "$ "..total
        watL.Text = "Water: "..w
        sugL.Text = "Sugar: "..s
        gelL.Text = "Gelatin: "..g
        lgL.Text = "Large 4150: "..l
        mdL.Text = "Medium 2840: "..m
        smL.Text = "Small 1470: "..sm
        task.wait(1)
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    f.Visible = not f.Visible
    toggleBtn.Text = f.Visible and "CERRAR" or "ABRIR"
    toggleBtn.BackgroundColor3 = f.Visible and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 50, 50)
end))