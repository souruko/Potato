
 function Turbine.Chat.Received(sender, args)

    -- filter nil massages
    if  (args.Message  == nil) then
        return
    end

    -- filter by chattype
    if 
	args.ChatType ~= Turbine.ChatType.PlayerCombat 
        and args.ChatType ~= Turbine.ChatType.Death then

        return
    end

    -- "defeate" tooltips
    if _G.Settings.highlight_defeated  then
        if string.find(args.Message, " defeated ") then
            local updateType,targetName = ParseCombatChat(string.gsub(string.gsub(args.Message,"<rgb=#......>(.*)</rgb>","%1"),"^%s*(.-)%s*$", "%1"))

            if updateType == 9 and targetName ~= nil then
                Potato:DefeatTooltip(targetName)
                return
            end
        end
    end

    if _G.Settings.display_durations then
        -- lm cc duration
        if string.find(args.Message, "hit</rgb> with Blinding Flash on ") then
            local sk = _G.Settings.cc_skills and _G.Settings.cc_skills.blinding_flash
            if sk == nil or sk.enabled then
                local updateType,initiatorName,targetName,skillName,var1,var2,var3,var4 = ParseCombatChat(string.gsub(string.gsub(args.Message,"<rgb=#......>(.*)</rgb>","%1"),"^%s*(.-)%s*$", "%1"))
                if updateType == 1 and targetName ~= nil then
                    Potato:DisplayDuration(1090541222, sk and sk.duration or 30, targetName)
                    return
                end
            end
        end

        -- burg cc duration
        if string.find(args.Message, "hit</rgb> with Riddle on ") then
            local sk = _G.Settings.cc_skills and _G.Settings.cc_skills.riddle
            if sk == nil or sk.enabled then
                local updateType,initiatorName,targetName,skillName,var1,var2,var3,var4 = ParseCombatChat(string.gsub(string.gsub(args.Message,"<rgb=#......>(.*)</rgb>","%1"),"^%s*(.-)%s*$", "%1"))
                if updateType == 1 and targetName ~= nil then
                    Potato:DisplayDuration(1090541257, sk and sk.duration or 30, targetName)
                    return
                end
            end
        end

        -- hunter cc duration
        if string.find(args.Message, "hit</rgb> with Distracting Shot on ") then
            local sk = _G.Settings.cc_skills and _G.Settings.cc_skills.distracting_shot
            if sk == nil or sk.enabled then
                local updateType,initiatorName,targetName,skillName,var1,var2,var3,var4 = ParseCombatChat(string.gsub(string.gsub(args.Message,"<rgb=#......>(.*)</rgb>","%1"),"^%s*(.-)%s*$", "%1"))
                if updateType == 1 and targetName ~= nil then
                    Potato:DisplayDuration(1091459007, sk and sk.duration or 35, targetName)
                    return
                end
            end
        end

        -- mariner cc duration
        if string.find(args.Message, "hit</rgb> with Thrum of the Sea on ") then
            local sk = _G.Settings.cc_skills and _G.Settings.cc_skills.thrum_of_the_sea
            if sk == nil or sk.enabled then
                local updateType,initiatorName,targetName,skillName,var1,var2,var3,var4 = ParseCombatChat(string.gsub(string.gsub(args.Message,"<rgb=#......>(.*)</rgb>","%1"),"^%s*(.-)%s*$", "%1"))
                if updateType == 1 and targetName ~= nil then
                    Potato:DisplayDuration(1092830905, sk and sk.duration or 25, targetName)
                    return
                end
            end
        end

        -- lm stun imunity
        if string.find(args.Message, "benefit</rgb> with Sign of Power: Righteousness on ") then
            local sk = _G.Settings.cc_skills and _G.Settings.cc_skills.sop_righteousness
            if sk == nil or sk.enabled then
                local updateType,initiatorName,targetName,skillName,var1,var2,var3,var4 = ParseCombatChat(string.gsub(string.gsub(args.Message,"<rgb=#......>(.*)</rgb>","%1"),"^%s*(.-)%s*$", "%1"))
                if updateType == 17 and targetName ~= nil then
                    Potato:DisplayDuration(1090553882, sk and sk.duration or 15, targetName)
                    return
                end
            end
        end

        -- custom cc skills
        if _G.Settings.cc_custom_skills then
            for i = 1, #_G.Settings.cc_custom_skills do
                local sk = _G.Settings.cc_custom_skills[i]
                if sk.enabled and sk.name ~= "" then
                    if string.find(args.Message, "hit</rgb> with " .. sk.name .. " on ") then
                        local updateType,initiatorName,targetName,skillName,var1,var2,var3,var4 = ParseCombatChat(string.gsub(string.gsub(args.Message,"<rgb=#......>(.*)</rgb>","%1"),"^%s*(.-)%s*$", "%1"))
                        if updateType == 1 and targetName ~= nil then
                            Potato:DisplayDuration(sk.icon or 1090541222, sk.duration, targetName)
                            return
                        end
                    end
                end
            end
        end
    end

 end



