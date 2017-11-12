require 'name_gen_config'
require 'name_gen'

Game = class()

function Game:init()
    math.randomseed(os.time())

    self.name_gen = NameGenerator(name_gen_config)

    self.screen_size = vec2(400, 300)
    self.screen_center = (self.screen_size * 0.5):floor()
    MainCamera:set_center(self.screen_center)
    MainCamera:set_scale(2)

    self.sky_image = love.graphics.newImage("images/sky.png")
    self.building_image = love.graphics.newImage("images/buildings.png")

    self.star_configs = {
        {
            count = 20,
            offset = vec2(-1, -1),
            place_rect = rect(10, 5, 390, 295),
            image = love.graphics.newImage("images/star3.png"),
            color = {255, 255, 255, 180}
        },
        {
            count = 20,
            offset = vec2(-1, -1),
            place_rect = rect(2, 2, 395, 298),
            image = love.graphics.newImage("images/star2.png"),
            color = {255, 255, 255, 160}
        },
        {
            count = 200,
            offset = vec2(),
            place_rect = rect(2, 2, 395, 298),
            image = love.graphics.newImage("images/star1.png"),
            color = {255, 255, 255, 150}
        }
    }

    self.cons_star_configs = {
        {
            count = 5,
            offset = vec2(-3.5, -3.5),
            place_rect = rect(50, 10, 350, 250),
            image = love.graphics.newImage("images/star5.png"),
            color = {255, 255, 255, 220}
        },
        {
            count = 10,
            offset = vec2(-2.5, -2.5),
            place_rect = rect(50, 10, 350, 250),
            image = love.graphics.newImage("images/star4.png"),
            color = {255, 255, 255, 220}
        }
    }

    self.cons_name_color = {255, 255, 255, 255}

    self.cons_line_color = {230, 230, 255, 220}
    self.cons_line_width = 0.5
    self.cons_star_padding = 5

    self.cons_star_count = {7, 12}
    self.cons_star_dist = {30, 80}
    self.cons_star_clearance = 25
    self.cons_line_clearance = {20, 5}
    self.cons_rect = rect(50, 60, 300, 210)
    self.cons_loop_chance = 0.25
    self.cons_loop_tries = 5
    self.cons_branch_chance = 0.3

    self.cons_max_fails = 100
    self.cons_chain_tries = 5

    self.cons_place_shift = {20, 10}

    self.transition_fade_time = 0.25
    self.transition_move_time = 3

    self.cons_name_font = love.graphics.newFont("fonts/Aller_Rg.ttf", 20)

    self.star_fade_y_range = {220, 295}

    self.transition_timer = 0

    self:new_sky()
end

function Game:update(dt)
    self.transition_timer = math.max(0, self.transition_timer - dt)
    if self.transition_timer == 0 and self.transition_stage then
        if self.transition_stage == "fade_out" then
            self.transition_stage = "move"
            self.transition_timer = self.transition_move_time
        elseif self.transition_stage == "move" then
            self.transition_stage = "fade_in"
            self.transition_timer = self.transition_fade_time

            self.cons_name = self.next_cons_name
            self.stars = self.next_stars
            self.cons_lines = self.next_cons_lines
        elseif self.transition_stage == "fade_in" then
            self.transition_stage = nil
        end
    end
end

function Game:render()
    love.graphics.draw(self.sky_image, 0, 0)

    if self.transition_stage == "fade_out" then
        self:draw_stars(self.stars)

        local fade_color = copy(self.cons_line_color)
        fade_color[4] = math.floor(fade_color[4] * (self.transition_timer / self.transition_fade_time))
        self:draw_cons_lines(self.cons_lines, fade_color)

        fade_color = copy(self.cons_name_color)
        fade_color[4] = math.floor(fade_color[4] * (self.transition_timer / self.transition_fade_time))
        self:draw_cons_name(self.cons_name, fade_color)
    elseif self.transition_stage == "move" then
        local ratio = -0.5 * (math.cos(math.pi * self.transition_timer / self.transition_move_time) - 1)
        local translate = vec2(0, (1 - ratio) * self.screen_size[2])
        local tf = function(p)
            return p + translate
        end

        self:draw_stars(self.stars, tf)

        translate = vec2(0, ratio * -self.screen_size[2])

        self:draw_stars(self.next_stars, tf)
    elseif self.transition_stage == "fade_in" then
        self:draw_stars(self.stars)

        local fade_color = copy(self.cons_line_color)
        fade_color[4] = math.floor(fade_color[4] * (1 - self.transition_timer / self.transition_fade_time))
        self:draw_cons_lines(self.cons_lines, fade_color)

        fade_color = copy(self.cons_name_color)
        fade_color[4] = math.floor(fade_color[4] * (1 - self.transition_timer / self.transition_fade_time))
        self:draw_cons_name(self.cons_name, fade_color)
    else
        self:draw_stars(self.stars)
        self:draw_cons_lines(self.cons_lines, self.cons_line_color)
        self:draw_cons_name(self.cons_name, self.cons_name_color)
    end

    love.graphics.setColor(255, 255, 255, 255)

    love.graphics.draw(self.building_image, 0, 0)
