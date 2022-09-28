--[[
	Copyright (C) 2022, CD
	
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

_addon.version = '1.0.0'
_addon.name = 'SortieHUD'
_addon.author = 'Sock'
_addon.commands = {'sh', 'sortiehud'}

texts = require('texts')
packets = require('packets')
require 'lists'
res = require('resources')
--inspect = require('inspect')
local gettime = require('socket').gettime


displaySettings = {pos={x=150,y=600},text={font='Consolas',size=11},bg={alpha=255}}
displayBox = texts.new(displaySettings)
displayBox:show()

sample_oldcase = 1164
sample_oldcase1 = 35
nq_earring = 1111
hq1_earring = 88
hq2_earring = 0



colors = {
	['Chest'] = 'cs(155,94,81)',
	['Casket'] = 'cs(58,108,222)',
	['Coffer'] = 'cs(209,51,27)'
}

count = {
	['sapphires'] = 0,
	['nq_case'] = 0,
	['hq_case'] = 0,
	['muffins'] = 0,
	['gained_muffins'] = 0,
	['A_obj'] = 0,
	['B_obj'] = 0,
	['C_obj'] = 0,
	['D_obj'] = 0,
}

recently_found = nil
last_dropped = 0 -- will be set to gettime() on drop

box_ids = {
	[21000193] = {type="Chest",name="A1",color="cs(100,100,100)",obj="Open any unlocked Gate #A"},
	[21000194] = {type="Chest",name="B1",color="cs(100,100,100)",obj="Gates B1-B6 in order"},
	[21000195] = {type="Chest",name="C1",color="cs(100,100,100)",obj="Open any locked Gate #B then #C1 without killing anything in C"},
	[21000196] = {type="Chest",name="D1",color="cs(100,100,100)",obj="Open #D2 and #D2 within 2 minutes of each other"},
	[21000197] = {type="Chest",name="A2",color="cs(100,100,100)",obj="Cast Enhancing/Trust magic next to Diaphanous A"},
	[21000198] = {type="Chest",name="B2",color="cs(100,100,100)",obj="/hurray next to Diaphanous B"},
	[21000199] = {type="Chest",name="C2",color="cs(100,100,100)",obj="Kill Cachaemic foe next to Diaphanous C"},
	[21000200] = {type="Chest",name="D2",color="cs(100,100,100)",obj="Drop Obsid. wing next to Diaphanous D"},
	[21000201] = {type="Chest",name="A3",color="cs(100,100,100)",obj="?? 3 Abject foes without using WS, casting at least one spell (Dia)"},
	[21000202] = {type="Chest",name="B3",color="cs(100,100,100)",obj="Defeat 5 Biune foes"},
	[21000203] = {type="Chest",name="C3",color="cs(100,100,100)",obj="MB without killing 3 Cachaemic foes"},
	[21000204] = {type="Chest",name="D3",color="cs(100,100,100)",obj="Non-killing 4-step SC on 3 Demisang foes"},
	[21000205] = {type="Chest",name="A4",color="cs(100,100,100)",obj="?? 3 more Abject foes without WS, casting at least one spell (Dia)"},
	[21000206] = {type="Chest",name="B4",color="cs(100,100,100)",obj="Defeat 5 more Biune foes"},
	[21000207] = {type="Chest",name="C4",color="cs(100,100,100)",obj="MB without killing 3 more Cachaemic foes"},
	[21000208] = {type="Chest",name="D4",color="cs(100,100,100)",obj="Non-killing 4-step SC on 3 more Demisang foes"},
	[21000209] = {type="Casket",name="A1",color="cs(100,100,100)",obj="Kill 5 Abject foes"},
	[21000210] = {type="Casket",name="A2",color="cs(100,100,100)",obj="/heal after Gate #A1"},
	[21000211] = {type="Coffer",name="A",color="cs(100,100,100)",obj="Kill Abject Obdella"},
	[21000212] = {type="Casket",name="B1",color="cs(100,100,100)",obj="Defeat 3 Biunes foes within 30 seconds of pulling"},
	[21000213] = {type="Casket",name="B2",color="cs(100,100,100)",obj="Open any unlocked Gate #B"},
	[21000214] = {type="Coffer",name="B",color="cs(100,100,100)",obj="Defeat Biune Porxie after opening Casket B1"},
	[21000215] = {type="Casket",name="C1",color="cs(100,100,100)",obj="Kill 3 monsters within 30 seconds from pull to death"},
	[21000216] = {type="Casket",name="C2",color="cs(100,100,100)",obj="Defeat every foe in C"},
	[21000217] = {type="Coffer",name="C",color="cs(100,100,100)",obj="Kill Cachaemic Bhoot within 2.5 minutes of entering C"},
	[21000218] = {type="Casket",name="D1",color="cs(100,100,100)",obj="Vanquish 6 Demisang Foes of different jobs"},
	[21000219] = {type="Casket",name="D2",color="cs(100,100,100)",obj="Kill WAR > MNK > WHM > BLM > RDM > THF in order"},
	[21000220] = {type="Coffer",name="D",color="cs(100,100,100)",obj="Kill Demisang Deleterious and then any 3 Demisang foes"},
	[21000221] = {type="Coffer",name="Aurum",color="cs(100,100,100)",obj="Kill all mini-NMs"},
}

rbox_ids = {} -- reverse lookup => { 'ChestA1' = {id=key}, ... }

for key, val in pairs(box_ids) do
	if val.type then
		local k = val.type..val.name
		rbox_ids[k] = { id = tonumber(key) }
	end
end

function makeDisplay()
	local properties = L{}
    properties:append('${header}')
    properties:append('${A}')
    properties:append('${B}')
    properties:append('${C}')
    properties:append('${D}')
    properties:append('${muffins}')
    properties:append('${totals}')
    

    displayBox:clear()
    displayBox:append(properties:concat('\n'))
end

function updateDisplay()
    local info = {}
    info.header = "    \\"..colors.Chest.."Chest\\     \\"..colors.Casket.."Casket\\  \\"..colors.Coffer.."Coff "
         info.A = " \\"..box_ids[rbox_ids.ChestA1.id].color.."A1\\ \\"..box_ids[rbox_ids.ChestA2.id].color.."A2 \\"..box_ids[rbox_ids.ChestA3.id].color.."A3 \\"..box_ids[rbox_ids.ChestA4.id].color.."A4   \\"..box_ids[rbox_ids.CasketA1.id].color.."A1 \\"..box_ids[rbox_ids.CasketA2.id].color.."A2    \\"..box_ids[rbox_ids.CofferA.id].color.."A   \\cs(255,255,255)"..count.A_obj.."/7 "
         info.B = " \\"..box_ids[rbox_ids.ChestB1.id].color.."B1\\ \\"..box_ids[rbox_ids.ChestB2.id].color.."B2 \\"..box_ids[rbox_ids.ChestB3.id].color.."B3 \\"..box_ids[rbox_ids.ChestB4.id].color.."B4   \\"..box_ids[rbox_ids.CasketB1.id].color.."B1 \\"..box_ids[rbox_ids.CasketB2.id].color.."B2    \\"..box_ids[rbox_ids.CofferB.id].color.."B   \\cs(255,255,255)"..count.B_obj.."/7 "
         info.C = " \\"..box_ids[rbox_ids.ChestC1.id].color.."C1\\ \\"..box_ids[rbox_ids.ChestC2.id].color.."C2 \\"..box_ids[rbox_ids.ChestC3.id].color.."C3 \\"..box_ids[rbox_ids.ChestC4.id].color.."C4   \\"..box_ids[rbox_ids.CasketC1.id].color.."C1 \\"..box_ids[rbox_ids.CasketC2.id].color.."C2    \\"..box_ids[rbox_ids.CofferC.id].color.."C   \\cs(255,255,255)"..count.C_obj.."/7 "
         info.D = " \\"..box_ids[rbox_ids.ChestD1.id].color.."D1\\ \\"..box_ids[rbox_ids.ChestD2.id].color.."D2 \\"..box_ids[rbox_ids.ChestD3.id].color.."D3 \\"..box_ids[rbox_ids.ChestD4.id].color.."D4   \\"..box_ids[rbox_ids.CasketD1.id].color.."D1 \\"..box_ids[rbox_ids.CasketD2.id].color.."D2    \\"..box_ids[rbox_ids.CofferD.id].color.."D   \\cs(255,255,255)"..count.D_obj.."/7 "
         
    info.muffins = " \\cs(255,255,255) Muffins["..(count.muffins+count.gained_muffins).." (\\cs(0,255,0)+"..count.gained_muffins.."\\cs(255,255,255)\\)] Case[\\cs(0,255,0)"..count.nq_case.."\\cs(255,255,255)] "
    info.totals = "    \\cs(255,255,255)Sapphires[\\cs(0,255,0)"..count.sapphires.."\\cs(255,255,255)] Case+1[\\cs(0,255,0)"..count.hq_case.."\\cs(255,255,255)] "
    displayBox:update(info)
    displayBox:show()
end

makeDisplay()
updateDisplay()

zoning = false
windower.register_event('incoming chunk',function(id,original,modified,injected,blocked)
	local packet = packets.parse('incoming', original)

	if last_dropped > 0 and (gettime() - last_dropped) > 3 then -- 3 seconds have elapsed since drops
		windower.add_to_chat(200,recently_found.. ' #obj completed')
		recently_found = nil
		last_dropped = 0
	end

	if id == 0x05B and not zoning then
		if box_ids[packet['ID']] then
			box_ids[packet['ID']].color = colors[box_ids[packet['ID']].type]

			if recently_found then
				recently_found = recently_found..', '..box_ids[packet['ID']].type..box_ids[packet['ID']].name
			else
				recently_found = box_ids[packet['ID']].type..box_ids[packet['ID']].name
			end

			last_dropped = gettime()
			updateDisplay()
		end
	elseif id == 0x118 and not zoning then
        --if count.muffins == 0 then 
        	count.muffins = original:byte(145)+256*original:byte(146)+(256*256*original:byte(147))
        	updateDisplay()
        --end
    elseif id == 0x028 and not zoning then
    	if packet['Category'] == 5 and res.items[packet['Target 1 Action 1 Param']] then -- earring
    		if res.items[packet['Target 1 Action 1 Param']].en:contains('??? Ear') and res.items[packet['Target 1 Action 1 Param']].en:contains("+1") then
    			hq1_earring = hq1_earring + 1
				--windower.add_to_chat(123,": +1 earring count is: "..hq1_earring)
    		elseif res.items[packet['Target 1 Action 1 Param']].en:contains('??? Ear') and res.items[packet['Target 1 Action 1 Param']].en:contains("+2") then
    			hq2_earring = hq2_earring + 1
				--windower.add_to_chat(123,": +2 earring count is: "..hq2_earring)
    		elseif res.items[packet['Target 1 Action 1 Param']].en:contains('??? Ear') and res.items[packet['Target 1 Action 1 Param']].en:contains("Earring") then
    			nq_earring = nq_earring + 1
				--windower.add_to_chat(123,": nq earring count is: "..nq_earring)
			end

			if packet['Param'] == 6614 then
				sample_oldcase = sample_oldcase + 1
				--windower.add_to_chat(123,"Old case count is: "..sample_oldcase)
			elseif packet['Param'] == 6615 then
				sample_oldcase1 = sample_oldcase1 + 1
				--windower.add_to_chat(123,"Old Case +1 count is: "..sample_oldcase1)
			end
    	end
    elseif packet['Item'] then    
	  	 if id == 0x01F and not zoning then
	     	if packet['Item'] > 0 and packet['Status'] == 0 and packet['Bag'] == 0 then
	     		if packet['Item'] == 6614 or packet['Item'] == 6615 or packet['Item'] == 9927 then
	     			windower.add_to_chat(200,"# ITEM FOUND: "..packet['Item'])
	     		end

	     		if res.items[packet['Item']].en == "Old Case" then
		    		count.nq_case = count.nq_case + 1
		    		updateDisplay()
		    	elseif res.items[packet['Item']].en == "Old Case +1" then
		    		count.hq_case = count.hq_case + 1
		    		updateDisplay()
		    	elseif res.items[packet['Item']].en == "Ra'Kaz. Sapphire" then
		    		count.sapphires = count.sapphires + 1
		    		updateDisplay()
				end
	     	end
		end
	end

	if id == 0xB then
		zoning = true
	elseif id == 0xA and zoning then
		coroutine.schedule(zoningFinished, 3) -- delay a bit so init does not see pre-zone party lists
	end
end)


function zoningFinished()
	zoning = false
end

windower.register_event('incoming text', function(original, modified, mode)
	--[[if mode ~= 50 and mode ~= 123 and mode ~= 200 then 
		windower.add_to_chat(50,mode.." (mod): "..modified)
		windower.add_to_chat(50,mode.." (orig): "..original) 

	end--]]
	if string.find(original,"received %d+ gallimaufry for a total of") then
		gained = tonumber(original:match("%d+"))
		count.gained_muffins = count.gained_muffins + gained
		updateDisplay()
	elseif string.find(original,"#%u treasure coffer status report: 7/7") then
		windower.add_to_chat(200,'#############     '..original:match("%u")..' wing is cleared!     ############')
		box_ids[rbox_ids["Chest"..original:match("%u").."1"].id].color = colors.Chest
		box_ids[rbox_ids["Chest"..original:match("%u").."2"].id].color = colors.Chest
		box_ids[rbox_ids["Chest"..original:match("%u").."3"].id].color = colors.Chest
		box_ids[rbox_ids["Chest"..original:match("%u").."4"].id].color = colors.Chest
		box_ids[rbox_ids["Casket"..original:match("%u").."1"].id].color = colors.Casket
		box_ids[rbox_ids["Casket"..original:match("%u").."2"].id].color = colors.Casket
		box_ids[rbox_ids["Coffer"..original:match("%u")].id].color = colors.Coffer
	elseif string.find(string.gsub(original,"'",""),"obtain the temporary item: %a+ #%u") then -- coffer was opened
		windower.add_to_chat(200,"Found temporary item! #############################")
		if string.find(original,"shard") then -- Chest 3
			box_ids[rbox_ids["Chest"..original:match("%u").."3"].id].color = colors.Chest
		elseif string.find(original,"metal") then -- Chest 4
			box_ids[rbox_ids["Chest"..original:match("%u").."4"].id].color = colors.Chest
		elseif string.find(original,"key") then -- Chest 1
			box_ids[rbox_ids["Chest"..original:match("%u").."1"].id].color = colors.Chest
		elseif string.find(original,"plate") then -- Chest 2
			box_ids[rbox_ids["Chest"..original:match("%u").."2"].id].color = colors.Chest
		end
	end

	if string.find(original,"#?: 1/1") then --all four coffers dropped (Aurum)
		box_ids[rbox_ids.CofferA.id].color = colors.Coffer
		box_ids[rbox_ids.CofferB.id].color = colors.Coffer
		box_ids[rbox_ids.CofferC.id].color = colors.Coffer
		box_ids[rbox_ids.CofferD.id].color = colors.Coffer
	end

	if string.find(original,"%u treasure coffer status report: %d/7") then
		count[original:match("%u")..'_obj'] = tonumber(original:match("%d"))
		updateDisplay()
	end

	if string.find(original,"#obj completed") and mode ~= 200 then
		local objs = original:match(" .* #"):gsub("#",""):gsub(",",""):gsub('^%s*(.-)%s*$', '%1')

		for sub in objs:gmatch("%w+") do
			local type = sub:lower():find("chest") and "Chest" or sub:lower():find("casket") and "Casket" or "Coffer"
			
			box_ids[rbox_ids[sub].id].color = colors[type]
			updateDisplay()
		end
	end
end)

windower.register_event('addon command',function(...)
    local args = T{...}
    local command
    if args[1] then command = string.lower(args[1]) end

	if command == 'report' then
		windower.add_to_chat(200,"Counts")
		windower.add_to_chat(200,"Old Case: "..sample_oldcase)
		windower.add_to_chat(200,"Old Case +1: "..sample_oldcase1)
		windower.add_to_chat(200,"NQ Earring: "..nq_earring..' ('..nq_earring/sample_oldcase..')')
		windower.add_to_chat(200,"+1 Earring: "..hq1_earring..' ('..(hq1_earring-sample_oldcase1)/sample_oldcase..')')
		windower.add_to_chat(200,"+2 Earring: "..hq2_earring)
	elseif command == 'reload' then
		windower.send_command('lua r sortiehud')
	end
end)

packets.inject(packets.new('outgoing', 0x115))
