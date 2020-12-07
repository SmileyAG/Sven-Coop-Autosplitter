//Thanks for supporting the project with code: BenInSweden and Chillu
//How to use: https://github.com/SmileyAG/Sven-Coop-Autosplitter/blob/master/README.md

state("svencoop", "v2017") // Offsets
{
	//int loading: "hw.dll", 0x00051588, 0x0;
	//string10 map: "hw.dll", 0x00060068, 0x0;
	//float playerX: "hw.dll", 0x0140BB60, 0x70;
	//float playerY: "hw.dll", 0x0140BB60, 0x74;
	//float hl1bosshealth: "hw.dll", 0x00D15D10, 0x74, 0x4, 0xACC;
	//int op4end:
	//int thep1end: "hw.dll", 0x00002948, 0x398;
	//int thep2end:
	//float thep3bosshealth: "hw.dll", 0x00D15E10, 0x398, 0x4, 0xACC;
	//float uplinkgarghealth: "hw.dll", 0x00D15D90, 0x74, 0x294, 0x7A8;
}

startup	// Settings
{	
	vars.startmaps = new List<string>() 
	{"hl_c01_a1", "of1a1", "ba_security1", "th_ep1_01", "th_ep2_00", "th_ep3_00", "dy_accident1"};
  
	settings.Add("HL1stop", false, "Autostop for Half-Life");
	//settings.Add("OP4stop", false, "Autostop for Opposing Force");
	settings.Add("EP1stop", false, "Autostop for They Hunger EP1");
	//settings.Add("EP2stop", false, "Autostop for They Hunger EP2");
	settings.Add("EP3stop", false, "Autostop for They Hunger EP3");
	settings.Add("Uplinkstart", false, "Autostart for Uplink"); 
	settings.Add("Uplinkstop", false, "Autostop for Uplink"); 
	settings.Add("Reset", false, "Autoreset");                              	  	
	settings.Add("Autostart", false, "Autostart");
	settings.Add("AutostartILs", false, "Autostart for ILs");

	// 2838: basic offsets for some elements in entvars typedef
    vars.entVarsOffs = new Dictionary<string, int>() {
        {"health"               	, 0x1E0},
        {"xPos"             		, 0x88},
		{"yPos"             		, 0x8C},
		{"zPos"             		, 0x90},
		{"max_health"             	, 0x230},
		{"targetname"				, 0x24C},
		{"classname"				, 0x80},
		{"globalname"				, 0x84},
		{"modelname"				, 0x130},
		{"privatedata"				, 0x7C}
    };

	// 2838: how many times should we retry finding an entity before stopping?
	vars.entFindRetries = 3;
}


