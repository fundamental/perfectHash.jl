#Generate Coefficients to perform minimal hashing
#Based off of gperf implementation
#Copyright (C) Mark McCurry 2014

#Assumes 7 bit ASCII throughout
function ideal_hash(word, pos)
    h = Int[]
    for p=pos
        if(p<=length(word))
            push!(h, int(word[p]))
        end
    end
    push!(h, length(word))
    {h...}
end

#Print values that map to duplicate keys
function dups(keys, vals)
    a = unique(keys)
    b = zeros(Int, length(a))

    for i=1:length(keys)
        b[find(map(x->(length(keys[i])==length(x) && keys[i]==x), a))] .+= 1
    end

    for i=1:length(b)
        if(b[i] != 1)
            println("Dups at ", a[i], ":")
            println(vals[find(map(x->(length(a[i])==length(x) && a[i]==x), keys))])
        end
    end
end

#Simplified Greedy Algorithm
#(May result in some positions that could be removed)
function find_pos(words::Vector{ASCIIString})
    pos_list     = []
    Max_Len      = maximum(map(length,words))
    current_dups = length(words)
    println("Finding Position for words: ", length(words))
    while(true)
        pos_best     = -1
        pos_best_val = 9999 #TODO find INT_MAX equiv
        for i=setdiff(1:Max_Len,pos_list)
            t = map(w->ideal_hash(w,[pos_list,i]), {words...})
            v=length(words)-length(unique(t))
            if(v<pos_best_val)
                pos_best_val = v
                pos_best     = i
            end
        end
        if(pos_best_val >= current_dups)
            break
        end
        current_dups = pos_best_val
        pos_list = [pos_list, pos_best]
        println("Positions Inc: ", pos_list')
    end
    dups(map(w->ideal_hash(w,pos_list), words), words)
    println("Duplicates: ", current_dups)
    #println("Positions info: ", map(w->ideal_hash(w,pos_list), words))
    sort(pos_list)
end

function hash_with_off(word::ASCIIString, pos::Vector{Int}, off::Vector{Int})
    h = Int[]
    for i=1:length(pos)
        if(pos[i]<=length(word))
           push!(h, word[pos[i]]+off[i])
        end
    end
    {sort([length(word), h...])...}
end

function multi_set_intersect(words, pos, off)
    vals = map(w->tuple(hash_with_off(w, pos, off)...),{words...})
    t    = length(unique(sort(vals)))
    length(vals)-t
end

#Find offset vector
function find_off(words::Vector{ASCIIString}, pos::Vector{Int})
    println("Finding Offsets")
    off = zeros(Int, length(pos))
    for i=1:length(pos)
        pos_best     = -1
        pos_best_val = 9999 #TODO find INT_MAX equiv
        for j=0:100
            off[i] = j
            v = multi_set_intersect(words, pos, off)
            if(v<pos_best_val)
                pos_best_val = v
                pos_best     = j
            end
            if(v == 0)
                break
            end
        end

        off[i] = pos_best
        if(pos_best_val == 0)
            break
        end
    end

    view = zeros(Int, length(words), 1+length(pos))
    for i=1:length(words)
        view[i,1]  = length(words[i])
        for j=1:length(pos)
            if(pos[j]<=length(words[i]))
                view[i,1+j] = words[i][j]+off[j]
            end
        end
    end
    println("Offsets: ", off)
    off
end

function hash_word(word, pos, off, table)
    h = length(word) 
    for i=1:length(pos)
        if(pos[i]<=length(word))
            h=h+int(table[word[pos[i]]+off[i]])
        end
    end
    h
end

#Find association Array
function find_assoc(words, pos, off)
    println("Finding associations")
    vs = zeros(Int, 128)
    println("Initial Hash: ", map(w->hash_word(w,pos,off,vs),words)')
    k = map(w->hash_word(w,pos,off,vs),words)
    v = words
    for k=1:4
        for i=1:128
            pos_best     = -1
            pos_best_val = 9999 #TODO find INT_MAX equiv
            for j=0:100
                vs[i] = j
                t = map(w->hash_word(w, pos, off, vs), {words...})
                vv = length(words)-length(unique(t))
                #println("Assoc: ", i, " ", j, " ", vv) 
                if(vv<pos_best_val)
                    pos_best_val = vv
                    pos_best     = j
                end
            end
            vs[i] = pos_best
        end
    end
    k = map(w->hash_word(w,pos,off,vs),words)
    dups(k, v)
    println("Assocation Array: ", vs')
    return vs
end

#Find array to remap elements to the right positions
function find_remap(words, pos, off, table)
    println("Remapping elements...")
    t = map(w->hash_word(w, pos, off, table), words)
    m = zeros(Int, maximum(t))
    for i=1:length(t)
        m[t[i]] = i
    end
    println(m')
    m
end

function make_minimal_hash(data)
    pos    = find_pos(data)
    off    = find_off(data, pos)
    assoc  = find_assoc(data, pos, off)
    remap  = find_remap(data, pos, off, assoc)
    println("Total len: ", length(string(data...)))
    return (pos, off, assoc, remap)
end


Test = ["foo", "bar", "bax", "blam", "random", "words", "tests", "something else"]
Test2 = [
"oscil/"
"mod-oscil/"
"FreqLfo/"
"AmpLfo/"
"FilterLfo/"
"FreqEnvelope/"
"AmpEnvelope/"
"FilterEnvelope/"
"FMFreqEnvelope/"
"FMAmpEnvelope/"
"VoiceFilter/"
"Enabled"
"Unison_size"
"Unison_frequency_spread"
"Unison_stereo_spread"
"Unison_vibratto"
"Unison_vibratto_speed"
"Unison_invert_phase"
"Type"
"PDelay"
"Presonance"
"Pextoscil"
"PextFMoscil"
"Poscilphase"
"PFMoscilphase"
"Pfilterbypass"
"Pfixedfreq"
"PfixedfreqET"
"PDetune"
"PCoarseDetune"
"PDetuneType"
"PFreqEnvelopeEnabled"
"PFreqLfoEnabled"
"PPanning"
"PVolume"
"PVolumeminus"
"PAmpVelocityScaleFunction"
"PAmpEnvelopeEnabled"
"PAmpLfoEnabled"
"PFilterEnabled"
"PFilterEnvelopeEnabled"
"PFilterLfoEnabled"
"PFMEnabled"
"PFMVoice"
"PFMVolume"
"PFMVolumeDamp"
"PFMVelocityScaleFunction"
"PFMDetune"
"PFMCoarseDetune"
"PFMDetuneType"
"PFMFreqEnvelopeEnabled"
"PFMAmpEnvelopeEnabled"
"detunevalue"
"octave"
"coarsedetune"
]

Test3 = [
"oscil"
"FreqLfo"
"AmpLfo"
"FilterLfo"
"resonance"
"FreqEnvelope"
"AmpEnvelope"
"FilterEnvelope"
"GlobalFilter"
"Pmode"
"Volume"
"hp.base.type"
"hp.base.par1"
"hp.freqmult"
"hp.modulator.par1"
"hp.modulator.freq"
"hp.width"
"hp.amp.mode"
"hp.amp.type"
"hp.amp.par1"
"hp.amp.par2"
"Php.autoscale"
"hp.onehalf"
"bandwidth"
"bwscale"
"hrpos.type"
"hrpos.par1"
"hrpos.par2"
"hrpos.par3"
"quality.samplesize"
"quality.basenote"
"quality.oct"
"quality.smpoct"
"fixedfreq"
"fixedfreqET"
"DetuneType"
"Stereo"
"Panning"
"AmpVelocityScaleFunction"
"PunchStrength"
"PunchTime"
"PunchStretch"
"PunchVelocitySensing"
"FilterVelocityScale"
"FilterVelocityScaleFunction"
"Pbandwidth"
"bandwidthvalue"
"nhr"
"profile"
"sample"
"detunevalue"
"octave"
"coarsedetune"
]

println("====================================================")
make_minimal_hash(Test)
println("vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv")
make_minimal_hash(Test2)
println("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
make_minimal_hash(Test3)
println("====================================================")


#Resulting RTOSC DataStructure
#Per dispatch level:
#   bool unique;
#   hash_inc, hash_assoc, hash_remap
#   hash_equiv_classes;//normally blank
#Per Word:
#   bool wild;//?
#   short fixed_length
#   bool has_enum
#   short enum_range
#   bool has_trailing_slash
#   bool has_arg_delim
#   char **arg_strs //would benifit from string intern table, but whatevs
