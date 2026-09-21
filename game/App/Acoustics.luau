--!strict
-- Acoustics: High-craft acoustic sound design suite for the App framework
-- Organic mechanical button clicks, tactile slider detents, pitch randomization (+-3.5%),
-- and two-source crossfading ambient synthesizer soundtrack.
local SoundService = game:GetService("SoundService")

local Acoustics = {}
Acoustics.__index = Acoustics

local MUSIC_TRACKS = { "9042295159", "9042294694", "9042293112" }

local cueDefs = {
	hover = { "139800881181209", 0.05, 1.12, 3, 0.08, true },
	press = { "75490872912178", 0.06, 0.95, 2, 0.04 },
	release = { "75490872912178", 0.06, 1.10, 2, 0.04 },
	click = { "88442833509532", 0.20, 1.00, 3, 0.05 },
	tab = { "75490872912178", 0.12, 1.05, 2, 0.10 },
	confirm = { "137214903496040", 0.26, 1.18, 2, 0.12 },
	denied = { "87519554692663", 0.18, 0.90, 1, 0.18 },
	upgrade = { "137214903496040", 0.24, 1.25, 2, 0.12 },
	purchase = { "88442833509532", 0.25, 0.88, 2, 0.15 },
	reward = { "137214903496040", 0.32, 1.35, 2, 0.20 },
	milestone = { "137214903496040", 0.40, 1.45, 2, 0.30 },
	toggle_on = { "75490872912178", 0.12, 1.22, 1, 0.08 },
	toggle_off = { "75490872912178", 0.10, 0.86, 1, 0.08 },
	slider = { "139800881181209", 0.05, 1.30, 2, 0.06 },
	input = { "139800881181209", 0.06, 0.98, 1, 0.10 },
	error = { "87519554692663", 0.22, 0.92, 1, 0.20 },
	notice = { "137214903496040", 0.16, 1.10, 2, 0.15 },
}

local defaultInstance: any = nil

local function ensureDefault(): any
	if not defaultInstance then
		defaultInstance = Acoustics.new()
	end
	return defaultInstance
end

function Acoustics.new(preferences: any?, isAlive: (() -> boolean)?)
	local self = setmetatable({}, Acoustics)
	self.rng = Random.new()
	self.preferences = preferences or {
		masterVolume = 0.8,
		sfxVolume = 0.9,
		musicVolume = 0.5,
		sfx = true,
		music = true,
		hover = true,
	}
	self.isAlive = isAlive or function() return true end

	-- Sound Groups
	local effectsMix = Instance.new("SoundGroup")
	effectsMix.Name = "AppAcousticsGroup"
	effectsMix.Volume = 1
	effectsMix.Parent = SoundService
	self.effectsMix = effectsMix

	local limiter = Instance.new("CompressorSoundEffect")
	limiter.Name = "AcousticLimiter"
	limiter.Threshold = -6
	limiter.Ratio = 3
	limiter.Attack = 0.015
	limiter.Release = 0.15
	limiter.Parent = effectsMix

	local musicMix = Instance.new("SoundGroup")
	musicMix.Name = "AppMusicGroup"
	musicMix.Volume = 0.4
	musicMix.Parent = SoundService
	self.musicMix = musicMix

	local soundFolder = Instance.new("Folder")
	soundFolder.Name = "AppAcousticsSounds"
	soundFolder.Parent = SoundService
	self.soundFolder = soundFolder

	local soundPools = {}
	local soundCursors = {}
	local cueTimers = {}

	for name, def in pairs(cueDefs) do
		local pool = {}
		for i = 1, def[4] do
			local s = Instance.new("Sound")
			s.Name = string.format("%s_%02d", name, i)
			s.SoundId = "rbxassetid://" .. def[1]
			s.Volume = def[2]
			s.PlaybackSpeed = def[3]
			s.SoundGroup = effectsMix
			s.Parent = soundFolder
			pool[i] = s
		end
		soundPools[name] = pool
		soundCursors[name] = 0
	end

	self.soundPools = soundPools
	self.soundCursors = soundCursors
	self.cueTimers = cueTimers
	self.lastGestureSound = nil

	-- Setup Music Sources (Dual source cross-fading)
	local function makeMusicSource(name: string)
		local s = Instance.new("Sound")
		s.Name = name
		s.Volume = 0
		s.SoundGroup = musicMix
		s.Parent = soundFolder
		return s
	end

	self.musicSources = { makeMusicSource("MusicA"), makeMusicSource("MusicB") }
	self.activeTrackIndex = 1
	self.currentSourceIdx = 1

	-- Setup track advance
	for idx, s in ipairs(self.musicSources) do
		s.Ended:Connect(function()
			if idx == self.currentSourceIdx then
				self:advanceMusic()
			end
		end)
	end

	defaultInstance = self
	self:syncVolumes()
	self:startMusic()

	return self
end

