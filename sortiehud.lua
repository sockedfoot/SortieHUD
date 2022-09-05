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


displaySettings = {pos={x=100,y=400},text={font='Consolas',size=11},bg={alpha=255}}
displayBox = texts.new(displaySettings)
displayBox:show()

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
	['gained_muffins'] = 0
}

box_ids = {
	[20996097] = {type="Chest",name="A1",color="cs(100,100,100)"},
	[20996098] = {type="Chest",name="B1",color="cs(100,100,100)"},
	[20996099] = {type="Chest",name="C1",color="cs(100,100,100)"},
	[20996100] = {type="Chest",name="D1",color="cs(100,100,100)"},
	[20996101] = {type="Chest",name="A2",color="cs(100,100,100)"},
	[20996102] = {type="Chest",name="B2",color="cs(100,100,100)"},
	[20996103] = {type="Chest",name="C2",color="cs(100,100,100)"},
	[20996104] = {type="Chest",name="D2",color="cs(100,100,100)"},
	[20996105] = {type="Chest",name="A3",color="cs(100,100,100)"},
	[20996106] = {type="Chest",name="B3",color="cs(100,100,100)"},
	[20996107] = {type="Chest",name="C3",color="cs(100,100,100)"},
	[20996108] = {type="Chest",name="D3",color="cs(100,100,100)"},
	[20996109] = {type="Chest",name="A4",color="cs(100,100,100)"},
	[20996110] = {type="Chest",name="B4",color="cs(100,100,100)"},
	[20996111] = {type="Chest",name="C4",color="cs(100,100,100)"},
	[20996112] = {type="Chest",name="D4",color="cs(100,100,100)"},
	[20996113] = {type="Casket",name="A1",color="cs(100,100,100)"},
	[20996114] = {type="Casket",name="A2",color="cs(100,100,100)"},
	[20996115] = {type="Coffer",name="A",color="cs(100,100,100)"},
	[20996116] = {type="Casket",name="B1",color="cs(100,100,100)"},
	[20996117] = {type="Casket",name="B2",color="cs(100,100,100)"},
	[20996118] = {type="Coffer",name="B",color="cs(100,100,100)"},
	[20996119] = {type="Casket",name="C1",color="cs(100,100,100)"},
	[20996120] = {type="Casket",name="C2",color="cs(100,100,100)"},
	[20996121] = {type="Coffer",name="C",color="cs(100,100,100)"},
	[20996122] = {type="Casket",name="D1",color="cs(100,100,100)"},
	[20996123] = {type="Casket",name="D2",color="cs(100,100,100)"},
	[20996124] = {type="Coffer",name="D",color="cs(100,100,100)"},
	[20996125] = {type="Coffer",name="Aurum",color="cs(100,100,100)"},

	["ChestA1"] = {id=20996097},
	["ChestB1"] = {id=20996098},
	["ChestC1"] = {id=20996099},
	["ChestD1"] = {id=20996100}, 
	["ChestA2"] = {id=20996101}, 
	["ChestB2"] = {id=20996102}, 
	["ChestC2"] = {id=20996103}, 
	["ChestD2"] = {id=20996104}, 
	["ChestA3"] = {id=20996105}, 
	["ChestB3"] = {id=20996106}, 
	["ChestC3"] = {id=20996107}, 
	["ChestD3"] = {id=20996108}, 
	["ChestA4"] = {id=20996109}, 
	["ChestB4"] = {id=20996110}, 
	["ChestC4"] = {id=20996111}, 
	["ChestD4"] = {id=20996112}, 
	["CasketA1"] = {id=20996113}, 
	["CasketA2"] = {id=20996114}, 
	["CofferA"] = {id=20996115}, 
	["CasketB1"] = {id=20996116}, 
	["CasketB2"] = {id=20996117}, 
	["CofferB"] = {id=20996118}, 
	["CasketC1"] = {id=20996119}, 
	["CasketC2"] = {id=20996120}, 
	["CofferC"] = {id=20996121}, 
	["CasketD1"] = {id=20996122}, 
	["CasketD2"] = {id=20996123}, 
	["CofferD"] = {id=20996124}, 
	["Aurum"] = {id=20996125}, 
}



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
    info.header = "    \\"..colors.Chest.."Chest\\      \\"..colors.Casket.."Casket\\   \\"..colors.Coffer.."Coffer "
         info.A = " \\"..box_ids[box_ids.ChestA1.id].color.."A1\\ \\"..box_ids[box_ids.ChestA2.id].color.."A2 \\"..box_ids[box_ids.ChestA3.id].color.."A3 \\"..box_ids[box_ids.ChestA4.id].color.."A4    \\"..box_ids[box_ids.CasketA1.id].color.."A1 \\"..box_ids[box_ids.CasketA2.id].color.."A2      \\"..box_ids[box_ids.CofferA.id].color.."A"
         info.B = " \\"..box_ids[box_ids.ChestB1.id].color.."B1\\ \\"..box_ids[box_ids.ChestB2.id].color.."B2 \\"..box_ids[box_ids.ChestB3.id].color.."B3 \\"..box_ids[box_ids.ChestB4.id].color.."B4    \\"..box_ids[box_ids.CasketB1.id].color.."B1 \\"..box_ids[box_ids.CasketB2.id].color.."B2      \\"..box_ids[box_ids.CofferB.id].color.."B"
         info.C = " \\"..box_ids[box_ids.ChestC1.id].color.."C1\\ \\"..box_ids[box_ids.ChestC2.id].color.."C2 \\"..box_ids[box_ids.ChestC3.id].color.."C3 \\"..box_ids[box_ids.ChestC4.id].color.."C4    \\"..box_ids[box_ids.CasketC1.id].color.."C1 \\"..box_ids[box_ids.CasketC2.id].color.."C2      \\"..box_ids[box_ids.CofferC.id].color.."C"
         info.D = " \\"..box_ids[box_ids.ChestD1.id].color.."D1\\ \\"..box_ids[box_ids.ChestD2.id].color.."D2 \\"..box_ids[box_ids.ChestD3.id].color.."D3 \\"..box_ids[box_ids.ChestD4.id].color.."D4    \\"..box_ids[box_ids.CasketD1.id].color.."D1 \\"..box_ids[box_ids.CasketD2.id].color.."D2      \\"..box_ids[box_ids.CofferD.id].color.."D"
         
    info.muffins = " \\cs(255,255,255) Muffins["..(count.muffins+count.gained_muffins).." (\\cs(0,255,0)+"..count.gained_muffins.."\\cs(255,255,255)\\)] Case[\\cs(0,255,0)"..count.nq_case.."\\cs(255,255,255)]"
    info.totals = "    \\cs(255,255,255)Sapphires[\\cs(0,255,0)"..count.sapphires.."\\cs(255,255,255)] Case+1[\\cs(0,255,0)"..count.hq_case.."\\cs(255,255,255)] "
    displayBox:update(info)
    displayBox:show()
