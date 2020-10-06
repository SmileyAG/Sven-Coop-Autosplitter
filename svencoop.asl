//Thanks for supporting the project with code: BenInSweden and Chillu
//How to use: https://github.com/TheSmiley47/Sven-Coop-Autosplitter/blob/master/README.md

state("svencoop", "v2017") // Offsets
{
	int loading: "hw.dll", 0x00051588, 0x0;
	string10 map: "hw.dll", 0x00060068, 0x0;
	//float playerX:
	//float playerY:
	//float hl1bosshealth:
	//int op4end:
	int thep1end: "hw.dll", 0x00002948, 0x398;
	//int thep2end:
	//float thep3bosshealth:
}

startup	// Settings
{
	vars.startmaps = new List<string>() 
	{"hl_c01_a1", "of1a1", "ba_security1", "th_ep1_01", "th_ep2_00", "th_ep3_00", "dy_accident1"};  
                              	  	
	settings.Add("Autostart", false, "Autostart");
	settings.Add("AutostartILs", false, "Autostart for ILs");
}

split // Auto-splitter
{
	if (current.loading == 1 && old.loading == 0) 
		return true;
	
	//if (current.hl1bosshealth <= 0 && old.hl1bosshealth >= 1 && current.map "hl_c17")
		//return true;
    
	//if (current.op4end == 1 && old.op4end == 0 && current.map == "of6a4b")
 	    	//return true;

	if (current.thep1end == 1 && old.thep1end == 0 && current.map == "th_ep1_05") 
            	return true;

	//if (current.thep2end == 1 && old.thep2end == 0 && current.map == "th_ep2_04") 
            	//return true;

	//if (current.thep3bosshealth <= 0 && old.thep3bosshealth >= 1 && current.map == "th_ep3_07") 
            	//return true;
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
}

isLoading // Gametimer
{
	return (current.loading == 1);
}

start // Start splitter
{
	if (settings["Autostart"])
	{
		if (current.loading == 0 && old.loading == 1 && vars.startmaps == current.map)
		{	
			return true;
		}
	}

	if (settings["AutostartILs"])
	{
		if (current.loading == 0 && old.loading == 1)
		{
			return true;
		}
	}
}

reset // Reset splitter
{
	if (vars.startmaps == current.map && current.loading == 0 && old.loading == 1)
		return true;
}

update // Version specific
{
	if (version.Contains("UNDETECTED"))
		return false;
}
