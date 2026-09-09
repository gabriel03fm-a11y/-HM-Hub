-- ============================================
--  RARE HUNTER 2026 - Versão Pura Lua
--  Corrigido: Sem links externos | Parada Total Funcional
--  Compatível com Delta Executor
-- ============================================

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")
local TweenService = game:GetService("TweenService")
local VU = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

-- Captura o clique do mouse para ataques automáticos
VU:CaptureController()

-- Tabela para armazenar os loops ativos e permitir parar todos
local activeLoops = {}
local isGlobalStopped = false

-- Função para equipar a melhor ferramenta
function EquipBestTool()
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            player.Character.Humanoid:EquipTool(tool)
            return true
        end
    end
    return false
end

-- Teleporte suave para as coordenadas
function TeleportTo(position)
    if not position or not hrp then return end
    local tween = TweenService:Create(hrp, TweenInfo.new(1.2, Enum.EasingStyle.Linear), {CFrame = CFrame.new(position)})
    tween:Play()
    tween.Completed:Wait()
end

-- Função para encontrar o Boss pelo nome
function FindBoss(bossName)
    local target = nil
    local dist = math.huge
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and string.find(v.Name, bossName) then
            local d = (hrp.Position - v.HumanoidRootPart.Position).Magnitude
            if d < dist then
                dist = d
                target = v
            end
        end
    end
    return target
end

-- Função para iniciar o ataque automático (clica segurando)
local isAttacking = false
function StartAttack()
    if isAttacking then return end
    isAttacking = true
    VU:Button1Down(Vector2.new(0,0))
    spawn(function()
        while isAttacking do
            VU:Click()
            task.wait(0.05)
        end
    end)
end

function StopAttack()
    isAttacking = false
    VU:Button1Up(Vector2.new(0,0))
end

-- ============================================
--  CRIAÇÃO DA INTERFACE (GUI)
-- ============================================
local screen = Instance.new("ScreenGui")
screen.Name = "RareHunterGUI"
screen.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 380, 0, 420)
frame.Position = UDim2.new(0.5, -190, 0.5, -210)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
frame.BackgroundTransparency = 0.15
frame.Active = true
frame.Draggable = true
frame.Parent = screen

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.Text = "🎯 RARE HUNTER 2026 (Puro Lua)"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

-- Lista de Itens Raros (Nome, Boss, Coordenadas)
local rareItems = {
    {name = "🌊 Coração de Leviatã", boss = "Leviathan", pos = Vector3.new(-3330, 10, 7150)},
    {name = "💀 Fragmento Sombrio", boss = "Darkbeard", pos = Vector3.new(-6250, 50, -2200)},
    {name = "⚔️ Artefato Divino", boss = "Dough King", pos = Vector3.new(-3150, 10, 6700)},
    {name = "🎸 Alma Guitarra", boss = "Cake Prince", pos = Vector3.new(-2800, 10, 5450)},
    {name = "👑 Chave do Indra", boss = "Indra", pos = Vector3.new(-3150, 10, 6700)}
}

local yPos = 55
local buttonRefs = {} -- Guarda referência dos botões

for _, item in ipairs(rareItems) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.92, 0, 0, 42)
    btn.Position = UDim2.new(0.04, 0, 0, yPos)
    btn.Text = item.name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 15
    btn.Parent = frame
    
    -- Dados específicos do botão
    btn.BossName = item.boss
    btn.TargetPos = item.pos
    btn.OriginalText = item.name
    btn.IsRunning = false
    btn.Connection = nil
    
    -- Função de clique do botão (liga/desliga)
    btn.MouseButton1Click:Connect(function()
        if isGlobalStopped then
            isGlobalStopped = false
        end
        
        if btn.IsRunning then
            -- PARA O LOOP
            btn.IsRunning = false
            if btn.Connection then
                btn.Connection:Disconnect()
                btn.Connection = nil
            end
            StopAttack()
            btn.Text = btn.OriginalText .. " ⏹️"
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
            return
        end
        
        -- INICIA O LOOP
        btn.IsRunning = true
        btn.Text = "🔄 " .. btn.OriginalText .. " (Buscando...)"
        btn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
        
        -- Equipa ferramenta
        EquipBestTool()
        
        -- Loop infinito via Heartbeat
        btn.Connection = RunService.Heartbeat:Connect(function()
            if not btn.IsRunning or isGlobalStopped then
                if isGlobalStopped then
                    btn.IsRunning = false
                    btn.Text = btn.OriginalText .. " ⏹️"
                    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
                    if btn.Connection then btn.Connection:Disconnect() end
                end
                return
            end
            
            -- 1. Teleporta para a área
            TeleportTo(btn.TargetPos)
            task.wait(0.8)
            
            -- 2. Procura o Boss
            local boss = FindBoss(btn.BossName)
            if boss and boss.Humanoid and boss.Humanoid.Health > 0 then
                -- Teleporta em cima do Boss
                local bossPos = boss.HumanoidRootPart.Position + Vector3.new(0, 5, 0)
                TeleportTo(bossPos)
                task.wait(0.3)
                
                btn.Text = "⚔️ " .. btn.OriginalText .. " (Atacando...)"
                StartAttack()
                
                -- Espera o Boss morrer
                repeat
                    task.wait(1)
                until not boss.Parent or boss.Humanoid.Health <= 0
                
                StopAttack()
                btn.Text = "✅ " .. btn.OriginalText .. " (Morto! Repetindo...)"
                task.wait(2) -- Espera respawn
            else
                btn.Text = "⏳ " .. btn.OriginalText .. " (Aguardando spawn...)"
                task.wait(4)
            end
        end)
    end)
    
    table.insert(buttonRefs, btn)
    yPos = yPos + 48
end

-- ============================================
--  BOTÃO "PARAR TUDO" (CORRIGIDO, SEM LINKS)
-- ============================================
local stopAll = Instance.new("TextButton")
stopAll.Size = UDim2.new(0.92, 0, 0, 45)
stopAll.Position = UDim2.new(0.04, 0, 0, yPos + 10)
stopAll.Text = "🛑 PARAR TODOS OS LOOPS"
stopAll.TextColor3 = Color3.fromRGB(255, 50, 50)
stopAll.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
stopAll.Font = Enum.Font.GothamBold
stopAll.TextSize = 16
stopAll.Parent = frame

stopAll.MouseButton1Click:Connect(function()
    isGlobalStopped = true
    StopAttack()
    
    -- Para todos os loops ativos
    for _, btn in pairs(buttonRefs) do
        if btn.IsRunning then
            btn.IsRunning = false
            if btn.Connection then
                btn.Connection:Disconnect()
                btn.Connection = nil
            end
            btn.Text = btn.OriginalText .. " ⏹️"
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
        end
    end
    print("🛑 Todos os loops foram parados com segurança!")
end)

-- Mensagem de confirmação no console
print("✅ RARE HUNTER 2026 (Puro Lua) CARREGADO!")
print("🎯 Clique em um item para começar o farm infinito.")
print("⚠️ Use por sua conta e risco (recomendo conta alternativa).")
