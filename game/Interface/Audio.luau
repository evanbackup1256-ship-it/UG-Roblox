local SoundService = game:GetService("SoundService")

local Audio = {}
Audio.__index = Audio

-- Interaction-sound cue system: pools of Sound instances per named cue,
-- gesture-hush cooldown (so a fast click doesn't stack hover+press+release
-- +click as four audibly overlapping sounds), and music ducking while a
-- non-trivial cue plays. Extracted from InterfaceController.luau, which
-- previously built this inline and assigned the result directly to
-- Kit.sound. Kept together with duckMusic (rather than splitting it into
-- yet another module) since Kit.sound is duckMusic's only caller.
--
-- isAlive/preferences/defer/trace are passed in rather than closed over,
-- since this module has no access to the controller's own locals.
function Audio.new(Kit, preferences, isAlive, defer, trace, own)
	local self = setmetatable({}, Audio)

	local effectsMix = own(Kit.create("SoundGroup", SoundService, {
		Name = "DeckInterfaceEffects",
		Volume = 1,
	}))

	Kit.create("CompressorSoundEffect", effectsMix, {
		Name = "InterfaceLimiter",
		Threshold = -5,
		Ratio = 2.5,
		Attack = 0.02,
		Release = 0.12,
	})

	Kit.create("EqualizerSoundEffect", effectsMix, {
		Name = "Presence",
		LowGain = -1,
		MidGain = 1.5,
		HighGain = 2.5,
	})

	local audioFolder = own(Kit.create("Folder", SoundService, { Name = "DeckInterfaceAudio" }))

	-- press/click used to share one asset (88442833509532) at close pitch,
	-- fired ~100-200ms apart on every single click (mouse-down, then
	-- Activated) — close enough in timbre and timing to read as the same
	-- sound playing twice rather than two distinct cues. press mirrors
	-- release's asset (the light "up" tick) as a light "down" tick instead,
	-- so a click's two cues are audibly distinct rather than near-duplicates.
	local cueDefinitions = {
		hover = { "139800881181209", 0.055, 1.10, 2, 0.09, true },
		press = { "75490872912178", 0.060, 0.96, 2, 0.04 },
		release = { "75490872912178", 0.065, 1.12, 2, 0.05 },
		click = { "88442833509532", 0.220, 1.00, 2, 0.07 },
		confirm = { "137214903496040", 0.280, 1.16, 2, 0.12 },
		denied = { "87519554692663", 0.160, 0.92, 1, 0.18 },
		page = { "75490872912178", 0.120, 1.04, 2, 0.12 },
		notice = { "137214903496040", 0.160, 1.10, 2, 0.15 },
		error = { "87519554692663", 0.200, 0.92, 1, 0.20 },
		operation = { "137214903496040", 0.260, 0.94, 2, 0.18 },
		upgrade = { "137214903496040", 0.240, 1.22, 2, 0.15 },
		purchase = { "88442833509532", 0.240, 0.87, 2, 0.15 },
		reward = { "137214903496040", 0.320, 1.30, 2, 0.20 },
		toggle_on = { "75490872912178", 0.120, 1.20, 1, 0.10 },
		toggle_off = { "75490872912178", 0.100, 0.88, 1, 0.10 },
		slider = { "139800881181209", 0.050, 1.30, 2, 0.08 },
		input = { "139800881181209", 0.070, 0.96, 1, 0.12 },
		boot = { "75490872912178", 0.160, 0.82, 1, 0.30 },
		ready = { "137214903496040", 0.280, 1.25, 1, 0.30 },
		milestone = { "137214903496040", 0.380, 1.42, 2, 0.35 },
		lock = { "87519554692663", 0.180, 0.78, 1, 0.16 },
		flip = { "75490872912178", 0.100, 1.08, 2, 0.09 },
	}

	local sounds, soundCursor, cueClock = {}, {}, {}
	local cueCount = 0

	for name, definition in cueDefinitions do
		cueCount += 1
		local pool = {}
		for index = 1, definition[4] do
			pool[index] = Kit.create("Sound", audioFolder, {
				Name = string.format("%s_%02d", name, index),
				SoundId = "rbxassetid://" .. definition[1],
				Volume = definition[2],
				PlaybackSpeed = definition[3],
				SoundGroup = effectsMix,
			})
		end
		sounds[name] = pool
		soundCursor[name] = 0
	end

	trace("audio: %d interaction cues loaded", cueCount)

	local duckGeneration = 0

	function self.duckMusic(musicMix)
		if not preferences.music then
			return
		end

		duckGeneration += 1
		local generation = duckGeneration
		Kit.animate(musicMix, { Volume = 0.18 }, 0.08, Enum.EasingStyle.Quad)
		defer(0.36, function()
			if generation == duckGeneration then
				Kit.animate(musicMix, { Volume = 0.42 }, 0.24, Enum.EasingStyle.Quad)
			end
		end)
	end

	-- Cues in this set represent one physical gesture in quick succession
	-- (mouse enters, then presses, then releases/activates, all within
	-- maybe 100-200ms of each other for a fast click). Each used to cool
	-- down purely on its own name, so a quick click played hover+press+
	-- release+click as up to four independent, audibly overlapping sounds.
	-- Every cue in this set now hushes whichever gesture-hush cue played
	-- immediately before it (not just hover), so a fast click plays one
	-- clean cue at a time — press cut off by release, release cut off by
	-- the final click/confirm — instead of stacking.
	local GESTURE_HUSH = { hover = true, press = true, release = true, click = true, confirm = true, denied = true }
	local lastGestureSound = nil

	function self.playCue(name, musicMix)
		if not isAlive() or not preferences.sfx then
			return
		end

		local definition = cueDefinitions[name]
		if not definition then
			return
		end

		if definition[6] and not preferences.hover then
			return
		end

		if GESTURE_HUSH[name] and lastGestureSound and lastGestureSound.Playing then
			lastGestureSound:Stop()
			lastGestureSound = nil
		end

		local now = os.clock()
		if now - (cueClock[name] or -math.huge) < definition[5] then
			return
		end
		cueClock[name] = now

		local pool = sounds[name]
		local index = soundCursor[name] % #pool + 1
		soundCursor[name] = index

		local sound = pool[index]
		sound:Stop()
		sound.TimePosition = 0
		sound.Volume = definition[2] * preferences.masterVolume * preferences.sfxVolume
		sound:Play()

		if GESTURE_HUSH[name] then
			lastGestureSound = sound
		end

		if musicMix and name ~= "hover" and name ~= "press" and name ~= "release" and name ~= "slider" and name ~= "input" then
			self.duckMusic(musicMix)
		end
	end

	self.effectsMix = effectsMix
	self.audioFolder = audioFolder

	return self
end

return Audio
