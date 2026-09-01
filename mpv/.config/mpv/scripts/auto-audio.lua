-- ~/.config/mpv/scripts/auto-audio.lua
-- Auto-configure audio settings based on active PipeWire default sink.
-- HDMI: ALSA driver with 5.1 AC3 passthrough & lavcac3enc transcode.
-- Speaker/Analog: PipeWire driver with stereo PCM.

local utils = require 'mp.utils'

local function configure_audio()
    local res = utils.subprocess({ args = {"pactl", "get-default-sink"}, cancellable = false })
    local sink = (res and res.stdout) or ""

    if string.find(sink:lower(), "hdmi") then
        mp.set_property("ao", "alsa")
        mp.set_property("audio-device", "alsa/hdmi:CARD=Generic,DEV=1")
        mp.set_property("audio-channels", "5.1")
        mp.set_property("audio-spdif", "ac3")
        mp.commandv("af", "set", "lavcac3enc=yes:640:3")
        mp.msg.info("Sink: HDMI -> Enabled ALSA 5.1 AC3 Passthrough")
    else
        mp.set_property("ao", "pipewire")
        mp.set_property("audio-device", "auto")
        mp.set_property("audio-channels", "stereo")
        mp.set_property("audio-spdif", "")
        mp.commandv("af", "set", "")
        mp.msg.info("Sink: Speaker/Analog -> Enabled PipeWire Stereo PCM")
    end
end

mp.add_hook("on_preloaded", 50, configure_audio)
