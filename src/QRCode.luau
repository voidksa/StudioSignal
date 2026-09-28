-- Byte-mode QR version 5-L: one data block, 108 data and 26 parity bytes.
-- A fixed size keeps the sign-in renderer small and avoids image permissions.
local QRCode = {}
local SIZE, DATA, PARITY = 37, 108, 26
local function multiply(a, b)
    local result = 0
    for _ = 1, 8 do
        if bit32.band(b, 1) ~= 0 then
            result = bit32.bxor(result, a)
        end
        b = bit32.rshift(b, 1)
        a = bit32.lshift(a, 1)
        if a >= 256 then
            a = bit32.bxor(a, 0x11D)
        end
    end
    return result
end

local function codewords(text)
    local bits = {}
    local function append(value, count)
        for i = count - 1, 0, -1 do
            table.insert(bits, bit32.band(bit32.rshift(value, i), 1))
        end
    end
    append(4, 4)
    append(#text, 8)
    for i = 1, #text do
        append(string.byte(text, i), 8)
    end
    append(0, math.min(4, DATA * 8 - #bits))
    while #bits % 8 ~= 0 do
        table.insert(bits, 0)
    end
    local words = {}
    for i = 1, #bits, 8 do
        local value = 0
        for j = 0, 7 do
            value = value * 2 + bits[i + j]
        end
        table.insert(words, value)
    end
    local pad = 236
    while #words < DATA do
        table.insert(words, pad)
        pad = pad == 236 and 17 or 236
    end
    local generator, root = { 1 }, 1
    for _ = 1, PARITY do
        local nextPoly = table.create(#generator + 1, 0)
        for i, value in generator do
            nextPoly[i] = bit32.bxor(nextPoly[i], value)
            nextPoly[i + 1] = bit32.bxor(nextPoly[i + 1], multiply(value, root))
        end
        generator, root = nextPoly, multiply(root, 2)
    end
    local divided = table.clone(words)
    for _ = 1, PARITY do
        table.insert(divided, 0)
    end
    for i = 1, DATA do
        local factor = divided[i]
        for j, coefficient in generator do
            divided[i + j - 1] = bit32.bxor(divided[i + j - 1], multiply(coefficient, factor))
        end
    end
    for i = DATA + 1, DATA + PARITY do
        table.insert(words, divided[i])
    end
    return words
end

function QRCode.encode(text)
    if type(text) ~= "string" or #text == 0 or #text > 106 then
        return nil
    end
    local cells, reserved = {}, {}
    for y = 1, SIZE do
        cells[y], reserved[y] = table.create(SIZE, false), table.create(SIZE, false)
    end
    local function set(x, y, dark)
        if x >= 0 and y >= 0 and x < SIZE and y < SIZE then
            cells[y + 1][x + 1], reserved[y + 1][x + 1] = dark, true
        end
    end
    local function finder(cx, cy)
        for dy = -4, 4 do
            for dx = -4, 4 do
                local distance = math.max(math.abs(dx), math.abs(dy))
                set(cx + dx, cy + dy, distance ~= 2 and distance ~= 4)
            end
        end
    end
    finder(3, 3)
    finder(SIZE - 4, 3)
    finder(3, SIZE - 4)
    for i = 8, SIZE - 9 do
        set(i, 6, i % 2 == 0)
        set(6, i, i % 2 == 0)
    end
    for dy = -2, 2 do
        for dx = -2, 2 do
            set(30 + dx, 30 + dy, math.max(math.abs(dx), math.abs(dy)) ~= 1)
        end
    end
    -- Level L, mask 0. BCH format information, including the fixed XOR mask.
    local data, remainder = 8, 8
    for _ = 1, 10 do
        remainder = bit32.bxor(bit32.lshift(remainder, 1), bit32.rshift(remainder, 9) * 0x537)
    end
    local format = bit32.bxor(bit32.bor(bit32.lshift(data, 10), remainder), 0x5412)
    local function bit(i)
        return bit32.band(bit32.rshift(format, i), 1) ~= 0
    end
    for i = 0, 5 do
        set(8, i, bit(i))
    end
    set(8, 7, bit(6))
    set(8, 8, bit(7))
    set(7, 8, bit(8))
    for i = 9, 14 do
        set(14 - i, 8, bit(i))
    end
    for i = 0, 7 do
        set(SIZE - 1 - i, 8, bit(i))
    end
    for i = 8, 14 do
        set(8, SIZE - 15 + i, bit(i))
    end
    set(8, SIZE - 8, true)
    local words = codewords(text)
    local cursor, right, upward = 0, SIZE - 1, true
    while right >= 1 do
        if right == 6 then
            right = 5
        end
        for row = 0, SIZE - 1 do
            local y = upward and SIZE - 1 - row or row
            for dx = 0, 1 do
                local x = right - dx
                if not reserved[y + 1][x + 1] then
                    local word = words[math.floor(cursor / 8) + 1] or 0
                    local dark = bit32.band(bit32.rshift(word, 7 - cursor % 8), 1) ~= 0
                    cells[y + 1][x + 1] = dark ~= ((x + y) % 2 == 0)
                    cursor += 1
                end
            end
        end
        right, upward = right - 2, not upward
    end
    return cells
end

function QRCode.draw(parent, text)
    parent:ClearAllChildren()
    local cells = QRCode.encode(text)
    if not cells then
        return false
    end
    local scale, quiet = 5, 4
    parent.Size = UDim2.fromOffset((SIZE + quiet * 2) * scale, (SIZE + quiet * 2) * scale)
    parent.BackgroundColor3 = Color3.new(1, 1, 1)
    for y, row in cells do
        local x = 1
        while x <= SIZE do
            if row[x] then
                local start = x
                while x <= SIZE and row[x] do
                    x += 1
                end
                local run = Instance.new("Frame")
                run.BorderSizePixel = 0
                run.BackgroundColor3 = Color3.new(0, 0, 0)
                run.Position =
                    UDim2.fromOffset((start - 1 + quiet) * scale, (y - 1 + quiet) * scale)
                run.Size = UDim2.fromOffset((x - start) * scale, scale)
                run.Parent = parent
            else
                x += 1
            end
        end
    end
    return true
end
return QRCode
