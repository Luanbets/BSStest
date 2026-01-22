local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

-- =========================================================
-- 1. LOAD MODULES TỪ GITHUB (KHÔNG CẦN LƯU FILE)
-- =========================================================
-- Đường dẫn gốc tới thư mục Modules trên GitHub của bạn (Dạng RAW)
local RepoURL = "https://raw.githubusercontent.com/Luanbets/BSStest/main/Modules/"

local function LoadModule(name)
    -- Tải code từ GitHub về và chạy luôn
    return loadstring(game:HttpGet(RepoURL .. name .. ".lua"))()
end

local FieldData   = LoadModule("FieldData")
local MonsterData = LoadModule("MonsterData")
local Utilities   = LoadModule("Utilities")

-- =========================================================
-- 2. HÀM HỖ TRỢ (ĐẾM ONG)
-- =========================================================
local function getRealBeeCount()
    local honeycombs = Workspace:FindFirstChild("Honeycombs")
    if not honeycombs then return 0 end
    local myHive = nil
    for _, hive in pairs(honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and hive.Owner.Value == lp then
            myHive = hive break
        end
    end
    if myHive and myHive:FindFirstChild("Cells") then
        local count = 0
        for _, cell in pairs(myHive.Cells:GetChildren()) do
            if cell:IsA("Model") and (not cell:FindFirstChild("CellType") or (cell.CellType.Value ~= "Empty" and cell.CellType.Value ~= 0)) then
                count = count + 1
            end
        end
        return count
    end
    return 0
end

-- =========================================================
-- 3. CHẠY LOGIC CHÍNH
-- =========================================================
local function Log(msg) print("[TEST GITHUB]: " .. tostring(msg)) end
local Tools = { Utils = Utilities }

task.spawn(function()
    local bees = getRealBeeCount()
    Log("Số ong: " .. bees)
    
    -- Gọi MonsterData đã load từ GitHub
    local targets = MonsterData.GetTargets(FieldData, bees)
    
    if #targets > 0 then
        Log("Tìm thấy " .. #targets .. " quái.")
        for _, mob in ipairs(targets) do
            Log("Đang diệt: " .. mob.Name)
            MonsterData.Kill(mob, Tools, Log)
            task.wait(1)
        end
    else
        Log("Không có quái nào.")
    end
end)
