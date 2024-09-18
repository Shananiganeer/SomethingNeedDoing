--[[
names of chars to do turnins
The last var is whether this char will attempt GC supply turnins and attempt rank promotions.
this will take up to 15-20 seconds so dont enable it for every character unless you really need it (supply missions for leveling jobs basically)
process_gc_rank  = 0	--0=no,1=yes. do we try to rank up the GC and maybe do a supply delivery turnin?
expert_hack      = 0	--0=no,1=yes. it will try in 15 second cycles. to do deliveries then turn them off and let it try to buy venture coins . up to 12 times. or when there is no increase in venture coins
clean_inventory	 = 0    --0=no, >0 check inventory slots free and try to clean out inventory . leave it at 0 if you dont know how to use it. and don't ask me for help on punish or i will block you.  the answer is in _functions.lua
]]
---------------------------------
--FUTA_GC SCRIPT CONFIGURATION --
---------------------------------
--Please read these, you could use this script to go randomize fc emblems for example instead of doing the full script
----------------------
--Behaviour Configs --
----------------------
gachi_jumpy   = 0 	--0=no jump, 1=yes jump.  jump or not. sometimes navmesh goes through the shortcut in uldah and sometimes gets stuck getting to bells in housing districts
auto_eqweep   = 0	--0=no, 1=yes + job change.  Basically this will check to see if your on a DOH or DOL, if you are then it will scan your DOW/DOM and switch you to the highest level one you have, auto equip and save gearset. niche feature i like for myself . off by default
config_sell   = 0	--0=dont do anything,1=change char setting to not give dialog for non tradeables etc selling to npc, 2=reset setting back to yes check for non tradeables etc selling to npc. usecase for 1 and 2 are one time things for a cleaning run so that they can subsequently handle selling or not selling. this feature will be stripped out once limiana updaptes AR
nnl			  = 1   --leave the novicenetwork
movementtype  = 0   --0 = vnavmesh, 1 = visland. many things wont work with visland mode. its there as emergency for cleaning only.
open_coffers  = 0	--0=no,1=yes. do we try to open coffers before doing a turnin round. (will iterate through the list of items).
----------------------
--Refueling Configs --
----------------------
restock_fuel  = 1111 --0=don't do anything, n>0 -> if we have less ceruleum fuel than this amount on a character that has repair materials, restock up to at least the restock_amt value on next line
restock_amt   = 6666 --n>0 minimum amount of total fuel to reach, when restocking
--------------------
--Process Configs --
--------------------
process_players  = 1	--0=no,1=yes+cleaning. do we run the actual GC turnins? turning this on will run the chars from chars_fn to go do seal turnins and process whatever deliveroo rules you setup, 2=cleaning only
--------------------
----Coffer Table----
--------------------
koffers = {
{38467,"Gladiator's Plundered Arms (Lv. 15)"},
{38469,"Gladiator's Doctore Arms (Lv. 20)"},
{38470,"Gladiator's Frostbite Arms (Lv. 24)"},
{38471,"Gladiator's Inquisitor Arms (Lv. 28)"},
{44107,"Black Mage's Verdant Arms (Lv. 47)"},
{38475,"Paladin's Ancient Arms (Lv. 41)"},
{38474,"Paladin's Crier Arms (Lv. 38)"},
{38476,"Paladin's Dzemael Arms (Lv. 44)"},
{38473,"Paladin's Flametongue Arms (Lv. 35)"},
{38472,"Paladin's Longstop Arms (Lv. 32)"},
{38477,"Paladin's Templar Arms (Lv. 47)"}
}

