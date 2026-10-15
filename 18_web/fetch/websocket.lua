-- The server side of WebSocket (RFC 6455), small enough to read: the handshake's answer, and the frames that carry messages.
-- The plugin's echo server uses it over a net connection; on the client side, web.socket does all of this with libcurl.

local websocket = {}

-- the text that the handshake joins to the client's key, which the RFC fixes
local GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

-- SHA-1 of a text, as 20 bytes; the handshake proves it understood the request with it
local function sha1(text)
  local function rotate(x, n)
    return ((x << n) | (x >> (32 - n))) & 0xFFFFFFFF
  end

  -- the text, a 1 bit, zeros, and its length in bits, to a whole number of 64-byte blocks
  local padded = text .. "\128" .. ("\0"):rep((55 - #text) % 64) .. string.pack(">I8", #text * 8)
  local h0, h1, h2, h3, h4 = 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0

  for block = 1, #padded, 64 do
    local w = { string.unpack(">" .. ("I4"):rep(16), padded, block) }

    for i = 17, 80 do
      w[i] = rotate(w[i - 3] ~ w[i - 8] ~ w[i - 14] ~ w[i - 16], 1)
    end

    local a, b, c, d, e = h0, h1, h2, h3, h4

    for i = 1, 80 do
      local f, k

      if i <= 20 then
        f, k = (b & c) | (~b & d), 0x5A827999
      elseif i <= 40 then
        f, k = b ~ c ~ d, 0x6ED9EBA1
      elseif i <= 60 then
        f, k = (b & c) | (b & d) | (c & d), 0x8F1BBCDC
      else
        f, k = b ~ c ~ d, 0xCA62C1D6
      end

      a, b, c, d, e = (rotate(a, 5) + (f & 0xFFFFFFFF) + e + k + w[i]) & 0xFFFFFFFF, a, rotate(b, 30), c, d
    end

    h0, h1, h2, h3, h4 = (h0 + a) & 0xFFFFFFFF, (h1 + b) & 0xFFFFFFFF, (h2 + c) & 0xFFFFFFFF, (h3 + d) & 0xFFFFFFFF, (h4 + e) & 0xFFFFFFFF
  end

  return string.pack(">I4I4I4I4I4", h0, h1, h2, h3, h4)
end

local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64(bytes)
  local out = {}

  for i = 1, #bytes, 3 do
    local a, b, c = bytes:byte(i, i + 2)
    local n = (a << 16) | ((b or 0) << 8) | (c or 0)

    for j = 0, 3 do
      local index = (n >> (18 - 6 * j)) & 63
      out[#out + 1] = (j < 2 or (j == 2 and b) or (j == 3 and c)) and ALPHABET:sub(index + 1, index + 1) or "="
    end
  end

  return table.concat(out)
end

-- the answer to a request that asks for a WebSocket, or nil for one that does not
function websocket.handshake(request)
  local key = request:match("\r\n[Ss]ec%-[Ww]eb[Ss]ocket%-[Kk]ey:%s*(%S+)")

  if not key or not request:lower():find("\r\nupgrade:%s*websocket") then
    return nil
  end

  return "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n" ..
      "Sec-WebSocket-Accept: " .. base64(sha1(key .. GUID)) .. "\r\n\r\n"
end

-- the opcodes of the frames this server knows
websocket.TEXT, websocket.BINARY, websocket.CLOSE, websocket.PING, websocket.PONG = 1, 2, 8, 9, 10

-- takes the first frame from what a client sent: its opcode, its payload and what follows it, or nil while the frame is incomplete
-- a client masks every frame's payload with 4 bytes, which the server takes off; a frame that is not the last of its message is taken as a whole message
function websocket.decode(data)
  if #data < 2 then
    return nil
  end

  local first, second = data:byte(1, 2)
  local length, at = second & 127, 3

  if length == 126 then
    if #data < 4 then
      return nil
    end

    length, at = string.unpack(">I2", data, 3), 5
  elseif length == 127 then
    if #data < 10 then
      return nil
    end

    length, at = string.unpack(">I8", data, 3), 11
  end

  local masked = second & 128 ~= 0
  local mask = masked and data:sub(at, at + 3) or "\0\0\0\0"
  at = at + (masked and 4 or 0)

  if #data < at + length - 1 then
    return nil
  end

  local payload = {}

  for i = 0, length - 1 do
    payload[i + 1] = string.char(data:byte(at + i) ~ mask:byte(i % 4 + 1))
  end

  return first & 15, table.concat(payload), data:sub(at + length)
end

-- a server's frame: a whole message, which a server does not mask
function websocket.encode(opcode, payload)
  local length = #payload
  local head = length < 126 and string.pack("BB", 128 | opcode, length)
      or length < 65536 and string.pack(">BBI2", 128 | opcode, 126, length)
      or string.pack(">BBI8", 128 | opcode, 127, length)
  return head .. payload
end

return websocket
