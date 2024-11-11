--[[

	This script file is a part of Garry's Mod addon "C.A.S.S.I.E from SCP: Secret Laboratory" and is disturbed under MIT license. 
	
	Copyright (c) 2023-2024 _wania
	
	For the full copyright and license information, please view the LICENSE file that was distributed with this source code.

]]

if SERVER then

	AddCSLuaFile("cassie/cl_cassie.lua")

	util.AddNetworkString( "CASSIEClientAddBroadcastMessage" )
	util.AddNetworkString("CASSIEClientClear")


	string.find_end = function(str,d)
		if not isstring(str) then return end
		for i = #str,1,-1 do
			if str[i] == d then return i,#str end
		end
		return nil,nil
	end

	local function AutoComplete(cmd,args)
		local beginp,endp = args:find_end(' ')
		if not beginp then return end
		local str = string.sub(args,1,beginp)
		local arg = string.sub(args,beginp+1,endp):lower():Trim()
		local list = {}
		for k,v in pairs(file.Find("sound/cassie/words/"..arg.."*.wav","GAME")) do
			list[k] = cmd .. str .. string.Split(v,'.wav')[1]
		end
		return list
	end

	concommand.Add("cassie", function( ply, cmd, args )
		if !ply:IsSuperAdmin() then return end

		net.Start("CASSIEClientAddBroadcastMessage")
		net.WriteBool(true)
		net.WriteTable(args)
		net.Broadcast()

	end,AutoComplete)

	concommand.Add("cassie_s", function( ply, cmd, args )
		if !ply:IsSuperAdmin() then return end

		net.Start("CASSIEClientAddBroadcastMessage")
		net.WriteBool(false)
		net.WriteTable(args)
		net.Broadcast()
	end,AutoComplete)


	concommand.Add("cassie_clear", function( ply, cmd, args )
		if !ply:IsSuperAdmin() then return end

		net.Start("CASSIEClientClear")
		net.Broadcast()
	end)

end


if CLIENT then

	include("cassie/cl_cassie.lua")

	net.Receive("CASSIEClientClear",function(len,ply)
		CASSIE:ClearBroadcast()
	end)

	net.Receive( "CASSIEClientAddBroadcastMessage", function( len, ply )

		local bg,args = net.ReadBool(),net.ReadTable()
		CASSIE:AddBroadcastMessage(args,bg)

		if not timer.Exists('CASSIE_Timer') then CASSIE:Read() end
	end)
end