--[[
------------------------
--SCRIPT REQUIREMENTS --
------------------------
Required Plogons:
Autoretainer
YesAlready
TextAdvance
Deliveroo
Visland
Vnavmesh
Simpletweaks
Something Need Doing (Croizat version)
-----------------
-SUPER IMPORTANT-
-----------------
Make sure _functions.lua exist in the snd folder. which should look something like this path %AppData%\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\
get _functions.lua from same place as this script came from

-------------------------
--PLUGIN CONFIGURATIONS--
-------------------------
FFXIV itself -> make sure all login notifications are off. like help, achievements etc. this is unfortunately super annoying. you may need to login/out a few times to ensure no weird popups are appearing.
Simpletweaks -> Setup autoequip command, "/equipguud" or just use the default "/equiprecommended"
Simpletweaks -> Setup equipjob command, "/equipjob"
Simpletweaks -> targeting fix on
SND -> Turn off SND targeting
YesAlready -> Lists -> Edit company crest design.
YesAlready -> Lists -> Retire to an inn room.
YesAlready -> Lists -> Move to the company workshop
YesAlready -> Lists -> Change free company allegiance.
YesAlready -> YesNo -> /Pay the 15,000-gil fee to switch your company's allegiance to the.*/
YesAlready -> YesNo -> /Execute.*/
YesAlready -> YesNo -> /of ceruleum for.*/
YesAlready -> YesNo -> /Enter the estate.*/
YesAlready -> YesNo -> Save changes to crest design?

Optional:
YesAlready -> YesNo -> /Purchase the action .*/ 
(if you add above. remove the wait 2 and the line for yesno pcall for buying buffs)

--some ideas for next version
--https://discord.com/channels/1001823907193552978/1196163718216679514/1215227696607531078
--stop repeating code for returning home.. introduces danger of errors popping up

--FC TAG Randomizer?!?!
--FC Tag re-writer?!?!
]]

--debug new stuff
--yield("FC Tag hehehe -> "..generateFiveDigitText(process_tags))
--yield("/pcraft stop")

-- Specify the path to your text file
--[[
	--some vestigial junk i may remove if not needed once i update script properly
	tempchar = GetCharacterName()
	tempchar = tempchar:match("%s*(.-)%s*") --remove spaces at start and end only
	tempchar = tempchar:gsub("%s", "")  --remove all spaces
	tempchar = tempchar:gsub("'", "")   --remove all apostrophes
]]

