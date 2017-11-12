NameGenerator = class()

function NameGenerator:init(config)
    -- printf(printr(config))
    self.source_names = config.source_names
    self.order = config.order
    self.end_length = config.end_length
    self.target_length = config.target_length
    self.suffixes = config.suffixes
    self.suffix_chance = config.suffix_chance

    self.chains = {}
    self.starts = {}
    self.is_end = {}
    for _, name in pairs(self.source_names) do
        name = name:lower()
        table.insert(self.starts, name:sub(1, self.order))

        local i = 1
        while i + self.order < #name do
            local prefix = name:sub(i, i + self.order - 1)
            local chain = name:sub(i + self.order, i + self.order)
            if not self.chains[prefix] then
                self.chains[prefix] = {}
            end
            -- printf("adding chain %s for prefix %s", chain, prefix)
            table.insert(self.chains[prefix], chain)
            i = i + 1
        end
        self.is_end[name:sub(#name - self.end_length + 1)] = true
        -- printf("%s is an end", name:sub(#name - self.end_length + 1))
    end

    -- for i = 1, 100 do
    --     print(self:generate_name())
    -- end
end

function NameGenerator:generate_name()
    local name = self.starts[math.random(1, #self.starts)]
    local target_length = math.random(self.target_length[1], self.target_length[2])
    while #name < target_length or (#name < self.target_length[2] and not self.is_end[name:sub(#name - self.end_length + 1)]) do
        local chains = self.chains[name:sub(#name - 1)]
        if not chains then
            break
        end
        -- printf("name %s selecting from %s chains", name, #chains)
        name = name .. chains[math.random(1, #chains)]
    end

    name = name:sub(1, 1):upper() .. name:sub(2)

    -- for _, source_name in pairs(self.source_names) do
    --     if name:lower() == source_name:lower() then
    --         printf("name '%s' is in source table", name)
    --     end
    -- end

    if math.random() < self.suffix_chance then
        name = name .. self.suffixes[math.random(1, #self.suffixes)]
    end

    return name
end
