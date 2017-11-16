Sky = class()

function Sky:init(screen_size, scale)
    self.screen_size = screen_size
    self.scale = scale

    self.star_configs = {
        {
            count = 20,
            offset = vec2(-1, -1),
            place_rect = rect(5, 5, 395, 295),
            image = love.graphics.newImage("images/star3.png"),
            color = {255, 255, 255, 190}
        },
        {
            count = 20,
            offset = vec2(-1, -1),
            place_rect = rect(2, 2, 398, 298),
            image = love.graphics.newImage("images/star2.png"),
            color = {255, 255, 255, 190}
        },
        {
            count = 200,
            offset = vec2(),
            place_rect = rect(2, 2, 398, 298),
            image = love.graphics.newImage("images/star1.png"),
            color = {255, 255, 255, 190}
        }
    }

    self.cons_star_configs = {
        {
            count = 5,
            offset = vec2(-3.5, -3.5),
            image = love.graphics.newImage("images/star5.png"),
            color = {255, 255, 255, 220}
        },
        {
            count = 10,
            offset = vec2(-2.5, -2.5),
            image = love.graphics.newImage("images/star4.png"),
            color = {255, 255, 255, 220}
        }
    }

    self.title_font = love.graphics.newFont("fonts/alagard.ttf", 78)
    self.subtitle_font = love.graphics.newFont("fonts/alagard.ttf", 36)
    self.title_text = love.graphics.newText(self.title_font, "Stargazer")
    self.subtitle_text = love.graphics.newText(self.subtitle_font, "press [space] to look up")
    local scaled_screen = self.screen_size * self.scale
    self.title_position = vec2(
            (scaled_screen[1] - self.title_text:getWidth()) * 0.5,
            scaled_screen[2] * 0.4 - self.title_text:getHeight() - 15):floor()
    self.subtitle_position = vec2(
            (scaled_screen[1] - self.subtitle_text:getWidth()) * 0.5,
            scaled_screen[2] * 0.4 + 15):floor()

    self.cons_name_color = {255, 255, 255, 230}
    self.cons_name_font = love.graphics.newFont("fonts/alagard.ttf", 48)
    self.cons_name_font:setFilter("nearest", "nearest")
    self.cons_name_pos = vec2(self.screen_size[1], 20)

    self.cons_line_color = {230, 230, 255, 220}
    self.cons_line_width = 0.5
    self.cons_star_padding = 5

    self.cons_star_count = {6, 12}
    self.cons_star_dist = {30, 80}
    self.cons_star_clearance = 25
    self.cons_line_clearance = {20, 5}
    self.cons_rect = rect(50, 60, 300, 210)
    self.cons_loop_chance = 0.25
    self.cons_loop_tries = 5
    self.cons_branch_chance = 0.3
    self.cons_max_fails = 100
    self.cons_chain_tries = 5

    self.cons_star_exclude_rect = rect(-4, -4, 5, 5)

    self.cons_place_shift = {20, 10}

    self.cons_name_text = love.graphics.newText(self.cons_name_font, "")
    self.star_canvas = love.graphics.newCanvas(unpack(self.screen_size))
end

function Sky:generate(name_gen)
    if not self.transition_stage then
        -- generate new stars and constellation
        self.cons_stars, self.cons_lines = self:create_cons()

        local exclude_rects = map(self.cons_stars, function(star)
                return self.cons_star_exclude_rect:translate(star.position)
            end)

        self.cons_name = name_gen:generate_name()
        self.cons_name_text:set(self.cons_name)

        local text_rect_ll = vec2(self.cons_name_pos[1] - self.cons_name_text:getWidth() * 0.5, self.cons_name_pos[2]) / self.scale
        local text_rect = rect(
                text_rect_ll[1],
                text_rect_ll[2],
                text_rect_ll[1] + self.cons_name_text:getWidth() / self.scale,
                text_rect_ll[2] + self.cons_name_text:getHeight() / self.scale)

        text_rect = text_rect:pad(vec2(3, 3))

        table.insert(exclude_rects, text_rect)

        self.stars = self:create_stars(exclude_rects)

        local function draw_stars(stars)
            for _, star in ipairs(stars) do
                love.graphics.setColor(unpack(star.color))
                love.graphics.draw(star.image, unpack(star.draw_position))
            end
        end

        -- draw new stars to canvas for later rendering
        love.graphics.setCanvas(self.star_canvas)
        love.graphics.clear()
        draw_stars(self.stars)
        draw_stars(self.cons_stars)
        love.graphics.setCanvas()
    end
end

