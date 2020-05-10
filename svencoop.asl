//LiveSplit - Edit Layout - Scriptable Auto Splitter
//Thanks for supporting in code: BenInSweden
//Works only in 2017 version

state("svencoop")
{
    int loading : "hw.dll", 0x00051588, 0x0;
    int op4end : "client.dll", 0x00241438, 0x10, 0x174;
	int thep1end : "hw.dll", 0x00002948, 0x398;
    string10 mapchecker : "hw.dll", 0x00060068, 0x0;
}

split 
{
	if ( current.loading == 1 && old.loading == 0 ) {
        return true;
    }
    if ( current.thep1end == 1 && old.thep1end == 0 && current.mapchecker == "th_ep1_05" ) {
        return true;
    }
    if ( current.op4end == 1 && old.op4end == 0 && current.mapchecker == "of6a4b" ) {
        return true;
    }
}

isLoading
{
    return (current.loading != 0);
}
