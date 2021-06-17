-- Simple voxal engine script for the TI-Nspire CX

-- External perlin noise utilities
perlin = {}
perlin.p = {}

-- Hash lookup table as defined by Ken Perlin
-- This is a randomly arranged array of all numbers from 0-255 inclusive
local permutation = {151,160,137,91,90,15,
  131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
  190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
  88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
  77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
  102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
  135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
  5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
  223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
  129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
  251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
  49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
  138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
}

-- p is used to hash unit cube coordinates to [0, 255]
for i=0,255 do
    -- Convert to 0 based index table
    perlin.p[i] = permutation[i+1]
    -- Repeat the array to avoid buffer overflow in hash function
    perlin.p[i+256] = permutation[i+1]
end

function bitand(a,b)
    local p,c=1,0
    while a>0 and b>0 do
        local ra,rb=a%2,b%2
        if ra+rb>1 then c=c+p end
        a,b,p=(a-ra)/2,(b-rb)/2,p*2
    end
    return c
end

-- Return range: [-1, 1]
function perlin:noise(x, y, z)
    y = y or 0
    z = z or 0

    -- Calculate the "unit cube" that the point asked will be located in
    local xi = bitand(math.floor(x),255)
    local yi = bitand(math.floor(y),255)
    local zi = bitand(math.floor(z),255)

    -- Next we calculate the location (from 0 to 1) in that cube
    x = x - math.floor(x)
    y = y - math.floor(y)
    z = z - math.floor(z)

    -- We also fade the location to smooth the result
    local u = self.fade(x)
    local v = self.fade(y)
    local w = self.fade(z)

    -- Hash all 8 unit cube coordinates surrounding input coordinate
    local p = self.p
    local A, AA, AB, AAA, ABA, AAB, ABB, B, BA, BB, BAA, BBA, BAB, BBB
    A   = p[xi  ] + yi
    AA  = p[A   ] + zi
    AB  = p[A+1 ] + zi
    AAA = p[ AA ]
    ABA = p[ AB ]
    AAB = p[ AA+1 ]
    ABB = p[ AB+1 ]

    B   = p[xi+1] + yi
    BA  = p[B   ] + zi
    BB  = p[B+1 ] + zi
    BAA = p[ BA ]
    BBA = p[ BB ]
    BAB = p[ BA+1 ]
    BBB = p[ BB+1 ]

    -- Take the weighted average between all 8 unit cube coordinates
    return self.lerp(w,
        self.lerp(v,
            self.lerp(u,
                self:grad(AAA,x,y,z),
                self:grad(BAA,x-1,y,z)
            ),
            self.lerp(u,
                self:grad(ABA,x,y-1,z),
                self:grad(BBA,x-1,y-1,z)
            )
        ),
        self.lerp(v,
            self.lerp(u,
                self:grad(AAB,x,y,z-1), self:grad(BAB,x-1,y,z-1)
            ),
            self.lerp(u,
                self:grad(ABB,x,y-1,z-1), self:grad(BBB,x-1,y-1,z-1)
            )
        )
    )
end

-- Gradient function finds dot product between pseudorandom gradient vector
-- and the vector from input coordinate to a unit cube vertex
perlin.dot_product = {
    [0x0]=function(x,y,z) return  x + y end,
    [0x1]=function(x,y,z) return -x + y end,
    [0x2]=function(x,y,z) return  x - y end,
    [0x3]=function(x,y,z) return -x - y end,
    [0x4]=function(x,y,z) return  x + z end,
    [0x5]=function(x,y,z) return -x + z end,
    [0x6]=function(x,y,z) return  x - z end,
    [0x7]=function(x,y,z) return -x - z end,
    [0x8]=function(x,y,z) return  y + z end,
    [0x9]=function(x,y,z) return -y + z end,
    [0xA]=function(x,y,z) return  y - z end,
    [0xB]=function(x,y,z) return -y - z end,
    [0xC]=function(x,y,z) return  y + x end,
    [0xD]=function(x,y,z) return -y + z end,
    [0xE]=function(x,y,z) return  y - x end,
    [0xF]=function(x,y,z) return -y - z end
}

function perlin:grad(hash, x, y, z)
    return self.dot_product[bitand(hash,0xF)](x,y,z)
end

-- Fade function is used to smooth final output
function perlin.fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

function perlin.lerp(t, a, b)
    return a + t * (b - a)
end

-- // DATA STRUCTURES \\ --

-- 2x1 Vector
Vec2 = class()

function Vec2:init(x, y)
	if x == nil then error("Tried to create a vector with x component nil")
	elseif y == nil then error("Tried to create a vector with y-component nil")
	end

	o = {}
	setmetatable(o, self)
	self.__index = self
	self[1] = x
	self[2] = y
	return o
end
-----

-- 3x1 Vector
Vec3 = class()

function Vec3:init(x, y, z)
	if x == nil then error("Tried to create a vector with x component nil")
	elseif y == nil then error("Tried to create a vector with y-component nil")
	elseif z == nil then error("Tried to create a vector with z-component nil")
	end

	o = {}
	setmetatable(o, self)
	self.__index = self
	self[1] = x
	self[2] = y
	self[3] = z
	return o
end

function Vec3:clone()
	return Vec3(self[1], self[2], self[3])
end

function Vec3:add(vector)
	return Vec3(
		self[1] + vector[1],
		self[2] + vector[2],
		self[3] + vector[3]
	)
end

function Vec3:sub(vector)
	return Vec3(
		self[1] - vector[1],
		self[2] - vector[2],
		self[3] - vector[3]
	)
end

function Vec3:cross(vector)
	return Vec3(
		self[2] * vector[3] - self[3] * vector[2],
		self[3] * vector[1] - self[1] * vector[3],
		self[1] * vector[2] - self[2] * vector[1]
	)
end

function Vec3:scale(scalar)
	return Vec3(
		scalar * self[1],
		scalar * self[2],
		scalar * self[3]
	)
end

function Vec3:divide(scalar)
	return self:scale(1/scalar)
end

function Vec3:magnitude()
	return math.sqrt(math.pow(self[1], 2) + math.pow(self[2], 2) + math.pow(self[3], 2))
end

function Vec3:dot(vector)
	return self[1] * vector[1] + self[2] * vector[2] + self[3] * vector[3]
end

function Vec3:normalize()
	return self:divide(self:magnitude())
end
-----

-- 4x1 Vector
Vec4 = class()

function Vec4:init(x, y, z, w)
	if x == nil then error("Tried to create a vector with x component nil")
	elseif y == nil then error("Tried to create a vector with y-component nil")
	elseif z == nil then error("Tried to create a vector with z-component nil")
	elseif w == nil then error("Tried to create a vector with w-component nil")
	end

	o = {}
	setmetatable(o, self)
	self.__index = self
	self[1] = x
	self[2] = y
	self[3] = z
	self[4] = w
	return o
end

function Vertex(x, y, z)
	return Vec4(x, y, z, 1)
end

function Point(x, y, z)
	return Vec4(x, y, z, 0)
end

function Vec4:clone()
	return Vec4(self[1], self[2], self[3], self[4])
end

function Vec4:print(name)
	print(name, ":", self[1], self[2], self[3], self[4])
end

function Vec4:add(vector)
	return Vec4(
		self[1] + vector[1],
		self[2] + vector[2],
		self[3] + vector[3],
		self[4] + vector[4]
	)
end

function Vec4:sub(vector)
	return Vec4(
		self[1] - vector[1],
		self[2] - vector[2],
		self[3] - vector[3],
		self[4] - vector[4]
	)
end

function Vec4:cross(vector)
	return Vec4(
		self[2] * vector[3] - self[3] * vector[2],
		self[3] * vector[1] - self[1] * vector[3],
		self[1] * vector[2] - self[2] * vector[1],
		1
	)
end

function Vec4:scale(scalar)
	return Vec4(
		scalar * self[1],
		scalar * self[2],
		scalar * self[3],
		scalar * self[4]
	)
end

function Vec4:divide(scalar)
	return self:scale(1/scalar)
end

function Vec4:magnitude()
	return math.sqrt(math.pow(self[1], 2) + math.pow(self[2], 2) + math.pow(self[3], 2) + math.pow(self[4], 2))
end

function Vec4:dot(vector)
	return self[1] * vector[1] + self[2] * vector[2] + self[3] * vector[3] + self[4] * vector[4]
end

function Vec4:normalize()
	return self:divide(self:magnitude())
end

function Vec4:clip2screen()
	self:print("clip2screen")
	-- divide by homogenous coord
	self:divide(self[4])
	local x = (self[1] + 1) / 2 * WIDTH
	local y = (self[2] + 1) / 2 * HEIGHT
	local result = Vec4(x, HEIGHT - y, self[3], 1)
	result:print("clip2screen result")
	return result
end
-----

-- 2x2 Matrix
Mat2 = class()
function Mat2:init(row0, row1)
	if row0 == nil then error("Tried to create a 2x2 matrix with first row nil")
	elseif row1 == nil then error("Tried to create a 2x2 matrix with second row nil")
	end

	local o = { __index = self }
	setmetatable(o, self)
	self[1] = row0
	self[2] = row1
	return o
end

function Mat2:determ()
	return self[1][1] * self[2][2] - self[1][2] * self[2][1]
end
-----

