// SVEN-COOP AUTOSPLITTER
// VERSION 1.1 - 2021/03/28
// GAME VERSIONS TESTED: 
// - Latest Steam version as of 2021/03/28
// - The version released on 2017/04/15
// - 2 versions from 2019 and one from 2016/09/03
// CREDITS:
// - 2838 for entity list functions, sigscanning functionality, reworks for all Auto-stops and some Auto-starts
// - SmileyAG for initial splitter codework
// - BenInSweden, Chillu and ScriptedSnark for additional code
// HOW TO USE: https://github.com/SmileyAG/Sven-Coop-Autosplitter/blob/master/README.md
// PLEASE REPORT THE PROBLEMS TO EITHER THE ISSUES SECTION IN THE GITHUB REPOSITORY ABOVE OR IN THE SVEN COOP DISCORD

// AUTO-STARTS TRIGGERS:
// - Uplink: when the player gets teleported outside the starting area
// - Other games: when the loading int changes from 1 to 0 and the map is correct

// AUTO-ENDS TRIGGERS
// - HL1: when Nihilanth's hp drops below or equal 0
// - They Hunger:
//	+ EP1: when the next think time of the ending multimanager entity goes above 0
//	+ EP2: when the valve's angular velocity goes from 0 to 40
//	+ EP3: when the final boss' hp drops below or equal 0
// - OP4: when the button's animation playback rate goes from 0 to 1
// - Uplink: when the hp of the vent at the end goes from 1 to 0

state("svencoop") {}

startup	// Settings
{	
	vars.startmaps = new List<string>() 
	{"hl_c01_a1", "of1a1", "ba_security1", "th_ep1_01", "th_ep2_00", "th_ep3_00", "dy_accident1"};
  
	settings.Add("global", false, "Global Settings");
		settings.Add("Autostart", false, "Enable autostart", "global");
		settings.Add("AutostartILs", false, "Enable autostart for ILs", "global");
		settings.Add("Reset", false, "Enable autoreset", "global");
	
	settings.Add("hl", false, "Half-Life");
		settings.Add("HL1stop", false, "Autostop for Half-Life", "hl");

	settings.Add("op4", false, "Opposing Force");
		settings.Add("OP4stop", false, "Autostop for Opposing Force", "op4");
	
	settings.Add("th", false, "They Hunger");
		settings.Add("EP1stop", false, "Autostop for Episode 1", "th");
		settings.Add("EP2stop", false, "Autostop for Episode 2", "th");
		settings.Add("EP3stop", false, "Autostop for Episode 3", "th");
	
	settings.Add("Uplink", false, "Uplink");
		settings.Add("Uplinkstart", false, "Autostart for Uplink", "Uplink");
		settings.Add("Uplinkstop", false, "Autostop for Uplink", "Uplink");

	settings.Add("misc", false, "Misc");
		settings.Add("HL1door", false, "Autostart for Half-Life upon door opening", "misc");
	
	// 2838: offsets for some elements in entvars typedef
    vars.entVarsOffs = new Dictionary<string, int>() {
        {"health"               	, 0x1E0},		// HEALTH
        {"xPos"             		, 0x88},		// X POSITION
		{"yPos"             		, 0x8C},		// Y POSITION
		{"zPos"             		, 0x90},		// Z POSITION
		{"xVel"             		, 0xA0},		// X SPEED
		{"yVel"             		, 0xA4},		// Y SPEED
		{"zVel"             		, 0xA8},		// Z SPEED
		{"max_health"             	, 0x230},		// MAXIMUM ALLOWED HEALTH
		{"target"					, 0x248},		// TARGET ENTITY
		{"targetname"				, 0x24C},		// NAME
		{"classname"				, 0x80},		// CLASS NAME
		{"globalname"				, 0x84},		// GLOBAL NAME
		{"modelname"				, 0x130},		// MODEL NAME
		{"framerate"				, 0x1B0},		// ANIMATION PLAYBACK RATE
		{"privatedata"				, 0x7C},		// POINTER TO EXTRA ENTITY DATA
		{"avelocityX"				, 0xDC},		// X ANGULAR SPEED
		{"avelocityY"				, 0xE0},		// Y ANGULAR SPEED
		{"avelocityZ"				, 0xE4},		// Z ANGULAR SPEED
		{"nextthink"				, 0x184}		// NEXT THINK TIME
    };

	// 2838: bools for deciding whether we should print debug info for various parts of the splitter
	vars.debugSwitches = new Dictionary<string, bool>() {
		{"ALL"						, true},		// SHOULD WE PRINT ANY DEBUG INFO?
		{"ENTFINDING"				, true},		// ENTITY FINDING FUNCTIONS
		{"SIGSCANNING"				, true},		// SIGSCANNING FUNCTIONS
	};

	// 2838: how many times should we retry finding an entity before stopping?
	vars.entFindRetries = 3;
	vars.aslVersion = "1.1 - 2021/03/28";
}

