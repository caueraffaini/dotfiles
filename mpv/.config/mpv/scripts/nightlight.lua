-- Disable night filter (wlsunset) during playback, restore on quit
local conf = os.getenv("HOME") .. "/.config/nightlight.conf"

local function nightlight_off()
    mp.utils.subprocess_detached({ args = { "pkill", "wlsunset" } })
    mp.utils.subprocess_detached({ args = { "pkill", "-RTMIN+9", "waybar" } })
end

local function nightlight_on()
    local lat, lon = "0.0", "0.0"
    local temp_night, temp_day = "3000", "6500"
    local f = io.open(conf, "r")
    if f then
        for line in f:lines() do
            local k, v = line:match('^%s*([%w_]+)%s*=%s*["\']?([^"\'%s]+)["\']?')
            if k == "NIGHTLIGHT_LAT" and v then lat = v
            elseif k == "NIGHTLIGHT_LON" and v then lon = v
            elseif k == "NIGHTLIGHT_TEMP_NIGHT" and v then temp_night = v
            elseif k == "NIGHTLIGHT_TEMP_DAY" and v then temp_day = v
            end
        end
        f:close()
    end

    mp.utils.subprocess_detached({
        args = {
            "wlsunset",
            "-l", lat,
            "-L", lon,
            "-t", temp_night,
            "-T", temp_day
        }
    })
    mp.utils.subprocess_detached({ args = { "pkill", "-RTMIN+9", "waybar" } })
end


mp.register_event("file-loaded", nightlight_off)
mp.register_event("end-file",    nightlight_on)
