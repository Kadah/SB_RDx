--	
--	OOP Module
--	based off of LOOP (http://loop.luaforge.net/) by Renato Maia <maia@inf.puc-rio.br>
--	edited by TAD2020 to combine Simple and Multiple Inheritance Class Models in to one file and for simple use
--	

local pairs        = pairs
local ipairs       = ipairs
local unpack       = unpack
local rawget       = rawget
local rawset       = rawset
local setmetatable = setmetatable
local getmetatable = getmetatable
local table        = require "table"

module "oop"

classes = {} -- this is just a shared table to make sharing classes easier

local function getclass(tab, keys)
	local key = table.remove(keys, 1)
	tab = tab[key] or {}
	return tab
end

--storeclass(class, key1, key2, key3, ...)
--	stores a class in the classes table as classes[key1][key2][key3] = class
function storeclass(class, ...)
	if arg[1] then
		local key = table.remove(arg)
		local tab = classes
		while arg[1] do
			tab = getclass(tab, arg)
		end
		tab[key] = class
	end
end


--------------------------------------------------------------------------------
function rawnew(class, object)
	return setmetatable(object or {}, class)
end
--------------------------------------------------------------------------------
function new(class, ...)
	if class.__init
		then return class:__init(...)
		else return rawnew(class, ...)
	end
end
--------------------------------------------------------------------------------
function initclass(class)
	if class == nil then class = {} end
	if class.__index == nil then class.__index = class end
	return class
end
--------------------------------------------------------------------------------
function tablecopy(source, destiny)
	if source then
		if not destiny then destiny = {} end
		for field, value in pairs(source) do
			rawset(destiny, field, value)
		end
	end
	return destiny
end
--------------------------------------------------------------------------------
local MultipleClass = {
	__call = new,
	__index = function (self, field)
		self = classof(self)
		for _, super in ipairs(self) do
			local value = super[field]
			if value ~= nil then return value end
		end
	end,
}

function class(class, ...)
	return rawnew(
      tablecopy(MultipleClass, {...}),
      initclass(class)
   )
   
   --[[if select("#", ...) > 1
		then return base.rawnew(table.copy(MultipleClass, {...}), initclass(class))
		else return base.class(class, ...)
	end]]
   
end
--------------------------------------------------------------------------------
classof = getmetatable
--------------------------------------------------------------------------------
memberof = rawget
--------------------------------------------------------------------------------
members = pairs
--------------------------------------------------------------------------------
function isclass(class)
	local metaclass = classof(class)
	if metaclass then
		return metaclass.__index == MultipleClass.__index or isclass(class) --this doesn't look right to me (TAD2020)
	end
end
--------------------------------------------------------------------------------
function superclass(class)
	local metaclass = base.classof(class)
	if metaclass then
		local indexer = metaclass.__index
		if (indexer == MultipleClass.__index)
			then return unpack(metaclass)
			else return metaclass.__index
		end
	end
end
--------------------------------------------------------------------------------
local function isingle(single, index)
	if single and not index then
		return 1, single
	end
end
function supers(class)
	local metaclass = classof(class)
	if metaclass then
		local indexer = metaclass.__index
		if indexer == MultipleClass.__index
			then return ipairs(metaclass)
			else return isingle, indexer
		end
	end
	return isingle
end
--------------------------------------------------------------------------------
function subclassof(class, super)
	if class == super then return true end
	for _, superclass in supers(class) do
		if subclassof(superclass, super) then return true end
	end
	return false
end
--------------------------------------------------------------------------------
function instanceof(object, class)
	return subclassof(classof(object), class)
end

