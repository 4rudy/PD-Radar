QBCore = exports['qb-core']:GetCoreObject()
local Plates = {}

local function getCarName(hash)
    local carName = "Unregistered"
    local carBrand = "Vehicle"
    local vehicle = exports["qb-core"]:getVehicleByHash(hash)

    if vehicle then
        carBrand = vehicle.brand
        carName = vehicle.name
    end
    return carBrand, carName
end

local function GenerateOwnerName()
	local first = Config.FakeNames.first[math.random(1, #Config.FakeNames.first)]
	local last = Config.FakeNames.last[math.random(1, #Config.FakeNames.last)]
	local fullname = first..' '..last
	return fullname
end

local function GetBoloStatus(plate, name)
    local result = MySQL.query.await("SELECT * FROM mdt_bolos WHERE plate = @plate OR owner = @owner OR individual = @person", {
		['@plate'] = plate,
		['@owner'] = name,
		['@person'] = name,
	})
	if result and result[1] then
		return true
	else
		return false
	end
end

local function GetStolenStatus(plate)
    local result = MySQL.query.await("SELECT * FROM mdt_vehicleinfo WHERE plate = @plate", {
        ['@plate'] = plate
    })
    if not result[1] then return false end
    if result[1].stolen then return true end
    return false
end

local function GetWarrantStatus(cid)
    local result = MySQL.query.await("SELECT * FROM mdt_convictions WHERE cid = @cid", {
        ['@cid'] = cid
    })
    if not result[1] then return false end
    if result[1].warrant == "1" then return true end
    return false
end

RegisterNetEvent("4rd-radar:server:AddStolenPlate", function(data)
	local veh, plate, name, class = data.veh, data.plate, data.name, data.class
	if type(plate) ~= "string" then return end
	local vehicle = MySQL.query.await("select pv.*, p.charinfo from player_vehicles pv LEFT JOIN players p ON pv.citizenid = p.citizenid WHERE pv.plate = :plate LIMIT 1", {
		plate = string.gsub(plate, "^%s*(.-)%s*$", "%1")
	})

	if not vehicle[1] then
		if not Plates[plate] then
			local person = GenerateOwnerName()
			Plates[plate] = {
				veh = veh,
				name = name,
				class = class,
				owner = person,
				bolo = false,
				stolen = true,
				warrant = false,
			}
		else
			Plates[plate].veh = veh
			Plates[plate].class = class
			Plates[plate].stolen = true
		end
	end
end)

RegisterNetEvent("4rd-radar:server:ScanPlate", function(data)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local veh, plate, name, class, locked = data.veh, data.plate, data.name, data.class, data.locked
	local vehData

	if plate ~= "" and plate ~= nil then
		local vehicle = MySQL.query.await("select pv.*, p.charinfo from player_vehicles pv LEFT JOIN players p ON pv.citizenid = p.citizenid WHERE pv.plate = :plate LIMIT 1", {
			plate = string.gsub(plate, "^%s*(.-)%s*$", "%1")
		})
		if vehicle and vehicle[1] then
			local owner = json.decode(vehicle[1].charinfo)
			local ownerName = owner['firstname'] .. " " .. owner['lastname']
			vehData = {
				veh = veh,
				name = name,
				class = class,
				plate = plate,
				stolen = GetStolenStatus(plate),
				bolo = GetBoloStatus(plate, tostring(ownerName)),
				warrant = GetWarrantStatus(vehicle[1].citizenid),
				owner = ownerName,
			}
		else
			if not Plates[plate] then
				local person = GenerateOwnerName()
				local bolo = GetBoloStatus(plate, tostring(person))
				Plates[plate] = {
					veh = veh,
					name = name,
					class = class,
					owner = person,
					bolo = bolo,
					stolen = false,
					warrant = false,
				}
				vehData = {
					veh = veh,
					name = name,
					class = class,
					plate = plate,
					owner = person,
					bolo = bolo,
					stolen = false,
					warrant = false,
				}
			else
				local owner = Plates[plate].owner
				local bolo = GetBoloStatus(plate, tostring(owner))
				if Plates[plate].bolo ~= bolo then
					Plates[plate].bolo = bolo
				end
				vehData = {
					veh = Plates[plate].veh,
					name = Plates[plate].name,
					class = Plates[plate].class,
					plate = plate,
					bolo = Plates[plate].bolo,
					stolen = Plates[plate].stolen,
					owner = owner,
					warrant = Plates[plate].warrant,
				}
			end
		end

		TriggerClientEvent("4rd-radar:client:ScanPlate", src, vehData, locked)
	else
		Player.Functions.Notify("Unable to read plate", 'error')
	end
end)

RegisterNetEvent("4rd-radar:server:checkLicensePlate", function(plate, model)
    local src = source
    local carName, carBrand = getCarName(model)
    if not plate or plate == "No Lock" then return end

    MySQL.Async.fetchSingle("SELECT * FROM `player_vehicles` WHERE `plate`=?", {plate}, function(result)
        local owner = "Unknown"
        if (result and result.citizenid) then
            owner = result.citizenid
        end

        TriggerClientEvent('chat:addMessage', src, {
            template = '<div class="chat-message server"><strong>Vehicle Scanner:</strong> <br>Plate: ' .. plate .. '<br>Model: ' .. carName .." ".. carBrand .. '<br>Owner CID: ' .. owner .. '</div>',
            args = {}
        })
    end)
end)

mc9.callback.create("4rd-radar:server:getName", function(source, hash)
    return getCarName(hash)
end)