-- 3x3 Matrix
Mat3 = class()
function Mat3:init(row0, row1, row2)
	if row0 == nil then error("Tried to create a 4x4 matrix with first row nil")
	elseif row1 == nil then error("Tried to create a 4x4 matrix with second row nil")
	elseif row2 == nil then error("Tried to create a 4x4 matrix with third row nil")
	end

	o = {}
	setmetatable(o, self)
	self.__index = self
	self[1] = row0
	self[2] = row1
	self[3] = row2
	return o
end

function Mat3:sub(x, y)
	local result = Mat2(Vec2(0, 0), Vec2(0, 0))
	local vectors = { self[1], self[2], self[3] }
	table.remove(vectors, x)
	for k, v in ipairs(vectors) do
		local vector = { v[1], v[2], v[3] }
		table.remove(vector, y)
		result[k] = Vec2(vector[1], vector[2])
	end
	-- print("Mat2 row", table.concat(result[1], " "))
	return result
end

function Mat3:minor(x, y)
	local result = self:sub(x, y):determ()
	-- print("Result for sub minor", result)
	return result
end

function Mat3:cofactor(x, y)
	local result = self:minor(x, y) * ((x + y) % 2 == 0 and 1 or -1)
	-- print("Result for sub cofactor", result)
	return result
end

function Mat3:determ()
	local row = self[1]
	local result = 0
	for x, r in ipairs(row) do
		result = result + r * self:cofactor(1, x)
	end
	return result
end

function Mat3:identity()
	return Mat3(
		Vec4(1, 0, 0),
		Vec4(0, 1, 0),
		Vec4(0, 0, 1)
	)
end

function Mat3:rotationZ(theta)
	local sinTheta = math.sin(theta)
	local cosTheta = math.cos(theta)
	return Mat3(
		Vec3( cosTheta, -sinTheta, 0),
		Vec3( sinTheta,  cosTheta, 0),
		Vec3( 0,          0,       1)
	)
end

function Mat3:rotationY(theta)
	local sinTheta = math.sin(theta)
	local cosTheta = math.cos(theta)
	return Mat3(
		Vec3(cosTheta, 0,  sinTheta),
		Vec3(0,         1,  0),
		Vec3(-sinTheta, 0,  cosTheta)
	)
end

function Mat3:rotationX(theta)
	local sinTheta = math.sin(theta)
	local cosTheta = math.cos(theta)
	return Mat3(
		Vec3(1,  0,          0),
		Vec3(0,  cosTheta, -sinTheta),
		Vec3(0,  sinTheta,  cosTheta)
	)
end

function Mat3:mulMatrix(matrix)
	local result = Mat3(matrix[1], matrix[2], matrix[3])
	for row = 1, 3, 2 do
		for col = 1, 3, 2 do
			result[row][col] = self[row][1] * matrix[1][col]
				+ self[row][2] * matrix[2][col]
				+ self[row][3] * matrix[2][col]
		end
	end
	return result
end

function Mat3:mulVector(vector)
	local result = Vec3(0, 0, 0)
	for row = 1, 3, 2 do
		result[row] = self[row][1] * vector[1]
			+ self[row][2] * vector[2]
			+ self[row][3] * vector[3]
	end
	return result
end
-----

-- 4x4 Matrix
Mat4 = class()
function Mat4:init(row0, row1, row2, row3)
	if row0 == nil then error("Tried to create a 4x4 matrix with first row nil")
	elseif row1 == nil then error("Tried to create a 4x4 matrix with second row nil")
	elseif row2 == nil then error("Tried to create a 4x4 matrix with third row nil")
	elseif row3 == nil then error("Tried to create a 4x4 matrix with fourth row nil")
	end

	o = {}
	setmetatable(o, self)
	self.__index = self
	self[1] = row0
	self[2] = row1
	self[3] = row2
	self[4] = row3
	return o
end

function Mat4:sub(x, y)
	local vectors = { self[1]:clone(), self[2]:clone(), self[3]:clone(), self[4]:clone() }
	table.remove(vectors, x)
	local result = Mat3(Vec3(0, 0, 0), Vec3(0, 0, 0), Vec3(0, 0, 0))
	for k, v in ipairs(vectors) do
		v = { v[1], v[2], v[3], v[4] }
		table.remove(v, y)
		result[k] = Vec3(v[1], v[2], v[3])
	end
	return result
end

function Mat4:minor(x, y)
	return self:sub(x, y):determ()
end

function Mat4:cofactor(x, y)
	return self:minor(x, y) * ((x + y) % 2 == 0 and 1 or -1)
end

function Mat4:determ()
	local row = self[1]
	local result = 0
	for x, v in ipairs(row) do
		result = result + v * self:cofactor(1, x)
	end
	return result
end

function Mat4:invert()
	local determ = self:determ()
	if determ == 0 then
		error("Cannot invert a matrix with a determinant of 0")
	end
	local result = Mat4:identity()
	for row = 1, 4, 1 do
		for col = 1, 4, 1 do
			local c = self:cofactor(row, col)
			result[col][row] = c / determ
		end
	end
	return result
end

function Mat4:identity()
	return Mat4(
		Vec4(1, 0, 0, 0),
		Vec4(0, 1, 0, 0),
		Vec4(0, 0, 1, 0),
		Vec4(0, 0, 0, 1)
	)
end

function Mat4:mulMatrix(matrix)
	local result = Mat4(matrix[1], matrix[2], matrix[3], matrix[4])
	for row = 1, 4, 1 do
		for col = 1, 4, 1 do
			result[row][col] = self[row][1] * matrix[1][col]
				+ self[row][2] * matrix[2][col]
				+ self[row][3] * matrix[3][col]
				+ self[row][4] * matrix[4][col]
		end
	end
	return result
end

function Mat4:mulVector(vector)
	local result = Vec4(0, 0, 0, 0)
	for row = 1, 4, 1 do
		result[row] = self[row][1] * vector[1]
			+ self[row][2] * vector[2]
			+ self[row][3] * vector[3]
			+ self[row][4] * vector[4]
	end
	return result
end

function Mat4:rotationZ(theta)
	theta = theta * math.pi / 180
	local sinTheta = math.sin(theta)
	local cosTheta = math.cos(theta)
	return Mat4(
		Vec4( cosTheta, -sinTheta, 0, 0),
		Vec4( sinTheta,  cosTheta, 0, 0),
		Vec4( 0,          0,       1, 0),
		Vec4( 0,          0,       0, 1)
	)
end

function Mat4:rotationY(theta)
	theta = theta * math.pi / 180
	local sinTheta = math.sin(theta)
	local cosTheta = math.cos(theta)
	return Mat4(
		Vec4(cosTheta, 0, -sinTheta, 0),
		Vec4(       0, 1,         0, 0),
		Vec4(sinTheta, 0,  cosTheta, 0),
		Vec4(       0, 0,         0, 1)
	)
end

function Mat4:rotationX(theta)
	theta = theta * math.pi / 180
	local sinTheta = math.sin(theta)
	local cosTheta = math.cos(theta)
	return Mat4(
		Vec4(1,        0,         0, 0),
		Vec4(0, cosTheta, -sinTheta, 0),
		Vec4(0, sinTheta,  cosTheta, 0),
		Vec4(0,        0,         0, 1)
	)
end

function Mat4:worldToScreen()
	-- combines projection and viewport-to-canvas
	local d = 1
	local viewportWidth = 1
	local viewportHeight = 1
	return Mat4(
		Vec4(d * WIDTH / viewportWidth, 0, 0, WIDTH),
		Vec4(0, d * HEIGHT / viewportHeight, 0, HEIGHT),
		Vec4(0, 0, 1, 0),
		Vec4(0, 0, 0, 1)
	)
end

function Mat4:scale(x, y, z)
	return Mat4(
		Vec4(x, 0, 0, 0),
		Vec4(0, y, 0, 0),
		Vec4(0, 0, z, 0),
		Vec4(0, 0, 0, 1)
	)
end

function Mat4:toVector()
	-- divide by homogenous coordinate
	return Vec3(self[1][1] / self[4][1], self[2][1] / self[4][1], self[3][1] / self[4][1])
end

function Mat4:fromVector(vector)
	local result = Mat4:identity()
	result[1][1] = vector[1]
	result[2][1] = vector[2]
	result[3][1] = vector[3]
	result[4][1] = 1
	return result
end

function Mat4:translation(x, y, z)
	return Mat4(
		Vec4(1, 0, 0, x),
		Vec4(0, 1, 0, y),
		Vec4(0, 0, 1, z),
		Vec4(0, 0, 0, 1)
	)
end

function Mat4:camera(position, orientation)
	local translation = Mat4:translation(position[1], position[2], position[3])
	local rotation = Mat4:rotationX(orientation[1])
		:mulMatrix(Mat4:rotationY(orientation[2])
		:mulMatrix(Mat4:rotationZ(orientation[3])))
	-- invert transform matrices before multiplying to move the scene itself
	return rotation:invert():mulMatrix(translation:invert())
end
-----

-- Texture
Texture = class()
function Texture:init(width, height, data)
	if width == nil then error("Nil width for Texture")
	elseif height == nil then error("Nil height for Texture")
	elseif data == nil then error("Nil data for Texture")
	end

	local o = { __index = self }
	setmetatable(o, self)
	self.width = width
	self.height = height
	self.data = data
	return o
end

