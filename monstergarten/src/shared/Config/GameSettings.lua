--!strict
-- Global tunables.
return {
	ShiftDuration = 480,
	ClockStart = 7,
	ClockEnd = 19,
	ParentsWarningAt = 450,
	CutsceneLength = 7,
	MaxSessions = 4,
	MaxPlayersPerShift = 6,
	QueueCountdown = 15,
	SessionSpacing = 1000,
	InteractRange = 12,
	RateLimitPerSecond = 10,
	NeedReplicateRate = 4, -- per second
	AITickRate = 0.25,
	NeedTickRate = 0.25,
	ResultsTimeout = 25,
	AutosaveInterval = 60,
	LeaderboardInterval = 60,
	MaxFires = 25,
	MaxPuddles = 60,
	MaxTrash = 40,
	FurnitureMaxHP = 100,
	WalkSpeed = 16,
	RunSpeed = 24,
	DebugUserIds = {} :: { number }, -- extra user ids allowed to use the F2 debug menu outside Studio
	RunTestsOnStart = false, -- set true (or Workspace attribute RunTests=true) to run unit tests in Studio
	DataStoreName = "MonstergartenPlayerData_v1",
}
