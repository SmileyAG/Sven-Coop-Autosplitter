# Sven-Co-op Auto-splitter

Auto-splitter for Sven Co-op.
If you have any questions then feel free to go our [Discord server](https://discord.com/invite/3Trxxsz) to ask.

## Authors
 - Main code work: 2838, _Smiley and ScriptedSnark
 - Additional code support from: BenInSweden and Chillu

## Installation
There are 2 ways that you can install this splitter

**First way (recommended):**
 1. Right click Livesplit
 2. Select "Edit Splits"
 3. If the "Game Name" field is empty then fill it with "Sven Co-op", otherwise skip to step 4
 4. Activate the splitter by clicking the "Activate" button beside the Splitter information text

**Second way (manual method):**
 1. Download the splitter from https://github.com/SmileyAG/Sven-Coop-Autosplitter/blob/master/svencoop.asl
 2. Right click Livesplit
 3. Select "Edit Layout"
 4. Click on Add (plus sign) -> Control -> Scriptable Auto Splitter
 5. Double click the newly available Scriptable Auto Splitter entry in your Layout elements list
 6. Click on Browse next to the "Script Path" field then locate the splitter

## Features
 - Automatic splitting
 - Automatic Timer Start, Stop and Resetting, all of which can be toggled
 - Pauses on server load
 - Works with almost all versions after 2016
 
## Technical Information
 - This splitter achieves compatibility with most versions of Sven Co-op through the use of [Signature Scanning](https://wiki.alliedmods.net/Signature_scanning), which searches through game memory and find important pointers to data instead of relying on static offsets.
 - The automatic timer functionalities are done through directly reading entities' memory and detecting changes. The way these pointers are found is identical to what the game does, so the automatic functions should be reliable and accurate.
 - Unfortunately, because entity data is not fully transfered to non-host players, their splitters won't be able to track changes so these automatic timer features will not work for them. As such, if you are not the host of a Co-op run, please only use timer as a rough indicator of your pace.

