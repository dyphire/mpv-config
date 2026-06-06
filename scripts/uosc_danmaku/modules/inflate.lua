 --[[lit-meta
	name = 'TohruMKDM/inflate'
	version = '2.0.0'
	homepage = 'https://github.com/TohruMKDM/lua-inflate'
	description = 'ZIP archive inflation in pure Lua.'
	tags = {'zlib', 'inflate', 'inflation', 'compression'}
	license = 'MIT'
	author = {name = 'Tohru~ (トール)', email = 'admin@ikaros.pw'}
    contributors = {'zerkman', 'samhocevar'}
]]

---@diagnostic disable-next-line: undefined-global
local bitOp = bit32 or bit
if not bitOp then
    error('This library requires bit operations to work property.')
end

local rshift, lshift, band, bxor, bnot = bitOp.rshift, bitOp.lshift, bitOp.band, bitOp.bxor, bitOp.bnot
local byte, char, sub, find = string.byte, string.char, string.sub, string.find
local concat, unpack = table.concat, unpack or table.unpack
local min = math.min

local ORDER = {17, 18, 19, 1, 9, 8, 10, 7, 11, 6, 12, 5, 13, 4, 14, 3, 15, 2, 16}
local CRC32 = {[0] = 0, 1996959894, -301047508, -1727442502, 124634137, 1886057615, -379345611, -1637575261, 249268274, 2044508324, -522852066, -1747789432, 162941995, 2125561021, -407360249, -1866523247, 498536548, 1789927666, -205950648, -2067906082, 450548861, 1843258603, -187386543, -2083289657, 325883990, 1684777152, -43845254,-1973040660, 335633487, 1661365465, -99664541, -1928851979, 997073096, 1281953886, -715111964, -1570279054, 1006888145, 1258607687, -770865667, -1526024853, 901097722, 1119000684, -608450090, -1396901568, 853044451, 1172266101, -589951537, -1412350631, 651767980, 1373503546, -925412992, -1076862698, 565507253, 1454621731, -809855591, -1195530993, 671266974, 1594198024, -972236366, -1324619484, 795835527, 1483230225, -1050600021, -1234817731, 1994146192, 31158534, -1731059524, -271249366, 1907459465, 112637215, -1614814043, -390540237, 2013776290, 251722036, -1777751922, -519137256, 2137656763, 141376813, -1855689577, -429695999, 1802195444, 476864866, -2056965928, -228458418, 1812370925, 453092731, -2113342271, -183516073, 1706088902, 314042704, -1950435094, -54949764, 1658658271, 366619977, -1932296973, -69972891, 1303535960, 984961486, -1547960204, -725929758, 1256170817, 1037604311, -1529756563, -740887301, 1131014506, 879679996, -1385723834, -631195440, 1141124467, 855842277, -1442165665, -586318647, 1342533948, 654459306, -1106571248, -921952122, 1466479909, 544179635, -1184443383, -832445281, 1591671054, 702138776, -1328506846, -942167884, 1504918807, 783551873, -1212326853, -1061524307, -306674912, -1698712650, 62317068, 1957810842, -355121351, -1647151185, 81470997,1943803523, -480048366, -1805370492, 225274430, 2053790376, -468791541, -1828061283, 167816743, 2097651377, -267414716, -2029476910, 503444072, 1762050814, -144550051, -2140837941, 426522225, 1852507879, -19653770, -1982649376, 282753626, 1742555852, -105259153, -1900089351, 397917763, 1622183637, -690576408, -1580100738, 953729732, 1340076626, -776247311, -1497606297, 1068828381, 1219638859, -670225446, -1358292148, 906185462, 1090812512, -547295293, -1469587627, 829329135, 1181335161, -882789492, -1134132454, 628085408, 1382605366, -871598187, -1156888829, 570562233, 1426400815, -977650754, -1296233688, 733239954, 1555261956, -1026031705, -1244606671, 752459403, 1541320221, -1687895376, -328994266, 1969922972, 40735498, -1677130071, -351390145, 1913087877, 83908371, -1782625662, -491226604, 2075208622, 213261112, -1831694693, -438977011, 2094854071, 198958881, -2032938284, -237706686, 1759359992, 534414190, -2118248755, -155638181, 1873836001, 414664567, -2012718362, -15766928, 1711684554, 285281116, -1889165569, -127750551, 1634467795, 376229701, -1609899400, -686959890, 1308918612, 956543938, -1486412191, -799009033, 1231636301, 1047427035, -1362007478, -640263460, 1088359270, 936918000, -1447252397, -558129467, 1202900863, 817233897, -1111625188, -893730166, 1404277552, 615818150, -1160759803, -841546093, 1423857449, 601450431, -1285129682, -1000256840, 1567103746, 711928724, -1274298825, -1022587231, 1510334235, 755167117}
local NBT = {2, 3, 7}
local CNT  = {144, 112, 24, 8}
local DPT = {8, 9, 7, 8}
local STATIC_HUFFMAN = {[0] = 5, 261, 133, 389, 69, 325, 197, 453, 37, 293, 165, 421, 101, 357, 229, 485, 21, 277, 149, 405, 85, 341, 213, 469, 53, 309, 181, 437, 117, 373, 245, 501}
local STATIC_BITS = 5
local CHUNK_SIZE = 4096

