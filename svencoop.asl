//Sven Co-op LiveSplit Auto-Splitter - Edit Layout - Scriptable Auto Splitter
//Thanks for supporting the project with code: BenInSweden and Chillu
//Works only with Sven Co-op 15 April 2017 version

//How to use: https://github.com/TheSmiley47/Sven-Coop-Autosplitter/blob/master/README.md

state("svencoop", "v2017") // Offsets
{
    int loading : "hw.dll", 0x00051588, 0x0;
    int op4end : "client.dll", 0x00241438, 0x4, 0x0, 0x174;
    int thep1end : "hw.dll", 0x00002948, 0x398;
    string10 map : "hw.dll", 0x00060068, 0x0;
}

startup	// Start splitter
{
    settings.Add("AutoStart", false, "Use auto-start");
}

split // Auto-splitter
{
    if ( current.loading == 1 && old.loading == 0 ) {
        return true;
    }
    if ( current.thep1end == 1 && old.thep1end == 0 && current.map == "th_ep1_05" ) {
        return true;
    }
    if ( current.op4end == 1 && old.op4end == 0 && current.map == "of6a4b" ) {
        return true;
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
	
	if(MD5Hash == "0792734230344D7182F9D6FD7783BA05"){
		version = "v2017";
		print("Detected game version: " + version + " - MD5Hash: " + MD5Hash);
	}
    	else{
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
	if (settings["AutoStart"])
	{
	if (current.loading == 0 && old.loading == 1)
	return true;
	}
}

update // Version specific
{
    	if (version.Contains("UNDETECTED"))
	return false;
}
