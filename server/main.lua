QBCore = exports['qb-core']:GetCoreObject()

--Callback de obtener las stats actuales
QBCore.Functions.CreateCallback("qb-skills:fetchStatus", function(source, cb)
     local src = source
     local Player = QBCore.Functions.GetPlayer(src)

    exports.oxmysql.scalar('SELECT skills FROM players WHERE citizenid = ?', { Player.PlayerData.citizenid }, function(status)
          if status then
               cb(json.decode(status))
          else
               cb(nil)
          end
     end)
end)

--Actualizar stats
RegisterServerEvent("qb-skills:update", function(data)
     local src = source
     local Player = QBCore.Functions.GetPlayer(src)
 
     exports.oxmysql:execute('UPDATE players SET skills = ? WHERE citizenid = ?', {data, Player.PlayerData.citizenid })
end)

RegisterServerEvent('qb-gym:checkChip', function()
	local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local quantity = Player.Functions.GetItemByName('gym_membership').amount
	
	if quantity > 0 then
		TriggerClientEvent('qb-gym:trueMembership', src) -- true
	else
		TriggerClientEvent('qb-gym:falseMembership', src) -- false
	end
end)

RegisterServerEvent('qb-gym:buyMembership', function()
	local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
	if Player.PlayerData.money.cash >= Config.MmbershipCardPrice then
        Player.Functions.RemoveMoney('cash', Config.MmbershipCardPrice)
        Player.Functions.AddItem('gym_membership', 1)	
        TriggerClientEvent('QBCore:Notify', src, 'You have paid for a gym membership', 'success', 3000)
		TriggerClientEvent('qb-gym:trueMembership', src) -- true
	else
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough money, you need '.. Config.MmbershipCardPrice, 'error', 3000)

	end	
end)
