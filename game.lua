Game = class()

function Game:init()
    math.randomseed(os.time())

    self.screen_center = vec2(200, 150)
    MainCamera:set_center(self.screen_center)
    MainCamera:set_scale(2)

    self.sky_image = love.graphics.newImage("images/sky.png")
    self.building_image = love.graphics.newImage("images/buildings.png")

    self.star_configs = {
        {
            count = 5,
            offset = vec2(-3, -3),
            place_rect = rect(50, 10, 350, 250),
            image = love.graphics.newImage("images/star5.png"),
            color = {255, 255, 255, 220},
            connect = true,
            clear_rect = rect(-4, -4, 5, 5)
        },
        {
            count = 10,
            offset = vec2(-2, -2),
            place_rect = rect(50, 10, 350, 250),
            image = love.graphics.newImage("images/star4.png"),
            color = {255, 255, 255, 220},
            connect = true,
            clear_rect = rect(-3, -3, 4, 4)
        },
        {
            count = 10,
            offset = vec2(-1, -1),
            place_rect = rect(10, 5, 390, 295),
            image = love.graphics.newImage("images/star3.png"),
            color = {255, 255, 255, 180},
            connect = false,
            clear_rect = nil
        },
        {
            count = 20,
            offset = vec2(-1, -1),
            place_rect = rect(2, 2, 395, 298),
            image = love.graphics.newImage("images/star2.png"),
            color = {255, 255, 255, 160},
            connect = false,
            clear_rect = nil
        },
        {
            count = 150,
            offset = vec2(),
            place_rect = rect(2, 2, 395, 298),
            image = love.graphics.newImage("images/star1.png"),
            color = {255, 255, 255, 150},
            connect = false,
            clear_rect = nil
        }
    }

    self.cons_line_count = {5, 7}
    self.cons_fail_count = 100
    self.cons_line_color = {255, 255, 255, 220}
    self.cons_line_width = 0.5
    self.cons_star_padding = 4
    self.cons_rect = rect(50, 10, 300, 190)

    self:create_stars()
    self:create_cons()
end

function Game:update(dt)

end

function Game:render()
    love.graphics.draw(self.sky_image, 0, 0)

    for _, star in ipairs(self.stars) do
        love.graphics.setColor(unpack(star.color))
        love.graphics.draw(star.image, unpack(star.draw_position))
    end

    love.graphics.setColor(unpack(self.cons_line_color))
    love.graphics.setLineWidth(self.cons_line_width)
    for _, line in ipairs(self.cons_lines) do
        love.graphics.line(line[1][1], line[1][2], line[2][1], line[2][2])
    end

    love.graphics.setColor(255, 255, 255, 255)

    love.graphics.draw(self.building_image, 0, 0)
end

function Game:mouse_pressed(pos, button)
    if button == 1 then
        self:create_stars()
        self:create_cons()
    end
end

function Game:mouse_released(pos, button)

end

function Game:mouse_wheel_moved(x, y)

end

function Game:key_pressed(key)

end

function Game:key_released(key)

end

function Game:create_stars()
    self.stars = {}
    self.connect_stars = {}

    local clear_rects = {}

    local function pos_valid(pos)
        for _, cr in ipairs(clear_rects) do
            if cr:contains(pos) then
                return false
            end
        end

        return true
    end

    for _, star_config in pairs(self.star_configs) do
        for i = 1, star_config.count do
            local star_pos
            while not star_pos or not pos_valid(star_pos) do
                star_pos = vec2(math.random(star_config.place_rect[1], star_config.place_rect[3]), math.random(star_config.place_rect[2], star_config.place_rect[4]))
            end

            local star = {
                image = star_config.image,
                color = star_config.color,
                position = star_pos,
                draw_position = star_pos + star_config.offset
            }

            table.insert(self.stars, star)

            if star_config.connect then
                table.insert(self.connect_stars, star)
            end

            if star_config.clear_rect then
                table.insert(clear_rects, star_config.clear_rect:translate(star_pos))
            end
        end
    end

    table.sort(self.connect_stars, function(a, b) return (a.position - self.screen_center):mag2() < (b.position - self.screen_center):mag2() end)
end

function Game:create_cons()
    self.cons_lines = {}

    local used_stars = {}

    local tar_line_count = math.random(self.cons_line_count[1], self.cons_line_count[2])
    local fails = 0

    local function try_line(cand_line)
        for _, line in pairs(self.cons_lines) do
            if lines_intersect(cand_line[1], cand_line[2], line[1], line[2]) then
                fails = fails + 1
                return false
            end
        end
        return true
    end

    local from_star = self.connect_stars[1]

    while #self.cons_lines < tar_line_count and fails < self.cons_fail_count do
        local to_star
        while not to_star or to_star == from_star or not self.cons_rect:contains(to_star.position) do
            to_star = self.connect_stars[math.random(1, #self.connect_stars)]
        end

        local star_diff = to_star.position - from_star.position
        local pad_vec = star_diff:norm() * self.cons_star_padding
        local cand_line = {from_star.position + pad_vec, to_star.position - pad_vec}

        if try_line(cand_line) then
            table.insert(self.cons_lines, cand_line)
            table.insert(used_stars, to_star)
            from_star = to_star
        else
            from_star = used_stars[math.random(1, #used_stars)]
        end
    end

    -- printf("cons has %s lines with %s fails", #self.cons_lines, fails)
end
