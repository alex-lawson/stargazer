function sign(v)
    if v >= 0 then
        return 1
    else
        return -1
    end
end

function lerp(ratio, a, b)
    if type(a) == "table" then
        return a[1] + (a[2] - a[1]) * ratio
    else
        return a + (b - a) * ratio
    end
end

function lerp_vec2(ratio, a, b)
    return vec2(
        lerp(ratio, a[1], b[1]),
        lerp(ratio, a[2], b[2])
    )
end

function angle_diff(from, to)
  return ((((to - from) % (2*math.pi)) + (3*math.pi)) % (2*math.pi)) - math.pi
end

function round(x, decimals)
    decimals = decimals or 0
    return math.floor((x * (10 ^ decimals)) + 0.5) / (10 ^ decimals)
end

function clamp(x, min, max)
    return x < min and min or (x > max and max or x)
end

-- Returns whether the three given points are in a straight line (returns 0),
-- go counter clockwise (returns > 0) or go clockwise (returns < 0)
function winding_direction(p1, p2, p3)
    return (p1[1] - p3[1]) * (p2[2] - p3[2]) - (p2[1] - p3[1]) * (p1[2] - p3[2])
end

-- This is based off an explanation and expanded math presented by Paul Bourke:
-- It takes two lines as inputs and returns true if they intersect, false if they don't.
-- If they do, ptIntersection returns the point where the two lines intersect.
-- params a, b = first line
-- params c, d = second line
-- param ptIntersection: The point where both lines intersect (if they do)
-- http://local.wasp.uwa.edu.au/~pbourke/geometry/lineline2d/
-- http://paulbourke.net/geometry/pointlineplane/
function lines_intersect( a, b, c, d )
    -- parameter conversion
    local L1 = {X1=a[1],Y1=a[2],X2=b[1],Y2=b[2]}
    local L2 = {X1=c[1],Y1=c[2],X2=d[1],Y2=d[2]}

    -- Denominator for ua and ub are the same, so store this calculation
    local d = (L2.Y2 - L2.Y1) * (L1.X2 - L1.X1) - (L2.X2 - L2.X1) * (L1.Y2 - L1.Y1)

    -- Make sure there is not a division by zero - this also indicates that the lines are parallel.
    -- If n_a and n_b were both equal to zero the lines would be on top of each
    -- other (coincidental).  This check is not done because it is not
    -- necessary for this implementation (the parallel check accounts for this).
    if (d == 0) then
        return false
    end

    -- n_a and n_b are calculated as seperate values for readability
    local n_a = (L2.X2 - L2.X1) * (L1.Y1 - L2.Y1) - (L2.Y2 - L2.Y1) * (L1.X1 - L2.X1)
    local n_b = (L1.X2 - L1.X1) * (L1.Y1 - L2.Y1) - (L1.Y2 - L1.Y1) * (L1.X1 - L2.X1)

    -- Calculate the intermediate fractional point that the lines potentially intersect.
    local ua = n_a / d
    local ub = n_b / d

    -- The fractional point will be between 0 and 1 inclusive if the lines
    -- intersect.  If the fractional calculation is larger than 1 or smaller
    -- than 0 the lines would need to be longer to intersect.
    if (ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1) then
        local x = L1.X1 + (ua * (L1.X2 - L1.X1))
        local y = L1.Y1 + (ua * (L1.Y2 - L1.Y1))
        return true, {x, y}
    end

    return false
end

function perp_dist(p, a, b)
    local dir = (b - a):norm()
    local perp = vec2(dir[2], -dir[1])
    local test_p = p - a
    return math.abs(test_p:dot(perp))
end

function par_seg_dist(p, a, b)
    local dir = (b - a)
    local len = dir:mag()
    dir = dir:norm()
    local test_p = p - a
    local dist = test_p:dot(dir)
    if dist < 0 then
        return -dist
    elseif dist > len then
        return dist - len
    else
        return 0
    end
end

function ease_sin(ratio)
    return -0.5 * (math.cos(math.pi * ratio) - 1)
end
