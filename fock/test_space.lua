collectgarbage("generational")
local fock_space = assert(require"iota.fock.space")
local complex = assert(require"iota.complex.number")
local fock_ket = assert(require"iota.fock.ket")
local fock_tuple = assert(require"iota.fock.tuple")

local vac = fock_ket.vac

local ket1 = vac:Cf(1):Cf(2):copy()
local ket2 = vac:Cf(1):Cf(4):setcoef(complex.new(1.0,2.0)):copy()
local ket3 = vac:Cf(1):Cf(4):Cf(2):setcoef(complex.new(1.0,2.0)):copy()

local tuple = fock_tuple.new()

tuple[ket1] = 1
tuple[ket2] = 2
tuple[ket3] = 3

print("ket",tuple[ket1], ket1)
print("ket",tuple[ket2], ket2)
print("ket",tuple[ket3], ket3)

local state = fock_space.new(tuple)
for k,v in pairs(state) do print(k,v) end

print(state[ket1],state[ket2],state[ket3])

local rnd1 = math.random()
local rnd2 = math.random()
local rnd3 = math.random()

state[ket1] = rnd1
state[ket2] = rnd2
state[ket3] = rnd3

assert(state[ket1] == rnd1, state[ket2] == rnd2, state[ket3] == rnd3)
print(state[ket1],state[ket2],state[ket3])

print"begin test method1"
print"state before"
for k,v in state:iter() do print("\t",k,v) end
state:Cf(10):Af(2):Cf(3):Nf(4):Cf(5)
print"state after"
for k,v in state:iter() do print("\t",k,v) end
print"end test method1"

print"copied state"
local newstate = fock_space.copy(state)

local rnd1 = function() return 2*(math.random()-0.5) end
local rnd = function() return rnd1()+rnd1()*complex.I end

newstate[ket1] = 0.1
newstate[ket2] = 0.2
newstate[ket3] = 0.3

for k,v in newstate:iter() do print("\t",k,v) end

local fock_driver = assert(require"iota.fock.driver")

math.randomseed(1234)

local Hket = function(H,ket)
	H(rnd(), ket:Cf(math.random(1,10)))
	H(rnd(), ket:Af(math.random(1,10)))
	H(rnd(), ket:Cf(math.random(1,10)))
	H(rnd(), ket:Af(math.random(1,10)))
	H(rnd(), ket:Cf(math.random(1,10)))
	H(rnd(), ket:Af(math.random(1,10)))
	H(rnd(), ket:Cf(math.random(1,10)))
	H(rnd(), ket:Af(math.random(1,10)))
end

newstate = fock_driver.Hstate(newstate, Hket, true)
for k,v in newstate:iter() do print("\t",k,v) end
print("#state", #newstate)

-- test memory leak
for k=1,1000 do
	newstate = fock_driver.Hstate(newstate, Hket)
	io.write(k, " ")
	--print("#state", #newstate)
end

newstate = fock_driver.Hstate(newstate, Hket, true)
for k,v in newstate:iter() do print("\t",k,v) end
print("#state", #newstate)

