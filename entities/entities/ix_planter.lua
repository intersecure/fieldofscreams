AddCSLuaFile()
ENT.Type = "anim"
ENT.Category = "HL2 RP"
ENT.PrintName = "Planter"
ENT.Spawnable = true
ENT.Base = "base_gmodentity"

--include ("database.lua")

if ( SERVER ) then
	
	function ENT:SpawnFunction( client, trace )	

		local planter = ents.Create( "ix_planter" )
		planter:SetPos( trace.HitPos )
		planter:Spawn()

	end

	function ENT:OnRemove()
		local id = self:GetId()
		RemoveTimers(self, id)
		--local q = dbObject:query("DELETE FROM farming_table WHERE id = " .. id .. ";")
		--q:start()		
	end	

	function ENT:SetupDataTables()

		self:NetworkVar("Int", 0, "nextUseTime")
		self:NetworkVar("Int", 1, "canUse")
		self:NetworkVar("Int", 2, "growTime")
		self:NetworkVar("Int", 3, "nFertLevel")
		self:NetworkVar("Int", 4, "nWaterLevel")
		self:NetworkVar("Int", 5, "nGrowth")
		self:NetworkVar("Int", 6, "nPhase")
		self:NetworkVar("Int", 7, "bGrown")
		self:NetworkVar("Int", 8, "Id")
		self:NetworkVar("Float", 9, "nAdjust")
		self:NetworkVar("Float", 10, "fertMult")
		self:NetworkVar("Bool", 11, "bPlanted")
		self:NetworkVar("Int", 12, "endTime") 	
		self:NetworkVar("Int", 13, "startTime")
		self:NetworkVar("Bool", 14, "bPhase1Complete")
		self:NetworkVar("Bool", 15, "bPhase2Complete")
		self:NetworkVar("Int", 16, "LastIndex")
		

		SetupEntity(self)
	
	end


	function SetupEntity(ent)

		local sid = ent:GetId()
		local name, pattern, str = ent, "%D+", tostring(ent)
		local i = string.gsub(str, pattern, "")
		local id = tonumber(i)
		ent:SetId(id)
		ent:SetnWaterLevel(100)
		ent:SetnFertLevel(100)
        --ent:SetnPhase(0)
		local q = dbObject:query("SELECT * FROM farming_table WHERE id = " .. id .. ";")
		q:start()
		
	end

	function ENT:Initialize()

		self:SetModel( "models/props/de_inferno/hr_i/flower_pots/barrel_planter_wood_full.mdl" )
		self:SetSolid( SOLID_VPHYSICS )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetCollisionGroup( COLLISION_GROUP_PLAYER )
		self:SetUseType( SIMPLE_USE )
		self:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
		
	end

		
	function ENT:Use(client)
		local name = self:GetClass()
		print ("NAME:", name)
		if (name == "ix_planter") then
			if (!self.nFertLevel and !self.nWaterLevel) then
				print ("not fertilized, not watered")
			elseif (!self.nFertLevel and self.nWaterLevel) then
				print ("watered, but not fertilized")
			elseif (self.nFertLevel and !self.nWaterLevel) then
				print ("fertilized, but not watered")
			else
				print ("all good")
			end

			local planted = self:GetbPlanted()
			local grown, fert, water, phase, id = self:GetbGrown(), self:GetnFertLevel(),self:GetnWaterLevel(), self:GetnPhase(), self:GetId()
			print ( "seed planted: ", planted )
			print ( "grown: ", grown )
			print ( "fertilization",  fert)
			print ( "water", water)
			print ( "target",  self)
			print ( "phase: ", phase)
			print ( "id:", id)

			local phase, grown = self:GetnPhase(), self:GetbGrown()
			print ("phase, grown", phase, grown)
			if ((phase >= 3) and (grown == 1)) then
        	    local char = client:GetCharacter()
        	    local inv = char:GetInventory()
				local slots = {inv:FindEmptySlot(1, 1, true)}
				print (slots[1], slots[2])
				inv:Add("fruit", 2, slots[1], slots[2])
				
				--self:SetnPhase(4)
				print ("bush3")
				--hook.Run ("phase", self)
				local index = self:GetLastIndex()
				local bush = ents.GetByIndex(index)
				ResetVars(self)
				bush:Remove()
			else print ("wtf")
			end
		else
			return 
		end

	end

	hook.Add ( "fert", "fertilization", function ( ent )
	
		--current water level modifies fertilizer gain a little

		local water = ent:GetnWaterLevel()
		local fertLevel = ent:GetnFertLevel()

		if ( water >= 0 ) then
			ent:SetnFertLevel(ent:GetnFertLevel()  + 10 ) 
			print ( "tiny fert" )
		elseif ( water >= 25 ) then
			ent:SetnFertLevel(ent:GetnFertLevel()  + 15 ) 
			print ( "small fert" )
		elseif ( water >= 50 ) then
			ent:SetnFertLevel(ent:GetnFertLevel() + 20 )
			print ( "med fert" )
		elseif (water >= 75 ) then
			ent:SetnFertLevel(ent:GetnFertLevel() + 25)
			print ( "big fert" )
		elseif (water >= 90 ) then
			ent:SetnFertLevel(ent:GetnFertLevel() + 30)
			ent:SetnWaterLevel(ent:GetnWaterLevel() + 10) 
			print ( "huge fert" )
		elseif (water >= 100 and water <= 120) then
			ent:SetnFertLevel(ent:GetnFertLevel() + 15)
			print ( "getting bad fert" )
		elseif (water >= 120 and water <= 140) then
			ent:SetnFertLevel(ent:GetnFertLevel() + 10)
			print ( "bad fert" )
		elseif (water >= 140 and water <= 150) then
			ent:SetnFertLevel(ent:GetnFertLevel() + 5)
			print ( "terrible fert" )
		end

		ReduceFert(ent)

	end)



	hook.Add ( "water", "manage water level when water is added", function( ent, sWaterType ) 

		print ("hook hit, water type: ", sWaterType)
		local waterLimit = 160
		local water = ent:GetnWaterLevel()
		print ("water", water)
		if (sWaterType == "good") and (water < waterLimit) then
			ent:SetnWaterLevel(water + 40)
			print ("good boy!")
		elseif (sWaterType == "shitty" ) and (water < waterLimit) then
			print ("boil your water freak")
			ent:SetnWaterLevel(water + 20)
		end

		ReduceWater(ent)

	end)
	
	hook.Add ( "planted", "seed fire", function  (ent)
		
		ent:SetbPlanted(true)
		local id = ent:GetId()
		local bushtbl = {InitBush(ent)}
		local bush1, bush2  = bushtbl[1], bushtbl[2]
		timer.Create( "CheckGrowth[" .. id .. "]", 5, 0, function() hook.Run ( "growth", ent, bush1, bush2, bush3 ) end )
		SaveSQL( ent )
		ReduceFert(ent)
		ReduceWater(ent)

	end )	
		
	hook.Add ( "growth", "check growth rate", function ( ent, bush1, bush2)

		local id = ent:GetId()
		print ("hit da growth hook")
		local water, fert, grown, planted, phase = ent:GetnWaterLevel(), ent:GetnFertLevel(), ent:GetbGrown(), ent:GetbPlanted(), ent:GetnPhase()
		--these will be 0 if it's a new entity, and should have been reset after the last grow cycle
		local endTime, startTime = ent:GetendTime(), ent:GetstartTime()
		local timeNow = os.time()
		print ("water, fert, grown, planted", water, fert, grown, planted)
		print ("times:", endTime, startTime)

		
		
		--therefore if it has times set, it's "growing" through a phase, but if it isn't and should be, set the times

		if(endTime == 0) and (grown == 0) and (planted) then
			local tTimes = {GetEndTime(ent, water, fert)}

			ent:SetstartTime(tTimes[2])
			ent:SetendTime(tTimes[1])
			local endTime = ent:GetendTime()
			local startTime = ent:GetstartTime()
			print("start time, end time:", tTimes[2], tTimes[1])
			print ("entity start, entity end:", ent:GetstartTime(), ent:GetendTime())
			print ("vars start, end:", endTime, startTime )
			--ent.endTime = endTime
			--ent.startTime = time
			return endTime, startTime
		end

		if ( ( ( endTime < timeNow ) ) and (grown == 0) and (planted) ) then
			hook.Run("phase", ent, bush1, bush2)
		elseif ( (endTime != 0) and (startTime != 0) and (grown == 0) and (endTime < timeNow) ) then
			--there is a start time and end time, and the crop hasn't grown, but it's not finished yet - no need to do anything
			return
		elseif ( (endTime != 0) and (startTime != 0) and (grown == 1) and (planted))  then
			--maybe the server grew the crop, correctly reset endTime but crashed before resetting startTime, or vice versa - either way, kill the timer
			print ("this shouldn't happen, destroy timer")
			timer.Destroy("CheckGrowth[" .. id .. "]")
		end
	end)

	

	hook.Add ( "phase", "check phase", function ( ent, bush1, bush2, bush3)

		--print ("PHASE IN HOOK:", ent:GetnPhase())
		local id = ent:GetId()
		local phase = ent:GetnPhase()
		local complete1 = ent:GetbPhase1Complete()
		local complete2 = ent:GetbPhase2Complete()
		local grown = ent:GetbGrown()
		local pos = ent:GetPos()
		local z = pos[3] + 21		

		if ( !IsValid ( ent ) ) then
			return
		elseif ( phase == 0 ) then
			ent:SetnPhase(1)
			ClearTimes(ent)
		elseif ( ( phase == 1 ) and (!complete1)) then
			bush1:SetModel("models/props/de_dust/hr_dust/foliage/banana_plant_03.mdl")
			bush1:Spawn()
			ent:SetnPhase(phase + 1) 
            WeldBones (ent, bush1)
			print ("setting phase to 2")
			ClearTimes(ent)
			ent:SetbPhase1Complete(true)
			ent:DeleteOnRemove(bush1)
		elseif ( ( phase == 2 ) and (!complete2) ) then

			SafeRemoveEntity(bush1)
			bush2:SetModel("models/props/de_dust/hr_dust/foliage/banana_plant_01.mdl")
			bush2:Spawn()
			WeldBones (ent, bush2)
			ent:SetnPhase(phase + 1)
			SaveSQL ( ent )
			ClearTimes(ent)
			ent:SetbPhase2Complete(true)
			ent:DeleteOnRemove(bush2)

		elseif ( ( phase == 3 ) and (grown == 0)) then

			local bush3 = ents.Create("ix_bush3")

			bush3:SetPos ( Vector ( pos[1], pos[2], z ) )
			SafeRemoveEntity(bush2)
			bush3:Spawn()
			print("bush3", bush3)
			print("bush:", bush3)
			WeldBones (ent, bush3)
			timer.Destroy ("CheckGrowth[" .. id .. "]")
			ent:SetbGrown(1)
			ent:SetLastIndex(bush3:EntIndex())
		elseif ( phase == 4) and (grown == 1) then	


			ResetVars(ent)
			bush:Remove()

		end

	end)


	function GetEndTime ( ent, water, fertlevel )
		--baseDuration will be modified depending on end water and fert levels
		local baseDuration = 1
		local water = ent:GetnWaterLevel()
		print ("water", water)
	
		local grown, valid = ent:GetbGrown(), ent:IsValid()

		local fertLevel = ent:GetnFertLevel()

		CheckWaterLevels(ent, water, fertLevel, grown)	
		
		print ("fertlvl", fertLevel)
		local time = os.time()
		local mult = ent:GetfertMult()
		print("mult,", mult)
		local fertRate = fertLevel * mult
		print ("fertRate", fertRate)
		local adjust = ent:GetnAdjust()
		print ("adjust", adjust)
		local growthIncrease = ((water - adjust) * fertRate) / 100
		print ("growthincrease:", growthIncrease)

		-- local subDuration = baseDuration * growthIncrease / 100
		local computedDuration = baseDuration - growthIncrease
		print ("base duration + = ", computedDuration)
		local endTime = time + computedDuration

		return endTime, time		

	end

	function CheckWaterLevels(ent, water, fertLevel, grown)
		-- this computes the final duration for the plant to reach the next phase
		if (grown == 0) then
			--print ("not grown, valid")		
			if ((water <= 100) and (water >= 90)) then	
				ent:SetfertMult(0.6) 
				ent:SetnAdjust(-10)
			elseif ((water <= 90) and (water >= 80)) then	
				ent:SetfertMult(0.5) 
				ent:SetnAdjust(-5)
			elseif ((water <= 80) and (water >= 60)) then	
				ent:SetfertMult(0.4) 
				ent:SetnAdjust(0)
			elseif ((water <= 80) and (water >= 60)) then	
				ent:SetfertMult(0.3) 
				ent:SetnAdjust(0)
			elseif ((water <= 60) and (water >= 30)) then	
				ent:SetfertMult(0.2) 
				ent:SetnAdjust(30)	
			elseif ((water <= 30) and (water >= 10)) then	
				ent:SetfertMult(0.1) 
				ent:SetnAdjust(50)	
			--not watering the plant gives you 0 fertilization bonus
			elseif ((water <= 10) and (water >= 0)) then	
				ent:SetfertMult(0) 
				ent:SetnAdjust(80)																
			elseif ((water) >= 100 and ((water) <= 120)) then 
				ent:SetnAdjust(20)
				ent:SetfertMult(0.2) 
			elseif ((water) >= 120 and ((water) <= 140)) then 
				ent:SetnAdjust(30)
				ent:SetfertMult(0.1) 
			--overwatering becomes more punishing
			elseif ((water) >= 140 and ((water) <= 160)) then 
				ent:SetnAdjust(50) 
				ent:SetfertMult(0)
			end
		end
	end

	function WeldBones( ent, bush )

		local bonename1, bonename2 = ( ent:GetBoneName(0) ), ( bush:GetBoneName(0) )
		print ("bones:", bonename1, bonename2)
		local bone1, bone2 = ent:LookupBone( bonename1 ), bush:LookupBone(bonename2)
		print ("bones:", bone1, bone2)
		constraint.Weld( ent, bush, bone1, bone2, 0, false )
		--constraint.Weld( bush, ent, bone1, bone2, 0, false )
		bush:PhysicsInitStatic(SOLID_VPHYSICS)
		ent:PhysicsInitStatic(SOLID_VPHYSICS)

	end

	function InitBush (ent)

		local pos = ent:GetPos()
		local z = pos[3] + 21

		local bush1 = ents.Create("prop_dynamic")
		local bush2 = ents.Create("prop_dynamic")
		--bush3 = ents.Create("prop_dynamic")

		bush1:PhysicsInitStatic(SOLID_VPHYSICS)
		bush1:SetCollisionGroup(COLLISION_GROUP_NONE)
		bush1:SetSolid(SOLID_VPHYSICS)
		bush1:SetPos ( Vector ( pos[1], pos[2], z ) )	
		bush2:PhysicsInitStatic(SOLID_VPHYSICS)
		bush2:SetCollisionGroup(COLLISION_GROUP_NONE)
		bush2:SetSolid(SOLID_VPHYSICS)
		bush2:SetPos ( Vector ( pos[1], pos[2], z ) )			
		--[[
		bush3:PhysicsInitStatic(SOLID_VPHYSICS)
		bush3:SetCollisionGroup(COLLISION_GROUP_NONE)
		bush3:SetSolid(SOLID_VPHYSICS)
		bush3:SetPos ( Vector ( pos[1], pos[2], z ) )	
--]]
		return bush1, bush2 -- bush3

	end

	function ClearTimes (ent)

		ent:SetendTime(0)
		ent:SetstartTime(0)

	end
	
	function ReduceWater (ent)

		local id = ent:GetId() 
		local rw = "ReduceW[ " .. id .. "]"

		if (!timer.Exists(rw)) then
		timer.Create(rw, 5, 0, function() 
			local water = ent:GetnWaterLevel()
			local grown = ent:GetbGrown()
			if ((water) > 0) and (grown == 0) then  
				ent:SetnWaterLevel(water - 1)
				print ("new water level: ", ent:GetnWaterLevel()) 
			elseif (grown == 1) or (water <= 0) then 
				timer.Remove (rw) 
				print ("water timer destroyed") 
			end
		end)
		else 
			print ("water timer exists")
		end

	end

	function ReduceFert ( ent )
	
		local id = ent:GetId()
		local rf = "ReduceF" .. id .. "]"
		local fertLimit = 0

		if (!timer.Exists(rf)) then
			timer.Create(rf, 5, 0, function() 
				local grown = ent:GetbGrown()	
				local fertLevel = ent:GetnFertLevel()

					if (fertLevel > fertLimit ) and (grown == 0) then  
					ent:SetnFertLevel(fertLevel - 5)
					print ("new fert level:", ent:GetnFertLevel())
					elseif (grown == 1) or (fertlevel <= fertLimit) then 
					-- don't keep the timer around when the plant has grown
					timer.Destroy (rf) 
					print ("fert timer destroyed") 
					end
			end)
		else 
			print ("timer already exists")
		end
	end

	function RemoveTimers (ent, id)

		local rf, rw, cg = "ReduceF" .. id .. "]", "ReduceW[ " .. id .. "]", "CheckGrowth[" .. id .. "]"
		timer.Remove(rf) timer.Remove(rw) timer.Remove(cg)
		print ("removing timers!")

	end

	function ResetVars (ent)

		ent:SetbPlanted(false)
		ent:SetbGrown(0)
		ent:SetnPhase(0)
		ent:SetendTime(0)
		ent:SetstartTime(0)

	end

	function SaveSQL( ent )

		local id, water, fert, phase, grown = ent:GetId(), ent:GetnWaterLevel(), ent:GetnFertLevel(), ent:GetnPhase(), ent:GetbGrown()
		
		local q = "UPDATE helix.farming_table SET Phase = " .. phase .. ", Water = " .. water .. ", Fert = " .. fert .. ", Grown = " .. grown .. " WHERE id = " .. id ..";"
		
		print ("query:", q)
		print ("isConnected", isConnected)
		status = dbObject:status()
		print ("connection status:", status)

			local q = dbObject:query(q)
			q:start()
			local error = q:error()
			print ("ERROR:", error)

			function q:onSuccess(data)
				print ("success", data)
			end

			function q:onError(err)
				print("An error occured while executing the query: " .. err)
			end
		
	end

	function ENT:Draw()

		self:DrawModel()
	
	end


--[[
	ENT:SetHelixTooltip(function(tooltip)
		local name = tooltip:AddRow("name")
		name:SetImportant()
		name:SetText(client:SteamName())
		name:SetBackgroundColor(team.GetColor(client:Team()))
		name:SizeToContents()
	
		tooltip:SizeToContents()
	end)
--]]
end