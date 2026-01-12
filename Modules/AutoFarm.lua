local module = {}
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Biến toàn cục để quản lý việc đang Farm
_G.IsFarming = false 

-- =======================================================
-- 1. LIÊN KẾT DỮ LIỆU (Worker gọi Data)
-- =======================================================
local function GetFieldData()
    -- Load FieldData để lấy tọa độ và size
    local url = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/FieldData.lua"
    local success, content = pcall(function() return game:HttpGet(url) end)
    if success then
        local func = loadstring(content)
        if func then return func() end
    end
    return nil
end

-- =======================================================
-- 2. HÀM TÌM TOKEN (Logic Worker)
-- =======================================================
local function FindBestToken(fieldPos, fieldSize)
    local closestToken = nil
    local minDist = 80 -- Chỉ tìm token trong phạm vi gần
    
    local folder = Workspace:FindFirstChild("Collectibles")
    if not folder then return nil end

    for _, token in pairs(folder:GetChildren()) do
        -- Token phải có Part (BasePart) hoặc Model có PrimaryPart
        -- Dữ liệu Token lấy theo TokenData nếu cần ưu tiên sau này
        local pos = nil
        if token:IsA("BasePart") then pos = token.Position 
        elseif token:IsA("Model") and token.PrimaryPart then pos = token.PrimaryPart.Position end
        
        if pos then
            -- Kiểm tra token có nằm trong Cánh Đồng không
            local distToField = (pos - fieldPos).Magnitude
            if distToField <= (fieldSize.X / 1.2) then -- Chia 1.2 để chắc chắn nằm trong vùng
                local distToPlayer = (LocalPlayer.Character.HumanoidRootPart.Position - pos).Magnitude
                if distToPlayer < minDist then
                    minDist = distToPlayer
                    closestToken = pos
                end
            end
        end
    end
    return closestToken
end

-- =======================================================
-- 3. HÀM FARM CHÍNH (Worker thực thi)
-- =======================================================
function module.Farm(fieldName, Utils)
    local FieldData = GetFieldData()
    if not FieldData or not FieldData[fieldName] then
        warn("AutoFarm: Không tìm thấy data của " .. tostring(fieldName))
        return
    end

    local info = FieldData[fieldName] -- Lấy ID, Pos, Size, Color
    local fPos = info.Pos
    local fSize = info.Size
    
    _G.IsFarming = true

    -- A. Bay tới cánh đồng
    local targetCFrame = CFrame.new(fPos.X, fPos.Y + 5, fPos.Z)
    if Utils then Utils.Tween(targetCFrame) end -- Dùng Tween của Utilities
    
    task.wait(0.5)

    -- B. Vòng lặp Farm (Chạy liên tục cho đến khi _G.IsFarming = false)
    local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    while _G.IsFarming and LocalPlayer.Character do
        Humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if not Humanoid or not Root then task.wait(1) continue end

        -- 1. Tìm Token
        local tokenPos = FindBestToken(fPos, fSize)

        if tokenPos then
            -- 2. Nếu có Token -> Lao tới lấy
            Humanoid:MoveTo(tokenPos)
            local timeOut = 0
            while (Root.Position - tokenPos).Magnitude > 4 and timeOut < 2 do
                task.wait(0.1); timeOut = timeOut + 0.1
                if not _G.IsFarming then break end
            end
        else
            -- 3. Nếu không có Token -> Đi Random trong vùng Field Size
            local rX = math.random(-fSize.X/2.5, fSize.X/2.5)
            local rZ = math.random(-fSize.Z/2.5, fSize.Z/2.5)
            local targetPos = Vector3.new(fPos.X + rX, fPos.Y, fPos.Z + rZ)
            
            Humanoid:MoveTo(targetPos)
            
            -- Đợi đi tới nơi (hoặc ngắt nếu thấy token mới xuất hiện)
            local timeOut = 0
            while (Root.Position - targetPos).Magnitude > 4 and timeOut < 1.5 do
                task.wait(0.1); timeOut = timeOut + 0.1
                -- Nếu thấy token ngon hơn thì bỏ đi random, quay lại lụm token
                if FindBestToken(fPos, fSize) then break end 
                if not _G.IsFarming then break end
            end
        end
        task.wait()
    end
    
    -- Dừng nhân vật khi tắt Farm
    if Humanoid then Humanoid:MoveTo(Root.Position) end
end

-- Hàm ngắt Farm
function module.Stop()
    _G.IsFarming = false
end

return module
