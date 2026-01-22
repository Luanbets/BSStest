local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

-- =========================================================
-- 1. LOAD MODULES (Đã điền sẵn đường dẫn chuẩn của bạn)
-- =========================================================
-- Lưu ý: Đảm bảo bạn đã lưu các file kia vào folder workspace của executor đúng theo đường dẫn này
local FieldDataPath   = "luanbets/bsstest/BSStest-main/Modules/FieldData.lua"
local MonsterDataPath = "luanbets/bsstest/BSStest-main/Modules/MonsterData.lua"
local UtilitiesPath   = "luanbets/bsstest/BSStest-main/Modules/Utilities.lua"

local function LoadModule(path)
    if not isfile(path) then
        warn("Không tìm thấy file: " .. path)
        return nil
    end
    return loadstring(readfile(path))()
end

local FieldData   = LoadModule(FieldDataPath)
local MonsterData = LoadModule(MonsterDataPath)
local Utilities   = LoadModule(UtilitiesPath)

-- Nếu thiếu file thì dừng luôn để tránh lỗi
if not FieldData or not MonsterData or not Utilities then
    return
end

-- =========================================================
-- 2. HÀM CHECK SỐ ONG THỰC TẾ (Lấy từ Hive)
-- =========================================================
local function getRealBeeCount()
    local honeycombs = Workspace:FindFirstChild("Honeycombs")
    if not honeycombs then return 0 end
    
    local myHive = nil
    for _, hive in pairs(honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and hive.Owner.Value == lp then
            myHive = hive
            break
        end
    end
    
    if myHive then
        local cellsFolder = myHive:FindFirstChild("Cells")
        if cellsFolder then
            local beeCount = 0
            for _, cell in pairs(cellsFolder:GetChildren()) do
                if cell:IsA("Model") and string.sub(cell.Name, 1, 1) == "C" then
                    local cellType = cell:FindFirstChild("CellType")
                    if cellType and (cellType.Value ~= "Empty" and cellType.Value ~= 0) then
                        beeCount = beeCount + 1
                    elseif not cellType then
                        beeCount = beeCount + 1
                    end
                end
            end
            return beeCount
        end
    end
    return 0
end

-- =========================================================
-- 3. CHẠY TEST TỰ ĐỘNG
-- =========================================================
local function Log(msg)
    print("[TEST]: " .. tostring(msg))
end

local Tools = { Utils = Utilities }

task.spawn(function()
    -- Lấy số ong hiện tại
    local currentBees = getRealBeeCount()
    Log("Số ong thực tế của bạn: " .. currentBees)
    
    Log("Đang quét quái vật...")
    
    -- Lấy danh sách quái dựa trên số ong thực
    local targets = MonsterData.GetTargets(FieldData, currentBees)

    if #targets == 0 then
        Log("Không tìm thấy quái nào (Có thể do Cooldown hoặc chưa đủ ong).")
    else
        Log("Tìm thấy " .. #targets .. " quái khả dụng.")
        for i, mob in ipairs(targets) do
            Log(">>> [" .. i .. "] Đang xử lý: " .. mob.Name)
            
            -- Gọi hàm giết quái
            local success = MonsterData.Kill(mob, Tools, Log)
            
            if success then
                Log("✅ Hoàn thành: " .. mob.Name)
            else
                Log("❌ Thất bại/Bỏ qua: " .. mob.Name)
            end
            task.wait(1.5) -- Nghỉ 1.5s giữa các con
        end
    end
    Log("Đã chạy xong quy trình test.")
end)