end

makeDisplay()
updateDisplay()

windower.register_event('incoming chunk',function(id,original,modified,injected,blocked)
	if id == 0x5B and not zoning then
		local packet = packets.parse('incoming', original)
		
		if box_ids[packet['ID']] then
			box_ids[packet['ID']].color = colors[box_ids[packet['ID']].type]
			updateDisplay()
		end
	elseif id == 0x118 and not zoning then
        if count.muffins == 0 then 
        	count.muffins = original:byte(145)+256*original:byte(146)+(256*256*original:byte(147))
        	updateDisplay()
        end
    elseif id == 0x0D2 and not zoning then
    	local packet = packets.parse('incoming', original)

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
	if string.find(original,"received %d+ gallimaufry for a total of") then
		gained = tonumber(original:match("%d+"))
		count.gained_muffins = count.gained_muffins + gained
		updateDisplay()
	end
end)



windower.register_event('add item', function(bag, index, id, count) -- if packet doesn't work for items
	if res.items[id].en == "Old Case" then
		-- count.nq_case = count.nq_case + 1
		-- updateDisplay()
		windower.add_to_chat(200,'Found Old Case!')
	elseif res.items[id].en == "Old Case +1" then
		-- count.hq_case = count.hq_case + 1
		-- updateDisplay()
		windower.add_to_chat(200,'Found Old Case +1!')
	elseif res.items[id].en == "Ra'Kaz. Sapphire" then
		-- count.sapphires = count.sapphires + 1
		-- updateDisplay()
		windower.add_to_chat(200,'Found Sapphire!')
	end
end)

packets.inject(packets.new('outgoing', 0x115))