function clamp(x, min, max)
	return math.min(math.max(x, min), max)
end

-- get texel from texture in range [0, 1]
-- 0, 0 is bottom-left, 1, 1 is top-right
function Texture:get(x, y)
	x = clamp(math.floor(x * self.width), 0, self.width)
	y = clamp(math.floor((1 - y) * self.height), 0, self.height)
	local index = y * self.height * 3 + x * 3 + 1
	local r = self.data[index]
	local g = self.data[index + 1]
	local b = self.data[index + 2]
	return Vec3(r / 255, g / 255, b / 255)
end
-----

-- Constants
WIDTH = platform.window:width()     -- 318
HEIGHT = platform.window:height()   -- 212
RED = Vec3(1, 0, 0)
GREEN = Vec3(0, 1, 0)
BLUE = Vec3(0, 0, 1)
PURPLE = Vec3(1, 0, 1)
CYAN = Vec3(0, 1, 1)
YELLOW = Vec3(1, 1, 0)
INF = 1/0

-- Textures
GRASS = Texture(15, 15, { 113,168,36,134,188,57,113,168,36,134,188,57,134,188,57,113,168,36,113,168,36,113,168,36,134,188,57,113,168,36,113,168,36,151,212,66,151,212,66,134,188,57,113,168,36,113,168,36,113,168,36,133,187,56,136,180,75,110,165,32,134,179,71,148,209,64,133,187,56,113,168,36,110,165,32,116,171,39,148,209,64,146,207,62,119,175,41,119,175,41,136,190,59,131,185,54,131,185,54,113,168,36,120,175,43,119,170,48,140,193,67,134,176,75,142,93,56,118,173,41,111,167,32,142,195,69,112,167,35,124,182,42,159,119,88,111,166,34,107,161,31,119,174,42,119,174,42,132,186,54,141,101,70,141,101,70,159,113,77,144,198,68,131,117,107,133,92,61,124,179,46,125,173,58,133,89,55,111,166,34,122,170,55,133,89,55,111,166,34,142,93,56,142,93,56,111,166,34,159,119,88,142,93,56,150,104,68,150,104,68,142,93,56,135,86,48,135,86,48,150,104,68,150,104,68,131,117,107,133,89,55,135,86,48,159,119,88,150,104,68,150,104,68,149,132,119,141,101,70,159,113,77,159,119,88,141,101,70,142,93,56,142,93,56,133,92,61,135,86,48,135,86,48,133,89,55,133,89,55,142,93,56,135,86,48,133,92,61,133,92,61,142,93,56,142,93,56,141,101,70,159,113,77,141,101,70,141,101,70,142,93,56,150,104,68,142,93,56,142,93,56,141,101,70,149,132,119,133,89,55,159,119,88,133,92,61,133,92,61,133,92,61,142,93,56,150,104,68,141,101,70,133,89,55,141,101,70,142,93,56,150,104,68,159,119,88,142,93,56,159,113,77,133,92,61,150,104,68,150,104,68,159,119,88,159,119,88,133,89,55,133,89,55,159,113,77,150,104,68,135,86,48,133,92,61,141,101,70,150,104,68,133,92,61,133,89,55,133,89,55,150,104,68,150,104,68,159,113,77,159,119,88,159,119,88,133,92,61,133,89,55,131,117,107,133,92,61,150,104,68,159,113,77,150,104,68,141,101,70,150,104,68,141,101,70,133,89,55,149,132,119,135,86,48,135,86,48,159,113,77,159,113,77,135,86,48,135,86,48,133,89,55,133,89,55,135,86,48,142,93,56,133,89,55,150,104,68,142,93,56,159,113,77,133,92,61,133,89,55,135,86,48,133,92,61,149,132,119,149,132,119,142,93,56,133,92,61,150,104,68,133,89,55,133,89,55,133,92,61,150,104,68,150,104,68,159,113,77,142,93,56,159,113,77,141,101,70,142,93,56,133,92,61,150,104,68,150,104,68,142,93,56,159,113,77,142,93,56,142,93,56,133,89,55,133,92,61,135,86,48,133,92,61,133,92,61,150,104,68,142,93,56,159,113,77,150,104,68,133,89,55,133,89,55,133,89,55,150,104,68,159,119,88,142,93,56,133,89,55,133,89,55,133,89,55,133,92,61,133,92,61,133,92,61,142,93,56,133,92,61,150,104,68,141,101,70,135,86,48,149,132,119,149,132,119,133,89,55,150,104,68,159,113,77,135,86,48,141,101,70,135,118,105,133,89,55,150,104,68,133,89,55,142,93,56,142,93,56,150,104,68,150,104,68,141,101,70,133,92,61,133,92,61,141,101,70,142,93,56,142,93,56,159,119,88,135,86,48,135,86,48,135,86,48,133,92,61,150,104,68,133,89,55,135,118,105,135,86,48,133,92,61,142,93,56,141,101,70 }) 
LEAVES = Texture(15, 15, { 87,146,61,87,146,61,87,146,61,87,146,61,87,146,61,87,146,61,87,146,61,87,146,61,87,146,61,87,146,61,87,146,61,87,146,61,87,146,61,89,153,61,87,146,61,87,146,61,87,146,61,87,146,61,87,146,61,98,156,73,76,130,52,87,146,61,87,146,61,105,167,79,105,167,79,87,146,61,105,167,79,105,167,79,105,167,79,98,156,73,87,146,61,89,142,67,89,142,67,89,153,61,87,146,61,89,142,67,89,142,67,105,167,79,105,167,79,105,167,79,83,149,53,83,149,53,83,149,53,89,142,67,89,142,67,105,167,79,89,153,61,89,153,61,89,153,61,89,153,61,89,153,61,87,146,61,89,142,67,89,142,67,105,167,79,89,153,61,89,142,67,83,149,53,89,153,61,89,153,61,75,133,50,75,133,50,75,133,50,89,153,61,89,153,61,89,153,61,89,153,61,89,153,61,87,146,61,105,167,79,89,142,67,89,153,61,75,133,50,89,153,61,75,133,50,75,133,50,89,153,61,82,151,52,89,153,61,89,153,61,89,153,61,89,153,61,89,153,61,89,153,61,89,153,61,87,146,61,76,130,52,75,133,50,89,153,61,82,151,52,83,149,53,75,133,50,89,153,61,82,151,52,82,151,52,89,153,61,89,153,61,75,133,50,75,133,50,82,151,52,89,153,61,89,153,61,87,146,61,87,146,61,75,133,50,89,153,61,83,149,53,83,149,53,82,151,52,75,133,50,75,133,50,75,133,50,75,133,50,89,153,61,82,151,52,75,133,50,89,153,61,89,153,61,105,167,79,87,146,61,105,167,79,89,153,61,83,149,53,83,149,53,89,153,61,89,153,61,75,133,50,75,133,50,75,133,50,75,133,50,82,151,52,82,151,52,75,133,50,89,153,61,89,153,61,105,167,79,87,146,61,105,167,79,89,153,61,75,133,50,83,149,53,75,133,50,82,151,52,89,153,61,89,153,61,97,158,71,82,151,52,82,151,52,89,153,61,82,151,52,89,153,61,105,167,79,105,167,79,87,146,61,76,130,52,75,133,50,75,133,50,83,149,53,75,133,50,83,149,53,83,149,53,89,153,61,82,151,52,89,153,61,75,133,50,83,149,53,83,149,53,89,153,61,105,167,79,87,146,61,87,146,61,76,130,52,75,133,50,89,153,61,89,153,61,82,151,52,82,151,52,75,133,50,75,133,50,82,151,52,75,133,50,83,149,53,97,158,71,82,151,52,75,133,50,82,151,52,87,146,61,87,146,61,76,130,52,75,133,50,89,153,61,89,153,61,89,153,61,89,153,61,82,151,52,75,133,50,75,133,50,89,153,61,105,167,79,89,153,61,89,153,61,75,133,50,89,153,61,87,146,61,87,146,61,105,167,79,89,142,67,89,142,67,89,142,67,75,133,50,82,151,52,82,151,52,89,153,61,89,153,61,89,142,67,75,133,50,75,133,50,82,151,52,89,142,67,89,153,61,87,146,61,87,146,61,105,167,79,89,142,67,89,142,67,89,142,67,75,133,50,75,133,50,75,133,50,75,133,50,82,151,52,82,151,52,89,153,61,82,151,52,75,133,50,75,133,50,89,153,61,87,146,61,87,146,61,98,156,73,98,156,73,91,160,61,105,167,79,89,153,61,89,153,61,89,153,61,89,153,61,105,167,79,105,167,79,105,167,79,105,167,79,82,151,52,82,151,52,89,153,61,87,146,61,87,146,61 })
DIRT = Texture(15, 15, { 150,104,68,150,104,68,150,104,68,141,101,70,141,101,70,141,101,70,159,113,77,159,113,77,133,89,55,133,89,55,141,101,70,141,101,70,141,101,70,150,104,68,141,101,70,141,101,70,141,101,70,150,104,68,150,104,68,150,104,68,159,113,77,141,101,70,142,93,56,159,119,88,150,104,68,142,93,56,133,89,55,149,132,119,135,86,48,135,86,48,150,104,68,142,93,56,142,93,56,141,101,70,141,101,70,141,101,70,159,113,77,150,104,68,142,93,56,135,86,48,135,86,48,159,113,77,159,113,77,159,119,88,159,119,88,150,104,68,133,89,55,142,93,56,142,93,56,133,92,61,141,101,70,141,101,70,159,113,77,142,93,56,131,117,107,133,92,61,135,86,48,133,92,61,133,89,55,133,89,55,135,86,48,133,89,55,159,119,88,142,93,56,142,93,56,133,92,61,159,119,88,142,93,56,150,104,68,150,104,68,142,93,56,135,86,48,135,86,48,150,104,68,150,104,68,131,117,107,133,89,55,135,86,48,159,119,88,150,104,68,150,104,68,149,132,119,141,101,70,159,113,77,159,119,88,141,101,70,142,93,56,142,93,56,133,92,61,135,86,48,135,86,48,133,89,55,133,89,55,142,93,56,135,86,48,133,92,61,133,92,61,142,93,56,142,93,56,141,101,70,159,113,77,141,101,70,141,101,70,142,93,56,150,104,68,142,93,56,142,93,56,141,101,70,149,132,119,133,89,55,159,119,88,133,92,61,133,92,61,133,92,61,142,93,56,150,104,68,141,101,70,133,89,55,141,101,70,142,93,56,150,104,68,159,119,88,142,93,56,159,113,77,133,92,61,150,104,68,150,104,68,159,119,88,159,119,88,133,89,55,133,89,55,159,113,77,150,104,68,135,86,48,133,92,61,141,101,70,150,104,68,133,92,61,133,89,55,133,89,55,150,104,68,150,104,68,159,113,77,159,119,88,159,119,88,133,92,61,133,89,55,131,117,107,133,92,61,150,104,68,159,113,77,150,104,68,141,101,70,150,104,68,141,101,70,133,89,55,149,132,119,135,86,48,135,86,48,159,113,77,159,113,77,135,86,48,135,86,48,133,89,55,133,89,55,135,86,48,142,93,56,133,89,55,150,104,68,142,93,56,159,113,77,133,92,61,133,89,55,135,86,48,133,92,61,149,132,119,149,132,119,142,93,56,133,92,61,150,104,68,133,89,55,133,89,55,133,92,61,150,104,68,150,104,68,159,113,77,142,93,56,159,113,77,141,101,70,142,93,56,133,92,61,150,104,68,150,104,68,142,93,56,159,113,77,142,93,56,142,93,56,133,89,55,133,92,61,135,86,48,133,92,61,133,92,61,150,104,68,142,93,56,159,113,77,150,104,68,133,89,55,133,89,55,133,89,55,150,104,68,159,119,88,142,93,56,133,89,55,133,89,55,133,89,55,133,92,61,133,92,61,133,92,61,142,93,56,133,92,61,150,104,68,141,101,70,135,86,48,149,132,119,149,132,119,133,89,55,150,104,68,159,113,77,135,86,48,141,101,70,135,118,105,133,89,55,150,104,68,133,89,55,142,93,56,142,93,56,150,104,68,150,104,68,141,101,70,133,92,61,133,92,61,141,101,70,142,93,56,142,93,56,159,119,88,135,86,48,135,86,48,135,86,48,133,92,61,150,104,68,133,89,55,135,118,105,135,86,48,133,92,61,142,93,56,141,101,70 })
GRASS_TOP = Texture(15, 15, { 113,168,36,134,188,57,113,168,36,134,188,57,134,188,57,113,168,36,113,168,36,113,168,36,134,188,57,113,168,36,113,168,36,151,212,66,151,212,66,134,188,57,113,168,36,113,168,36,113,168,36,134,188,57,134,177,74,113,168,36,134,177,74,151,212,66,134,188,57,113,168,36,113,168,36,113,168,36,151,212,66,151,212,66,113,168,36,113,168,36,134,188,57,134,188,57,134,188,57,113,168,36,113,168,36,113,168,36,149,201,76,134,177,74,149,201,76,113,168,36,113,168,36,149,201,76,113,168,36,113,168,36,134,188,57,113,168,36,113,168,36,113,168,36,113,168,36,132,187,53,113,168,36,113,168,36,113,168,36,132,187,53,134,177,74,149,201,76,132,187,53,134,177,74,113,168,36,113,168,36,134,177,74,113,168,36,113,168,36,151,212,66,151,212,66,113,168,36,151,212,66,113,168,36,134,188,57,134,188,57,113,168,36,134,177,74,134,177,74,113,168,36,134,177,74,132,187,53,134,188,57,134,177,74,113,168,36,134,177,74,134,177,74,113,168,36,113,168,36,151,212,66,113,168,36,132,187,53,132,187,53,113,168,36,134,188,57,113,168,36,113,168,36,132,187,53,134,177,74,113,168,36,132,187,53,113,168,36,113,168,36,149,201,76,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,132,187,53,113,168,36,132,187,53,113,168,36,113,168,36,134,177,74,134,177,74,113,168,36,149,201,76,113,168,36,149,201,76,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,132,187,53,113,168,36,134,177,74,113,168,36,113,168,36,134,177,74,134,177,74,149,201,76,113,168,36,113,168,36,113,168,36,134,188,57,113,168,36,134,188,57,113,168,36,113,168,36,113,168,36,132,187,53,113,168,36,132,187,53,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,132,187,53,132,187,53,132,187,53,113,168,36,113,168,36,132,187,53,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,134,177,74,113,168,36,132,187,53,113,168,36,132,187,53,132,187,53,113,168,36,113,168,36,132,187,53,113,168,36,113,168,36,113,168,36,113,168,36,149,201,76,149,201,76,149,201,76,113,168,36,113,168,36,113,168,36,132,187,53,132,187,53,149,201,76,113,168,36,113,168,36,113,168,36,113,168,36,132,187,53,113,168,36,113,168,36,113,168,36,113,168,36,134,188,57,134,177,74,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,132,187,53,132,187,53,132,187,53,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,132,187,53,132,187,53,113,168,36,113,168,36,113,168,36,113,168,36,134,188,57,113,168,36,151,212,66,151,212,66,113,168,36,113,168,36,113,168,36,149,201,76,132,187,53,132,187,53,132,187,53,149,201,76,149,201,76,149,201,76,134,177,74,113,168,36,134,188,57,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,113,168,36,151,212,66,113,168,36,113,168,36,134,188,57,113,168,36,134,177,74,113,168,36,134,188,57,134,188,57,113,168,36 })
LOG_SIDE = Texture(15, 15, { 85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43,94,58,48,85,52,43 })
LOG_VERT = Texture(15, 15, { 85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,85,52,43,85,52,43,118,73,60,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,118,73,60,85,52,43,85,52,43,118,73,60,85,52,43,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,85,52,43,118,73,60,85,52,43,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,118,73,60,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,118,73,60,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,118,73,60,85,52,43,118,73,60,85,52,43,85,52,43,118,73,60,85,52,43,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,85,52,43,118,73,60,85,52,43,85,52,43,118,73,60,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,85,52,43,118,73,60,85,52,43,85,52,43,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,118,73,60,85,52,43,85,52,43 })
-----

