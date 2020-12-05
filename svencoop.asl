//Thanks for supporting the project with code: BenInSweden and Chillu
//How to use: https://github.com/SmileyAG/Sven-Coop-Autosplitter/blob/master/README.md

state("svencoop", "v2017") {
	bool loading            : "hw.dll", 0x51588, 0x0;
	string10 map           : "hw.dll", 0x60068, 0x0;
	float playerX          : "hw.dll", 0x140BB60, 0x70;
	float playerY          : "hw.dll", 0x140BB60, 0x74;
	float hl1BossHealth    : "hw.dll", 0xD15D10, 0x74, 0x4, 0xACC;
	//int op4End             :
	int thep1End           : "hw.dll", 0x2948, 0x398;
	//int thep2End           :
	float thep3BossHealth  : "hw.dll", 0xD15E10, 0x398, 0x4, 0xACC;
	float upLinkGargHealth : "hw.dll", 0xD15D90, 0x74, 0x294, 0x7A8;
}

startup {
	vars.startMaps = new HashSet<string> {"hl_c01_a1", "of1a1", "ba_security1", "th_ep1_01", "th_ep2_00", "th_ep3_00", "dy_accident1"};

	settings.Add("HL1split", false, "Split for Half-Life");
	//settings.Add("OP4split", false, "Split for Opposing Force");
	settings.Add("EP1split", false, "Split for They Hunger EP1");
	//settings.Add("EP2split", false, "Split for They Hunger EP2");
	settings.Add("EP3split", false, "Split for They Hunger EP3");
	settings.Add("upLinkStart", false, "Start timer for Uplink");
	settings.Add("upLinkSplit", false, "Split for Uplink");
	settings.Add("start", false, "Start timer");
	settings.Add("startILs", false, "Start timer for ILs");
}

init {
	switch (modules.First().ModuleMemorySize) {
		case 774144: version = "v2017"; break;
		default: version = "UNDETECTED"; break;
	}
}

update {
	if (version == "UNDETECTED") return false;
}

start {
	var inPos = (Func<float, float, float, float, bool>) ((xMin, xMax, yMin, yMax) => {
		return current.playerX >= xMin && current.playerX <= xMax && current.playerY >= yMin && current.playerY <= yMax ? true : false;
	});

	return
		settings["upLinkStart"] && inPos(-2092, -2004, 524, 720) && current.map == "uplink" ||
		settings["start"] && current.loading && !old.loading && vars.startMaps.Contains(current.map) ||
		settings["startILs"] && !current.loading && old.loading;
}

split {
	return
		current.loading && !old.loading ||
		settings["HL1split"]    && current.hl1BossHealth    <= 0    && old.hl1BossHealth    >= 1 && current.map == "hl_c17" ||
		//settings["OP4split"]    && current.op4End           == 1    && old.op4End           == 0 && current.map == "of6a4b" ||
		settings["EP1split"]    && current.thep1End         == 1    && old.thep1End         == 0 && current.map == "th_ep1_05" ||
		//settings["EP2split"]    && current.thep2End         == 1    && old.thep2End         == 0 && current.map == "th_ep2_04" ||
		settings["EP3split"]    && current.thep3BossHealth  <= 0    && old.thep3BossHealth  >= 1 && current.map == "th_ep3_07" ||
		settings["upLinkSplit"] && current.upLinkGargHealth == 1000 && old.upLinkGargHealth == 0 && current.map == "uplink";
}

reset {
	return !current.loading && old.loading && vars.startMaps.Contains(current.map);
}

isLoading {
	return current.loading;
}
