//LiveSplit - Edit Layout - Scriptable Auto Splitter

state("svencoop")
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