function Sky:generate_title()
    self.cons_stars = {}
    self.cons_lines = {}
    self.cons_name = ""
    self.cons_name_text:set("")

    local exclude_rects = {}

    local title_rect = rect.with_size(self.title_position, vec2(self.title_text:getDimensions())):pad(vec2(4, 4))
    title_rect = (title_rect / self.scale):floor()
    local subtitle_rect = rect.with_size(self.subtitle_position, vec2(self.subtitle_text:getDimensions())):pad(vec2(4, 4))
    subtitle_rect = (subtitle_rect / self.scale):floor()

    table.insert(exclude_rects, title_rect)
    table.insert(exclude_rects, subtitle_rect)

    self.stars = self:create_stars(exclude_rects)

    love.graphics.setCanvas(self.star_canvas)
    love.graphics.clear()
    for _, star in ipairs(self.stars) do
        love.graphics.setColor(unpack(star.color))
        love.graphics.draw(star.image, unpack(star.draw_position))
    end
    love.graphics.setCanvas()
end

function Sky:create_stars(exclude_rects)
    local random = math.random

    local function pos_valid(pos)
        for _, rect in ipairs(exclude_rects) do
            if rect:contains(pos) then
                return false
            end
        end
        return true
    end

    local new_stars = {}

    for _, star_config in ipairs(self.star_configs) do
        for i = 1, star_config.count do
            local star_pos
            while not star_pos or not pos_valid(star_pos) do
                star_pos = vec2(random(star_config.place_rect[1], star_config.place_rect[3]), random(star_config.place_rect[2], star_config.place_rect[4]))
            end

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

function Sky:create_cons()
    local new_cons_lines = {}
    local new_cons_stars = {}

    local random = math.random

    local function pos_valid(pos)
        -- position not too close to another star
        for _, star in ipairs(new_cons_stars) do
            local dist = (pos - star.position):mag()
            if dist < self.cons_star_clearance then
                -- printf("pos check failed: too close to star")
                return false
            end
        end

        -- position not too close to an existing constellation line
        for _, line in ipairs(new_cons_lines) do
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
        for _, star in ipairs(new_cons_stars) do
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
        for _, line in ipairs(new_cons_lines) do
            if lines_intersect(line[1], line[2], from_star.position, to_star.position) then
                -- printf("conn check failed: lines intersect")
                return false
            end
        end

        return true
    end

    local function make_cons_star(star_pos)
        local star_config = self.cons_star_configs[random(1, #self.cons_star_configs)]
        return {
            image = star_config.image,
            position = star_pos,
            color = star_config.color,
            draw_position = star_pos + star_config.offset
        }
    end

    local fails = 0
    local target_stars = random(self.cons_star_count[1], self.cons_star_count[2])

    local first_star_pos = vec2(random(self.cons_rect[1], self.cons_rect[3]), random(self.cons_rect[2], self.cons_rect[4]))
    local cur_star = make_cons_star(first_star_pos)
    table.insert(new_cons_stars, cur_star)

    while #new_cons_stars < target_stars and fails < self.cons_max_fails do
        local chain_tries = 0
        local new_star
        while not new_star and chain_tries < self.cons_chain_tries do
            local cand_dist = random(self.cons_star_dist[1], self.cons_star_dist[2])
            local cand_pos = cur_star.position + vec2.with_angle(random() * 2 * math.pi, cand_dist)
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
            table.insert(new_cons_stars, new_star)

            local padding = (new_star.position - cur_star.position):norm() * self.cons_star_padding
            table.insert(new_cons_lines, {cur_star.position + padding, new_star.position - padding})

            if random() < self.cons_loop_chance then
                local loop_star
                local loop_tries = 0
                while not loop_star and loop_tries < self.cons_loop_tries do
                    local cand_loop_star = new_cons_stars[random(1, #new_cons_stars)]
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

            if random() < self.cons_branch_chance then
                cur_star = new_cons_stars[random(1, #new_cons_stars)]
            else
                cur_star = new_star
            end
        else
            cur_star = new_cons_stars[random(1, #new_cons_stars)]
            fails = fails + 1
        end
    end

    -- translate constellation into center view

    local cons_bounds = rect(new_cons_stars[1].position[1], new_cons_stars[1].position[2], new_cons_stars[1].position[1], new_cons_stars[1].position[2])
    for _, star in ipairs(new_cons_stars) do
        cons_bounds = cons_bounds:combine(star.position)
    end

    local translate = self.cons_rect:center() - cons_bounds:center()
    translate = translate + vec2(
        (random() - 0.5) * 2 * self.cons_place_shift[1],
        (random() - 0.5) * 2 * self.cons_place_shift[2]
    )

    for _, star in ipairs(new_cons_stars) do
        star.position = star.position + translate
        star.draw_position = star.draw_position + translate
    end
    for _, line in ipairs(new_cons_lines) do
        line[1] = line[1] + translate
        line[2] = line[2] + translate
    end

    -- printf("cons has %s lines %s stars with %s fails", #new_cons_lines, #new_cons_stars, fails)

    return new_cons_stars, new_cons_lines
end