function ParseCombatChat(line)
	-- 1) Damage line ---

	local initiatorName,avoidAndCrit,skillName,targetNameAmountAndType = string.match(line,"^(.*) scored a (.*)hit(.*) on (.*)%.$"); -- (updated in v4.1.0)
	
	if (initiatorName ~= nil) then
		
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
		
		local avoidType =
			string.match(avoidAndCrit,"^partially blocked") and 8 or
			string.match(avoidAndCrit,"^partially parried") and 9 or
			string.match(avoidAndCrit,"^partially evaded") and 10 or 1;
		local critType =
			string.match(avoidAndCrit,"critical $") and 2 or
			string.match(avoidAndCrit,"devastating $") and 3 or 1;
		skillName = string.match(skillName,"^ with (.*)$") or "Direct Damage"; -- (as of v4.1.0)
		
		local targetName,amount,dmgType,moralePower = string.match(targetNameAmountAndType,"^(.*) for ([%d,]*) (.*)damage to (.*)$");
		-- damage was absorbed
		if targetName == nil then
			targetName = string.gsub(targetNameAmountAndType,"^[Tt]he ","");
			amount = 0;
			dmgType = 13;
			moralePower = 3;
		-- some damage was dealt
		else
			targetName = string.gsub(targetName,"^[Tt]he ","");
			amount = string.gsub(amount,",","")+0;
      
      dmgType = string.match(dmgType, "^%(.*%) (.*)$") or dmgType; -- 4.2.3 adjust for mounted combat
			-- note there may be no damage type
			dmgType = 
				dmgType == "Common " and 1 or
				dmgType == "Fire " and 2 or
				dmgType == "Lightning " and 3 or
				dmgType == "Frost " and 4 or
				dmgType == "Acid " and 5 or
				dmgType == "Shadow " and 6 or
				dmgType == "Light " and 7 or
				dmgType == "Beleriand " and 8 or
				dmgType == "Westernesse " and 9 or
				dmgType == "Ancient Dwarf-make " and 10 or 
        dmgType == "Orc-craft " and 11 or
        dmgType == "Fell-wrought " and 12 or 13;
			moralePower = (moralePower == "Morale" and 1 or moralePower == "Power" and 2 or 3);
		end
		
		-- Currently ignores damage to power
		if (moralePower == 2) then return nil end
		
		-- Update
		return 1,initiatorName,targetName,skillName,amount,avoidType,critType,dmgType;
	end
	
	-- 2) Heal line --
	--     (note the distinction with which self heals are now handled)
	--     (note we consider the case of heals of zero magnitude, even though they presumably never occur)
	local initiatorName,crit,skillNameTargetNameAmountAndType = string.match(line,"^(.*) applied a (.-)heal (.*)%.$");
	
	if (initiatorName ~= nil) then
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
		local critType =
			crit == "critical " and 2 or
			crit == "devastating " and 3 or 1;
		
		local skillNameTargetNameAndAmount,ending = string.match(skillNameTargetNameAmountAndType,"^(.*)to (.*)$");
		local targetName,skillName,amount;
		moralePower = (ending == "Morale" and 1 or (ending == "Power" and 2 or 3));
		-- heal was absorbed (unfortunately it appears this actually shows as a "hit" instead, so we never get into the first conditional)
		if (moralePower == 3) then
			targetName = string.gsub(ending,"^[Tt]he ","");
			amount = 0;
			-- skill name will equal nil if this was a self heal
			skillName = string.match(skillNameTargetNameAndAmount,"^with (.*) $");
		-- heal applied
		else
			skillName,targetName,amount = string.match(skillNameTargetNameAndAmount,"^(.*)to (.*) restoring ([%d,]*) points? $");
			targetName = string.gsub(targetName,"^[Tt]he ","");
			amount = string.gsub(amount,",","")+0;
			-- skill name will equal nil if this was a self heal
			skillName = string.match(skillName,"^with (.*) $");
		end
		
		-- rearrange if this was a self heal
		if (skillName == nil) then
			skillName = initiatorName;
			initiatorName = targetName;
		end
		
		-- Update
		return (moralePower == 2 and 4 or 3),initiatorName,targetName,skillName,amount,critType;
	end
	
	-- 3) Buff line --
	
	local initiatorName,skillName,targetName = string.match(line,"^(.*) applied a benefit with (.*) on (.*)%.$");
	
	if (initiatorName ~= nil) then
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
		targetName = string.gsub(targetName,"^[Tt]he ","");
		
		-- Update
		return 17,initiatorName,targetName,skillName;
	end
	
	-- 4) Avoid line --
	local initiatorNameMiss,skillName,targetNameAvoidType = string.match(line,"^(.*) to use (.*) on (.*)%.$");
	
	if (initiatorNameMiss ~= nil) then
		initiatorName = string.match(initiatorNameMiss,"^(.*) tried$");
		local targetName, avoidType;
		-- standard avoid
		if (initiatorName ~= nil) then
			initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
			targetName,avoidType = string.match(targetNameAvoidType,"^(.*) but (.*) the attempt$");
			targetName = string.gsub(targetName,"^[Tt]he ","");
			avoidType = 
				string.match(avoidType," blocked$") and 5 or
				string.match(avoidType," parried$") and 6 or
				string.match(avoidType," evaded$") and 7 or
				string.match(avoidType," resisted$") and 4 or
				string.match(avoidType," was immune to$") and 3 or 1;
				
		-- miss or deflect (deflect added in v4.2.2)
		else
			initiatorName = string.match(initiatorNameMiss,"^(.*) missed trying$");
      if (initiatorName == nil) then
        initiatorName = string.match(initiatorNameMiss,"^(.*) was deflected trying$");
        avoidType = 11;
      else
        avoidType = 2;
      end
      
			initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
			targetName = string.gsub(targetNameAvoidType,"^[Tt]he ","");
		end
		
		-- Sanity check: must have avoided in some manner
		if (avoidType == 1) then return nil end
		
		-- Update
		return 1,initiatorName,targetName,skillName,0,avoidType,1,13;
	end
	
	-- 5) Reflect line --
	
	local initiatorName,amount,dmgType,targetName = string.match(line,"^(.*) reflected ([%d,]*) (.*) to the Morale of (.*)%.$");
	
	if (initiatorName ~= nil) then
		local skillName = "Reflect";
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
		targetName = string.gsub(targetName,"^[Tt]he ","");
		amount = string.gsub(amount,",","")+0;
		
		local dmgType = string.match(dmgType,"^(.*)damage$");
		-- a damage reflect
		if (dmgType ~= nil) then
			dmgType = 
				dmgType == "Common " and 1 or
				dmgType == "Fire " and 2 or
				dmgType == "Lightning " and 3 or
				dmgType == "Frost " and 4 or
				dmgType == "Acid " and 5 or
				dmgType == "Shadow " and 6 or
				dmgType == "Light " and 7 or
				dmgType == "Beleriand " and 8 or
				dmgType == "Westernesse " and 9 or
				dmgType == "Ancient Dwarf-make " and 10 or
				dmgType == "Orc-craft " and 11 or
				dmgType == "Fell-wrought " and 12 or 13;
						
			-- Update
			return 1,initiatorName,targetName,skillName,amount,1,1,dmgType;
		-- a heal reflect
		else
			-- Update
			return 3,initiatorName,targetName,skillName,amount,1;
		end
	end
	
	-- 6) Temporary Morale bubble line (as of 4.1.0)
  local amount = string.match(line,"^You have lost ([%d,]*) points of temporary Morale!$");
	if (amount ~= nil) then
		amount = string.gsub(amount,",","")+0;
		
		-- the only information we can extract directly is the target and amount
		return 14,nil,LocalPlayer.name,nil,amount;
	end
	
	-- 7) Combat State Break notice (as of 4.1.0)
	
	-- 7a) Root broken
	local targetName = string.match(line,"^.* ha[sv]e? released (.*) from being immobilized!$");
	if (targetName ~= nil) then
		targetName = string.gsub(targetName,"^[Tt]he ","");
		
		-- the only information we can extract directly is the target name
		return 16,nil,targetName,nil;
	end
	
	-- 7b) Daze broken
	local targetName = string.match(line,"^.* ha[sv]e? freed (.*) from a daze!$");
	if (targetName ~= nil) then
		targetName = string.gsub(targetName,"^[Tt]he ","");
		
		-- the only information we can extract directly is the target name
		return 16,nil,targetName,nil;
	end
	
	-- 7c) Fear broken (TODO: Check)
	local targetName = string.match(line,"^.* ha[sv]e? freed (.*) from a fear!$");
	if (targetName ~= nil) then
		targetName = string.gsub(targetName,"^[Tt]he ","");
		
		-- the only information we can extract directly is the target name
		return 16,nil,targetName,nil;
	end
	
	-- 8) Interrupt line --
	
	local targetName, initiatorName = string.match(line,"^(.*) was interrupted by (.*)!$");
	
	if (targetName ~= nil) then
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
		targetName = string.gsub(targetName,"^[Tt]he ","");
		
		-- Update
		return 7,initiatorName,targetName;
	end
	
	-- 9) Dispell line (corruption removal) --
	
	local corruption, targetName = string.match(line,"You have dispelled (.*) from (.*)%.$");
	
	if (corruption ~= nil) then
		initiatorName = LocalPlayer.name;
		targetName = string.gsub(targetName,"^[Tt]he ","");
		
		-- NB: Currently ignore corruption name
		
		-- Update
		return 8,initiatorName,targetName;
	end
	
	-- 10) Defeat lines ---
	
	-- 10a) Defeat line 1 (mob or played was killed)
	local initiatorName = string.match(line,"^.* defeated (.*)%.$");
	
	if (initiatorName ~= nil) then
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
		
		-- Update
		return 9,initiatorName;
	end
	
	-- 10b) Defeat line 2 (mob died)
	local initiatorName = string.match(line,"^(.*) died%.$");

	if (initiatorName ~= nil) then
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
		
		-- Update
		return 9,initiatorName;
	end
	
	-- 10c) Defeat line 3 (a LocalPlayer was killed or died)
	local initiatorName = string.match(line,"^(.*) has been defeated%.$");

	if (initiatorName ~= nil) then
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
		
		-- Update
		return 9,initiatorName;
	end
	
	-- 10d) Defeat line 4 (you were killed)
	local match = string.match(line,"^.* incapacitated you%.$");

	if (match ~= nil) then
		initiatorName = LocalPlayer.name;
		
		-- Update
		return 9,initiatorName;
	end
	
	-- 10e) Defeat line 5 (you died)
	local match = string.match(line,"^You have been incapacitated by misadventure%.$");

	if (match ~= nil) then
		initiatorName = LocalPlayer.name;
		
		-- Update
		return 9,initiatorName;
	end
	
	-- 10f) Defeat line 6 (you killed a mob)
	local initiatorName = string.match(line,"^Your mighty blow defeated^ (.*)%.$");
	
	if (initiatorName ~= nil) then
		initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
		
		-- Update
		return 9,initiatorName;
	end
	
	-- 11) Revive lines --
	
	-- 11a) Revive line 1 (LocalPlayer revived)
	local initiatorName = string.match(line,"^(.*) has been revived%.$");
	
	if (initiatorName ~= nil) then
	  initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
	  
		-- Update
	  return 10,initiatorName;
	end
	
	-- 11b) Revive line 2 (LocalPlayer succumbed)
	local initiatorName = string.match(line,"^(.*) has succumbed to .* wounds%.$");
	
	if (initiatorName ~= nil) then
	  initiatorName = string.gsub(initiatorName,"^[Tt]he ","");
	  
		-- Update
	  return 10,initiatorName;
	end
	
	-- 11c) Revive line 3 (you were revived)
	local match = string.match(line,"^You have been revived%.$");
	
	if (match ~= nil) then
	  initiatorName = LocalPlayer.name;
	  
		-- Update
	  return 10,initiatorName;
	end
	
	-- 11d) Revive line 4 (you succumbed)
	local match = string.match(line,"^You succumb to your wounds%.$");
	
	if (match ~= nil) then
	  initiatorName = LocalPlayer.name;
	  
		-- Update
	  return 10,initiatorName;
	end
	
	-- if we reach here, we were unable to parse the line
	--  (note there is very little that isn't parsed)
end
