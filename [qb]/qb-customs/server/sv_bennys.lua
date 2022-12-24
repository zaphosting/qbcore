-----------------------
----   Variables   ----
-----------------------
local QBCore = exports['qb-core']:GetCoreObject()
local RepairCosts = {}

-----------------------
----   Functions   ----
-----------------------

local function IsVehicleOwned(plate)
    local retval = false
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', { plate })
    if result then retval = true end
    return retval
end

-----------------------
----   Callbacks   ----
-----------------------

QBCore.Functions.CreateCallback('qb-customs:server:GetLocations', function(_, cb)
    cb(Config.Locations)
end)

-----------------------
---- Server Events ----
-----------------------

AddEventHandler("playerDropped", function()
    local source = source
    RepairCosts[source] = nil
end)

RegisterNetEvent('qb-customs:server:attemptPurchase', function(type, upgradeLevel, location)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    local job = Player.PlayerData.job.name
    local moneyType = Config.MoneyType
    local balance = Player.Functions.GetMoney(moneyType)
    local price
    if type == "repair" then
        price = RepairCosts[source] or Config.DefaultRepairPrice
        moneyType = Config.RepairMoneyType
        balance = Player.Functions.GetMoney(moneyType)
    elseif type == "performance" or type == "turbo" then
        price = vehicleCustomisationPrices[type].prices[upgradeLevel]
    else
        price = vehicleCustomisationPrices[type].price
    end
    local restrictionJobs = Config.Locations[location] and Config.Locations[location].restrictions.job or {}
    local paidBySociety = false
    local jobRestricted = false
    for i = 1, #restrictionJobs do
        if restrictionJobs[i] == job then
            jobRestricted = true
            paidBySociety = true
            break
        end
    end
    if not paidBySociety then
        for i = 1, #Config.PaidBySociety do
            if Config.PaidBySociety[i] == job then
                paidBySociety = true
                break
            end
        end
    end
    if paidBySociety then
        if exports['qb-management']:GetAccount(job) >= price then
            exports['qb-management']:RemoveMoney(job, price)
        else
            paidBySociety = false
            TriggerClientEvent('QBCore:Notify', source, "Your job society can't pay for this. You will be charged instead.")
        end
    end
    if balance >= price or paidBySociety then
        if not paidBySociety then
            Player.Functions.RemoveMoney(moneyType, price, "bennys")
        end
        if jobRestricted and job ~= 'mechanic' then
            exports['qb-management']:AddMoney("mechanic", price)
        end
        TriggerClientEvent('qb-customs:client:purchaseSuccessful', source)
    else
        TriggerClientEvent('qb-customs:client:purchaseFailed', source)
    end
end)

RegisterNetEvent('qb-customs:server:updateRepairCost', function(cost)
    local source = source
    RepairCosts[source] = cost
end)

RegisterNetEvent("qb-customs:server:updateVehicle", function(myCar)
    if IsVehicleOwned(myCar.plate) then
        MySQL.update('UPDATE player_vehicles SET mods = ? WHERE plate = ?', { json.encode(myCar), myCar.plate })
    end
end)

-- Use this event to dynamically enable/disable a location. Can be used to change anything at a location.
-- TriggerEvent('qb-customs:server:UpdateLocation', 'Hayes', 'settings', 'enabled', test)

RegisterNetEvent('qb-customs:server:UpdateLocation', function(location, type, key, value)
    local source = source
    if not QBCore.Functions.HasPermission(source, 'god') then return CancelEvent() end
    Config.Locations[location][type][key] = value
    TriggerClientEvent('qb-customs:client:UpdateLocation', -1, location, type, key, value)
end)

-- name, help, args, argsrequired, cb, perms
QBCore.Commands.Add('customs', 'Open customs (admin only)', {}, false, function(source)
    local ped = GetPlayerPed(source)
    TriggerClientEvent('qb-customs:client:EnterCustoms', source, {
        coords = GetEntityCoords(ped),
        heading = GetEntityHeading(ped),
        categories = {
            repair = true,
            mods = true,
            armor = true,
            respray = true,
            liveries = true,
            wheels = true,
            tint = true,
            plate = true,
            extras = true,
            neons = true,
            xenons = true,
            horn = true,
            turbo = true,
            cosmetics = true,
        }
    })
end, 'admin')
