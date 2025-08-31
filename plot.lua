local base64 = (function()
    local lookupValueToCharacter = buffer.create(64)
    local lookupCharacterToValue = buffer.create(256)

    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local padding = string.byte("=")

    for index = 1, 64 do
        local value = index - 1
        local character = string.byte(alphabet, index)
        
        buffer.writeu8(lookupValueToCharacter, value, character)
        buffer.writeu8(lookupCharacterToValue, character, value)
    end

    local function encode(input: buffer): buffer
        local inputLength = buffer.len(input)
        local inputChunks = math.ceil(inputLength / 3)
        
        local outputLength = inputChunks * 4
        local output = buffer.create(outputLength)
        
        -- Since we use readu32 and chunks are 3 bytes large, we can't read the last chunk here
        for chunkIndex = 1, inputChunks - 1 do
            local inputIndex = (chunkIndex - 1) * 3
            local outputIndex = (chunkIndex - 1) * 4
            
            local chunk = bit32.byteswap(buffer.readu32(input, inputIndex))
            
            -- 8 + 24 - (6 * index)
            local value1 = bit32.rshift(chunk, 26)
            local value2 = bit32.band(bit32.rshift(chunk, 20), 0b111111)
            local value3 = bit32.band(bit32.rshift(chunk, 14), 0b111111)
            local value4 = bit32.band(bit32.rshift(chunk, 8), 0b111111)
            
            buffer.writeu8(output, outputIndex, buffer.readu8(lookupValueToCharacter, value1))
            buffer.writeu8(output, outputIndex + 1, buffer.readu8(lookupValueToCharacter, value2))
            buffer.writeu8(output, outputIndex + 2, buffer.readu8(lookupValueToCharacter, value3))
            buffer.writeu8(output, outputIndex + 3, buffer.readu8(lookupValueToCharacter, value4))
        end
        
        local inputRemainder = inputLength % 3
        
        if inputRemainder == 1 then
            local chunk = buffer.readu8(input, inputLength - 1)
            
            local value1 = bit32.rshift(chunk, 2)
            local value2 = bit32.band(bit32.lshift(chunk, 4), 0b111111)

            buffer.writeu8(output, outputLength - 4, buffer.readu8(lookupValueToCharacter, value1))
            buffer.writeu8(output, outputLength - 3, buffer.readu8(lookupValueToCharacter, value2))
            buffer.writeu8(output, outputLength - 2, padding)
            buffer.writeu8(output, outputLength - 1, padding)
        elseif inputRemainder == 2 then
            local chunk = bit32.bor(
                bit32.lshift(buffer.readu8(input, inputLength - 2), 8),
                buffer.readu8(input, inputLength - 1)
            )

            local value1 = bit32.rshift(chunk, 10)
            local value2 = bit32.band(bit32.rshift(chunk, 4), 0b111111)
            local value3 = bit32.band(bit32.lshift(chunk, 2), 0b111111)
            
            buffer.writeu8(output, outputLength - 4, buffer.readu8(lookupValueToCharacter, value1))
            buffer.writeu8(output, outputLength - 3, buffer.readu8(lookupValueToCharacter, value2))
            buffer.writeu8(output, outputLength - 2, buffer.readu8(lookupValueToCharacter, value3))
            buffer.writeu8(output, outputLength - 1, padding)
        elseif inputRemainder == 0 and inputLength ~= 0 then
            local chunk = bit32.bor(
                bit32.lshift(buffer.readu8(input, inputLength - 3), 16),
                bit32.lshift(buffer.readu8(input, inputLength - 2), 8),
                buffer.readu8(input, inputLength - 1)
            )

            local value1 = bit32.rshift(chunk, 18)
            local value2 = bit32.band(bit32.rshift(chunk, 12), 0b111111)
            local value3 = bit32.band(bit32.rshift(chunk, 6), 0b111111)
            local value4 = bit32.band(chunk, 0b111111)

            buffer.writeu8(output, outputLength - 4, buffer.readu8(lookupValueToCharacter, value1))
            buffer.writeu8(output, outputLength - 3, buffer.readu8(lookupValueToCharacter, value2))
            buffer.writeu8(output, outputLength - 2, buffer.readu8(lookupValueToCharacter, value3))
            buffer.writeu8(output, outputLength - 1, buffer.readu8(lookupValueToCharacter, value4))
        end
        
        return output
    end

    local function decode(input: buffer): buffer
        local inputLength = buffer.len(input)
        local inputChunks = math.ceil(inputLength / 4)
        
        -- TODO: Support input without padding
        local inputPadding = 0
        if inputLength ~= 0 then
            if buffer.readu8(input, inputLength - 1) == padding then inputPadding += 1 end
            if buffer.readu8(input, inputLength - 2) == padding then inputPadding += 1 end
        end

        local outputLength = inputChunks * 3 - inputPadding
        local output = buffer.create(outputLength)
        
        for chunkIndex = 1, inputChunks - 1 do
            local inputIndex = (chunkIndex - 1) * 4
            local outputIndex = (chunkIndex - 1) * 3
            
            local value1 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, inputIndex))
            local value2 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, inputIndex + 1))
            local value3 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, inputIndex + 2))
            local value4 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, inputIndex + 3))
            
            local chunk = bit32.bor(
                bit32.lshift(value1, 18),
                bit32.lshift(value2, 12),
                bit32.lshift(value3, 6),
                value4
            )
            
            local character1 = bit32.rshift(chunk, 16)
            local character2 = bit32.band(bit32.rshift(chunk, 8), 0b11111111)
            local character3 = bit32.band(chunk, 0b11111111)
            
            buffer.writeu8(output, outputIndex, character1)
            buffer.writeu8(output, outputIndex + 1, character2)
            buffer.writeu8(output, outputIndex + 2, character3)
        end
        
        if inputLength ~= 0 then
            local lastInputIndex = (inputChunks - 1) * 4
            local lastOutputIndex = (inputChunks - 1) * 3
            
            local lastValue1 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, lastInputIndex))
            local lastValue2 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, lastInputIndex + 1))
            local lastValue3 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, lastInputIndex + 2))
            local lastValue4 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, lastInputIndex + 3))

            local lastChunk = bit32.bor(
                bit32.lshift(lastValue1, 18),
                bit32.lshift(lastValue2, 12),
                bit32.lshift(lastValue3, 6),
                lastValue4
            )
            
            if inputPadding <= 2 then
                local lastCharacter1 = bit32.rshift(lastChunk, 16)
                buffer.writeu8(output, lastOutputIndex, lastCharacter1)
                
                if inputPadding <= 1 then
                    local lastCharacter2 = bit32.band(bit32.rshift(lastChunk, 8), 0b11111111)
                    buffer.writeu8(output, lastOutputIndex + 1, lastCharacter2)
                    
                    if inputPadding == 0 then
                        local lastCharacter3 = bit32.band(lastChunk, 0b11111111)
                        buffer.writeu8(output, lastOutputIndex + 2, lastCharacter3)
                    end
                end
            end
        end
        
        return output
    end

    return {
        encode = encode,
        decode = decode,
    }
