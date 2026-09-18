local SoundService = game:GetService("SoundService")

local MusicManager = {}
MusicManager.__index = MusicManager

-- Real two-source crossfade, replacing the old single-Sound hard cut on
-- track end: while one Sound fades out, the other fades in underneath it,
-- so consecutive tracks overlap instead of the music going briefly silent
-- (or jarring straight into the next track) at every advance.
local TRACKS = { "9042295159", "9042294694", "9042293112" }
local CROSSFADE_DURATION = 2.2

function MusicManager.new(Kit, audio)
	local musicMix = Kit.create("SoundGroup", SoundService, {
		Name = "DeckInterfaceMusic",
		Volume = 0.42,
	})

	local function buildSound(name)
		local sound = Kit.create("Sound", audio, {
			Name = name,
			Volume = 0,
			SoundGroup = musicMix,
		})
		Kit.create("EqualizerSoundEffect", sound, {
			Name = "WarmMix",
			LowGain = 1.5,
			MidGain = -0.5,
			HighGain = -2,
		})
		return sound
	end

	local self = setmetatable({
		Kit = Kit,
		musicMix = musicMix,
		sources = { buildSound("MusicA"), buildSound("MusicB") },
		active = 1,
		track = 1,
		shuffle = Random.new(),
		targetVolume = 0,
		wantsPlaying = false,
		connections = {},
		crossfading = false,
	}, MusicManager)

	self.sources[self.active].SoundId = "rbxassetid://" .. TRACKS[self.track]

	for index, sound in ipairs(self.sources) do
		self.connections[index] = sound.Ended:Connect(function()
			if index == self.active then
				self:_advance()
			end
		end)
	end

	return self
end

-- Chooses the next track without an immediate repeat, same shuffle
-- discipline the previous single-Sound implementation used.
function MusicManager:_nextTrack()
	if #TRACKS <= 1 then
		return self.track
	end
	local nextTrack = self.shuffle:NextInteger(1, #TRACKS - 1)
	if nextTrack >= self.track then
		nextTrack += 1
	end
	return nextTrack
end

function MusicManager:_advance()
	local Kit = self.Kit
	local outgoing = self.sources[self.active]
	local incoming = self.sources[self.active == 1 and 2 or 1]

	self.track = self:_nextTrack()
	incoming.SoundId = "rbxassetid://" .. TRACKS[self.track]
	incoming.Volume = 0
	incoming:Play()

	self.crossfading = true
	Kit.animate(outgoing, { Volume = 0 }, CROSSFADE_DURATION, Enum.EasingStyle.Sine)
	Kit.animate(incoming, { Volume = self.targetVolume }, CROSSFADE_DURATION, Enum.EasingStyle.Sine)

	self.active = self.active == 1 and 2 or 1
	task.delay(CROSSFADE_DURATION, function()
		if self.active and outgoing.Parent then
			outgoing:Stop()
		end
		self.crossfading = false
	end)
end

-- Called from InterfaceController's refreshPresentation() with the same
-- masterVolume/musicVolume/pageMix weighting it always computed; this just
-- owns where that weight is actually applied now (the active source, and
-- the incoming source too if a crossfade is mid-flight so both sides track
-- a live preference change instead of only the one that started the fade).
function MusicManager:RefreshVolume(masterVolume, musicVolume, pageMix)
	local Kit = self.Kit
	self.targetVolume = masterVolume * musicVolume * pageMix

	local activeSound = self.sources[self.active]
	Kit.animate(activeSound, { Volume = self.targetVolume }, 0.8, Enum.EasingStyle.Sine)

	if self.crossfading then
		local incoming = self.sources[self.active == 1 and 2 or 1]
		Kit.animate(incoming, { Volume = self.targetVolume }, 0.8, Enum.EasingStyle.Sine)
	end
end

function MusicManager:SetPlaying(shouldPlay)
	self.wantsPlaying = shouldPlay
	local activeSound = self.sources[self.active]

	if shouldPlay then
		if not activeSound.IsPlaying then
			activeSound:Resume()
			if not activeSound.IsPlaying then
				activeSound:Play()
			end
		end
	else
		for _, sound in ipairs(self.sources) do
			if sound.IsPlaying then
				sound:Pause()
			end
		end
	end
end

-- Transient duck-on-SFX (InterfaceController's duckMusic) still targets the
-- SoundGroup directly, same as before — exposed so InterfaceController can
-- keep that call site unchanged.
function MusicManager:GetSoundGroup()
	return self.musicMix
end

function MusicManager:Destroy()
	for _, connection in self.connections do
		connection:Disconnect()
	end
	table.clear(self.connections)
	for _, sound in ipairs(self.sources) do
		sound:Destroy()
	end
	self.musicMix:Destroy()
end

return MusicManager