-- Global Z-Buffer
DEPTH_BUFFER = {} -- depth buffer stores 1/z for each pixel to better account for lerping
-----

function getDepthBuffer(x, y)
	if DEPTH_BUFFER[x] ~= nil then
		if DEPTH_BUFFER[x][y] ~= nil then
			return DEPTH_BUFFER[x][y]
		else
			return -INF
		end
	else
		return -INF
	end
end

function setDepthBuffer(x, y, depth)
	if DEPTH_BUFFER[x] ~= nil then
		DEPTH_BUFFER[x][y] = depth
	else
		local row = {}
		row[y] = depth
		DEPTH_BUFFER[x] = row
	end
end
-----

-- Graphics utils
function setColor(gc, color)
	gc:setColorRGB(math.min(color[1] * 255, 255), math.min(color[2] * 255, 255), math.min(color[3] * 255, 255))
end

function drawText(gc, text, x, y)
	gc:drawString(text, x, HEIGHT - y)
end

function set(gc, x, y)
	gc:fillRect(x, HEIGHT - y, 1, 1)
end
-----

-- returns all values between two endpoints
function interpolate(i0, d0, i1, d1)
	if i0 == i1 then
		return { d0 }
	end
	local values = {}
	local m = (d1 - d0) / (i1 - i0)
	local d = d0
	for _ = i0, i1, 1 do
		table.insert(values, d)
		d = d + m
	end
	return values
end

function edgeInterpolate(y0, v0, y1, v1, y2, v2)
	local v01 = interpolate(y0, v0, y1, v1)
	local v12 = interpolate(y1, v1, y2, v2)
	local v02 = interpolate(y0, v0, y2, v2)
	table.remove(v01)
	local v012 = v01
	for _, v in ipairs(v12) do
		table.insert(v012, v)
	end
	return v02, v012
end