function Acoustics:advanceMusic()
	if not self.isAlive() then return end
	local nextTrackIdx = (self.activeTrackIndex % #MUSIC_TRACKS) + 1
	self.activeTrackIndex = nextTrackIdx

	local prevSource = self.musicSources[self.currentSourceIdx]
	self.currentSourceIdx = if self.currentSourceIdx == 1 then 2 else 1
	local nextSource = self.musicSources[self.currentSourceIdx]

	nextSource.SoundId = "rbxassetid://" .. MUSIC_TRACKS[nextTrackIdx]
	nextSource.TimePosition = 0
	nextSource.Volume = 0
	nextSource:Play()

	local targetVol = self:calculateMusicVolume()
	local duration = 2.0
	local steps = 20
	task.spawn(function()
		for step = 1, steps do
			task.wait(duration / steps)
			local alpha = step / steps
			nextSource.Volume = targetVol * alpha
			prevSource.Volume = targetVol * (1 - alpha)
		end
		prevSource:Stop()
	end)
end

function Acoustics:calculateMusicVolume(): number
	if self.preferences.music == false then return 0 end
	local master = self.preferences.masterVolume or 0.8
	local music = self.preferences.musicVolume or 0.5
	return 0.45 * master * music
end

function Acoustics:syncVolumes()
	if self.musicMix then
		self.musicMix.Volume = self:calculateMusicVolume()
	end
end

function Acoustics:startMusic()
	if self.preferences.music == false then return end
	local src = self.musicSources[self.currentSourceIdx]
	src.SoundId = "rbxassetid://" .. MUSIC_TRACKS[self.activeTrackIndex]
	src.Volume = self:calculateMusicVolume()
	src:Play()
end

local GESTURE_HUSH = { hover = true, press = true, release = true, click = true }

local function executePlay(inst: any, cueName: string, pitchVariation: number?)
	if not inst.isAlive() then return end
	if inst.preferences and inst.preferences.sfx == false then return end

	local def = cueDefs[cueName]
	if not def then return end

	if def[6] and inst.preferences and inst.preferences.hover == false then
		return
	end

	local now = os.clock()
	if now - (inst.cueTimers[cueName] or -math.huge) < def[5] then
		return
	end
	inst.cueTimers[cueName] = now

	if GESTURE_HUSH[cueName] and inst.lastGestureSound and inst.lastGestureSound.Playing then
		inst.lastGestureSound:Stop()
		inst.lastGestureSound = nil
	end

	local pool = inst.soundPools[cueName]
	if not pool or #pool == 0 then return end

	local cursor = inst.soundCursors[cueName] % #pool + 1
	inst.soundCursors[cueName] = cursor
	local sound = pool[cursor]

	sound:Stop()
	sound.TimePosition = 0

	local master = (inst.preferences and inst.preferences.masterVolume) or 0.8
	local sfx = (inst.preferences and inst.preferences.sfxVolume) or 0.9
	sound.Volume = def[2] * master * sfx

	local variance = pitchVariation or 0.035
	local delta = inst.rng:NextNumber(-variance, variance)
	sound.PlaybackSpeed = def[3] + delta

	sound:Play()

	if GESTURE_HUSH[cueName] then
		inst.lastGestureSound = sound
	end
end

-- Universal play method: supports Acoustics.play(name), Acoustics:play(name), inst:play(name), inst.play(name)
function Acoustics.play(selfOrCue: any, cueOrPitch: any, maybePitch: any)
	if selfOrCue == Acoustics then
		local inst = ensureDefault()
		executePlay(inst, cueOrPitch, maybePitch)
	elseif type(selfOrCue) == "table" and (selfOrCue :: any).soundPools then
		executePlay(selfOrCue, cueOrPitch, maybePitch)
	else
		local inst = ensureDefault()
		executePlay(inst, selfOrCue, cueOrPitch)
	end
end

function Acoustics.setMasterVolume(selfOrVal: any, val: any)
	local target: any
	local v: number
	if selfOrVal == Acoustics then
		target = ensureDefault()
		v = val
	elseif type(selfOrVal) == "table" and (selfOrVal :: any).musicMix then
		target = selfOrVal
		v = val
	else
		target = ensureDefault()
		v = selfOrVal
	end
	target.preferences.masterVolume = math.clamp(v or 0, 0, 1)
	target:syncVolumes()
end

function Acoustics.setSfxVolume(selfOrVal: any, val: any)
	local target: any
	local v: number
	if selfOrVal == Acoustics then
		target = ensureDefault()
		v = val
	elseif type(selfOrVal) == "table" and (selfOrVal :: any).musicMix then
		target = selfOrVal
		v = val
	else
		target = ensureDefault()
		v = selfOrVal
	end
	target.preferences.sfxVolume = math.clamp(v or 0, 0, 1)
end

function Acoustics.setMusicVolume(selfOrVal: any, val: any)
	local target: any
	local v: number
	if selfOrVal == Acoustics then
		target = ensureDefault()
		v = val
	elseif type(selfOrVal) == "table" and (selfOrVal :: any).musicMix then
		target = selfOrVal
		v = val
	else
		target = ensureDefault()
		v = selfOrVal
	end
	target.preferences.musicVolume = math.clamp(v or 0, 0, 1)
	target:syncVolumes()
end

function Acoustics:Destroy()
	pcall(function()
		if self.effectsMix then self.effectsMix:Destroy() end
		if self.musicMix then self.musicMix:Destroy() end
		if self.soundFolder then self.soundFolder:Destroy() end
	end)
	if defaultInstance == self then
		defaultInstance = nil
	end
end

function Acoustics.destroy()
	if defaultInstance then
		local inst = defaultInstance
		defaultInstance = nil
		inst:Destroy()
	end
end

return Acoustics