init // Version specific
{
	Action<string, string> printtag = (tag, msg) => {
		print("[" + tag + "] " + msg);
	};

	vars.printtag = printtag;

	byte[] exeMD5HashBytes = new byte[0];
	using (var md5 = System.Security.Cryptography.MD5.Create())
	{
		using (var s = File.Open(modules.First().FileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
		{
			exeMD5HashBytes = md5.ComputeHash(s);
		}
	}
	var MD5Hash = exeMD5HashBytes.Select(x => x.ToString("X2")).Aggregate((a, b) => a + b);

	if (MD5Hash == "0792734230344D7182F9D6FD7783BA05")
	{
		version = "v2017";
		printtag("VERSIONING", "Detected game version: " + version + " - MD5Hash: " + MD5Hash);
	}
    else
	{
		version = "UNDETECTED";
		printtag("VERSIONING", "UNDETECTED GAME VERSION - MD5Hash: " + MD5Hash);
	}

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

    curLoadingSig.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr;

    var nihiHPBaseSig = new SigScanTarget(5,  
        "83 ?? 38",
        "??",
        "68 ?? ?? ?? ??", // PUSH entry_point
        "E8 ?? ?? ?? ??",
        "83 C4 08"); 

    nihiHPBaseSig.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr + 0x10; // 2838: this address is always 10 bytes away from the actual one

    var plyrPosSig = new SigScanTarget(22, 
		"C7 05 ?? ?? ?? ?? 01 00 00 00",
		"E8 ?? ?? ?? ??",
		"FF 15 ?? ?? ?? ??",
		"68 ?? ?? ?? ??"); 

    plyrPosSig.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr + 0x38;

	var thep1endSig = new SigScanTarget(2, 
		"F6 05 ?? ?? ?? ?? 02", // MOV byte ptr [thep1end],0x2
		"74 ??",
		"68 00 03 00 00"); 

    thep1endSig.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr;

	var thep3endSig = new SigScanTarget(11, 
		"8? ?? ?? ?? ?? ??",
		"83 ?? 38",
		"??",
		"68 ?? ?? ?? ??"); // PUSH entry_point

    thep3endSig.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : (ptr + 0x110);

	var entListSig = new SigScanTarget(14, 
		"0f ?? ?? ?? ?? ??",
		"?? ??",
		"?? ??",
		"75 ??", 	// MOV EDI,dword ptr [entList]
		"8B 3D ?? ?? ?? ??",
		"5?");
	// 2838: unsure about this sig...
    entListSig.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr;

	var pStringBaseSig = new SigScanTarget(2, 
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
	// D9 1D ?? ?? ?? ?? FF 15 ?? ?? ?? ?? D9 EE
	// D9 1D ?? ?? ?? ?? ?? FF 15 ?? ?? ?? ?? D9 EE

    globalSig.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr;

    var profiler = Stopwatch.StartNew();

    // 2838: init process scanners, limit scope to hw.dll only
    ProcessModuleWow64Safe hw = modules.FirstOrDefault(x => x.ModuleName.ToLower() == "hw.dll");
    var hwScanner = new SignatureScanner(game, hw.BaseAddress, hw.ModuleMemorySize);

    IntPtr curMapPtr = hwScanner.Scan(curMapSig);
    IntPtr curLoadingPtr = hwScanner.Scan(curLoadingSig);
    IntPtr nihiHPBasePtr = hwScanner.Scan(nihiHPBaseSig);
	IntPtr plyrXPosPtr = hwScanner.Scan(plyrPosSig);
	IntPtr plyrYPosPtr = plyrXPosPtr + 0x4;
	IntPtr thep1endPtr = hwScanner.Scan(thep1endSig);
	IntPtr entListPtr = hwScanner.Scan(entListSig);
	IntPtr pStringBasePtr = hwScanner.Scan(pStringBaseSig);
	IntPtr statePtr = hwScanner.Scan(stateSig);
	IntPtr globalPtr = hwScanner.Scan(globalSig);

	//IntPtr thep3endPtr = hwScanner.Scan(thep3endSig);
    //var nihiHPDP = new DeepPointer(nihiHPBasePtr, 0x74, 0x4, 0xACC);
	//var thep3endDP = new DeepPointer(thep3endPtr, 0x398, 0x4, 0xACC);
	//var uplinkgarghealthDP = new DeepPointer(thep3endPtr - 0x80, 0x74, 0x294, 0x7A8);

	printtag("SIGSCANNING", (entListPtr == IntPtr.Zero ? ("Couldn't find entList ptr!") : ("Found entList ptr at 0x" + entListPtr.ToString("X"))));
	printtag("SIGSCANNING", (globalPtr == IntPtr.Zero ? ("Couldn't find globals ptr!") : ("Found globals ptr at 0x" + globalPtr.ToString("X"))));
	printtag("SIGSCANNING", (pStringBasePtr == IntPtr.Zero ? ("Couldn't find stringbase ptr!") : ("Found stringbase ptr at 0x" + pStringBasePtr.ToString("X"))));
    printtag("SIGSCANNING", (curMapPtr == IntPtr.Zero ?  "Couldn't find current map ptr!" : ("Found current map ptr at 0x" + curMapPtr.ToString("X"))));
    printtag("SIGSCANNING", (curLoadingPtr == IntPtr.Zero ? ("Couldn't find loading ptr!") : ("Found loading ptr at 0x" + curLoadingPtr.ToString("X"))));
	printtag("SIGSCANNING", (statePtr == IntPtr.Zero ? ("Couldn't find state ptr!") : ("Found state ptr at 0x" + statePtr.ToString("X"))));
	printtag("SIGSCANNING", (plyrXPosPtr == IntPtr.Zero ? ("Couldn't find player's pos ptr!") : ("Found player's pos ptr at 0x" + plyrXPosPtr.ToString("X"))));
	printtag("SIGSCANNING", (thep1endPtr == IntPtr.Zero ? ("Couldn't find thep1end ptr!") : ("Found thep1end ptr at 0x" + thep1endPtr.ToString("X"))));
	//printtag("SIGSCANNING", (nihiHPBasePtr == IntPtr.Zero ? ("Couldn't find nihi's hp entry ptr!") : ("Found nihi's hp entry ptr at 0x" + nihiHPBasePtr.ToString("X"))));
	//printtag("SIGSCANNING", (thep3endPtr == IntPtr.Zero ? ("Couldn't find thep3end entry ptr!") : ("Found thep3end entry ptr at 0x" + thep3endPtr.ToString("X"))));
	//printtag("SIGSCANNING", (thep3endPtr == IntPtr.Zero ? ("Couldn't find uplinkgarghealth entry ptr!") : ("Found uplinkgarghealth entry ptr at 0x" + (thep3endPtr - 0x80).ToString("X"))));

    printtag("SIGSCANNING", "Signature scanning complete after " + profiler.ElapsedMilliseconds * 0.001f + " seconds");
    profiler.Stop();


	// uint to float byte cast -- convert bit-for-bit an uint to a float
	Func<uint, float> ui2fbc = (input) => {
		return BitConverter.ToSingle(BitConverter.GetBytes(input), 0);
	};

	// reverse of above
	Func<float, uint> f2uibc = (input) => {
		return (uint)BitConverter.ToInt32(BitConverter.GetBytes(input),0);
	};

	Func<IntPtr, string, uint> GetEntProperty = (ptr, propertyName) => {
		return memory.ReadValue<uint>(ptr + (int)vars.entVarsOffs[propertyName]);
	};

	// 2838: strings are stored some distance away from the base string address
	Func<IntPtr, string, string> GetEntNameProperty = (ptr, propertyName) => {
		if (pStringBasePtr == IntPtr.Zero) return "";
		// 2838: this is some of the ugliest type casting i have ever done but intptr has forced my hand
		return memory.ReadString((IntPtr)((uint)memory.ReadPointer(pStringBasePtr) + memory.ReadValue<uint>(ptr + (int)vars.entVarsOffs[propertyName])), 256);
	};

	Func<int, IntPtr> GetEntFromIndex = (index) => {
		if (entListPtr == IntPtr.Zero) return IntPtr.Zero;
		return memory.ReadPointer(entListPtr) + 804 * index;
	};

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

	Func<string, string, IntPtr> FindEntByNameProperty = (property, value) => {
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
	vars.ui2fbc = ui2fbc;
	vars.f2uibc = f2uibc;

    vars.map = new StringWatcher(curMapPtr, 10);
    vars.loading = new MemoryWatcher<int>(curLoadingPtr);
	vars.state = new MemoryWatcher<int>(statePtr);
	vars.playerX = new MemoryWatcher<float>(plyrXPosPtr); 
	vars.playerY = new MemoryWatcher<float>(plyrYPosPtr);
	vars.thep1end = new MemoryWatcher<int>(thep1endPtr);

	vars.uplinkgarghealth = new MemoryWatcher<float>(IntPtr.Zero);
	vars.nihiHP = new MemoryWatcher<float>(IntPtr.Zero);
	vars.thep3bosshealth = new MemoryWatcher<float>(IntPtr.Zero);

    vars.watchList = new MemoryWatcherList () {
        vars.map,
        vars.loading,
        vars.nihiHP,
		vars.playerX,
		vars.playerY,
		vars.thep1end,
		vars.thep3bosshealth,
		vars.uplinkgarghealth,
		vars.nihiHP,
		vars.state
    };

	// 2838: this is for special actions that should only be done on game load
	Action OnSessionStart = () => {

		// refresh nihi's hp pointer in case his entity index ever changes
		if (vars.map.Current == "hl_c17")
		{
			vars.nihiHP.Reset();
			IntPtr nihiPtr = FindEntByNameProperty("targetname","nihilanth");
			vars.nihiHP = new MemoryWatcher<float>((nihiPtr == IntPtr.Zero) ? IntPtr.Zero : (nihiPtr + (int)vars.entVarsOffs["health"]));
			vars.watchList.Add(vars.nihiHP);
		}
		else if (vars.map.Current == "th_ep3_07")
		{
			vars.thep3bosshealth.Reset();
			IntPtr thep3bossPtr = FindEntByNameProperty("targetname","sheriffs_chppr2");
			vars.thep3bosshealth = new MemoryWatcher<float>((thep3bossPtr == IntPtr.Zero) ? IntPtr.Zero : (thep3bossPtr + (int)vars.entVarsOffs["health"]));
			vars.watchList.Add(vars.thep3bosshealth);
		}
		else if (vars.map.Current == "uplink")
		{
			vars.uplinkgarghealth.Reset();
			IntPtr uplinkgarghealthPtr = FindEntByNameProperty("classname","monster_gargantua");
			vars.uplinkgarghealth = new MemoryWatcher<float>((uplinkgarghealthPtr == IntPtr.Zero) ? IntPtr.Zero : (uplinkgarghealthPtr + (int)vars.entVarsOffs["health"]));
			vars.watchList.Add(vars.uplinkgarghealth);
		}
	};

	// 2838: call onsessionstart now as people might be loading this script mid-run
	OnSessionStart();

	vars.OnSessionStart = OnSessionStart;

}

isLoading // Gametimer
{
	return (vars.loading.Current == 1 || vars.state.Current < 2);
}

start // Start splitter
{
	vars.curTime = 0;

	if ((settings["Uplinkstart"] && vars.playerX.Current >= -2092 && vars.playerX.Current <= -2004 
	&& vars.playerY.Current >= 524 && vars.playerY.Current <= 720 && vars.map.Current == "uplink")
	|| (settings["Autostart"] && vars.loading.Current == 0 && vars.loading.Old == 1 && vars.startmaps.Contains(vars.map.Current))
	|| (settings["AutostartILs"] && vars.loading.Current == 0 && vars.loading.Old == 1))
	{
		return true;
	}
}

reset // Reset splitter
{
	if (settings["Reset"] && vars.loading.Current == 0 && vars.loading.Old == 1 && vars.startmaps.Contains(vars.map.Current))
	{
		return true;
	}
}

split // Auto-splitter
{
	if (vars.loading.Current == 1 && vars.loading.Old == 0) 
		return true;
	
	if (settings["HL1stop"] && vars.nihiHP.Current <= 0 && vars.nihiHP.Old >= 1 && vars.map.Current == "hl_c17") return true;
	if (settings["EP1stop"] && vars.thep1end.Current == 1 && vars.thep1end.Old == 0 && vars.map.Current == "th_ep1_05") return true;
	if (settings["EP3stop"] && vars.thep3bosshealth.Current <= 0 && vars.thep3bosshealth.Old >= 1 && vars.map.Current == "th_ep3_07") return true;
	if (settings["Uplinkstop"] && vars.uplinkgarghealth.Current == 1000 && vars.uplinkgarghealth.Old == 0 && vars.map.Current == "uplink") return true;
    
	/* 
	if (settings["OP4stop"])
	{
		if (current.op4end == 1 && old.op4end == 0 && vars.map.Current == "of6a4b")
		{
 	    		return true;
		}
	}
	*/

	/*
	if (settings["EP2stop"])
	{
		if (current.thep2end == 1 && old.thep2end == 0 && vars.map.Current == "th_ep2_04") 
		{
            		return true;
		}
	}
	*/

}

update
{   
    vars.watchList.UpdateAll(game);
	if ((vars.state.Current == 2 && vars.state.Old < 2) || (vars.loading.Current == 0 && vars.loading.Old == 1))
	{
		vars.OnSessionStart();
	}

}