function line(gc, p0, p1)
	local x0, y0 = p0[1], p0[2]
	local x1, y1 = p1[1], p1[2]
	if math.abs(x1 - x0) > math.abs(y1 - y0) then
		-- line is horizontal
		-- make sure x0 < x1
		if x0 > x1 then
			x0, x1 = x1, x0
			y0, y1 = y1, y0
		end
		local ys = interpolate(x0, y0, x1, y1)

		-- print(#ys, "Ys", table.concat(ys, " "))
		for x = x0, x1, 1 do
			local index = math.floor(x - x0 + 1)
			-- print("Index", index)
			set(gc, x, ys[index])
		end
	else
		-- line is vertical
		-- make sure y0 < y1
		if y0 > y1 then
		  x0, x1 = x1, x0
		  y0, y1 = y1, y0
		end
		local xs = interpolate(y0, x0, y1, x1)
		-- print(#xs, "Xs", table.concat(xs, " "))
		for y = y0, y1, 1 do
			local index = math.floor(y - y0 + 1)
			set(gc, xs[index], y)
		end
	end
end

function triangleWireframe(gc, p0, p1, p2)
	line(gc, p0, p1)
	line(gc, p1, p2)
	line(gc, p2, p0)
end

function computeTriangleNormal(v0, v1, v2)
	local v0v1 = v1:add(v0:scale(-1))
	local v0v2 = v2:add(v0:scale(-1))
	return v0v1:cross(v0v2)
end

function triangle(gc, p0, p1, p2, texture, uv0, uv1, uv2)
	-- local normal = computeTriangleNormal(p0, p1, p2)
	-- local center = p0:add(p1):add(p2):scale(-1/3)
	-- if center:dot(normal) < 0 then
	-- 	return
	-- end

	-- gc:fillPolygon({ p0[1], p0[2], p1[1], p1[2], p2[1], p2[2] })
	if p1[2] < p0[2] then p0, p1 = p1, p0; uv0, uv1 = uv1, uv0 end
	if p2[2] < p0[2] then p0, p2 = p2, p0; uv0, uv2 = uv2, uv0 end
	if p2[2] < p1[2] then p2, p1 = p1, p2; uv2, uv1 = uv1, uv2 end

	local x02, x012 = edgeInterpolate(p0[2], p0[1], p1[2], p1[1], p2[2], p2[1])
	local z02, z012 = edgeInterpolate(p0[2], p0[3], p1[2], p1[3], p2[2], p2[3])
	local uz02, uz012 = edgeInterpolate(p0[2], uv0[1], p1[2], uv1[1], p2[2], uv2[1])
	local vz02, vz012 = edgeInterpolate(p0[2], uv0[2], p1[2], uv1[2], p2[2], uv2[2])

	local x_left, x_right
	local z_left, z_right
	local uz_left, uz_right = uz02, uz012
	local vz_left, vz_right = vz012, vz02
	local m = math.min(math.floor(#x02 / 2) + 1, math.min(#x02, #x012))
	if x02[m] < x012[m] then
		x_left, x_right = x02, x012
		z_left, z_right = z02, z012
		uz_left, uz_right = uz02, uz012
		vz_left, vz_right = vz02, vz012
	else
		x_left, x_right = x012, x02
		z_left, z_right = z012, z02
		uz_left, uz_right = uz012, uz02
		vz_left, vz_right = vz012, vz02
	end

	for y = p0[2], p2[2], 1 do
		local index = math.floor(y - p0[2] + 1)
		if index > #x_left or index > #x_right then
			break
		end
		local zSegment = interpolate(x_left[index], z_left[index], x_right[index], z_right[index])
		local uzSegment = interpolate(x_left[index], uz_left[index], x_right[index], uz_right[index])
		local vzSegment = interpolate(x_left[index], vz_left[index], x_right[index], vz_right[index])
		for x = x_left[index], x_right[index], 1 do
			local lerpIndex = math.max(math.floor(x - x_left[index] + 1), 1)
			local z = zSegment[lerpIndex]
			if 1/z > getDepthBuffer(math.floor(x), math.floor(y)) then
				setDepthBuffer(math.floor(x), math.floor(y), 1/z)
				local u = uzSegment[lerpIndex]
				local v = vzSegment[lerpIndex]
				-- get texel color
				local color = texture:get(u, v)
				setColor(gc, color)
				set(gc, x, y)
			end
		end
	end
end

function shadedTriangle(gc, p0, p1, p2, color)
	if p1[2] < p0[2] then p0, p1 = p1, p0 end
	if p2[2] < p0[2] then p0, p2 = p2, p0 end
	if p2[2] < p1[2] then p2, p1 = p1, p2 end

	local x01 = interpolate(p0[2], p0[1], p1[2], p1[1])
	local h01 = interpolate(p0[2], p0[3], p1[2], p1[3])

	local x12 = interpolate(p1[2], p1[1], p2[2], p2[1])
	local h12 = interpolate(p1[2], p1[3], p2[2], p2[3])

	local x02 = interpolate(p0[2], p0[1], p2[2], p2[1])
	local h02 = interpolate(p0[2], p0[3], p2[2], p2[3])

	table.remove(x01)
	table.remove(h01)

	local x012 = x01
	for _, v in pairs(x12) do
		table.insert(x012, v)
	end

	local h012 = h01
	for _, v in pairs(h12) do
		table.insert(h012, v)
	end

	local x_left, x_right
	local h_left, h_right
	local m = math.floor(#x012 / 2)
	if x02[m] < x012[m] then
		x_left = x02
		h_left = h02

		x_right = x012
		h_right = h012
	else
		x_left = x012
		h_left = h012

		x_right = x02
		h_right = h02
	end

	for y = p0[2], p2[2], 1 do
		local index = y - p0[2] + 1
		local x_l = x_left[index]
		local x_r = x_right[index]

		local hSegment = interpolate(x_l, h_left[index], x_r, h_right[index])
		for x = x_l, x_r do
			local idx = x - x_l + 1
			local hCoeff = hSegment[idx]
			if hCoeff == nil then
				local minI = INF
				for i = x_l, x_r do
					local coeff = hSegment[idx - i - 1]
					if coeff ~= nil and i < minI then
						min_i = i
						hCoeff = coeff
					end
				end
				for i = x_l, x_r do
					local coeff = hSegment[idx + i + 1]
					if coeff ~= nil and i < minI then
						minI = i
						hCoeff = coeff
					end
				end
				if hCoeff == nil then
					hCoeff = h_left[index]
				end
			end
			local shadedColor = color:scale(hCoeff)
			setColor(gc, shadedColor)
			set(gc, x, y)
		end
	end
end

function viewportToCanvas(vertex)
	local result = Vec3(vertex[1] * WIDTH + WIDTH / 2, vertex[2] * HEIGHT + HEIGHT / 2, vertex[3])
	return result
end

function projectVector4(vertex)
	return viewportToCanvas(Vec3(vertex[1] / vertex[3] * HEIGHT/WIDTH, vertex[2] / vertex[3], vertex[3]))
end
-----

-- Camera
Camera = class()
function Camera:init(position, front, up, yaw, pitch)
	if position == nil then error("Nil position for Camera")
	elseif yaw == nil then error("Nil yaw for Camera")
	elseif pitch == nil then error("Nil pitch for Camera")
	end

	local o = { __index = self }
	setmetatable(o, self)
	self.position = position
	self.front = front
	self.up = up
	self.yaw = yaw
	self.pitch = pitch
	return o
end

function Camera:getTransform()
	return Mat4:camera(self.position, Vertex(self.pitch, self.yaw, 0))
end

function lookAtDir(eye, dir, up)
	local f = dir:normalize()
	local s = f:cross(up):normalize()
	local u = s:cross(f)

	return Mat4(
		Vec4(s[1], u[1], -f[1], 0),
		Vec4(s[2], u[2], -f[2], 0),
		Vec4(s[3], u[3], -f[3], 0),
		Vec4(-eye:dot(s), -eye:dot(u), eye:dot(f), 1)
	)
end

function Camera:getView()
	return lookAtDir(self.position, self.position:add(self.front), self.up)
end

function Camera:rotate(yaw, pitch)
	self.yaw = self.yaw + yaw
	self.pitch = self.pitch + pitch

	self.front = Mat3:rotationY(self.pitch):mulVector(self.front)
end

function Camera:getFront()
	return self.front
	-- local yaw = self.yaw * math.pi / 180
	-- local pitch = self.pitch * math.pi / 180
	-- return Vec3(math.cos(yaw) * math.cos(pitch), math.sin(pitch), math.sin(yaw) * math.sin(pitch))
end
-----

-- Global camera
camera = Camera(Vec3(0, 2, 0), Vec3(0, 0, 1), nil, -4, 5)
-- camera = Camera(Vec3(0, 0, 0), Vec3(0, 0, 1), Vec3(0, 1, 0), 0, 0)
-----

-- Triangle
Triangle = class()
function Triangle:init(i0, i1, i2, texture, uvs)
	if i0 == nil or i1 == nil or i2 == nil then error("Nil vertex for Triangle")
	elseif uvs == nil then error("Nil uv coords for Triangle")
	end

	local o = { __index = self }
	setmetatable(o, self)
	self.i0 = i0
	self.i1 = i1
	self.i2 = i2
	self.uvs = uvs
	self.texture = texture
	return o
end
----

-- Clipping Plane
Plane = class()
function Plane:init(normal, distance)
	if normal == nil then error("Nil normal for Plane")
	elseif distance == nil then error("Nil distance for Plane")
	end

	local o = { __index = self }
	setmetatable(o, self)
	self.normal = normal
	self.distance = distance
	return o
end
-----

-- Model
Model = class()
function Model:init(vertices, triangles, boundsCenter, boundsRadius)
	if vertices == nil then error("Nil vertices for Model")
	elseif triangles == nil then error("Nil triangles for Model")
	end

	local o = { __index = self }
	setmetatable(o, self)
	self.vertices = vertices
	self.triangles = triangles
	self.boundsCenter = boundsCenter
	self.boundsRadius = boundsRadius
	return o
end

function renderTriangleWireframe(gc, projected, t)
	setColor(gc, t.color)
	local v0, v1, v2 = projected[t.i0], projected[t.i1], projected[t.i2]
	for _, v in ipairs({ v0, v1, v2 }) do
		for _, coord in ipairs(v) do
			if math.abs(coord) == INF then
				error("Tried to render triangle with vertex at infinity")
			end
		end
	end
	triangleWireframe(gc, v0, v1, v2)
end

function renderTriangle(gc, projected, t)
	-- setColor(gc, t.color)
	local v0, v1, v2 = projected[t.i0], projected[t.i1], projected[t.i2]
	for _, v in ipairs({ v0, v1, v2 }) do
		for _, coord in ipairs(v) do
			if math.abs(coord) == INF then
				error("Tried to render triangle with vertex at infinity")
			end
		end
	end
	local uv0, uv1, uv2 = t.uvs[1], t.uvs[2], t.uvs[3]
	triangle(gc, v0, v1, v2, t.texture, uv0, uv1, uv2)
end

function Model:render(gc)
	local projected = {}
	-- project vertices in clip space to screen
	for _, v in ipairs(self.vertices) do
		table.insert(projected, projectVector4(v))
	end
	-- render each triangle using the projected vertices array
	for _, t in ipairs(self.triangles) do
		renderTriangle(gc, projected, t)
		-- renderTriangleWireframe(gc, projected, t)
	end
end
-----

-- Instance
Instance = class()
function Instance:init(model, transform)
	if model == nil then print("Nil model for Instance")
	elseif transform == nil then print("Nil transform matrix for Instance")
	end

	local o = { __index = self }
	setmetatable(o, self)
	self.model = model
	self.transform = transform
	return self
end

function Instance:clone()
	return Instance(self.model:clone(), self.transform:clone())
end

function signedDistance(plane, vertex)
	local normal = plane.normal
	return vertex:dot(normal) + plane.distance
end

function planeIntersection(a, b, plane)
	-- equation for finding t if we define triangle as P = A + t(B - A)
	local t = (-plane.distance - plane.normal:dot(a)) / plane.normal:dot(b:sub(a))
	-- plug t into equation and return resulting intersection point
	return a:add(b:sub(a):scale(t))
end

function addClippedTriangles(newTriangles, triangle, plane, vertices)
	local v0 = vertices[triangle.i0]
	local v1 = vertices[triangle.i1]
	local v2 = vertices[triangle.i2]

	local in0 = signedDistance(plane, v0) > 0 and 1 or 0
	local in1 = signedDistance(plane, v1) > 0 and 1 or 0
	local in2 = signedDistance(plane, v2) > 0 and 1 or 0

	local inCount = in0 + in1 + in2
	if inCount == 0 then
		-- do nothing
	elseif inCount == 3 then
		table.insert(newTriangles, triangle)
	elseif inCount == 1 then
		-- triangle has one vertex in, output is one clipped triangle
		-- let a be the vertex in
		local a, b, c
		if in0 == 1 then a, b, c = triangle.i0, triangle.i1, triangle.i2
		elseif in1 == 1 then a, b, c = triangle.i1, triangle.i0, triangle.i2
		else a, b, c = triangle.i2, triangle.i0, triangle.i1
		end
		local aVert, bVert, cVert = vertices[a], vertices[b], vertices[c]
		local bVertPrime = planeIntersection(aVert, bVert, plane)
		local cVertPrime = planeIntersection(aVert, cVert, plane)
		if aVert[3] == 0 or bVertPrime[3] == 0 or cVertPrime[3] == 0 then
			return nil
		end
		-- add new vertices at intersection to clipped model data for new triangle
		table.insert(vertices, bVertPrime)
		table.insert(vertices, cVertPrime)
		-- add triangle
		table.insert(newTriangles, Triangle(a, #vertices - 1, #vertices, triangle.texture, triangle.uvs))
	elseif inCount == 2 then
		-- triangle has two vertices in, output is two clipped triangles
		-- let c be the vertex out
		local c, b, a
		if in0 == 0 then c, b, a = triangle.i0, triangle.i1, triangle.i2
		elseif in1 == 0 then c, b, a = triangle.i1, triangle.i0, triangle.i2
		else c, b, a = triangle.i2, triangle.i0, triangle.i1
		end
		local aVert, bVert, cVert = vertices[a], vertices[b], vertices[c]
		local aVertPrime = planeIntersection(aVert, cVert, plane)
		local bVertPrime = planeIntersection(bVert, cVert, plane)
		if aVert[3] == 0 or bVert[3] == 0 or aVertPrime[3] == 0 or bVertPrime[3] == 0 then
			return nil
		end
		-- add new vertices at intersection to clipped model data for new triangle
		table.insert(vertices, aVertPrime)
		table.insert(vertices, bVertPrime)
		local aPrimeIndex = #vertices - 1
		local bPrimeIndex = #vertices
		-- add new triangles
		if aVert[3] ~= 0 and bVert[3] ~= 0 and aVertPrime[3] ~= 0 then
			table.insert(newTriangles, Triangle(a, b, aPrimeIndex, triangle.texture, triangle.uvs))
		end
		if aVertPrime[3] ~= 0 and bVert[3] ~= 0 and bVertPrime[3] ~= 0 then
			table.insert(newTriangles, Triangle(aPrimeIndex, b, bPrimeIndex, triangle.texture, triangle.uvs))
		end
	end
end

function Instance:transformAndClipToModel(transform, clippingPlanes)
	local modelTransform = self.transform
	-- print(self.model.boundsRadius)
	-- local center = transform:mulVector(modelTransform:mulVector(self.model.boundsCenter))
	-- local radiusSquared = math.pow(self.model.boundsRadius, 2)
	-- for _, plane in ipairs(clippingPlanes) do
	-- 	local distanceSquared = plane.normal:dot(center) + plane.distance
	-- 	if distanceSquared < -radiusSquared then
	-- 		return nil
	-- 	end
	-- end

	local vertices = {}
	for _, vertex in ipairs(self.model.vertices) do
		table.insert(vertices, transform:mulVector(modelTransform:mulVector(vertex)))
	end

	local triangles = self.model.triangles
	for _, plane in ipairs(clippingPlanes) do
		local newTriangles = {}
		for _, triangle in ipairs(triangles) do
			-- calculate if triangle is back-facing and cull it
			-- local a, b, c = vertices[triangle.i0], vertices[triangle.i1], vertices[triangle.i2]
			-- local v1 = b:sub(a)
			-- local v2 = c:sub(a)
			-- local normal = v1:cross(v2)
			-- local viewVector = Vec4(camera.yaw, camera.pitch, 0, 0)
			-- local angleToCamera = normal:dot(v1:sub(viewVector))
			-- if angleToCamera <= 0 then
				addClippedTriangles(newTriangles, triangle, plane, vertices)
			-- end
		end
		triangles = newTriangles
	end
	return Model(vertices, triangles, nil, nil)
end

function Instance:projectAndRender(gc)
	local projected = {}
	-- project vertices in clip space to screen
	for _, v in ipairs(self.model.vertices) do
		table.insert(projected, projectVector4(v))
	end
	-- render each triangle using the projected vertices array
	for _, t in ipairs(self.model.triangles) do
		renderTriangle(gc, projected, t)
	end
end

function renderInstances(gc, instances, clippingPlanes, transform)
	for _, instance in ipairs(instances) do
		local model = instance:transformAndClipToModel(transform, clippingPlanes)
		if model ~= nil then
			model:render(gc)
		end
	end
end
-----

-- Face enum
FACE_TOP    = 1
FACE_BOTTOM = 2
FACE_LEFT   = 3
FACE_RIGHT  = 4
FACE_FRONT  = 5
FACE_BACK   = 6
-----

-- Material enum
BLOCK_GRASS = 1
BLOCK_DIRT  = 2
BLOCK_LOG   = 3
FACE_LEAVES = 4
-----

local CUBE_VERTICES = {
	Vertex( 1,  1,  1),
	Vertex(-1,  1,  1),
	Vertex(-1, -1,  1),
	Vertex( 1, -1,  1),
	Vertex( 1,  1, -1),
	Vertex(-1,  1, -1),
	Vertex(-1, -1, -1),
	Vertex( 1, -1, -1)
}

-- Mesh
local Mesh = class()
function Mesh:init()
	local o = { __index = self }
	setmetatable(o, self)
	self.model = Model({}, {})
	return self
end

function Mesh:addTriangle(i0, i1, i2, x, y, z, uvs, texture)
	table.insert(self.model.vertices, CUBE_VERTICES[i0]:add(Vec4(x, y, z, 0)))
	table.insert(self.model.vertices, CUBE_VERTICES[i1]:add(Vec4(x, y, z, 0)))
	table.insert(self.model.vertices, CUBE_VERTICES[i2]:add(Vec4(x, y, z, 0)))

	local index = #self.model.vertices
	table.insert(self.model.triangles, Triangle(index - 2, index - 1, index, texture, uvs))
end

function Mesh:addFace(face, texture, x, y, z)
	if face == FACE_BACK then
		-- BACK
		self:addTriangle(1, 2, 3, x, y, z, { Vec2(0, 0), Vec2(1, 0), Vec2(1, 1) }, texture)
		self:addTriangle(1, 3, 4, x, y, z, { Vec2(0, 0), Vec2(1, 1), Vec2(0, 1) }, texture)
	elseif face == FACE_RIGHT then
		-- RIGHT
		self:addTriangle(5, 1, 4, x, y, z, { Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) }, texture)
		self:addTriangle(5, 4, 8, x, y, z, { Vec2(0, 1), Vec2(1, 0), Vec2(0, 0) }, texture)
	elseif face == FACE_FRONT then
		-- FRONT
		self:addTriangle(6, 5, 8, x, y, z, { Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) }, texture)
		self:addTriangle(6, 8, 7, x, y, z, { Vec2(0, 1), Vec2(1, 0), Vec2(0, 0) }, texture)
	elseif face == FACE_LEFT then
		-- LEFT
		self:addTriangle(2, 6, 7, x, y, z, { Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) }, texture)
		self:addTriangle(2, 7, 3, x, y, z, { Vec2(0, 1), Vec2(1, 0), Vec2(0, 0) }, texture)
	elseif face == FACE_TOP then
		-- TOP
		self:addTriangle(2, 1, 6, x, y, z, { Vec2(0, 0), Vec2(1, 0), Vec2(0, 1) }, texture)
		self:addTriangle(6, 1, 5, x, y, z, { Vec2(0, 1), Vec2(1, 0), Vec2(1, 1) }, texture)
	elseif face == FACE_BOTTOM then
		-- BOTTOM
		self:addTriangle(3, 7, 8, x, y, z, { Vec2(0, 0), Vec2(1, 1), Vec2(0, 1) }, texture)
		self:addTriangle(3, 8, 4, x, y, z, { Vec2(1, 0), Vec2(0, 1), Vec2(0, 0) }, texture)
	end
end

function Mesh:render(gc, transform)
	self.model:render(gc)
end
-----

-- World mesh
local World = class()
function World:init()
	local o = { __index = self }
	self.blockMap = {}
	self.blocks = {}
	setmetatable(o, self)
	return self
end

function World:get(x, y, z)
	x = math.floor(x)
	y = math.floor(y)
	z = math.floor(z)
	if self.blockMap[x] == nil then return nil end
	if self.blockMap[x][y] == nil then return nil end
	return self.blockMap[x][y][z]
end

function World:set(x, y, z, block)
	print("Setting block", block, "at", x, y, z)
	x = math.floor(x)
	y = math.floor(y)
	z = math.floor(z)
	if self.blockMap[x] == nil then self.blockMap[x] = {} end
	if self.blockMap[x][y] == nil then self.blockMap[x][y] = {} end
	self.blockMap[x][y][z] = block
	table.insert(self.blocks, { x = x, y = y, z = z, blockType = block })
end

function World:genMesh()
	local mesh = Mesh()
	for _, block in ipairs(self.blocks) do
		local x = block.x
		local y = block.y
		local z = block.z
		print("Adding triangle at ", x, y, z)
		mesh:addFace(FACE_TOP, GRASS, x, y, z)
		mesh:addFace(FACE_BOTTOM, GRASS, x, y, z)
		mesh:addFace(FACE_RIGHT, GRASS, x, y, z)
		mesh:addFace(FACE_LEFT, GRASS, x, y, z)
		mesh:addFace(FACE_FRONT, GRASS, x, y, z)
		mesh:addFace(FACE_BACK, GRASS, x, y, z)
	end
	return mesh
end
-----

local grass = Model(
	CUBE_VERTICES,
	{
		-- BACK
		-- (1 1 1)	(-1 1 1)	(-1 -1 1)
		Triangle(1, 2, 3, GRASS, { Vec2(0, 0), Vec2(1, 0), Vec2(1, 1) }),
		-- (1 1 1)	(-1 -1 1)	(1 -1 1)
		Triangle(1, 3, 4, GRASS, { Vec2(0, 0), Vec2(1, 1), Vec2(0, 1) }),

		-- RIGHT
		-- (1 1 -1)	(1 1 1)	(1 -1 1)
		Triangle(5, 1, 4, GRASS, { Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) }),
		-- (1 1 -1)	(1 -1 1)	(1 -1 -1)
		Triangle(5, 4, 8, GRASS, { Vec2(0, 1), Vec2(1, 0), Vec2(0, 0) }),

		-- FRONT
		-- (-1 1 -1)	(1 1 -1)	(1 -1 -1)
		Triangle(6, 5, 8, GRASS, { Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) }), -- Check
		-- (-1 1 -1)	(1 -1 -1)	(-1 -1 -1)
		Triangle(6, 8, 7, GRASS, { Vec2(0, 1), Vec2(1, 0), Vec2(0, 0) }),

		-- LEFT
		-- (-1 1 1)	(-1 1 -1)	(-1 -1 -1)
		Triangle(2, 6, 7, GRASS, { Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) }),
		-- (-1 1 1)	(-1 -1 -1)	(-1 -1 1)
		Triangle(2, 7, 3, GRASS, { Vec2(0, 1), Vec2(1, 0), Vec2(0, 0) }),

		-- TOP
		-- (-1 1 1)	(1 1 1)	(-1 1 -1)
		Triangle(2, 1, 6, GRASS_TOP, { Vec2(0, 0), Vec2(1, 0), Vec2(0, 1) }),
		-- (-1 1 -1)	(1 1 1)	(1 1 -1)
		Triangle(6, 1, 5, GRASS_TOP, { Vec2(0, 1), Vec2(1, 0), Vec2(1, 1) }),

		-- BOTTO
		-- (-1 -1 1)	(-1 -1 -1)	(1 -1 -1)
		Triangle(3, 7, 8, GRASS, { Vec2(1, 0), Vec2(1, 1), Vec2(0, 1) }),
		-- (-1 -1 1)	(1 -1 -1)	(1 -1 1)
		Triangle(3, 8, 4, GRASS, { Vec2(1, 0), Vec2(0, 1), Vec2(0, 0) })
	},
	Vertex(0, 0, 0),
	math.sqrt(3)
)

local dirt = Model(
	CUBE_VERTICES,
	{
		-- BACK
		-- (1 1 1)	(-1 1 1)	(-1 -1 1)
		Triangle(1, 2, 3, DIRT, { Vec2(0, 0), Vec2(1, 0), Vec2(1, 1) }),
		-- (1 1 1)	(-1 -1 1)	(1 -1 1)
		Triangle(1, 3, 4, DIRT, { Vec2(0, 0), Vec2(1, 1), Vec2(0, 1) }),

		-- RIGHT
		-- (1 1 -1)	(1 1 1)	(1 -1 1)
		Triangle(5, 1, 4, DIRT, { Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) }),
		-- (1 1 -1)	(1 -1 1)	(1 -1 -1)
		Triangle(5, 4, 8, DIRT, { Vec2(0, 1), Vec2(1, 0), Vec2(0, 0) }),

		-- FRONT
		-- (-1 1 -1)	(1 1 -1)	(1 -1 -1)
		Triangle(6, 5, 8, DIRT, { Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) }), -- Check
		-- (-1 1 -1)	(1 -1 -1)	(-1 -1 -1)
		Triangle(6, 8, 7, DIRT, { Vec2(0, 1), Vec2(1, 0), Vec2(0, 0) }),

		-- LEFT
		-- (-1 1 1)	(-1 1 -1)	(-1 -1 -1)
		Triangle(2, 6, 7, DIRT, { Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) }),
		-- (-1 1 1)	(-1 -1 -1)	(-1 -1 1)
		Triangle(2, 7, 3, DIRT, { Vec2(0, 1), Vec2(1, 0), Vec2(0, 0) }),

		-- TOP
		-- (-1 1 1)	(1 1 1)	(-1 1 -1)
		Triangle(2, 1, 6, DIRT, { Vec2(0, 0), Vec2(1, 0), Vec2(0, 1) }),
		-- (-1 1 -1)	(1 1 1)	(1 1 -1)
		Triangle(6, 1, 5, DIRT, { Vec2(0, 1), Vec2(1, 0), Vec2(1, 1) }),

		-- BOTTO
		-- (-1 -1 1)	(-1 -1 -1)	(1 -1 -1)
		Triangle(3, 7, 8, DIRT, { Vec2(1, 0), Vec2(1, 1), Vec2(0, 1) }),
		-- (-1 -1 1)	(1 -1 -1)	(1 -1 1)
		Triangle(3, 8, 4, DIRT, { Vec2(1, 0), Vec2(0, 1), Vec2(0, 0) })
	},
	Vertex(0, 0, 0),
	math.sqrt(3)
)

