local mtype = math.type or type
local tmove,unpack,tsort,tinsert,tremove = table.move, table.unpack, table.sort, table.insert, table.remove

local complex = assert(require"iota.complex.number")
local fock_ket = assert(require"iota.fock.ket")
local fock_tuple = assert(require"iota.fock.tuple")

local driver = {}

driver.version = "fock.driver from ιlibrary for ".. _VERSION .. "/ Jan 2019"

local checkket = function(ket)
	return ket and type(ket) == 'userdata' and getmetatable(ket).__name == 'fock.ket'
end

local checktuple = function(tuple)
	return tuple and type(tuple) == 'userdata' and getmetatable(tuple).__name == 'fock.tuple'
end

local createKet = function(sym,t)
	assert(type(t) == 'table')
	local ket = fock_ket.vac
	for k=1,#t do ket = ket:C(t[k],sym) end
	ket = ket:setcoef(1.0):copy()
	assert(ket:iscopy() == false)
	assert(ket:getcoef() == complex.new(1.0))
	assert(#ket == #t)
	return ket
end

driver.createFermions = function (b,n1,n2)
	local n2 = n2 or n1
	assert(type(b) == 'table')
	assert(n1 >= 1 and n2 >= 1 and n2 >= n1)
	
	-- COMBINATION OF n ELEMENTS OF TABLE t
	local function comb (n,t)
		assert(type(t) == "table" and mtype(n) == "integer", "f(integer,table) "..type(t).." "..type(n))
		local m,s = #t,{}
		assert(n<=m,"n <= #t")
		local function rc (i,next)
			for j=next,m do
				s[i] = t[j]
				if i == n then
					coroutine.yield(s)
				else
					rc(i+1,j+1)
				end
			end
		end
		return coroutine.wrap(function() rc(1,1) end)
	end
	
	-- put fermionic subset in c
	local c = {}
	for k=1,#b do c[k] = b[k] end
	assert(#c > 0, "Fermions not found!")
	tsort(c) -- ordered keys
	
	print"CREATING FERMIONS SPACE:"
	print(string.format("\tNumber of different fermions encountered: %d",#c))
	print("\tMinimum number of particles:",n1)
	print("\tMaximum number of particles:",n2)

	local tuple = fock_tuple.new()
	
	local pos = 0
	for i=n1,n2 do
		for s in comb(i,c) do
			local t = {}
			for j=1,i do t[j] = s[j] end
			tsort(t)
			local ket = createKet(fock_ket.fermion,t)
			if ket:getcoef() ~= 0 then -- eliminate vac and null
				pos = pos + 1
				tuple[ket] = pos
			else print"WARNING! KET WITH ZERO COEFFICIENT NOT INCLUDED" end
		end
	end

	return tuple
end

driver.createBosons = function (b,n1,n2)
	local n2 = n2 or n1
	assert(type(b) == 'table')
	assert(n1 > 0 and n2 > 0 and n2 >= n1 and type(b) == "table")
	
	-- COMBINATION OF maxe ELEMENTS OF TABLE tab WITH REPETITIONS
	-- http://rosettacode.org/wiki/Combinations_with_repetitions#Lua
	local function comb(n, t)
	        local function rc(tab, maxe, sidx, nchosen, current)
		        local sidx,nchosen,current = sidx or 1, nchosen or 0, current or {}
		        if nchosen == maxe then
		                coroutine.yield(current)
		                return
		        end
		        local nidx = 1
		        for i=1,#tab do
		                if nidx >= sidx then
		                        current[nchosen+1] = tab[nidx]
		                        rc(tab,maxe,nidx,nchosen+1,current)
		                end
		                nidx = nidx+1
		        end
		end
	        return coroutine.wrap(function() return rc(t,n) end)
	end
	
	local c = {} -- bosonic subset
	for i=1,#b do c[i] = b[i] end
	assert(#c > 0, "Bosons not found!")
	tsort(c) -- ordered keys
	
	print"CREATING BOSONS SPACE:"
	print("\tNumber of different bosons encountered:",#c)
	print("\tMinimum number of particles:",n1)
	print("\tMaximum number of particles:",n2)
	
	local tuple = fock_tuple.new()
	
	local pos = 0
	for i=n1,n2 do
		for s in comb(i,c) do
			local t = {}
			for j=1,i do t[j] = s[j] end
			tsort(t)
			local ket = createKet(fock_ket.boson,t)
			if ket:getcoef() ~= 0 then -- eliminate vac and null
				pos = pos + 1
				tuple[ket] = pos
			else print"WARNING! KET WITH ZERO COEFFICIENT NOT INCLUDED" end
		end
	end
	
	return tuple
end

driver.braHket = function(tuple,Hket,iHj)
	print"COMPUTING braHket..."
	assert(checktuple(tuple))
	assert(type(Hket) == 'function', 'Second argument must be a funciton of signature Hket(H,ketj), with H == H(coef,ket)')
	assert(type(iHj) == 'function', 'Third argument must be a function of signature iHj(i,j,Hij).')
	
	local clock,ts1,ts2,ts3,time = os.clock,0.0,0.0,0.0,0.0
	
	local state = {}
	
	local H = function(c,ket)
		local coef = ket:getcoef()
		if coef ~= complex.new(0.0) then
			local n = tuple[ket]
			assert(n, 'Non existent basis on tuple. Check the definition of H() as well as the fock space.')
			rawset(state, n, (rawget(state,n) or 0.0) + c*coef)
		end
	end

	local count = 0
	local countmax = #tuple
	
	for ketj,valj in pairs(tuple) do if type(ketj) == 'userdata' then
	
		count  = count+1
		if count%10000 == 0 or count == countmax then
			io.write(string.format("\r%d %3.1f %%",count,1.0*count/countmax*100))
			io.flush()
		end
		
		-- zero state
		-- state = {}
		for k,v in pairs(state) do rawset(state,k,nil) end
		-- create state of action of H() on ket, namely, the Hamiltonian |ketj>.
		time = clock()
		Hket(H,ketj:copy())
		ts3 = ts3 + (clock()-time)
		-- call iHj to do something interesting
		time = clock()
		local j = valj
		for i,Hij in pairs(state) do iHj(i,j,Hij) end
		ts1 = ts1 + (clock()-time)
	end end
	
	local printf = function(...) print(string.format(...)) end
	printf("\n	TIME TO CALL Hket: %.2f sec", ts3)
	printf("	TIME TO CALL iHj:  %.2f sec", ts1)
	printf("	MEMORY USAGE:    %.3f MB", collectgarbage("count")/1024)
	print"END"
end

driver.get_Hmatrix = function(tuple,Hket)
	local Matrix = require"iota.Matrix"
	local mat = nil
	if Matrix then mat = Matrix.newmat(#tuple,#tuple,true)
	else
		mat = setmetatable({},{__index = function(t,k) local nt={} rawset(t,k,nt) return nt end})
	end
	
	assert(checktuple(tuple))
	assert(type(Hket) == 'function', 'Third argument must be a funciton of signature Hket(H,ketj), with H == H(coef,ket)')
	
	local iHj = function(i,j,Hij) mat[i][j] = Hij end
	
	driver.braHket(tuple,Hket,iHj)
	
	return mat
end

driver.write_H = function (name,tuple,Hket)
	local file = assert(io.open(name..".mat","w"))
	local str = "# name: "..name.."\n# type: sparse complex matrix\n"
	
	assert(checktuple(tuple))
	assert(type(Hket) == 'function', 'Third argument must be a funciton of signature Hket(H,ketj), with H == H(coef,ket)')
	
	local strlen = string.len(str)
	
	file:write(str)
	file:write("# nnz: 0000000000\n")
	file:write("# rows: 0000000000\n")
	file:write("# columns: 0000000000\n")
	local row,idx = {},{}
	local function print_row(j)
		table.sort(idx)
		for _i=1,#idx do
			local i = idx[_i]
			file:write(string.format("%d %d (%.15f,%.15f)\n",i,j,complex.real(row[i]),complex.imag(row[i])))
		end
	end
	local nnz = 0
	local column = 1
	local function iHj(i,j,Hij)
		if j ~= column then
			print_row(column)
			for k,_ in pairs(row) do row[k] = nil end
			for k,_ in pairs(idx) do idx[k] = nil end
			column = j
		end
		idx[#idx+1] = i
		row[i] = Hij
		nnz = nnz + 1
	end
	
	driver.braHket(tuple,Hket,iHj)
	
	print_row(column)
	--file:write("\n")
	file:seek("set",strlen+7)
	file:write(string.format("%10d",nnz))
	file:seek("cur",9)
	file:write(string.format("%10d",#tuple))
	file:seek("cur",12)
	file:write(string.format("%10d",#tuple))
	file:close()

	os.execute("(head -n5 "..name..".mat && tail -n+6 "..name..".mat | sort -n -k2 -k1) > ordered.mat && mv ordered.mat "..name..".mat")
end

return driver
--return setmetatable({__newindex = function(t,k,v) error('Update table now allowed.') end}, driver)

