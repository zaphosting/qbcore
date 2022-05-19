local QBCore = exports['qb-core']:GetCoreObject()

-- Functions

local function openWatch()
    SendNUIMessage({
        action = "openWatch",
        watchData = {}
    })
    SetNuiFocus(true, true)
end

local function closeWatch()
    SetNuiFocus(false, false)
end

local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Events

RegisterNUICallback('close', function(_, cb)
    closeWatch()
    cb('ok')
end)

RegisterNetEvent('qb-fitbit:use', function(_, cb)
    openWatch()
    cb('ok')
end)

-- NUI Callbacks

RegisterNUICallback('setFoodWarning', function(data, cb)
    local foodValue = tonumber(data.value)
    TriggerServerEvent('qb-fitbit:server:setValue', 'food', foodValue)
    QBCore.Functions.Notify(Lang:t('success.hunger_set', {hungervalue = foodValue}), 'success')
    cb('ok')
end)

RegisterNUICallback('setThirstWarning', function(data, cb)
    local thirstValue = tonumber(data.value)
    TriggerServerEvent('qb-fitbit:server:setValue', 'thirst', thirstValue)
    QBCore.Functions.Notify(Lang:t('success.thirst_set', {thirstvalue = thirstValue}), 'success')
    cb('ok')
end)

-- Threads

CreateThread(function()
    while true do
        Wait(5 * 60 * 1000)
        if LocalPlayer.state.isLoggedIn then
            QBCore.Functions.TriggerCallback('qb-fitbit:server:HasFitbit', function(hasItem)
                if hasItem then
                    local PlayerData = QBCore.Functions.GetPlayerData()
                    if PlayerData.metadata["fitbit"].food ~= nil then
                        if PlayerData.metadata["hunger"] < PlayerData.metadata["fitbit"].food then
                            TriggerEvent("chatMessage", Lang:t('info.fitbit'), "warning", Lang:t('warning.hunger_warning', {hunger = round(PlayerData.metadata["hunger"], 2)}))
                            PlaySound(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 0, 0, 1)
                        end
                    end

                    if PlayerData.metadata["fitbit"].thirst ~= nil then
                        if PlayerData.metadata["thirst"] < PlayerData.metadata["fitbit"].thirst then
                            TriggerEvent("chatMessage", Lang:t('info.fitbit'), "warning", Lang:t('warning.thirst_warning', {thirst = round(PlayerData.metadata["thirst"], 2)}))
                            PlaySound(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 0, 0, 1)
                        end
                    end
                end
            end, "fitbit")
        end
    end
end)
