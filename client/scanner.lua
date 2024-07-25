QBCore = exports['qb-core']:GetCoreObject()
local lastVeh = nil
local lastPlate = nil

RegisterNetEvent("4rd-radar:client:AddStolenPlate", function(veh, plate)
    local hash = GetEntityModel(veh)
    local vehName, vehClass = mc9.callback.await("4rd-radar:server:getName", hash)

    local vData = {
        veh = veh,
        plate = plate,
        name = vehName,
        class = vehClass,
    }

    TriggerServerEvent("4rd-radar:server:AddStolenPlate", vData)
end)

RegisterNetEvent("4rd-radar:client:ScanPlate", function(vData, locked)
    local pData, scanStatus, plateStatus
    local flagReason = {}

    if vData.warrant or vData.stolen or vData.bolo then
        scanStatus = "bad"
        plateStatus = "FLAGGED"
        if vData.warrant then table.insert(flagReason, "WARRANT") end
        if vData.stolen then table.insert(flagReason, "STOLEN") end
        if vData.bolo then table.insert(flagReason, "BOLO") end
        if Config.LockOnFlag and not locked then
            TriggerEvent("wk:togglePlateLock", "front", true, true)
        end
    else
        scanStatus = "good"
        plateStatus = "NEGATIVE"
    end
    pData = {
        length = Config.NotifDuration,
        netId = vData.id,
        info = ('[%s]'):format(vData.plate),
        info2 = vData.owner,
        info3 = vData.name..", "..vData.class,
        plateStatus = plateStatus,
        flagReason = flagReason,
    }

    exports['ps-dispatch']:ScanPlate(pData, scanStatus)
end)

CreateThread(function()
    if not Config.PSDispatch then return end
    RegisterCommand('platescan', function()
        local curVeh = GetVehiclePedIsIn(PlayerPedId(), false)
        if not curVeh then return end

    	if GetVehicleClass(curVeh) ~= 18 or not isPD() or not isPDCar() then return end
    	if IsPauseMenuActive() or IsAimCamActive() then return end
    	local data, vData = GetFrontPlate(), {}

        if data.veh ~= nil and data.veh ~= 0 then
            local hash = GetEntityModel(data.veh)
            local vehName, vehClass = mc9.callback.await("4rd-radar:server:getName", hash)
    	    lastVeh = data.veh
    	    lastPlate = data.plate

    	    vData = {
                locked = data.locked,
    	    	veh = data.veh,
    	    	plate = data.plate,
    	    	name = vehName,
    	    	class = vehClass,
    	    }
            TriggerServerEvent("4rd-radar:server:ScanPlate", vData)
    	else
            local hash = GetEntityModel(lastVeh)
            local vehName, vehClass = mc9.callback.await("4rd-radar:server:getName", hash)

    		vData = {
                locked = data.locked,
    			veh = lastVeh,
    			plate = lastPlate,
    			name = vehName,
    			class = vehClass,
    		}
            TriggerServerEvent("4rd-radar:server:ScanPlate", vData)
    	end
    end)
    RegisterKeyMapping('platescan', 'Scan Plate (Police)', 'mouse_button', 'MOUSE_LEFT')
end)

RegisterNetEvent('4rd-radar:client:targetPlate', function(targetVeh)
    local hash = GetEntityModel(targetVeh)
    local vehName, vehClass = mc9.callback.await("4rd-radar:server:getName", hash)

	local vData = {
        locked = GetVehicleDoorLockStatus(targetVeh),
		veh = targetVeh,
		plate = QBCore.Functions.GetPlate(targetVeh),
		name = vehName,
		class = vehClass,
	}
	TriggerServerEvent("4rd-radar:server:ScanPlate", vData)
end)

CreateThread(function()
    local bones = {
        'numberplate', 'exhaust', 'boot'
    }
    exports['qb-target']:AddTargetBone(bones, {
        options = {
            {
                num = 1,
                icon = 'fa-solid fa-car',
                label = 'Run Plate',
                action = function(entity) TriggerEvent('4rd-radar:client:targetPlate', entity) end,
                canInteract = function() return isPD() end,
            }
        },
        distance = 4.0,
    })
end)
