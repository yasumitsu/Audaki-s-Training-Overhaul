return PlaceObj('ModDef', {
	'title', "Audaki’s Training Overhaul",
	'description', "Rebalances the mechanics in which stat points are gained by field experience and the sector training operation.\n\n[h1]Disclaimer[/h1]\nThis mod was orinally created by [url=https://steamcommunity.com/id/Audaki/] Kira [/url]\nShe gave permission to update and maintain so, here I am. Kira san, arigato gozaimassss <3\n\n[h1]Audaki’s Training Overhaul[/h1]\nAfter developing TTSJ, the original training overhaul mod, I still wasn't fully satisfied. So I sat down and continued working and designing.\n\nThis mod is the result of 2 weeks of additional development time and over 100 hours of playtesting.\n\n[h2]Vision[/h2]\nImagine a play-through of JA3, where:\n[list]\n  [*] Activity (Combat, Quests) is always rewarded\n  [*] AFK Training is no longer a good strategy\n  [*] Activity in a sector will always benefit your mercs\n  [*] Overall, Sector Training Operation is Slower\n  [*] But Field Experience Gain is Faster and more even\n  [*] Static Cooldowns and once-per-map are Replaced with a Progress System\n[/list]\n\n[h3]In Field Experience[/h3]\n[list]\n  [*] Every skill use will be rewarded\n  [*] Example: Every defused mine/trap will count\n  [*] Skill uses either get a roll or grant Progress for the next roll\n  [*] With enough Progress your Merc is allowed to roll for a Stat Gain again\n  [*] Both Activity (Combat, Quests) and using the Skill will advance Progress\n[/list]\n\nThe most optimal strategy is now simply to let the merc you want to train fastest do the actions, without having to think anymore about cooldowns or once-a-map lockouts.\n\n[h3]Sector Operation Training[/h3]\nNow imagine in Sector Operation Training\n[list]\n  [*] Being inactive is no longer the best strategy\n  [*] Imagine, Training feels like a reward instead of cheating\n  [*] Earn Train Boosts via Activity (Combat, Quests)\n  [*] Without Train Boosts your Training will be extremely slow\n  [*] With Train Boosts your Training can be faster than Vanilla\n  [*] Spend Train Boosts in Sector Training Operation\n  [*] Sector Training Operation is now capped to 80 (configurable)\n  [*] Training now is a little slower when you simultaneously train more mercs\n  [*] First 5 Train Boosts get a slight boost in gain rate\n  [*] Therefore training more often in small intervals is worth it\n[/list]\n\nMod can be safely added and removed at any time. Although it is recommended to use this mod in a new play-through for balancing reasons.\n[hr][/hr]\n[i]All what she said, and maybe some more features in the future.[/i]\n[list]\n	[*] HG's sample Sector operation \"Scrounge\" incorporated to the mod\n	[*] Stregth can be increased via \"Scrounge\" operation\n[/list]",
	'image', "Mod/audaAto/Images/81u7g30YSbL._AC_UF1000,1000_QL80_.jpg",
	'external_links', {
		"https://github.com/yasumitsu/Audaki-s-Training-Overhaul",
	},
	'last_changes', "- removed the UI text from merc portrait, I could barely read it",
	'dependencies', {},
	'id', "audaAto",
	'author', "Audaki_ra",
	'version_major', 2,
	'version_minor', 1,
	'version', 502,
	'lua_revision', 233360,
	'saved_with_revision', 350233,
	'code', {
		"Code/Main.lua",
	},
	'default_options', {
		audaAtoSectorTrainStatCap = "80 (Hard, Default)",
		audaAtoSgeGainMod = "50% (Hard, Default)",
	},
	'has_data', true,
	'saved', 1718424714,
	'code_hash', 415722606620530497,
	'affected_resources', {
		PlaceObj('ModResourcePreset', {
			'Class', "SectorOperation",
			'Id', "Scrounge",
			'ClassDisplayName', "Sector operation",
		}),
		PlaceObj('ModResourcePreset', {
			'Class', "LootDef",
			'Id', "ScroungeOperationUrbanLoot",
			'ClassDisplayName', "Loot definition",
		}),
		PlaceObj('ModResourcePreset', {
			'Class', "LootDef",
			'Id', "ScroungeOperationWildernessLoot",
			'ClassDisplayName', "Loot definition",
		}),
		PlaceObj('ModResourcePreset', {
			'Class', "XTemplate",
			'Id', "SectorOperation_ScroungeLootUI",
			'ClassDisplayName', "UI Template (XTemplate)",
		}),
	},
	'steam_id', "3260806453",
	'TagBalancing&Difficulty', true,
	'TagPerks&Talents&Skills', true,
})