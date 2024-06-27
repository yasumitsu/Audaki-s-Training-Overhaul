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
			CheckCompleted = function (self, merc, sector)
				if self:ProgressCurrent(merc, sector) >= self:ProgressCompleteThreshold(merc, sector) then
					self:Complete(sector)
				end
			end,
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
			OnRemoveOperation = function (self, merc)
				local sector = merc:GetSector()
				local workers = GetOperationProfessionals(sector.Id, self.id, false, merc.session_id) or {}
				local last = #workers<=0
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
		PlaceObj('ModItemSectorOperation', {
			Complete = function (self, sector)
				local stat = sector.training_stat
				local prop_meta = table.find_value(UnitPropertiesStats:GetProperties(), "id", stat)
				local stat_name = prop_meta.name	
				
				local mercs = GetOperationProfessionals(sector.Id, self.id, "Student")
				
				local merc_names = {}		
				for _, merc in ipairs(mercs) do	
					if merc.stat_learning then
						local learning_data = merc.stat_learning[stat] or empty_table
						local up_levels  = learning_data.up_levels or 0
						local progress = learning_data.progress or 0
						merc_names[up_levels] = merc_names[up_levels] or  {} 
						table.insert(merc_names[up_levels],merc.Nick)	
						if merc.stat_learning[stat] then
							merc.stat_learning[stat].up_levels = 0
						end
					end
				end
				
				local mercs = GetOperationProfessionals(sector.Id, self.id)
				for _, merc in ipairs(mercs) do
					merc:SetCurrentOperation("Idle")			
				end
				self:OnComplete(sector, mercs)
				if next (merc_names) then
					CombatLog("important", T{449926986206, "<stat_name> Training (<sector_id>) finished.",stat_name = stat_name, sector_id = GetSectorName(sector)})
					for up_levels, names in sorted_pairs(merc_names) do
						if up_levels == 0 then
							CombatLog("important", T{964788160766, "<merc_names> improved but not enough to gain a stat increase.", merc_names = ConcatListWithAnd(names) })
						else
							CombatLog("important", T{124938068325, "<em><unit></em> gained +<amount> <em><stat></em>",stat = stat_name, amount = Untranslated(up_levels), unit = ConcatListWithAnd(names)})
						end
					end					
				end
				Msg("OperationCompleted", self, mercs, sector)
			end,
			Custom = false,
			FilterAvailable = function (self, merc, profession)
				local sector = merc:GetSector()
				local stat = sector.training_stat
				if stat and profession == "Student" then
					if HasPerk(merc, "OldDog") then return false end
					local teachers = GetOperationProfessionals(sector.Id, self.id, "Teacher")
					local teacher = teachers[1]
					local solo = not teacher
					--if not teacher then return false end
					local max_learned_stat = self:ResolveValue("max_learned_stat")
					local teacher_stat = teacher and teacher[stat] or  self:ResolveValue("SoloTrainingStat")
					return  teacher_stat>merc[stat] and merc[stat]<=max_learned_stat
				else-- teacher
					local students = GetOperationProfessionals(sector.Id, self.id, "Student")
					for i_, st in ipairs(students) do
						if stat and st[stat] and merc[stat] and st[stat]>=merc[stat] then
							return false
						end	
					end
					return stat and  merc[stat] >= self.min_requirement_stat_value
				end
			end,
			GetRelatedStat = function (self, merc)
				local sector =  merc:GetSector()
				local stat = sector.training_stat
				if stat then
					return stat, merc[stat]
				end
			end,
			GetSectorSlots = function (self, prof, sector)
				if prof == "Student" then
					return  -1
				end
				return 1
			end,
			GetTimelineEventDescription = function (self, sector_id, eventcontext)
				local teachers, students
				local evmercs, prof
				if eventcontext.mercs then
					evmercs = table.map(eventcontext.mercs, function(id) return gv_UnitData[id].Nick end)
					prof = eventcontext.profession
				end
				local mercs = GetOperationProfessionalsGroupedByProfession(sector_id, self.id)
				local solo = not  next(mercs["Teacher"] )
				if prof then
					if prof=="Teacher" then
						teachers = evmercs 
						students = mercs["Student"]
						students = table.map(students, "Nick")
					else
						teachers = mercs["Teacher"]
						teachers = table.map(teachers, "Nick")
						students = evmercs
					end
				else
					students = mercs["Student"]
					students = table.map(students, "Nick")
					teachers = mercs["Teacher"]
					teachers = table.map(teachers, "Nick")
				end
				students = ConcatListWithAnd(students or empty_table)
				teachers = ConcatListWithAnd(teachers or empty_table)
				if solo then
					return T{178030548891, " <em><students></em> will finish training.", students = students}
				else
					return T{793160161691, "<em><teachers></em> will finish training <em><students></em>.", teachers = teachers, students = students}
				end
			end,
			HasOperation = function (self, sector)
				return true
			end,
			IsEnabled = function (self, sector)
				return true
			end,
			OnComplete = function (self, sector, mercs)
				--CompleteCurrentTrainMercs(sector, mercs)
				--student.stat_learning[stat].progress = learning_progress
			end,
			OnRemoveOperation = function (self, merc)
				merc.training_activity_progress = 0
			end,
			OnSetOperation = function (self, merc, arg)
				merc.training_activity_progress = 0
				if merc.OperationProfession=="Student" then
					local sector = merc:GetSector()
					local stat = sector.training_stat
					if merc.stat_learning and merc.stat_learning[stat] then
						merc.stat_learning[stat].up_levels = 0
					end
					return  merc.stat_learning and merc.stat_learning[stat] and merc.stat_learning[stat].progress or 0
				end
				RecalcOperationETAs(merc:GetSector(), "TrainMercs")		
			end,
			Parameters = {
				PlaceObj('PresetParamNumber', {
					'Name', "ActivityDurationInHoursFull",
					'Value', 24,
					'Tag', "<ActivityDurationInHoursFull>",
				}),
				PlaceObj('PresetParamNumber', {
					'Name', "PerTickProgress",
					'Value', 400,
					'Tag', "<PerTickProgress>",
				}),
				PlaceObj('PresetParamNumber', {
					'Name', "learning_speed",
					'Value', 250,
					'Tag', "<learning_speed>",
				}),
				PlaceObj('PresetParamNumber', {
					'Name', "wisdow_weight",
					'Value', 50,
					'Tag', "<wisdow_weight>",
				}),
				PlaceObj('PresetParamNumber', {
					'Name', "learning_base_bonus",
					'Value', 25,
					'Tag', "<learning_base_bonus>",
				}),
				PlaceObj('PresetParamNumber', {
					'Name', "max_learned_stat",
					'Value', 90,
					'Tag', "<max_learned_stat>",
				}),
				PlaceObj('PresetParamNumber', {
					'Name', "SoloTrainingStat",
					'Value', 80,
					'Tag', "<SoloTrainingStat>",
				}),
				PlaceObj('PresetParamPercent', {
					'Name', "SoloTrainingSpeedModifier",
					'Value', 300,
					'Tag', "<SoloTrainingSpeedModifier>%",
				}),
			},
			Professions = {
				PlaceObj('SectorOperationProfession', {
					'id', "Teacher",
					'display_name', T(589413786157, --[[ModItemSectorOperation TrainMercs display_name]] "Teacher"),
					'description', T(514842266059, --[[ModItemSectorOperation TrainMercs description]] "The Teacher will help the Students learn the selected skill."),
					'display_name_all_caps', T(597047932925, --[[ModItemSectorOperation TrainMercs display_name_all_caps]] "TEACHER"),
					'display_name_plural', T(712672761571, --[[ModItemSectorOperation TrainMercs display_name_plural]] "Teachers"),
					'display_name_plural_all_caps', T(668035057859, --[[ModItemSectorOperation TrainMercs display_name_plural_all_caps]] "TEACHERS"),
				}),
				PlaceObj('SectorOperationProfession', {
					'id', "Student",
					'display_name', T(730999259056, --[[ModItemSectorOperation TrainMercs display_name]] "Student"),
					'description', T(275381673199, --[[ModItemSectorOperation TrainMercs description]] "Students train a selected attribute over time. The higher the attribute the more time it takes to increase it."),
					'display_name_all_caps', T(959818465273, --[[ModItemSectorOperation TrainMercs display_name_all_caps]] "STUDENT"),
					'display_name_plural', T(880950083489, --[[ModItemSectorOperation TrainMercs display_name_plural]] "Students"),
					'display_name_plural_all_caps', T(417953882935, --[[ModItemSectorOperation TrainMercs display_name_plural_all_caps]] "STUDENTS"),
				}),
			},
			ProgressCompleteThreshold = function (self, merc, sector, prediction)
				--2 days,each tick is in 15min => 48*4 and scale 1000
						
				return self:ResolveValue("ActivityDurationInHoursFull")*4*self:ResolveValue("PerTickProgress")
			end,
			ProgressCurrent = function (self, merc, sector, prediction)
				if not merc then
					local mercs = GetOperationProfessionals(sector.Id, self.id, "Teacher") or GetOperationProfessionals(sector.Id, self.id, "Student")
					merc = mercs[1]	
				end	
				return merc and merc.training_activity_progress or 0
			end,
			ProgressPerTick = function (self, merc, prediction)
				        local progressPerTick = self:ResolveValue("PerTickProgress")
				        if CheatEnabled("FastActivity") then
				            progressPerTick = progressPerTick * 100
				        end
				        return progressPerTick
			end,
			SectorMercsTick = function (self, merc)
				local sector = merc:GetSector()
				local teacher = GetOperationProfessionals(sector.Id, self.id, "Teacher")
				local solo = not teacher
				local progress_per_tick = self:ProgressPerTick(teacher and teacher[1])
				local to_complete 
				merc.training_activity_progress = merc.training_activity_progress + progress_per_tick
				to_complete = self:ProgressCurrent(merc, sector) >= self:ProgressCompleteThreshold(merc, sector)
				merc.training_activity_progress = merc.training_activity_progress - progress_per_tick
				
				-- solo trianing
				--[[
				if not to_complete then
					local teachers = GetOperationProfessionals(sector.Id, self.id, "Teacher")
					if  not next(teachers) then
						to_complete = true 
					end
				end
				--]]
				if not to_complete then
					local students = GetOperationProfessionals(sector.Id, self.id, "Student")
					if not next(students) then
						to_complete = true
					end
				end
				-- call all mercs tick and complete after that		
				local mercs = GetOperationProfessionals(sector.Id, self.id)
				table.insert_unique(mercs, merc)
				for _, m in ipairs( mercs) do
					if to_complete then
						self:Tick(m)
					end
					m.training_activity_progress = m.training_activity_progress + progress_per_tick
				end
				if to_complete then
					self:Complete(sector)
				end
			end,
			SortKey = 40,
			Tick = function (self, merc)
				        -- Learning speed parameter defines the treshold of how much must be gained to gain 1 in a stat. Bigger number means slower.
				        local sector = merc:GetSector()
				        local stat = sector.training_stat
				        if self:ProgressCurrent(merc, sector) >= self:ProgressCompleteThreshold(merc, sector) then
				            return
				        end
				        if merc.OperationProfession == "Student" then
				            local teachers = GetOperationProfessionals(sector.Id, self.id, "Teacher")
				            local teacher = teachers[1]
				            if not teacher then
				                return
				            end
				        else
				            -- teacher
				            local students = GetOperationProfessionals(sector.Id, self.id, "Student")
				            local t_stat = merc[stat]
				            for _, student in ipairs(students) do
				                local is_learned_max = student[stat] >= t_stat or student[stat] >= AudaAto.sectorTrainingStatCap
				                if not is_learned_max then
				                    student.stat_learning = student.stat_learning or {}
				
				                    local progressPerTick = MulDivRound(t_stat, 100 + merc.Leadership, 100)
				                                                + self:ResolveValue("learning_base_bonus")
				                    if HasPerk(merc, "Teacher") then
				                        local bonusPercent = CharacterEffectDefs.Teacher:ResolveValue("MercTrainingBonus")
				                        progressPerTick = progressPerTick + MulDivRound(progressPerTick, bonusPercent, 100)
				                    end
				
				                    if #students >= 2 then
				                        progressPerTick = MulDivRound(progressPerTick, 100, 100 + 15 * (#students - 1))
				                    end
				
				                    if student.statGainingPoints == 0 then
				                        progressPerTick = MulDivRound(progressPerTick, 100, 1000)
				                    else
				                        progressPerTick = MulDivRound(progressPerTick, 1000, 100)
				                    end
				
				                    -- Ensure minimum progress
				                    progressPerTick = Max(5, progressPerTick)
				
				                    student.stat_learning[stat] = student.stat_learning[stat] or {progress=0, up_levels=0}
				                    local learning_progress = student.stat_learning[stat].progress
				                    learning_progress = learning_progress + progressPerTick
				
				                    local progress_threshold = 250 * student[stat] * (150 - Max(80, (student.Wisdom - 50) * 2)) / 100
				
				                    if student[stat] >= (AudaAto.sectorTrainingStatCap - 20) then
				                        progress_threshold = MulDivRound(progress_threshold, 100 + 5
				                            * (student[stat] - (AudaAto.sectorTrainingStatCap - 21)), 100)
				                    end
				
				                    if learning_progress >= progress_threshold then
				
				                        student.statGainingPoints = Max(0, student.statGainingPoints - 1)
				
				                        local gainAmount = 1
				                        local modId =
				                            string.format("StatTraining-%s-%s-%d", stat, student.session_id, GetPreciseTicks())
				                        GainStat(student, stat, gainAmount, modId, "Training")
				
				                        PlayVoiceResponse(student, "TrainingReceived")
				                        -- CombatLog("important",T{424323552240, "<merc_nickname> gained +1 <stat_name> from training in <sector_id>", stat_name = stat_name, merc_nickname  =  student.Nick, sector_id = Untranslated(sector.Id)})
				                        learning_progress = 0
				                        student.stat_learning[stat].up_levels = student.stat_learning[stat].up_levels + 1
				                    end
				                    student.stat_learning[stat].progress = learning_progress
				                end
				            end
				        end
				        local students = GetOperationProfessionals(sector.Id, self.id, "Student")
				        if not next(students) then
				            --	self:Complete(sector)
				            return
				        end
			end,
			description = T(487911271577, --[[ModItemSectorOperation TrainMercs description]] "Assign a Trainer to improve the stats of the other mercs. The trainer must have a higher stat than the trained mercs. Practicing without a teacher is considerably slower and can't improve stats beyond a certain point."),
			display_name = T(325243324189, --[[ModItemSectorOperation TrainMercs display_name]] "Train mercs"),
			group = "Default",
			icon = "UI/SectorOperations/T_Icon_Activity_TrainingMercs_Teacher",
			id = "TrainMercs",
			image = "UI/Messages/Operations/train_merc",
			min_requirement_stat_value = 50,
			short_name = T(325638505021, --[[ModItemSectorOperation TrainMercs short_name]] "Training"),
			sub_title = T(635055109153, --[[ModItemSectorOperation TrainMercs sub_title]] "Spend some time to improve merc stats"),
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