init // Version specific
{
	print("=========+++=========");
	print("SVEN COOP AUTOSPLITTER VERSION " + vars.aslVersion + " by 2838, SmileyAG, ScriptedSnark, BenInSweden and Chillu!");
	print("!! NOTE !! Auto-stops will only work for players hosting the server due to how the engine handles entities!");
	print("=========+++=========");

	Action<string, string> printtag = (tag, msg) => {
		if (vars.debugSwitches[tag] && vars.debugSwitches["ALL"])
			print("[" + tag + "] " + msg);
	};

	vars.printtag = printtag;

    var curMapSig = new SigScanTarget(2,  
        "80 3D ?? ?? ?? ?? 00",     // CMP byte ptr [map],0x0
        "74 ??", 
        "68 ?? ?? ?? ??",
        "50");

    curMapSig.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr;

    var curLoadingSig = new SigScanTarget(13,  
        "68 ?? ?? ?? ??",
        "D9 1D ?? ?? ?? ??",
        "C7 05 ?? ?? ?? ?? 01 00 00 00"); // MOV dword ptr [0x05f44af0],0x1

	// 2838: some versions swap the first 2 instructions
	curLoadingSig.AddSignature(13,
	    "D9 1D ?? ?? ?? ??",
		"68 ?? ?? ?? ??",
        "C7 05 ?? ?? ?? ?? 01 00 00 00");

    curLoadingSig.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr;

    var plyrPosSig = new SigScanTarget(22, 
		"C7 05 ?? ?? ?? ?? 01 00 00 00",
		"E8 ?? ?? ?? ??",
		"FF 15 ?? ?? ?? ??",
		"68 ?? ?? ?? ??"); 

    plyrPosSig.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr + 0x38;

	var entListSig = new SigScanTarget(8, 
		"69 ?? 24 03 00 00",
		"03 05 ?? ?? ?? ??"); // ADD EAX,dword ptr [entlist]

    entListSig.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr;

	var pStringBaseSig = new SigScanTarget(8, 
		"8b ?? ?? ?? ?? ??",
		"03 ?? ?? ?? ?? ??", // ADD EAX,dword ptr [0x06cf03ac]
		"??",
		"68 ?? ?? ?? ??",
		"E8 ?? ?? ?? ??",
		"D9 EE");

    pStringBaseSig.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr;

	var stateSig = new SigScanTarget(9, 
		"89 04 AD ?? ?? ?? ??",
		"83 3D ?? ?? ?? ?? 02"); // CMP dword ptr [state],0x2

    stateSig.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr;

	var globalSig = new SigScanTarget(24, 
		"78 1d 03 00",
		"89 ?? 50 02 00 00",
		"dd ?? ?? ?? ?? ??",
		"?? ?? ?? ?? ?? ??",
		"d9 ?? ?? ?? ?? ??"); // FSTP dword ptr [gpGlobals]

	// alternatives, needs 2 sigs but might be more reliable?
	globalSig.AddSignature(2, "D9 1D ?? ?? ?? ?? FF 15 ?? ?? ?? ?? D9 EE");
	globalSig.AddSignature(2, "D9 1D ?? ?? ?? ?? ?? FF 15 ?? ?? ?? ?? D9 EE");

    globalSig.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr;

    var profiler = Stopwatch.StartNew();

    // 2838: init process scanners, limit scope to hw.dll only
    ProcessModuleWow64Safe hw = modules.FirstOrDefault(x => x.ModuleName.ToLower() == "hw.dll");
    var hwScanner = new SignatureScanner(game, hw.BaseAddress, hw.ModuleMemorySize);

    IntPtr curMapPtr = hwScanner.Scan(curMapSig);
    IntPtr curLoadingPtr = hwScanner.Scan(curLoadingSig);
	IntPtr plyrXPosPtr = hwScanner.Scan(plyrPosSig);
	IntPtr plyrYPosPtr = plyrXPosPtr + 0x4;
	IntPtr entListPtr = hwScanner.Scan(entListSig);
	IntPtr pStringBasePtr = hwScanner.Scan(pStringBaseSig);
	IntPtr statePtr = hwScanner.Scan(stateSig);
	IntPtr globalPtr = hwScanner.Scan(globalSig);

	printtag("SIGSCANNING", (entListPtr == IntPtr.Zero ? ("Couldn't find entList ptr!") : ("Found entList ptr at 0x" + entListPtr.ToString("X"))));
	printtag("SIGSCANNING", (globalPtr == IntPtr.Zero ? ("Couldn't find globals ptr!") : ("Found globals ptr at 0x" + globalPtr.ToString("X"))));
	printtag("SIGSCANNING", (pStringBasePtr == IntPtr.Zero ? ("Couldn't find stringbase ptr!") : ("Found stringbase ptr at 0x" + pStringBasePtr.ToString("X"))));
    printtag("SIGSCANNING", (curMapPtr == IntPtr.Zero ?  "Couldn't find current map ptr!" : ("Found current map ptr at 0x" + curMapPtr.ToString("X"))));
    printtag("SIGSCANNING", (curLoadingPtr == IntPtr.Zero ? ("Couldn't find loading ptr!") : ("Found loading ptr at 0x" + curLoadingPtr.ToString("X"))));
	printtag("SIGSCANNING", (statePtr == IntPtr.Zero ? ("Couldn't find state ptr!") : ("Found state ptr at 0x" + statePtr.ToString("X"))));
	printtag("SIGSCANNING", (plyrXPosPtr == IntPtr.Zero ? ("Couldn't find player's pos ptr!") : ("Found player's pos ptr at 0x" + plyrXPosPtr.ToString("X"))));
	    
	printtag("SIGSCANNING", "Signature scanning complete after " + profiler.ElapsedMilliseconds * 0.001f + " seconds");
    profiler.Stop();

	// PURPOSE: check if a point is inside a defined bound in the XY plane
	Func<float, float, float, float, float, float, bool> CheckWithinBoundsXY = (x, y, xb1, xb2, yb1, yb2) => {
		return ((x >= ((xb1 < xb2) ? xb1 : xb2)) && 
				(x <= ((xb1 > xb2) ? xb1 : xb2)) && 
				(y >= ((yb1 < yb2) ? yb1 : yb2)) && 
				(y <= ((yb1 > yb2) ? yb1 : yb2)) );
	};

	// PURPOSE: uint to float byte cast -- convert bit-for-bit an uint to a float
	Func<uint, float> ui2fbc = (input) => {
		return BitConverter.ToSingle(BitConverter.GetBytes(input), 0);
	};

	// RESERVED FOR FUTURE USE
	// PURPOSE: reverse of above
	Func<float, uint> f2uibc = (input) => {
		return (uint)BitConverter.ToInt32(BitConverter.GetBytes(input),0);
	};

	// PURPOSE: returns a non-string property of an entity
	Func<IntPtr, string, uint> GetEntProperty = (ptr, propertyName) => {
		return memory.ReadValue<uint>(ptr + (int)vars.entVarsOffs[propertyName]);
	};

	// PURPOSE: string-only variant of above
	// 2838: strings are stored some distance away from the base string address
	Func<IntPtr, string, string> GetEntNameProperty = (ptr, propertyName) => {
		if (pStringBasePtr == IntPtr.Zero) return "";
		// 2838: this is some of the ugliest type casting i have ever done but intptr has forced my hand
		return memory.ReadString((IntPtr)((uint)memory.ReadPointer(pStringBasePtr) + memory.ReadValue<uint>(ptr + (int)vars.entVarsOffs[propertyName])), 256);
	};

	// PURPOSE: gets the entity pointer from its index
	Func<int, IntPtr> GetEntFromIndex = (index) => {
		if (entListPtr == IntPtr.Zero) return IntPtr.Zero;
		return memory.ReadPointer(entListPtr) + 804 * index;
	};

	// RESERVED FOR FUTURE USE
	// PURPOSE: reverse of above
	Func<IntPtr, int> GetIndexFromEnt = (ptr) => {
		return (int)((uint)ptr - (uint)memory.ReadPointer(entListPtr)) / 804;
	};

	// PURPOSE: find an entity using a non-string property of an entity
	Func<string, uint, IntPtr> FindEntByProperty = (property, value) => {
		int j = 0;
		for (j = 0; j < vars.entFindRetries; j++)
		{		
			for (int i = 0; i <= 2048; i++)
			{
				if (GetEntProperty(GetEntFromIndex(i),property) == value)
				{
					printtag("ENTFINDING", "Try #" + (j + 1) + ", found entity with " + property + " of " + value + " at " + i);
					return GetEntFromIndex(i);
				}
			}
			printtag("ENTFINDING", "Try #" + (j + 1) + ", couldn't find entity with " + property + " of " + value + "!");
		}
		printtag("ENTFINDING", "Couldn't find entity with " + property + " of " + value + " after " + j + " tries!");
		return IntPtr.Zero;
	};

	// PURPOSE: find an entity with a specific position
	Func<float, float, float, IntPtr> FindEntByPos = (x, y, z) => {
		if (memory.ReadPointer(entListPtr) == IntPtr.Zero) return IntPtr.Zero; 
		int j = 0;
		for (j = 0; j < vars.entFindRetries; j++)
		{		
			for (int i = 0; i <= 2048; i++)
			{
				IntPtr tmp = GetEntFromIndex(i);
				if (ui2fbc(GetEntProperty(tmp,"xPos")) == x && ui2fbc(GetEntProperty(tmp,"yPos")) == y && ui2fbc(GetEntProperty(tmp,"yPos")) == y)
				{
					printtag("ENTFINDING", "Try #" + (j + 1) + ", found entity with position " + x + " " + y + " " + z + " " + " at " + i);
					return tmp;
				}
			}
			printtag("ENTFINDING", "Try #" + (j + 1) + ", couldn't find entity with position " + x + " " + y + " " + z + "!");
		}
		printtag("ENTFINDING", "Couldn't find entity with position " + x + " " + y + " " + z + " after " + j + " tries!");
		return IntPtr.Zero;
	};

	// PURPOSE: string-only variant of above
	Func<string, string, IntPtr> FindEntByNameProperty = (property, value) => {
		if (memory.ReadPointer(entListPtr) == IntPtr.Zero) return IntPtr.Zero; 
		int j = 0;
		for (j = 0; j < vars.entFindRetries; j++)
		{		
			for (int i = 0; i <= 2048; i++)
			{
				if (GetEntNameProperty(GetEntFromIndex(i),property) == value)
				{
					printtag("ENTFINDING", "Try #" + (j + 1) + ", found entity with " + property + " of " + value + " at " + i);
					return GetEntFromIndex(i);
				}
			}
			printtag("ENTFINDING", "Try #" + (j + 1) + ", couldn't find entity with " + property + " of " + value + "!");
		}
		printtag("ENTFINDING", "Couldn't find entity with " + property + " of " + value + " after " + j + " tries!");
		return IntPtr.Zero;
	};

	vars.GetEntProperty = GetEntProperty;
	vars.FindEntByProperty = FindEntByProperty;
	vars.GetEntNameProperty = GetEntNameProperty;
	vars.GetEntFromIndex = GetEntFromIndex;
	vars.FindEntByNameProperty = FindEntByNameProperty;
	vars.GetIndexFromEnt = GetIndexFromEnt;
	vars.ui2fbc = ui2fbc;
	vars.f2uibc = f2uibc;
	vars.CheckWithinBoundsXY = CheckWithinBoundsXY;
	vars.FindEntByNameProperty = FindEntByNameProperty;

    vars.map = new StringWatcher(curMapPtr, 10);
    vars.loading = new MemoryWatcher<int>(curLoadingPtr);
	vars.state = new MemoryWatcher<int>(statePtr);
	vars.playerX = new MemoryWatcher<float>(plyrXPosPtr); 
	vars.playerY = new MemoryWatcher<float>(plyrYPosPtr);

	vars.uplinkVentHealth = new MemoryWatcher<float>(IntPtr.Zero);
	vars.nihiHP = new MemoryWatcher<float>(IntPtr.Zero);
	vars.thep3bosshealth = new MemoryWatcher<float>(IntPtr.Zero);
	vars.uplinkVentHP = new MemoryWatcher<float>(IntPtr.Zero);
	vars.thep2ValveAngle = new MemoryWatcher<float>(IntPtr.Zero);
	vars.op4ButtonFramerate = new MemoryWatcher<float>(IntPtr.Zero);
	vars.thep1MMThinkTime = new MemoryWatcher<float>(IntPtr.Zero);
	vars.hl1DoorSpeed = new MemoryWatcher<float>(IntPtr.Zero);

    vars.watchList = new MemoryWatcherList () {
        vars.map,
        vars.nihiHP,
		vars.playerX,
		vars.playerY,
		vars.thep3bosshealth,
		vars.uplinkVentHealth,
		vars.thep2ValveAngle,
		vars.op4ButtonFramerate,
		vars.thep1MMThinkTime,
		vars.nihiHP,
		vars.state,
		vars.hl1DoorSpeed
    };

	// 2838: this is for special actions that should only be done on game load
	// i would've used actions to clean this up but they don't allow ref unfortunately
	Action OnSessionStart = () => {
		string map = vars.map.Current;
		switch (map)
		{
			case "hl_c17":
			{
				vars.nihiHP.Reset();
				IntPtr nihiPtr = FindEntByNameProperty("targetname","nihilanth");
				vars.nihiHP = new MemoryWatcher<float>((nihiPtr == IntPtr.Zero) ? IntPtr.Zero : (nihiPtr + (int)vars.entVarsOffs["health"]));
				vars.watchList.Add(vars.nihiHP);
				break;
			}
			case "th_ep3_07":
			{
				vars.thep3bosshealth.Reset();
				IntPtr thep3bossPtr = FindEntByNameProperty("targetname","sheriffs_chppr2");
				vars.thep3bosshealth = new MemoryWatcher<float>((thep3bossPtr == IntPtr.Zero) ? IntPtr.Zero : (thep3bossPtr + (int)vars.entVarsOffs["health"]));
				vars.watchList.Add(vars.thep3bosshealth);
				break;
			}
			case "uplink":
			{
				vars.uplinkVentHealth.Reset();
				IntPtr uplinkVentHealthPtr = FindEntByNameProperty("targetname","garg_vent_break");
				vars.uplinkVentHealth = new MemoryWatcher<float>((uplinkVentHealthPtr == IntPtr.Zero) ? IntPtr.Zero : (uplinkVentHealthPtr + (int)vars.entVarsOffs["health"]));
				vars.watchList.Add(vars.uplinkVentHealth);
				break;
			}
			case "th_ep2_04":
			{
				vars.thep2ValveAngle.Reset();
				IntPtr thep2ValveAnglePtr = FindEntByNameProperty("target", "oil_spouts1_mm");
				vars.thep2ValveAngle = new MemoryWatcher<float>((thep2ValveAnglePtr == IntPtr.Zero) ? IntPtr.Zero : (thep2ValveAnglePtr + (int)vars.entVarsOffs["avelocityZ"]));
				vars.watchList.Add(vars.thep2ValveAngle);
				break;
			}
			case "of6a4b":
			{
				IntPtr op4ButtonFrameratePtr = FindEntByNameProperty("target", "endrelay");
				vars.op4ButtonFramerate.Reset();
				vars.op4ButtonFramerate = new MemoryWatcher<float>((op4ButtonFrameratePtr == IntPtr.Zero) ? IntPtr.Zero : (op4ButtonFrameratePtr + (int)vars.entVarsOffs["framerate"]));
				vars.watchList.Add(vars.op4ButtonFramerate);
				break;
			}
			case "th_ep1_05":
			{
				IntPtr thep1MMPtr = FindEntByNameProperty("targetname", "stairscene_mngr");
				vars.thep1MMThinkTime.Reset();
				vars.thep1MMThinkTime = new MemoryWatcher<float>((thep1MMPtr == IntPtr.Zero) ? IntPtr.Zero : (thep1MMPtr + (int)vars.entVarsOffs["nextthink"]));
				vars.watchList.Add(vars.thep1MMThinkTime);
				break;
			}
			case "hl_c01_a1":
			{
				IntPtr hl1DoorPtr = FindEntByNameProperty("targetname", "doors");
				vars.hl1DoorSpeed.Reset();
				vars.hl1DoorSpeed = new MemoryWatcher<float>((hl1DoorPtr == IntPtr.Zero) ? IntPtr.Zero : (hl1DoorPtr + (int)vars.entVarsOffs["zVel"]));
				vars.watchList.Add(vars.hl1DoorSpeed);
				break;
			}
		}

		vars.watchList.UpdateAll(game);
	};

	// 2838: call onsessionstart now as people might be loading this script mid-run
	vars.watchList.UpdateAll(game);
	OnSessionStart();

	vars.OnSessionStart = OnSessionStart;
}

