//LiveSplit - Edit Layout - Scriptable Auto Splitter
//Thanks for supporting in code: BenInSweden

state("svencoop", "Steam")
{
    int loading : "hw.dll", 0x0005E87C, 0x0;
}

state("svencoop", "v2017")
{
    int loading : "hw.dll", 0x00051588, 0x0;
}

split 
{
    return current.loading == 1 && old.loading == 0;
}

isLoading
{
    return (current.loading != 0);
}

init
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
	//print("MD5Hash: " + MD5Hash.ToString()); //Lets DebugView show me the MD5Hash of the game executable

    	if(MD5Hash == "C3E13874B743EE77DA380CC3FB1AFF76"){
		version = "Steam";
		print("Detected game version: " + version + " - MD5Hash: " + MD5Hash);
	}
	else if(MD5Hash == "0792734230344D7182F9D6FD7783BA05"){
		version = "v2017";
		print("Detected game version: " + version + " - MD5Hash: " + MD5Hash);
	}
    	else{
		version = "UNDETECTED - Contact us!";
		print("UNDETECTED GAME VERSION - MD5Hash: " + MD5Hash);
	}
}
