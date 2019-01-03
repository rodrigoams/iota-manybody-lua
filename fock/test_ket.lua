#! /usr/local/bin/lua
-- test fock.ket library

------------------------------------------------------------------------------
collectgarbage("generational")
local complex = assert(require"iota.complex.number")
local fock = assert(require"iota.fock.ket")

print(fock.version)

local fock_tuple = assert(require"iota.fock.tuple")

local ftuple = fock_tuple.new()

for k,v in pairs(fock) do print(k,v) end

local addtime1 = 0
local addParticles = function(ket, coef, sym, t1, ...)
	local coef = complex.new(coef)
	local t = false
	if type(t1) == 'table' then t = t1
	else t = {t1,...} end
	local ket = ket
	local t1 = os.clock()
	for k=1,#t do ket = ket:C(t[k],sym) end
	addtime1 = addtime1 + os.clock() - t1
	ket = ket:setcoef(coef):copy()
	assert(ket:iscopy() == false)
	assert(ket:getcoef() == coef, tostring(coef).." "..tostring(ket:getcoef()) )
	assert(#ket == #t)
	return ket
end
local addFermions = function(ket, coef, ...)
	return addParticles(ket, coef, fock.fermion, ...)
end
local addBosons = function(ket, coef, ...)
	return addParticles(ket, coef, fock.boson, ...)
end

local function check(c1,t,ket)
	local c1 = complex.new(c1)
	local c2 = ket:getcoef()
	local ketb = {ket:getbasis()}
	if c1 ~= c2 then
		print("\nWrong coeficients",c1, c2)
		print(table.unpack(t))
		print(table.unpack(ketb))
		assert(c1 == c2)
	end
	local check_table = function(t1,t2)
			if #t1 ~= #t2 then print("Work length: ",#t1,#t2) return false end
			for k=1,#t1 do
				if t1[k] ~= t2[k] then return false end
			end
			return true
	end
	if not check_table(ketb,t) then
		print("\nWrong Creation")
		print(c1,table.unpack(t))
		print(c2,table.unpack(ketb))
		error(1)
	end
	print("OK",c1,table.unpack(t))
end

io.write"Testing Fermions...\n" io.flush()
local ket = addFermions(fock.vac, 1.0, 1,2,3,4,6,7,8)
check( 1.0, {1,2,3,4,6,7,8}, ket)
local k = ket:Cb(11)
check(1.0, {1,2,3,4,6,7,8,11}, k)
k = k:Af(4) check(-1.0, {1,2,3,6,7,8,11}, k)
k = k:Cf(5) check(1.0, {1,2,3,5,6,7,8,11}, k)
k = ket:Cf(4) check( 0.0, {}, k)
k = ket:Af(5) check( 0.0, {}, k)
k = ket:Cf(1):Af(1) check( 0.0, {}, k)
k = ket:Af(1):Cf(1) check( 1.0, {1,2,3,4,6,7,8}, k)
k = ket:Nf(3) check( 1.0, {1,2,3,4,6,7,8}, k)
k = ket:Af(3):Nf(3) check( 0.0, {1,2,4,6,7,8}, k)
k = ket:Af(3):Cf(3):Nf(3) check( 1.0, {1,2,3,4,6,7,8}, k)
print"Fermions OK!"

io.write"Testing Bosons...\n" io.flush()
local ket = addBosons(fock.vac, 1.0, 1,2,3,4,5,11,11,12,14)
check( 1.0, {1,2,3,4,5,11,11,12,14}, ket)
local k = ket:Cb(11)
check( 3.0, {1,2,3,4,5,11,11,11,12,14}, k)
k = k:Ab(11) check( 3.0, {1,2,3,4,5,11,11,12,14}, k)
k = ket:Ab(11) check(1.0, {1,2,3,4,5,11,12,14}, k)
k = k:Cb(11) check(2.0, {1,2,3,4,5,11,11,12,14}, k)
k = k:Cb(9) check(2.0, {1,2,3,4,5,9,11,11,12,14}, k)
k = k:Cb(14) check(2*2, {1,2,3,4,5,9,11,11,12,14,14}, k)
k = ket:Nb(11) check(2, {1,2,3,4,5,11,11,12,14}, k)
k = ket:Nb(12) check(1, {1,2,3,4,5,11,11,12,14}, k)
k = ket:Cb(11):Nb(11) check(3*3, {1,2,3,4,5,11,11,11,12,14}, k)
k = ket:Cb(11):Nb(12) check(3, {1,2,3,4,5,11,11,11,12,14}, k)
k = ket:Ab(12):Nb(12) check(0, {1,2,3,4,5,11,11,14}, k)
print"Bosons OK!"


local tspace = setmetatable({__index=function(t,k) return {} end},{})
local tspace_count = 0
local tspace_index = function(ket)
	local tspace = tspace
	local function rep(tspace,k,...)
		return rep(tspace[k],k,...)
	end
	local ret = rep(ket:basis())
end

io.write"Testing Memory...\n" io.flush()
local tuple = {}
local count = 0
local maxmem = 0
local time1,time2,time3 = 0,0,0
local random = math.random
for n=1,1.0E3 do
	local r = {}
	for k=1,random(1000) do rawset(r,k,random(1,255)) end
	local t2 = os.clock()
	local ket = false
	--if math.random() > 0.5 then
		ket = addBosons(fock.vac, 1.0, r)
	--else ket = addFermions(fock.vac, 1.0, r) end
	time2 = time2 + os.clock() - t2
	local t3 = os.clock()
	--local coef,str = ket:get()
	time3 = time3 + os.clock() - t3
	--print(#ket,coef,str,type(str),ket:basis())
	local t1 = os.clock()
	--[[
	if not rawget(tuple,str) then
		count = count + 1
		rawset(tuple,str,count)
		assert(rawget(tuple,str) == count)

	end
	--]]
	--[
	if not ftuple[ket] then
		count = count + 1
		ftuple[ket] = count
		assert(ftuple[ket] == count)
	end
	--]]
	time1 = time1 + os.clock() - t1
	for k=1,#r do r[k] = nil end
	local mem = collectgarbage("count")/1024
	if mem > maxmem then maxmem = mem end
	if n%100 == 0 then print(n,count,"memory:",mem,"MB") print("times",time1,time2,time3,addtime1) end
end
print("MAXMEM",maxmem,"MB")
print"Memory OK!"



