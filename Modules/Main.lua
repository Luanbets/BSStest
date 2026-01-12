-- ====================================================
-- AUTO CLAIM HIVE V14.0 (ADVANCED TEST FARM)
-- ====================================================
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- BIẾN ĐIỀU KHIỂN
local isPaused = false
local currentFarmTask = nil -- Để quản lý việc dừng farm cũ khi chọn farm mới

-- ====================================================
-- UI SETUP
-- ====================================================
local uiName = "BSSA_Advanced_Test"
if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = uiName
pcall(function() screenGui.Parent = CoreGui end)
if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 350, 0, 320) -- Tăng kích thước
mainFrame.Position = UDim2.new(0.5, -175, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(0, 255, 255); stroke.Thickness = 1.5; stroke.Transparency = 0.5

-- Header
local titleLbl = Instance.new("TextLabel", mainFrame)
titleLbl.Size = UDim2.new(1, 0, 0, 30); titleLbl.Position = UDim2.new(0, 0, 0, 5)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "BSSA-Z: ADVANCED FARMING"
titleLbl.TextColor3 = Color3.fromRGB(255, 200, 0); titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 16

-- Log Area
local lblAction = Instance.new("TextLabel", mainFrame)
lblAction.Size = UDim2.new(1, -20, 0, 20); lblAction.Position = UDim2.new(0, 10, 0, 35)
lblAction.BackgroundTransparency = 1; lblAction.TextColor3 = Color3.fromRGB(255, 255, 255)
lblAction.Font = Enum.Font.GothamBold; lblAction.TextSize = 14; lblAction.TextXAlignment = Enum.TextXAlignment.Left; lblAction.Text = "Ready..."

-- BUTTON CONTAINER (SCROLLING)
local btnContainer = Instance.new("ScrollingFrame", mainFrame)
btnContainer.Size = UDim2.new(1, -20, 1, -100)
btnContainer.Position = UDim2.new(0, 10, 0, 60)
btnContainer.BackgroundTransparency = 1
btnContainer.ScrollBarThickness = 4

local uiGrid = Instance.new("UIGridLayout", btnContainer)
uiGrid.CellSize = UDim2.new(0, 100, 0, 35)
uiGrid.CellPadding = UDim2.new(0, 5, 0, 5)

-- HÀM LOG
local function Log(text, color)
    lblAction.Text = "> " .. text
    lblAction.TextColor3 = color or Color3.fromRGB(255, 255, 255)
end

local function WaitIfPaused() while isPaused do task.wait(0.5) end end

-- ====================================================
-- LOGIC TẢI MODULE
-- ====================================================
local function LoadModule(url)
    local noCacheUrl = url .. "?t=" .. tostring(tick())
    local success, content = pcall(function() return game:HttpGet(noCacheUrl) end)
    if success then
        local func = loadstring(content)
        if func then return func() end
    end
    return nil
end

-- ====================================================
-- LOGIC CHỌN FIELD (HỖ TRỢ)
-- ====================================================
-- 1. Hàm đếm số ong (Copy từ FieldData để đảm bảo dùng được ngay tại Main)
local function getRealBeeCount()
    local honeycombs = Workspace:FindFirstChild("Honeycombs") or Workspace:FindFirstChild("Hives")
    if not honeycombs then return 0 end
    
    for _, hive in pairs(honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and hive.Owner.Value == LocalPlayer then
            local cells = hive:FindFirstChild("Cells")
            if cells then
                local count = 0
                for _, cell in pairs(cells:GetChildren()) do
                    if cell:IsA("Model") and string.sub(cell.Name, 1, 1) == "C" then
                        local typeVal = cell:FindFirstChild("CellType")
                        if typeVal and typeVal.Value ~= "Empty" and typeVal.Value ~= 0 then count = count + 1 end
                    end
                end
                return count
            end
        end
    end
    return 0
end

-- 2. Map Material (Định nghĩa các cánh đồng cho từng loại)
local MaterialMap = {
    ["Blueberry"]  = {"Blue Flower Field", "Bamboo Field", "Pine Tree Forest", "Stump Field"},
    ["Strawberry"] = {"Strawberry Field", "Mushroom Field", "Rose Field", "Pepper Patch"},
    ["Sunflower"]  = {"Sunflower Field"},
    ["Pineapple"]  = {"Pineapple Patch"},
    ["Pumpkin"]    = {"Pumpkin Patch"},
    ["Cactus"]     = {"Cactus Field"},
}

-- 3. Hàm tìm cánh đồng tốt nhất
local function FindBestField(criteriaType, value, FieldData)
    local myBees = getRealBeeCount()
    local bestField = nil
    local highestReq = -1
    
    local candidateFields = {}

    -- Lọc danh sách candidate dựa trên criteria
    if criteriaType == "Honey" then
        -- Honey: Check tất cả field trong FieldData
        for name, _ in pairs(FieldData) do table.insert(candidateFields, name) end
    elseif criteriaType == "Material" then
        -- Material: Lấy từ Map
        candidateFields = MaterialMap[value] or {}
    elseif criteriaType == "Color" then
        -- Color: Lọc theo màu
        for name, data in pairs(FieldData) do
            if data.Color == value or data.Color == "Mixed" then -- Mixed farm được mọi màu
                table.insert(candidateFields, name)
            end
        end
    end

    -- Tìm field có ReqBees cao nhất mà người chơi đáp ứng được
    for _, fieldName in pairs(candidateFields) do
        local data = FieldData[fieldName]
        if data and myBees >= (data.ReqBees or 0) then
            if (data.ReqBees or 0) > highestReq then
                highestReq = (data.ReqBees or 0)
                bestField = fieldName
            end
        end
    end
    
    return bestField
end

-- ====================================================
-- INIT & BUTTONS
-- ====================================================
task.spawn(function()
    Log("Loading Modules...", Color3.fromRGB(255, 255, 0))

    -- Load Utilities
    local Utils = LoadModule("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/Utilities.lua")
    -- Load FieldData (Để lấy thông tin ReqBees)
    local FieldData = LoadModule("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/FieldData.lua")
    -- Load AutoFarm
    local AutoFarm = LoadModule("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/AutoFarm.lua")

    if not Utils or not FieldData or not AutoFarm then
        Log("❌ Load Failed! Check Net.", Color3.fromRGB(255, 0, 0))
        return
    end

    Log("Ready! Bees: " .. getRealBeeCount(), Color3.fromRGB(0, 255, 0))

    -- HÀM TẠO NÚT NHANH
    local function CreateBtn(text, color, callback)
        local btn = Instance.new("TextButton", btnContainer)
        btn.Text = text
        btn.BackgroundColor3 = color
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(function()
            if currentFarmTask then task.cancel(currentFarmTask) end -- Reset task cũ nếu cần
            callback()
        end)
    end

    -- === 1. FARM HONEY (BEST FIELD) ===
    CreateBtn("🏆 Farm Honey", Color3.fromRGB(255, 170, 0), function()
        local best = FindBestField("Honey", nil, FieldData)
        if best then
            Log("Go: " .. best, Color3.fromRGB(255, 255, 0))
            AutoFarm.StartFarm(best, Log, Utils)
        else
            Log("No suitable field!", Color3.fromRGB(255, 0, 0))
        end
    end)

    -- === 2. FARM COLORS ===
    CreateBtn("🔴 Red Field", Color3.fromRGB(200, 50, 50), function()
        local best = FindBestField("Color", "Red", FieldData)
        if best then
            Log("Go Red: " .. best, Color3.fromRGB(255, 100, 100))
            AutoFarm.StartFarm(best, Log, Utils)
        end
    end)

    CreateBtn("🔵 Blue Field", Color3.fromRGB(50, 100, 200), function()
        local best = FindBestField("Color", "Blue", FieldData)
        if best then
            Log("Go Blue: " .. best, Color3.fromRGB(100, 150, 255))
            AutoFarm.StartFarm(best, Log, Utils)
        end
    end)

    CreateBtn("⚪ White Field", Color3.fromRGB(200, 200, 200), function()
        local best = FindBestField("Color", "White", FieldData)
        if best then
            Log("Go White: " .. best, Color3.fromRGB(255, 255, 255))
            AutoFarm.StartFarm(best, Log, Utils)
        end
    end)

    -- === 3. FARM MATERIALS ===
    local mats = {"Sunflower", "Blueberry", "Strawberry", "Pineapple", "Pumpkin"}
    for _, mat in pairs(mats) do
        CreateBtn("Mat: " .. mat, Color3.fromRGB(100, 100, 100), function()
            local best = FindBestField("Material", mat, FieldData)
            if best then
                Log("Farm " .. mat .. ": " .. best, Color3.fromRGB(0, 255, 200))
                AutoFarm.StartFarm(best, Log, Utils)
            else
                Log("Can't farm " .. mat, Color3.fromRGB(255, 0, 0))
            end
        end)
    end
end)

-- Footer Controls
local pauseBtn = Instance.new("TextButton", mainFrame)
pauseBtn.Size = UDim2.new(1, -20, 0, 30); pauseBtn.Position = UDim2.new(0, 10, 1, -40)
pauseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50); pauseBtn.Text = "RUNNING / PAUSE"
pauseBtn.TextColor3 = Color3.fromRGB(0, 255, 100); pauseBtn.Font = Enum.Font.GothamBold; pauseBtn.TextSize = 14
Instance.new("UICorner", pauseBtn).CornerRadius = UDim.new(0, 6)

pauseBtn.MouseButton1Click:Connect(function()
    isPaused = not isPaused
    pauseBtn.Text = isPaused and "PAUSED" or "RUNNING"
    pauseBtn.TextColor3 = isPaused and Color3.fromRGB(255,80,80) or Color3.fromRGB(0,255,100)
end)

local minBtn = Instance.new("TextButton", mainFrame); minBtn.Size = UDim2.new(0,30,0,30); minBtn.Position = UDim2.new(1,-30,0,0); minBtn.BackgroundTransparency=1; minBtn.Text="-"; minBtn.TextColor3=Color3.new(1,1,1); minBtn.TextSize=20; minBtn.Font=Enum.Font.GothamBold
local openBtn = Instance.new("TextButton", screenGui); openBtn.Size=UDim2.new(0,50,0,50); openBtn.Position=UDim2.new(0,20,0.5,-25); openBtn.BackgroundColor3=Color3.fromRGB(25,25,30); openBtn.Text="BSSA"; openBtn.TextColor3=Color3.fromRGB(0,255,255); openBtn.Font=Enum.Font.GothamBold; openBtn.Visible=false
Instance.new("UICorner", openBtn).CornerRadius=UDim.new(0,12); Instance.new("UIStroke", openBtn).Color=Color3.fromRGB(0,255,255)

minBtn.MouseButton1Click:Connect(function() mainFrame.Visible=false; openBtn.Visible=true end)
openBtn.MouseButton1Click:Connect(function() mainFrame.Visible=true; openBtn.Visible=false end)
