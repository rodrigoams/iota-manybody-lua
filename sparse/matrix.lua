local mtype = math.type

local complex = require"iota.complex.number"

local matrix = {}

matrix.newmat = function (m,n,notsparse)
	if notsparse then assert(type(notsparse) == 'boolean') end
	assert(mtype(m) == "integer" and mtype(n) == "integer","You should use integers (> 0) arguments")
	assert(m>0 and n>0,"Dimensions must be > 0")
	local mat = {}
	mat.nrows = m
	mat.ncolumns = n
	mat.nnz = 0
	mat.type = notsparse and "dense" or "sparse"
	for i=1,m do
		mat[i] = {}
		if notsparse == true then -- dense
			for j=1,n do mat[i][j] = 0.0 end
		else -- sparse
			local nnz = 0
			mat[i].nnz = nnz
			mat[i].type = "sparse"
			local mt = {}
			mt.__pairs = function(t)
				local tab = mt
				local key = nil
				return function(t) 
					::inicio::
					local k,v = next(tab,key)
					if k == nil then return nil,nil end
					key = k
					if type(k) == 'string' then goto inicio end
					return k,v
				end
			end
			mt.__index = function(t,k) return rawget(mt,k) or 0.0 end
			mt.__newindex = function(t,k,v)
				local absv = complex.abs(v)
				if absv > 0.0 then
					if not rawget(mt,k) then
						mat.nnz = mat.nnz + 1
						nnz = nnz + 1
					end
					rawset(mt,k,v)
				else
					if rawget(mt,k) then
						rawset(mt,k,nil)
						mat.nnz = mat.nnz - 1
						nnz = nnz - 1
					end
				end
			end
			mt.__len = function(t) return mat.ncolumns end
			setmetatable(mat[i],mt)
		end
	end
	return setmetatable(mat,matrix)
end

matrix.print = function(mat,name)
	if name then print(name) end
	for i=1,mat.nrows do
		for j=1,mat.ncolumns do
			io.write(string.format(" %10.6f",mat[i][j]))
			--io.write(string.format(" %d",mat[i][j]))
		end
		print""
	end
end

matrix.write2octaveCellTop = function(file,name,nrows,ncolumns)
	assert(type(name) == "string")
        file:write(string.format("# name: %s\n",name))
	file:write("# type: cell\n")
	file:write(string.format("# rows: %d\n",nrows))
	file:write(string.format("# columns: %d\n",ncolumns))
end

matrix.write2octave = function(mat,file,name)
	assert((type(file) == "userdata" or type(file) == "file") and type(name) == "string")
	local name = (name == "cell") and "<cell-element>" or name
	--local namemat = name..".mat"
	--local mode = (mode == "cell") and "a" or "w"
	-- open file
        --local file = io.open(namemat,mode)
        -- octave file description
        --file:write("# Created by Rodrigo!!!\n")
        file:write(string.format("# name: %s\n",name))
	if mat.type == "sparse" then
		file:write("# type: sparse matrix\n")
		file:write(string.format("# nnz: %d\n",mat.nnz))
	else
		file:write("# type: matrix\n")
	end
        file:write(string.format("# rows: %d\n",mat.nrows))
        file:write(string.format("# columns: %d\n",mat.ncolumns))
        -- column major order
	local mtype, mabs = math.type, math.abs
	if mat.type == "sparse" then
		for ki,vi in pairs(mat) do
			if mtype(ki) == "integer" then
				local temp = {}
				for k,_ in pairs(vi) do
					temp[#temp+1] = k
				end
				table.sort(temp)
				for _,v in ipairs(temp) do
					local r = vi[v]
					if mabs(r) ~= 0.0 then
						file:write(string.format("%d %d %.15f\n",v,ki,r))
					end
				end
			end
		end
	else
		for i=1,mat.nrows do
			for j=1,mat.ncolumns do
				file:write(string.format("%.15f ",mat[i][j]))
			end
			file:write("\n")
		end
	end
	--if mode == "a" then
	for i=1,4 do file:write("\n") end
	--end
        --file:close()
	--os.execute("gzip -9 -f "..namemat)
end


matrix.newvec = function(n)
	local mat = matrix.newmat(1,n)
	return mat[1]
end

matrix.tostring = function(mat)
	assert(mat.nrows and mat.ncolumns)
	local H = ""
	H = H .. "{\n"
	for i=1,mat.nrows do
	for j=1,mat.ncolumns do
		if j == 1 then H = H .. "{" end
		H = H .. tostring(mat[i][j])
		if j ~= mat.ncolumns then H = H .. "," end
		if j == mat.ncolumns then
			if i ~= mat.ncolumns then H = H .. "},\n"
			else H = H .. "}\n" end
		end
	end end
	H = H .. "}\n"
	return H
end

matrix.__tostring = function(mat) return matrix.tostring(mat) end

matrix.__index = matrix

return matrix
