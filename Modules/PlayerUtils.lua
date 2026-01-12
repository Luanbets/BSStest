local PlayerUtils = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- =======================================================
-- 1. TRUY XUẤT DỮ LIỆU CƠ BẢN
-- =======================================================
function PlayerUtils.GetHoney()
    if LocalPlayer:FindFirstChild("CoreStats") and LocalPlayer.CoreStats:FindFirstChild("Honey") then
        return LocalPlayer.CoreStats.Honey.Value
    end
    return 0
end

function PlayerUtils.GetItemAmount(itemName)
    -- Tìm trong túi đồ (Inventory)
    local inventory = LocalPlayer:FindFirstChild("b")
    if inventory and inventory:FindFirstChild(itemName) then
        return inventory[itemName].Value
    end

    -- Tìm trong kho trứng (EggStats)
    local eggs = LocalPlayer:FindFirstChild("EggStats")
    if eggs and eggs:FindFirstChild(itemName) then
        return eggs[itemName].Value
    end

    return 0
end

-- =======================================================
-- 2. KIỂM TRA ĐIỀU KIỆN (CORE LOGIC)
-- Trả về: { success = bool, missing = table, honey_needed = number }
-- =======================================================
function PlayerUtils.CheckRequirements(price, ingredients)
    local result = {
        success = true,
        missingItems = {},    -- Danh sách item còn thiếu
        missingHoney = 0      -- Số Honey còn thiếu
    }

    -- 1. Check Honey
    local currentHoney = PlayerUtils.GetHoney()
    if price and currentHoney < price then
        result.success = false
        result.missingHoney = price - currentHoney
    end

    -- 2. Check Nguyên Liệu
    if ingredients then
        for _, req in pairs(ingredients) do
            local itemName = req[1]
            local needAmount = req[2]
            local currentAmount = PlayerUtils.GetItemAmount(itemName)

            if currentAmount < needAmount then
                result.success = false
                -- Lưu lại tên và số lượng còn thiếu để Manager biết đi farm
                table.insert(result.missingItems, {
                    Name = itemName,
                    Need = needAmount,
                    Have = currentAmount,
                    Missing = needAmount - currentAmount
                })
            end
        end
    end

    return result
end

return PlayerUtils
