--[[

	This script file is a part of Garry's Mod addon "C.A.S.S.I.E from SCP: Secret Laboratory" and is disturbed under MIT license. 
	
	Copyright (c) 2023-2024 _wania
	
	For the full copyright and license information, please view the LICENSE file that was distributed with this source code.

]]

local deque = {}

function deque.Create()
    local tab = {}
    tab.data = {}
    tab.head = 0
    tab.tail = -1
    tab.num = 0

    function tab.pop_front(self)
        if self.head > self.tail then error("queue is empty") end
        local ret = self.data[self.head]
        self.data[self.head] = nil
        self.head = self.head + 1
        self.num = self.num - 1
        return ret
    end

    function tab.pop_back(self)
        if self.head > self.tail then error("queue is empty") end
        local ret = self.data[self.tail]
        self.data[self.tail] = nil
        self.tail = self.tail - 1
        self.num = self.num - 1
        return ret
    end

    function tab.push_back(self,data)
        self.tail = self.tail + 1
        self.num = self.num + 1
        self.data[self.tail] = data
    end

    function tab.push_front(self,data)
        self.head = self.head - 1
        self.data[self.head] = data
        self.num = self.num + 1
    end

    function tab.front(self)
        if self.head > self.tail then error("queue is empty") end
        return self.data[self.head]
    end

    function tab.back(self)
        if self.head > self.tail then error("queue is empty") end
        return self.data[self.tail]
    end

    function tab.empty(self)
        return self.head > self.tail
    end

    function tab.clear(self)
        tab.data = {}
        tab.head = 0
        tab.tail = -1
        tab.num = 0
    end

    function tab.size(self)
        return self.num
    end

    function tab.append(self,tab2)
        for i = tab2.head,tab2.tail do
            self:push_back(tab2.data[i])
        end
    end
    return tab
end


---

CASSIE = {}
CASSIE.broadcast = deque.Create()
CASSIE.soundchannels = {}
CASSIE.space_delay = 1
CASSIE.background_delay = 4
CASSIE.word_pause = 0.1

function CASSIE:AddBroadcastMessage(table,enablebg)
    if #table < 1 then return end
    CASSIE.broadcast = CASSIE.broadcast or queue.Create()
    local totaltime = 0
    local jam = nil
    local pitch = 100
    local result = deque.Create()

    for k,v in pairs(table) do
        v = string.Trim(v):lower()
        if string.find(v,'^p%d+$') then
            pitch = math.Clamp(tonumber(string.sub(v,2)),1,200)
        elseif string.find(v,'^j%d%d%d_%d$') then
            jam = {
                delay = math.Clamp(tonumber(string.sub(v,2,4)) or 1,1,999),
                amount = math.Clamp(tonumber(string.sub(v,6,6)) or 1,1,9)
            }

        elseif v == '.' then
            totaltime = totaltime + CASSIE.space_delay
            result:push_back({space = true})
        else
            local sound = {}
            sound.name = "cassie/words/"..v..".wav"
            sound.pitch = pitch
            sound.jam = jam
            sound.duration = SoundDuration("cassie/words/"..v..".wav")
            sound.pause = CASSIE.word_pause
            totaltime = totaltime + sound.duration/pitch*100
            if jam then
                totaltime = totaltime + jam.delay/1000 * jam.amount
            end
            result:push_back(sound)
            jam = nil
        end
    end

    if enablebg then
        totaltime = math.Clamp(totaltime + CASSIE.background_delay,4,40)
        totaltime = math.Round(totaltime)
        if totaltime == 14 then totaltime = 15 end
        result:push_front({
            name = "cassie/background/bg_"..totaltime ..".wav",
            duration = 2.5,
            pitch = 100,
            bg = true
        })
        result:back().pause = result:back().pause + CASSIE.background_delay
    end

    CASSIE.broadcast:append(result)
end

function CASSIE:ClearBroadcast()
    if timer.Exists("CASSIE_Timer") then
        timer.Remove("CASSIE_Timer")
    end
    CASSIE.broadcast:clear()
    if CASSIE.soundchannels.background then
        LocalPlayer():StopSound(CASSIE.soundchannels.background)
    end
    if CASSIE.soundchannels.word then
        LocalPlayer():StopSound(CASSIE.soundchannels.word)
    end
end


function CASSIE:Read()
    if CASSIE.broadcast:empty() then
        CASSIE:ClearBroadcast()
        return
    end
    local sound = CASSIE.broadcast:front()
    local time = 0
    if CASSIE.soundchannels.word then LocalPlayer():StopSound(CASSIE.soundchannels.word) end
    if sound.space then
        CASSIE.broadcast:pop_front()
        time = CASSIE.space_delay
    else
        if sound.bg then
            CASSIE.soundchannels.background = sound.name
        else

            CASSIE.soundchannels.word = sound.name
        end

        if sound.jam and sound.jam.amount > 0 then

            sound.jam.amount = sound.jam.amount - 1
            time = sound.jam.delay/1000 or 0
        --

        else
            CASSIE.broadcast:pop_front()
            time = sound.duration/sound.pitch*100 + (sound.pause or 0)
        end
        LocalPlayer():EmitSound(sound.name,100,sound.pitch,1,CHAN_AUTO,0,3)
    end

    timer.Create('CASSIE_Timer',time,1,function()
        CASSIE:Read()
    end )

end