local function generateCrc32(input)
    local crc = -1
    for i = 1, #input do
        local c = byte(input, i)
        crc = bxor(CRC32[bxor(c, band(crc, 255))], rshift(crc, 8))
    end
    crc = bnot(crc)
    if crc < 0 then
        crc = crc + 4294967296
    end
    return crc
end

local function flushBits(stream, int)
    stream.bits = rshift(stream.bits, int)
    stream.count = stream.count - int
end

local function peekBits(stream, int)
    local buffer, bits, count, position = stream.buffer, stream.bits, stream.count, stream.position
    while count < int do
        bits = bits + lshift(byte(buffer, position), count)
        position = position + 1
        count = count + 8
    end
    stream.bits = bits
    stream.position = position
    stream.count = count
    return band(bits, lshift(1, int) - 1)
end

local function getBits(stream, int)
    local result = peekBits(stream, int)
    stream.bits = rshift(stream.bits, int)
    stream.count = stream.count - int
    return result
end

local function getElement(stream, hufftable, int)
    local element = hufftable[peekBits(stream, int)]
    local length = band(element, 15)
    local result = rshift(element, 4)
    stream.bits = rshift(stream.bits, length)
    stream.count = stream.count - length
    return result
end

local function huffman(depths)
    local size = #depths
    local blocks, codes, hufftable = {[0] = 0}, {}, {}
    local bits, code = 1, 0
    for i = 1, size do
        local depth = depths[i]
        if depth > bits then
            bits = depth
        end
        blocks[depth] = (blocks[depth] or 0) + 1
    end
    for i = 1, bits do
        code = (code + (blocks[i - 1] or 0)) * 2
        codes[i] = code
    end
    for i = 1, size do
        local depth = depths[i]
        if depth > 0 then
            local element = (i - 1) * 16 + depth
            local rcode = 0
            for j = 1, depth do
                rcode = rcode + lshift(band(1, rshift(codes[depth], j - 1)), depth - j)
            end
            for j = 0, 2 ^ bits - 1, 2 ^ depth do
                hufftable[j + rcode] = element
            end
            codes[depth] = codes[depth] + 1
        end
    end
    return hufftable, bits
end

local function loop(output, stream, litTable, litBits, distTable, distBits)
    local index = #output + 1
    local lit
    repeat
        lit = getElement(stream, litTable, litBits)
        if lit < 256 then
            output[index] = lit
            index = index + 1
        elseif lit > 256 then
            local bits, size, dist = 0, 3, 1
            if lit < 265 then
                size = size + lit - 257
            elseif lit < 285 then
                bits = rshift(lit - 261, 2)
                size = size + lshift(band(lit - 261, 3) + 4, bits)
            else
                size = 258
            end
            if bits > 0 then
                size = size + getBits(stream, bits)
            end
            local element = getElement(stream, distTable, distBits)
            if element < 4 then
                dist = dist + element
            else
                bits = rshift(element - 2, 1)
                dist = dist + lshift(band(element, 1) + 2, bits) + getBits(stream, bits)
            end
            local position = index - dist
            repeat
                output[index] = output[position]
                index = index + 1
                position = position + 1
                size = size - 1
            until size == 0
        end
    until lit == 256
end

