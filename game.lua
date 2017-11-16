require 'name_gen_config'
require 'name_gen'
require 'sky'

Game = class()

function Game:init()
    math.randomseed(os.time())

    self.name_gen = NameGenerator(name_gen_config)

    self.screen_size = vec2(400, 300)
    self.screen_center = (self.screen_size * 0.5):floor()
    MainCamera:set_center(self.screen_center)
    MainCamera:set_scale(2)

    self.sky_bg_image = love.graphics.newImage("images/sky_bg.png")
    self.sky_bg_image:setWrap("repeat","repeat")
    self.sky_fg_image = love.graphics.newImage("images/sky_fg.png")
    self.sky_fg_image:setWrap("repeat","repeat")
    self.sky_bg_quad = love.graphics.newQuad(0, 0, self.screen_size[1], self.screen_size[2], self.sky_bg_image:getDimensions())
    self.building_image = love.graphics.newImage("images/buildings.png")

    self.transition_fade_time = 0.5
    self.transition_move_time = 3

    self.transition_timer = 0

    self.sky = Sky(self.screen_size)
    self.next_sky = Sky(self.screen_size)

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

            self.sky, self.next_sky = self.next_sky, self.sky
        elseif self.transition_stage == "fade_in" then
            self.transition_stage = nil
        end
    end
end

function Game:render()
    love.graphics.setColor(255, 255, 255, 255)

    love.graphics.draw(self.sky_bg_image, self.sky_bg_quad, 0, 0)

    if self.transition_stage == "fade_out" then
        love.graphics.draw(self.sky.star_canvas)

        local fade_ratio = self.transition_timer / self.transition_fade_time
        self:draw_cons_lines(self.sky, fade_ratio)
        self:draw_cons_name(self.sky, fade_ratio)
    elseif self.transition_stage == "move" then
        local ratio = ease_sin(self.transition_timer / self.transition_move_time)

        local translate = vec2(0, (1 - ratio) * self.screen_size[2])
        love.graphics.draw(self.sky.star_canvas, unpack(translate))
        translate = vec2(0, ratio * -self.screen_size[2])
        love.graphics.draw(self.next_sky.star_canvas, unpack(translate))
    elseif self.transition_stage == "fade_in" then
        love.graphics.draw(self.sky.star_canvas)

        local fade_ratio = 1 - self.transition_timer / self.transition_fade_time
        self:draw_cons_lines(self.sky, fade_ratio)
        self:draw_cons_name(self.sky, fade_ratio)
    else
        love.graphics.draw(self.sky.star_canvas)

        self:draw_cons_lines(self.sky)
        self:draw_cons_name(self.sky)
    end

    love.graphics.setColor(255, 255, 255, 255)

    love.graphics.draw(self.sky_fg_image, self.sky_bg_quad, 0, 0)
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
    elseif key == "f12" and not self.transition_stage then
        local screenshot = love.graphics.newScreenshot();
        screenshot:encode('png', self.sky.cons_name .. '.png');
        Log:message("Screenshot saved as %s", love.filesystem.getSaveDirectory() .. '/' .. self.sky.cons_name .. '.png')
    end
end

function Game:key_released(key)

end

function Game:draw_cons_name(sky, alpha)
    love.graphics.setColor(
            sky.cons_name_color[1],
            sky.cons_name_color[2],
            sky.cons_name_color[3],
            math.floor(sky.cons_name_color[4] * (alpha or 1.0)))

    local draw_x = math.floor(sky.cons_name_pos[1] - sky.cons_name_text:getWidth() * 0.5)
    love.graphics.draw(sky.cons_name_text, draw_x, sky.cons_name_pos[2])
end

function Game:draw_cons_lines(sky, alpha)
    love.graphics.setColor(
            sky.cons_line_color[1],
            sky.cons_line_color[2],
            sky.cons_line_color[3],
            math.floor(sky.cons_line_color[4] * (alpha or 1.0)))

    love.graphics.setLineWidth(sky.cons_line_width)
    for _, line in ipairs(sky.cons_lines) do
        love.graphics.line(line[1][1], line[1][2], line[2][1], line[2][2])
    end
end

-- function Game:stretch_in_cons_lines(lines, overall_ratio)
--     love.graphics.setLineWidth(self.cons_line_width)
--     love.graphics.setColor(unpack(self.cons_line_color))

--     local cur_stretch_index = math.floor(#lines * overall_ratio) + 1
--     for i, line in ipairs(self.sky.cons_lines) do
--         if i < cur_stretch_index then
--             love.graphics.line(line[1][1], line[1][2], line[2][1], line[2][2])
--         elseif i == cur_stretch_index then
--             local stretch_ratio = clamp(#lines * overall_ratio - cur_stretch_index + 1, 0, 1)
--             local end_point = lerp_vec2(stretch_ratio, line[1], line[2])
--             love.graphics.line(line[1][1], line[1][2], end_point[1], end_point[2])
--         end
--     end
-- end

function Game:new_sky(with_transition)
    if not self.transition_stage then
        if with_transition then
            self.next_sky:generate(self.name_gen)

            self.transition_stage = "fade_out"
            self.transition_timer = self.transition_fade_time
        else
            self.sky:generate(self.name_gen)

            self.transition_stage = "fade_in"
            self.transition_timer = self.transition_fade_time
        end
    end
end
