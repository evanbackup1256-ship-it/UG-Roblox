--!strict
-- AppContext: Shared runtime context passed to all Screen modules
export type Context = {
	-- Kit and Design System
	Theme: any,
	Springs: any,
	Elements: any,
	Buttons: any,
	Inputs: any,
	Feedback: any,
	Acoustics: any,
	Odometer: any,
	C: any,

	-- Static references
	Config: any,
	Icons: any,
	player: Player,
	Shop: any,
	director: any,

	-- Live reactive state (reassigned in place on server snapshot)
	state: any,
	preferences: any,
	selectedScreen: string,
	quantity: number,

	-- Screen containers & scaffolding
	screens: { [string]: ScrollingFrame },
	bind: (screenKey: string, onUpdate: (state: any) -> ()) -> (),
	layoutScreen: (screenKey: string, layoutFn: (viewportWidth: number) -> number) -> (),
	relayout: (screenKey: string) -> (),

	-- Action & Navigation Callbacks
	act: (kind: string, key: string?, amount: any?, silent: boolean?) -> (),
	switchScreen: (screenKey: string) -> (),
	notify: (message: string, isError: boolean?, title: string?) -> (),
	showTour: (step: number?) -> (),
	settingRefresh: { () -> () },
	savePreferences: ((prefs: any) -> ())?,
	getLeaderboard: ((category: string?) -> any)?,

	-- Helpers
	fmt: (val: number) -> string,
	connect: (signal: RBXScriptSignal, callback: (...any) -> ()) -> RBXScriptConnection,
	defer: (delaySeconds: number, fn: (...any) -> ()) -> thread,
	cancel: (threadObj: thread) -> (),
	own: (cleanupFn: any) -> any,
}

local AppContext = {}
return AppContext