function Final_GC_Cleaning()
	--turn around in case we aren't facing the correct way
	--this attempts to target serpent or flame personnel or even storm.  assuming you have a separate line in a hotkey for each type.
	--the purpose of this section is to get your char to face the npcs and orient the camera properly. otherwise the rest of the script might die

	visland_stop_moving() --just in case we want to auto equip rq before dumping gear
	--deliveroo i choose you
	yield("/deliveroo enable")
	yield("/wait 1")

	--loop until deliveroo done if we aren't using the hack.
	if FUTA_processors[hoo_arr_weeeeee][3][4] == 0 then
		dellyroo = true
		dellyroo = DeliverooIsTurnInRunning()
		dellycount = 0
		while dellyroo do
			yield("/wait 5")
			dellyroo = DeliverooIsTurnInRunning()
			dellycount = dellycount + 1
			yield("/echo Processing Retainer Abuser")
			if dellycount > 100 then
				--this will solve getting stuck on deliveroo doing nothing while its enabled
				yield("/deliveroo disable")
				yield("/wait 2")
				ungabunga()
				yield("/deliveroo enable")
				yield("/wait 3")
				dellycount = 0
			end
		end
	end

	--added 5 second wait here because sometimes they get stuck.
	yield("/wait 5")
	
	if nnl == 1 then
		yield("/novicenetworkleave")
	end
	
	--expert delivery hack. meant for printing venture tokens on early chars
	if FUTA_processors[hoo_arr_weeeeee][3][4] == 1 then
	PauseYesAlready()
	yield("/wait 2")
		GCrenk = GetFlamesGCRank()
		if GetMaelstromGCRank() > GCrenk then
			GCrenk = GetMaelstromGCRank()
		end
		if GetAddersGCRank() > GCrenk then
			GCrenk = GetAddersGCRank()
		end
		SealCap = 9000	
		if GCrenk == 2 then SealCap = 14000 end
		if GCrenk == 3 then SealCap = 19000 end
		if GCrenk == 4 then SealCap = 24000 end
		if GCrenk == 5 then SealCap = 29000 end  --requires R1 Hunting Log done
		if GCrenk == 6 then SealCap = 34000 end
		if GCrenk == 7 then SealCap = 39000 end
		if GCrenk == 8 then SealCap = 44000 end  --requires R2 Hunting Log done + Aurum Vale
		if GCrenk == 9 then SealCap = 49000 end  --requires Dzemael Darkhold
		yield("/echo Seal Cap is -> "..SealCap)
		SetFlamesGCRank(9)
		SetAddersGCRank(9)
		SetMaelstromGCRank(9)
		dellycount = 0
		yield("/echo Expert Delivery hack enabled")
		yield("/wait 1")
		benture = GetItemCount(21072)
		while dellycount < 12 do --max of 12 loops
			yield("/deliveroo enable")
			yield("/wait 6")
			--20 = storm, 21 = serpent, 22 = flame
			maxcheck = 0
			while (GetItemCount(20) + GetItemCount(21) + GetItemCount(22)) < SealCap and maxcheck < 15 do
				yield("/wait 1")
				maxcheck = maxcheck + 1
			end
			yield("/deliveroo disable")
			yield("/wait 2")
			ungabunga() --get out of menus haha
			dellycount = dellycount + 1
			if benture == GetItemCount(21072) then --nothing changed since last time we did the round. maybe we ned to exit but increase the cardinality just in case
				dellycount = dellycount + 5
			end
			benture = GetItemCount(21072)
		end
		SetFlamesGCRank(GCrenk)
		SetAddersGCRank(GCrenk)
		SetMaelstromGCRank(GCrenk)
		RestoreYesAlready()
		yield("/wait 2")
	end
	
	--try to turn in supply mission items and rankup before leaving if its set for that char
	if FUTA_processors[hoo_arr_weeeeee][3][3] == 1 then
		yield("/echo movement stopped - time for GC turn ins")
		--yield("<wait.15>")
		--yield("/waitaddon SelectString <maxwait.120>")
		yield("/visland stop")
		yield("/wait 1")
		yield("/target Personnel Officer")
		yield("/wait 1")
		yield("/send NUMPAD0")
		yield("/pcall SelectString true 0 <wait.1>")
		yield("/send NUMPAD0")
		yield("/wait 1")
		yield("/send NUMPAD0")
		yield("/wait 1")
		yield("/pcall GrandCompanySupplyList true 0 1 2")
		yield("/wait 1")
		yield("/send NUMPAD0")
		yield("/wait 1")
		yield("/send NUMPAD0")
		yield("/wait 1")
		yield("/send ESCAPE <wait.1.5>")
		yield("/send ESCAPE <wait.1.5>")
		yield("/wait 3")

		floop = 0
		while floop < 3 do --we can go up to 4 safely if we are below it. if you put in the effort to finish GC log 1, go pop rank 5 :~D
			--try to promote
			yield("/wait 1")
			yield("/target Personnel Officer")
			yield("/wait 1")
			yield("/interact")
			yield("/wait 2")
			yield("/pcall SelectString true 1")
			yield("/wait 3")
			yield("/pcall GrandCompanyRankUp true 0")
			yield("/wait 1")
			yield("/send ESCAPE <wait.1.5>")
			yield("/send ESCAPE <wait.1.5>")
			yield("/send ESCAPE <wait.1.5>")
			yield("/send ESCAPE <wait.1.5>")
			yield("/wait 3")
			--wait for char condition 1
			while GetCharacterCondition(32) == true and GetCharacterCondition(35) == true do
				yield("/wait 1")
			end
			yield("/wait 2")
			floop = floop + 1
		end

		--output a log of the GC ranks and your current job level to a log file stored in the SND folder
		--yield("/echo Log output debug line 1")
		local folderPath = os.getenv("appdata").."\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\"
		local file = io.open(folderPath .. "GCrankLog.txt", "a")
		if file then
			-- Write text to the file
			currentTime = os.date("*t")
			formattedTime = string.format("%04d-%02d-%02d %02d:%02d:%02d", currentTime.year, currentTime.month, currentTime.day, currentTime.hour, currentTime.min, currentTime.sec)
			file:write(formattedTime.." - "..FUTA_processors[hoo_arr_weeeeee][1][1].." - Adders - "..GetAddersGCRank().." - Maelstrom - "..GetMaelstromGCRank().." - Flames - "..GetFlamesGCRank().."\n")
			-- Close the file handle
			file:close()
			yield("/echo Text has been written to '" .. folderPath .. "GCrankLog.txt'")
		else
			yield("/echo Error: Unable to open file for writing")
		end
	end
	
	FUTA_return()
	
