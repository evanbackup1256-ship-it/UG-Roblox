-- Type-only module: the context every InterfacePage* module receives as its
-- single `Shared` argument. No runtime content — InterfaceController.luau
-- builds the actual table; this just gives page modules something to
-- annotate against so a typo/missing field is caught by the type checker
-- instead of only surfacing as a runtime nil-index in Studio.
export type SharedFn = {
	switchPage: (string) -> (),
	apply: (any) -> (),
	act: (string, string?, any?, boolean?) -> (),
	notify: (string, boolean?, string?) -> (),
	showTutorial: (number?) -> (),
	revealPageChange: (string) -> (),
	settingRefresh: { () -> () },
	stopDrag: () -> (),
}

export type Shared = {
	-- read-only references
	Kit: any,
	Config: any,
	Icons: any,
	C: any,
	director: any,
	player: Player,
	Shop: any,
	SpringDriver: any,
	Tokens: any,

	-- mutable fields, reassigned in place by the orchestrator, read fresh
	-- by pages on every access (never cache these in a page-local)
	state: any,
	preferences: any,
	selected: string,
	pending: boolean,
	hydrated: boolean,
	userCaused: boolean,
	-- The Infrastructure page owns the buy-quantity selector's value (its
	-- cycling button mutates this), but act()'s "buy" branch — defined in
	-- the orchestrator, before Infrastructure builds — needs to read the
	-- current selection when the player clicks Deploy. Kept in sync the
	-- same way as the other mutable fields above.
	quantity: number,

	-- lifecycle helpers
	own: (any) -> any,
	connect: (RBXScriptSignal, (...any) -> ()) -> RBXScriptConnection,
	release: (any) -> (),
	run: ((...any) -> ()) -> (),
	defer: (number, (...any) -> ()) -> thread,
	cancel: (thread) -> (),

	-- page scaffolding
	pages: { [string]: ScrollingFrame },
	layouts: { [string]: (number) -> () },
	updates: { [string]: { (any) -> () } },
	nav: { [string]: any },
	bind: (string, (any) -> ()) -> (),
	layoutPage: (string, (number) -> number) -> (),
	relayout: (string) -> (),
	positionText: (Instance, string, string, number, number, number, number, number, Color3, boolean?) -> TextLabel,
	pager: (Instance, (...any) -> (), (...any) -> ()) -> (...any) -> (),

	-- shared UI helpers
	liven: (any, number?) -> any,
	bump: (any) -> () -> (),
	fmt: (number) -> string,
	bumpPeak: (number) -> number | boolean,
	trace: (string, ...any) -> (),
	traceWarn: (string, ...any) -> (),
	refreshPresentation: () -> (),
	Preferences: RemoteEvent,
	Leaderboard: RemoteFunction,

	-- late-bound mutuals (see the forward-declare pattern in
	-- InterfaceController.luau) — always call Shared.fn.X(...) inline at
	-- the callback site, never cache a page-local `local x = Shared.fn.X`,
	-- since fn.X is only assigned its real value after every page module's
	-- build() has already run.
	fn: SharedFn,
}

return {}
