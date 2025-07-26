--[[

 sha256 -- public domain Lua SHA-256 implementation
 no warranty implied; use at your own risk

 author: dyphire

 COMPATIBILITY

 Lua 5.1+, LuaJIT

 LICENSE: MIT License

--]]

local unpack = unpack or table.unpack

local function band(a,b)
    local res = 0
    local bit = 1
    for i = 0,31 do
        local aa = a % 2
        local bb = b % 2
        if aa == 1 and bb == 1 then
            res = res + bit
        end
        a = (a - aa) / 2
        b = (b - bb) / 2
        bit = bit * 2
    end
    return res
end

local function bor(a,b)
    local res = 0
    local bit = 1
    for i = 0,31 do
        local aa = a % 2
        local bb = b % 2
        if aa == 1 or bb == 1 then
            res = res + bit
        end
        a = (a - aa) / 2
        b = (b - bb) / 2
        bit = bit * 2
    end
    return res
end

local function bxor(a,b)
    local res = 0
    local bit = 1
    for i = 0,31 do
        local aa = a % 2
        local bb = b % 2
        if (aa + bb) == 1 then
            res = res + bit
        end
        a = (a - aa) / 2
        b = (b - bb) / 2
        bit = bit * 2
    end
    return res
end

local function bnot(a)
    return 0xFFFFFFFF - a
end

local function lshift(a,n)
    return (a * 2^n) % 2^32
end

local function rshift(a,n)
    return math.floor(a / 2^n) % 2^32
end

local function bit_ror(x, n)
    return bor(rshift(x, n), lshift(x, 32 - n))
end

local function sha256(message)
    local k = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    }

    local function preprocess(msg)
        local len = #msg
        local bitLen = len * 8
        msg = msg .. "\128"

        local zeroPad = 64 - ((len + 9) % 64)
        if zeroPad ~= 64 then
            msg = msg .. string.rep("\0", zeroPad)
        end

        msg = msg .. string.char(
            rshift(bitLen, 56) % 256,
            rshift(bitLen, 48) % 256,
            rshift(bitLen, 40) % 256,
            rshift(bitLen, 32) % 256,
            rshift(bitLen, 24) % 256,
            rshift(bitLen, 16) % 256,
            rshift(bitLen, 8) % 256,
            bitLen % 256
        )
        return msg
    end

    local function chunkify(msg)
        local chunks = {}
        for i = 1, #msg, 64 do
            table.insert(chunks, msg:sub(i, i + 63))
        end
        return chunks
    end

    local function processChunk(chunk, hash)
        local w = {}

        for i = 1, 64 do
            if i <= 16 then
                w[i] = lshift(string.byte(chunk, (i - 1) * 4 + 1), 24) +
                       lshift(string.byte(chunk, (i - 1) * 4 + 2), 16) +
                       lshift(string.byte(chunk, (i - 1) * 4 + 3), 8) +
                       string.byte(chunk, (i - 1) * 4 + 4)
            else
                local s0 = bxor(bxor(bit_ror(w[i - 15], 7), bit_ror(w[i - 15], 18)), rshift(w[i - 15], 3))
                local s1 = bxor(bxor(bit_ror(w[i - 2], 17), bit_ror(w[i - 2], 19)), rshift(w[i - 2], 10))
                w[i] = (w[i - 16] + s0 + w[i - 7] + s1) % 2^32
            end
        end

        local a, b, c, d, e, f, g, h = unpack(hash)

        for i = 1, 64 do
            local s1 = bxor(bxor(bit_ror(e, 6), bit_ror(e, 11)), bit_ror(e, 25))
            local ch = bxor(band(e, f), band(bnot(e), g))
            local temp1 = (h + s1 + ch + k[i] + w[i]) % 2^32
            local s0 = bxor(bxor(bit_ror(a, 2), bit_ror(a, 13)), bit_ror(a, 22))
            local maj = bxor(bxor(band(a, b), band(a, c)), band(b, c))
            local temp2 = (s0 + maj) % 2^32

            h = g
            g = f
            f = e
            e = (d + temp1) % 2^32
            d = c
            c = b
            b = a
            a = (temp1 + temp2) % 2^32
        end

        return
            (hash[1] + a) % 2^32,
            (hash[2] + b) % 2^32,
            (hash[3] + c) % 2^32,
            (hash[4] + d) % 2^32,
            (hash[5] + e) % 2^32,
            (hash[6] + f) % 2^32,
            (hash[7] + g) % 2^32,
            (hash[8] + h) % 2^32
    end

    message = preprocess(message)
    local chunks = chunkify(message)

    local hash = {
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    }

    for _, chunk in ipairs(chunks) do
        hash = {processChunk(chunk, hash)}
    end

    local result = ""
    for _, h in ipairs(hash) do
        result = result .. string.format("%08x", h)
    end

    return result
end

return sha256