local log = Model(
	CUBE_VERTICES,
	{
		-- BACK
		-- (1 1 1)	(-1 1 1)	(-1 -1 1)
		Triangle(1, 2, 3, LOG_SIDE, { Vec2(0, 0), Vec2(1, 0), Vec2(1, 1) }),
		-- (1 1 1)	(-1 -1 1)	(1 -1 1)
		Triangle(1, 3, 4, LOG_SIDE, { Vec2(0, 0), Vec2(1, 1), Vec2(0, 1) }),

		-- RIGHT
		-- (1 1 -1)	(1 1 1)	(1 -1 1)
		Triangle(5, 1, 4, LOG_SIDE, { Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) }),
		-- (1 1 -1)	(1 -1 1)	(1 -1 -1)
		Triangle(5, 4, 8, LOG_SIDE, { Vec2(0, 1), Vec2(1, 0), Vec2(0, 0) }),

		-- FRONT
		-- (-1 1 -1)	(1 1 -1)	(1 -1 -1)
		Triangle(6, 5, 8, LOG_SIDE, { Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) }), -- Check
		-- (-1 1 -1)	(1 -1 -1)	(-1 -1 -1)
		Triangle(6, 8, 7, LOG_SIDE, { Vec2(0, 1), Vec2(1, 0), Vec2(0, 0) }),

		-- LEFT
		-- (-1 1 1)	(-1 1 -1)	(-1 -1 -1)
		Triangle(2, 6, 7, LOG_SIDE, { Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) }),
		-- (-1 1 1)	(-1 -1 -1)	(-1 -1 1)
		Triangle(2, 7, 3, LOG_SIDE, { Vec2(0, 1), Vec2(1, 0), Vec2(0, 0) }),

		-- TOP
		-- (-1 1 1)	(1 1 1)	(-1 1 -1)
		Triangle(2, 1, 6, LOG_VERT, { Vec2(0, 0), Vec2(1, 0), Vec2(0, 1) }),
		-- (-1 1 -1)	(1 1 1)	(1 1 -1)
		Triangle(6, 1, 5, LOG_VERT, { Vec2(0, 1), Vec2(1, 0), Vec2(1, 1) }),

		-- BOTTOM
		-- (-1 -1 1)	(-1 -1 -1)	(1 -1 -1)
		Triangle(3, 7, 8, LOG_VERT, { Vec2(1, 0), Vec2(1, 1), Vec2(0, 1) }),
		-- (-1 -1 1)	(1 -1 -1)	(1 -1 1)
		Triangle(3, 8, 4, LOG_VERT, { Vec2(1, 0), Vec2(0, 1), Vec2(0, 0) })
	},
	Vertex(0, 0, 0),
	math.sqrt(3)
)

