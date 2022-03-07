AddCSLuaFile()
ENT.Type = "anim"
ENT.Category = "HL2 RP"
ENT.PrintName = "Planter"
ENT.Spawnable = true
ENT.Base = "base_gmodentity"

if (SERVER) then
	
	function ENT:SpawnFunction(client, trace)	
		local planter = ents.Create("ix_planter")
		planter:SetPos(trace.HitPos)
		planter:Spawn()
	end

	function ENT:OnRemove()
		local id = self:GetId()

		local RemoveTimers = function(self, id)	
			local rfert, rwater, cgrowth = "ReduceF" .. id .. "]", "ReduceW[ " .. id .. "]", "CheckGrowth[" .. id .. "]"
			timer.Remove(rfert) timer.Remove(rwater) timer.Remove(cgrowth)
			print ("removing timers!")
		end

		RemoveTimers()
	end
		
	end	

	function ENT:SetupDataTables()
		self:NetworkVar("Int", 0, "nextUseTime")
		self:NetworkVar("Int", 1, "canUse")
		self:NetworkVar("Int", 2, "growTime")
		self:NetworkVar("Float", 3, "nFertLevel")
		self:NetworkVar("Float", 4, "nWaterLevel")
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
		self:NetworkVar("String", 17, "sWater")
		SetupEntity(self)
	end

	function SetupEntity(ent)
		local sid = ent:GetId()
		local name, pattern, str = ent, "%D+", tostring(ent)
		local i = string.gsub(str, pattern, "")
		local id = tonumber(i)
		ent:SetId(id)
		ent:SetnWaterLevel(0)
		ent:SetnFertLevel(0)
	end

	function ENT:Initialize()
		self:SetModel("models/props/de_inferno/hr_i/flower_pots/barrel_planter_wood_full.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInitStatic(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
		self:SetUseType(SIMPLE_USE)
		self:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
	end

	function ENT:Use(client, itemTable)	
		local name = self:GetClass()
		local grown, fert, water, phase, id, planted = self:GetbGrown(), self:GetnFertLevel(),self:GetnWaterLevel(), self:GetnPhase(), self:GetId(), self:GetbPlanted()
		local flag = false
		local endTime, timeNow = self:GetendTime(), os.time()
		local stillGrowing = ((planted) and (grown == 0) and (endTime > 0))
		local harvestReady = ((phase >= 3) and (grown == 1))

		if (harvestReady) then
           	local char = client:GetCharacter()
           	local inv = char:GetInventory()
			local slots = {inv:FindEmptySlot(1, 1, true)}
			print (slots[1], slots[2])
			inv:Add("fruit", 2, slots[1], slots[2])
			local index = self:GetLastIndex()
			local bush = ents.GetByIndex(index)
			ResetVars(self)
			bush:Remove()
			client:NotifyLocalized("You pull the sickly sweet smelling fruit from the vine.")
			return
		end

		if (stillGrowing) then
			local timeLeft = endTime - timeNow
			local timeInMinutes = (timeLeft / 60)
			local mils = tonumber(string.format("%.0f", timeInMinutes))
			--substitute with "timeLeft" to see seconds
			client:NotifyLocalized("It looks like the plant will take about " .. mils .. " minutes to grow.")
		end

		if (sWater != nil) then
			client:NotifyLocalized(sWater)
		end
		
		client:NotifyLocalized("It looks like the plant is " .. fert .. " percent fertilized.")
	end

	function CheckWaterLevel(ent, water)
		local switch = (math.floor (water+0.5) / 10)
		print ("switch,", switch)
		local WaterTable = 
		{
			[0] =  function() client:NotifyLocalized("The soil looks very dry.") end,
			[1] =  function() client:NotifyLocalized("The soil looks very dry.") end,  
			[2] =  function() client:NotifyLocalized("It's getting there.") end, 
			[3] =  function() client:NotifyLocalized("The soil is moist.") end,
			[4] =  function() client:NotifyLocalized("A small amount of water has been added to the soil.") end,
			[5] =  function() client:NotifyLocalized("The ground is looking a bit watered.") end,
			[6] =  function() client:NotifyLocalized("A fair amount of water.") end,
			[7] =  function() client:NotifyLocalized("An okay amount of water.") end,
			[8] =  function() client:NotifyLocalized("A decent amount of water.") end,
			[9] =  function() client:NotifyLocalized("A decent amount of water has been added to the soil.") end,
			[10] = function() client:NotifyLocalized("The ground is looking well watered.") end,
			[11] = function() client:NotifyLocalized("The soil is starting to look very wet.") end,
			[12] = function() client:NotifyLocalized("The soil is beginning to get soaked.") end,
			[13] = function() client:NotifyLocalized("The soil looks soaked.") end,
			[14] = function() client:NotifyLocalized("The pot is brimming with water.") end,
			[15] = function() client:NotifyLocalized("The soil is drenched.") end,
			[16] = function() client:NotifyLocalized("Water is pouring out of the pot.") end,
		}
		return switch
	end

	hook.Add ("water", "manage water level when water is added", function(ent, sWaterType, client) 
		print ("hook hit, water type: ", sWaterType)
		local waterLimit = 160
		local water, fertLevel = ent:GetnWaterLevel(), ent:GetnFertLevel()
		local afterGood, afterBad  = (water + 40), (water + 20)
		local strGood, strBad, notify = ("The purified water nourishes the soil."), ("The filthy water does little good."), ("There is too much water already.")
		local canAdd = ((waterBad < waterLimit) and (water < waterLimit))
		print ("canadd:", canAdd)

		if (canAdd) then
			if (sWaterType == "good") then
				ent:SetnWaterLevel(waterGood)
				client:NotifyLocalized(strGood)
			else
				client:NotifyLocalized(strBad)
				ent:SetnWaterLevel(waterBad)
			end
		else
			client:NotifyLocalized(notify)
		end

		CheckWaterLevel(ent, water)
		ReduceWater(ent)
	end)

	hook.Add ("fert", "fertilization", function (ent, flag)
		local water = ent:GetnWaterLevel()
		local fertLevel = ent:GetnFertLevel()
		local set = CheckWaterLevel (ent, water)

			if (flag) then
				if (client) then
				ent:SetnFertLevel(set)
				end
			end
		
			ReduceFert(ent)
	end)
	
	hook.Add ("planted", "seed fire", function  (ent)
		local bushtbl = {InitBush (ent)}
		local bush = bushtbl[1]
		local id, grown, valid, water, fertLevel, time = ent:GetId(), ent:GetbGrown(), ent:IsValid(), ent:GetnWaterLevel(), ent:GetnFertLevel(), os.time()
		timer.Create("CheckGrowth[" .. id .. "]", 5, 0, function() CheckGrowth (ent, bush) end)
		ent:SetbPlanted(true)

		local SetTimes = function(ent, water, fertlevel)
				local baseDuration = 5
				local tbl = {CheckWaterLevel(ent, water)}
				local mult, adjust = tbl[2], tbl[3]
				local fertRate = fertLevel * mult		
				local baseIncrease = (baseDuration * (adjust))
				local computedTime = (baseIncrease * (mult))
				local endTime = time + computedTime
				ent:SetendTime(endTime)
				ent:SetstartTime(time)
			end			

		SetTimes(ent)
		ReduceFert(ent)
		ReduceWater(ent)

	end)	

	
		
	function CheckGrowth (ent, bush)
		local id = ent:GetId()
		local water, fert, grown, planted, phase = ent:GetnWaterLevel(), ent:GetnFertLevel(), ent:GetbGrown(), ent:GetbPlanted(), ent:GetnPhase()
		local endTime, startTime, timeNow = ent:GetendTime(), ent:GetstartTime(), os.time()
		local goPhase = (endTime < timeNow and grown == 0 and planted)
		local goDestroy = ((endTime != 0) and (startTime != 0) and (grown == 1) and (planted))

		if (goPhase) then
			CheckPhase(ent, bush)
			return
		end
		if (goDestroy) then
			print ("this shouldn't happen, destroy timer")
			timer.Destroy("CheckGrowth[" .. id .. "]")
		end
	end

	function CheckPhase (ent, bush)
		local id, phase, complete1, complete2, grown, pos, z = ent:GetId(), ent:GetnPhase(), ent:GetbPhase1Complete(), ent:GetbPhase2Complete(), ent:GetbGrown(), ent:GetPos()
		local z = pos[3] + 21		
		local advancePhase1 = ((phase == 1) and (!complete1))
		local advancePhase2 = ((phase == 2) and (!complete2))
		local advancePhase3 = ((phase == 3) and (grown == 0))

		local GoPhase(ent, bush, id, phase)
			print ("running GOPHASE")
			ClearTimes(ent)
			WeldBones (ent, bush)
	
			if (phase == 1) then
				ent:SetbPhase1Complete(true)
				bush:SetModel("models/props/de_dust/hr_dust/foliage/banana_plant_03.mdl")
			end
			if (phase == 2) then
				ent:SetbPhase2Complete(true)
				bush:SetModel("models/props/de_dust/hr_dust/foliage/banana_plant_01.mdl") 
			end
			if (phase == 3) then
				timer.Destroy ("CheckGrowth[" .. id .. "]")
				bush:SetModel("models/props/de_dust/hr_dust/foliage/banana_plant_02.mdl")
			end
	
			ent:SetnPhase(phase + 1)
			print "blah"
		end
	

		print ("checking phase")
		print ("advance phase:", phase, advancePhase1, advancePhase2, advancePhase3)
		if (IsValid (ent)) then
			if (phase == 0) then
				GoPhase(ent, bush, id, 0)
			end
			if (advancePhase1) then
				GoPhase(ent, bush, id, 1)	
			end
			if (advancePhase2) then
				GoPhase(ent, bush, id, 2)
			end
			if (advancePhase3) then
				GoPhase(ent, bush, id, 3)
			end
		end
	end

	function WeldBones(ent, bush)
		local bonename1, bonename2 = (ent:GetBoneName(0)), (bush:GetBoneName(0))
		local bone1, bone2 = ent:LookupBone(bonename1), bush:LookupBone(bonename2)
		constraint.Weld(ent, bush, bone1, bone2, 0, false)
		constraint.Weld(bush, ent, bone1, bone2, 0, false)
		bush:PhysicsInitStatic(SOLID_VPHYSICS)
		ent:PhysicsInitStatic(SOLID_VPHYSICS)
	end

	function InitBush (ent)
		local pos = ent:GetPos()
		local z = pos[3] + 21
		local bush = ents.Create("prop_dynamic")
		bush:PhysicsInitStatic(SOLID_VPHYSICS)
		bush:SetCollisionGroup(COLLISION_GROUP_NONE)
		bush:SetSolid(SOLID_VPHYSICS)
		bush:SetPos (Vector (pos[1], pos[2], z))	
		return bush				
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
				elseif (grown == 1) or (water <= 0) then 
					timer.Remove (rw) 
				end
			end)
		end
	end

	function ClearTimes (ent)
		ent:SetendTime(0)
		ent:SetstartTime(0)
	end

	function ReduceFert (ent)
		local id = ent:GetId()
		local rf = "ReduceF" .. id .. "]"
		local fertLimit = 0
		
		if (!timer.Exists(rf)) then
			timer.Create(rf, 5, 0, function() 
				local grown = ent:GetbGrown()	
				local fertLevel = ent:GetnFertLevel()

					if (fertLevel > fertLimit) and (grown == 0) then  
					ent:SetnFertLevel(fertLevel - 5)
					elseif (grown == 1) or (fertLevel <= fertLimit) then 
					-- don't keep the timer around when the plant has grown
					timer.Destroy (rf) 
					end
			end)
		end
	end

	function ENT:Draw()
		self:DrawModel()
	end

end