isLoading // Gametimer
{
	return (vars.loading.Current == 1); //|| vars.state.Current < 2);
}

start // Start splitter
{
	vars.curTime = 0;

	if (!settings["Autostart"]) return false;

	bool loadingChanged = vars.loading.Current == 0 && vars.loading.Old == 1;

	if (settings["AutostartILs"]) return loadingChanged;

	switch ((string)vars.map.Current)
	{
		case "hl_c01_a1":
		{
			if (!(vars.map.Current == "hl_c01_a1" && settings["HL1door"])) 
				return (loadingChanged && vars.startmaps.Contains(vars.map.Current));
			else return (vars.hl1DoorSpeed.Old == 0 && vars.hl1DoorSpeed.Current == -40f);
		}
		case "uplink":
		{
			return (settings["Uplinkstart"] && vars.map.Current == "uplink" 
			&& vars.CheckWithinBoundsXY(vars.playerX.Old, vars.playerY.Old, -2160f, -1807f, 1990f, 2500f) 
			&& !vars.CheckWithinBoundsXY(vars.playerX.Current, vars.playerY.Current, -2160f, -1807f, 1990f, 2500f));
		}
		default:
		{
			return loadingChanged && vars.startmaps.Contains(vars.map.Current); 
		}
	}
}

reset // Reset splitter
{
	if (settings["Reset"] && vars.loading.Current == 0 && vars.loading.Old == 1 && vars.startmaps.Contains(vars.map.Current))
		return true;
}

