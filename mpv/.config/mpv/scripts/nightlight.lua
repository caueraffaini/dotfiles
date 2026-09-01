-- Disable night filter (wlsunset) during playback, restore on quit
local conf = os.getenv("HOME") .. "/.config/nightlight.conf"

local function nightlight_off()
    os.execute("pkill wlsunset 2>/dev/null; pkill -RTMIN+9 waybar 2>/dev/null")
end

local function nightlight_on()
    os.execute(
        "bash -c 'source " .. conf .. " 2>/dev/null; " ..
        "wlsunset " ..
        "-l \"${NIGHTLIGHT_LAT:-0.0}\" " ..
        "-L \"${NIGHTLIGHT_LON:-0.0}\" " ..
        "-t \"${NIGHTLIGHT_TEMP_NIGHT:-3000}\" " ..
        "-T \"${NIGHTLIGHT_TEMP_DAY:-6500}\" &' && " ..
        "pkill -RTMIN+9 waybar 2>/dev/null"
    )
end


mp.register_event("file-loaded", nightlight_off)
mp.register_event("end-file",    nightlight_on)
