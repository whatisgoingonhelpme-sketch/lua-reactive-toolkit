local reactive = require("reactive")

local count, setCount = reactive.signal(0)
local doubled = reactive.computed(function()
    return count() * 2
end)

reactive.effect(function()
    print(("count = %d, doubled = %d"):format(count(), doubled()))
end)

reactive.watch(count, function(newValue, oldValue)
    print(("count changed from %d to %d"):format(oldValue, newValue))
end, { immediate = true })

for i = 1, 5 do
    reactive.batch(function()
        setCount(i)
        setCount(i + 0.5) -- this gets merged by the batch
    end)
end