split // Auto-splitter
{
	if (vars.loading.Current == 0)
	{
		if (vars.loading.Old == 1 && !vars.startmaps.Contains(vars.map.Current))
			return true;

		switch ((string)vars.map.Current)
		{
			default:
				return false;
			case "hl_c17":
				return settings["HL1stop"] && vars.nihiHP.Current <= 0 && vars.nihiHP.Old >= 1;
			case "th_ep1_05":
				return settings["EP1stop"] && vars.thep1MMThinkTime.Current != 0f && vars.thep1MMThinkTime.Old == 0f;
			case "of6a4b":
				return settings["OP4stop"] && vars.op4ButtonFramerate.Current == 1f && vars.op4ButtonFramerate.Old == 0f;
			case "th_ep2_04":
				return settings["EP2stop"] && vars.thep2ValveAngle.Current == 40f && vars.thep2ValveAngle.Old == 0f;
			case "th_ep3_07":
				return settings["EP3stop"] && vars.thep3bosshealth.Current <= 0 && vars.thep3bosshealth.Old > 0;
			case "uplink":
				return settings["Uplinkstop"] && vars.uplinkVentHealth.Current <= 0 && vars.uplinkVentHealth.Old > 0;
		} 
	}
}

update
{   
    vars.watchList.UpdateAll(game);

	// 2838: we don't include vars.loading in the watchlist as it must only be updated here
	vars.loading.Update(game);
	if ((vars.state.Current == 2 && vars.state.Old < 2) || (vars.loading.Current == 0 && vars.loading.Old == 1))
		vars.OnSessionStart();
}
