local Config = {}
Config.Tiers = {
	{
		key = "rack",
		name = "Server rack",
		subtitle = "A standard 42U cabinet with room for twelve compute trays.",
		cost = 10,
		growth = 1.15,
		rate = 0.5,
		unlock = 0,
		color = Color3.fromRGB(133, 232, 193),
		icon = "infrastructure"
	},
	{
		key = "node",
		name = "Compute node",
		subtitle = "A compact dual-socket worker for steady batch traffic.",
		cost = 100,
		growth = 1.17,
		rate = 4,
		unlock = 5,
		color = Color3.fromRGB(151, 188, 249),
		icon = "operations"
	},
	{
		key = "cluster",
		name = "Edge cluster",
		subtitle = "Three nodes and a local cache behind one edge switch.",
		cost = 1200,
		growth = 1.19,
		rate = 35,
		unlock = 15,
		color = Color3.fromRGB(197, 176, 245),
		icon = "research"
	},
	{
		key = "datacenter",
		name = "Data center",
		subtitle = "A staffed regional site with redundant power and transit.",
		cost = 15000,
		growth = 1.22,
		rate = 300,
		unlock = 30,
		color = Color3.fromRGB(237, 201, 140),
		icon = "shop"
	},
	{
		key = "gpu",
		name = "GPU array",
		subtitle = "Eight accelerator trays wired for training and inference.",
		cost = 180000,
		growth = 1.2,
		rate = 2600,
		unlock = 45,
		color = Color3.fromRGB(136, 221, 241),
		icon = "operations"
	},
	{
		key = "quantum",
		name = "Quantum core",
		subtitle = "A cryogenic coprocessor reserved for specialist workloads.",
		cost = 2200000,
		growth = 1.2,
		rate = 22000,
		unlock = 65,
		color = Color3.fromRGB(204, 165, 250),
		icon = "research"
	},
	{
		key = "orbital",
		name = "Orbital relay",
		subtitle = "A low-orbit relay with a narrow, predictable contact window.",
		cost = 26000000,
		growth = 1.21,
		rate = 185000,
		unlock = 90,
		color = Color3.fromRGB(251, 181, 166),
		icon = "events"
	},
	{
		key = "fusion",
		name = "Fusion grid",
		subtitle = "Dedicated generation for sites that cannot shed load.",
		cost = 320000000,
		growth = 1.2,
		rate = 1600000,
		unlock = 120,
		color = Color3.fromRGB(249, 219, 139),
		icon = "rewards"
	},
	{
		key = "neural",
		name = "Neural nexus",
		subtitle = "An adaptive scheduler trained on your own traffic history.",
		cost = 4000000000,
		growth = 1.21,
		rate = 14000000,
		unlock = 160,
		color = Color3.fromRGB(163, 242, 185),
		icon = "contracts"
	},
	{
		key = "stellar",
		name = "Stellar engine",
		subtitle = "Experimental deep-space compute with extreme round-trip time.",
		cost = 50000000000,
		growth = 1.22,
		rate = 125000000,
		unlock = 200,
		color = Color3.fromRGB(197, 215, 255),
		icon = "changelog"
	},
}
local frontierSites = {
	{"Ashburn Row 04", "High-clock CPU trays beside the east-coast transit spine."},
	{"Frankfurt Transit 2", "A carrier-dense floor tuned for European routing."},
	{"Singapore Edge 7", "Low-latency capacity for the Malacca traffic corridor."},
	{"São Paulo Cache Hall", "Regional cache storage for bursty media workloads."},
	{"London Peering Floor", "Private interconnects close to the Docklands exchanges."},
	{"Tokyo Burst Cell", "Short-duration accelerator capacity with strict power limits."},
	{"Sydney Relay Bank", "A Pacific relay designed around long-haul redundancy."},
	{"Mumbai Memory Row", "Memory-heavy workers for large in-memory queues."},
	{"Toronto Cold Aisle", "Dense compute backed by a sealed liquid loop."},
	{"Stockholm Heat Loop", "Waste heat recovery offsets the site power bill."},
	{"Chicago Futures Rack", "Deterministic low-latency workers for market feeds."},
	{"Osaka Render Cage", "GPU capacity reserved for overnight render batches."},
	{"Madrid Archive Row", "Warm object storage with fast regional restore paths."},
	{"Johannesburg Route Hub", "Southern Africa transit with two independent uplinks."},
	{"Paris Inference Bay", "Quantized inference nodes for high-volume requests."},
	{"Seoul Tensor Floor", "Accelerator fabric joined by a dedicated leaf-spine."},
	{"Dallas Failover Hall", "Hot standby capacity on an isolated power feed."},
	{"Warsaw Storage Ring", "Erasure-coded storage distributed across four cages."},
	{"Dubai Exchange Pod", "A compact peering site for Gulf-region traffic."},
	{"Helsinki Heat Loop", "Cold-climate compute with direct outdoor cooling."},
	{"Reykjavík Hydro Hall", "Stable baseload power for continuous batch work."},
	{"Zurich Ledger Rack", "Audited storage and compute for regulated workloads."},
	{"Vienna Batch Yard", "Low-priority capacity that clears long queues cheaply."},
	{"Milan Media Cell", "Transcode workers with local high-throughput scratch disks."},
	{"Taipei Fabric Row", "High-bandwidth nodes beside the hardware supply chain."},
	{"Manila Queue House", "Elastic workers for uneven regional request volume."},
	{"Jakarta Traffic Bank", "Edge capacity built for dense mobile traffic."},
	{"Bangkok Session Vault", "Fast session storage replicated across three zones."},
	{"Auckland Pacific Edge", "A resilient endpoint for south-Pacific routes."},
	{"Santiago Andes Relay", "Cross-continent relay with independent mountain fiber."},
	{"Mexico City Metro Cache", "Urban cache nodes placed close to last-mile networks."},
	{"Bogotá Uplink Hall", "Regional aggregation with rapid route failover."},
	{"Lagos Backbone Row", "West African transit capacity on dual cable systems."},
	{"Nairobi Routing Cell", "East African edge compute with local traffic exchange."},
	{"Cape Town Cable House", "Landing-station compute for south Atlantic routes."},
	{"Cairo Archive Node", "Durable storage at the junction of three regions."},
	{"Casablanca Transit Rack", "A small Atlantic gateway with spare route capacity."},
	{"Lisbon Atlantic Edge", "Low-hop service for transatlantic control traffic."},
	{"Dublin Recovery Floor", "Snapshot restore capacity kept off the primary grid."},
	{"Amsterdam Peering Hall", "Dense interconnects for high-volume regional exchange."},
	{"Brussels Control Row", "Policy and orchestration nodes for the central region."},
	{"Prague Compiler Bay", "Build workers with aggressive local artifact caching."},
	{"Bucharest Storage Cell", "Cost-efficient replicated storage for cold datasets."},
	{"Athens Warm Standby", "Partially live capacity for Mediterranean failover."},
	{"Istanbul Gateway Rack", "A routing bridge between European and Asian regions."},
	{"Tel Aviv Security Pod", "Isolated analysis workers for incident response."},
	{"Doha Burst Reserve", "Power-rich spare capacity for scheduled traffic peaks."},
	{"Bengaluru Build Farm", "Parallel build workers backed by a shared cache."},
	{"Chennai Coastal Relay", "A cable-adjacent relay for Bay of Bengal traffic."},
	{"Hong Kong Exchange Cage", "Premium interconnect capacity inside the exchange."},
}
local frontierIcons = {"infrastructure", "operations", "research", "contracts", "rewards", "events"}
for i = 1, 50 do
	local site = frontierSites[i]
	table.insert(Config.Tiers, {
		key = "frontier_" .. string.format("%02d", i),
		name = site[1],
		subtitle = site[2],
		cost = math.floor(8e10 * (1.34 ^ (i - 1))),
		growth = 1.24 + (i % 4) * 0.01,
		rate = 2.5e8 * (1.32 ^ (i - 1)),
		unlock = 240 + (i - 1) * 35,
		color = Color3.fromHSV((i * 0.071) % 1, 0.42, 0.98),
		icon = frontierIcons[((i - 1) % #frontierIcons) + 1]
	})
end
Config.Research = {
	{
		key = "efficiency",
		name = "Parallel processing",
		subtitle = "Every machine produces 25% more per level.",
		cost = 150,
		growth = 2.8,
		max = 8
	},
	{
		key = "automation",
		name = "Job optimization",
		subtitle = "Manual jobs earn 100% more per level.",
		cost = 75,
		growth = 2.4,
		max = 8
	},
	{
		key = "cooling",
		name = "Liquid cooling",
		subtitle = "All production +15% per level.",
		cost = 300,
		growth = 2.6,
		max = 10,
		icon = "infrastructure"
	},
	{
		key = "network",
		name = "Fiber backbone",
		subtitle = "All production +20% per level.",
		cost = 700,
		growth = 2.7,
		max = 10,
		icon = "infrastructure"
	},
	{
		key = "cache",
		name = "Smart caching",
		subtitle = "Manual job payout +50% per level.",
		cost = 200,
		growth = 2.4,
		max = 10,
		icon = "operations"
	},
	{
		key = "scheduling",
		name = "Task scheduler",
		subtitle = "Shorten job cooldown by 0.04s per level.",
		cost = 450,
		growth = 2.5,
		max = 10,
		icon = "operations"
	},
	{
		key = "procurement",
		name = "Supply contracts",
		subtitle = "Infrastructure prices -3% per level.",
		cost = 1000,
		growth = 3,
		max = 10,
		icon = "contracts"
	},
	{
		key = "grants",
		name = "Research grants",
		subtitle = "Research prices -2% per level.",
		cost = 1500,
		growth = 3,
		max = 10,
		icon = "research"
	},
	{
		key = "bounties",
		name = "Premium clients",
		subtitle = "Contract rewards +10% per level.",
		cost = 2500,
		growth = 3,
		max = 10,
		icon = "contracts"
	},
	{
		key = "overclock",
		name = "Overclock tuning",
		subtitle = "Boost duration +5 seconds per level.",
		cost = 600,
		growth = 2.7,
		max = 10,
		icon = "operations"
	},
	{
		key = "energy",
		name = "Energy recovery",
		subtitle = "Reduce boost cooldown by 10s per level.",
		cost = 1200,
		growth = 2.8,
		max = 10,
		icon = "operations"
	},
	{
		key = "distributed",
		name = "Distributed systems",
		subtitle = "All production +30% per level.",
		cost = 20000,
		growth = 3.2,
		max = 10,
		icon = "infrastructure"
	},
	{
		key = "loadbalancing",
		name = "Adaptive load balancing",
		subtitle = "Route demand across your fleet for +18% production per level.",
		cost = 3500,
		growth = 2.9,
		max = 10,
		icon = "infrastructure"
	},
	{
		key = "edgecache",
		name = "Edge cache mesh",
		subtitle = "Cache hot workloads for +35% manual job payout per level.",
		cost = 4200,
		growth = 2.8,
		max = 10,
		icon = "operations"
	},
	{
		key = "finops",
		name = "FinOps automation",
		subtitle = "Negotiate infrastructure costs down by 2% per level.",
		cost = 5200,
		growth = 2.95,
		max = 10,
		icon = "shop"
	},
	{
		key = "insight",
		name = "Predictive insight",
		subtitle = "Reduce research costs by 1.5% per level.",
		cost = 6500,
		growth = 3.05,
		max = 10,
		icon = "research"
	},
	{
		key = "observability",
		name = "Deep observability",
		subtitle = "Premium contracts pay 8% more per level.",
		cost = 7800,
		growth = 3.1,
		max = 10,
		icon = "contracts"
	},
	{
		key = "autoscaling",
		name = "Predictive autoscaling",
		subtitle = "Shorten job cooldown by 0.025 seconds per level.",
		cost = 9000,
		growth = 3.15,
		max = 10,
		icon = "operations"
	},
	{
		key = "redundancy",
		name = "Fault-tolerant redundancy",
		subtitle = "Extend Overclock by 3 seconds per level.",
		cost = 12000,
		growth = 3.2,
		max = 10,
		icon = "rewards"
	},
	{
		key = "greencompute",
		name = "Green compute",
		subtitle = "Lower all production overhead with a 12% multiplier per level.",
		cost = 18000,
		growth = 3.25,
		max = 10,
		icon = "infrastructure"
	},
}
local expansionNames = {
	{"Kernel batching", "Batch compatible workloads for steadier production.", "production", 0.06, "operations"},
	{"Thermal telemetry", "React to thermal drift before capacity is lost.", "production", 0.055, "infrastructure"},
	{"Route synthesis", "Continuously find faster paths through the fleet.", "production", 0.065, "infrastructure"},
	{"Queue prediction", "Predict demand and prepare jobs before they arrive.", "job", 0.08, "operations"},
	{"Contract intelligence", "Score incoming work and improve every payout.", "reward", 0.06, "contracts"},
	{"Vendor federation", "Pool purchasing power across trusted suppliers.", "hardware", 0.018, "shop"},
	{"Open research", "Share discoveries to reduce future research costs.", "research", 0.015, "research"},
	{"Memory fabric", "Link memory pools into a faster shared fabric.", "production", 0.07, "operations"},
	{"Carbon scheduling", "Move workloads to efficient energy windows.", "production", 0.05, "rewards"},
	{"Burst compiler", "Compile repeat jobs into high-value bursts.", "job", 0.09, "operations"},
}
local programNames = {
	{"Scheduler coalescing", "Thermocouple mesh", "BGP route hints", "Demand forecaster", "Bid desk telemetry", "Vendor failover", "Research peering", "NUMA fabric", "Carbon windowing", "Hot-loop compiler"},
	{"Work-stealing queues", "Coolant flow model", "Anycast planner", "Arrival-rate model", "Contract risk model", "Multi-source purchasing", "Shared test corpus", "CXL memory pool", "Grid-aware dispatch", "Profile-guided builds"},
	{"Kernel fusion", "Thermal digital twin", "Route convergence lab", "Capacity simulator", "Automated bid desk", "Supplier clearinghouse", "Open benchmark network", "Disaggregated memory", "Carbon-aware autoscale", "Trace-driven compiler"},
}
for chapter = 1, 3 do
	for index, definition in ipairs(expansionNames) do
		table.insert(Config.Research, {
			key = string.format("program_%d_%02d", chapter, index),
			name = programNames[chapter][index],
			subtitle = definition[2],
			cost = math.floor((24000 * 3.2 ^ (chapter - 1)) * (1.32 ^ (index - 1))),
			growth = 2.65 + chapter * 0.12,
			max = 6,
			effect = definition[3],
			value = definition[4] + (chapter - 1) * 0.005,
			icon = definition[5],
		})
	end
end
Config.Contracts = {
	{
		key = "first",
		name = "First cabinet",
		subtitle = "Deploy your first server rack.",
		metric = "units",
		target = 1,
		reward = 25
	},
	{
		key = "fleet",
		name = "Ten-unit floor",
		subtitle = "Own 10 infrastructure units.",
		metric = "units",
		target = 10,
		reward = 200
	},
	{
		key = "flow",
		name = "25 C/s service",
		subtitle = "Reach 25 compute per second.",
		metric = "rate",
		target = 25,
		reward = 600
	},
	{
		key = "scale",
		name = "5K lifetime compute",
		subtitle = "Earn 5,000 compute in total.",
		metric = "earned",
		target = 5000,
		reward = 1500
	},
	{
		key = "empire",
		name = "500 C/s service",
		subtitle = "Reach 500 compute per second.",
		metric = "rate",
		target = 500,
		reward = 10000
	},
	{
		key = "builder",
		name = "Fifty-unit floor",
		subtitle = "Own 50 infrastructure units.",
		metric = "units",
		target = 50,
		reward = 25000
	},
	{
		key = "million",
		name = "One million processed",
		subtitle = "Earn 1 million compute.",
		metric = "earned",
		target = 1000000,
		reward = 250000
	},
	{
		key = "power",
		name = "10K C/s service",
		subtitle = "Reach 10,000 compute per second.",
		metric = "rate",
		target = 10000,
		reward = 100000
	},
	{
		key = "hundred",
		name = "Hundred-unit floor",
		subtitle = "Own 100 infrastructure units.",
		metric = "units",
		target = 100,
		reward = 1500000
	},
	{
		key = "frontier",
		name = "One-million C/s service",
		subtitle = "Reach 1 million compute per second.",
		metric = "rate",
		target = 1000000,
		reward = 20000000
	},
	{
		key = "billion",
		name = "One billion processed",
		subtitle = "Earn 1 billion compute.",
		metric = "earned",
		target = 1000000000,
		reward = 200000000
	},
	{
		key = "architect",
		name = "250-unit floor",
		subtitle = "Own 250 infrastructure units.",
		metric = "units",
		target = 250,
		reward = 3000000000
	},
	{
		key = "velocity",
		name = "Queue worker",
		subtitle = "Complete 25 manual jobs.",
		metric = "jobs",
		target = 25,
		reward = 7500000
	},
	{
		key = "signal",
		name = "100K C/s service",
		subtitle = "Reach 100,000 compute per second.",
		metric = "rate",
		target = 100000,
		reward = 12000000
	},
	{
		key = "network",
		name = "500-unit network",
		subtitle = "Own 500 infrastructure units.",
		metric = "units",
		target = 500,
		reward = 25000000
	},
	{
		key = "legacy",
		name = "Ten billion processed",
		subtitle = "Earn 10 billion compute in total.",
		metric = "earned",
		target = 10000000000,
		reward = 1000000000
	},
}
Config.Achievements = {
	{
		key = "first_deploy",
		name = "Rack online",
		subtitle = "Deploy your first infrastructure unit.",
		metric = "units",
		target = 1,
		reward = 100,
		icon = "operations"
	},
	{
		key = "ten_units",
		name = "Ten installed",
		subtitle = "Own 10 infrastructure units.",
		metric = "units",
		target = 10,
		reward = 500,
		icon = "infrastructure"
	},
	{
		key = "hundred_units",
		name = "Hundred installed",
		subtitle = "Own 100 infrastructure units.",
		metric = "units",
		target = 100,
		reward = 5000,
		icon = "infrastructure"
	},
	{
		key = "million_compute",
		name = "Million processed",
		subtitle = "Earn one million compute.",
		metric = "earned",
		target = 1000000,
		reward = 25000,
		icon = "rewards"
	},
	{
		key = "researcher",
		name = "Lab level five",
		subtitle = "Reach level 5 in any research track.",
		metric = "research",
		target = 5,
		reward = 2500,
		icon = "research"
	},
	{
		key = "all_research",
		name = "Baseline complete",
		subtitle = "Reach level 3 in every research track.",
		metric = "research_all",
		target = 3,
		reward = 10000,
		icon = "research"
	},
	{
		key = "daily_streak",
		name = "Seven-day rotation",
		subtitle = "Claim 7 daily rewards.",
		metric = "streak",
		target = 7,
		reward = 7500,
		icon = "rewards"
	},
	{
		key = "overclock",
		name = "First redline",
		subtitle = "Activate Overclock once.",
		metric = "boosts",
		target = 1,
		reward = 1000,
		icon = "operations"
	},
	{
		key = "velocity",
		name = "Twenty-five jobs",
		subtitle = "Complete 25 manual jobs.",
		metric = "jobs",
		target = 25,
		reward = 12000,
		icon = "operations"
	},
	{
		key = "high_availability",
		name = "100K live",
		subtitle = "Reach 100,000 compute per second.",
		metric = "rate",
		target = 100000,
		reward = 50000,
		icon = "infrastructure"
	},
	{
		key = "network_effect",
		name = "Five hundred installed",
		subtitle = "Own 500 infrastructure units.",
		metric = "units",
		target = 500,
		reward = 150000,
		icon = "contracts"
	},
	{
		key = "legacy_builder",
		name = "Ten billion processed",
		subtitle = "Earn 10 billion compute in total.",
		metric = "earned",
		target = 10000000000,
		reward = 5000000,
		icon = "rewards"
	},
}
Config.ShopOffers = {
    {
        key = "rack_package",
        name = "Starter fleet",
        subtitle = "Five server racks, ready to deploy.",
        tier = "rack",
        quantity = 5,
        color = Color3.fromRGB(151, 235, 197),
    },
    {
        key = "node_package",
        name = "Compute expansion",
        subtitle = "Five nodes for your next workload.",
        tier = "node",
        quantity = 5,
        color = Color3.fromRGB(151, 188, 249),
    },
    {
        key = "cluster_package",
        name = "Edge deployment",
        subtitle = "Five clusters. Room to scale.",
        tier = "cluster",
        quantity = 5,
        color = Color3.fromRGB(197, 176, 245),
    },
	{key = "datacenter_package", name = "Regional backbone", subtitle = "Three data centers for sustained expansion.", tier = "datacenter", quantity = 3, discount = 0.08, color = Color3.fromRGB(237, 201, 140)},
	{key = "gpu_package", name = "Training division", subtitle = "Three GPU arrays prepared for heavy workloads.", tier = "gpu", quantity = 3, discount = 0.09, color = Color3.fromRGB(136, 221, 241)},
	{key = "quantum_package", name = "Quantum reserve", subtitle = "Two quantum cores with priority deployment.", tier = "quantum", quantity = 2, discount = 0.1, color = Color3.fromRGB(204, 165, 250)},
	{key = "orbital_package", name = "Orbital network", subtitle = "Two relays configured as a resilient pair.", tier = "orbital", quantity = 2, discount = 0.11, color = Color3.fromRGB(251, 181, 166)},
	{key = "fusion_package", name = "Fusion foundation", subtitle = "A fusion grid package for mature operations.", tier = "fusion", quantity = 2, discount = 0.12, color = Color3.fromRGB(249, 219, 139)},
	{key = "neural_package", name = "Cognitive fabric", subtitle = "Two neural nexuses trained to grow together.", tier = "neural", quantity = 2, discount = 0.13, color = Color3.fromRGB(163, 242, 185)},
}

Config.Settings = {
	motion = true,
	sfx = true,
	music = true,
	hover = true,
	notifications = true,
	autoOrbit = false,
	previews = true,
	particles = true,
	masterVolume = 0.7,
	sfxVolume = 0.7,
	musicVolume = 0.22,
	orbitSpeed = 0.3
}

Config.Codes = {
	CLOUDSTART = { reward = 250, label = "Founder supply", description = "A welcome cache for every new operator.", category = "WELCOME" },
	DECK2026 = { reward = 750, label = "Launch celebration", description = "Launch-week compute for the community.", category = "EVENT" },
	FRONTIER = { reward = 1500, label = "Frontier cache", description = "A boost toward the first frontier systems.", category = "PROGRESS" },
	SMOOTHSYSTEMS = { reward = 2250, label = "Systems refresh", description = "Celebrating the performance and interface update.", category = "UPDATE" },
	FIFTYPROGRAMS = { reward = 3000, label = "Research grant", description = "Funding for the expanded research catalogue.", category = "UPDATE" },
}

Config.Gamepasses = {
	DoubleProduction = 0,
	Founder = 0
}

Config.Products = {
	ComputeStarter = { id = 0, amount = 2500, name = "Starter compute" },
	ComputeVault = { id = 0, amount = 15000, name = "Compute vault" }
}

Config.Changelogs = {
	{version = "2.0.0", date = "2026-09-14", title = "Dispatch build", tag = "SYSTEMS", entries = {"Added nine energy-limited dispatch types", "Added 36 firmware modules across three hardware generations", "Moved level, field data, reserve, and reputation into the control header", "Operation results and recharge costs are validated by the server"}},
	{version = "1.2.0", date = "2026-09-14", title = "Systems expansion", tag = "MAJOR", entries = {"Fifty research programs split into fast, paged catalogues", "Expanded fleet exchange with progression-aware bundles", "Guided onboarding, real loading milestones, and redesigned notifications", "Centered interaction motion across mouse, touch, and gamepad"}},
	{version = "1.1.0", date = "2026-09-13", title = "Interface rebuild", tag = "DESIGN", entries = {"Responsive navigation and page transitions", "Visibility-aware 3D preview rendering", "Live performance telemetry and saved accessibility settings"}},
	{version = "1.0.0", date = "2026-09-12", title = "Launch", tag = "RELEASE", entries = {"Infrastructure, research, contracts, achievements, daily rewards, codes, and overclocking", "Server-authoritative saves and economy actions"}},
}
Config.Changelog = Config.Changelogs[1]
Config.Tutorial = {
	{title = "You have the pager", body = "Control shows the numbers that matter during a shift: balance, throughput, installed units, energy, and field data.", icon = "overview", page = "overview"},
	{title = "Clear the queue", body = "The green control handles routine jobs. Installed hardware keeps working when you leave the page.", icon = "operations", page = "overview"},
	{title = "Use the dispatch board", body = "Each dispatch lists its success rate and energy draw. Repeat a type to improve its mastery rating.", icon = "operations", page = "operations"},
	{title = "Add hardware", body = "Hardware starts producing as soon as it is installed. Use search, filters, and quantity controls for large orders.", icon = "infrastructure", page = "infrastructure"},
	{title = "Fund the lab", body = "Lab work permanently changes throughput, pricing, payouts, or cooldowns. Costs rise with each level.", icon = "research", page = "research"},
	{title = "Install firmware", body = "Dispatches return field data. Spend it here to specialize the fleet instead of buying raw capacity.", icon = "modules", page = "modules"},
	{title = "Close the shift", body = "Check work orders, claim completed records, and read Bulletins for live codes before signing off.", icon = "rewards", page = "rewards"},
}
-- Each entry's `outcomes` table replaces the old hardcoded pass/fail/crit
-- split in ActionService:_operation with per-operation tunable tiers:
--   critical  - the original crit behavior, now named/tunable per-op.
--   flawless  - a new, rarer top tier gated behind a minimum combo streak
--               (state.operationCombo), so it rewards sustained runs
--               rather than being purely a lucky roll from a cold start.
-- flawless.chanceWithin is tuned down slightly for later/rarer operations,
-- consistent with how `chance` itself already scales down with unlock tier.
Config.Operations = {
	{key = "diagnostic", name = "Fleet diagnostic", subtitle = "Trace bottlenecks and recover stranded capacity.", energy = 12, reward = 80, data = 4, xp = 18, chance = 0.94, unlock = 1, icon = "operations",
		outcomes = {
			critical = {chanceWithin = 0.20, multiplier = 1.5, label = "critical"},
			flawless = {chanceWithin = 0.05, multiplier = 2.25, label = "flawless", minCombo = 5},
		}},
	{key = "migration", name = "Traffic migration", subtitle = "Move a live service between regions without dropping sessions.", energy = 18, reward = 220, data = 8, xp = 32, chance = 0.88, unlock = 2, icon = "infrastructure",
		outcomes = {
			critical = {chanceWithin = 0.20, multiplier = 1.5, label = "critical"},
			flawless = {chanceWithin = 0.05, multiplier = 2.25, label = "flawless", minCombo = 5},
		}},
	{key = "audit", name = "Security audit", subtitle = "Harden exposed services before the next scan.", energy = 24, reward = 540, data = 14, xp = 48, chance = 0.82, unlock = 3, icon = "contracts",
		outcomes = {
			critical = {chanceWithin = 0.19, multiplier = 1.5, label = "critical"},
			flawless = {chanceWithin = 0.045, multiplier = 2.25, label = "flawless", minCombo = 6},
		}},
	{key = "recovery", name = "Region restore", subtitle = "Rebuild a failed region from the last clean snapshot set.", energy = 32, reward = 1400, data = 24, xp = 70, chance = 0.76, unlock = 5, icon = "rewards",
		outcomes = {
			critical = {chanceWithin = 0.19, multiplier = 1.5, label = "critical"},
			flawless = {chanceWithin = 0.045, multiplier = 2.25, label = "flawless", minCombo = 6},
		}},
	{key = "launch", name = "Launch window", subtitle = "Hold latency targets through a scheduled traffic spike.", energy = 40, reward = 3800, data = 38, xp = 105, chance = 0.7, unlock = 7, icon = "operations",
		outcomes = {
			critical = {chanceWithin = 0.18, multiplier = 1.5, label = "critical"},
			flawless = {chanceWithin = 0.04, multiplier = 2.25, label = "flawless", minCombo = 7},
		}},
	{key = "research_grid", name = "Science allocation", subtitle = "Lease spare capacity to a university simulation grid.", energy = 48, reward = 9000, data = 60, xp = 150, chance = 0.65, unlock = 10, icon = "research",
		outcomes = {
			critical = {chanceWithin = 0.18, multiplier = 1.5, label = "critical"},
			flawless = {chanceWithin = 0.04, multiplier = 2.25, label = "flawless", minCombo = 7},
		}},
	{key = "orbital_sync", name = "Satellite pass", subtitle = "Process a latency-sensitive downlink during one contact window.", energy = 58, reward = 24000, data = 95, xp = 220, chance = 0.6, unlock = 14, icon = "events",
		outcomes = {
			critical = {chanceWithin = 0.17, multiplier = 1.5, label = "critical"},
			flawless = {chanceWithin = 0.035, multiplier = 2.25, label = "flawless", minCombo = 8},
		}},
	{key = "zero_day", name = "Zero-day containment", subtitle = "Isolate an unknown exploit without taking the fleet offline.", energy = 70, reward = 65000, data = 150, xp = 320, chance = 0.54, unlock = 19, icon = "codes",
		outcomes = {
			critical = {chanceWithin = 0.17, multiplier = 1.5, label = "critical"},
			flawless = {chanceWithin = 0.035, multiplier = 2.25, label = "flawless", minCombo = 8},
		}},
	{key = "singularity", name = "Climate model run", subtitle = "Complete a full-resolution forecast before the deadline.", energy = 85, reward = 180000, data = 240, xp = 480, chance = 0.48, unlock = 25, icon = "star",
		outcomes = {
			critical = {chanceWithin = 0.16, multiplier = 1.5, label = "critical"},
			flawless = {chanceWithin = 0.03, multiplier = 2.25, label = "flawless", minCombo = 10},
		}},
}

local moduleBlueprints = {
	{"Workload profiler", "Find waste in active workloads.", "production", 0.04},
	{"Hot-path compiler", "Optimize the code paths that matter.", "job", 0.07},
	{"Reserve capacitor", "Store more operational energy.", "energy", 8},
	{"Failure predictor", "Spot incidents before they cascade.", "success", 0.018},
	{"Outcome broker", "Negotiate stronger operation payouts.", "operation", 0.055},
	{"Trust ledger", "Build reputation faster after successful work.", "reputation", 0.08},
	{"Memory locality", "Keep high-traffic data close to compute.", "production", 0.045},
	{"Command macros", "Compress routine manual work.", "job", 0.075},
	{"Kinetic recovery", "Recover energy between operations faster.", "recovery", 0.08},
	{"Chaos harness", "Practice failures in a controlled environment.", "success", 0.02},
	{"Data refinery", "Extract more useful data from every operation.", "data", 0.07},
	{"Supplier graph", "Reduce infrastructure acquisition costs.", "hardware", 0.012},
}
local moduleNames = {
	{"Trace sampler", "Fast-path cache", "Reserve bank", "Incident lead", "Rate desk", "Trust journal", "Locality map", "Runbook keys", "Flywheel recovery", "Fault injector", "Packet sieve", "Vendor index"},
	{"Fleet profiler", "Ahead-of-time queue", "Capacitor bus", "Failure horizon", "Yield router", "Service record", "Memory fabric", "Command palette", "Regenerative loop", "Chaos chamber", "Signal refinery", "Supply exchange"},
	{"Continuous profiler", "Speculative executor", "Grid reserve", "Predictive governor", "Outcome market", "Public trust ledger", "Coherent memory plane", "Autonomous runbook", "Closed energy cycle", "Resilience twin", "Telemetry distillery", "Procurement network"},
}
Config.Modules = {}
for generation = 1, 3 do
	for index, blueprint in ipairs(moduleBlueprints) do
		table.insert(Config.Modules, {
			key = string.format("module_%d_%02d", generation, index),
			name = moduleNames[generation][index],
			subtitle = blueprint[2],
			effect = blueprint[3],
			value = blueprint[4] * (1 + (generation - 1) * 0.35),
			cost = math.floor(350 * 2.25 ^ (generation - 1) * 1.16 ^ (index - 1)),
			dataCost = math.floor(8 * 1.9 ^ (generation - 1) + index * generation),
			max = 5,
			unlock = (generation - 1) * 8 + math.floor((index - 1) / 3) + 1,
			icon = ({"modules", "operations", "energy", "reputation"})[((index - 1) % 4) + 1],
			-- Stored directly (not re-derived by parsing `key` with a regex
			-- later) since the generation is already known here at
			-- construction time — see modulesByGeneration below.
			generation = generation,
		})
	end
end
-- Pre-index Config.Modules by `effect` once at load time (Config.Modules is static
-- after construction above) so moduleEffect() below scans only the matching subset
-- instead of all entries on every call. Iteration order within each bucket matches
-- the original Config.Modules order, so summation order (and thus float rounding)
-- is unchanged.
local modulesByEffect = {}
for _, item in ipairs(Config.Modules) do
	if item.effect then
		local bucket = modulesByEffect[item.effect]
		if not bucket then
			bucket = {}
			modulesByEffect[item.effect] = bucket
		end
		table.insert(bucket, item)
	end
end
-- Same pre-indexing strategy, grouped by generation instead of effect, so
-- the "firmware_suite" synergy check (Config.synergyStatus below) scans
-- only 12 modules per generation instead of walking and regex-matching
-- all 36 on every call — this function runs on every server publish
-- (every player action and every ~0.5s production tick), so an O(modules)
-- scan there is a real, recurring cost worth avoiding.
local modulesByGeneration = {}
for _, item in ipairs(Config.Modules) do
	local bucket = modulesByGeneration[item.generation]
	if not bucket then
		bucket = {}
		modulesByGeneration[item.generation] = bucket
	end
	table.insert(bucket, item)
end
function Config.moduleEffect(state, effect)
	local bucket = modulesByEffect[effect]
	if not bucket then
		return 0
	end
	local value = 0
	local owned = state.modules or {}
	for _, item in ipairs(bucket) do
		value += (owned[item.key] or 0) * item.value
	end
	return value
end
function Config.level(state)
	return math.max(1, math.floor(math.sqrt((state.xp or 0) / 90)) + 1)
end
function Config.energyCapacity(state)
	return 100 + Config.moduleEffect(state, "energy")
end
function Config.moduleCost(item, level)
	return math.floor(item.cost * 2.15 ^ level), math.floor(item.dataCost * 1.7 ^ level)
end
-- Same pre-indexing strategy as modulesByEffect above, applied to Config.Research
-- (50 entries after the program-chapter loop). Preserves original iteration order
-- within each effect bucket.
local researchByEffect = {}
for _, item in ipairs(Config.Research) do
	if item.effect then
		local bucket = researchByEffect[item.effect]
		if not bucket then
			bucket = {}
			researchByEffect[item.effect] = bucket
		end
		table.insert(bucket, item)
	end
end
local function researchEffect(research, effect)
	local bucket = researchByEffect[effect]
	if not bucket then
		return 0
	end
	local value = 0
	for _, item in ipairs(bucket) do
		value += (research[item.key] or 0) * (item.value or 0)
	end
	return value
end
function Config.cost(tier, owned)
	return math.floor(tier.cost * tier.growth ^ owned)
end
function Config.buyCost(tier, owned, s)
	local r = s.research
	local reduction = (r.procurement or 0) * 0.03 + (r.finops or 0) * 0.02 + researchEffect(r, "hardware") + Config.moduleEffect(s, "hardware")
	return math.max(1, math.floor(Config.cost(tier, owned) * math.max(0.2, 1 - reduction)))
end
function Config.researchCost(item, owned, s)
	local r = s.research
	local reduction = (r.grants or 0) * 0.02 + (r.insight or 0) * 0.015 + researchEffect(r, "research")
	return math.max(1, math.floor(Config.cost(item, owned) * math.max(0.2, 1 - reduction)))
end
function Config.job(s)
	local r = s.research
	return 2 * (1 + (r.automation or 0)) * (1 + (r.cache or 0) * 0.5) * (1 + (r.edgecache or 0) * 0.35) * (1 + researchEffect(r, "job")) * (1 + Config.moduleEffect(s, "job"))
end
function Config.reward(c, s)
	local r = s.research
	return math.floor(c.reward * (1 + (r.bounties or 0) * 0.1) * (1 + (r.observability or 0) * 0.08) * (1 + researchEffect(r, "reward")))
end
-- `synergyStatus` is optional — pass a pre-computed one (see
-- Config.synergyBonus) to skip a redundant full synergy evaluation when
-- the caller already computed one for the same state, e.g.
-- StateService.public.
function Config.rate(state, synergyStatus)
	local value = 0
	for _, tier in ipairs(Config.Tiers) do
		value += (state.owned[tier.key] or 0) * tier.rate
	end
	local r = state.research
	return value * (1 + (r.efficiency or 0) * 0.25) * (1 + (r.cooling or 0) * 0.15) * (1 + (r.network or 0) * 0.2) * (1 + (r.distributed or 0) * 0.3) * (1 + (r.loadbalancing or 0) * 0.18) * (1 + (r.greencompute or 0) * 0.12) * (1 + researchEffect(r, "production")) * (1 + Config.moduleEffect(state, "production")) * (1 + Config.prestigeBonus(state)) * (1 + Config.synergyBonus(state, synergyStatus))
end
function Config.units(state)
	local value = 0
	for _, n in pairs(state.owned) do
		value += n
	end
	return value
end
function Config.metric(state, key)
	if key == "units" then
		return Config.units(state)
	end
	if key == "rate" then
		return Config.rate(state)
	end
	if key == "jobs" then
		return state.jobs or 0
	end
	return state.totalEarned
end

Config.Prestige = {
	threshold = 1e7,
	pointDivisor = 1e6,
	pointExponent = 0.5,
	rateBonusPerPoint = 0.02,
}

-- Points a reset would grant right now, based on lifetime compute earned
-- this run. Same formula used to preview the gain client-side and to
-- actually grant it in EconomyService.prestige, so the two never drift.
function Config.prestigePoints(state)
	local earned = state.totalEarned or 0
	if earned < Config.Prestige.threshold then
		return 0
	end
	return math.floor((earned / Config.Prestige.pointDivisor) ^ Config.Prestige.pointExponent)
end

-- Permanent production multiplier from banked prestige tokens (survives a reset).
function Config.prestigeBonus(state)
	return (state.prestigeTokens or 0) * Config.Prestige.rateBonusPerPoint
end

-- A synergy is a LIVE status (unlike one-time Achievements): active
-- whenever its condition holds over currently owned tiers/research/
-- modules, granting a global production bonus only while it holds. This
-- can't be expressed as a moduleEffect/researchEffect bucket (those sum a
-- per-owned-level value independently per key) since these conditions are
-- AND/threshold-across-multiple-keys — so it gets its own table and
-- functions, mirroring how prestigeBonus already sits outside the bucket
-- system.
Config.Synergies = {
	{
		key = "full_stack",
		name = "Full-stack fleet",
		description = "Own at least one unit of 4 different infrastructure tiers.",
		kind = "tiers",
		threshold = 4,
		pool = {"rack", "node", "cluster", "datacenter", "gpu"},
		bonus = 0.08,
		icon = "infrastructure",
	},
	{
		key = "research_triad",
		name = "Research triad",
		description = "Reach level 3+ in efficiency, cooling, and network research simultaneously.",
		kind = "researchLevel",
		threshold = 3,
		pool = {"efficiency", "cooling", "network"},
		bonus = 0.10,
		icon = "research",
	},
	{
		key = "firmware_suite",
		name = "Firmware suite",
		description = "Own at least 2 modules from 3 different generations.",
		kind = "moduleGenerations",
		threshold = 3,
		bonus = 0.12,
		icon = "modules",
	},
}

-- Returns {[synergyKey] = true/false, ...} for every Config.Synergies
-- entry, so the client can show progress toward inactive synergies, not
-- just the active bonus total.
function Config.synergyStatus(state)
	local status = {}
	for _, s in ipairs(Config.Synergies) do
		if s.kind == "tiers" then
			local count = 0
			for _, key in ipairs(s.pool) do
				if (state.owned[key] or 0) > 0 then
					count += 1
				end
			end
			status[s.key] = count >= s.threshold
		elseif s.kind == "researchLevel" then
			local met = true
			for _, key in ipairs(s.pool) do
				if (state.research[key] or 0) < s.threshold then
					met = false
					break
				end
			end
			status[s.key] = met
		elseif s.kind == "moduleGenerations" then
			local count = 0
			for generation, bucket in modulesByGeneration do
				for _, item in ipairs(bucket) do
					if (state.modules[item.key] or 0) >= 2 then
						count += 1
						break
					end
				end
			end
			status[s.key] = count >= s.threshold
		else
			status[s.key] = false
		end
	end
	return status
end

-- Sum of every currently-active synergy's bonus. Zero for any state with no
-- active synergies (every existing save on the day this ships), so
-- Config.rate stays bit-identical for players until they naturally qualify
-- for one.
--
-- Accepts an already-computed `status` (from Config.synergyStatus) to avoid
-- recomputing it — this function runs inside Config.rate, which itself
-- runs on every server publish (every action and every ~0.5s production
-- tick for every online player), so callers that already have a status in
-- hand (StateService.public) should pass it rather than pay for a second
-- full synergy evaluation.
function Config.synergyBonus(state, status)
	status = status or Config.synergyStatus(state)
	local bonus = 0
	for _, s in ipairs(Config.Synergies) do
		if status[s.key] then
			bonus += s.bonus
		end
	end
	return bonus
end

return Config