local leaves = Model(
	CUBE_VERTICES,
	{
		-- BACK
		-- (1 1 1)	(-1 1 1)	(-1 -1 1)
		Triangle(1, 2, 3, LEAVES, { Vec2(0, 0), Vec2(1, 0), Vec2(1, 1) }),
		-- (1 1 1)	(-1 -1 1)	(1 -1 1)
		Triangle(1, 3, 4, LEAVES, { Vec2(0, 0), Vec2(1, 1), Vec2(0, 1) }),

		-- RIGHT
		-- (1 1 -1)	(1 1 1)	(1 -1 1)
		Triangle(5, 1, 4, LEAVES, { Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) }),
		-- (1 1 -1)	(1 -1 1)	(1 -1 -1)
		Triangle(5, 4, 8, LEAVES, { Vec2(0, 1), Vec2(1, 0), Vec2(0, 0) }),

		-- FRONT
		-- (-1 1 -1)	(1 1 -1)	(1 -1 -1)
		Triangle(6, 5, 8, LEAVES, { Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) }), -- Check
		-- (-1 1 -1)	(1 -1 -1)	(-1 -1 -1)
		Triangle(6, 8, 7, LEAVES, { Vec2(0, 1), Vec2(1, 0), Vec2(0, 0) }),

		-- LEFT
		-- (-1 1 1)	(-1 1 -1)	(-1 -1 -1)
		Triangle(2, 6, 7, LEAVES, { Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) }),
		-- (-1 1 1)	(-1 -1 -1)	(-1 -1 1)
		Triangle(2, 7, 3, LEAVES, { Vec2(0, 1), Vec2(1, 0), Vec2(0, 0) }),

		-- TOP
		-- (-1 1 1)	(1 1 1)	(-1 1 -1)
		Triangle(2, 1, 6, LEAVES, { Vec2(0, 0), Vec2(1, 0), Vec2(0, 1) }),
		-- (-1 1 -1)	(1 1 1)	(1 1 -1)
		Triangle(6, 1, 5, LEAVES, { Vec2(0, 1), Vec2(1, 0), Vec2(1, 1) }),

		-- BOTTOM
		-- (-1 -1 1)	(-1 -1 -1)	(1 -1 -1)
		Triangle(3, 7, 8, LEAVES, { Vec2(1, 0), Vec2(1, 1), Vec2(0, 1) }),
		-- (-1 -1 1)	(1 -1 -1)	(1 -1 1)
		Triangle(3, 8, 4, LEAVES, { Vec2(1, 0), Vec2(0, 1), Vec2(0, 0) })
	},
	Vertex(0, 0, 0),
	math.sqrt(3)
)

