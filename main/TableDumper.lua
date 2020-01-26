-- Defold require module, local m = require "my_directory.my_file"
local M = {}

function M.dumpTable(tbl, indent)
	if(type(tbl) == "table") then
		local count = 0
		if indent == nil then
			print("")
			indent = 2
		end
		local indentStr = string.rep("+", indent)
		for k, v in pairs(tbl) do
			print(indentStr .. " table: key = " .. tostring(k) .. "   value = " .. tostring(v))
			if(type(v) == "table") then
				M.dumpTable(v, indent + 2)
			end
			count = count + 1
		end
		print(indentStr .. " > Table length = " .. tostring(count))
		if indent == 2 then print("") end
	else
		print("~~> type (" .. type(tbl) .. ") argument passed, dumpTable expects a lua table")
	end
end

return M
