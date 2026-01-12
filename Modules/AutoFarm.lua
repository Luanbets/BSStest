local module = {}

function module.Run(LogFunc, WaitFunc, Utils)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- LOAD MODULES
    local shopUtilsUrl = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/ShopUtils.lua?t=" .. tostring(tick())
    local autoFarmUrl = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/AutoFarm.lua?t=" .. tostring(tick())
    
    LogFunc("Loading ShopUtils & AutoFarm...", Color3.fromRGB(255, 255, 255))
    
    local ShopUtils = nil
    local AutoFarm = nil
    
    -- Load ShopUtils
    local success1, content1 = pcall(function() return game:HttpGet(shopUtilsUrl) end)
    if success1 then
        local loadFunc = loadstring(content1)
        if loadFunc then ShopUtils = loadFunc() end
    end
    
    -- Load AutoFarm
    local success2, content2 = pcall(function() return game:HttpGet(autoFarmUrl) end)
    if success2 then
        local loadFunc = loadstring(content2)
        if loadFunc then AutoFarm = loadFunc() end
    end

    if not ShopUtils or not AutoFarm then
        LogFunc("⚠️ Lỗi tải module!", Color3.fromRGB(255, 80, 80))
        return
    end

    -- Tọa độ
    local EggShopPos = CFrame.new(-140.41, 4.69, 243.97)
    local ToolShopPos = CFrame.new(84.88, 4.51, 290.49)

    -- Data Check
    local currentData = Utils.LoadData() 
    local daMua = currentData.Cotmoc1_Progress or 0 
    
    if daMua >= 4 or currentData.Cotmoc1Done then
        LogFunc("Cotmoc1: Completed!", Color3.fromRGB(0, 255, 0))
        if not currentData.Cotmoc1Done then Utils.SaveData("Cotmoc1Done", true) end
        return
    end

    -- ===============================================
    -- 1. MUA TRỨNG (2 QUẢ)
    -- ===============================================
    if daMua < 2 then
        LogFunc("Moving to Egg Shop...", Color3.fromRGB(255, 220, 0)) 
        Utils.Tween(EggShopPos, WaitFunc)
        task.wait(1)
        
        for i = (daMua + 1), 2 do
            WaitFunc()
            game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Basic", ["Amount"]=1, ["Category"]="Eggs"})
            Utils.SaveData("Cotmoc1_Progress", i)
            daMua = i 
            LogFunc("Bought Egg " .. i .. "/2", Color3.fromRGB(200, 200, 200))
            task.wait(1)
        end
    end

    -- ===============================================
    -- 2. MUA BACKPACK (Step 3)
    -- ===============================================
    if daMua < 3 then
        LogFunc("Moving to Tool Shop...", Color3.fromRGB(255, 220, 0))
        Utils.Tween(ToolShopPos, WaitFunc)
        task.wait(1)

        WaitFunc()
        
        -- CHECK TRƯỚC KHI MUA
        local canBuy = ShopUtils.CheckBuy("Backpack", LogFunc)
        
        if not canBuy then
            -- THIẾU NGUYÊN LIỆU → GỌI AUTOFARM
            LogFunc("⚠️ Chưa đủ điều kiện mua Backpack", Color3.fromRGB(255, 150, 0))
            LogFunc("🔄 Bắt đầu Farm tự động...", Color3.fromRGB(0, 255, 255))
            
            AutoFarm.FarmUntilReady("Backpack", LogFunc, Utils)
            
            -- Sau khi farm xong, quay lại shop
            LogFunc("🔙 Quay lại Tool Shop...", Color3.fromRGB(255, 220, 0))
            Utils.Tween(ToolShopPos, WaitFunc)
            task.wait(1)
        end
        
        -- MUA BACKPACK
        LogFunc("Buying Backpack...", Color3.fromRGB(255, 255, 255))
        game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Backpack", ["Category"]="Accessory"})
        Utils.SaveData("Cotmoc1_Progress", 3)
        daMua = 3
        LogFunc("✅ Bought Backpack", Color3.fromRGB(0, 255, 0))
        task.wait(1)
    end

    -- ===============================================
    -- 3. MUA RAKE (Step 4)
    -- ===============================================
    if daMua == 3 then
        if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then
            task.wait(2)
        end
        
        LogFunc("Moving to Tool Shop...", Color3.fromRGB(255, 220, 0))
        Utils.Tween(ToolShopPos, WaitFunc)
        task.wait(1)

        WaitFunc()
        
        -- CHECK TRƯỚC KHI MUA
        local canBuy = ShopUtils.CheckBuy("Rake", LogFunc)
        
        if not canBuy then
            LogFunc("⚠️ Chưa đủ điều kiện mua Rake", Color3.fromRGB(255, 150, 0))
            LogFunc("🔄 Bắt đầu Farm tự động...", Color3.fromRGB(0, 255, 255))
            
            AutoFarm.FarmUntilReady("Rake", LogFunc, Utils)
            
            LogFunc("🔙 Quay lại Tool Shop...", Color3.fromRGB(255, 220, 0))
            Utils.Tween(ToolShopPos, WaitFunc)
            task.wait(1)
        end
        
        -- MUA RAKE
        LogFunc("Buying Rake...", Color3.fromRGB(255, 255, 255))
        game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Rake", ["Category"]="Collector"})
        Utils.SaveData("Cotmoc1_Progress", 4)
        daMua = 4
        LogFunc("✅ Bought Rake", Color3.fromRGB(0, 255, 0))
        task.wait(1)
    end

    -- ===============================================
    -- HOÀN THÀNH
    -- ===============================================
    if daMua >= 4 then
        LogFunc("🎉 Cotmoc1 Full Done!", Color3.fromRGB(0, 255, 0))
        Utils.SaveData("Cotmoc1Done", true)
    else
        LogFunc("⏳ Cotmoc1 Paused at step " .. daMua, Color3.fromRGB(255, 200, 100))
    end
end

return module
