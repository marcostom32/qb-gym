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

function FetchSkills()
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


function UpdateSkill(skill, amount)

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


function SkillMenu2()
	ped = PlayerPedId();
	MenuTitle = "Skills"
    RefreshSkills()
	ClearMenu()
    for type, value in pairs(Config.Skills) do
        Menu.addButton(type .. ' <span style="color:#0d7ec0">' .. value["Current"] .. "</span> %", "closeMenuFull",nil)
	end
end

function buyMember()
    TriggerServerEvent('qb-gym:buyMembership')
    closeMenuFull()
end

function BuyMembership()
	ped = PlayerPedId();
	MenuTitle = "Gym Shop"
	ClearMenu()
    Menu.addButton('Buy Membership', "buyMember",nil)
end


Menu = {}
Menu.GUI = {}
Menu.buttonCount = 0
Menu.selection = 0
Menu.hidden = true
MenuTitle = "Menu"

function Menu.addButton(name, func,args)

	local yoffset = 0.25
	local xoffset = 0.3
	local xmin = 0.0
	local xmax = 0.15
	local ymin = 0.03
	local ymax = 0.03
	Menu.GUI[Menu.buttonCount+1] = {}


	Menu.GUI[Menu.buttonCount+1]["name"] = name
	Menu.GUI[Menu.buttonCount+1]["func"] = func
	Menu.GUI[Menu.buttonCount+1]["args"] = args
	Menu.GUI[Menu.buttonCount+1]["active"] = false
	Menu.GUI[Menu.buttonCount+1]["xmin"] = xmin
	Menu.GUI[Menu.buttonCount+1]["ymin"] = ymin * (Menu.buttonCount + 0.01) +yoffset
	Menu.GUI[Menu.buttonCount+1]["xmax"] = xmax 
	Menu.GUI[Menu.buttonCount+1]["ymax"] = ymax 
	Menu.buttonCount = Menu.buttonCount+1
end


function Menu.updateSelection() 
	if IsControlJustPressed(1, 173) then -- Down Arrow
		if(Menu.selection < Menu.buttonCount -1 ) then
			Menu.selection = Menu.selection +1
		else
			Menu.selection = 0
		end		
		PlaySound(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
	elseif IsControlJustPressed(1, 27) then -- Up Arrow
		if(Menu.selection > 0)then
			Menu.selection = Menu.selection -1
		else
			Menu.selection = Menu.buttonCount-1
		end	
		PlaySound(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
	elseif IsControlJustPressed(1, 215) then
		MenuCallFunction(Menu.GUI[Menu.selection +1]["func"], Menu.GUI[Menu.selection +1]["args"])
		PlaySound(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
	end
	local iterator = 0
	for id, settings in ipairs(Menu.GUI) do
		Menu.GUI[id]["active"] = false
		if(iterator == Menu.selection ) then
			Menu.GUI[iterator +1]["active"] = true
		end
		iterator = iterator +1
	end
end

function Menu.renderGUI()
	if not Menu.hidden then
		Menu.renderButtons()
		Menu.updateSelection()
	end
end

function Menu.renderBox(xMin,xMax,yMin,yMax,color1,color2,color3,color4)
	DrawRect(0.7, yMin,0.15, yMax-0.002, color1, color2, color3, color4);
end

function Menu.renderButtons()
	
		local yoffset = 0.5
		local xoffset = 0

		
		
	for id, settings in pairs(Menu.GUI) do
		local screen_w = 0
		local screen_h = 0
		screen_w, screen_h =  GetScreenResolution(0, 0)
		
		boxColor = {38,38,38,199}
		local movetext = 0.0
		if(settings["active"]) then
			boxColor = {31, 116, 207,155}
		end


		if settings["extra"] ~= nil then

			SetTextFont(4)

			SetTextScale(0.34, 0.34)
			SetTextColour(255, 255, 255, 255)
			SetTextEntry("STRING") 
			AddTextComponentString(settings["name"])
			DrawText(0.63, (settings["ymin"] - 0.012 )) 

			DrawRect(0.832, settings["ymin"], 0.11, settings["ymax"]-0.002, 255,255,255,199)
			--Global.DrawRect(x, y, width, height, r, g, b, a)
		else
			SetTextFont(4)
			SetTextScale(0.31, 0.31)
			SetTextColour(255, 255, 255, 255)
			SetTextCentre(true)
			SetTextEntry("STRING") 
			AddTextComponentString(settings["name"])
			DrawText(0.7, (settings["ymin"] - 0.012 )) 

		end
		Menu.renderBox(settings["xmin"] ,settings["xmax"], settings["ymin"], settings["ymax"],boxColor[1],boxColor[2],boxColor[3],boxColor[4])
	 end     
end

--------------------------------------------------------------------------------------------------------------------

function ClearMenu()
	--Menu = {}
	Menu.GUI = {}
	Menu.buttonCount = 0
	Menu.selection = 0
end

function MenuCallFunction(fnc, arg)
	_G[fnc](arg)
end

function closeMenuFull()
    Menu.hidden = true
    show = nil
    ClearMenu()
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
local checkskills = {
    [1] = {
        coords = vector3(-1199.33, -1580.15, 4.61)
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
                            BuyMembership()    
                            Menu.hidden = not Menu.hidden    
                        end
                        Menu.renderGUI() 
                    end  
                end
            end
            for k, v in pairs(checkskills) do
                local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                if dist < 4.5 then
                    if dist < 1.5 then
                        sleep = 0
                        DrawText3D(v.coords.x, v.coords.y, v.coords.z, "~b~E~w~ - [Check Stats]")
                        if IsControlJustReleased(0, 38) then
                            SkillMenu2()      
                            Menu.hidden = not Menu.hidden  
                        end
                        Menu.renderGUI() 
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
