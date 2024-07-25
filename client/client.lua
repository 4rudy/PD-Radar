QBCore = exports['qb-core']:GetCoreObject()

local radarOpen = false
local frontRadar = true
local rearRadar = true
local frontMode = "same"
local rearMode = "same"
local rearSpeedLimit = 0
local frontSpeedLimit = 0
local aci = { ["same"] = vector3(0.0, 100.0, 0.0), ["opp"] = vector3(-10.0, 100.0, 0.0) }
local frontPlateLocked = false
local rearPlateLocked = false
local frontSpeedLocked = false
local rearSpeedLocked = false
local currentFrontSpeed = 0
local currentRearSpeed = 0
local lockedFrontSpeed = 0
local lockedRearSpeed = 0
local lockedFrontPlate
local lockedRearPlate
local currentFrontPlate
local currentRearPlate
local currentFrontVehicle
local currentRearVehicle

local function canSeeRadar()
    local vehicle = GetVehiclePedIsIn(PlayerPedId())
    return DoesEntityExist(vehicle) and ((GetPedInVehicleSeat(vehicle, -1) == PlayerPedId()) or (GetPedInVehicleSeat(vehicle, 0) == PlayerPedId()))
end

local function formatSpeed(speed)
    return math.floor(speed * 2.236936)
end

function isPDCar()
    local curVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    if not curVeh then return false end
    return Config.PDCars[GetEntityModel(curVeh)]
end

function isPD()
    local curJob = QBCore.Functions.GetPlayerData().job
    return Config.PDJobs[curJob.name] or Config.PDJobs[curJob.type]
end

function GetFrontPlate()
	local data = {
		locked = GetVehicleDoorLockStatus(currentFrontVehicle),
		plate = currentFrontPlate,
		veh = currentFrontVehicle,
	}
	return data
end
exports("GetFrontPlate", GetFrontPlate)

local function displayRadar(shouldClose)
    if shouldClose and not canSeeRadar() then return end
    radarOpen = shouldClose
    SendNUIMessage({
        type = "Display",
        bool = radarOpen
    })
    if not shouldClose then
        SetNuiFocus(false, false)
    end
end

local function gettamsayi(num)
    return tonumber(string.format("%.0f", num))
end

local function GetVehicleInDirectionSphere(entFrom, coordFrom, coordTo)
    local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 50, entFrom, 0)
    local _, _, _, _, vehicle = GetShapeTestResult(rayHandle)
    return vehicle
end

local function scanPlate(plate, vehicle)
    TriggerServerEvent('4rd-radar:server:checkLicensePlate', plate, GetEntityModel(vehicle))
end

RegisterNetEvent('QBCore:Client:EnteredVehicle', function()
    if isPDCar() and not radarOpen then
        displayRadar(true)
    end
end)

RegisterNetEvent('QBCore:Client:LeftVehicle', function()
    radarOpen = false
    displayRadar(false)
end)

RegisterNUICallback("close", function()
    displayRadar(false)
end)

RegisterNUICallback("setSpeedLimit", function(data, cb)
    if data.type == "rear" then
        rearSpeedLimit = tonumber(data.limit)
    end
    if data.type == "front" then
        frontSpeedLimit = tonumber(data.limit)
    end
end)

RegisterNUICallback("setType", function(data, cb)
    if data.yon == "rear" then
        rearMode = data.type
    end
    if data.yon == "front" then
        frontMode = data.type
    end
end)

RegisterNUICallback("closeCursor", function(data, cb)
    SetNuiFocus(false,false)
end)

RegisterCommand("+toggleCarRadar", function()
    local curVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    if not curVeh then return end

    if GetVehicleClass(curVeh) ~= 18 or not isPD() then return end
    displayRadar(not radarOpen)
end)
RegisterKeyMapping('+toggleCarRadar', "Toggle Radar", 'keyboard', Config.Keys.Radar)

