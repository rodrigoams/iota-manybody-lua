
local octave = require"iota.parser.octave"
print(octave)
for k,v in pairs(octave) do print(k,v) end

octave.load_ascii("EVALS-0000.mat")
octave.load_ascii("EVECS-0000.mat")