--[[ dumping out this part. opening venture coffers is kind of annoying waste of time. maybe we make it optional later -->TODO<--
	--Code for opening venture coffers
	yield("/wait 3")
	yield("/echo Number of Venture Coffers to open: "..GetItemCount(32161))
	VCnum = GetItemCount(32161)
	while (VCnum > 0) do
		--this is no longer reliable
		--yield("/item Venture Coffer")
		yield("/send X")
		yield("/wait 6")
		VCnum = GetItemCount(32161)
		yield("/echo Number of Venture Coffers left: "..GetItemCount(32161))
	end
	---]]

	--Code for opening FC menu so allagan tools can pull the FC points
	--yield("/freecompanycmd")
	--yield("/wait 3")
	--removed above two lines because allagan tools was 0ing out FC points sometimes when opening too quickly before logging out of the char
end

--gc turn in
function FUTA_robust_gc()
	yield("/wait 2")
	--CharacterSafeWait() --we dont neeed to wait we are on the char already
	 yield("/echo Processing Retainer Abuser")
	--before we dump gear lets check if we are opening coffers
	if open_coffers == 1 then
		for i=1,#koffers do
			if GetItemCount(koffers[i][1]) > 0 then
				yield("/item "..koffers[i][2])
				yield("/wait 4")
			end
		end
		yield("/wait 4")
	end
	--before we dump gear lets check to see if we are on the right job or if we care about it.
	if config_sell == 1 then
		yield("/maincommand Item Settings")
		yield("/wait 0.5")
		yield("/pcall ConfigCharaItem true 18 288 0 u0")
		yield("/pcall ConfigCharaItem true 0")
		yield("/wait 0.5")
		yield("/pcall ConfigCharacter true 1")
	end
	if config_sell == 2 then
		yield("/maincommand Item Settings")
		yield("/wait 0.5")
		yield("/pcall ConfigCharaItem true 18 288 1 u0")
		yield("/pcall ConfigCharaItem true 0")
		yield("/wait 0.5")
		yield("/pcall ConfigCharacter true 1")
	end
	if auto_eqweep == 1 then
		if are_we_dol() then
			yield("/equipjob "..job_short(which_cj()))
			yield("/echo Switching to "..job_short(which_cj()))
			yield("/wait 3")
		end
	end
	weclean = 0
	if process_players == 1  then
		TeleportToGCTown()
		ZoneTransition()
		yield("/echo Walk to GC attempt 1")
		yield("/wait 2")
		WalkToGC()
		yield("/echo Walk to GC attempt 2")
		yield("/wait 2")
		WalkToGC()
		yield("/echo Walk to GC attempt 3?")
		yield("/wait 2")
		WalkToGC()
		yield("/wait 2")
		Final_GC_Cleaning()
	end
	workshop_entered = 0
	if restock_fuel > 0 and GetItemCount(10373) > 0 and GetItemCount(10155) <= restock_fuel then
		enter_workshop()
		try_to_buy_fuel(restock_amt)
		workshop_entered = 1
	end
	if weclean == 1 then
		--only if we are parked outside of fc house
		if workshop_entered == 0 and FUTA_processors[hoo_arr_weeeeee][1][2] == 0 then
			enter_workshop()
		end
		ungabunga()
		clean_inventory() --default behaviour. it will just work if we are near a bell
	end
end
--last one out turn off the lights
--yield("/ays multi e")