RegisterCommand("+toggleFrontPlateLock", function()
	if not canSeeRadar() or not radarOpen then return end

    local vehicle = GetVehiclePedIsIn(PlayerPedId())
    if ((GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId())) then return end

    frontPlateLocked = not frontPlateLocked
    if frontPlateLocked then
        lockedFrontPlate = currentFrontPlate
        PlaySoundFrontend( -1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 1 )
        QBCore.Functions.Notify("Front Plate Locked", "error")
    else
        lockedFrontPlate = nil
        QBCore.Functions.Notify("Front Plate Unlocked", "success")
    end
end)
RegisterKeyMapping("+toggleFrontPlateLock", "Front Plate Reader Lock/Unlock", "keyboard", Config.Keys.FrontLock)

RegisterCommand("+toggleRearPlateLock", function()
	if not canSeeRadar() or not radarOpen then return end

    local vehicle = GetVehiclePedIsIn(PlayerPedId())
    if ((GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId())) then return end

    rearPlateLocked = not rearPlateLocked
    if rearPlateLocked then
        lockedRearPlate = currentRearPlate
        PlaySoundFrontend( -1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 1 )
        QBCore.Functions.Notify("Rear Plate Locked", "error")
    else
        lockedRearPlate = nil
        QBCore.Functions.Notify("Rear Plate Unlocked", "success")
    end
end)
RegisterKeyMapping("+toggleRearPlateLock", "Rear Plate Reader Lock/Unlock", "keyboard", Config.Keys.RearLock)

RegisterCommand("+toggleFrontSpeedLock", function()
	if not canSeeRadar() or not radarOpen then return end

    local vehicle = GetVehiclePedIsIn(PlayerPedId())
    if ((GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId())) then return end

    frontSpeedLocked = not frontSpeedLocked
    if frontSpeedLocked then
        lockedFrontSpeed = currentFrontSpeed
        PlaySoundFrontend( -1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 1 )
        QBCore.Functions.Notify("Front Speed Locked", "error")
    else
        lockedFrontSpeed = 0
        QBCore.Functions.Notify("Front Speed Unlocked", "success")
    end
end)
RegisterKeyMapping("+toggleFrontSpeedLock", "Radar Front Speed Lock/Unlock", "keyboard", Config.Keys.FrontSpeed)

RegisterCommand("+toggleRearSpeedLock", function()
	if not canSeeRadar() or not radarOpen then return end

    local vehicle = GetVehiclePedIsIn(PlayerPedId())
    if ((GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId())) then return end

    rearSpeedLocked = not rearSpeedLocked
    if rearSpeedLocked then
        lockedRearSpeed = currentRearSpeed
        PlaySoundFrontend( -1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 1 )
        QBCore.Functions.Notify("Rear Speed Locked", "error")
    else
        lockedRearSpeed = 0
        QBCore.Functions.Notify("Rear Speed Unlocked", "success")
    end
end)
RegisterKeyMapping("+toggleRearSpeedLock", "Radar Rear Speed Lock/Unlock", "keyboard", Config.Keys.RearSpeed)

CreateThread(function()
    if not Config.ChatReader then return end

    RegisterCommand("+scanFrontPlate", function()
        local curVeh = GetVehiclePedIsIn(PlayerPedId(), false)
        if not curVeh then return end

        if GetVehicleClass(curVeh) ~= 18 or not isPD() or not isPDCar() then return end
        scanPlate(currentFrontPlate, currentFrontVehicle)
    end)
    RegisterKeyMapping('+scanFrontPlate', "Scan Front Plate", 'keyboard', 'UP')

    RegisterCommand("+scanRearPlate", function()
        local curVeh = GetVehiclePedIsIn(PlayerPedId(), false)
        if not curVeh then return end

        if GetVehicleClass(curVeh) ~= 18 or not isPD() or not isPDCar() then return end
        scanPlate(currentRearPlate, currentRearVehicle)
    end)
    RegisterKeyMapping('+scanRearPlate', "Scan Front Plate", 'keyboard', 'DOWN')
end)

CreateThread(function()
    if not Config.Cursor.key.active then return end
    while true do
        if radarOpen then
            Wait(0)
            local key1Pressed = false
            local key2Pressed = false

            if Config.Cursor.key.key1 then
                key1Pressed = IsControlPressed(0, Config.Cursor.key.key1)
            end

            if Config.Cursor.key.key2 ~= false then
                key2Pressed = IsControlJustPressed(0, Config.Cursor.key.key2)
            end

            if key1Pressed and (key2Pressed or Config.Cursor.key.key2 == false) then
                if radarOpen then
                    SetNuiFocus(true, true)
                end
            end
        else
            Wait(3000)
        end
    end
end)

