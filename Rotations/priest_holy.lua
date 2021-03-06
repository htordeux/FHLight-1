local L = MyLocalizationTable
local spellTable = {}
local parseMoving = {}
local parseControl = {}
local parseControlFocus = {}
local parseDispel = {}
local parseDamage = {}

local UnitIsUnit = UnitIsUnit
local canDPS = jps.canDPS
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local ipairs = ipairs
local GetUnitName = GetUnitName
local tinsert = table.insert

local iceblock = tostring(select(1,GetSpellInfo(45438))) -- ice block mage
local divineshield = tostring(select(1,GetSpellInfo(642))) -- divine shield paladin

	local POH = tostring(select(1,GetSpellInfo(596)))
	local Hymn = tostring(select(1,GetSpellInfo(64843))) -- "Divine Hymn" 64843
	local Serenity = tostring(select(1,GetSpellInfo(88684))) -- "Holy Word: Serenity" 88684
	local Chastise = tostring(select(1,GetSpellInfo(88625))) -- Holy Word: Chastise 88625
	local Santuary = tostring(select(1,GetSpellInfo(88685))) -- Holy Word: Sanctuary 88685

	local ChakraSanctuary = tostring(select(1,GetSpellInfo(81206))) -- Chakra: Sanctuary 81206
	local ChakraChastise = tostring(select(1,GetSpellInfo(81209))) -- Chakra: Chastise 81209
	local ChakraSerenity = tostring(select(1,GetSpellInfo(81208))) -- Chakra: Serenity 81208
	
	local sanctuaryPOH = "/cast "..ChakraSanctuary.."\n".."/cast "..POH
	local sanctuaryHymn = "/cast "..ChakraSanctuary.."\n".."/cast "..Hymn
	local macroSerenity = "/cast "..Serenity
	local macroChastise = "/cast "..Chastise
	local macroCancelaura = "/cancelaura "..ChakraSerenity.."\n".."/cancelaura "..ChakraSanctuary -- takes 1 GCD
	local macroCancelauraChastise = macroCancelaura.."\n"..macroChastise -- takes 2 GCD
	
local ClassEnemy = {
	["WARRIOR"] = "cac",
	["PALADIN"] = "caster",
	["HUNTER"] = "cac",
	["ROGUE"] = "cac",
	["PRIEST"] = "caster",
	["DEATHKNIGHT"] = "cac",
	["SHAMAN"] = "caster",
	["MAGE"] = "caster",
	["WARLOCK"] = "caster",
	["MONK"] = "caster",
	["DRUID"] = "caster"
}

local EnemyCaster = function(unit)
	if not jps.UnitExists(unit) then return false end
	local _, classTarget, classIDTarget = UnitClass(unit)
	return ClassEnemy[classTarget]
end

----------------------------
-- ROTATION
----------------------------

local priestHoly = function()

----------------------------
-- LOWESTIMPORTANTUNIT
----------------------------

	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(1)
	local timerShield = jps.checkTimer("ShieldTimer")
	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER
	local playerIsInterrupt = jps.checkTimer("PlayerInterrupt")

	local LowestImportantUnit = jps.LowestImportantUnit()
	local LowestImportantUnitHealth = jps.hp(LowestImportantUnit,"abs") -- UnitHealthMax(unit) - UnitHealth(unit)
	local LowestImportantUnitHpct = jps.hp(LowestImportantUnit) -- UnitHealth(unit) / UnitHealthMax(unit)
	local POHTarget, groupToHeal, groupTableToHeal = jps.FindSubGroupTarget(priest.get("HealthRaid")/100) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	