end)()

local lzw = (function()
	local char = string.char
	local type = type
	local select = select
	local sub = string.sub
	local tconcat = table.concat

	local basedictcompress = {}
	local basedictdecompress = {}
	for i = 0, 255 do
		local ic, iic = char(i), char(i, 0)
		basedictcompress[ic] = iic
		basedictdecompress[iic] = ic
	end

	local function dictAddA(str, dict, a, b)
		if a >= 256 then
			a, b = 0, b+1
			if b >= 256 then
				dict = {}
				b = 1
			end
		end
		dict[str] = char(a,b)
		a = a+1
		return dict, a, b
	end

	local function compress(input)
		if type(input) ~= "string" then
			return nil, "string expected, got "..type(input)
		end
		local len = #input
		if len <= 1 then
			return "u"..input
		end

		local dict = {}
		local a, b = 0, 1

		local result = {"c"}
		local resultlen = 1
		local n = 2
		local word = ""
		for i = 1, len do
			local c = sub(input, i, i)
			local wc = word..c
			if not (basedictcompress[wc] or dict[wc]) then
				local write = basedictcompress[word] or dict[word]
				if not write then
					return nil, "algorithm error, could not fetch word"
				end
				result[n] = write
				resultlen = resultlen + #write
				n = n+1
				if  len <= resultlen then
					return "u"..input
				end
				dict, a, b = dictAddA(wc, dict, a, b)
				word = c
			else
				word = wc
			end
		end
		result[n] = basedictcompress[word] or dict[word]
		resultlen = resultlen+#result[n]
		n = n+1
		if  len <= resultlen then
			return "u"..input
		end
		return tconcat(result)
	end

	local function dictAddB(str, dict, a, b)
		if a >= 256 then
			a, b = 0, b+1
			if b >= 256 then
				dict = {}
				b = 1
			end
		end
		dict[char(a,b)] = str
		a = a+1
		return dict, a, b
	end

	local function decompress(input)
		if type(input) ~= "string" then
			return nil, "string expected, got "..type(input)
		end

		if #input < 1 then
			return nil, "invalid input - not a compressed string"
		end

		local control = sub(input, 1, 1)
		if control == "u" then
			return sub(input, 2)
		elseif control ~= "c" then
			return nil, "invalid input - not a compressed string"
		end
		input = sub(input, 2)
		local len = #input

		if len < 2 then
			return nil, "invalid input - not a compressed string"
		end

		local dict = {}
		local a, b = 0, 1

		local result = {}
		local n = 1
		local last = sub(input, 1, 2)
		result[n] = basedictdecompress[last] or dict[last]
		n = n+1
		for i = 3, len, 2 do
			local code = sub(input, i, i+1)
			local lastStr = basedictdecompress[last] or dict[last]
			if not lastStr then
				return nil, "could not find last from dict. Invalid input?"
			end
			local toAdd = basedictdecompress[code] or dict[code]
			if toAdd then
				result[n] = toAdd
				n = n+1
				dict, a, b = dictAddB(lastStr..sub(toAdd, 1, 1), dict, a, b)
			else
				local tmp = lastStr..sub(lastStr, 1, 1)
				result[n] = tmp
				n = n+1
				dict, a, b = dictAddB(tmp, dict, a, b)
			end
			last = code
		end
		return tconcat(result)
	end

	return {
		compress = compress,
		decompress = decompress,
	}
end)()