CreateThread(function()
    while true do
        if radarOpen then
            local vehicle = GetVehiclePedIsIn(PlayerPedId())
            if canSeeRadar() then

                local vehicleSpeed = formatSpeed(GetEntitySpeed(vehicle))
                SendNUIMessage({
                    type = "updateRadar",
                    myspeed = vehicleSpeed
                })

                local vehiclePos = GetEntityCoords(vehicle, true)
                local h = gettamsayi(GetEntityHeading(vehicle), 0)
                if frontRadar then
                    local forwardPosition = GetOffsetFromEntityInWorldCoords(vehicle, aci[frontMode])
                    local fwdPos = { x = forwardPosition.x, y = forwardPosition.y, z = forwardPosition.z }
                    local _, fwdZ = GetGroundZFor_3dCoord(fwdPos.x, fwdPos.y, fwdPos.z + 500.0)

                    if fwdPos.z < fwdZ and not (fwdZ > vehiclePos.z + 1.0) then
                        fwdPos.z = fwdZ + 0.5
                    end
                    local fwdVeh = GetVehicleInDirectionSphere(vehicle, vehiclePos, fwdPos)
                    if DoesEntityExist(fwdVeh) and IsEntityAVehicle(fwdVeh) then
                        local fwdVehSpeed = gettamsayi(formatSpeed(GetEntitySpeed(fwdVeh)), 0)
                        local fwdVehHeading = GetEntityHeading(fwdVeh)
                        local plate = GetVehicleNumberPlateText(fwdVeh)
                        currentFrontVehicle = fwdVeh
                        currentFrontSpeed = (frontSpeedLocked and lockedFrontSpeed) or fwdVehSpeed
                        currentFrontPlate = (frontPlateLocked and lockedFrontPlate) or plate

                        SendNUIMessage({
                            type = "updateRadar",
                            frontplate = currentFrontPlate,
                            frontspeed = currentFrontSpeed
                        })
                        if frontSpeedLimit > 0 and frontSpeedLimit and currentFrontSpeed > frontSpeedLimit then
                            PlaySoundFrontend( -1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 1 )
                        end
                    end
                end
                if rearRadar then
                    local backwardPosition = GetOffsetFromEntityInWorldCoords(vehicle, aci[rearMode].x, -aci[rearMode].y, aci[rearMode].z)
                    local bwdPos = { x = backwardPosition.x, y = backwardPosition.y, z = backwardPosition.z }
                    local _, bwdZ = GetGroundZFor_3dCoord(bwdPos.x, bwdPos.y, bwdPos.z + 500.0)

                    if bwdPos.z < bwdZ and not (bwdZ > vehiclePos.z + 1.0) then
                        bwdPos.z = bwdZ + 0.5
                    end
                    local bwdVeh = GetVehicleInDirectionSphere(vehicle, vehiclePos, bwdPos)
                    if DoesEntityExist(bwdVeh) and IsEntityAVehicle(bwdVeh) then
                        local bwdVehSpeed = gettamsayi(formatSpeed(GetEntitySpeed(bwdVeh)), 0)
                        local bwdVehHeading = GetEntityHeading(bwdVeh)
                        local plate = GetVehicleNumberPlateText(bwdVeh)
                        currentRearVehicle = bwdVeh
                        currentRearSpeed = (rearSpeedLocked and lockedRearSpeed) or bwdVehSpeed
                        currentRearPlate = (rearPlateLocked and lockedRearPlate) or plate

                        SendNUIMessage({
                            type = "updateRadar",
                            rearplate = currentRearPlate,
                            rearspeed = currentRearSpeed
                        })

                        if rearSpeedLimit > 0 and rearSpeedLimit and currentRearSpeed > rearSpeedLimit then
                            PlaySoundFrontend( -1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 1 )
                        end
                    end
                end
            end
            Wait(200)
        else
            Wait(1000)
        end
    end
end)