local function dynamic(output, stream)
    local lit, dist, length = 257 + getBits(stream, 5), 1 + getBits(stream, 5), 4 + getBits(stream, 4)
    local depths = {}
    for i = 1, length do
        depths[ORDER[i]] = getBits(stream, 3)
    end
    for i = length + 1, 19 do
        depths[ORDER[i]] = 0
    end
    local lengthTable, lengthBits = huffman(depths)
    local i = 1
    local total = lit + dist + 1
    repeat
        local element = getElement(stream, lengthTable, lengthBits)
        if element < 16 then
            depths[i] = element
            i = i + 1
        elseif element < 19 then
            local int = NBT[element  - 15]
            local count = 0
            local num = 3 + getBits(stream, int)
            if element == 16 then
                count = depths[i - 1]
            elseif element == 18 then
                num = num + 8
            end
            for _ = 1, num do
                depths[i] = count
                i = i + 1
            end
        end
    until i == total
    local litDepths, distDepths = {}, {}
    for j = 1, lit do
        litDepths[j] = depths[j]
    end
    for j = lit + 1, #depths do
        distDepths[#distDepths + 1] = depths[j]
    end
    local litTable, litBits = huffman(litDepths)
    local distTable, distBits = huffman(distDepths)
    loop(output, stream, litTable, litBits, distTable, distBits)
end

local function static(output, stream)
    local depths = {}
    for i = 1, 4 do
        local depth = DPT[i]
        for _ = 1, CNT[i] do
            depths[#depths + 1] = depth
        end
    end
    local litTable, litBits = huffman(depths)
    loop(output, stream, litTable, litBits, STATIC_HUFFMAN, STATIC_BITS)
end

local function uncompressed(output, stream)
    flushBits(stream, band(stream.count, 7))
    local length = getBits(stream, 16); getBits(stream, 16)
    local buffer, position = stream.buffer, stream.position
    for i = position, position + length - 1 do
        output[#output + 1] = byte(buffer, i, i)
    end
    stream.position = position + length
end

local function int2le(buffer, position)
    local a, b = byte(buffer, position, position + 1)
    return b * 256 + a
end

local function int4le(buffer, position)
    local a, b, c, d = byte(buffer, position, position + 3)
    return ((d * 256 + c) * 256 + b) * 256 + a
end

local inflate = {}

---@class BitStream
---@field buffer string Character Buffer
---@field position integer Position in the character buffer
---@field bits integer Bits buffer
---@field count integer Number of bits in the buffer
local BitStream = {}
BitStream.__index = BitStream

---Creates a new bitstream object with the specified buffer
---@param buffer string The character buffer to use for the bitstream.
---@return BitStream
function inflate.new(buffer)
    local EOCD
    local pos = 1
    repeat
        local i, j = find(buffer, 'PK\5\6', pos, true)
        if i then
            EOCD = i
            pos = j + 1
        end
    until not i
    if EOCD then
        buffer = sub(buffer, 1, EOCD + 19)..'\0\0'
    end
    local object = {buffer = buffer, position = 0, bits = 0, count = 0}
    return setmetatable(object, BitStream)
end
---Update the chunk size to be used in inflation. Defaults to `4096`
---@param size integer The new chunk size, should be a power of 2.
function inflate.setChunkSize(size)
    CHUNK_SIZE = size
end

---Returns an iterator that spans the list of files in the stream
---@return fun(): name: string?, offset: integer?, size: integer?, packed: boolean?, crc: integer?
function BitStream:files()
    local buffer = self.buffer
    local position = int4le(buffer, #buffer - 5) + 1
    return function()
        if int4le(buffer, position) ~= 33639248 then
            return
        end
        local packed = int2le(buffer, position + 10) ~= 0
        local crc = int4le(buffer, position + 16)
        local length = int2le(buffer, position + 28)
        local offset = int4le(buffer, position + 42) + 1
        local name = sub(buffer, position + 46, position + 45 + length)
        position = position + 46 + length + int2le(buffer, position + 30) + int2le(buffer, position + 32)
        return name, offset + 30 + length + int2le(buffer, offset + 28), int4le(buffer, offset + 18), packed, crc
    end
end
---Inflates the bitstream starting from the specified offset and optionally performs checksum verification
---@param offset integer The position at which to begin inflating.
---@param crc? integer The checksum value to use for verification.
---@return string
function BitStream:inflate(offset, crc)
    local output, buffer = {}, {}
    local last, typ
    self.bits = 0
    self.count = 0
    self.position = offset
    repeat
        last, typ = getBits(self, 1), getBits(self, 2)
        typ = typ == 0 and uncompressed(output, self) or typ == 1 and static(output, self) or typ == 2 and dynamic(output, self) 
    until last == 1
    local size = #output
    for i = 1, size, CHUNK_SIZE do
        buffer[#buffer + 1] = char(unpack(output, i, min(i + CHUNK_SIZE - 1, size)))
    end
    local result = concat(buffer)
    if crc and crc ~= generateCrc32(result) then
        error("Checksum verification failed: the computed CRC does not match the expected value.", 2)
    end
    return result
end
---Extracts a specific file from the bitstream
---@param filepath string The file to unzip.
---@param verify? boolean Whether or not to perform checksum verification.
---@return string
function BitStream:unzip(filepath, verify)
    for name, offset, size, packed, crc in self:files() do
        if name == filepath then
            return packed and self:inflate(offset, verify and crc or nil) or sub(self.buffer, offset, offset + size - 1)
        end
    end
    error('File "'..filepath..'" not found in ZIP archive.')
end
--- Extracts unpacked contents from the bitstream at the specified offset and size
--- @param offset integer The starting position from which to extract the contents.
--- @param size integer The size of the contents to extract.
function BitStream:extract(offset, size)
    return sub(self.buffer, offset, offset + size - 1)
end

return inflate
