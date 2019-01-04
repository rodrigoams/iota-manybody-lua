local mtype = math.type or type
local tmove,unpack,tsort,tinsert,tremove = table.move, table.unpack, table.sort, table.insert, table.remove

local complex = assert(require"iota.complex.number")
local fock_ket = assert(require"iota.fock.ket")
local fock_tuple = assert(require"iota.fock.tuple")

local ket2str = fock_ket.ket2str
local str2ket = fock_ket.str2ket
local checkket = fock_ket.check

local checkargtuple = function(arg,tuple) if not fock_tuple.check(tuple) then error(string.format("wrong tuple at argument %d",arg)) end end

local checkcomplex = complex.check
local checkcoef = function(n) return (type(n) == 'number') or checkcomplex(n) end

local space,spacemt = {},{}

space.version = "fock.space from ιlibrary for ".. _VERSION .. "/ Jan 2019"

local DEBUG = true

printd = function(...) if DEBUG then print(...) end end

space.check = function (space) return type(space) == 'table'  and getmetatable(space).__name == spacemt end

local execmethod = function(data,method)
	local data = data
	local method = method
	local temp = {} -- temporary data
	return function(state,...)
		printd"begin method"
		for str,coef in pairs(data) do
			local ket = str2ket(str)
			assert(checkket(ket))
			local m = ket[method]
			if not m then error("Invalid method") end
			local newket = m(ket,...)
			local newcoef = newket:getcoef()
			local newstr = ket2str(newket)
			temp[newstr] = (temp[newstr] or 0.0) + coef*newcoef
			printd("\t",ket,method,m,...,newket)
		end
		printd"end method"
		for k,v in pairs(data) do data[k] = nil end -- clean old state
		local count = 0
		for k,v in pairs(temp) do -- copy new state and clean buffer
			assert(checkcomplex(v),"value is not a complex number")	
			if v ~= complex.zero then
				printd("result",str2ket(k):setcoef(v))
				data[k] = v
				count = count + 1
				temp[k] = nil
			end
		end
		getmetatable(state).setlen(count)
		return state
	end
end

space.new = function (tuple)
	checkargtuple(1, tuple)
	local data = {} -- array of ket2str with coefficients, default 0.0
	local tuple = tuple
	local len = 0
	return setmetatable({ -- state
			tuple = tuple,
			iter = function(t)
			local str,coef = nil,nil
			local iter = function()
				str,coef = next(data,str)
				if str then
					local ket = str2ket(str)
					assert(checkket(ket))
					return ket,coef
				else return nil,nil end
			end
			return iter,t,nil
		end
	},{
		data = data,
		setlen = function(s) assert(type(s) == 'number' or checkcomplex(s)) len=s end,
		__name = spacemt,
		__index = function(t,k)
			if checkket(k) then return data[ket2str(k)] or 0.0 end
			if type(k) == 'string' then return execmethod(data,k) end
			return nil
		end,
		__newindex = function(t,k,v)
			assert(checkcoef(v), "'value' is not a (complex) number.")
			if checkket(k) then
				local str = ket2str(k)
				if data[str] then print("WARNING: rewriting data["..tostring(k).."] = "..tostring(v).." from tuple!!")
				else len = len+1 end
				data[str] = v
			else print("Invalid key, you must use a 'fock.ket' ") end
		end,
		__len = function(t) return len end
	})
end

space.copy = function(state)
	assert(space.check(state),"wrong 'fock.space' at argument 1")
	local tuple = state.tuple
	checkargtuple(0,tuple)
	local newstate = space.new(state.tuple)
	local data = getmetatable(state).data
	local newdata = getmetatable(newstate).data
	for k,v in pairs(data) do newdata[k] = data[k] end
	getmetatable(newstate).setlen(#state)
	return newstate
end

return space
