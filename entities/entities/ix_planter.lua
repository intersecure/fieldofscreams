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
		end

		RemoveTimers(self, id)
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
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
		self:SetUseType(SIMPLE_USE)
		self:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
		self:SetPersistent(true)
	end

	function ENT:Use(client, itemTable)	

		local ResetVars = function(self)
			self:SetbPlanted(false)
			self:SetbGrown(0)
			self:SetnPhase(0)
			self:SetendTime(0)
			self:SetstartTime(0)
		end

		local name = self:GetClass()
		local bush = constraint.FindConstraintEntity(self, "Weld")
		local grown, fert, water, phase, id, planted = self:GetbGrown(), self:GetnFertLevel(),self:GetnWaterLevel(), self:GetnPhase(), self:GetId(), self:GetbPlanted()
		local endTime, timeNow = self:GetendTime(), os.time()
		local stillGrowing = ((planted) and (grown == 0) and (endTime > 0))
		local harvestReady = ((phase >= 3) and (grown == 1))

		if (harvestReady) then
           	local char = client:GetCharacter()
           	local inv = char:GetInventory()
			local slots = {inv:FindEmptySlot(1, 1, true)}
			inv:Add("fruit", 2, slots[1], slots[2])
			local bushIndex = self:GetLastIndex()

			if (bushIndex > 0) then
				local bush = ents.GetByIndex(bushIndex)
				bush:Remove()
				self:SetLastIndex(0)
				self:SetbPlanted(false)
			end

			client:NotifyLocalized("You pull the sickly sweet smelling fruit from the vine.")
			return
		end

		if (stillGrowing) then
			local timeLeft = endTime - timeNow
			local timeInMinutes = (timeLeft / 60)
			local mils = tonumber(string.format("%.0f", timeInMinutes))
			client:NotifyLocalized("It looks like the plant will take about " .. mils .. " minutes to grow.")
		end

		CheckWaterLevel(self, water)
		client:NotifyLocalized("It looks like the plant is " .. fert .. " percent fertilized.")
	end

	function CheckWaterLevel(ent, water)
		local switch = (math.floor(water / 10))
		local WaterTable = 
		{
			[0] =  function() client:NotifyLocalized("The soil looks very dry.") end,
			[1] =  function() client:NotifyLocalized("The soil is slightly damp.") end,  
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
		
		local userNotify = WaterTable[switch]
		if (userNotify) then
			userNotify()
		end
		return switch
	end

	hook.Add ("water", "manage water level when water is added", function(ent, sWaterGood, client) 
		local waterLimit = 180
		local water, fertLevel = ent:GetnWaterLevel(), ent:GetnFertLevel()
		local afterGood, afterBad  = (water + 40), (water + 20)
		local strGood, strBad, notify = ("The purified water nourishes the soil."), ("The filthy water does little good."), ("There is too much water already.")
		local canAdd = ((afterBad < waterLimit) and (water < waterLimit))

		if (canAdd) then
			if (sWaterGood) then
				ent:SetnWaterLevel(afterGood)
				client:NotifyLocalized(strGood)
			else
				client:NotifyLocalized(strBad)
				ent:SetnWaterLevel(afterBad)
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
		local tblset = {CheckWaterLevel(ent, water)}
		local set = tblset[1]

		if (client) then
			ent:SetnFertLevel(fertLevel + set + 15)
		end
		
		ReduceFert(ent)
	end)
	
	hook.Add ("planted", "seed fire", function  (ent)
		local InitBush = function (ent, bush)
			local pos = ent:GetPos()
			local z = pos[3] + 21
			local bush = ents.Create("prop_dynamic")
			local bushIndex = bush:EntIndex()
			bush:PhysicsInit(SOLID_VPHYSICS)
			bush:SetCollisionGroup(COLLISION_GROUP_NONE)
			bush:SetSolid(SOLID_VPHYSICS)			
			bush:SetPos(Vector (pos[1], pos[2], z))	
			ent:DeleteOnRemove(bush)
			ent:SetLastIndex(bushIndex)
			return bush				
		end

		local bushtbl = {InitBush (ent)}
		local bush = bushtbl[1]
		local id, grown, valid, water, fertLevel, time = ent:GetId(), ent:GetbGrown(), ent:IsValid(), ent:GetnWaterLevel(), ent:GetnFertLevel(), os.time()

		local SetTimes = function(ent, water, fertlevel)
			local baseDuration = 1
			local baseBonus = 25
			local fertBonus = fertLevel / 4
			local mult = (water + fertBonus + baseBonus) / 100	
			local computedTime = baseDuration
			if (mult > 1) then
				local increase = (mult%1)
				local computedTime = (baseDuration * increase)	
			end

			local endTime = time + computedTime
			ent:SetendTime(endTime)
			ent:SetstartTime(time)
		end			

		timer.Create("TimeGrowth[" .. id .. "]", 5, 0, function() CheckGrowth (ent, bush) end)

		ent:SetbPlanted(true)
		SetTimes(ent, water, fertLevel)
		ReduceFert(ent)
		ReduceWater(ent)
	end)	

	function CheckGrowth (ent, bush)
		local id, grown, planted, endTime, startTime, timeNow  = ent:GetId(), ent:GetbGrown(), ent:GetbPlanted(), ent:GetendTime(), ent:GetstartTime(), os.time()
		local checkTime = (endTime < timeNow and grown == 0 and planted)
		local goDestroy = ((endTime != 0) and (startTime != 0) and (grown == 1) and (planted))

		if (checkTime) then
			CheckPhase(ent, bush)
			return
		end

		if (goDestroy) then
			timer.Destroy("TimeGrowth[" .. id .. "]")
		end
	end

	function CheckPhase (ent, bush)
		local id, phase = ent:GetId(), ent:GetnPhase()
		local complete1, complete2, pos, z = ent:GetbPhase1Complete(), ent:GetbPhase2Complete(), ent:GetPos()
		local z = pos[3] + 21		
		local advancePhase1 = ((phase == 1) and (!complete1))
		local advancePhase2 = ((phase == 2) and (!complete2))
		local advancePhase3 = ((phase == 3))

		local WeldBones = function(ent, bush)
			ent:PhysicsInit(SOLID_VPHYSICS)
			bush:PhysicsInit(SOLID_VPHYSICS)
			local bonename1, bonename2 = (ent:GetBoneName(0)), (bush:GetBoneName(0))
			local bone1, bone2 = (ent:LookupBone(bonename1)), (bush:LookupBone(bonename2))
			constraint.Weld(ent, bush, bone1, bone2, 0, false)
			--constraint.Weld(bush, ent, 0, bone1, bone2, 0, false)			
		end

		local ClearTimes = function(ent)
			ent:SetendTime(0)
			ent:SetstartTime(0)
		end
	
		local CasePhase = {
			[0] = function() print("started growing") end,
			[1] = function() ent:SetbPhase1Complete(true) bush:SetModel("models/props/de_dust/hr_dust/foliage/banana_plant_03.mdl") WeldBones (ent, bush) end,	
			[2] = function() ent:SetbPhase2Complete(true) bush:SetModel("models/props/de_dust/hr_dust/foliage/banana_plant_01.mdl") end,
			[3] = function() timer.Destroy ("TimeGrowth[" .. id .. "]") bush:SetModel("models/props/de_dust/hr_dust/foliage/banana_plant_02.mdl") ent:SetbGrown(1) end,
		}

		if (IsValid (ent)) then
			CasePhase[phase]()
		end

		ent:SetnPhase(phase + 1)
		ClearTimes(ent)			

	end
	
	function ReduceWater (ent)
		local id = ent:GetId() 
		local rw = "ReduceW[ " .. id .. "]"

		if (!timer.Exists(rw)) then
			timer.Create(rw, 5, 0, function() 
				local water = ent:GetnWaterLevel()
				local grown = ent:GetbGrown()
				local reduce = ((water) > 0) and (grown == 0)
				local del = ((grown == 1) or (water <= 0))
				if (reduce) then  
					ent:SetnWaterLevel(water - 1)
				end
				if (del) then 
					timer.Remove (rw) 
				end
			end)
		end
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
					timer.Destroy (rf) 
					end
			end)
		end
	end

	function ENT:Draw()
		self:DrawModel()
	end

end
