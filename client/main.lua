QBCore = exports['qb-core']:GetCoreObject()

local PlayerData = {}
local training = false
local resting = false
local membership = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    FetchSkills()
    if Config.DeleteStats == true then
		while true do
			local seconds = Config.UpdateFrequency * 1000
			Wait(seconds)

			for skill, value in pairs(Config.Skills) do
				UpdateSkill(skill, value["RemoveAmount"])
			end

			TriggerServerEvent("qb-skills:update", json.encode(Config.Skills))
		end
	end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

local function round(num) 
    return math.floor(num+.5) 
end

local function GetCurrentSkill(skill)
    return Config.Skills[skill]
end

function RefreshSkills()
    for type, value in pairs(Config.Skills) do
        if value["Stat"] then
            StatSetInt(value["Stat"], round(value["Current"]), true)
        end
    end
end

local function FetchSkills()
    QBCore.Functions.TriggerCallback("qb-skills:fetchStatus", function(data)
		if data then
            for status, value in pairs(data) do
                if Config.Skills[status] then
                    Config.Skills[status]["Current"] = value["Current"]
                else
                    print("Removing: " .. status) 
                end
            end
		end
        RefreshSkills()
    end)
end

RegisterCommand('skills', function() 
    for type, value in pairs(Config.Skills) do
        TriggerEvent('chat:addMessage', {
            template = '<div class="chat-message advert"><div class="chat-message-body"><strong>Habs</strong><br>'..type .. ': <span style="color:#0d7ec0">' .. value["Current"] ..'</div></div>',
        })
	end
end, false)


local function UpdateSkill(skill, amount)

    if not Config.Skills[skill] then
        print("Skill " .. skill .. " doesn't exist")
        return
    end
    local SkillAmount = Config.Skills[skill]["Current"]
    if SkillAmount + tonumber(amount) < 0 then
        Config.Skills[skill]["Current"] = 0
    elseif SkillAmount + tonumber(amount) > 100 then
        Config.Skills[skill]["Current"] = 100
    else
        Config.Skills[skill]["Current"] = SkillAmount + tonumber(amount)
    end
    RefreshSkills()
    if tonumber(amount) > 0 then
        QBCore.Functions.Notify('~g~+' .. amount .. '% ~s~' .. skill, 'success')
    end
	TriggerServerEvent("qb-skills:update", json.encode(Config.Skills))
end

local function CheckTraining()
	if resting == true then
        QBCore.Functions.Notify('You\'re resting', 'primary')
		resting = false
		Wait(60000)
		training = false
	end
	if resting == false then
        QBCore.Functions.Notify('You can now do exercise again', 'success')
	end
end


local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

CreateThread(function()
		while true do
			Wait(60000)
			local ped = PlayerPedId()
			local vehicle = GetVehiclePedIsUsing(ped)
            
		if IsPedRunning(ped) then
			UpdateSkill("resistance", 0.2)
		elseif IsPedInMeleeCombat(ped) then
			UpdateSkill("strength", 0.5)
		elseif IsPedSwimmingUnderWater(ped) then
			UpdateSkill("diving", 0.5)
		elseif IsPedShooting(ped) then
			UpdateSkill("shooting", 0.5)
		elseif DoesEntityExist(vehicle) then
			local speed = GetEntitySpeed(vehicle) * 3.6

			if GetVehicleClass(vehicle) == 8 or GetVehicleClass(vehicle) == 13 and speed >= 5 then
				local rotation = GetEntityRotation(vehicle)
				if IsControlPressed(0, 210) then
					if rotation.x >= 25.0 then
						UpdateSkill("Raise front wheel", 0.5)
					end 
				end
			end
			if speed >= 140 then
				UpdateSkill("driving", 0.2)
			end
		end
	end
end)

RegisterCommand('habilidades', function() 
	SkillMenu()
end, false)
	
CreateThread(function()
	blip = AddBlipForCoord(-1201.2257, -1568.8670, 4.6101)
	SetBlipSprite(blip, 311)
	SetBlipDisplay(blip, 4)
	SetBlipScale(blip, 0.8)
	SetBlipColour(blip, 7)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString('Gym')
	EndTextCommandSetBlipName(blip)
end)

RegisterNetEvent('qb-gym:trueMembership', function()
	membership = true
end)

RegisterNetEvent('qb-gym:falseMembership', function()
	membership = false
end)

local Shops = {
    [1] = {
        coords = vector3(-1195.6551, -1577.7689, 4.631155)
    },
}

CreateThread(function()
    while true do
        sleep = 1000
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            for k, v in pairs(Shops) do
                local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                if dist < 4.5 then
                    if dist < 1.5 then
                        sleep = 0
                        DrawText3D(v.coords.x, v.coords.y, v.coords.z, "~b~E~w~ - [Gym Shop]")
                        if IsControlJustReleased(0, 38) then
                            OpenGymMenu()
                        end
                    end  
                end
            end

            for k, v in pairs(Config.Locations) do
                local dist = #(pos - vector3(Config.Locations[k].coords.x, Config.Locations[k].coords.y, Config.Locations[k].coords.z))
                if dist < 4.5 then
                    if dist < Config.Locations[k].viewDistance then
                        sleep = 0
                        DrawText3D(Config.Locations[k].coords.x, Config.Locations[k].coords.y, Config.Locations[k].coords.z, Config.Locations[k].Text3D)
                        if IsControlJustReleased(0, 38) then
                            if training == false then
                                TriggerServerEvent('qb-gym:checkChip')
                                QBCore.Functions.Notify('Preparing exercise', 'success')
                                Wait(1000)					
                                if membership == true then
                                    SetEntityHeading(ped, Config.Locations[k].heading)
                                    SetEntityCoords(ped, Config.Locations[k].coords.x, Config.Locations[k].coords.y, Config.Locations[k].coords.z - 1)
                                    TaskStartScenarioInPlace(ped, Config.Locations[k].animation, 0, true)
                                    Wait(30000)
                                    ClearPedTasksImmediately(ped)
                                    UpdateSkill(Config.Locations[k].skill, Config.Locations[k].SkillAddQuantity)
                                    print(Config.Locations[k].skill, Config.Locations[k].SkillAddQuantity)
                                    QBCore.Functions.Notify('You need to rest 60 seconds before doing another exercise', 'error')
                                    training = true
                                    resting = true
                                    CheckTraining()
                                elseif membership == false then
                                    QBCore.Functions.Notify('You need to be a member to do this exercise', 'error')
                                end
                            elseif training == true then
                                QBCore.Functions.Notify('Necesitas un descanso', 'primary')
                                resting = true
                                CheckTraining()
                            end
                        end
                    end  
                end
            end
		Wait(sleep)
    end
end)