end

function Game:mouse_pressed(pos, button)
    if button == 1 then
        self:new_sky(true)
    end
end

function Game:mouse_released(pos, button)

end

function Game:mouse_wheel_moved(x, y)

end

function Game:key_pressed(key)
    if key == "space" then
        self:new_sky(true)
    end
end

function Game:key_released(key)

end

function Game:draw_cons_name(name, color)
    love.graphics.setFont(self.cons_name_font)
    love.graphics.setColor(color)
    love.graphics.printf(name, 0, 10, 400, "center")
end

function Game:draw_stars(stars, tf)
    for _, star in ipairs(stars) do
        local pos = tf and tf(star.draw_position) or star.draw_position
        local alpha = math.floor(star.color[4] * math.max(0, math.min(1, 1 - (pos[2] - self.star_fade_y_range[1]) / (self.star_fade_y_range[2] - self.star_fade_y_range[1]))))
        love.graphics.setColor(star.color[1], star.color[2], star.color[3], alpha)
        love.graphics.draw(star.image, unpack(pos))
    end
end

function Game:draw_cons_lines(lines, color, tf)
    love.graphics.setColor(unpack(color))
    love.graphics.setLineWidth(self.cons_line_width)
    for _, line in ipairs(self.cons_lines) do
        if tf then
            love.graphics.line(tf(line[1][1]), tf(line[1][2]), tf(line[2][1]), tf(line[2][2]))
        else
            love.graphics.line(line[1][1], line[1][2], line[2][1], line[2][2])
        end
    end
end

function Game:new_sky(with_transition)
    if not with_transition then
        self.cons_name = self.name_gen:generate_name()
        self.stars = self:create_stars()
        self.cons_lines = self:create_cons(self.stars)
    elseif self.transition_stage == nil then
        self.next_cons_name = self.name_gen:generate_name()
        self.next_stars = self:create_stars()
        self.next_cons_lines = self:create_cons(self.next_stars)

        self.transition_stage = "fade_out"
        self.transition_timer = self.transition_fade_time
    end
end

function Game:create_stars()
    local new_stars = {}

    for _, star_config in pairs(self.star_configs) do
        for i = 1, star_config.count do
            local star_pos = vec2(math.random(star_config.place_rect[1], star_config.place_rect[3]), math.random(star_config.place_rect[2], star_config.place_rect[4]))

            local star = {
                image = star_config.image,
                color = star_config.color,
                position = star_pos,
                draw_position = star_pos + star_config.offset
            }

            table.insert(new_stars, star)
        end
    end

    return new_stars
end

