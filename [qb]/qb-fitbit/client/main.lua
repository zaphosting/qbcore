local QBCore = exports['qb-core']:GetCoreObject()
local inWatch = false

-- Functions

local function openWatch()
    SendNUIMessage({
        action = "openWatch",
        watchData = {}
    })
    SetNuiFocus(true, true)
    inWatch = true
end

local function closeWatch()
    SetNuiFocus(false, false)
end

local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Events

RegisterNUICallback('close', function()
    closeWatch()
end)

RegisterNetEvent('qb-fitbit:use', function()
  openWatch()
end)

-- NUI Callbacks

RegisterNUICallback('setFoodWarning', function(data)
    local foodValue = tonumber(data.value)

    TriggerServerEvent('qb-fitbit:server:setValue', 'food', foodValue)

    QBCore.Functions.Notify('Fitbit: Hunger warning set to '..foodValue..'%')
end)

RegisterNUICallback('setThirstWarning', function(data)
    local thirstValue = tonumber(data.value)

    TriggerServerEvent('qb-fitbit:server:setValue', 'thirst', thirstValue)

    QBCore.Functions.Notify('Fitbit: Thirst warning set to '..thirstValue..'%')
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
                            TriggerEvent("chatMessage", "FITBIT ", "warning", "Your hunger is "..round(PlayerData.metadata["hunger"], 2).."%")
                            PlaySound(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 0, 0, 1)
                        end
                    end
                    if PlayerData.metadata["fitbit"].thirst ~= nil then
                        if PlayerData.metadata["thirst"] < PlayerData.metadata["fitbit"].thirst  then
                            TriggerEvent("chatMessage", "FITBIT ", "warning", "Your thirst is "..round(PlayerData.metadata["thirst"], 2).."%")
                            PlaySound(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 0, 0, 1)
                        end
                    end
                end
            end, "fitbit")
        end
    end
end)
