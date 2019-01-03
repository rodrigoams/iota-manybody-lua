local array = {}
local larray = require"iota.complex.array"
local time = false
array.new = larray.new
local get = larray.get
local set = larray.set
array.inner = function(...)
  if TIME then time = os.clock() end
  local res = larray.inner(...)
  if TIME then TIME.inner = TIME.inner + (os.clock()-time) end
  if COUNT then COUNT.inner = COUNT.inner+1 end
  return res
end
array.xayb = function(x,a,y,b)
  if time then time = os.clock() end
  larray.xayb(x,a,y,b,false,false)
  if TIME then TIME.xayb = TIME.xayb + (os.clock()-time) end
  if COUNT then COUNT.xayb = COUNT.xayb+1 end
end
array.xcopy = function(x,a,y)
  if TIME then time = os.clock() end
  larray.xcopy(x,a,y,false)
  if TIME then TIME.xcopy = TIME.xcopy + (os.clock()-time) end
  if COUNT then COUNT.xcopy = COUNT.xcopy+1 end
end
array.print = function(a) for k=1,#a do print(string.format("%5d %10.6f %10.6fi",k,complex.real(get(a,k)),complex.imag(get(a,k)))) end end
local mt = getmetatable(array.new(1))
mt.__index = function(a,k) return get(a,k) end
mt.__newindex = function(a,k,v) set(a,k,v) end
mt.__len = function(a) return larray.size(a) end

return array
