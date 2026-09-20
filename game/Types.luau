export type Preferences = {
    motion: boolean,
    sfx: boolean,
    music: boolean,
    hover: boolean,
    notifications: boolean,
    autoOrbit: boolean,
    previews: boolean,
    particles: boolean,
    masterVolume: number,
    sfxVolume: number,
    musicVolume: number,
    orbitSpeed: number,
    accentTheme: string,
}

export type DailyProgress = {
    day: string,
    streak: number,
    claimed: number,
    boosts: number,
}

export type PlayerState = {
    compute: number,
    totalEarned: number,
    jobs: number,
    owned: {[string]: number},
    research: {[string]: number},
    claimed: {[string]: boolean},
    achievements: {[string]: boolean},
    daily: DailyProgress,
    settings: Preferences,
    boostUntil: number,
    boostReady: number,
    canSave: boolean,
    callsign: string,
}

return nil