local instances = {}

for x = -3, 9, 1 do
	for y = 0, 15, 1 do
		local height = (perlin:noise(0.5 / (x == 0 and 1 or x),  0.5 / y, 1) + 1) * 3
		for z = 0, height, 1 do
			local instance
			if z == math.floor(height) then
				instance = Instance(grass, Mat4:translation(x * 2 - 8, -6 + z * 2, y * 2 + 13))
			else
				instance = Instance(dirt, Mat4:translation(x * 2 - 8, -6 + z * 2, y * 2 + 13))
			end
			table.insert(instances, instance)
		end
		-- local instance = Instance(grass, Mat4:translation(x * 2 - 8, -6 + (height + 2) * 2, y * 2 + 13))
		-- table.insert(instances, instance)
	end
end

local treeX = 4
local treeZ = 3
for y = 0, 1, 1 do
	local instance = Instance(log, Mat4:translation(treeX * 2 - 8, -6 + y * 2 + 6, treeZ * 2 + 13))
	table.insert(instances, instance)
end

local instance = Instance(leaves, Mat4:translation((treeX - 1) * 2 - 8, -6 + 2 * 2 + 6, treeZ * 2 + 13))
table.insert(instances, instance)

instance = Instance(leaves, Mat4:translation((treeX + 1) * 2 - 8, -6 + 2 * 2 + 6, treeZ * 2 + 13))
table.insert(instances, instance)

instance = Instance(leaves, Mat4:translation(treeX * 2 - 8, -6 + 2 * 2 + 6, (treeZ - 1) * 2 + 13))
table.insert(instances, instance)

instance = Instance(leaves, Mat4:translation(treeX * 2 - 8, -6 + 2 * 2 + 6, (treeZ + 1) * 2 + 13))
table.insert(instances, instance)

instance = Instance(leaves, Mat4:translation(treeX * 2 - 8, -6 + 3 * 2 + 6, treeZ * 2 + 13))
table.insert(instances, instance)

-- Event listeners
function on.arrowKey(key)
	if key == "left" then camera:rotate(1, 0)
	elseif key == "right" then camera:rotate(-1, 0)
	elseif key == "down" then camera:rotate(0, 1)
	elseif key == "up" then camera:rotate(0, -1)
	end
end

function on.charIn(char)
	local front = camera:getFront()
	front = Vec4(front[1], front[2], front[3], 0)
	-- print(table.concat(front, ' '))
	if char == 'w' then camera.position = camera.position:add(front)
	elseif char == 's' then camera.position = camera.position:sub(front)
	end
end

-- Program entry point
function on.paint(gc)
	-- local vertices = cube.vertices
	-- print("Vertices")
	-- for _, t in ipairs(cube.triangles) do
	-- print("(" .. table.concat(vertices[t.i0], ' ') .. ")", "(" .. table.concat(vertices[t.i1], ' ') .. ")", "(" .. table.concat(vertices[t.i2], " ") .. ")")
	-- end
	-- draw sky
	setColor(gc, Vec3(24 / 255, 69 / 255, 97 / 25))
	gc:fillRect(0, 0, WIDTH, HEIGHT)

	-- set default color
	setColor(gc, Vec3(0, 0, 0))

	-- clear depth buffer
	DEPTH_BUFFER = {}

	local s2 = math.sqrt(2)
	local planes = {
		Plane(Vertex(0, 0, 1), -1),   -- Near
		Plane(Vertex(s2, 0, s2), 0),  -- Left
		Plane(Vertex(-s2, 0, s2), 0), -- Right
		Plane(Vertex(0, -s2, s2), 0), -- Top
		Plane(Vertex(0, s2, s2), 0)   -- Bottom
	}

	-- local world = World()
	-- for x = 0, 20, 1 do
	-- 	for z = 0, 20, 1 do
	-- 		local height = perlin:noise(1 / x, 1 / z, 1) * 5
	-- 		for y = 0, height do
	-- 			world:set(x, y, z, "GRASS")
	-- 		end
	-- 	end
	-- end

	-- local mesh = world:genMesh()
	-- local instance = Instance(mesh.model, camera:getTransform())

	local start = timer.getMilliSecCounter()
	renderInstances(gc, instances, planes, camera:getTransform())
	-- local model = instance:transformAndClipToModel(camera:getTransform(), planes)
	-- model:render(gc)
	local finish = timer.getMilliSecCounter()

	setColor(gc, Vec3(0, 0, 0))
	drawText(gc, math.floor(1000 / (finish - start)) .. "FPS", 5, HEIGHT)
	drawText(gc, camera.yaw .. " " .. camera.pitch, 5, HEIGHT - 20)
	drawText(gc, table.concat(camera.position, ' '), 5, HEIGHT - 40)
end