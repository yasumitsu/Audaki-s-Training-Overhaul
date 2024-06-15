return {
	PlaceObj('ModItemFolder', {
		'name', "Code",
	}, {
		PlaceObj('ModItemCode', {
			'name', "Main",
			'CodeFileName', "Code/Main.lua",
		}),
		}),
	PlaceObj('ModItemFolder', {
		'name', "Option",
	}, {
		PlaceObj('ModItemOptionChoice', {
			'name', "audaAtoSectorTrainStatCap",
			'DisplayName', "Sector Training Stat Cap",
			'Help', "When using the <em>Sector Training Operation</em> this setting controls the highest stat you can train your mercs up to. This does not affect Field Experience.",
			'DefaultValue', "80 (Hard, Default)",
			'ChoiceList', {
				"60 (Masochist)",
				"65",
				"70 (Very Hard)",
				"75",
				"80 (Hard, Default)",
				"85 (Balanced)",
				"90 (Easy)",
				"95 (Very Easy)",
				"100 (Piece of Cake)",
			},
		}),
		PlaceObj('ModItemOptionChoice', {
			'name', "audaAtoSgeGainMod",
			'DisplayName', "TrainBoost GainSpeed",
			'Help', "This setting controls how fast you can collect how many Train Boosts<newline><newline>50% is default balancing<newline><newline>Less is harder<newline>More is easier<newline><newline>This setting controls how fast you earn Train Boosts for Activity (Combat, Quests)",
			'DefaultValue', "50% (Hard, Default)",
			'ChoiceList', {
				"5% (Masochist)",
				"10%",
				"25% (Very Hard)",
				"40%",
				"50% (Hard, Default)",
				"60%",
				"75%",
				"90%",
				"100% (Balanced)",
				"125%",
				"150%",
				"175%",
				"200% (Easy)",
				"300%",
				"400% (Very Easy)",
				"600%",
				"800% (Piece of Cake)",
			},
		}),
		}),
	PlaceObj('ModItemFolder', {
		'name', "Operations",
	}, {
		PlaceObj('ModItemSectorOperation', {
			Custom = false,
			GetSectorSlots = function (self, prof, sector)
				return 2
			end,
			HasOperation = function (self, sector)
				if self.Custom then
					return sector.custom_operations and sector.custom_operations[self.id] and
						sector.custom_operations[self.id].status == "enabled"
				end
				
				return true
			end,
			IsEnabled = function (self, sector)
				return true
			end,
			ModifyProgress = function (self, value, sector)
				local ac = sector.custom_operations and sector.custom_operations[self.id]
				if ac then
					ac.progress = ac.progress + value
				end
			end,
			OnComplete = function (self, sector, mercs)
				 --city, mine, guard post, hospital or repair shop
				local loot_table = "ScroungeOperationWildernessLoot"
				if sector.City  and sector.City~= "none" or sector.Mine  or sector.Hospital or sector.Guardpost or sector.RepairShop then
					loot_table = "ScroungeOperationUrbanLoot"
				end	
				
				local ca = sector.custom_operations[self.id]
				ca.progress = 0
				sector.custom_operations[self.id]  = nil
				if loot_table then
					local items = {}
					local loot_tbl = LootDefs[loot_table]
					if loot_tbl then
						loot_tbl:GenerateLoot(self, {}, mercs[1]:Random(), items)
						-- show pop up with items
						local popupHost = GetDialog("PDADialogSatellite")
						popupHost = popupHost and popupHost:ResolveId("idDisplayPopupHost")
						OpenDialog("SectorOperation_ScroungeLootUI", popupHost, {sector_id = sector.Id,loot = items, mercs = mercs})
					end	
				end
			end,
			OnSetOperation = function (self, merc, arg)
				local sector = merc:GetSector()
				sector.custom_operations = sector.custom_operations or {}
				sector.custom_operations[self.id] = sector.custom_operations[self.id] or {progress = 0}
			end,
			Professions = {
				PlaceObj('SectorOperationProfession', {
					'id', "Somethingseeker",
					'display_name', T(609246764644, --[[ModItemSectorOperation Scrounge display_name]] "Somethingseeker"),
					'display_name_all_caps', T(553604731202, --[[ModItemSectorOperation Scrounge display_name_all_caps]] "SOMETHINGSEEKER"),
					'display_name_plural', T(308384752884, --[[ModItemSectorOperation Scrounge display_name_plural]] "Somethingseekers"),
					'display_name_plural_all_caps', T(312895543441, --[[ModItemSectorOperation Scrounge display_name_plural_all_caps]] "SOMETHINGSEEKERS"),
				}),
			},
			ProgressCompleteThreshold = function (self, merc, sector, prediction)
				return self.target_contribution
			end,
			ProgressCurrent = function (self, merc, sector, prediction)
				return sector.custom_operations and sector.custom_operations[self.id] and sector.custom_operations[self.id].progress or 0
			end,
			ProgressPerTick = function (self, merc, prediction)
				local _, val = self:GetRelatedStat(merc)
				return val
			end,
			ShowInCombatBadge = false,
			Tick = function (self, merc)
				local sector = merc:GetSector()
				local progress_per_tick = self:ProgressPerTick(merc)
				if CheatEnabled("FastActivity") then
					progress_per_tick = progress_per_tick*100
				end
				self:ModifyProgress(progress_per_tick, sector)
				self:CheckCompleted(merc, sector)
			end,
			comment = "Scrounge Operation:\n\nUp to 2 mercs can scrounge the sector for extra loot based on the sector that it is used in. The activity uses Wisdom as a primary stat and Wisdom reduces the time it takes to finish the activity (keep in mind that wisdom varies between 65-100 not between 0 and 100).\nReduce the time down to 6h based on combined wisdom of mercs in the activity.\n\nDefine new loot tables \n\nScroungeUrban - in any sector that has a city, mine, guard post, hospital or repair shop\nScroungeWilderness - in any sector that doesn't have all of the options above.\n\nRoll on the loot table once at the end of the operation and give the items to operation mercs and units from their squads with a popup that states what was gained.",
			description = T(721602292798, --[[ModItemSectorOperation Scrounge description]] "Some mercs can scrounge the sector for extra loot based on the sector that it is used in."),
			display_name = T(995460013505, --[[ModItemSectorOperation Scrounge display_name]] "Scrounge the Sector"),
			group = "Default",
			icon = "Mod/audaAto/Images/T_Icon_Activity_QuestActivity.png",
			id = "Scrounge",
			image = "Mod/audaAto/Images/recycle-symbol-dreamstime_88530524-664-664x630.dds",
			min_requirement_stat = "Strength",
			related_stat = "Strength",
			related_stat_2 = "Wisdom",
			short_name = T(455937100690, --[[ModItemSectorOperation Scrounge short_name]] "Scrounge"),
			sub_title = T(290258882878, --[[ModItemSectorOperation Scrounge sub_title]] "Special"),
			target_contribution = 4800,
		}),
		}),
	PlaceObj('ModItemFolder', {
		'name', "LootDef",
	}, {
		PlaceObj('ModItemLootDef', {
			Comment = "used in Harvest Junk operation",
			group = "Default",
			id = "ScroungeOperationUrbanLoot",
			PlaceObj('LootEntryLootDef', {
				loot_def = "IndustrialContainer",
				weight = 100000,
			}),
			PlaceObj('LootEntryLootDef', {
				loot_def = "Container_Explosives_VariedUtility",
				weight = 100000,
			}),
			PlaceObj('LootEntryLootDef', {
				loot_def = "JunkHarvest_Optional",
				weight = 100000,
			}),
		}),
		PlaceObj('ModItemLootDef', {
			Comment = "used in Harvest Junk operation",
			group = "Default",
			id = "ScroungeOperationWildernessLoot",
			PlaceObj('LootEntryLootDef', {
				loot_def = "EnemyValuables",
				weight = 100000,
			}),
			PlaceObj('LootEntryLootDef', {
				loot_def = "Container_MedStimms",
				weight = 100000,
			}),
			PlaceObj('LootEntryLootDef', {
				loot_def = "Container_Explosives_Batch",
				weight = 100000,
			}),
		}),
		}),
	PlaceObj('ModItemFolder', {
		'name', "UI",
	}, {
		PlaceObj('ModItemXTemplate', {
			__is_kind_of = "XDialog",
			group = "Zulu Satellite UI",
			id = "SectorOperation_ScroungeLootUI",
			PlaceObj('XTemplateWindow', {
				'__class', "ZuluModalDialog",
				'Background', RGBA(30, 30, 35, 115),
				'GamepadVirtualCursor', true,
			}, {
				PlaceObj('XTemplateWindow', {
					'comment', "Background",
					'__class', "XFrame",
					'IdNode', false,
					'Dock', "box",
					'HAlign', "center",
					'VAlign', "center",
					'LayoutMethod', "VList",
					'Image', "UI/PDA/os_background",
					'FrameBox', box(8, 8, 8, 8),
				}, {
					PlaceObj('XTemplateWindow', {
						'comment', "TitleBar",
						'__context', function (parent, context) return gv_Sectors[context.sector_id] end,
						'__class', "XFrame",
						'Image', "UI/PDA/os_header",
						'FrameBox', box(5, 5, 5, 5),
					}, {
						PlaceObj('XTemplateWindow', {
							'__class', "XFrame",
							'Id', "idSectorBG",
							'IdNode', false,
							'Padding', box(2, 0, 2, 0),
							'Dock', "left",
							'VAlign', "center",
							'MinWidth', 32,
							'Image', "UI/PDA/os_header",
							'FrameBox', box(5, 5, 20, 5),
						}, {
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Id', "idSector",
								'HAlign', "center",
								'VAlign', "center",
								'FoldWhenHidden', true,
								'TextStyle', "ConflictTitleBar",
								'ContextUpdateOnOpen', true,
								'OnContextUpdate', function (self, context, ...)
									if context.Side == "enemy1" or context.Side == "enemy2" then
										self.parent:SetImage("UI/PDA/sector_enemy")
									elseif context.Side == "player1" or context.Side == "player2" or context.Side == "ally" then
										self.parent:SetImage("UI/PDA/sector_ally")
									else
										self.parent:SetImage("UI/PDA/os_header")
									end
									
									self:SetText(T{764093693143, "<SectorIdColored(id)>", id = context.Id})
								end,
								'Translate', true,
								'WordWrap', false,
							}),
							}),
						PlaceObj('XTemplateWindow', {
							'comment', "SectorName",
							'__class', "XText",
							'Margins', box(5, 0, 0, 0),
							'HAlign', "left",
							'VAlign', "center",
							'HandleKeyboard', false,
							'HandleMouse', false,
							'TextStyle', "ConflictTitleBar",
							'ContextUpdateOnOpen', true,
							'OnContextUpdate', function (self, context, ...)
								local text = context.display_name
								self:SetText(T(text))
							end,
							'Translate', true,
						}),
						PlaceObj('XTemplateTemplate', {
							'__template', "PDASmallButton",
							'Id', "idClose",
							'Margins', box(2, 2, 4, 2),
							'Dock', "right",
							'HAlign', "center",
							'VAlign', "center",
							'MinWidth', 16,
							'MinHeight', 16,
							'MaxWidth', 16,
							'MaxHeight', 16,
							'OnPressEffect', "action",
							'OnPressParam', "actionClosePanel",
							'Text', "x",
							'CenterImage', "",
						}),
						}),
					PlaceObj('XTemplateWindow', {
						'comment', "descr",
						'__class', "XText",
						'Margins', box(8, 10, 8, 8),
						'Padding', box(0, 0, 0, 0),
						'HAlign', "left",
						'VAlign', "top",
						'MaxWidth', 500,
						'HandleKeyboard', false,
						'HandleMouse', false,
						'TextStyle', "ConflictDescription",
						'ContextUpdateOnOpen', true,
						'OnContextUpdate', function (self, context, ...)
							local merc_names = {}
							for _, merc in ipairs(context.mercs) do
								merc_names[#merc_names + 1] = merc.Nick
							end
							self:SetText( T{"<em><mercs></em> finished looking for useful items in <SectorName(sector)>\n\nFound Items:", mercs = ConcatListWithAnd(merc_names), sector = gv_Sectors[context.sector_id]})
						end,
						'Translate', true,
						'Text', T(374336506724, --[[ModItemXTemplate SectorOperation_ScroungeLootUI Text]] "Found Items:"),
						'TextVAlign', "center",
					}),
					PlaceObj('XTemplateWindow', {
						'__context', function (parent, context) return context.loot end,
						'__condition', function (parent, context)
							return true
						end,
						'__class', "XContentTemplate",
						'Margins', box(8, 0, 8, 8),
					}, {
						PlaceObj('XTemplateWindow', {
							'__class', "XFrame",
							'IdNode', false,
							'Dock', "box",
							'Image', "UI/PDA/os_background",
							'FrameBox', box(8, 8, 8, 8),
						}),
						PlaceObj('XTemplateWindow', {
							'comment', "loot",
							'__class', "XInventoryItemEmbed",
							'Padding', box(10, 10, 10, 10),
							'HAlign', "center",
							'MaxWidth', 500,
							'LayoutMethod', "HWrap",
							'LayoutHSpacing', 10,
							'LayoutVSpacing', 10,
							'FoldWhenHidden', true,
							'BorderColor', RGBA(60, 63, 68, 255),
							'Background', RGBA(42, 45, 54, 120),
							'HideWhenEmpty', true,
						}),
						}),
					PlaceObj('XTemplateWindow', {
						'Margins', box(8, 0, 8, 8),
						'HAlign', "center",
					}, {
						PlaceObj('XTemplateWindow', {
							'comment', "ActionBar",
							'__class', "XToolBarList",
							'Id', "idToolbar",
							'LayoutHSpacing', 16,
							'Background', RGBA(255, 255, 255, 0),
							'Toolbar', "ActionBar",
							'ButtonTemplate', "PDACommonButton",
							'ToolbarSectionTemplate', "",
						}, {
							PlaceObj('XTemplateAction', {
								'ActionId', "actionLoot",
								'ActionName', T(588119184658, --[[ModItemXTemplate SectorOperation_ScroungeLootUI ActionName]] "Take Loot"),
								'ActionToolbar', "ActionBar",
								'ActionGamepad', "ButtonX",
								'ActionBindable', true,
								'ActionState', function (self, host)
									
								end,
								'OnAction', function (self, host, source, ...)
									local context = host:GetContext()
									local items = context.loot
									local mercs = context.mercs
									for idx, merc in ipairs(mercs) do
										if #items<=0 then break end
										AddItemsToSquadBag(merc.Squad, items)
										merc:AddItemsToInventory(items)
									end
									
									if #items > 0 then
										local stash = GetSectorInventory(context.sector_id)		
										if stash then 
											AddItemsToInventory(stash, items, true)
										end
									end
									host:Close()
								end,
								'__condition', function (parent, context)
									return true
								end,
							}),
							PlaceObj('XTemplateAction', {
								'ActionId', "actionInventory",
								'ActionName', T(668442166266, --[[ModItemXTemplate SectorOperation_ScroungeLootUI ActionName]] "Inventory"),
								'ActionToolbar', "ActionBar",
								'ActionGamepad', "ButtonY",
								'ActionBindable', true,
								'ActionState', function (self, host)
									
								end,
								'OnAction', function (self, host, source, ...)
									local context = host:GetContext()
									local inventoryUnit = context.mercs[1]
									if inventoryUnit then
										host:Close()
										local stash = GetSectorInventory(context.sector_id)		
										if stash then 
											AddItemsToInventory(stash, context.loot)
										end
										OpenInventory(inventoryUnit)
									end
								end,
								'__condition', function (parent, context)
									return true
								end,
							}),
							PlaceObj('XTemplateAction', {
								'ActionId', "actionClosePanel",
								'ActionName', T(220337140854, --[[ModItemXTemplate SectorOperation_ScroungeLootUI ActionName]] "Close"),
								'ActionToolbar', "ActionBar",
								'ActionShortcut', "Escape",
								'ActionGamepad', "ButtonB",
								'ActionBindable', true,
								'OnAction', function (self, host, source, ...)
									host:Close()
								end,
							}),
							}),
						}),
					}),
				}),
		}),
		}),
}