----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

	local ShieldTarget = nil
	local ShieldTargetHealth = 100
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForShield(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < ShieldTargetHealth then
				ShieldTarget = unit
				ShieldTargetHealth = unitHP
			end
		end
	end

	local MendingTarget = nil
	local MendingTargetHealth = 100
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForMending(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < MendingTargetHealth then
				MendingTarget = unit
				MendingTargetHealth = unitHP
			end
		end
	end
	
	local BindingHealTarget = nil
	local BindingHealTargetHealth = 100
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForBinding(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < BindingHealTargetHealth then
				BindingHealTarget = unit
				BindingHealTargetHealth = unitHP
			end
		end
	end
	
	-- {"Magic", "Poison", "Disease", "Curse"}
	--local DispelTarget = jps.FindMeDispelTarget( {"Magic"} )
	local DispelTargetRole = nil
	for _,unit in ipairs(FriendUnit) do 
		if jps.RoleInRaid(unit) == "HEALER" and jps.canDispel(unit,{"Magic"}) then
			DispelTargetRole = unit
		break end
	end

	local DispelFriendlyTarget = nil
	local DispelFriendlyTargetHealth = 100
	for _,unit in ipairs(FriendUnit) do
		local unitHP = jps.hp(unit)
		if jps.DispelFriendlyRBG(unit) then
			if unitHP < DispelFriendlyTargetHealth then
				DispelFriendlyTarget = unit
				DispelFriendlyTargetHealth = unitHP
			end
		end
	end
	if DispelFriendlyTarget == nil then
		for _,unit in ipairs(FriendUnit) do
			local unitHP = jps.hp(unit)
			if jps.DispelFriendly(unit,1) then
				if unitHP < DispelFriendlyTargetHealth then
					DispelFriendlyTarget = unit
					DispelFriendlyTargetHealth = unitHP
				end
			end
		end	
	end

	local LeapFriend = nil
	local LeapFriendFlag = nil 
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForLeap(unit) and jps.FriendAggro(unit) then
			if jps.buff(23335,unit) or jps.buff(23333,unit) then -- 23335/alliance-flag -- 23333/horde-flag 
				LeapFriendFlag = unit
			end
		end
	end

---------------------
-- ENEMY TARGET
---------------------

	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget() -- returns "target" by default

	-- set focus an enemy targeting you
	if not jps.UnitExists("focus") and canDPS("mouseover") and jps.UnitIsUnit("mouseovertarget","player") then
		jps.Macro("/focus mouseover")
		local name = GetUnitName("focus")
		print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	end
	-- CONFIG priest.get("KeepFocus") check if you want keep focus set manually
	if jps.UnitExists("focus") and not canDPS("focus") then
		if not priest.get("KeepFocus") then jps.Macro("/clearfocus") end
	end

	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	elseif canDPS("focustarget") then rangedTarget = "focustarget"
	elseif canDPS("mouseover") then rangedTarget = "mouseover"
	end
	-- if your target is friendly keep it as target
	if not jps.canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

	local FearEnemyTarget = nil
	for _,unit in ipairs(EnemyUnit) do 
		if priest.canFear(unit) and not jps.LoseControl(unit) then
			FearEnemyTarget = unit
		break end
	end

	local DeathEnemyTarget = nil
	for _,unit in ipairs(EnemyUnit) do 
		if priest.canShadowWordDeath(unit) then 
			DeathEnemyTarget = unit
		break end
	end

	local MassDispellTarget = nil
	for _,unit in ipairs(EnemyUnit) do 
		if jps.buff(divineshield,unit) then
			MassDispellTarget = unit
			jps.Macro("/target "..MassDispellTarget)
		break end
	end

----------------------------------------------------------
-- TRINKETS -- OPENING -- CANCELAURA -- STOPCASTING
----------------------------------------------------------

-- "Holy Spark" 131567 "Etincelle sacrée" -- increases the healing done by your next Flash Heal, Greater Heal or Holy Word: Serenity by 50% for 10 sec.
local InterruptTable = {
	{priest.Spell.flashHeal, 0.70 , jps.buff(27827) },
	{priest.Spell.greaterHeal, 0.85 , jps.buff(27827) },
	{priest.Spell.heal, 1 , false },
	{priest.Spell.prayerOfHealing, 0.85, jps.MultiTarget or jps.buffId(81206)}
}

-- Avoid interrupt Channeling
	if jps.ChannelTimeLeft() > 0 then return nil end
-- Avoid Overhealing
	priest.ShouldInterruptCasting( InterruptTable , AvgHealthLoss ,  CountInRange )

------------------------
-- LOCAL TABLES
------------------------

	parseControl = {
		-- Chakra: Chastise 81209 -- Chakra: Sanctuary 81206 -- Chakra: Serenity 81208 -- Holy Word: Chastise 88625
		{ 88625, not jps.buffId(81208) and not jps.buffId(81206) , rangedTarget  , "|cFFFF0000Chastise_NO_Chakra_"..rangedTarget },
		{ 88625, jps.buffId(81209) , rangedTarget , "|cFFFF0000Chastise_Chakra_"..rangedTarget },
		-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
		--{ 8122, type(FearEnemyTarget) == "string" , FearEnemyTarget , "FEAR_MultiUnit_" },
		{ 8122, priest.canFear(rangedTarget) , rangedTarget },
		-- "Psyfiend" 108921 Démon psychique
		{ 108921, playerAggro and priest.canFear(rangedTarget) , rangedTarget },
		-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
		{ 108920, playerAggro and priest.canFear(rangedTarget) , rangedTarget },
	}
	
	parseControlFocus = {
		-- Chakra: Chastise 81209 -- Chakra: Sanctuary 81206 -- Chakra: Serenity 81208 -- Holy Word: Chastise 88625
		{ 88625, not jps.buffId(81208) and not jps.buffId(81206) , "focus"  , "|cFFFF0000Chastise_NO_Chakra_".."focus" },
		{ 88625, jps.buffId(81209) , "focus" , "|cFFFF0000Chastise_Chakra_".."focus" },
		-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
		{ 8122, priest.canFear("focus") , "focus" , "Fear_".."focus" },
		-- "Psyfiend" 108921 Démon psychique
		{ 108921, EnemyCaster("focus") == "cac" and priest.canFear("focus") , "focus" },
		-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
		{ 108920, EnemyCaster("focus") == "cac" and priest.canFear("focus") , "focus" },
	}

	
	parseDispel = {
		-- "Dispel" "Purifier" 527
		{ 527, type(DispelTargetRole) == "string" , DispelTargetRole , "|cff1eff00DispelTargetRole_MultiUnit_" },
		{ 527, type(DispelFriendlyTarget) == "string" , DispelFriendlyTarget , "|cff1eff00DispelFriendlyTarget_MultiUnit_" },
		-- "Leap of Faith" 73325 -- "Saut de foi"
		{ 73325 , type(LeapFriendFlag) == "string" , LeapFriendFlag , "|cff1eff00Leap_MultiUnit_" },
		{ 73325 , type(LeapFriend) == "string" , LeapFriend , "|cff1eff00Leap_MultiUnit_" },
	}
	
	parseDamage = {
		-- Chakra: Chastise 81209
		{ 81209, not jps.buffId(81209) , "player" , "|cffa335eeChakra_Chastise" },
		-- "Chastise" 88625 -- Chakra: Chastise 81209
		{ 88625, jps.buffId(81209) , rangedTarget , "|cFFFF0000Chastise_"..rangedTarget },
		-- "Mot de l'ombre : Mort" 32379 -- FARMING OR PVP -- NOT PVE
		{ 32379, type(DeathEnemyTarget) == "string" , DeathEnemyTarget , "|cFFFF0000Death_MultiUnit_" },
		{ 32379, priest.canShadowWordDeath(rangedTarget) , rangedTarget , "|cFFFF0000Death_Health_"..rangedTarget },
		-- "Flammes sacrées" 14914
		{ 14914, true , rangedTarget },
		-- "Mot de pouvoir : Réconfort" -- "Power Word: Solace" 129250 -- REGEN MANA
		{ 129250, true , rangedTarget },
		-- "Mot de l'ombre: Douleur" 589 -- FARMING OR PVP -- NOT PVE -- Only if 1 targeted enemy 
		{ 589, TargetCount == 1 and jps.myDebuffDuration(589,rangedTarget) == 0 , rangedTarget  },
		-- "Châtiment" 585
		{ 585, not jps.Moving , rangedTarget  },
	}

------------------------
-- SPELL TABLE ---------
------------------------

-- Set Holy Word: Sanctuary 88685 as NextSpell if I cast manually Chakra Sanctuary
	if jps.buffId(81206) and jps.cooldown(88685) == 0 then jps.NextSpell = Santuary end
	
local spellTable = {

	-- "Esprit de rédemption" 27827/spirit-of-redemption
	{ "nested", jps.buff(27827) , 
		{
			-- "Divine Hymn" 64843
			{ 64843, jps.buff(27827) and AvgHealthLoss < 0.85  , "player" },
			-- "Circle of Healing" 34861
			{ 34861, true , LowestImportantUnit },
			{ 2060, jps.buffStacks(63735,"player") == 2 and jps.buff(27827) , LowestImportantUnit  },
			{ 2061, jps.buff(27827) , LowestImportantUnit },
		},
	},
	
	{"nested", not jps.Combat , 
		{
			-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
			{ 6346, not jps.buff(6346,"player") , "player" },
			-- "Inner Fire" 588 Keep Inner Fire up 
			{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player"), "player" }, -- "Volonté intérieure" 73413
			-- "Fortitude" 21562 Keep Inner Fortitude up 
			{ 21562, not jps.buff(21562,"player") , "player" },
			-- "Enhanced Intellect" 79640 -- "Alchemist's Flask 75525
			{ {"macro","/use item:75525"}, jps.buffDuration(79640,"player") < 900 , "player" },
		},
	},

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(1), jps.useTrinketBool(1) and playerIsStun , "player" },
	-- "Divine Star" Holy 110744 Shadow 122121
	{ 110744, jps.IsSpellKnown(110744) and playerIsInterrupt > 0 and LowestImportantUnitHpct < priest.get("HealthDPS")/100 , "player" , "Interrupt_DivineStar" },

	-- FOCUS CONTROL -- Chakra: Chastise 81209 -- Chakra: Sanctuary 81206 -- Chakra: Serenity 81208 -- Holy Word: Chastise 88625
	{ {"macro",macroCancelaura}, (jps.buffId(81208) or jps.buffId(81206)) and (jps.cooldown(81208) == 0 or jps.cooldown(81206) == 0) and jps.checkTimer("Chastise") == 0
	and canDPS(rangedTarget) , rangedTarget  , "Cancelaura_Chakra_" },
	{ "nested", LowestImportantUnitHpct > 0.50 and not jps.LoseControl("focus") and canDPS("focus") , parseControlFocus },
	{ "nested", LowestImportantUnitHpct > 0.50 and not jps.LoseControl(rangedTarget) , parseControl },
	
	-- Chakra: Serenity 81208 -- "Holy Word: Serenity" 88684
	{ 81208, not jps.buffId(81208) and jps.FinderLastMessage("Chastise_NO") == true , "player" , "|cffa335eeChakra_Serenity" },
	{ 81208, not jps.buffId(81208) and LowestImportantUnitHpct < 0.85 and jps.FinderLastMessage("Cancelaura") == false , "player" , "|cffa335eeChakra_Serenity" },
	{ 81208, not jps.buffId(81208) and not jps.FaceTarget and jps.FinderLastMessage("Cancelaura") == false , "player" , "|cffa335eeChakra_Serenity" },

	-- "Void Shift" 108968 -- "Prière du désespoir" 19236
	{ 108968, not playerAggro and UnitIsUnit(LowestImportantUnit,"player")~=1 and LowestImportantUnitHpct < 0.40 and jps.hp("player") > 0.85 , LowestImportantUnit , "Emergency_VoidShift_"..LowestImportantUnit },
	-- "Guardian Spirit"
	{ 47788, jps.FriendAggro(LowestImportantUnit) and LowestImportantUnitHpct < 0.40 , LowestImportantUnit },
	-- "Soins rapides" 2061 "From Darkness, Comes Light" 109186 gives buff -- "Vague de Lumière" 114255 "Surge of Light"
	{ 2061, jps.buff(114255) and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit , "SoinsRapides_Light_"..LowestImportantUnit },
	{ 2061, jps.buff(114255) and (jps.buffDuration(114255) < 4) , LowestImportantUnit , "SoinsRapides_Light_"..LowestImportantUnit },
	-- "Holy Spark" 131567 "Etincelle sacrée" -- increases the healing done by your next Flash Heal, Greater Heal or Holy Word: Serenity by 50% for 10 sec.
	{ "nested", jps.buff(131567,LowestImportantUnit) and LowestImportantUnitHpct < 0.70 , 
		{
			-- "Holy Word: Serenity" 88684 -- Chakra: Serenity 81208
			{ {"macro",macroSerenity}, jps.cooldown(88684) == 0 and jps.buffId(81208) , LowestImportantUnit },
			-- "Soins supérieurs" 2060
			{ 2060,  not jps.Moving and jps.buffStacks(63735,"player") == 2 , LowestImportantUnit },
			-- "Soins rapides" 2061
			{ 2061, not jps.Moving and jps.buffStacks(63735,"player") < 2 , LowestImportantUnit },
		},
	},

	-- DISPEL	
	{ "nested", LowestImportantUnitHpct > 0.50 , parseDispel },
	-- "Prière de guérison" 33076 -- TIMER POM -- UnitAffectingCombat("player") == 1
	{ 33076, not jps.buffTracker(33076) , LowestImportantUnit , "Tracker_Mending_"..LowestImportantUnit },

	-- PLAYER AGGRO
	{ "nested", playerAggro ,
		{
			-- "Spectral Guise" -- "Semblance spectrale" 108968 -- fast out of combat drinking
			{ 112833, jps.IsSpellKnown(112833) , "player" , "Aggro_Spectral" },
			-- "Oubli" 586 -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même et votre vitesse de déplacement ne peut être réduite pendant 5 s
			-- "Oubli" 586 -- Glyphe d'oubli 55684 -- Votre technique Oubli réduit à présent tous les dégâts subis de 10%.
			--{ 586, playerAggro and jps.IsSpellKnown(108942) , "player" , "Aggro_Oubli" },
			--{ 586, playerAggro and jps.glyphInfo(55684) , "player" , "Aggro_Oubli" },
			
			{ "nested", jps.hp("player") < priest.get("HealthDPS")/100 ,
				{
					-- "Pierre de soins" 5512
					{ {"macro","/use item:5512"}, select(1,IsUsableItem(5512))==1 and jps.itemCooldown(5512)==0 , "player" },
					-- "Prière du désespoir" 19236
					{ 19236, select(2,GetSpellBookItemInfo(priest.Spell["Desesperate"]))~=nil , "player" },
					-- "Prière de guérison" 33076 -- TIMER POM -- UnitAffectingCombat("player") == 1
					{ 33076, not jps.buff(33076) , "player" , "Aggro_Mending_Player" },
				},
				
				{ "nested", jps.hp("player") < priest.get("HealthEmergency")/100 ,
					{
					-- "Holy Word: Serenity" 88684 -- Chakra: Serenity 81208
					{ {"macro",macroSerenity}, jps.cooldown(88684) == 0 and jps.buffId(81208) , "player" , "Aggro_Serenity_Player" },
					-- "Soins rapides" 2061 "Holy Spark" 131567 "Etincelle sacrée" -- increases the healing done by your next Flash Heal, Greater Heal or Holy Word: Serenity by 50% for 10 sec.
					{ 2061, not jps.Moving and jps.buff(131567) ,"player" , "Aggro_SoinsRapides_HolySpark_Player" },
					-- "Power Word: Shield" 17 
					{ 17, jps.hp("player") < 0.50 and not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Aggro_Shield_Player" },
					-- "Soins rapides" 2061
					{ 2061, not jps.Moving and jps.hp("player") < 0.50, "player" , "Aggro_SoinsRapides__Player" },
					},
				},
						
				-- "Renew" 139 -- Haste breakpoints are 12.5 and 16.7%(Holy)
				{ 139, not jps.buff(139,"player") , "player" ,"Aggro_Renew_Player" },
				-- "Don des naaru" 59544
				{ 59544, (select(2,GetSpellBookItemInfo(priest.Spell["NaaruGift"]))~=nil) , "player" , "Aggro_Naaru_Player" },
			},
		},
	},

	-- GROUP HEAL
	{ "nested", CountInRange > 2 and AvgHealthLoss < 0.85 , 
		{
			-- "Circle of Healing" 34861
			{ 34861, true , LowestImportantUnit ,"COH_"..LowestImportantUnit },
			-- "Cascade" Holy 121135
			{ 121135, jps.IsSpellKnown(121135) , LowestImportantUnit },
			-- "Divine Insight" 109175
			{ 33076, jps.IsSpellKnown(109175) and jps.buff(109175), LowestImportantUnit },
		},
	},

	-- GROUP HEAL -- Chakra: Sanctuary 81206 -- jps.MultiTarget
	{ "nested", jps.MultiTarget and CountInRange > 2 and AvgHealthLoss < 0.75 and LowestImportantUnitHpct > 0.25 , 
		{
			-- "Divine Hymn" 64843 -- Chakra: Sanctuary 81206
			{ {"macro",sanctuaryHymn}, not playerAggro and not jps.buffId(81206) and jps.cooldown(81206) == 0 and jps.cooldown(64843) == 0 and AvgHealthLoss < 0.50 , "player" , "|cffa335eeSanctuary_HYMN"},
			-- "Circle of Healing" 34861
			{ 34861, true , LowestImportantUnit ,"COH_"..LowestImportantUnit },
			-- "Cascade" Holy 121135
			{ 121135, jps.IsSpellKnown(121135) , LowestImportantUnit },
			-- "Prayer of Healing" 596 -- Chakra: Sanctuary 81206 -- increase 25 % Prayer of Mending, Circle of Healing, Divine Star, Cascade, Halo, Divine Hymn
			{ {"macro",sanctuaryPOH}, not jps.buffId(81206) and jps.cooldown(81206) == 0 and (type(POHTarget) == "string") and jps.cooldown(596) == 0 , POHTarget , "|cffa335eeSanctuary_POH"},
			{ 596, (type(POHTarget) == "string") , POHTarget },
		},
	},

	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ 528, jps.castEverySeconds(528,2) and jps.DispelOffensive(rangedTarget) and LowestImportantUnitHpct > 0.50 , rangedTarget , "|cff1eff00DispelOffensive_"..rangedTarget },
	-- "Mot de l'ombre : Mort" 32379 -- FARMING OR PVP -- NOT PVE
	{ 32379, type(DeathEnemyTarget) == "string" , DeathEnemyTarget , "|cFFFF0000Death_MultiUnit_" },
	{ 32379, priest.canShadowWordDeath(rangedTarget) , rangedTarget , "|cFFFF0000Death_Health_"..rangedTarget },

	{ "nested", LowestImportantUnitHpct < 0.85 ,
		{
			-- "Holy Word: Serenity" 88684 -- Chakra: Serenity 81208
			{ {"macro",macroSerenity}, jps.cooldown(88684) == 0 and jps.buffId(81208) , LowestImportantUnit , "Emergency_Serenity_"..LowestImportantUnit },
			-- "Prière de guérison" 33076 
			{ 33076, (type(MendingTarget) == "string") , MendingTarget , "Emergency_MendingTarget_" },
			{ "nested", not jps.Moving and LowestImportantUnitHpct < 0.70 , 
				{
					-- "Soins supérieurs" 2060
					{ 2060,  jps.buffStacks(63735,"player") == 2 , LowestImportantUnit , "Emergency_SoinsSup_"..LowestImportantUnit  },
					-- "Soins rapides" 2061
					{ 2061, (LowestImportantUnitHpct < 0.50) , LowestImportantUnit , "Emergency_SoinsRapides_40%_"..LowestImportantUnit },
					-- "Soins de lien"
					{ 32546 , type(BindingHealTarget) == "string" , BindingHealTarget , "Emergency_Lien_" },
					-- "Soins rapides" 2061
					{ 2061, jps.buffStacks(63735,"player") < 2, LowestImportantUnit , "Emergency_SoinsRapides_"..LowestImportantUnit },
				},
			},
			-- "Circle of Healing" 34861
			{ 34861, AvgHealthLoss < 0.85 , LowestImportantUnit , "Emergency__COH_"..LowestImportantUnit },
			-- "Don des naaru" 59544
			{ 59544, (select(2,GetSpellBookItemInfo(priest.Spell["NaaruGift"]))~=nil) , LowestImportantUnit , "Emergency_Naaru_"..LowestImportantUnit },
			-- "Renew" 139 -- Haste breakpoints are 12.5 and 16.7%(Holy)
			{ 139, not jps.buff(139,LowestImportantUnit) , LowestImportantUnit , "Emergency_Renew_"..LowestImportantUnit },
			-- "Power Word: Shield" 17 
			{ 17, LowestImportantUnitHpct < 0.50 and not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Emergency_Shield_"..LowestImportantUnit },
		},
	},
	
	-- "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
	-- "Renew" 139 -- Haste breakpoints are 12.5 and 16.7%(Holy)
	{ 139, not jps.buffTracker(139) and jps.FriendAggro(LowestImportantUnit) , LowestImportantUnit , "Tracker_Renew_"..LowestImportantUnit },
	
	-- DAMAGE -- Chakra: Chastise 81209
	{ "nested", jps.FaceTarget and canDPS(rangedTarget) and LowestImportantUnitHpct > 0.85 , parseDamage },

	-- "Holy Word: Serenity" 88684 -- Chakra: Serenity 81208
	{ {"macro",macroSerenity}, jps.cooldown(88684) == 0 and jps.buffId(81208) and (LowestImportantUnitHealth > priest.AvgAmountGreatHeal) , LowestImportantUnit , "Serenity_"..LowestImportantUnit },
	{ "nested", not jps.Moving , 
		{
			-- "Soins supérieurs" 2060
			{ 2060,  (jps.buffStacks(63735,"player") == 2) and (LowestImportantUnitHealth > priest.AvgAmountGreatHeal) , LowestImportantUnit , "SoinsSup_"..LowestImportantUnit  },
			-- "Soins de lien"
			{ 32546 , type(BindingHealTarget) == "string" , BindingHealTarget , "Lien_" },					
			-- "Soins rapides" 2061
			{ 2061, (LowestImportantUnitHealth > priest.AvgAmountGreatHeal) and jps.buffStacks(63735,"player") < 2, LowestImportantUnit, "SoinsRapides_"..LowestImportantUnit },
		},
	},

	-- "Infusion de puissance" 10060 
	{ 10060, not jps.buffId(10060,"player") and UnitAffectingCombat("player") == 1, "player" , "POWERINFUSION_" },
	-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
	{ 6346, not jps.buff(6346,"player") , "player" },
	-- "Feu intérieur" 588 -- "Volonté intérieure" 73413
	{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player") , "player" }, -- "target" by default must must be a valid target

	-- "Soins" 2050
	{ 2050, jps.buff(139,LowestImportantUnit) and LowestImportantUnitHealth > priest.AvgAmountHeal and jps.buffDuration(139,LowestImportantUnit) < 4 , LowestImportantUnit , "Soins_"..LowestImportantUnit },
	
}

	local spell = nil
	local target = nil
	local spell,target = parseSpellTable(spellTable)
	return spell,target
end

jps.registerRotation("PRIEST","HOLY", priestHoly, "Holy Priest" )

-- Haste at least 12.51% (4721) preferably up to 16.66% (7082) cap
-- to ensure we get additional ticks from HW: Sanctuary and the Glyphed Renew.

-- Chakra: Serenity 81208
-- Increases the healing done by your single-target healing spells by 25%
-- causes them to refresh the duration of your Renew on the target, and transforms your Holy Word: Chastise spell into Holy Word: Serenity.
-- "Holy Word: Serenity" 88684
-- Instantly heals the target for 12367 to 14517 (+ 130% of Spell power)
-- "Holy Word: Serenity" increases the critical effect chance of your healing spells on the target by 25% for 6 sec. 10 sec cooldown.

-- Chakra: Sanctuary 81206
-- Increases the healing done by your area of effect healing spells by 25% -- Prayer of Mending, Circle of Healing, Divine Star, Cascade, Halo, Divine Hymn
-- reduces the cooldown of your Circle of Healing spell by 2 sec, and transforms your Holy Word: Chastise spell into Holy Word: Sanctuary
-- Holy Word: Sanctuary 88685
-- Blesses the ground with divine light, healing all within it for 461 to 547 (+ 5.83% of Spell power) every 2 sec for 30 sec.
-- Only one Sanctuary can be active at a time  Healing effectiveness diminishes for each player beyond 6 within the area.

-- Chakra: Chastise 81209
-- Increases the damage done by your Shadow and Holy spells by 50%, grants a 10% chance for Smite to reset the cooldown of Holy Word: Chastise
-- reduces the mana cost of Smite and Holy Fire by 90%, and transforms your Holy Word spell back into Holy Word: Chastise
-- Holy Word: Chastise 88625
-- Chastise the target for 627 to 702 (+ 61.4% of Spell power) Holy damage, and disorients them for 3 sec -- 30 sec cooldown.

-- "Serendipity" 63735
-- When you heal with Binding Heal or Flash Heal, the cast time of your next Greater Heal or Prayer of Healing spell is reduced by 20% 
-- and mana cost reduced by 20%. Stacks up to 2 times. Lasts 20 sec.

-- "Guardian Spirit" 47788
-- Calls a guardian spirit to watch over the friendly target. The spirit increases the healing received by the target by 60%
-- and also prevents the target from dying by sacrificing. Lasts 10 sec.  Castable while stunned.

-- "Lightwell" This spell can be used while Tanking, Kiting, Blinded, Stunned, Disoriented, Sapped, Casting another heal or spell

-- "Holy Spark" 131567 (Priest PvP Healing 2P Bonus Holy Spark). When you cast Prayer of Mending, the initial target is blessed with a Holy Spark
-- increasing the healing done by your next Flash Heal, Greater Heal or Holy Word: Serenity by 50% for 10 sec.
-- 1.Serenity -- 2.PoM -- 3.Greater Heal which uses your HOLY SPARK buff proc the greater heal which is also likely to crit due to Serenity buff

-- From Darkness, Comes Light has been buffed this patch increasing it's procs when using Renew, Circle of Healing, Prayer of Mending, and Prayer of Healing

-- "Divine Insight" 109175
-- When you cast Greater Heal or Prayer of Healing, there is a 40% chance
-- your next Prayer of Mending will not trigger its cooldown, and will jump to each target instantly.
