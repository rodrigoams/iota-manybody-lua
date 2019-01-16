collectgarbage("generational")

local ca = require"iota.complex.array"

print(ca.version)

local cn = require"iota.complex.number"

local N = 1.0e6
local carray1 = ca.new(N)
local carray2 = ca.new(N)

assert(ca.size(carray1) == N)
assert(ca.size(carray2) == N)

collectgarbage("collect")

local random = function()
	return (math.random()-0.5)
end

for k=1,N do
	local k,v1,v2 = math.random(1,N), random() + random()*cn.I, random() + random()*cn.I

	ca.set(carray1,k,v1)
	assert(ca.get(carray1,k) == v1)

	ca.set(carray2,k,v2)
	assert(ca.get(carray2,k) == v2)
end

do
	local c1 = collectgarbage("count")
	collectgarbage("collect")
	print("collected garbage:", (c1 - collectgarbage("count"))/1024, "MiB" )
end

print("total lua memory usage: ", collectgarbage("count")/1024, "MiB")
print("expected usage from arrays: ", 2*(8*2)*N/1024/1024, "MiB")

ca.xcopy(carray1,1.0,carray2,true)

for k=1,N do
	local v1,v2 = ca.get(carray1,k), ca.get(carray2,k)
	assert(v1 == cn.conj(v2))
end

ca.xayb(carray1,0.5,carray2,0.5,false,false)

for k=1,N do
	local r1,i1 = cn.real(ca.get(carray1,k)), cn.imag(ca.get(carray1,k))
	local r2,i2 = cn.real(ca.get(carray2,k)), cn.imag(ca.get(carray2,k))
	assert(r1 == r2)
	assert(i2 == 0.0)
end

local epsilon = 1.0
while (1.0 + 0.5 * epsilon) ~= 1.0 do epsilon = 0.5 * epsilon end
--print("epsilon", epsilon)

local sum = 0.0
for k=1,N do sum = sum + ca.get(carray1,k)*ca.get(carray2,k) end

print("sum, inner", sum, ca.inner(carray1,carray2,false,false))

assert( cn.abs(ca.inner(carray1,carray2,false,false) - sum) < 1.0e10 )

os.exit()