local msgpack = (function()
	local function utf8len(s)
		local _, count = s:gsub('[^\128-\193]', '')
		return count
	end
	local pack, unpack = string.pack, string.unpack
	local tconcat, tunpack = table.concat, table.unpack
	local ssub = string.sub
	local type, pcall, pairs, select = type, pcall, pairs, select


	--[[----------------------------------------------------------------------------

			Encoder

	--]]----------------------------------------------------------------------------
	local encode_value -- forward declaration

	local function is_an_array(value)
		local expected = 1
		for k in pairs(value) do
			if k ~= expected then
				return false
			end
			expected = expected + 1
		end
		return true
	end

	local encoder_functions = {
		['nil'] = function()
			return pack('B', 0xc0)
		end,
		['boolean'] = function(value)
			if value then
				return pack('B', 0xc3)
			else
				return pack('B', 0xc2)
			end
		end,
		['number'] = function(value)
			if type(n) == "number" and n % 1 == 0 then
				if value >= 0 then
					if value < 128 then
						return pack('B', value)
					elseif value <= 0xff then
						return pack('BB', 0xcc, value)
					elseif value <= 0xffff  then
						return pack('>BI2', 0xcd, value)
					elseif value <= 0xffffffff then
						return pack('>BI4', 0xce, value)
					else
						return pack('>BI8', 0xcf, value)
					end
				else
					if value >= -32 then
						return pack('B', 0xe0 + (value + 32))
					elseif value >= -128 then
						return pack('Bb', 0xd0, value)
					elseif value >= -32768 then
						return pack('>Bi2', 0xd1, value)
					elseif value >= -2147483648 then
						return pack('>Bi4', 0xd2, value)
					else
						return pack('>Bi8', 0xd3, value)
					end
				end
			else
				local test = unpack('f', pack('f', value))
				if test == value then -- check if we can use float
					return pack('>Bf', 0xca, value)
				else
					return pack('>Bd', 0xcb, value)
				end
			end
		end,
		['string'] = function(value)
			local len = #value
			if utf8len(value) then -- check if it is a real utf8 string or just byte junk
				if len < 32 then
					return pack('B', 0xa0 + len) .. value
				elseif len < 256 then
					return pack('>Bs1', 0xd9, value)
				elseif len < 65536 then
					return pack('>Bs2', 0xda, value)
				else
					return pack('>Bs4', 0xdb, value)
				end
			else -- encode it as byte-junk :)
				if len < 256 then
					return pack('>Bs1', 0xc4, value)
				elseif len < 65536 then
					return pack('>Bs2', 0xc5, value)
				else
					return pack('>Bs4', 0xc6, value)
				end
			end
		end,
		['table'] = function(value)
			if is_an_array(value) then -- it seems to be a proper Lua array
				local elements = {}
				for i, v in ipairs(value) do
					elements[i] = encode_value(v)
				end

				local length = #elements
				if length < 16 then
					return pack('>B', 0x90 + length) .. tconcat(elements)
				elseif length < 65536 then
					return pack('>BI2', 0xdc, length) .. tconcat(elements)
				else
					return pack('>BI4', 0xdd, length) .. tconcat(elements)
				end
			else -- encode as a map
				local elements = {}
				for k, v in pairs(value) do
					elements[#elements + 1] = encode_value(k)
					elements[#elements + 1] = encode_value(v)
				end

				local length = #elements // 2
				if length < 16 then
					return pack('>B', 0x80 + length) .. tconcat(elements)
				elseif length < 65536 then
					return pack('>BI2', 0xde, length) .. tconcat(elements)
				else
					return pack('>BI4', 0xdf, length) .. tconcat(elements)
				end
			end
		end,
	}

	encode_value = function(value)
		return encoder_functions[type(value)](value)
	end

	local function encode(...)
		local data = {}
		for i = 1, select('#', ...) do
			data[#data + 1] = encode_value(select(i, ...))
		end
		return tconcat(data)
	end


	--[[----------------------------------------------------------------------------

			Decoder

	--]]----------------------------------------------------------------------------
	local decode_value -- forward declaration

	local function decode_array(data, position, length)
		local elements, value = {}
		for i = 1, length do
			value, position = decode_value(data, position)
			elements[i] = value
		end
		return elements, position
	end

	local function decode_map(data, position, length)
		local elements, key, value = {}
		for i = 1, length do
			key, position = decode_value(data, position)
			value, position = decode_value(data, position)
			elements[key] = value
		end
		return elements, position
	end

	local decoder_functions = {
		[0xc0] = function(data, position)
			return nil, position
		end,
		[0xc2] = function(data, position)
			return false, position
		end,
		[0xc3] = function(data, position)
			return true, position
		end,
		[0xc4] = function(data, position)
			return unpack('>s1', data, position)
		end,
		[0xc5] = function(data, position)
			return unpack('>s2', data, position)
		end,
		[0xc6] = function(data, position)
			return unpack('>s4', data, position)
		end,
		[0xca] = function(data, position)
			return unpack('>f', data, position)
		end,
		[0xcb] = function(data, position)
			return unpack('>d', data, position)
		end,
		[0xcc] = function(data, position)
			return unpack('>B', data, position)
		end,
		[0xcd] = function(data, position)
			return unpack('>I2', data, position)
		end,
		[0xce] = function(data, position)
			return unpack('>I4', data, position)
		end,
		[0xcf] = function(data, position)
			return unpack('>I8', data, position)
		end,
		[0xd0] = function(data, position)
			return unpack('>b', data, position)
		end,
		[0xd1] = function(data, position)
			return unpack('>i2', data, position)
		end,
		[0xd2] = function(data, position)
			return unpack('>i4', data, position)
		end,
		[0xd3] = function(data, position)
			return unpack('>i8', data, position)
		end,
		[0xd9] = function(data, position)
			return unpack('>s1', data, position)
		end,
		[0xda] = function(data, position)
			return unpack('>s2', data, position)
		end,
		[0xdb] = function(data, position)
			return unpack('>s4', data, position)
		end,
		[0xdc] = function(data, position)
			local length
			length, position = unpack('>I2', data, position)
			return decode_array(data, position, length)
		end,
		[0xdd] = function(data, position)
			local length
			length, position = unpack('>I4', data, position)
			return decode_array(data, position, length)
		end,
		[0xde] = function(data, position)
			local length
			length, position = unpack('>I2', data, position)
			return decode_map(data, position, length)
		end,
		[0xdf] = function(data, position)
			local length
			length, position = unpack('>I4', data, position)
			return decode_map(data, position, length)
		end,
	}

	-- add fix-array, fix-map, fix-string, fix-int stuff
	for i = 0x00, 0x7f do
		decoder_functions[i] = function(data, position)
			return i, position
		end
	end
	for i = 0x80, 0x8f do
		decoder_functions[i] = function(data, position)
			return decode_map(data, position, i - 0x80)
		end
	end
	for i = 0x90, 0x9f do
		decoder_functions[i] = function(data, position)
			return decode_array(data, position, i - 0x90)
		end
	end
	for i = 0xa0, 0xbf do
		decoder_functions[i] = function(data, position)
			local length = i - 0xa0
			return ssub(data, position, position + length - 1), position + length
		end
	end
	for i = 0xe0, 0xff do
		decoder_functions[i] = function(data, position)
			return -32 + (i - 0xe0), position
		end
	end

	decode_value = function(data, position)
		local byte, value
		byte, position = unpack('B', data, position)
		value, position = decoder_functions[byte](data, position)
		return value, position
	end


	--[[----------------------------------------------------------------------------

			Interface

	--]]----------------------------------------------------------------------------
	return {
		-- primary encode function
		encode = function(...)
			local data, ok = {}
			for i = 1, select('#', ...) do
				ok, data[i] = pcall(encode_value, select(i, ...))
				if not ok then
					return nil, 'cannot encode MessagePack'
				end
			end
			return tconcat(data)
		end,

		-- encode just one value
		encode_one = function(value)
			local ok, data = pcall(encode_value, value)
			if ok then
				return data
			else
				return nil, 'cannot encode MessagePack'
			end
		end,

		-- primary decode function
		decode = function(data, position)
			local values, value, ok = {}
			position = position or 1
			while position <= #data do
				ok, value, position = pcall(decode_value, data, position)
				if ok then
					values[#values + 1] = value
				else
					return nil, 'cannot decode MessagePack'
				end
			end
			return tunpack(values)
		end,

		-- decode just one value
		decode_one = function(data, position)
			local value, ok
			ok, value, position = pcall(decode_value, data, position or 1)
			if ok then
				return value, position
			else
				return nil, 'cannot decode MessagePack'
			end
		end,
	}

	--[[----------------------------------------------------------------------------
	--]]----------------------------------------------------------------------------
end)()

local function sortPlotData(plotData)
    local temp = plotData.Furniture
    table.sort(temp, function(a, b)
        local aPos = a.Position
        local bPos = b.Position
    
        if aPos[1] ~= bPos[1] then
            return aPos[1] < bPos[1]
        elseif aPos[2] ~= bPos[2] then
            return aPos[2] < bPos[2]
        else
            return aPos[3] < bPos[3]
        end
    end)
    plotData.Furniture = temp
    temp = plotData.Paintables
    table.sort(temp, function(a, b)
        return a.Name < b.Name
    end)
    plotData.Paintables=temp

    return plotData
end

local function Color3ToRGBTable(color)
	return {
		["R"]=math.floor(color.R * 255),
		["G"]=math.floor(color.G * 255),
		["B"]=math.floor(color.B * 255)
	}
end

local HttpService = game:GetService("HttpService")

local function vanguardPlotToAnomiss(plotData)
    if not plotData["data"] then
        writefile("TEMP.json", HttpService:JSONEncode(plotData))
    end
    local newPlotData = {
		["Info"] = {
			["Type"]=plotData["data"]["name"],
			["Owner"]="Converted From Vanguard",
			["OwnerID"]=0
		},
		["Furniture"] = {},
		["Paintables"] = {}
	}

    for i,furn in pairs(plotData["data"]["furniture"]) do
        local FurnitureData = {
			["Name"]=furn["name"],
			["Position"]= {CFrame.new(table.unpack(furn["cframe"])):GetComponents()},
			["Information"] = {
				["Color"] = Color3ToRGBTable(Color3.new(furn["color"].R,furn["color"].G,furn["color"].B)),
				["Material"] = furn["material"]
			}
		}

        for k, v in pairs(furn["extrainfo"]) do FurnitureData["Information"][k] = v end

        newPlotData["Furniture"][#newPlotData["Furniture"]+1] = FurnitureData
    end

    for i,paintable in pairs(plotData["data"]["wallcolors"]) do
        newPlotData["Paintables"][paintable["name"]] = {
            ["Color"] = Color3ToRGBTable(Color3.new(paintable.color.R,paintable.color.G,paintable.color.B)),
            ["Material"] = paintable["material"]
        }
    end

    return newPlotData
end

local plotlocations = {
	workspace.PlayerPlots,
	workspace.GarageStorage
}

local UserInputService = game:GetService("UserInputService")
local hwid = gethwid()

local function bulkUpload(SaveUnpackedPlot)
    local bulkUploadObject = {}

    for _, plotfolder in pairs(plotlocations) do
        for _, plot in pairs(plotfolder:GetDescendants()) do
            if plot:FindFirstChild("OwnerBox") and plot.Properties.Owner.Value ~= "NA" then
                if not plot:FindFirstChild("Floor1") then continue end
                local plotData = sortPlotData(vanguardPlotToAnomiss(SaveUnpackedPlot(true,plot,nil,true)))
                
                local encodedPlotData = lzw.compress(msgpack.encode(plotData))
                bulkUploadObject[#bulkUploadObject+1] = {
                    PlotOwner = plotData.Info.OwnerID,
                    PlotType = plotData.Info.Type,
                    ScriptKey = hwid,
                    PlotData = buffer.tostring(base64.encode(buffer.fromstring(encodedPlotData)))
                }
            end
        end
    end

    local response = request({
        Url = "https://anomiss-backend.commandblock644.workers.dev/bulkUpload",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = buffer.tostring(base64.encode(buffer.fromstring(lzw.compress(HttpService:JSONEncode(bulkUploadObject)))))
    })
end

local IsWindowFocused = true

UserInputService.WindowFocused:Connect(function()
	IsWindowFocused = true
end)
UserInputService.WindowFocusReleased:Connect(function()
	IsWindowFocused = false
end)

return function (SaveUnpackedPlot)
    task.spawn(function()
        while true do
            if not IsWindowFocused then
                repeat
                    wait(10)
                until IsWindowFocused
            end
            bulkUpload(SaveUnpackedPlot)
            wait(120)
        end
    end)
end
