local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateUseableItem("fitbit", function(source)
    TriggerClientEvent('qb-fitbit:use', source)
end)

RegisterNetEvent('qb-fitbit:server:setValue', function(type, value)
    local src = source
    local ply = QBCore.Functions.GetPlayer(src)
    if not ply then return end

    local fitbitData = {}

    if type == "thirst" then
        local currentMeta = ply.PlayerData.metadata["fitbit"]
        fitbitData = {
            thirst = value,
            food = currentMeta.food
        }
    elseif type == "food" then
        local currentMeta = ply.PlayerData.metadata["fitbit"]
        fitbitData = {
            thirst = currentMeta.thirst,
            food = value
        }
    end

    ply.Functions.SetMetaData('fitbit', fitbitData)
end)
