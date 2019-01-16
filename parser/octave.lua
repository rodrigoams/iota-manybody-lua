--[[
/*
* iota.parser library
* parser.octave for Lua 5.4
* Author: Rodrigo A. Moreira <rodrigoams@gmail.com>
* 11 Jan 2019
*/
From: http://octave.org/doxygen/4.0/d4/d5a/load-save_8cc_source.html
--]]

local octave = {}

local precision = 16; -- The number of decimal digits to use when writting ascii data

-- Function for reading ascii data
-- Extract a KEYWORD and its value as an string
-- Input should look like
-- [%#][ \t]*keyword[ \t]*:[ \t]*string-value[ \t]*\n

local get_keyword = function(str)
	local _,_,key,value = str:find("[%%#%s]+([%g]+)[%s]*:[%s]*([%g%s]+)[%s%c]*")
	return key, value
end

local tonumberid = function(map,id)
	local mid =  assert(map[id],"identifier '".. id .. "' not found on map.")
	return assert(tonumber(mid),"identifier '".. id .."' is not a number.")
end

local getrc = function(map)
	local columns = tonumberid(map,"columns")
	local rows = tonumberid(map,"rows")
	return rows, columns
end

local trim = function(str) return str:gsub("^%s*(.-)%s*$", "%1") end

local normalize = function(str)
	return trim(str:lower():gsub("[%s%c]+"," ")) -- substitute multiple whitespaces  by only one
end

local map_complex_number_str = function(map, str)
	local complex = require"iota.complex.number"
	for r,i in str:gmatch("%(%s*(.-)%s*,%s*(.-)%s*%)") do
		r = assert(tonumber(r))
		i = assert(tonumber(i))
		map[#map+1] = complex.new(r,i)
	end
end

octave.load_ascii = function(filename)
	print("iota.parser.octave.load_ascii")
	collectgarbage("collect")
	print("loading: ", filename)
	local mem1 = collectgarbage("count")
	local file = assert(io.open(filename,"r"),"File '"..filename.."' cannot be read.")
	local map = setmetatable({},{__index = function(t,k) if math.type(k) == 'integer' then rawset(t,k,{}) return rawget(t,k) end end})
	for lin in file:lines() do
		local line = normalize(lin)
		--print("iota.parser.octave: Reading header of "..filename)
		if line:find("#") then -- header
			local k,v  = get_keyword(line) -- get keyword and respective value
			if k and v then
				map[k] = v
				print("\t",get_keyword(line))
			end
			--print"iota.parser.octave: end"
		else
			local type = map["type"]
			if type == "matrix" then -- real matrix
				for r=1,rows do
					local v = map[r]

					for c in line:gmatch("%w+") do v[#v+1] = tonumber(c) end
					assert(#v == columns,"Wrong number of columns!")

					--print(r,"->",table.unpack(v))
					line = file:read('l')
					if not line then break end
					line = normalize(line)
				end
			elseif type == "complex matrix" then -- complex matrix
				local rows,columns = getrc(map)
				for r=1,rows do
					local v = map[r]

					map_complex_number_str(v, line)
					assert(#v == columns,"Wrong number of columns!")

					--print(r,"->",table.unpack(v))
					line = file:read('l')
					if not line then break end
					line = normalize(line)
				end
			else error("Type '"..type.."' not programmed.") end	
		end
	end
	file:close()
	collectgarbage("collect")
	print("memory used to store data: ", (collectgarbage("count") - mem1)/1024, "MiB")
	print("end")
	return map
--[[
The data is expected to be in the following format:
The input file must have a header followed by some data.
All lines in the header must begin with a '#' character.
The header must contain a list of keyword and value pairs with the keyword and value separated by a colon.
Keywords must appear in the following order:
# name: <name>
# type: <type>
# <info>

 Where, for the built in types are:
 <name> : a valid identifier
 <type> : <typename>
					| global <typename>
 <typename> : scalar
					| complex scalar
					| matrix
					| complex matrix
					| bool
					| bool matrix
					| string
					| range
<info> : <matrix info>
					| <string info>
 <matrix info> : # rows: <integer>
						: # columns: <integer>
<string info> : # elements: <integer>
  192 //                : # length: <integer> (once before each string)
  193 //
  194 //  For backward compatibility the type "string array" is treated as a
  195 // "string" type. Also "string" can have a single element with no elements
  196 // line such that
  197 //
  198 //  <string info> : # length: <integer>
  199 //
  200 // Formatted ASCII data follows the header.
  201 //
  202 // Example:
  203 //
  204 //  # name: foo
  205 //  # type: matrix
  206 //  # rows: 2
  207 //  # columns: 2
  208 //    2  4
  209 //    1  3
  210 //
  211 // Example:
  212 //
  213 //  # name: foo
  214 //  # type: string
  215 //  # elements: 5
  216 //  # length: 4
  217 //  this
  218 //  # length: 2
  219 //  is
  220 //  # length: 1
  221 //  a
  222 //  # length: 6
  223 //  string
  224 //  # length: 5
  225 //  array
  226 //
  227
  --]]
end

return octave