function Game:create_cons(stars)
    local new_cons_lines = {}
    local cons_stars = {}

    local function pos_valid(pos)
        -- position not too close to another star
        for _, star in pairs(cons_stars) do
            local dist = (pos - star.position):mag()
            if dist < self.cons_star_clearance then
                -- printf("pos check failed: too close to star")
                return false
            end
        end

        -- position not too close to an existing constellation line
        for _, line in pairs(new_cons_lines) do
            local d1 = perp_dist(pos, unpack(line))
            local d2 = par_seg_dist(pos, unpack(line))
            if d1 < self.cons_line_clearance[1] and d2 < self.cons_line_clearance[2] then
                -- printf("pos check failed: too close to line")
                return false
            end
        end

        return true
    end

    local function conn_valid(from_star, to_star)
        -- line not too close to another star
        for _, star in pairs(cons_stars) do
            if star ~= from_star and star ~= to_star then
                local d1 = perp_dist(star.position, from_star.position, to_star.position)
                local d2 = par_seg_dist(star.position, from_star.position, to_star.position)
                if d1 < self.cons_line_clearance[1] and d2 < self.cons_line_clearance[2] then
                    -- print("conn check failed: line too close to star")
                    return false
                end
            end
        end

        -- line doesn't cross an existing constellation line
        for _, line in pairs(new_cons_lines) do
            if lines_intersect(line[1], line[2], from_star.position, to_star.position) then
                -- printf("conn check failed: lines intersect")
                return false
            end
        end

        return true
    end

    local function make_cons_star(star_pos)
        local star_config = self.cons_star_configs[math.random(1, #self.cons_star_configs)]
        return {
            image = star_config.image,
            position = star_pos,
            color = star_config.color,
            draw_position = star_pos + star_config.offset
        }
    end

    local fails = 0
    local target_stars = math.random(self.cons_star_count[1], self.cons_star_count[2])

    local first_star_pos = vec2(math.random(self.cons_rect[1], self.cons_rect[3]), math.random(self.cons_rect[2], self.cons_rect[4]))
    local cur_star = make_cons_star(first_star_pos)
    table.insert(cons_stars, cur_star)
    table.insert(stars, cur_star)

    while #cons_stars < target_stars and fails < self.cons_max_fails do
        local chain_tries = 0
        local new_star
        while not new_star and chain_tries < self.cons_chain_tries do
            local cand_dist = math.random(self.cons_star_dist[1], self.cons_star_dist[2])
            local cand_pos = cur_star.position + vec2.with_angle(math.random() * 2 * math.pi, cand_dist)
            if self.cons_rect:contains(cand_pos) and pos_valid(cand_pos) then
                local cand_star = make_cons_star(cand_pos)
                if conn_valid(cur_star, cand_star) then
                    new_star = cand_star
                else
                    -- printf("cand star at pos %s failed conn check", cand_pos)
                    chain_tries = chain_tries + 1
                end
            else
                -- printf("cand pos %s failed %s check", cand_pos, self.cons_rect:contains(cand_pos) and "pos" or "rect")
                chain_tries = chain_tries + 1
            end
        end

        if new_star then
            table.insert(cons_stars, new_star)
            table.insert(stars, new_star)

            local padding = (new_star.position - cur_star.position):norm() * self.cons_star_padding
            table.insert(new_cons_lines, {cur_star.position + padding, new_star.position - padding})

            if math.random() < self.cons_loop_chance then
                local loop_star
                local loop_tries = 0
                while not loop_star and loop_tries < self.cons_loop_tries do
                    local cand_loop_star = cons_stars[math.random(1, #cons_stars)]
                    if cand_loop_star ~= cur_star and cand_loop_star ~= new_star then
                        if conn_valid(new_star, cand_loop_star) then
                            loop_star = cand_loop_star
                        end
                    end
                    loop_tries = loop_tries + 1
                end

                if loop_star then
                    local padding = (loop_star.position - new_star.position):norm() * self.cons_star_padding
                    table.insert(new_cons_lines, {new_star.position + padding, loop_star.position - padding})
                end
            end

            if math.random() < self.cons_branch_chance then
                cur_star = cons_stars[math.random(1, #cons_stars)]
            else
                cur_star = new_star
            end
        else
            cur_star = cons_stars[math.random(1, #cons_stars)]
            fails = fails + 1
        end
    end

    -- translate constellation into center view

    local cons_bounds = rect(cons_stars[1].position[1], cons_stars[1].position[2], cons_stars[1].position[1], cons_stars[1].position[2])
    for _, star in pairs(cons_stars) do
        cons_bounds = cons_bounds:combine(star.position)
    end

    local translate = self.cons_rect:center() - cons_bounds:center()
    translate = translate + vec2(
        (math.random() - 0.5) * 2 * self.cons_place_shift[1],
        (math.random() - 0.5) * 2 * self.cons_place_shift[2]
    )

    for _, star in pairs(cons_stars) do
        star.position = star.position + translate
        star.draw_position = star.draw_position + translate
    end
    for _, line in pairs(new_cons_lines) do
        line[1] = line[1] + translate
        line[2] = line[2] + translate
    end

    return new_cons_lines

    -- printf("cons has %s lines %s stars with %s fails", #new_cons_lines, #cons_stars, fails)
end
