-- reactive.lua
local reactive = {}

local Signal = {}
Signal.__index = Signal

local activeEffect = nil
local effectStack = {}
local effectQueue = {}
local inQueue = setmetatable({}, { __mode = "k" })
local batchDepth = 0

local function cleanup(effect)
	for signal in pairs(effect.deps) do
		local subs = signal.subscribers
		if subs then
			subs[effect] = nil
		end
	end
	effect.deps = {}
end

local function drainQueue()
	while #effectQueue > 0 do
		local effect = table.remove(effectQueue, 1)
		inQueue[effect] = nil
		effect:run()
	end
end

local function schedule(effect)
	if not inQueue[effect] then
		inQueue[effect] = true
		table.insert(effectQueue, effect)
	end

	if batchDepth == 0 then
		drainQueue()
	end
end

function Signal.new(initial)
	return setmetatable({
		value = initial,
		subscribers = setmetatable({}, { __mode = "k" }),
	}, Signal)
end

function Signal:get()
	if activeEffect then
		self.subscribers[activeEffect] = true
		activeEffect.deps[self] = true
	end
	return self.value
end

function Signal:set(nextValue)
	if nextValue == self.value then
		return
	end

	self.value = nextValue

	for effect in pairs(self.subscribers) do
		schedule(effect)
	end
end

function Signal:update(fn)
	self:set(fn(self:get()))
end

local Effect = {}
Effect.__index = Effect

function Effect:new(fn, options)
	local effect = setmetatable({
		fn = fn,
		deps = {},
		scheduler = options and options.scheduler,
	}, Effect)
	effect:run()
	return effect
end

function Effect:run()
	cleanup(self)
	table.insert(effectStack, self)
	activeEffect = self

	local ok, err = pcall(self.fn)

	table.remove(effectStack)
	activeEffect = effectStack[#effectStack]

	if not ok then
		error(err, 0)
	end
end

function reactive.signal(initial)
	local signal = Signal.new(initial)
	local function getter()
		return signal:get()
	end
	local function setter(value)
		signal:set(value)
	end
	return getter, setter, signal
end

function reactive.effect(fn, options)
	if options and options.defer then
		local effect
		effect = Effect:new(function()
			return fn(function()
				cleanup(effect)
			end)
		end, options)
		return function()
			cleanup(effect)
		end
	else
		local effect = Effect:new(fn, options)
		return function()
			cleanup(effect)
		end
	end
end

function reactive.computed(fn)
	local value, dirty = nil, true
	local getter, setter, signal = reactive.signal(nil)

	local recompute
	recompute = Effect:new(function()
		if dirty then
			setter(fn())
			dirty = false
		end
	end, {
		scheduler = function(effect)
			dirty = true
			schedule(effect)
		end,
		defer = true,
	})

	return function()
		if dirty then
			recompute:run()
		end
		return getter()
	end
end

function reactive.watch(getter, callback, options)
	local firstRun = true
	local oldValue

	return reactive.effect(function(stop)
		local newValue = getter()
		if firstRun then
			firstRun = false
			oldValue = newValue
			if not (options and options.immediate) then
				return
			end
		end

		callback(newValue, oldValue, stop)
		oldValue = newValue
	end)
end

function reactive.batch(fn)
	batchDepth += 1
	local ok, err = pcall(fn)
	batchDepth -= 1

	if batchDepth == 0 then
		drainQueue()
	end

	if not ok then
		error(err, 2)
	end
end

function reactive.peek(getter)
	local effect = activeEffect
	activeEffect = nil
	local ok, result = pcall(getter)
	activeEffect = effect
	if not ok then
		error(result, 2)
	end
	return result
end

return reactive
