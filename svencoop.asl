//Thanks for supporting the project with code: BenInSweden and Chillu
//How to use: https://github.com/SmileyAG/Sven-Coop-Autosplitter/blob/master/README.md

state("svencoop", "v2017") // Offsets
{
	//int loading: "hw.dll", 0x00051588, 0x0;
	//string10 map: "hw.dll", 0x00060068, 0x0;
	float playerX: "hw.dll", 0x0140BB60, 0x70;
	float playerY: "hw.dll", 0x0140BB60, 0x74;
	float hl1bosshealth: "hw.dll", 0x00D15D10, 0x74, 0x4, 0xACC;
	//int op4end:
	int thep1end: "hw.dll", 0x00002948, 0x398;
	//int thep2end:
	float thep3bosshealth: "hw.dll", 0x00D15E10, 0x398, 0x4, 0xACC;
	float uplinkgarghealth: "hw.dll", 0x00D15D90, 0x74, 0x294, 0x7A8;
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
}

split // Auto-splitter
{
	if (vars.loading.Current == 1 && vars.loading.Old == 0) 
		return true;
	
	if (settings["HL1stop"])
	{
		if (vars.nihiHP.Current <= 0 && vars.nihiHP.Old >= 1 && vars.map.Current == "hl_c17")
		{
			return true;
		}
	}
    
	/* 
	if (settings["OP4stop"])
	{
		if (current.op4end == 1 && old.op4end == 0 && vars.map.Current == "of6a4b")
		{
 	    		return true;
		}
	}
	*/

	if (settings["EP1stop"])
	{
		if (current.thep1end == 1 && old.thep1end == 0 && vars.map.Current == "th_ep1_05") 
		{
            return true;
		}
	}
	
	/*
	if (settings["EP2stop"])
	{
		if (current.thep2end == 1 && old.thep2end == 0 && vars.map.Current == "th_ep2_04") 
		{
            		return true;
		}
	}
	*/
	
	if (settings["EP3stop"])
	{
		if (current.thep3bosshealth <= 0 && old.thep3bosshealth >= 1 && vars.map.Current == "th_ep3_07")
		{
            return true;
		}
	}
	
	if (settings["Uplinkstop"])
	{
		if (current.uplinkgarghealth == 1000 && old.uplinkgarghealth == 0 && vars.map.Current == "uplink")
		{
			return true;
		}
	}
}

init // Version specific
{
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
		print("Detected game version: " + version + " - MD5Hash: " + MD5Hash);
	}
    else
	{
		version = "UNDETECTED";
		print("UNDETECTED GAME VERSION - MD5Hash: " + MD5Hash);
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

    var profiler = Stopwatch.StartNew();

    // 2838: init process scanners, limit scope to hw.dll only
    ProcessModuleWow64Safe hw = modules.FirstOrDefault(x => x.ModuleName.ToLower() == "hw.dll");
    var hwScanner = new SignatureScanner(game, hw.BaseAddress, hw.ModuleMemorySize);

    IntPtr curMapPtr = hwScanner.Scan(curMapSig);
    IntPtr curLoadingPtr = hwScanner.Scan(curLoadingSig);
    IntPtr nihiHPBasePtr = hwScanner.Scan(nihiHPBaseSig);

    var nihiHPDP = new DeepPointer(nihiHPBasePtr, 0x74, 0x4, 0xACC);

    print(curMapPtr == IntPtr.Zero ? ("[SIGSCANNING] Couldn't find current map ptr!") : ("[SIGSCANNING] Found current map ptr at 0x" + curMapPtr.ToString("X")));
    print(curLoadingPtr == IntPtr.Zero ? ("[SIGSCANNING] Couldn't find loading ptr!") : ("[SIGSCANNING] Found loading ptr at 0x" + curLoadingPtr.ToString("X")));
    print(nihiHPBasePtr == IntPtr.Zero ? ("[SIGSCANNING] Couldn't find nihi's hp entry ptr!") : ("[SIGSCANNING] Found nihi's hp entry ptr at 0x" + nihiHPBasePtr.ToString("X")));

    print("[SIGSCANNING] Signature scanning complete after " + profiler.ElapsedMilliseconds * 0.001f + " seconds");
    profiler.Stop();

    vars.map = new StringWatcher(curMapPtr, 10);
    vars.loading = new MemoryWatcher<int>(curLoadingPtr);
    vars.nihiHP = new MemoryWatcher<float>(nihiHPDP);
    vars.watchList = new MemoryWatcherList () {
        vars.map,
        vars.loading,
        vars.nihiHP
    };

}

isLoading // Gametimer
{
	return (vars.loading.Current == 1);
}

start // Start splitter
{
	if (settings["Uplinkstart"])
	{
		if (current.playerX >= -2092 && current.playerX <= -2004 && current.playerY >= 524 && current.playerY <= 720 && vars.map.Current == "uplink")
		{
			return true;
		}
	}

	if (settings["Autostart"])
	{
		if (vars.loading.Current == 0 && vars.loading.Old == 1 && vars.startmaps.Contains(vars.map.Current))
		{	
			return true;
		}
	}

	if (settings["AutostartILs"])
	{
		if (vars.loading.Current == 0 && vars.loading.Old == 1)
		{
			return true;
		}
	}
}

reset // Reset splitter
{
	if (settings["Reset"])
	{
		if (vars.loading.Current == 0 && vars.loading.Old == 1 && vars.startmaps.Contains(vars.map.Current))
		{
			return true;
		}
	}
}

update // Version specific
{   
    vars.watchList.UpdateAll(game);
}
