/*
	================================================================================
	System Shock 2 Community Patch (SCP) Scripts
	================================================================================

	================================================================================
	SCPMods
	================================================================================
	Hard Security
	Enabled by placing a file named "modSecurity" in the "scriptdata" folder.
	May be enabled/disabled at any time in a game.
	WARNING: Not tested in multiplayer.
	
	Makes the following changes to the security system:
	- When an alarm is tripped, a security computer must be hacked (at decreased
	  difficulty) to disable the alarm.
	- Failing a hack of a security computer will trip the alarm, but not "break"
	  the computer. As above, the computer must be hacked to disable the alarm.
	- Cameras may be hacked to permanently disable them. ICE picks work.
	- Failing a camera hack will trip the alarm.
	- Destroying a security camera, whether or not security is hacked, will trip
	  the alarm.
	- Destroying a camera or failing a camera hack while an alarm is already in
	  progress will reset the alarm countdown to the full countdown time.
	--------------------------------------------------------------------------------
	Death Taunts
	Enabled by placing a file named "modTaunts" in the "scriptdata" folder.
	May be enabled/disabled at any time in a game.
	
	Causes SHODAN, Xerxes, and/or the Many (as appropriate at the current plot
	state) to play an audio taunt when you die, if the QBR on the current level has
	been activated (otherwise many of them don't have time to completely play before
	the game returns to the main menu screen). This feature was originally planned
	but not fully implemented. All taunts were created by Irrational, but were just
	chopped out of existing audio files.
	--------------------------------------------------------------------------------
	Intoxication Effects
	Enabled by placing a file named "modDrunk" in the "scriptdata" folder.
	May be enabled/disabled at any time in a game.
	
	Adds eye nystagmus and walking stumble when drunk. This effect was created for
	SCP, but is disabled by default because it gets glitchy when leaning into
	things.
	--------------------------------------------------------------------------------
	Classic Final Boss
	Enabled by placing a file named "modFinalBoss" in the "scriptdata" folder.
	May be enabled/disabled at any time in a game.
	
	Reverts SCP's changes to the final (SHODAN) boss fight, mostly.
	================================================================================

	================================================================================
	Spawn Ecology Customization
	================================================================================
	In addition to the standard no_spawn, lower_spawn_min, and raise_spawn_rand
	config vars for influencing spawn rates, SCP adds a few more. As with the
	original config vars, these only affect some respawn ecologies, not all.
	- mult_spawn_max: Multiplies the defined maximum population for each ecology
	  by the provided value. For example "mult_spawn_max 2" would double all
	  allowed populations, while "mult_spawn_max 0.5" would halve them. Only affects
	  non-alarm ecologies. Note that many ecologies have a hard cap on spawns that
	  can't be exceeded even by raising the population limit. 
	- mult_spawn_period: Multiplies the period for each ecology. The period is how
	  often each ecology activates and checks its current monster population. Most
	  ecologies have a period of a few minutes. For example "mult_spawn_period 0.5"
	  would cause ecologies to repopulate twice as fast. Only affects non-alarm
	  ecologies.
	================================================================================
*/

// ================================================================================
//  GLOBAL CONFIGURATION
// ================================================================================

// debugging modes
const SPAWN_DEBUG_LEVEL     = 0; // trace eco/spawn activity (0=none, 1=basic, 2=verbose)
const TRIPWIRE_DEBUG_ENABLE = false; // visualize and validate (most) tripwires in-game
const MODIFY_DEBUG_ENABLE   = false; // trace all weapon modify activity
const QUEST_DEBUG_ENABLE    = false; // trace all quest variable changes
const PDA_DEBUG_ENABLE      = false; // enable log/note/email tabs for all decks in PDA

// spawn behaviors
const SPAWN_RAYCAST_RETRY  = true; // keep trying after Raycast failure
const SPAWN_FORCE_FARTHEST = true; // force effect of Farthest flag on all spawners
const SPAWN_ECO_ESCALATE   = 5; // ecology alarm escalation threshold (0=disable)

// check for activating SCP in the middle of a non-SCP game
const MIDGAME_ACT_CHECK = true;

// base grenade damage source scale (must match gamesys value)
const BASE_GRENADE_SCALE = 1.85;

// delay before destroyed worm piles respawn, in seconds
const WORM_PILE_RESPAWN_TIME = 300;

// global compass offset, in degrees
const COMPASS_OFFSET = 90;


// ================================================================================
//  PLAYER SCRIPTS
// ================================================================================

// --------------------------------------------------------------------------------
// Catch-all player stuff
class scpPlayerScript extends SqRootScript {
	function OnBeginScript() {
		if (!Object.Exists(self)) {
			return;
		}
		initTraits();
		if (QUEST_DEBUG_ENABLE && IsEditor()) {
			Quest.SubscribeMsg(self, "*");
		}

		if (PDA_DEBUG_ENABLE && IsEditor()) {
			// this doesn't work when executed immediately
			PostMessage(self, "DebugPDA");
		}

		if (Engine.ConfigIsDefined("undead") || Engine.ConfigIsDefined("no_spawn")) {
			print("Cheater!");
		}
		
		if (MIDGAME_ACT_CHECK && !Quest.Exists("SCPGame") && !IsEditor() && scp.MapName() != "earth") {
			// this doesn't work when executed immediately
			PostMessage(self, "Midgame");
		}

		// detect if player has level transitioned while dead
		//if (GetProperty("HitPoints") <= 1 && GetProperty("DeathStage") == 4) {
		//	PostMessage(self, "Slain");
		//}
	}

	function OnEndScript() {
		if (QUEST_DEBUG_ENABLE && IsEditor()) {
			Quest.UnsubscribeMsg(self, "*");
		}
	}

	function OnTraitGained() {
		initTraits();
	}

	// player has activated SCP in the middle of a non-SCP game
	function OnMidgame() {
		ShockGame.TlucTextAdd("SCPMidgame", "misc", 0);
		Sound.PlaySchemaAmbient(self, "hack_critical");
	}

	// implement qvar debugging
	function OnQuestChange() {
		if (!QUEST_DEBUG_ENABLE) {
			return;
		}
		local m = message();
		local note = startswith(m.m_pName.tolower(), "note");
		local states = ["removed", "added", "done", "secret done"];
		scp.Trace("QVar \"" + m.m_pName + "\" set to " + m.m_newValue + " (was " + m.m_oldValue + ")" + (note ? (" [quest " + states[m.m_newValue] + "]") : ""));
	}

	// enable all decks in PDA log/note/email tabs
	function OnDebugPDA() {
		local deck, logObj;
		scp.Trace("PDA DEBUG MODE ENABLED");
		for (deck = 1; deck < 10; deck++) {
			logObj = Object.Create("Audio Log");
			Property.Set(logObj, "Logs" + deck, "Logs", 2 << 29);
			ShockGame.UseLog(logObj, true);
		}
	}

	// an in-engine cutscene has begun
	function OnSaveOverlays() {
		// charge all equipped items so nothing runs out of charge in the middle of the cutscene
		local slot, item;
		local slotList = [ePlayerEquip.kEquipArmor, ePlayerEquip.kEquipSpecial, ePlayerEquip.kEquipSpecial2];
		foreach (slot in slotList) {
			item = ShockGame.Equipped(slot);
			if (item && Property.Possessed(item, "Energy")) {
				SetData("OrigCharge" + slot, Property.Get(item, "Energy"));
				PostMessage(item, "Recharge");
			}
		}
		// suspend any research in progress
		local lnk = Link.GetOne("Research", self);
		if (lnk) {
			SetData("csResSus", LinkDest(lnk));
			Link.Destroy(lnk);
		}
	}

	// an in-engine cutscene has ended
	function OnRestoreOverlays() {
		// restore charge for all equipped items
		local slot, item;
		local slotList = [ePlayerEquip.kEquipArmor, ePlayerEquip.kEquipSpecial, ePlayerEquip.kEquipSpecial2];
		foreach (slot in slotList) {
			item = ShockGame.Equipped(slot);
			if (item && Property.Possessed(item, "Energy")) {
				Property.SetSimple(item, "Energy", GetData("OrigCharge" + slot) || 100);
			}
		}
		// resume any suspended research
		local obj = GetData("csResSus");
		if (obj) {
			ShockGame.TechTool(obj); // this activates use mode...
			ShockGame.Mouse(0, 1); // ...so deactivate it
			ClearData("csResSus");
		}
	}

	// sent to player by all alcoholic beverages when consumed
	function OnLiquor() {
		if (!Object.HasMetaProperty(self, "Drunk")) {
			Object.AddMetaProperty(self, "Drunk");
		}
		PostMessage(self, "Drink");
	}

	// implement unused death taunts
	function OnSlain() {
		local deathMode;
		if (scp.IsModEnabled("modTaunts") && Quest.Get("AllowRespawn") && scp.PlayerNanites() >= 10) {
			// figure out death mode from current quest flags
			// mode 0=Xerxes; 1=Xerxes/Many; 2=Xerxes/Many/SHODAN; 3=Many/SHODAN; 4=Many; 5=SHODAN
			if (Quest.Get("EnterShodan")) {
				deathMode = 5;
			}
			else if (Quest.Get("EnterMany")) {
				deathMode = 4;
			}
			else if (Quest.Get("Transmit")) {
				deathMode = 3;
			}
			else if (Quest.Get("ShodanRoom")) {
				deathMode = 2;
			}
			else if (Quest.Get("ManyVision")) {
				deathMode = 1;
			}
			else {
				deathMode = 0;
			}
			//print("Death taunt mode: " + deathMode);
			Sound.PlaySchemaAmbient(self, "PlayerDeath" + deathMode);
		}
	}

	// initialize enhancements to OS Upgrades
	function initTraits() {
		// make Spatially Aware display all enemies on automap
		local map = scp.MapName();
		if (ShockGame.HasTrait("Player", eTrait.kTraitAutomap) && !(map == "many" || map == "shodan")) {
			local baddies = ["Robots", "Hybrids", "Annelids", "Turrets", "Cyborgs", "Shodan Avatars"];
			foreach (archetype in baddies) {
				Property.SetSimple(archetype, "MapObjIcon", "mevil");
				Property.SetSimple(archetype, "MapObjRotate", false);
			}
			// hold the eggs
			Property.SetSimple("Eggs", "MapObjIcon", "minvis");
			// add vision cone to cameras
			Property.SetSimple("Camera Vision", "MapObjIcon", "mcam");
		}
		// make Security Expert render player invisible to robots when security hacked
		if (ShockGame.HasTrait("Player", eTrait.kTraitSecurity)) {
			Property.SetSimple("Robots", "AI_VisType", 1); // security camera vision type
		}
	}

	/*
	function OnRecalcedStats() {
		// make Tank increase max HP by amount equivalent to 2 points of Endurance
		if (ShockGame.HasTrait("Player", eTrait.kTraitTank)) {
			local oldMax = GetProperty("MAX_HP");
			local newMax = oldMax + [5, 10, 5, 3, 3, 3][Quest.Get("Difficulty")] * 2;
			SetProperty("MAX_HP", newMax);
			SetProperty("HitPoints", scp.Clamp(GetProperty("HitPoints") + (newMax - oldMax), 1, newMax));
		}

		// make Power Psi increase player's max psi by 20%
		if (ShockGame.HasTrait("Player", eTrait.kTraitPsionic)) {
			local oldMax = GetProperty("PsiState", "Max Points");
			local newMax = oldMax * 1.2;
			SetProperty("PsiState", "Max Points", newMax);
			ShockGame.SetPlayerPsiPoints(scp.Clamp(ShockGame.GetPlayerPsiPoints() + (newMax - oldMax), 0, newMax));
		}
	}
	*/

	/*
	// --------------------------------------------------------------------------------
	// experimental HUD flicker effect when player hit by electricity
	// goes in player script
	function OnDamage() {
		// electricty stim
		if (message().kind == -378) {
			if (IsDataSet("ZapTimer")) {
				KillTimer(GetData("ZapTimer"));
			}
			SetData("ZapJitters", 1);
			SetData("ZapTimer", SetOneShotTimer("Zapped", 0.02));
		}
	}

	function OnTimer() {
		if (message().name == "Zapped") {
			local zj = GetData("ZapJitters");
			local olay;
			local olays = [kOverlayAmmo, kOverlayMeters, kOverlayHUD, kOverlayCrosshair];
			foreach (olay in olays) {
				ShockGame.OverlayChange(olay, scp.Rand(69) > zj ? kOverlayModeOff : kOverlayModeOn);
			}
			zj++;
			if (zj < 70) {
				SetData("ZapJitters", zj);
				SetData("ZapTimer", SetOneShotTimer("Zapped", 0.02));
			}
		}
	}
	*/
}

// --------------------------------------------------------------------------------
// Enhanced nav marker with UI beep and message when created, and ability to
// remove by frobbing.
// Requires adding Engine Features/FrobInfo: World Action: Script
class scpNavMarker extends SqRootScript {
	function OnCreate() {
		scp.AddText("NavMarkerCreate", "usemsg");
		Sound.PlaySchemaAmbient(self, "place_item");
	}

	function OnFrobWorldEnd() {
		scp.AddText("NavMarkerFrob", "usemsg");
		Object.Destroy(self);
	}
}

// --------------------------------------------------------------------------------
// Enhanced compass script
// - Plays UI sound when toggled.
// - Can offset compass heading globally
// - Can offset compass heading on a per-map basis by setting mission quest
//   data "compassOffset". Offset must be in degrees, range 0 - 360.
class scpCompass extends SqRootScript {
	function OnBeginScript() {
		if (Object.Exists(self)) {
			// give compass object time to fully initialize
			PostMessage(self, "SetHeading");
		}
	}

	function OnSetHeading() {
		local offset = Quest.Get("compassOffset") + COMPASS_OFFSET;
		SetProperty("CameraObj", "Heading", offset * 182);
	}

	function OnToggle() {
		SetProperty("CameraObj", "Draw?", !GetProperty("CameraObj", "Draw?"));
		Sound.PlaySchemaAmbient(self, "btabs");
	}

	function OnHide() {
		SetProperty("CameraObj", "Draw?", false);
	}
}

// --------------------------------------------------------------------------------
// Implement player intoxication effects
// (place on Drunk metaproperty)
class scpDrunk extends SqRootScript {
	// reusing this inapplicable property to save drunk level so it can survive level transitions
	static DrinkCount = "ProtocolExpl";

	// resume from save or level transition
	function OnBeginScript() {
		if (Object.Exists(self)) {
			activate();
		}
	}

	// drink notification from player script
	function OnDrink() {
		local drinks = GetProperty(DrinkCount) || 0.0;
		SetProperty(DrinkCount, drinks + 1.0);
		activate();
	}

	// med bed used
	function OnFullHeal() {
		soberUp();
	}

	// no being drunk after resurrection
	function OnSlain() {
		soberUp();
	}

	// a psychic or cybernetic vision is about to begin
	function OnSaveOverlays() {
		soberUp();
	}

	function OnTimer() {
		// drunk vision/coordination
		if (message().name == "Drunk") {
			// both eye and walking wobble accomplished by incrementally rotating the player
			// - higher time divider = lower frequency & higher amplitude
			// - higher sine divider = lower amplitude
			// wobble scale and detox rate determined by timer frequency, so don't change it
			local drinks = GetProperty(DrinkCount);
			// cap effects at four drinks
			// multiplier adjusts per-drink intensity
			local drunkPct = scp.Clamp(drinks * 1.5, 0.0, 4.0) / 4;
			local time = ShockGame.SimTime();
			local pos = Object.Position(self);
			local vel = vector();
			// horizontal gaze nystagmus
			local rot = sin(time / 30.0) * drunkPct;
			// walking wobble
			Physics.GetVelocity(self, vel);
			if (fabs(vel.x) + fabs(vel.y) > 6 && fabs(vel.z) < 0.01) {
				rot += (sin(time / 600.0) + sin(time / 300.0)) * drunkPct * 1.5;
			}
			Object.Teleport(self, vector(), vector(0, 0, rot), self);
			// prevent leaning through doors and into walls (this is terrible)
			local offset = (Camera.GetPosition() - pos);
			if (fabs(offset.x) > 0.05 || fabs(offset.y) > 0.05) {
				offset = offset * vector (1.5, 1.5, 1);
				if (Engine.ObjRaycast(pos, pos + offset, vector(), object(), 2, 3, self, null)) {
					Physics.PlayerMotionSetOffset(0, vector());
				}
			}
			// metabolize
			drinks -= 0.003; // about 10 seconds per unit of drink
			if (drinks <= 0.0) {
				soberUp();
			}
			else {
				SetProperty(DrinkCount, drinks);
				SetData("DrunkTimer", SetOneShotTimer("Drunk", 0.03));
			}
		}
	}

	function activate() {
		local drinks = GetProperty(DrinkCount) || 0.0;
		if (drinks > 0) {
			if (IsDataSet("DrunkTimer")) {
				KillTimer(GetData("DrunkTimer"));
			}
			SetData("DrunkTimer", SetOneShotTimer("Drunk", 0.03));
		}
	}

	function soberUp() {
		if (IsDataSet("DrunkTimer")) {
			KillTimer(GetData("DrunkTimer"));
			ClearData("DrunkTimer");
		}
		Property.Remove(self, DrinkCount);
		Object.RemoveMetaProperty(self, "Drunk");
	}
}

// --------------------------------------------------------------------------------
// Squirrel RootPsi class with no changes so inheriting Psi functions can be patched
// (copied from SS2Tool implementation)
class RootPsi extends SqRootScript {
	function ActivatePsi() {
		local power, type;
		local scriptdonor = ShockObj.FindScriptDonor(self, GetClassName());
		SetData("MetaPropID", scriptdonor);
		SetData("Power", power = Property.Get(scriptdonor, "PsiPower", "Power"));
		SetData("Type", type = Property.Get(scriptdonor, "PsiPower", "Type"));
		SetData("Data1", Property.Get(scriptdonor, "PsiPower", "Data 1"));
		SetData("Data2", Property.Get(scriptdonor, "PsiPower", "Data 2"));
		SetData("Data3", Property.Get(scriptdonor, "PsiPower", "Data 3"));
		SetData("Data4", Property.Get(scriptdonor, "PsiPower", "Data 4"));
		local stat = ShockGame.GetStat(self, eStats.kStatPsi);
		if (ShockPsi.IsOverloaded(power)) {
			stat += 2;
		}
		SetData("PsiStat", stat);
		if (type == ePsiPowerType.kPsiTypeShield) {
			SetData("EndHandle", SetOneShotTimer("ShutDown", ShockPsi.GetActiveTime(power), power));
		}
	}

	function DeactivatePsi() {
		ShockPsi.OnDeactivate( GetData("Power") );
		ClearData("Power");
	}

	function ClearShieldTimer() {
		if (IsDataSet("EndHandle")) {
			KillTimer( GetData("EndHandle") );
			ClearData("EndHandle");
		}
	}

	function OnBeginScript() {
		if (!IsDataSet("Power") && self == ObjID("Player")) {
			ActivatePsi();
		}
	}

	function OnTimer() {
		if (message().name == "ShutDown") {
			if (self == ObjID("Player") && message().data == GetData("Power")) {
				ClearData("EndHandle");
				DeactivatePsi();
			}
		}
	}

	function OnDeactivatePsi() {
		if (self == ObjID("Player") && message().data == GetData("Power")) {
			ClearShieldTimer();
			DeactivatePsi();
		}
	}
}

// --------------------------------------------------------------------------------
// Fix Localized Pyrokinesis triggering unnecessary grunts when burning objects
class Immolate extends RootPsi {
	function ActivatePsi() {
		base.ActivatePsi();

		if (!IsDataSet("pyroFX")) {
			SetData("pyroFX", Object.Create("Localized Pyro"));
		}

		// make the pyroFX object the Incendiary stim source, otherwise if player is the source
		// it will cause some objects to do player pain grunts
		local pyroFX = GetData("pyroFX");

		if (!Link.AnyExist("CulpableFor", self, pyroFX)) {
			Link.Create("CulpableFor", self, pyroFX);
		}

		if (!Object.HasMetaProperty(pyroFX, "ImmolateStimSrc")) {
			Object.AddMetaProperty(pyroFX, "ImmolateStimSrc");
		}
	}

	function DeactivatePsi() {
		base.DeactivatePsi();
		Object.Destroy(GetData("pyroFX"));
		ClearData("pyroFX");
	}
}

// --------------------------------------------------------------------------------
// Fix Remote Circuitry Manipulation allowing hacking of normally non-hackable objects
class CyberPsi extends RootPsi {
	function ActivatePsi() {
		// mandatory psi stuff
		base.ActivatePsi();
		DeactivatePsi();
		// hack something
		local hackObj = ShockGame.GetDistantSelectedObj();
		local objState = Property.Get(hackObj, "ObjState") || 0;
		if (!hackObj) {
			// no target
		}
		else if (!Property.Possessed(hackObj, "HackDiff") ||
			Property.Get(hackObj, "HackDiff", "Success %") <= -1000 ||
			objState == eObjState.kObjStateBroken ||
			objState == eObjState.kObjStateHacked ||
			(Object.InheritsFrom(hackObj, "Hackable Crate") && objState == eObjState.kObjStateNormal) ||
			(Property.Possessed(hackObj, "HitPoints") && Property.Get(hackObj, "HitPoints") < 1))
		{
			scp.AddText("FreeHackCant", "misc");
		}
		else {
			ShockGame.HRM(0, hackObj, true);
		}
	}
}


// ================================================================================
//  SECURITY SCRIPTS (CAMERAS, COMPUTERS, ECOLOGIES)
// ================================================================================

// --------------------------------------------------------------------------------
// Enhanced SecurityComputer script
// - Stops turrets (and robots if applicable) from attacking player when security hacked
// - Implements optional hard security mode: security computer must be hacked to disable alarm
class scpSecurityComputer extends SqRootScript {
	function OnBeginScript() {
		if (Object.Exists(self)) {
			SetData("hardSecMode", scp.IsModEnabled("modSecurity") && scp.MapName() != "earth");
		}
	}

	function OnFrobWorldEnd() {
		if (GetData("hardSecMode")) {
			// in hard security mode, failing a hack doesn't break the security computer,
			// but you do have to hack it (at reduced difficulty) to disable the alarm
			SetProperty("ObjState", eObjState.kObjStateNormal);
			if (!IsDataSet("hackSuccess")) {
				// stash base hack difficulty
				SetData("hackSuccess", GetProperty("HackDiff", "Success %"));
				SetData("hackCritFail", GetProperty("HackDiff", "Critical Fail %"));
				SetData("hackCost", GetProperty("HackDiff", "Cost"));
			}
			// set appropriate hack difficulty
			// (greater node success %, no critical nodes)
			if (ShockGame.IsAlarmActive()) {
				// set lesser hack difficulty
				SetProperty("HackDiff", "Success %", GetData("hackSuccess") + 20);
				SetProperty("HackDiff", "Critical Fail %", 0);
				SetProperty("HackDiff", "Cost", GetData("hackCost") / 2);
			}
			else {
				// restore base values
				SetProperty("HackDiff", "Success %", GetData("hackSuccess"));
				SetProperty("HackDiff", "Critical Fail %", GetData("hackCritFail"));
				SetProperty("HackDiff", "Cost", GetData("hackCost"));
			}
		}
		else if (GetProperty("ObjState") == eObjState.kObjStateNormal) {
			scp.SilenceEcoXerxes();
			ShockGame.DisableAlarmGlobal();
		}
		Sound.PlayEnvSchema(self, "Event Activate", self, 0, eEnvSoundLoc.kEnvSoundAtObjLoc);
		ShockGame.OverlayChangeObj(kOverlaySecurComp, kOverlayModeOn, self);
	}

	function OnHackSuccess() {
		local hackTime;
		local alarmActive = ShockGame.IsAlarmActive();
		local hardSecMode = GetData("hardSecMode");
		scp.SilenceEcoXerxes();
		ShockGame.DisableAlarmGlobal();
		ShockGame.RemoveAlarm();
		// in normal security mode a hack always hacks security
		// in hard security mode a hack while an alarm is active just disables the alarm
		if (!hardSecMode || (hardSecMode && !alarmActive)) {
			hackTime = GetProperty("HackTime") * ShockGame.GetStat("Player", eStats.kStatCyber);
			hackSecurity(hackTime);
			Networking.Broadcast(self, "NetHackSuccess", true, hackTime);
		}
	}

	function OnNetHackSuccess() {
		hackSecurity(message().data);
	}

	function OnHackCritfail() {
		Link.BroadcastOnAllLinks(self, "Alarm", "SwitchLink");
		Networking.Broadcast(self, "NetHackCritfail", false, 0);
		Property.SetSimple("Player", "HackTime", 0);
	}

	function OnNetHackCritfail() {
		Property.SetSimple("Player", "HackTime", 0);
	}

	function hackSecurity(hackTime) {
		Property.SetSimple("Player", "HackVisi", 0);
		ShockGame.RecalcStats("Player");
		ShockGame.OverlayChange(kOverlayHackIcon, kOverlayModeOn);
		Sound.PlaySchemaAmbient(self, "xer01");
		Property.SetSimple("Player", "HackTime", hackTime + ShockGame.SimTime());
		// kill select AI links to player
		local obj, lnk, flavor;
		local kill = [];
		local linkFlavors = ["~AIAwareness", "~AIAttack", "~AITarget"];
		foreach (flavor in linkFlavors) {
			foreach (lnk in Link.GetAll(flavor, "Player", 0)) {
				obj = LinkDest(lnk);
				if (Object.InheritsFrom(obj, "Turrets")) {
					kill.push(lnk);
				}
				else if (Object.InheritsFrom(obj, "Robots") && ShockGame.HasTrait("Player", eTrait.kTraitSecurity)) {
					kill.push(lnk);
				}
			}
		}
		foreach (lnk in kill) {
			Link.Destroy(lnk);
		}
	}
}

// --------------------------------------------------------------------------------
// Security camera helper script
// Requires custom models camblk and camhak.
// - Visibly disables security cameras while security is hacked.
// - Makes slain cameras not frobbable, display "destroyed" name string.
// - Supports camera being vulnerable to stasis field generator.
// - Supports Spatially Aware map icon functionality
// - Incorporates functionality of CameraDeath script.
// - Implements optional hard security mode.
//   - Makes cameras hackable.
//   - Restarts alarm when destroyed.
class scpCameraHelper extends SqRootScript {
	function OnBeginScript() {
		// sanity check
		if (!Object.Exists(self) || !Physics.HasPhysics(self)) {
			return;
		}
		// randomly space out the timer so every camera on the level isn't
		// calling this at the same time
		if (IsDataSet("HackTimer")) {
			KillTimer(GetData("HackTimer"));
		}
		if (GetProperty("HitPoints") > 0) {
			SetData("HackTimer", SetOneShotTimer("HackCheck", scp.Rand()));
		}
		// hard security mode
		local map = scp.MapName();
		if (scp.IsModEnabled("modSecurity") && !(map == "earth" || map == "shodan")) {
			SetData("hardSecMode", true);
			if (GetProperty("ObjState") != eObjState.kObjStateHacked) {
				SetProperty("HackText", "CameraHackMod:\"Hack to permanently disable this camera.\"");
				SetProperty("HUDUse", "CameraMod:\"Hack camera.\"");
				// derive hack params from parent security computer
				local ecoObj, compObj;
				// defaults if can't find security computer
				local hackSucc = 15;
				local hackCrit = 4;
				local hackCost = 5;
				// find camera's computer
				ecoObj = scp.GetLinkedWith("SwitchLink", "Ecology", self);
				compObj = scp.GetLinkedWith("~SwitchLink", "HackDiff", ecoObj);
				if (compObj) {
					hackSucc = Property.Get(compObj, "HackDiff", "Success %") - 10;
					hackCrit = Property.Get(compObj, "HackDiff", "Critical Fail %") + 1;
					hackCost = Property.Get(compObj, "HackDiff", "Cost");
				}
				// assign values
				SetProperty("HackDiff", "Success %", hackSucc);
				SetProperty("HackDiff", "Critical Fail %", hackCrit);
				SetProperty("HackDiff", "Cost", hackCost);
			}
		}
		else if (GetData("hardSecMode")) {
			// clean up after disabling hard security mode
			SetData("hardSecMode", false);
			Property.Remove(self, "HackText");
			Property.Remove(self, "HackDiff");
			Property.Remove(self, "HUDUse");
		}
		// attach subobject so Spatially Aware map icon can show current facing
		if (!IsDataSet("IconDone")) {
			local obj = Object.Create("Camera Vision");
			local lnk = Link.Create("DetailAttachement", obj, self);
			LinkTools.LinkSetData(lnk, "Type", 4); // subobject
			LinkTools.LinkSetData(lnk, "vhot/sub #", 1);
			SetData("IconDone", true);
		}
	}

	function OnTimer() {
		local mName = message().name;
		if (mName == "HackCheck") {
			if (ShockGame.OverlayOn(kOverlayHackIcon)) {
				if (!GetData("SecHacked")) {
					SetData("SecHacked", true);
					SetProperty("ModelName", "camhak");
					SetProperty("AI_Vision", 0);
					SetProperty("AI_Frozen", "Start Time", 0);
					SetProperty("AI_Frozen", "Duration", 2000000000);
					// hacking security prevents this from being sent normally
					PostMessage(self, "Unfreeze");
				}
			}
			else if (GetData("SecHacked")) {
				clearHacked(true);
			}
			// schedule next check
			if (GetProperty("ObjState") != eObjState.kObjStateHacked) {
				SetData("HackTimer", SetOneShotTimer("HackCheck", 1));
			}
		}
		else if (mName == "ResetModel") {
			if (GetProperty("ObjState") == eObjState.kObjStateHacked) {
				SetProperty("ModelName", "camblk");
			}
			else {
				SetProperty("ModelName", "camhak");
			}
		}
	}

	function OnFrobWorldEnd() {
		if (GetData("hardSecMode") && GetProperty("ObjState") == eObjState.kObjStateNormal) {
			// activate overlay
			ShockGame.OverlayChangeObj(kOverlaySecurComp, kOverlayModeOn, self);
			ShockGame.OverlayChangeObj(kOverlayHRMPlug, kOverlayModeOn, self);
		}
	}

	// make camera permanently hacked
	function OnHackSuccess() {
		if (IsDataSet("HackTimer")) {
			KillTimer(GetData("HackTimer"));
		}
		clearHacked(false);
		Property.Remove(self, "HUDUse");
		SetProperty("ObjState", eObjState.kObjStateHacked);
		SetProperty("AI", "Default"); // only way to kill camloop schema
		SetProperty("AI", "Camera");
		SetProperty("AI_Mode", eAIMode.kAIM_Asleep);
		SetProperty("ModelName", "camblk");
		SetProperty("SelfIllum", 0);
		killMapIcon();
		// prevent Xerxes talking over himself
		local eco = scp.GetLinkedWith("SwitchLink", "Ecology", self);
		if (eco) {
			scp.SilenceEcoXerxes();
			Sound.PlaySchemaAmbient(eco, "xer05");
		}
		else {
			Sound.PlaySchemaAmbient(self, "xer05");
		}
		// putting the AI to sleep prevents this from being sent normally
		PostMessage(self, "Unfreeze");
	}

	// handle being hacked with an ICE pick
	function OnIcePick() {
		if (ShockGame.OverlayGetObj() == self) {
			ShockGame.OverlayChangeObj(kOverlaySecurComp, kOverlayModeOff, self);
			ShockGame.OverlayChangeObj(kOverlayHRM, kOverlayModeOff, self);
		}
	}

	function OnHackCritfail() {
		// override hack script breaking camera
		SetProperty("ObjState", eObjState.kObjStateNormal);
		hardAlarm();
	}

	function OnNetHackCritfail() {
		Property.SetSimple("Player", "HackTime", 0);
	}

	// assist stasis field generator
	function OnStasisStimulus() {
		if (!Object.HasMetaProperty(self, "Blind")) {
			Object.AddMetaProperty(self, "Blind")
		}
	}

	function OnUnfreeze() {
		Object.RemoveMetaProperty(self, "Blind");
	}

	function OnSlain() {
		// perform CameraDeath script functions (spawn explosion and switch to destroyed model)
		ActReact.React("tweq_control", 1.0, self, 0, eTweqType.kTweqTypeModels, eTweqDo.kTweqDoActivate);
		Object.Teleport(Object.Create("HE_harmless"), vector(), vector(), self);
		Networking.Broadcast(self, "NetSlain", false);
		// make broken camera not frobbable, etc.
		Object.AddMetaProperty(self, "BreakCamera");
		// hide any active overlays
		if (ShockGame.OverlayGetObj() == self) {
			ShockGame.OverlayChangeObj(kOverlaySecurComp, kOverlayModeOff, self);
			ShockGame.OverlayChangeObj(kOverlayHRM, kOverlayModeOff, self);
		}
		// clean up helper stuff
		KillTimer(GetData("HackTimer"));
		if (GetData("SecHacked")) {
			clearHacked(false);
		}
		killMapIcon();
		// raise alarm in hard mode
		if (GetData("hardSecMode") && GetProperty("ObjState") == eObjState.kObjStateNormal) {
			hardAlarm();
		}
	}

	function OnNetSlain() {
		Object.Teleport(Object.Create("HE_harmless"), vector(), vector(), self);
	}

	// raise an alarm in hard security mode
	function hardAlarm() {
		local ecoObj = scp.GetLinkedWith("SwitchLink", "Ecology", self);
		if (!ecoObj) {
			print("WARNING: No ecology linked to camera " + self + "!");
		}
		if (ShockGame.IsAlarmActive()) {
			ShockGame.DisableAlarmGlobal();
		}
		// give ecology time to receive reset before reactivating alarm
		PostMessage(self, "RestartAlarm", ecoObj);
	}

	function OnRestartAlarm() {
		// suppress Xerxes security alert terminated announcement
		scp.SilenceEcoXerxes();
		// (re)activate alarm
		Link.BroadcastOnAllLinksData(self, "Alarm", "SwitchLink", ObjID("Player"));
		// give ecology time to receive alarm before playing a different Xerxes message
		PostMessage(self, "RestartAlarmFinal", message().data);
	}

	function OnRestartAlarmFinal() {
		// suppress Xerxes security alert activation announcement
		scp.SilenceEcoXerxes();
		// play unused (in vanilla) "threat detected" schema
		Sound.PlaySchemaAmbient(message().data, "xer06");
	}

	function OnAlertness() {
		if (GetData("SecHacked")) {
			// fighting the CameraAlert script
			SetOneShotTimer("ResetModel", 0.1)
		}
	}

	function killMapIcon() {
		local lnk = Link.GetOne("~DetailAttachement", self);
		if (lnk) {
			Object.Destroy(LinkDest(lnk));
		}
	}

	function clearHacked(changeModel) {
		SetData("SecHacked", false);
		if (changeModel) {
			SetProperty("ModelName", "camgrn");
		}
		Property.Remove(self, "AI_Vision");
		Property.Remove(self, "AI_Frozen");
	}
}

// --------------------------------------------------------------------------------
// Save object ID of ecology to qvar
class scpEcologyHelper extends SqRootScript {
	function OnSim() {
		local i = 0;
		local prefix = "ecoObjID";
		while (true) {
			if (Quest.Exists(prefix + i)) {
				// make sure no duplicates
				if (Quest.Get(prefix + i) == self) {
					break;
				}
				else {
					i++;
					continue;
				}
			}
			else {
				Quest.Set(prefix + i, self, eQuestDataType.kQuestDataMission);
				break;
			}
		}
	}
}

// --------------------------------------------------------------------------------
// Extinguish animated light on self if no switchlink to another object (assumed
// to be a security console) exists
class scpConLight extends SqRootScript {
	function OnBeginScript() {
		if (Object.Exists(self) && !Link.GetOne("SwitchLink", self)) {
			Light.SetMode(self, ANIM_LIGHT_MODE_EXTINGUISH);
		}
	}
}


// ================================================================================
//  AI/CREATURE/APPARITION SCRIPTS
// ================================================================================

// --------------------------------------------------------------------------------
// Enhanced turret script
// - Marks turret as hacked when hacked.
// - Appropriately hides/refreshes overlays when hacked.
// - Removes "Hack turret" use text when hacked.
// - Supports repairing turret access port after failed hack.
// - Makes physics model match open/closed state.
class scpTurret extends SqRootScript {
	// turret physics sizes/offsets
	static turSX  = 3.0;    // length (actual 3.55)
	static turSY  = 2.4;    // width (actual 2.7)
	static turSZC = 3.65;   // height, closed
	static turSZO = 5.7;    // height, open
	static turOX  = 0.0;    // X offset
	static turOY  = 0.07;   // Y offset
	static turOZC = -1.025; // Z offset, closed
	static turOZO = 0.0;    // Z offset, open

	function OnBeginScript() {
		// turrets with scripts that broadcast on death cause the turret to be internally
		// resurrected for a moment (maybe), and they crash the game if their physics are
		// touched, so make sure we don't do that
		if (isPopupTurret() && !IsDataSet("MadeOBB") && Object.Exists(self) && Physics.HasPhysics(self)) {
			SetOneShotTimer("InitPhysics", 0.2);
		}
	}

	function OnTimer() {
		if (message().name == "InitPhysics" && Object.Exists(self) && Physics.HasPhysics(self)) {
			// change collision model from sphere to OBB
			Physics.DeregisterModel(self);
			SetProperty("PhysType", "Type", 0); // OBB
			SetProperty("PhysType", "# Submodels", 6);
			SetProperty("PhysDims", "Size", vector(turSX, turSY, turSZC));
			SetProperty("PhysDims", "Radius 1", 0);
			SetProperty("PhysDims", "Radius 2", 0);
			SetProperty("PhysDims", "Offset 1", vector(turOX, turOY, turOZC));
			SetProperty("PhysDims", "Offset 2", vector());
			SetProperty("PhysControl", "Controls Active", 24); // Location, Rotation
			SetProperty("PhysCanMant", true);
			Physics.Activate(self);
			SetData("MadeOBB", true);
		}
		else if (message().name == "CloseTop") {
			if (GetProperty("JointPos", "Joint 1") < 1.75) {
				// closed turret bounding box
				SetProperty("PhysDims", "Size", vector(turSX, turSY, turSZC));
				SetProperty("PhysDims", "Offset 1", vector(turOX, turOY, turOZC));
			}
			else {
				SetData("CloseTimer", SetOneShotTimer("CloseTop", 0.25));
			}
		}
	}

	function OnAlertness() {
		if (!isPopupTurret()) {
			return;
		}
		if (IsDataSet("CloseTimer")) {
			KillTimer(GetData("CloseTimer"));
		}
		if (message().level > 1) {
			// open turret bounding box
			SetProperty("PhysDims", "Size", vector(turSX, turSY, turSZO));
			SetProperty("PhysDims", "Offset 1", vector(turOX, turOY, turOZO));
		}
		else {
			// wait for turret to return to closed position
			SetData("CloseTimer", SetOneShotTimer("CloseTop", 0.25));
		}
	}

	function OnFrobWorldEnd() {
		local objState = GetProperty("ObjState");
		if (objState == eObjState.kObjStateHacked || Object.HasMetaProperty(self, "Good Guy")) {
			ShockGame.OverlayChangeObj(kOverlayTurret, kOverlayModeOn, self);
		}
		else if (objState == eObjState.kObjStateNormal) {
			ShockGame.OverlayChangeObj(kOverlayTurret, kOverlayModeOn, self);
			ShockGame.OverlayChangeObj(kOverlayHRMPlug, kOverlayModeOn, self);
		}
		else if (objState == eObjState.kObjStateBroken) {
			ShockGame.OverlayChangeObj(kOverlayContainer, kOverlayModeOn, self);
		}
	}

	function OnHackSuccess() {
		// make hacked
		Property.SetSimple(self, "ObjState", eObjState.kObjStateHacked);
		Object.AddMetaProperty(self, "Good Guy");
		Sound.PlaySchemaAmbient(self, "xer05");
		// clean up overlays
		if (ShockGame.OverlayOn(kOverlayTurret)) {
			PostMessage(self, "Refresh");
		}
		else if (ShockGame.OverlayOn(kOverlayHRM)) {
			ShockGame.OverlayChangeObj(kOverlayHRM, kOverlayModeOff, self);
			PostMessage(self, "Refresh");
		}
		SetProperty("HUDUse", "");
	}

	function OnHackCritfail() {
		Property.SetSimple(self, "ObjState", eObjState.kObjStateBroken);
		Object.RemoveMetaProperty(self, "Good Guy");
		Link.BroadcastOnAllLinks(self, "Alarm", "SwitchLink");
	}

	function OnSlain() {
		if (ShockGame.OverlayGetObj() == self) {
			ShockGame.OverlayChangeObj(kOverlayTurret, kOverlayModeOff, self);
			ShockGame.OverlayChangeObj(kOverlayHRM, kOverlayModeOff, self);
			ShockGame.OverlayChangeObj(kOverlayContainer, kOverlayModeOff, self);
		}
	}

	function OnRefresh() {
		// doesn't refresh text if redisplayed immediately
		ShockGame.OverlayChangeObj(kOverlayTurret, kOverlayModeOn, self);
	}
	
	function isPopupTurret() {
		local arch = ShockGame.GetArchetypeName(self);
		return arch == "Blast Turret" || arch == "Laser Turret" || arch == "Slug Turret";
	}
}

// --------------------------------------------------------------------------------
// Spawns Rickenbacker turret corpse with matching turret rotation
// (explosion spawned by flinder so it can have the appropriate offset)
class scpRickTurretDeath extends SqRootScript {
	function OnSlain() {
		spawnCorpse();
		Networking.Broadcast(self, "NetSlain", false);
	}
	
	function OnNetSlain() {
		spawnCorpse();
	}
	
	function spawnCorpse() {
		local ceilType = Object.InheritsFrom(self, "Rick Turret");
		local joint = ceilType ? "Joint 1" : "Joint 2";
		local obj = Object.Create(ceilType ? "Rick Turret Corpse" : "Rick Turret Corpse Inv");
		Property.Set(obj, "JointPos", joint, GetProperty("JointPos", joint) * (ceilType ? 1 : -1));
		Object.Teleport(obj, vector(), vector(), self);
		Object.Destroy(self);
	}
}

// --------------------------------------------------------------------------------
// Enhanced BaseAI script
// Adds muting of any ambient sound on an AI when stasis frozen. This works for bots
// and worms, but not eggs and swarms since they don't freeze conventionally.
class BaseAI extends SqRootScript {
	function OnDamage() {
		AI.UnStun(self);
	}
	
	function OnFreeze() {
		if (HasProperty("AmbientHacked")) {
			local rad = GetProperty("AmbientHacked", "Radius");
			if (rad > 0) {
				SetData("AmbRad", rad);
				SetProperty("AmbientHacked", "Radius", 0);
			}
		}
	}

	function OnUnFreeze() {
		if (IsDataSet("AmbRad")) {
			SetProperty("AmbientHacked", "Radius", GetData("AmbRad"));
		}
	}
}

// --------------------------------------------------------------------------------
// Enhanced BaseEgg script
// - Supports freezing eggs with stasis field generator.
// - Implements spawning organs at same rate as other AIs.
//   (remove organ flinder link from Grub Pods (-1337) and Swarmer Pods (-1338))
class scpBaseEgg extends SqRootScript {
	function OnTurnOn() {
		SetData("triggered", true);
		if (!GetData("opened") && !GetData("frozen")) {
			SetData("opened", true);
			podOpen();
		}
	}

	function OnStasisStimulus() {
		// create stasis visual effect
		if (!GetData("frozen")) {
			createFX();
		}
		SetData("frozen", true);
		// mute sound
		if (HasProperty("AmbientHacked")) {
			local rad = GetProperty("AmbientHacked", "Radius");
			if (rad > 0) {
				SetData("AmbRad", rad);
				SetProperty("AmbientHacked", "Radius", 0);
			}
		}
		// schedule unfreezing
		if (IsDataSet("StasisTimer")) {
			KillTimer(GetData("StasisTimer"));
		}
		SetData("StasisTimer", SetOneShotTimer("StasisTimer", message().intensity));
	}

	function OnTimer() {
		if (message().name == "StasisTimer") {
			SetData("frozen", false);
			destroyFX();
			if (IsDataSet("AmbRad")) {
				SetProperty("AmbientHacked", "Radius", GetData("AmbRad"));
			}
			if (GetData("triggered")) {
				PostMessage(self, "TurnOn");
			}
		}
	}

	function podOpen() {
		ActReact.React("tweq_control", 1.0, self, 0, eTweqType.kTweqTypeAll, eTweqDo.kTweqDoActivate);
		Sound.PlaySchema(self, "pod_exp");
	}

	function createFX() {
		local obj = Object.Create("EM Stasis Field");
		Link.Create("ParticleAttachement", obj, self);
	}

	function destroyFX() {
		local lnk;
		if (Link.AnyExist("~ParticleAttachement", self, 0)) {
			foreach (lnk in Link.GetAll("~ParticleAttachement", self, 0)) {
				Link.Destroy(lnk);
			}
		}
	}

	function emitOrgan(type) {
		local chance = 0.25;
		if (!Quest.Exists("First " + type)) {
			chance = 1;
			Quest.Set("First " + type, true, eQuestDataType.kQuestDataCampaign);
		}
		if (scp.Rand() < chance) {
			local obj = Object.Create(type);
			Object.Teleport(obj, vector(), vector(), self);
			Property.Set(obj, "PhysState", "Velocity", vector(scp.Rand(10) - 5, scp.Rand(10) - 5, scp.Rand(3) - 1));
			Property.Set(obj, "PhysState", "Rot Velocity", vector(scp.Rand(10) - 5, scp.Rand(10) - 5, scp.Rand(10) - 5));
		}
	}
}

// --------------------------------------------------------------------------------
// Implements goo eggs using enhanced base script
class scpGooEgg extends scpBaseEgg {
	function podOpen() {
		base.podOpen();
		Object.Teleport(Object.Create("Egg Goo Emitter"), vector(0, 0, 1), vector(), self);
		Object.Teleport(Object.Create("EggGooCloud"), vector(), vector(), self);
	}
}

// --------------------------------------------------------------------------------
// Implements swarmer eggs using enhanced base script
class scpSwarmerEgg extends scpBaseEgg {
	function podOpen() {
		base.podOpen();
		Object.Teleport(Object.Create("Swarm"), vector(), vector(), self);
	}

	function OnSlain() {
		emitOrgan("Swarm Organ");
	}
}

// --------------------------------------------------------------------------------
// Implements grub eggs using enhanced base script
// TODO: emit grubs from egg opening
class scpGrubEgg extends scpBaseEgg {
	function podOpen() {
		base.podOpen();
		Object.Teleport(Object.Create("Grub"), vector(), vector(), self);
	}

	function OnSlain() {
		emitOrgan("Grub Organ");
	}
}

// --------------------------------------------------------------------------------
// Enhanced swarm script. Supports freezing swarms with stasis field generator
// (area shots only). Requires swarm have a receptron somewhere that performs
// Stasis stim->Send to Scripts. This doesn't pause the swarm's death timer while
// in stasis, but they have such a short lifespan it hardly matters.
class scpSwarm extends SqRootScript {
	function OnBeginScript() {
		if (Object.Exists(self) && !Networking.IsProxy(self)) {
			SetOneShotTimer("SlaySwarm", 20);
		}
	}

	function OnStasisStimulus() {
		if (!GetData("frozen")) {
			createFX();
			// swarm AI doesn't implement Freeze script service, so have to do all this manually
			SetProperty("AI_MoveSpeed", 0); // freeze in place
			SetProperty("AI_TurnRate", 0); // prevent turning to face player
			SetProperty("arSrcScale", 0); // neutralize damage stims
			// mute sound
			local rad = GetProperty("AmbientHacked", "Radius");
			if (rad > 0) {
				SetData("AmbRad", rad);
				SetProperty("AmbientHacked", "Radius", 0);
			}
		}
		SetData("frozen", true);
		if (IsDataSet("StasisTimer")) {
			KillTimer(GetData("StasisTimer"));
		}
		SetData("StasisTimer", SetOneShotTimer("StasisTimer", message().intensity));
	}

	function OnTimer() {
		if (!Object.Exists(self)) {
			return;
		}
		local msg = message().name;
		if (msg == "SlaySwarm") {
			// no dying while in stasis
			if (GetData("frozen")) {
				SetData("Dead", true);
			}
			else {
				destroyFX();
				Damage.Slay(self, 0);
			}
		}
		else if (msg == "StasisTimer") {
			SetData("frozen", false);
			Property.Remove(self, "AI_MoveSpeed");
			Property.Remove(self, "AI_TurnRate");
			SetProperty("arSrcScale", 1);
			destroyFX();
			if (IsDataSet("AmbRad")) {
				SetProperty("AmbientHacked", "Radius", GetData("AmbRad"));
			}
			if (IsDataSet("Dead")) {
				Damage.Slay(self, 0);
			}
		}
	}

	function createFX() {
		local obj = Object.Create("EM Stasis Field");
		Link.Create("ParticleAttachement", obj, self);
	}

	function destroyFX() {
		local lnk;
		if (Link.AnyExist("~ParticleAttachement", self, 0)) {
			foreach (lnk in Link.GetAll("~ParticleAttachement", self, 0)) {
				Link.Destroy(lnk);
			}
		}
	}
}

// --------------------------------------------------------------------------------
// Respawns worm piles after a few minutes
class scpWormGooCorpse extends SqRootScript {
	function OnBeginScript() {
		if (!Object.Exists(self)) {
			return;
		}
		// account for player leaving/returning to level
		if (IsDataSet("DeathTime") && !Networking.IsProxy(self)) {
			local d = GetData("DeathTime");
			local t = ShockGame.SimTime();
			if (t > (d + WORM_PILE_RESPAWN_TIME * 1000)) {
				KillTimer(GetData("RespawnTimer"));
				// delay so other objects in level can initialize
				PostMessage(self, "Respawned");
			}
			//print((floor((d + WORM_PILE_RESPAWN_TIME * 1000) - t) / 1000) + " seconds until respawn");
		}
	}

	function OnCreate() {
		if (!Networking.IsProxy(self)) {
			SetData("DeathTime", ShockGame.SimTime());
			SetData("RespawnTimer", SetOneShotTimer("respawn", WORM_PILE_RESPAWN_TIME));
		}
	}

	function OnTimer() {
		if (message().name == "respawn") {
			respawn(true);
		}
	}

	function OnRespawned() {
		respawn(false);
	}

	function respawn(fade) {
		local obj = Object.BeginCreate("WormGoo");
		Object.Teleport(obj, vector(), vector(), self);
		// only bother with fade-in effect if player is around to see it
		if (fade && scp.DistanceSq(Object.Position(self), Object.Position("Player")) < 3000) {
			Property.SetSimple(obj, "RenderAlpha", 0);
			Property.SetSimple(obj, "Scale", vector(0.75, 0.75, 1));
			PostMessage(obj, "Fade");
		}
		Object.EndCreate(obj);
		Object.Destroy(self);
	}
}

// --------------------------------------------------------------------------------
// Fade in respawned worm piles
class scpWormGooHelper extends SqRootScript {
	function OnBeginScript() {
		if (Object.Exists(self) && GetData("fading")) {
			// assume that initial fade, if any, was interrupted
			killFade();
		}
	}

	function OnFade() {
		SetData("fading", true);
		SetOneShotTimer("fade", 0.1);
	}

	function OnTimer() {
		local per, scale;
		if (message().name == "fade" && GetData("fading")) {
			per = GetProperty("RenderAlpha");
			per = scp.Clamp(per + 0.04, 0, 1);
			if (per < 1) {
				scale = per / 4 + 0.75;
				SetProperty("RenderAlpha", per);
				SetProperty("Scale", vector(scale, scale, 1));
				SetOneShotTimer("fade", 0.03);
			}
			else {
				killFade();
			}
		}
	}

	function killFade() {
		SetData("fading", false);
		Property.Remove(self, "RenderAlpha");
		Property.Remove(self, "Scale");
	}
}

// --------------------------------------------------------------------------------
// Enhanced apparition script
// Teleports AI to ApparStart link dest (if available), fades in with dynamic
// light, and plays its object schema. On end, fades AI out.
// AI should start with Has Refs: FALSE.
//
// Messages accepted:
//    ApparBegin - initiates apparition fade-in and audio playback
//       - Sound/Object Sound
//       - Schema/Class Tags: creaturetype apparition, statechange event
//    ApparEnd - initiates apparition fade-out
//    ApparFinalEnd - sent to self on completion of fade-out
//
// Messages sent:
//    ApparFinalEnd - when apparition has finished fading out
//
class scpApparition extends SqRootScript {
	static MaxAlpha = 0.5;
	static FadeInTime = 2;
	static FadeOutTime = 1.5;
	static FadeInt = 0.05;
	static FlickInt = 0.1;

	function OnApparBegin() {
		// teleport to ApparStart link dest, if available
		local link = Link.GetOne("ApparStart", self);
		if (link) {
			Object.Teleport(self, Object.Position(sLink(link).To()), Object.Facing(sLink(link).To()));
		}
		// add world ref and initiate fade-in
		SetProperty("RenderAlpha", 0);
		SetProperty("HasRefs", true);
		SetData("Alpha", 0);
		SetOneShotTimer("ApparIn", 0);
		// play apparition sound
		Sound.PlaySchemaAmbient(self, GetProperty("ObjSoundName"));
		Sound.PlayEnvSchemaNet(self, "Event StateChange, LoopState Loop", self);
	}

	// initiate fade-out
	function OnApparEnd() {
		if (IsDataSet("Timer")) {
			KillTimer(GetData("Timer"));
		}
		SetOneShotTimer("ApparOut", 0.0);
		Sound.HaltSchema(self);
	}

	// sequence done and faded out, remove world ref
	function OnApparFinalEnd() {
		SetProperty("HasRefs", false);
	}

	function OnTimer() {
		local msg = message().name;
		if (msg == "ApparOut") {
			// fade-out
			local skipFlick = GetData("SkipFlick");
			SetData("SkipFlick", !skipFlick);
			local alpha = GetData("Alpha");
			if (alpha > 0.0) {
				alpha -= MaxAlpha / (FadeOutTime / FadeInt);
				if (alpha < 0.0) {
					alpha = 0.0;
				}
				SetData("Alpha", alpha);
				// flicker at same rate as when not fading
				// this ony works because fading is at double the update rate as not fading
				if (skipFlick) {
					alpha = Flicker(alpha);
				}
				Property.SetSimple(self, "RenderAlpha", alpha);
				Property.SetSimple(self, "SelfLit", alpha / MaxAlpha * 100.0);
				Property.SetSimple(self, "SelfLitRad", alpha / MaxAlpha * 5.0 + 5.0);
				SetOneShotTimer("ApparOut", FadeInt);
			}
			else {
				// done fading out
				SendMessage(self, "ApparFinalEnd");
			}
		}
		else if (msg == "ApparIn") {
			// fade-in
			local skipFlick = GetData("SkipFlick");
			SetData("SkipFlick", !skipFlick);
			local alpha = GetData("Alpha");
			if (alpha < MaxAlpha) {
				alpha += MaxAlpha / (FadeInTime / FadeInt);
				if (alpha > MaxAlpha) {
					alpha = MaxAlpha;
				}
				SetData("Alpha", alpha);
				if (skipFlick) {
					alpha = Flicker(alpha);
				}
				Property.SetSimple(self, "RenderAlpha", alpha);
				Property.SetSimple(self, "SelfLit", alpha / MaxAlpha * 100.0);
				SetOneShotTimer("ApparIn", FadeInt);
			}
			else {
				// done fading in
				SetData("Timer", SetOneShotTimer("ApparFlick", FlickInt));
			}
		}
		else if (msg == "ApparFlick") {
			// flicker
			local alpha = Flicker(MaxAlpha);
			Property.SetSimple(self, "RenderAlpha", alpha);
			Property.SetSimple(self, "SelfLit", alpha / MaxAlpha * 100.0);
			SetData("Timer", SetOneShotTimer("ApparFlick", FlickInt));
		}
	}

	// add or subtract a random amount from passed alpha
	function Flicker(alpha) {
		local flickAdj = 0.1 * alpha / MaxAlpha;
		return alpha + scp.Rand(flickAdj) - (flickAdj / 2.0);
	}
}


// ================================================================================
//  DEVICE SCRIPTS
// ================================================================================

// --------------------------------------------------------------------------------
// Replacement for elevator door orange button (-3519) TweqDepressable script that
// implements smoother animation
class scpTweqElevButt extends SqRootScript {
	static models = ["eleor", "eleor1", "eleor2", "eleor3", "eleor4", "eleor5", "eleor6", "eleor7", "eleor8", "eleor9", "eleoron"];
	static frames = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, -1];
	static centerFrame = 11;

	function OnFrobWorldEnd() {
		if (IsDataSet("AnimTimer")) {
			KillTimer(GetData("AnimTimer"));
		}
		if (GetData("AnimFrame")) {
			// make button animate correctly when pushed while it's bouncing back out
			local curFrame = GetData("AnimFrame");
			if (curFrame >= centerFrame) {
				SetData("AnimFrame", centerFrame - (curFrame - centerFrame));
			}
		}
		else {
			SetData("AnimFrame", 0);
		}
		SetData("AnimTimer", SetOneShotTimer("Anim", 0));
	}
	
	function OnTimer() {
		if (message().name != "Anim") {
			return;
		}
		local curFrame = GetData("AnimFrame");
		SetProperty("ModelName", models[frames[curFrame]]);	
		if (frames[curFrame + 1] == -1) {
			SetData("AnimFrame", 0);
		}
		else {
			SetData("AnimFrame", curFrame + 1);
			SetData("AnimTimer", SetOneShotTimer("Anim", 0.017));
		}
	}
}

// --------------------------------------------------------------------------------
// Elevator door helper
//
// Prevents elevator doors from closing on player by re-opening them if player gets
// close while they're closing. Prevents elevator doors from closing on player
// while standing between doors. Closes doors when elevator control panel frobbed.
//
// Setup:
// - Create Elevator Tripwire (-4666) spanning elevator doors, phydims 5x5x5, floored.
// - Add scpDoor script to elevator doors. Check do not inherit.
// - Link tripwire to elevator doors.
// - Link elevator control panel to tripwire.
// - Add scpElevatorPanel script to control panel.
class scpElevatorHelper extends SqRootScript {
	function OnBeginScript() {
		if (Object.Exists(self)) {
			Physics.SubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
		}
	}

	function OnEndScript() {
		Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
	}

	// when player enters trigger area, force doors back open if they're not completely closed
	function OnPhysEnter() {
		local status;
		local msg = message();
		if (!Networking.IsPlayer(message().transObj) || !newPhysEvent(msg)) {
			return;
		}
		// if any doors not closed, open all and cancel auto-close timer
		foreach (door in Link.GetAll("SwitchLink", self)) {
			status = Door.GetDoorState(LinkDest(door));
			if (status == eDoorStatus.kDoorOpen || status == eDoorStatus.kDoorOpening || status == eDoorStatus.kDoorClosing) {
				Link.BroadcastOnAllLinks(self, "OpenNow", "SwitchLink");
				break;
			}
		}
	}

	// when player leaves trigger area, re/start door close countdown
	function OnPhysExit() {
		local msg = message();
		if (!Networking.IsPlayer(message().transObj) || !newPhysEvent(msg)) {
			return;
		}
		Link.BroadcastOnAllLinks(self, "TurnOff", "SwitchLink");
	}

	// when elevator control panel frobbed, close all doors
	function OnFrobPanel() {
		Link.BroadcastOnAllLinks(self, "CloseNow", "SwitchLink");
	}

	// when closing door collides with player, open all doors
	function OnDoorHit() {
		if (Door.GetDoorState(message().from) == eDoorStatus.kDoorClosing) {
			Link.BroadcastOnAllLinks(self, "OpenNow", "SwitchLink");
		}
	}

	// ensure physics enter/exit event is unique
	function newPhysEvent(msg) {
		if (msg.message == GetData("LastMsg") && msg.transObj == GetData("LastObj")) {
			return false;
		}
		else {
			SetData("LastMsg", msg.message);
			SetData("LastObj", msg.transObj);
			return true;
		}
	}
}

// --------------------------------------------------------------------------------
// Relays panel frob message to elevator doors controller
class scpElevatorPanel extends SqRootScript {
	function OnFrobWorldEnd() {
		Link.BroadcastOnAllLinks(self, "FrobPanel", "SwitchLink");
	}
}

// --------------------------------------------------------------------------------
// Enhanced StdDoor script
//
// Control messages:
//   TurnOn - open door, start auto close timer (if non-zero)
//   TurnOff - close door after DoorTimer delay (if non-zero)
//   OpenNow - open door ignoring any auto close timer
//   CloseNow - close door ignoring any door timer delay
//   OpenFast - silently open door instantly
//   CloseFast - silently close door instantly
//   HoldTheDoor - open door only if currently closing
// Config parameters:
//   Door/Door Timer Duration - seconds until door closes after TurnOn (default 0)
//   Editor/Design Note: DoorCloseDelay - seconds until door closes after TurnOff (default 3)
class scpDoor extends SqRootScript {

	// reusing this inapplicable property to save door's original speed (don't trust script data)
	static OrigSpeed = "ProtocolExpl";

	function OnBeginScript() {
		if (Object.Exists(self)) {
			Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
		}
	}

	function OnEndScript() {
		Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
	}

	// ----------------------------------------------------------------------
	// door control message handlers

	function OnTurnOn() {
		ClobberTimer();
		SetDoorNormal();
		SetCloseTimer();
		Door.OpenDoor(self);
	}

	function OnTurnOff() {
		ClobberTimer();
		SetDoorNormal();
		local DoorTimer = "DoorCloseDelay" in userparams() ? userparams().DoorCloseDelay : 3;
		if (DoorTimer != 0) {
			SetData("Timer", SetOneShotTimer("DoorClose", DoorTimer));
		}
		else {
			Door.CloseDoor(self);
		}
	}

	function OnOpenNow() {
		ClobberTimer();
		SetDoorNormal();
		Door.OpenDoor(self);
	}

	function OnCloseNow() {
		ClobberTimer();
		SetDoorNormal();
		Door.CloseDoor(self);
	}

	function OnCloseFast() {
		ClobberTimer();
		SetDoorFast();
		Door.CloseDoor(self);
	}

	function OnOpenFast() {
		ClobberTimer();
		SetDoorFast();
		Door.OpenDoor(self);
	}

	function OnHoldTheDoor() {
		if (Door.GetDoorState(self) == eDoorStatus.kDoorClosing) {
			ClobberTimer();
			Door.OpenDoor(self);
		}
	}

	function OnFrobWorldEnd() {
		ClobberTimer();
		SetDoorNormal();
		if (ShockGame.CheckLocked(self, true, message().Frobber)) {
			Door.ToggleDoor(self);
		}
	}

	// ----------------------------------------------------------------------
	// schema-related message handlers

	function OnDoorOpening() {
		if (!message().isProxy) {
			Link.BroadcastOnAllLinks(self, "TurnOn", "SwitchLink");
		}
		PlayStateSound();
	}

	function OnDoorClosing() {
		if (!message().isProxy) {
			Link.BroadcastOnAllLinks(self, "TurnOff", "SwitchLink");
		}
		PlayStateSound();
	}

	function OnDoorOpen() {
		Sound.HaltSchema(self, "", 0);
		PlayStateSound();
	}

	function OnDoorClose() {
		Sound.HaltSchema(self, "", 0);
		PlayStateSound();
	}

	// ----------------------------------------------------------------------
	// support functions

	function PlayStateSound() {
		if (!GetData("FastMode")) {
			Sound.PlayEnvSchemaNet(self, StateChangeTags(), self, 0, eEnvSoundLoc.kEnvSoundOnObj, eSoundNetwork.kSoundNoNetworkSpatial);
		}
	}

	function StateChangeTags() {
		local StateTags = ["Open", "Closed", "Opening", "Closing", "Halted"];
		local Status = message().ActionType;
		local OldStatus = message().PrevActionType;
		local retval = "Event StateChange, OpenState " + StateTags[Status] + ", OldOpenState " + StateTags[OldStatus];
		if (OldStatus != eDoorStatus.kDoorHalt && IsDataSet("PlayerFrob")) {
			retval += ", CreatureType Player";
		}
		if (Status != eDoorStatus.kDoorClosing && Status != eDoorStatus.kDoorOpening) {
			ClearData("PlayerFrob");
		}
		return retval;
	}

	function OnPhysCollision() {
		Link.BroadcastOnAllLinks(self, "DoorHit", "~SwitchLink");
	}

	function OnTimer() {
		if (message().name == "DoorClose") {
			Door.CloseDoor(self);
		}
	}

	function ClobberTimer() {
		if (IsDataSet("Timer")) {
			KillTimer(GetData("Timer"));
		}
	}

	function SetCloseTimer() {
		local iStayOpenTime = GetProperty("DoorTimer");
		if (iStayOpenTime != 0) {
			ClobberTimer();
			SetData("Timer", SetOneShotTimer("DoorClose", iStayOpenTime));
		}
	}

	function SetDoorNormal() {
		// nothing to reset
		if (!HasProperty(OrigSpeed)) {
			return;
		}
		// reset normal speed
		SetData("FastMode", false);
		if (HasProperty("TransDoor")) {
			SetProperty("TransDoor", "Base Speed", GetProperty(OrigSpeed));
		}
		else if (HasProperty("RotDoor")) {
			SetProperty("RotDoor", "Base Speed", GetProperty(OrigSpeed));
		}
	}

	function SetDoorFast() {
		// ensure original speed is saved
		if (!HasProperty(OrigSpeed)) {
			if (HasProperty("TransDoor")) {
				SetProperty(OrigSpeed, GetProperty("TransDoor", "Base Speed"));
			}
			else if (HasProperty("RotDoor")) {
				SetProperty(OrigSpeed, GetProperty("RotDoor", "Base Speed"));
			}
		}
		// set high speed
		SetData("FastMode", true);
		if (HasProperty("TransDoor")) {
			SetProperty("TransDoor", "Base Speed", 9999);
		}
		else if (HasProperty("RotDoor")) {
			SetProperty("RotDoor", "Base Speed", 9999);
		}
	}
}

// --------------------------------------------------------------------------------
// Enhanced HealingStation script
// - Removes toxins.
// - Removes radiation (and toxins) when player at full health.
// - Displays message when player doesn't need any healing.
// - Doesn't deduct nanites from player if they don't have enough to pay.
// When using this remove NVDetoxTrap from player object.
class scpHealingStation extends SqRootScript {
	static healCost = 5; // possibly make this based on difficulty
	function OnFrobWorldEnd() {
		local Frobber = message().Frobber;
		local hp = Property.Get(Frobber, "HitPoints");
		local hpMax = Property.Get(Frobber, "MAX_HP");
		if (hpMax > hp || Property.Get(Frobber, "RadLevel") > 0 || Property.Get(Frobber, "Toxin") > 0 || Object.HasMetaProperty(Frobber, "Drunk")) {
			if (scp.PlayerNanites() >= healCost && ShockGame.PayNanites(healCost) == S_OK) {
				// restore HP
				PostMessage(Frobber, "FullHeal");
				// remove radiation
				Property.SetSimple(Frobber, "RadLevel", 0);
				ShockGame.OverlayChange(kOverlayRadiation, kOverlayModeOff);
				// remove toxins
				Property.SetSimple(Frobber, "Toxin", 0);
				ShockGame.OverlayChange(kOverlayPoison, kOverlayModeOff);
				// notify healing complete
				scp.AddText("MedBedUse", "misc", "", healCost);
				Sound.PlayEnvSchema(self, "Event Activate", self, 0, eEnvSoundLoc.kEnvSoundAtObjLoc);
			}
			else {
				scp.AddText("NeedNanites", "misc");
			}
		}
		else {
			scp.AddText("MedBedUnused", "misc", "Patient already in good condition.");
		}
	}
}

// --------------------------------------------------------------------------------
// Adds success/failure sound effects to keypads.
// Adds ability to act as a lock (link door tripwire to keypad). Currently disabled.
// Adds optional locked message:
// - Use property Script/Locked Message
// - Add string to lockmsg.str
class scpKeypadHelper extends SqRootScript {
	function OnKeypadDone() {
		if (message().code == GetProperty("KeypadCode")) {
			SetData("Opened", true);
			playSuccess();
		}
		else {
			Sound.PlaySchemaAmbient(self, "no_invroom");
		}
	}

	function OnFrobWorldEnd() {
		if (!GetData("Opened")) {
			local lockMsg = Data.GetString("lockmsg", GetProperty("LockMsg"));
			if (lockMsg != "") {
				ShockGame.AddText(lockMsg, "Player");
			}
		}
		else {
			playSuccess();
		}
	}

	// disabled because this causes problems with some vanilla setups
	/*
	function OnTurnOn() {
		if (GetData("Opened")) {
			Link.BroadcastOnAllLinks(self, "TurnOn", "SwitchLink");
		}
	}

	function OnTurnOff() {
		if (GetData("Opened")) {
			Link.BroadcastOnAllLinks(self, "TurnOff", "SwitchLink");
		}
	}
	*/

	function OnReset() {
		ClearData("Opened");
	}

	function OnNetOpened() {
		SetData("Opened", true);
	}

	function OnHackSuccess() {
		SetData("Opened", true);
	}

	function OnICEPick () {
		ShockGame.OverlayChangeObj(kOverlayKeypad, kOverlayModeOff, self);
		ShockGame.OverlayChangeObj(kOverlayHRM, kOverlayModeOff, self);
	}

	function playSuccess() {
		Sound.PlaySchema(self, "use_cardslot");
	}
}

// --------------------------------------------------------------------------------
// Implements hack modifier when player has Replicator Expert
// Adds physics object to front slope of replicator to prevent objects sinking into it
class scpReplicatorHelper extends SqRootScript {
	function OnBeginScript() {
		if (Object.Exists(self) && !IsDataSet("BumpObj")) {
			// allow object to fully instantiate
			SetOneShotTimer("StartSpawn", 0.25);
		}
	}

	function OnTimer() {
		local mName = message().name;
		local obj, lnk;
		if (mName == "StartSpawn") {
			if (IsDataSet("BumpObj")) {
				// this shouldn't happen, but sometimes it does
				return;
			}
			obj = Object.Create("marker");
			lnk = Link.Create("~DetailAttachement", self, obj);
			LinkTools.LinkSetData(lnk, "rel pos", vector(0, -0.38, -3.6));
			LinkTools.LinkSetData(lnk, "rel rot", vector(45, 0, 0));
			SetData("BumpObj", obj);
			// allow object position to update
			SetOneShotTimer("FinishSpawn", 0.25);
		}
		else if (mName == "FinishSpawn") {
			// detail attachments can't have physics, and destroying the link also
			// destroys the object, so use its coordinates to create a new object
			obj = GetData("BumpObj");
			if (Object.Exists(obj)) {
				Object.Teleport(Object.Create("RepBumper"), vector(), vector(), obj);
				Object.Destroy(obj);
			}
		}
	}

	// Apply a 20% reduction to overall hack difficulty
	function OnFrobWorldEnd() {
		if (ShockGame.HasTrait("Player", eTrait.kTraitReplicator) && !IsDataSet("BonusApplied")) {
			SetProperty("HackDiff", "Success %", GetProperty("HackDiff", "Success %") + 20);
			SetData("BonusApplied", true);
		}
	}
}

// --------------------------------------------------------------------------------
// Notifies player object when an OS upgrade machine has been used, displays
// message for upgrade installed, removes HUD brackets, and prevents trainer from
// opening again.
class scpTraitHelper extends SqRootScript {
	function OnUsed() {
		Sound.PlaySchemaAmbient(self, "boot_sw");
		SetProperty("HUDSelect", false);
		SetData("Used", true);
		// delay because player traits property hasn't been updated yet
		PostMessage(self, "UsedFinish");
		// inform player that he has a new power
		PostMessage("Player", "TraitGained");
	}

	function OnUsedFinish() {
		// display upgrade installed
		local c, traitNum, traitDesc;
		local slot = 4;
		while (slot > 0) {
			traitNum = Property.Get("Player", "TraitsDesc", "Trait " + slot)
			if (traitNum > 0) {
				traitDesc = Data.GetString("traits", "Trait" + traitNum);
				c = traitDesc.find(":");
				if (c != null) {
					scp.AddText("TraitAdded", "misc", "%s OS upgrade installed.", traitDesc.slice(0, c));
				}
				break;
			}
			slot--;
		}
	}

	function OnTweqComplete() {
		// make machine not open anymore
		if (GetProperty("JointPos", "Joint 1") < 1 && GetData("Used") && !Networking.IsMultiplayer()) {
			SetProperty("CfgTweqJoints", "    rate-low-high", vector());
		}
	}
}

// --------------------------------------------------------------------------------
// Enhanced glass shattering effect
// (add to Breakable Windows in hierarchy, remove flinder links)
// For scripted window breakages, add a ScriptParams link from an object to the glass
// to simulate an explosion originating from that point.
class scpGlass extends SqRootScript {
	function OnSlain() {
		// sanity check
		local dims = GetProperty("PhysDims", "Size");
		if (dims == 0) {
			return;
		}
		
		// calculate number of shards
		local xDim = dims.x;
		local yDim = dims.y;
		local zDim = dims.z;
		local numShards;
		// only consider major dimensions, not thickness
		if (xDim < yDim && xDim < zDim) {
			numShards = yDim * zDim;
		}
		else if (yDim < xDim && yDim < zDim) {
			numShards = xDim * zDim;
		}
		else {
			numShards = xDim * yDim;
		}
		numShards = (numShards / 2).tointeger();
		// ensure some shards even from tiny objects
		if (numShards < 2) {
			numShards = 2;
		}
		
		// calculate safe bounds
		xDim = dims.x > 0.5 ? dims.x - 0.5 : 0.5;
		yDim = dims.y > 0.5 ? dims.y - 0.5 : 0.5;
		zDim = dims.z > 0.5 ? dims.z - 0.5 : 0.5;

		// build point list
		local i;
		local points = [];
		for (i = 0; i < numShards; i++) {
			points.push(vector(scp.Rand(xDim) - xDim / 2 + 0.25, scp.Rand(yDim) - yDim / 2 + 0.25, scp.Rand(zDim) - zDim / 2 + 0.25));
		}

		// set up 3D rotation matrix
		// https://stackoverflow.com/questions/34050929/3d-point-rotation-algorithm
		local face = Object.Facing(self);
		local deg2rad = PI / 180;
		local heading = face.z * deg2rad;
		local pitch = face.y * deg2rad;
		local bank = face.x * deg2rad;
		local cosa = cos(heading);
		local sina = sin(heading);
		local cosb = cos(pitch);
		local sinb = sin(pitch);
		local cosc = cos(bank);
		local sinc = sin(bank);
		local Axx = cosa * cosb;
		local Axy = cosa * sinb * sinc - sina * cosc;
		local Axz = cosa * sinb * cosc + sina * sinc;
		local Ayx = sina * cosb;
		local Ayy = sina * sinb * sinc + cosa * cosc;
		local Ayz = sina * sinb * cosc - cosa * sinc;
		local Azx = -sinb;
		local Azy = cosb * sinc;
		local Azz = cosb * cosc;

		// spawn shards from point list
		local px, py, pz, point, shardPos, wielder, dist, power, shard;
		local pushVel = vector();
		local randVel = vector();
		local culVel = vector();
		local culPos = vector();
		local selfPos = vector();
		local culHasVel = false;
		local culIsBlast = false;
		local culIsMelee = false;
		local culprit = message().culprit;

		// determine culprit
		if (culprit > 0) {
			culPos = Object.Position(culprit);
			culIsBlast = Object.InheritsFrom(culprit, "Explosions");
			Physics.GetVelocity(culprit, culVel);
			culHasVel = culVel.x != 0 || culVel.y != 0 || culVel.z != 0;
			if (!culHasVel) {
				if (Property.Possessed(culprit, "Melee Type")) {
					culIsMelee = true;
					selfPos = Object.Position(self);
					//wielder = LinkDest(Link.GetOne("~CulpableFor", culprit));
					//Physics.GetVelocity(wielder, culVel);
				}
			}
		}
		// scripted fake explosion culprit
		if (!culIsMelee && !culIsBlast && !culHasVel && Link.AnyExist("~ScriptParams", self)) {
			culIsBlast = true;
			culprit = LinkDest(Link.GetOne("~ScriptParams", self));
			culPos = Object.Position(culprit);
		}
		local windowPos = Object.Position(self);
		local shardObjects = ["glass1", "glass2", "glass3", "glass4"];
		local culExists = culHasVel || culIsBlast || culIsMelee;

		local shardCount = 0;
		foreach (point in points) {
			// rotate points to match window orientation
			px = point.x;
			py = point.y;
			pz = point.z;
			shardPos = vector(Axx * px + Axy * py + Axz * pz, Ayx * px + Ayy * py + Ayz * pz, Azx * px + Azy * py + Azz * pz) + windowPos;
			// create shard
			shard = Object.BeginCreate(shardObjects[floor(scp.Rand(4))]);
			if (culExists) {
				dist = scp.DistanceSq(culPos, shardPos);
				if (culIsMelee) {
					// push away from player position
					// TODO add player forward velocity
					pushVel = -(culPos - selfPos).GetNormalized() * 3;
				}
				else if (culIsBlast) {
					// push away from center of explosion, modulated by distance
					power = (dist > 160 ? 1.0 : 160 - dist) / 6;
					pushVel = -(culPos - shardPos).GetNormalized() * power;
				}
				else if (culHasVel) {
					// push in direction projectile was moving, modulated by distance from point of impact
					power = dist > 20 ? 0.0 : 20 - dist;
					pushVel = culVel.GetNormalized() * power + 1;
				}
				// some low-level scatter
				randVel = vector(scp.Rand(4) - 2, scp.Rand(4) - 2, scp.Rand(1) - 0.5);
				// combine forces and apply
				Property.Set(shard, "PhysState", "Velocity", pushVel + randVel);
			}
			else {
				// generic scatter
				Property.Set(shard, "PhysState", "Velocity", vector(scp.Rand(10) - 5, scp.Rand(10) - 5, scp.Rand(2) - 1));
			}
			// cap sound channels used
			if (shardCount++ > 5) {
				Property.Set(shard, "Material Tags", "1: Tags", "Material none");
			}
			// spawn with random size, spin, and orientation
			Property.SetSimple(shard, "Scale", vector(scp.Rand(0.6) + 0.2, scp.Rand(0.6) + 0.2, 1));
			Property.Set(shard, "PhysState", "Rot Velocity", vector(scp.Rand(10) - 5, scp.Rand(10) - 5, scp.Rand(10) - 5));
			Physics.SetGravity(shard, 0.85); // fall a little more dramatically
			Object.Teleport(shard, shardPos, vector(scp.Rand(360), scp.Rand(360), scp.Rand(360)));
			Object.EndCreate(shard);
			// make sure it ended up in-world
			if (!Physics.ValidPos(shard)) {
				Object.Destroy(shard);
			}
		}
	}
}

// --------------------------------------------------------------------------------
// Plays ladder step sound when attaching to a ladder
// (place script on Ladder archetype)
class scpLadderHelper extends SqRootScript {
	function OnBeginScript() {
		if (GetProperty("PhysType", "Type") == 0 && GetProperty("PhysAttr", "Climbable Sides") != 0) {
			Physics.SubscribeMsg(self, ePhysScriptMsgType.kContactMsg);
		}
	}

	function OnEndScript() {
		Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kContactMsg);
	}

	function OnPhysContactCreate() {
		if (message().contactObj == ObjID("Player")) {
			PostMessage(self, "CheckClimbing");
		}
	}

	function OnCheckClimbing() {
		local plrObj = ObjID("Player");
		local climbObj = object();
		Physics.GetClimbingObject(plrObj, climbObj);
		if (climbObj.tointeger() == self.tointeger()) {
			Sound.PlayEnvSchema(self, "Event Climbstep", plrObj, self, eEnvSoundLoc.kEnvSoundAtObjLoc);
		}
	}
}

// --------------------------------------------------------------------------------
// Makes QBR scanner pads no longer highlight after use
class scpResurrectMachineHelper extends SqRootScript {
	function OnFrobWorldEnd() {
		SetProperty("HUDSelect", false);
	}
}

// --------------------------------------------------------------------------------
// Sets self-illumination on model in sync with random/random but coherent anim light modes.
// Model illumination scaled to anim light max brightness by default.
// Max brightness can be overridden by lightMaxNominal in the Design Note for a dimmer light.
class scpLightHelper extends SqRootScript {
	function OnBeginScript() {
		Light.Subscribe(self);
		SetData("LightMax", "lightMaxNominal" in userparams() ? userparams().lightMaxNominal : GetProperty("AnimLight", "max brightness"));
	}

	function OnEndScript() {
		Light.Unsubscribe(self);
	}

	function OnLightChange() {
		SetProperty("SelfIllum", message().data / GetData("LightMax"));
	}
}


// ================================================================================
//  WEAPON MODIFY SCRIPTS
// ================================================================================

// --------------------------------------------------------------------------------
// Enhanced RootModify script. Implements Tinker support.
class scpRootModify extends SqRootScript {
	function modStart() {
		// for future use
	}

	// Add to a gun property
	// Accepts property, subproperty, addend, Tinker attenuation (optional)
	function addSetting(arg1, arg2, arg3, atten = 1) {
		addSettingNum(0, arg1, arg2, arg3, atten);
		addSettingNum(1, arg1, arg2, arg3, atten);
	}

	function addSettingNum(arg0, arg1, arg2, arg3, atten) {
		arg1 = arg1 == "" ? "BaseGunDesc" : arg1;
		local setting = "Setting " + arg0 + ": " + arg2;
		local val = GetProperty(arg1, setting).tofloat();
		local valNew = val + tinker(arg3, atten);
		setProp(arg1, setting, valNew);
		dprint(setting + ": " + val + " + "  + arg3 + " = " + valNew);
	}

	// Multiply a gun property
	// Accepts property, subproperty, multiplier, Tinker attenuation (optional)
	function scaleSetting(arg1, arg2, arg3, atten = 1.0) {
		scaleSettingNum(0, arg1, arg2, arg3, atten);
		scaleSettingNum(1, arg1, arg2, arg3, atten);
	}

	function scaleSettingNum(arg0, arg1, arg2, arg3, atten) {
		arg1 = arg1 == "" ? "BaseGunDesc" : arg1;
		local setting = "Setting " + arg0 + ": " + arg2;
		local val = GetProperty(arg1, setting).tofloat();
		local valNew = val * tinker(arg3, atten);
		setProp(arg1, setting, valNew);
		dprint(setting + ": " + val + " * "  + arg3 + " = " + valNew);
	}

	// Divide a gun property
	// Accepts property, subproperty, divisor, Tinker attenuation (optional), minimum adjusted value (optional)
	function divideSetting(arg1, arg2, arg3, atten = 1.0, min = 0) {
		divideSettingNum(0, arg1, arg2, arg3, atten, min);
		divideSettingNum(1, arg1, arg2, arg3, atten, min);
	}

	function divideSettingNum(arg0, arg1, arg2, arg3, atten, min) {
		arg1 = arg1 == "" ? "BaseGunDesc" : arg1;
		local setting = "Setting " + arg0 + ": " + arg2;
		local val = GetProperty(arg1, setting).tofloat();
		if (val == 0 || arg3 == 0) {
			dprint(setting + ": DIVIDE BY ZERO");
			return;
		}
		local valNew = val / tinker(arg3, atten);
		// don't allow divided values to fall below minimum
		if (min != 0) {
			valNew = valNew < min ? min : valNew;
		}
		setProp(arg1, setting, valNew);
		dprint(setting + ": " + val + " / "  + arg3 + " = " + valNew);
	}

	function setProp(arg1, arg2, arg3) {
		if (typeof GetProperty(arg1, arg2) == "integer") {
			// when Dark converts a float to an int it truncates instead of rounding
			arg3 = scp.Round(arg3);
		}
		SetProperty(arg1, arg2, arg3);
	}

	function reduceKickback(arg) {
		dprint("Reducing kickback...");
		divideSetting("GunKick", "Kickback Pitch", arg);
		divideSetting("GunKick", "Kickback Heading", arg);
		divideSetting("GunKick", "Kickback", arg);
	}

	function reduceJolt(arg) {
		dprint("Reducing jolt...");
		divideSetting("GunKick", "Jolt Pitch", arg);
		divideSetting("GunKick", "Jolt Heading", arg);
		divideSetting("GunKick", "Jolt Back", arg);
	}

	// Apply Tinker modifier
	function tinker(val, atten = 1.0) {
		return tinkerOk() ? val * (1.0 + (0.2 * atten)) : val;
	}

	// Determine whether Tinker bonus can be applied.
	// Makes sure weapons with the scpModWeapon() script don't get player's Tinker bonus.
	function tinkerOk() {
		return ShockGame.HasTrait("Player", eTrait.kTraitTinker) && Link.AnyExist("~Contains", self, ObjID("Player"));
	}

	// debug print
	function dprint(txt) {
		if (MODIFY_DEBUG_ENABLE) {
			scp.Trace(txt + (tinkerOk() ? " (Tinker)" : ""));
		}
	}
}

// --------------------------------------------------------------------------------
class scpPistolModify extends scpRootModify {
	function OnModify1() {
		modStart();
		addSetting("", "Clip", 12);
		scaleSetting("", "Stim Mult", 1.1, 0.3);
	}
	function OnModify2() {
		modStart();
		divideSetting("", "Reload Time", 3);
		scaleSetting("", "Stim Mult", 1.14, 0.25);
	}
}

// --------------------------------------------------------------------------------
class scpShotgunModify extends scpRootModify {
	function OnModify1() {
		modStart();
		divideSetting("", "Reload Time", 3);
		scaleSetting("", "Stim Mult", 1.1, 0.3);
	}
	function OnModify2() {
		modStart();
		reduceKickback(3);
		reduceJolt(3);
		scaleSetting("", "Stim Mult", 1.14, 0.25);
	}
}

// --------------------------------------------------------------------------------
class scpRifleModify extends scpRootModify {
	function OnModify1() {
		modStart();
		divideSetting("", "Reload Time", 3);
		scaleSetting("", "Stim Mult", 1.1, 0.3);
	}
	function OnModify2() {
		modStart();
		addSetting("", "Clip", 36);
		scaleSetting("", "Stim Mult", 1.14, 0.25);
	}
}

// --------------------------------------------------------------------------------
class scpLaserModify extends scpRootModify {
	function OnModify1() {
		modStart();
		addSetting("", "Clip", 50); //vanilla code
		scaleSetting("", "Stim Mult", 1.1, 0.3);
	}
	function OnModify2() {
		modStart();
		//SetProperty("", "Setting 0: Ammo Usage", 2); //vanilla code
		//SetProperty("", "Setting 1: Ammo Usage", 14); //vanilla code
		divideSetting("", "Ammo Usage", 1.42857);
		scaleSetting("", "Stim Mult", 1.14, 0.25);
	}
}

// --------------------------------------------------------------------------------
class scpEMPModify extends scpRootModify {
	function OnModify1() {
		modStart();
		addSetting("", "Clip", 50);
		scaleSetting("", "Stim Mult", 1.1, 0.3);
	}
	function OnModify2() {
		modStart();
		scaleSetting("", "Speed Mult", 1.5);
		divideSetting("", "Ammo Usage", 2, 1);
		scaleSetting("", "Stim Mult", 1.14, 0.25);
	}
}

// --------------------------------------------------------------------------------
class scpGrenadeModify extends scpRootModify {
	function OnModify1() {
		modStart();
		addSetting("", "Clip", 3);
		//addSetting("", "Stim Mult", 1); //vanilla code
		scaleSetting("", "Stim Mult", 1.1, 0.3);
	}
	function OnModify2() {
		modStart();
		scaleSetting("", "Speed Mult", 1.5);
		divideSetting("", "Reload Time", 3);
		scaleSetting("", "Stim Mult", 1.14, 0.25);
	}
}

// --------------------------------------------------------------------------------
class scpStasisModify extends scpRootModify {
	function OnModify1() {
		modStart();
	    scaleSetting("", "Speed Mult", 2);
	}
	function OnModify2() {
		modStart();
		divideSetting("", "Ammo Usage", 2, 1);
	}
}

// --------------------------------------------------------------------------------
class scpFusionModify extends scpRootModify {
	function OnModify1() {
		modStart();
		addSetting("", "Clip", 40);
		scaleSetting("", "Stim Mult", 1.1, 0.3);
	}
	function OnModify2() {
		modStart();
		divideSetting("", "Ammo Usage", 2, 1);
		scaleSetting("", "Stim Mult", 1.14, 0.25);
	}
}

// --------------------------------------------------------------------------------
class scpViralModify extends scpRootModify {
	function OnModify1() {
		modStart();
		addSetting("", "Clip", 10);
		scaleSetting("", "Stim Mult", 1.1, 0.3);
	}
	function OnModify2() {
		modStart();
		divideSetting("", "Ammo Usage", 2, 1, 1);
		scaleSetting("", "Stim Mult", 1.14, 0.25);
	}
}

// --------------------------------------------------------------------------------
class scpAnnelidModify extends scpRootModify {
	function OnModify1() {
		modStart();
		addSetting("", "Clip", 10);
		scaleSetting("", "Stim Mult", 1.1, 0.3);
	}
	function OnModify2() {
		modStart();
		scaleSetting("", "Speed Mult", 2);
		scaleSetting("", "Stim Mult", 1.14, 0.25);
	}
}


// ================================================================================
//  ITEM SCRIPTS
// ================================================================================

// --------------------------------------------------------------------------------
// Merged WormHeartImplant/BaseImplant script. DO NOT use with BaseImplant!
// - Fixes implant breaking across map transitions.
// - Implements toxins building up with use, as implied by description.
// - Fixes Betty talking over herself when implant runs out of power.
// - Now only plays "heal" sound when healing performed.
class scpWormHeartImplant extends SqRootScript {
	static HealRate = 30;
	static ToxinPerHP = 0.1;
	static ToxinAccum = "ProtocolExpl";

	function OnBeginScript() {
		if (Object.Exists(self)) {
			Activate(false);
		}
	}

	function OnEndScript() {
		StopTimers();
	}

	// sent to implant when equipped
	function OnTurnOn() {
		Activate(true);
	}

	// sent to implant when unequipped
	function OnTurnOff() {
		Deactivate();
	}

	// attempt activation of implant; doesn't check "Active" status because we
	// might be resuming from a save; have to manually restart timers even
	// though save games preserve timers because we're killing the timers on
	// script end to keep things simple; skipEquipCheck is because the engine
	// sends TurnOn to implants before actually placing them in the inventory
	function Activate(skipEquipCheck) {
		// check activation requirements
		if (!(scp.IsEquipped(self) || skipEquipCheck) || GetProperty("Energy") <= 0) {
			return;
		}
		SetData("Active", true);
		SetData("Betty", false);
		StopTimers();
		StartDrainTimer();
		StartHealTimer();
	}

	// deactivate implant
	function Deactivate() {
		// prevent multiple deactivation
		if (!GetData("Active")) {
			return;
		}
		SetData("Active", false);
		StopTimers();
		// release the backwash
		local toxins = GetProperty(ToxinAccum);
		if (toxins > 4) {
			toxins = 4;
		}
		ActReact.Stimulate("Player", "Venom", toxins);
		SetProperty(ToxinAccum, 0);
		// check for deferred Betty
		if (GetData("Betty")) {
			SetData("Betty", false);
			SetData("BettyTimer", SetOneShotTimer("Betty", 1.5));
		}
	}

	// handle dragging implant onto charger
	function OnFrobToolEnd() {
		local DstObj = message().DstObjId;
		if (Object.InheritsFrom(DstObj, "Recharging Station")) {
			ShockGame.PreventSwap();
			PostMessage(self, "Recharge");
			Sound.PlayEnvSchema(DstObj, "Event Activate", DstObj, 0, eEnvSoundLoc.kEnvSoundAtObjLoc);
		}
	}

	// handle charging; ignores battery bug by always charging to max regardless of passed data
	function OnRecharge() {
		local oldEnergy = GetProperty("Energy");
		local newEnergy = Property.Get("Player", "BaseTechDesc", "Maintain") * 10 + 100;
		SetProperty("Energy", newEnergy);
		if (newEnergy > oldEnergy) {
			PostMessage(message().from, "Consume"); // recharge stations will ignore this
		}
		if (oldEnergy == 0) {
			Activate(false);
		}
	}

	function OnTimer() {
		local mName = message().name;
		if (mName == "DrainImp") {
			if (GetData("Active")) {
				local newEnergy = GetProperty("Energy") - GetProperty("DrainAmt");
				if (newEnergy < 0) {
					newEnergy = 0;
				}
				SetProperty("Energy", newEnergy);
				ShockGame.RefreshInv();
				if (newEnergy > 0) {
					StartDrainTimer();
				}
				else {
					// defer Betty if she'll be making a toxin annoucement
					if (GetProperty(ToxinAccum) && !Property.Get("Player", "Toxin")) {
						SetData("Betty", true);
					}
					else {
						Sound.PlaySchemaAmbient(self, "bb07"); //"Power drained"
					}
					Deactivate();
				}
			}
		}
		else if (mName == "WormHeal") {
			if (GetData("Active")) {
				if (Property.Get("Player", "HitPoints") < Property.Get("Player", "MAX_HP")) {
					ShockGame.HealObj("Player", 1);
					Sound.PlayEnvSchema(self, "Event Activate", 0, 0, eEnvSoundLoc.kEnvSoundAmbient);
					SetProperty(ToxinAccum, GetProperty(ToxinAccum) + ToxinPerHP);
				}
				StartHealTimer();
			}
		}
		else if (mName == "Betty") {
			Sound.PlaySchemaAmbient(self, "bb07");
		}
	}

	function StartDrainTimer() {
		SetData("Timer", SetOneShotTimer("DrainImp", GetProperty("DrainRate") || 10));
	}

	function StartHealTimer() {
		SetData("HealTimer", SetOneShotTimer("WormHeal", HealRate));
	}

	function StopTimers() {
		if (IsDataSet("Timer")) {
			KillTimer(GetData("Timer"));
		}
		if (IsDataSet("HealTimer")) {
			KillTimer(GetData("HealTimer"));
		}
		if (IsDataSet("BettyTimer")) {
			KillTimer(GetData("BettyTimer"));
		}
	}
}

// --------------------------------------------------------------------------------
// Replacement WormSkin armor script that fixes it breaking across map transitions.
// Adds support for setting drain rate via Obj/Energy/Drain Rate.
class scpWormSkin extends SqRootScript {
	function OnBeginScript() {
		if (Object.Exists(self) && scp.IsEquipped(self)) {
			StartTimer();
		}
	}

	function OnEndScript() {
		if (IsDataSet("Timer")) {
			KillTimer(GetData("Timer"));
		}
	}

	function OnTurnOn() {
		ShockGame.WearArmor(self);
		Property.Set("Player", "ArmrStatsDesc", "PSI", 2);
		ShockGame.RecalcStats("Player");
		StartTimer();
	}

	function OnTurnOff() {
		ShockGame.WearArmor(0);
		Property.Set("Player", "ArmrStatsDesc", "PSI", 0);
		ShockGame.RecalcStats("Player");
		KillTimer(GetData("Timer"));
	}

	function OnTimer() {
		if (message().name == "PsiDrain") {
			local psi = ShockGame.GetPlayerPsiPoints();
			if (psi) {
				ShockGame.SetPlayerPsiPoints(psi - 1);
			}
			else {
				ShockGame.HealObj("Player", -1);
			}
			StartTimer();
		}
	}

	function StartTimer() {
		SetData("Timer", SetOneShotTimer("PsiDrain", GetProperty("DrainRate") || 30));
	}
}

// --------------------------------------------------------------------------------
// Suspends research if uninstalling LabAssistant implant brings player's Research
// skill below minimum requirement.
class LabAssHelper extends SqRootScript {
	function OnTurnOff() {
		local lnk = Link.GetOne("Research", ObjID("Player"));
		if (lnk) {
			local obj = LinkDest(lnk);
			if (Property.Get("Player", "BaseTechDesc", "Research") < Property.Get(obj, "ReqTechDesc", "Research")) {
				Link.Destroy(lnk);
				scp.AddText("ResearchSus", "misc", "%s research suspended.", Data.GetObjString(obj, "ObjShort"));
				ShockGame.TechTool(obj);
			}
		}
	}
}

// --------------------------------------------------------------------------------
// Enhanced cheeseborger (diagnostic/repair module) script
// Fixes broken schema playing on use.
class scpCheeseborger extends SqRootScript {
	function OnFrobInvEnd() {
		if (ShockGame.HasTrait("Player", eTrait.kTraitBorg)) {
			ShockGame.HealObj(message().Frobber, 15);
			scp.Consume(self, "act_cheese");
		}
		else {
			Sound.PlaySchemaAmbient(self, "no_invroom");
		}
	}
}

// --------------------------------------------------------------------------------
// Enhanced GamePig cartridge script
// Requires adding Engine Features/FrobInfo: World Action: Move, Inv Action: Script, Tool Action: Script
// - Supports dropping cartridge on GamePig to install
// - Plays sound when cartridge installed
class scpMiniGameCart extends SqRootScript {
	function OnFrobInvEnd() {
		installCart();
	}

	function OnFrobToolEnd() {
		if (Object.InheritsFrom(message().DstObjId, "Gameboy")) {
			ShockGame.PreventSwap();
			installCart();
		}
	}

	function OnPirateGameCart() {
		Property.SetSimple("Player", "MiniGames", Property.Get("Player", "MiniGames") | message().data);
	}

	function installCart() {
		Property.SetSimple("Player", "MiniGames", Property.Get("Player", "MiniGames") | Property.Get(self, "MiniGames"));
		Networking.Broadcast(self, "PirateGameCart", true, GetProperty("MiniGames"));
		scp.Consume(self, "boot_sw");
		//TODO: display name of game added?
		scp.AddText("MFDGameCart", "misc", "MFD game cartridge installed.");
	}
}

// --------------------------------------------------------------------------------
// Enhanced FreeHack (ICE-Pick) script
// - Plays hack success sound when used.
// - Fixes ICE-Picks being thrown into world if player attempts to hack non-hackable object.
// - Send message to hacked object letting them know they were hacked by an ICE-Pick.
// - Prevents ICE-Picks being usable on destroyed objects.
// (does NOT set hacked status on crates, since that blocks removing items from them)
class scpFreeHack extends SqRootScript {
	function OnFrobToolEnd() {
		local hackObj = message().DstObjId;
		if (Property.Possessed(hackObj, "HackDiff") && Property.Get(hackObj, "HackDiff", "Success %") > -1000 && !(Property.Possessed(hackObj, "HitPoints") && Property.Get(hackObj, "HitPoints") < 1)) {
			ShockGame.PreventSwap();
			// check for already hacked/opened
			if ((Property.Get(hackObj, "ObjState") == eObjState.kObjStateHacked) || (Object.InheritsFrom(hackObj, "Hackable Crate") && Property.Get(hackObj, "ObjState") == eObjState.kObjStateNormal)) {
				scp.AddText("FreeHackHacked", "misc");
			}
			else {
				if (Property.Get(hackObj, "ObjState") != eObjState.kObjStateBroken) {
					Networking.SendToProxy("Player", hackObj, "HackSuccess", null);
					Networking.SendToProxy("Player", hackObj, "ICEPick", null);
					scp.AddText("FreeHack", "misc");
					scp.Consume(self, "hack_success");
					// hide hack plug overlay, except for crates, which for some reason messes them up
					if (!Object.InheritsFrom(hackObj, "Hackable Crate")) {
						ShockGame.OverlayChangeObj(kOverlayHRMPlug, kOverlayModeOff, self);
					}
				}
			}
		}
		else {
			// allow swap if used on inventory object
			if (!Link.GetOne("~Contains", hackObj)) {
				ShockGame.PreventSwap();
				scp.AddText("FreeHackCant", "misc");
			}
		}
	}

	function OnFrobInvEnd() {
		scp.AddText("HelpFreeHack", "misc");
	}
}

// --------------------------------------------------------------------------------
// Enhanced wrench (maintenance tool) script
// - Allows repairing turrets.
// - Allows swapping in inventory when used on non-repairable object.
class scpWrench extends SqRootScript {
	function OnFrobToolEnd() {
		local fixObj = message().DstObjId;
		local state, hp, maxHP;
		local playerMaintSkill = Property.Get("Player", "BaseTechDesc", "Maintain");
		local objSkillRequired = Property.Get(fixObj, "ReqTechDesc", "Maintain");
		// enforce a minimum skill level
		if (objSkillRequired == 0) {
			objSkillRequired = 1;
		}
		// guns
		if (ShockGame.ValidGun(fixObj)) {
			ShockGame.PreventSwap();
			state = Property.Get(fixObj, "ObjState");
			hp = Property.Get(fixObj, "GunState", "Condition (%)");
			if (state == eObjState.kObjStateUnresearched) {
				scp.AddText("WrenchUnresearched", "misc");
			}
			else if (state == eObjState.kObjStateBroken) {
				scp.AddText("WrenchOnBroken", "misc");
			}
			else if (playerMaintSkill < objSkillRequired) {
				scp.AddText("WrenchSkillReq", "misc", "", objSkillRequired);
			}
			else if (hp > 90) {
				scp.AddText("WrenchUnused", "misc");
			}
			else if (state == eObjState.kObjStateNormal) {
				// repair gun 10% per point of maint skill
				hp = scp.Clamp(hp + playerMaintSkill * 10.0, 0.0, 100.0);
				Property.Set(fixObj, "GunState", "Condition (%)", hp);
				scp.Consume(self, "*");
			}
		}
		// turrets
		else if (Object.InheritsFrom(fixObj, "Turrets")) {
			ShockGame.PreventSwap();
			hp = Property.Get(fixObj, "HitPoints");
			maxHP = Property.Get(fixObj, "MAX_HP");
			if (playerMaintSkill < objSkillRequired) {
				scp.AddText("WrenchSkillReqTur", "misc", "", objSkillRequired);
			}
			else if (hp >= maxHP) {
				scp.AddText("WrenchUnusedTur", "misc");
			}
			else {
				// repair turret 5 HP per point of maint skill (default turrets have a max HP of 48)
				hp = scp.Clamp(hp + playerMaintSkill * 5, 0, maxHP);
				Property.SetSimple(fixObj, "HitPoints", hp);
				scp.Consume(self, "*");
			}
		}
		// non-repairable, swap if inventory object
		else if (!Link.GetOne("~Contains", fixObj)) {
			ShockGame.PreventSwap();
			scp.AddText("WrenchOnNonGun", "misc");
		}
	}

	function OnFrobInvEnd() {
		scp.AddText("HelpWrench", "misc");
	}
}

// --------------------------------------------------------------------------------
// Enhanced CancerStick (cigarette) script
// - Reduces HP down to 1 instead of 0
// - Boosts PSI by 1 point
// - Strong Metabolism OS upgrade prevents HP loss
class scpCancerStick extends SqRootScript {
	function OnFrobInvEnd() {
		local frobber = message().Frobber;
		// increase psi
		ShockGame.SetPlayerPsiPoints(ShockGame.GetPlayerPsiPoints() + 1);
		// reduce health
		if (Property.Get(frobber, "HitPoints") >= 2 && !ShockGame.HasTrait(frobber, eTrait.kTraitMetabolism)) {
			ShockGame.HealObj(frobber, -1);
		}
		// TODO remove device from schema tags, plays schema directly
		scp.Consume(self, "*");
	}
}

// --------------------------------------------------------------------------------
// Enhanced Liquor script
// - Notifies player so drunk effects can be applied (if enabled)
// - Strong Metabolism OS upgrade prevents PSI loss and drunk effects
// - Reduces radiation poisoning by 1.5
class scpLiquor extends SqRootScript {
	function OnFrobInvEnd() {
		local frobber = message().Frobber;
		// heal
		ShockGame.HealObj(frobber, 1);
		// reduce psi and get drunk
		if (!ShockGame.HasTrait(frobber, eTrait.kTraitMetabolism)) {
			ShockGame.SetPlayerPsiPoints(ShockGame.GetPlayerPsiPoints() - 4);
			if (scp.IsModEnabled("modDrunk")) {
				PostMessage(frobber, "Liquor");
			}
		}
		// reduce rads
		local rads = Property.Get(frobber, "RadLevel");
		if (rads > 0) {
			rads = (rads - 1.5 < 0) ? 0 : rads - 1.5;
			Property.SetSimple(frobber, "RadLevel", rads);
		}
		scp.Consume(self, "*");
	}
}

// --------------------------------------------------------------------------------
// Applies one modify level to an unmodified weapon
class scpModWeapon extends SqRootScript {
	function OnBeginScript() {
		if (Object.Exists(self) && GetProperty("GunState", "Modification") == 0) {
			ShockGame.SetModify(self, 1);
		}
	}
}

// --------------------------------------------------------------------------------
// Enhanced healing item base script
// - Fixes healing items being usable when already at full health.
// - Fixes healing items being capped to player damage at moment item is used.
// - Fixes intended 20% healing rate boost with Pharmo Friendly.
// - Fixes Pharmo Friendly and Easy difficulty bonuses not being consistently applied.
// - Changes from increasing HP by a variable amount per 1.5-second tick, to 1 HP per
//   a variable tick.
class scpBaseHeal extends SqRootScript {
	function OnFrobInvEnd() {
		local itemHeal, healPool;
		local patient = message().Frobber;

		// abort if healing item is unresearched
		if (GetProperty("ObjState") != eObjState.kObjStateNormal) {
			return;
		}
		// abort if already at full HP
		if (Property.Get(patient, "HitPoints") == Property.Get(patient, "MAX_HP")) {
			scp.AddText("HPMaxed", "misc", "Hit points already at full.");
			return;
		}

		itemHeal = healPerItem();
		// 20% Pharmo Friendly bonus
		if (ShockGame.HasTrait(patient, eTrait.kTraitPharmo)) {
			itemHeal *= 1.2;
		}
		// 50% Easy difficulty bonus
		if (Quest.Get("Difficulty") == 1) {
			itemHeal *= 1.5;
		}

		healPool = (GetData("HealPool") || 0) + itemHeal;
		SetData("HealPool", healPool);
		SetData("Patient", patient);
		SetData("HealRush", healRush());

		Sound.PlayEnvSchema(self, "Event Activate", 0, 0, eEnvSoundLoc.kEnvSoundAmbient);
		Container.StackAdd(self, -1);
		if (GetProperty("StackCount") <= 0) {
			ShockGame.HideInvObj(self);
		}
		killTimer();
		SetData("HealTimer", SetOneShotTimer("DoHeal", 0.1));
	}

	function OnTimer() {
		if (message().name == "DoHeal") {
			doHeal(1);
		}
	}

	function OnEndScript() {
		killTimer();
		local healPool = GetData("HealPool") || 0;
		if (healPool > 0) {
			doHeal(healPool);
		}
	}

	function doHeal(amt) {
		local healPool = GetData("HealPool");
		local healRush = GetData("HealRush");
		local patient = GetData("Patient");
		ShockGame.HealObj(patient, amt);
		healPool -= amt;
		if (healPool > 0 && (Property.Get(patient, "HitPoints") < Property.Get(patient, "MAX_HP"))) {
			SetData("HealPool", healPool);
			SetData("HealTimer", SetOneShotTimer("DoHeal", (healRate() / healRush) * (ShockGame.HasTrait(patient, eTrait.kTraitPharmo) ? 0.8 : 1.0)));
			healRush *= 0.9;
			SetData("HealRush", healRush < 1 ? 1 : healRush);
		}
		else {
			SetData("HealPool", 0);
			if (GetProperty("StackCount") <= 0) {
				Object.Destroy(self);
			}
		}
	}

	function killTimer() {
		if (IsDataSet("HealTimer")) {
			KillTimer(GetData("HealTimer"));
		}
	}
}

/*
// for testing how long healing items take
// place on healing item; only use with single-item stacks
class scpTimeHeal extends SqRootScript {
	function OnFrobInvEnd() {
		SetData("HealStart", ShockGame.SimTime());
		SetOneShotTimer("TimeHeal", 0.1);
	}

	function OnTimer() {
		if (message().name == "TimeHeal") {
			print((ShockGame.SimTime() - GetData("HealStart")) / 1000.0);
			SetOneShotTimer("TimeHeal", 0.1);
		}
	}
}
*/

// --------------------------------------------------------------------------------
// Implements med hypos using enhanced base script
// (vanilla heals 2 per 1.5 tick)
class scpMedPatch extends scpBaseHeal {
	function healPerItem() {
		return 10;
	}

	function healRate() {
		return 0.75;
	}
	
	function healRush() {
		return 1.6;
	}
}

// --------------------------------------------------------------------------------
// Implements med kits using enhanced base script
// (vanilla heals 5 per 1.5 tick)
class scpMedKit extends scpBaseHeal {
	function healPerItem() {
		return 200;
	}

	function healRate() {
		return 0.3;
	}

	function healRush() {
		return 3.0;
	}
}

// --------------------------------------------------------------------------------
// Implements healing organs using enhanced base script
// (vanilla heals 1 per 1.5 tick)
class scpHealingGland extends scpBaseHeal {
	function healPerItem() {
		return 15;
	}

	function healRate() {
		return 1.5;
	}

	function healRush() {
		return 1.0;
	}
}

// --------------------------------------------------------------------------------
// Enhanced beaker script
// - Plays sound when collecting worms.
// - Supports being stacked.
class scpBeakerScript extends SqRootScript {
	function OnFrobToolEnd() {
		if (Object.InheritsFrom(message().DstObjId, "Worm Piles")) {
			local lnk = Link.GetOne("Mutate", ShockGame.GetArchetypeName(self) ,0);
			if (lnk) {
				scp.Consume(message().SrcObjId, "ft_og_flesh");
				ShockGame.AddInvObj(Object.Create(LinkDest(lnk)));
			}
		}
	}
}

// --------------------------------------------------------------------------------
// Displays notification if player attempts to use filled worm beaker to collect worms
class scpWormBeaker extends SqRootScript {
	function OnFrobToolEnd() {
		if (Object.InheritsFrom(message().DstObjId, "Worm Piles")) {
			scp.AddText("WormBeakerPile", "misc", "Only empty beakers can be used to collect worms.");
			ShockGame.PreventSwap();
		}
	}
}

// --------------------------------------------------------------------------------
// Enhanced bouncy prox grenade script
// - Fixes bouncy prox grenades not detonating on impact with AIs.
// - On falling asleep, replaces self with a contact prox grenade.
class scpProxGrenade extends SqRootScript {
	function OnBeginScript() {
		if (Object.Exists(self)) {
			Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
			Physics.SubscribeMsg(self, ePhysScriptMsgType.kFellAsleepMsg);
		}
	}

	function OnEndScript() {
		Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
		Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kFellAsleepMsg);
	}

	function OnPhysCollision() {
		if (message().collType == ePhysCollisionType.kCollObject && Property.Possessed(message().collObj, "AI")) {
			Damage.Slay(self, 0);
		}
	}

	function OnPhysFellAsleep() {
		Object.Teleport(Object.Create("Contacted Prox Grenade"), vector(), vector(), self);
		Object.Destroy(self);
	}
}

// --------------------------------------------------------------------------------
// Enhanced contact proximity grenade script
// - Fixes prox grenades not receiving any damage multipliers
//   (must have Propagate Source Scale set on corpse link)
// - Fixes trigger getting permanently left in map when grenade directly destroyed
// - Adds impact sound on initial creation
// - Adds beep when grenade triggered
// - Adds slight delay after triggering before grenade detonates
class scpContactProxGrenade extends SqRootScript {
	function OnBeginScript() {
		if (Object.Exists(self) && !Networking.IsProxy(self)) {
			PostMessage(self, "Init");
		}
	}

	function OnInit() {
		local lnk, obj, scale;
		Sound.PlaySchema(self, "hfabmet");
		// create tripwire
		obj = Object.Create("Prox Grenade Trigger");
		Object.Teleport(obj, vector(), vector(), self);
		Link.Create("ScriptParams", self, obj);

		// try to guess which weapon fired this grenade
		local gun = ShockGame.Equipped(ePlayerEquip.kEquipWeapon);
		if (!Object.InheritsFrom(gun, "Gren Launcher")) {
			// scan player inventory for grenade launcher with prox grenade ammo selected
			foreach (lnk in Link.GetAll("Contains", "Player")) {
				obj = LinkDest(lnk);
				if (Object.InheritsFrom(obj, "Gren Launcher") && (Link.AnyExist("Projectile", obj, "Prox Grenade Proj") || Link.AnyExist("Projectile", obj, "Bouncy Prox Grenade"))) {
					gun = obj;
				}
			}
		}
		if (gun) {
			// probably the launcher that launched us
			scale = Property.Get(gun, "BaseGunDesc", "Setting 0: Stim Mult");
		}
		else {
			// oh well, assume an unmodded grenade launcher
			scale = BASE_GRENADE_SCALE;
		}

		// apply skill and trait bonuses
		scale *= (1.0 + (Property.Get("Player", "BaseWeaponDesc", "Heavy") - Property.Get("Gren Launcher", "BaseWeaponDesc", "Heavy")) * 0.15);
		scale *= ShockGame.HasTrait("Player", eTrait.kTraitSharpshooter) ? 1.15 : 1.0;
		SetProperty("arSrcScale", scale);
	}

	function OnFrobWorldEnd() {
		killTimer();
		// simulate picking up a prox grenade
		local obj = Object.Create("Prox. Grenade");
		Property.SetSimple(obj, "StackCount", 1);
		ShockGame.AddInvObj(obj);
		Sound.PlaySchemaAmbient(self, "pickup_item");
		scp.AddText("PickupString", "misc.str", "", Data.GetObjString(obj, "objshort"));
		// destroy ourself
		Object.Destroy(LinkDest(Link.GetOne("ScriptParams", self, 0)));
		Object.Destroy(self);
	}

	function OnIncursion() {
		if (!IsDataSet("Tripped")) {
			SetData("Tripped", true);
			Sound.PlaySchema(self, "beep7");
			SetData("DetTimer", SetOneShotTimer("Detonate", 0.3));
		}
	}

	function OnTimer() {
		if (message().name == "Detonate") {
			Damage.Slay(self, 0);
		}
	}
	
	function OnSlain() {
		killTimer();
		Object.Destroy(LinkDest(Link.GetOne("ScriptParams", self, 0)));
	}
	
	function killTimer() {
		if (IsDataSet("DetTimer")) {
			KillTimer(GetData("DetTimer"));
		}
	}
}

// --------------------------------------------------------------------------------
// Enhanced proximity grenade trigger script
// - Changes trigger to notify parent of incursion instead of blowing itself up.
// - Adds detection of damage stims (requires adding Basic Vuln to archetype).
class scpProxGrenadeTrigger extends SqRootScript {
	function OnBeginScript() {
		if (Object.Exists(self)) {
			Physics.SubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
		}
	}

	function OnEndScript() {
		Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
	}

	function OnPhysEnter() {
		local transObj = message().transObj;
		if (Networking.IsPlayer(transObj) || Property.Possessed(transObj, "AI")) {
			reportIncursion();
		}
	}

	function OnDamage() {
		reportIncursion();
	}

	function reportIncursion() {
		if (!IsDataSet("Tripped")) {
			SetData("Tripped", true);
			PostMessage(LinkDest(Link.GetOne("~ScriptParams", self, 0)), "Incursion");
		}
	}
}

// ================================================================================
//  MAP-SPECIFIC SCRIPTS
// ================================================================================

// --------------------------------------------------------------------------------
// Destroy self on sim start; use to block player if Squirrel isn't loaded
class scpSelfDestruct extends SqRootScript {
	function OnSim() {
		Object.Destroy(self);
	}
}

// --------------------------------------------------------------------------------
// Re-enable text overlay after exiting training booth disables it
class scpEnableText extends SqRootScript {
	function OnTurnOn() {
		ShockGame.OverlayChangeObj(kOverlayText, kOverlayModeOn, null);
	}
}

// --------------------------------------------------------------------------------
// Flash the screen when player teleports. Used only on Earth.
class scpTeleportFlash extends SqRootScript {
	function OnTurnOn() {
		ShockGame.StartFadeIn(1000, 200, 0, 0)
		Object.Teleport(Object.Create("Citadel Teleport"), vector(), vector(), ObjID("Player"));
	}
}

// --------------------------------------------------------------------------------
// Minimal ecology for tech security training that doesn't play Xerxes barks and
// can be immediately silenced
class scpTrainerEcology extends SqRootScript {
	function OnAlarm() {
		if (GetProperty("EcoState") == 0) {
			SetProperty("EcoState", 2);
			AlarmOn();
		}
	}

	function OnReset() {
		if (GetProperty("EcoState") == 2) {
			Link.BroadcastOnAllLinks(self, "Reset", "SwitchLink");
			SetProperty("EcoState", 0);
			AlarmOff();
		}
	}

	function AlarmOn() {
		ShockGame.AddAlarm(GetProperty("Ecology", "Alert Recovery") * 1000);
		Sound.PlaySchemaAmbient(self, "klaxalarm");
	}
	
	function AlarmOff() {
		ShockGame.RemoveAlarm();
		Sound.HaltSchema(self);
		Sound.PlaySchemaAmbient(self, "alarmoff");
	}

	function ResetEcology() {
		Link.BroadcastOnAllLinks(self, "Reset", "SwitchLink");
		SetProperty("EcoState", 0);
		AlarmOff();
	}
}

// --------------------------------------------------------------------------------
// Stop tech training security camera from tracking player through walls
// (this is standard behavior, but it's not normally directly observable as in this training room)
class scpTechCamForget extends SqRootScript {
	function OnTurnOn() {
		local lnk = Link.GetOne("AIAttack", "TrainerCam");
		if (lnk) {
			Link.Destroy(lnk);
		}
	}
}

// --------------------------------------------------------------------------------
// Hide tech training security computer so it can't be frobbed through wall
class scpTechCompOff extends SqRootScript {
	function OnTurnOn() {
		Property.SetSimple("TrainerSec", "HasRefs", false);
	}
}

// --------------------------------------------------------------------------------
// Reveal tech training security computer
class scpTechCompOn extends SqRootScript {
	function OnTurnOn() {
		Property.SetSimple("TrainerSec", "HasRefs", true);
	}
}

// --------------------------------------------------------------------------------
// Cancel any active alarm or security hack from tech training
class scpTechExit extends SqRootScript {
	function OnTurnOn() {
		// must hide overlay first to prevent engine playing Xerxes bark
		ShockGame.OverlayChange(kOverlayHackIcon, kOverlayModeOff);
		Property.SetSimple("Player", "HackTime", 0);
		Property.SetSimple("Player", "HackVisi", 1);
		ShockGame.RecalcStats("Player");
		// silence all alarm-termination sounds
		PostMessage("TrainerEco", "Reset");
		SetOneShotTimer("SilenceEco", 0.01);
	}

	function OnTimer() {
		if (message().name == "SilenceEco") {
			Sound.HaltSchema("TrainerEco");
			Sound.HaltSchema("TrainerSec");
		}
	}
}

// --------------------------------------------------------------------------------
// Simulate station shuttle receding beyond visible range
class scpShuttleRecede extends SqRootScript {
	function OnMovingTerrainWaypoint() {
		local lnk;
		if (Object.GetName(message().waypoint) == "FinalDest") {
			foreach (lnk in Link.GetAll("~DetailAttachement", self, 0)) {
				PostMessage(LinkDest(lnk), "TurnOff"); //managed by NVParticleGroup
			}
			SetProperty("SelfIllum", false);
			SetOneShotTimer("Recede", 0.1);
		}
	}

	function OnTimer() {
		local msg = message().name;
		if (msg == "Recede") {
			local a = (GetProperty("Scale") || vector(1, 1, 1)).x;
			SetProperty("Scale", vector(a * 0.99, a * 0.99, a * 0.99));
			if (a > 0.15) {
				SetOneShotTimer("Recede", 0.1);
			}
			else {
				a = GetProperty("RenderAlpha") || 1.0;
				if (a > 0.01) {
					SetProperty("RenderAlpha", a * 0.9);
					SetOneShotTimer("Recede", 0.1);
				}
				else {
					Object.Destroy(self);
				}
			}
		}
	}
}

// --------------------------------------------------------------------------------
// Update screen for station career advice computer
class scpCareerComp extends SqRootScript {
	function OnTurnOn() {
		local models = ["unnsc_m1", "unnsc_m2", "unnsc_m3", "unnsc_n1", "unnsc_n2", "unnsc_n3", "unnsc_o1", "unnsc_o2", "unnsc_o3"];
		local index = Property.Get("Player", "Service") * 3 + Property.Get("Player", "CharGenYear");
		if (typeof index == "integer") {
			SetProperty("ModelName", models[index]);
		}
	}
}

// --------------------------------------------------------------------------------
// Forcibly activate mini automap overlay. Used only at the start of medsci1.
class scpMiniMapOn extends SqRootScript {
	function OnBeginScript() {
		if (!IsDataSet("Done")) {
			// delay modifying overlays since HUD isn't fully initialized yet
			SetOneShotTimer("ShowMap", 0.1);
		}
	}

	function OnTimer() {
		if (message().name == "ShowMap") {
			SetData("Done", true);
			ShockGame.OverlayChange(kOverlayMiniMap, kOverlayModeOn);
		}
	}
}

// --------------------------------------------------------------------------------
// Controls all effects and effects for medsci2 decontamination shower
// - Shower activates immediately, deactivates after a delay
// - Removes radiation incrementaly instead of all at once
class scpDeconShower extends SqRootScript {
	function OnBeginScript() {
		if (!IsDataSet("CurState")) {
			SetData("CurState", false);
		}
	}

	function OnTurnOn() {
		killTimers();
		reduceRads(message().data);
		controlThings(true);
	}

	function OnTurnOff() {
		killTimers();
		// delayed deactivation
		SetData("OffTimer", SetOneShotTimer("ShowerOff", 1.5));
	}

	function OnTimer() {
		local msg = message().name;
		local pgMsg;
		if (msg == "ShowerOff") {
			controlThings(false);
		}
		else if (msg == "CtrlMist") {
			pgMsg = message().data;
			PostMessage(ObjID("shower mist #1"), pgMsg);
			PostMessage(ObjID("shower mist #2"), pgMsg);
		}
		else if (msg == "RedRads") {
			reduceRads(message().data);
		}
	}

	function controlThings(state) {
		if (state == GetData("CurState")) {
			return;
		}
		SetData("CurState", state);
		// particle group control message
		local pgMsg = state ? "TurnOn" : "TurnOff";
		// must invert this because Irrational's script interprets TurnOn/TurnOff backwards
		local soundMsg = state ? "TurnOff" : "TurnOn";
		// control sounds
		PostMessage(ObjID("shower sound #1"), soundMsg);
		PostMessage(ObjID("shower sound #2"), soundMsg);
		// control particles
		PostMessage(ObjID("decon shower #1"), pgMsg);
		PostMessage(ObjID("decon shower #2"), pgMsg);
		// delayed particles (it's okay to have multiples of these queued up)
		SetOneShotTimer("CtrlMist", 0.6, pgMsg);
	}

	function reduceRads(target) {
		local rads = Property.Get(target, "RadLevel");
		if (rads > 0) {
			rads = rads - 1 < 0 ? 0 : rads - 0.5;
			Property.SetSimple(target, "RadLevel", rads);
			SetData("RadTimer", SetOneShotTimer("RedRads", 0.125, target));
			if (rads == 0) {
				ShockGame.OverlayChange(kOverlayRadiation, kOverlayModeOff);
			}
		}
	}

	function killTimers() {
		if (IsDataSet("OffTimer")) {
			KillTimer(GetData("OffTimer"));
		}
		if (IsDataSet("RadTimer")) {
			KillTimer(GetData("RadTimer"));
		}
	}
}

// --------------------------------------------------------------------------------
// Spawn a protocol droid when TurnOn received
// Used only on eng2 protocol droid crates that spawn protocol droids.
class scpProtoBotSpawn extends SqRootScript {
	function OnTurnOn() {
		Object.RemoveMetaProperty(self, "ProtoBot Splode");
		Object.AddMetaProperty(self, "ProtoBot Spawn");
		Damage.Slay(self, 0);
	}
}

// --------------------------------------------------------------------------------
// Creates a physics attachment to parent object linked with ScriptParams link
// when TurnOn received, if still in contact with it.
// Host object must be positioned to fall on parent object to establish physics
// contact at least once.
// Used only on eng2 nanites on collapsing lift.
class scpPhysLink extends SqRootScript {
	function OnBeginScript() {
		if (Object.Exists(self) && Physics.HasPhysics(self)) {
			Physics.SubscribeMsg(self, ePhysScriptMsgType.kContactMsg);
		}
	}

	function OnEndScript() {
		Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kContactMsg);
	}

	function OnPhysContactCreate() {
		SetData("LastObj", message().contactObj);
	}

	function OnTurnOn() {
		local lnk = Link.GetOne("ScriptParams", self);
		local obj = LinkDest(lnk);
		Link.Destroy(lnk);
		if (obj == GetData("LastObj")) {
			lnk = Link.Create("PhysAttach", self, obj);
			LinkTools.LinkSetData(lnk, "Offset", Object.Position(self) - Object.Position(obj));
		}
	}
}

// --------------------------------------------------------------------------------
// Programmatically sets up a bunch of stuff for the SHODAN presentation that would
// be a huge pain to tinker with manually in DromEd.
class scpShodanShow extends SqRootScript {
	function OnTurnOn() {
		local delayTrapName;
		local delayTraps = ["Hall Delay 2", "Hall Delay 1", "Hall Delay 3", "Hall Delay 4", "Roof Delay 1", "Roof Delay 3", "Roof Delay 2", "Wall Delay 1", "Wall Delay 7", "Wall Delay 2", "Wall Delay 6", "Wall Delay 3", "Wall Delay 5", "Wall Delay 4", "Floor Delay 1", "Floor Delay 2", "Floor Delay 3"];
		local delInterval = 7.0 / (delayTraps.len() - 1);
		local delay = 0;
		foreach (delayTrapName in delayTraps) {
			// set all room parts to fade out at even intervals
			Property.SetSimple(delayTrapName, "DelayTime", delay);
			delay += delInterval;
			// set fade parameters
			setFadeParams(delayTrapName);
		}
		setFadeParams("Master Console Delay");
		Link.BroadcastOnAllLinks(self, "TurnOn", "SwitchLink");
	}

	function setFadeParams(delayTrapName) {
		local lnk, obj;
		foreach (lnk in Link.GetAll("SwitchLink", ObjID(delayTrapName), 0)) {
			obj = LinkDest(lnk);
			if (Property.Possessed(obj, "Scripts") && (Property.Get(obj, "Scripts", "Script 0") == "scpShodanDoor" || Property.Get(obj, "Scripts", "Script 0") == "scpShodanProp")) {
				Property.SetSimple(obj, "ObjList", "NVRelayTrapOffDelay=1000; NVRelayTrapOn='FadeIn'; NVRelayTrapOff='TurnOn'; NVRelayTrapTOn='DoFadeIn'; NVRelayTrapTOff='DoTurnOn'; NVRelayTrapTDest='[me]'; NVPhantomTrapOn='DoFadeIn'; NVPhantomTrapOff='DoTurnOn'; NVPhantomFadeOn=100; NVPhantomFadeOff=300");
				Property.Set(obj, "Scripts", "Script 2", "NVRelayTrap");
				Property.Set(obj, "Scripts", "Script 3", "NVPhantomTrap");
			}
		}
	}
}

// --------------------------------------------------------------------------------
// Minimal door handler for SHODAN transformation sequence
// Uses property Door/Door Open Sound to indicate open schema
// Works in conjunction with NVPhantomTrap
class scpShodanDoor extends SqRootScript {
	function OnTurnOn() {
		if (HasProperty("DoorOpenSound")) {
			Sound.PlaySchema(self, GetProperty("DoorOpenSound"));
		}
		Door.OpenDoor(self);
	}

	function OnTurnOff() {
		SetOneShotTimer("DoorClose", 3.9);
	}

	function OnTimer() {
		local m = message().name;
		if (m == "DoorClose") {
			// save and remove material tags so object walls/floors
			// don't make any impact sounds when they close
			if (Property.PossessedSimple(self, "Material Tags")) {
				SetData("MatTags", GetProperty("Material Tags"));
			}
			SetProperty("Material Tags", "");
			// slam the doors shut
			if (HasProperty("TransDoor")) {
				SetProperty("TransDoor", "Base Speed", 999);
				SetProperty("BashFactor", 0);
			}
			Door.CloseDoor(self);
			PostMessage(self, "FadeIn");
			SetOneShotTimer("Restore", 0.5);
		}
		else if (m == "Restore") {
			if (IsDataSet("MatTags")) {
				SetProperty("Material Tags", GetData("MatTags"));
			}
			else {
				Property.Remove(self, "Material Tags");
			}
		}
	}

	function OnPhantomOn() {
		Property.Remove(self, "RenderAlpha");
	}
}

// --------------------------------------------------------------------------------
// Prop fader for SHODAN transformation sequence
// Works in conjunction with NVPhantomTrap
class scpShodanProp extends SqRootScript {
	function OnTurnOff() {
		SetOneShotTimer("FadeDelay", 3.9);
	}

	function OnTimer() {
		if (message().name == "FadeDelay") {
			PostMessage(self, "FadeIn");
		}
	}

	function OnPhantomOn() {
		Property.Remove(self, "RenderAlpha");
	}
}

// --------------------------------------------------------------------------------
// Adds quest notes for each Rec deck art terminal code found, in the order they're found
// Place on each Code Art (-2936) terminal. Set Design Note: "ArtCode=" code pic number.
// E.g. "ArtCode=0", etc. Qvars for art codes are in format Note_5_XX, where 10 - 13 are
// the first code found, 14 - 17 the second, 18 - 21 the third, and 22 - 25 the fourth.
// FUN FACT: Last two digits are limited by engine to 32 max.
class scpAddArtCodeQB extends SqRootScript {
	function OnTimer() {
		if (message().name == "StaticOver" && !IsDataSet("Done")) {
			local frobs = (GetData("Frobs") || 0) + 1;
			SetData("Frobs", frobs);
			if (frobs == 2) {
				addCode();
				SetData("Done", true);
			}
		}
	}

	function addCode() {
		local artFound = Quest.Get("ArtFound");
		local artCode = userparams().ArtCode;
		Quest.Set("Note_5_" + (artFound * 4 + 10 + artCode), 1, eQuestDataType.kQuestDataCampaign);
		Quest.Set("ArtFound", artFound + 1, eQuestDataType.kQuestDataCampaign);
	}
}

// --------------------------------------------------------------------------------
// Clears all Rec art code notes and replaces them with a single note displaying the final code
class scpFinishArtCodeQBs extends SqRootScript {
	function OnTurnOn() {
		local i;
		local count = 0;
		// remove all possible art code quest notes
		for (i = 10; i < 26; i++) {
			if (Quest.Exists("Note_5_" + i)) {
				Quest.Delete("Note_5_" + i);
				count++;
			}
		}
		if (count < 4) {
			//print("Cheater!");
		}
		// add completed quest note with the full transmitter code
		Quest.Set("Note_5_9", 2, eQuestDataType.kQuestDataCampaign);
	}
}

// --------------------------------------------------------------------------------
// Kills player if rec1 broken lift falls on his head
class scpLiftBash extends SqRootScript {
	function OnBeginScript() {
		Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
	}

	function OnEndScript() {
		Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
	}
	
	function OnPhysCollision() {
		local curVel = vector();
		Physics.GetVelocity(self, curVel)
		if (Networking.IsPlayer(message().collObj)) {
			Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
			if (curVel.z < -15) {
				ActReact.Stimulate(message().collObj, "Standard Impact", 1000, self);
			}
		}
	}
}

// --------------------------------------------------------------------------------
// Applies vertical boost to basketball velocity when basketball hoop is visible
// (the only basketball hoop in the entire game is on rec1)
class scpBBall extends SqRootScript {
	function OnPhysMadePhysical() {
		local hoop = Object.FindClosestObjectNamed(ObjID("Player"), "B-Ball Hoop");
		if (hoop && Object.RenderedThisFrame(hoop)) {
			// delay modifying velocity since ball isn't fully instantiated yet
			PostMessage(self, "HoopShot");
		}
	}

	function OnHoopShot() {
		local curVel = vector();
		Physics.GetVelocity(self, curVel)
		Physics.SetVelocity(self, vector(curVel.x, curVel.y, 20));
	}
}

// --------------------------------------------------------------------------------
// Manages collapsing grate trap in rec2
// Grate will fall if trigged by tripwire or any physics contact
class scpRecGrate extends SqRootScript {
	function OnBeginScript() {
		Physics.SubscribeMsg(self, ePhysScriptMsgType.kWokeUpMsg);
	}

	function OnEndScript() {
		Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kWokeUpMsg);
	}

	function OnPhysWokeUp() {
		doCollapse();
	}

	function OnTurnOn() {
		doCollapse();
	}

	function doCollapse() {
		if (IsDataSet("done")) {
			return;
		}
		SetData("done", true);
		// spawn falling grate
		local obj = Object.Create("Grate 6x8 falling");
		Object.Teleport(obj, vector(), vector(), self);
		// play breakage sounds
		Sound.PlaySchemaAtLocation(obj, "hvegsm", Object.Position(obj));
		Sound.PlaySchemaAtLocation(obj, "debris_metal", Object.Position(obj));
		// give replacement grate a chance to instantiate (can sometimes take a couple of frames)
		SetOneShotTimer("Destroy", 0.01);
	}

	function OnTimer() {
		if (message().name == "Destroy") {
			Object.Destroy(self);
		}
	}
}

// --------------------------------------------------------------------------------
// Makes Command deck tram decelerate before stops so player isn't flung around 
// (add script to command1 tram)
class scpTramHelper extends SqRootScript {
	function OnTurnOn() {
		if (IsDataSet("TramTimer")) {
			KillTimer(GetData("TramTimer"));
		}
		// wait for elevator script to finish
		PostMessage(self, "TramInit");
	}

	function OnCallTram() {
		OnTurnOn();
	}

	function OnTramInit() {
		// stash destination node so recalc code doesn't have to keep grabbing it
		SetData("TramDest", LinkDest(Link.GetOne("TPathNext", self)));
		SetData("TramTimer", SetOneShotTimer("TramRecalc", 0.1));
	}
	
	function OnTimer() {
		local msg = message().name;
		if (msg == "TramRecalc") {
			// periodically recalculate arrival time to compensate for any engine hitches
			local curLoc = Object.Position(self);
			local nextLoc = Object.Position(GetData("TramDest"));
			local dist = fabs(curLoc.x - nextLoc.x);
			local curVel = vector();
			Physics.GetVelocity(self, curVel);
			local dur = dist / fabs(curVel.x);
			if (dur > 1.25) {
				SetData("TramTimer", SetOneShotTimer("TramRecalc", 1));
			}
			else {
				SetData("TramTimer", SetOneShotTimer("TramDecel", dur - 0.25));
			}
		}
		else if (msg == "TramDecel") {
			// set low tram speed; engine will smoothly decelerate it for us
			ShockGame.UpdateMovingTerrainVelocity(self, GetData("TramDest"), 1);
		}
	}
}

// --------------------------------------------------------------------------------
// Allow scpTramHelper to also work with tram call buttons
// (add script to all command1 tram call buttons)
class scpTramCallHelper extends SqRootScript {
	function OnFrobWorldEnd() {
		Link.BroadcastOnAllLinks(self, "CallTram", "SwitchLink");
	}
}

// --------------------------------------------------------------------------------
// Relays damage received to another object
// Used on command1 shuttle.
class scpDamageRelay extends SqRootScript {
	function OnDamage() {
		local m = message();
		local lnk = Link.GetOne("SwitchLink", self);
		if (lnk) {
			Damage.Damage(LinkDest(lnk), m.culprit, m.damage, m.kind);
			SetProperty("HitPoints", GetProperty("MAX_HP"));
		}
	}
}

// --------------------------------------------------------------------------------
// Place on marker that Korenchkin reaver should be teleported to; works once
// (in SCP this marker is set to destroy itself on Easy difficulty)
class scpAnatolyTeleport extends SqRootScript {
	function OnTurnOn() {
		if (GetData("Used")) {
			return;
		}
		SetData("Used", true);
		local link = Link.GetOne("SwitchLink", self);
		if (link) {
			local DstObj = LinkDest(link);
			if (!Object.HasMetaProperty(DstObj, "Dematerialized")) {
				Property.SetSimple(DstObj, "RenderAlpha", 0);
				Object.Teleport(DstObj, Object.Position(self), Object.Facing(self));
				Sound.PlayEnvSchema(DstObj, "Event Activate", DstObj, 0, eEnvSoundLoc.kEnvSoundAtObjLoc);
				SetData("Target", DstObj);
				SetOneShotTimer("FadeIn", 0.1);
			}
		}
	}

	function OnTimer() {
		if (message().name == "FadeIn") {
			local DstObj = GetData("Target");
			local alpha = Property.Get(DstObj, "RenderAlpha") + 0.1;
			if (alpha > 1) {
				alpha == 1;
			}
			Property.SetSimple(DstObj, "RenderAlpha", alpha);
			if (alpha < 1) {
				SetOneShotTimer("FadeIn", 0.1);
			}
		}
	}
}

// --------------------------------------------------------------------------------
// Flash the screen when a psi reaver brain gets killed
// (only used on command2 as a signal to players that they have properly defeated
// Korenchkin and can now proceed to the Rickenbacker)
class scpReaverFlash extends SqRootScript {
	function OnTurnOn() {
		ShockGame.StartFadeIn(1000, 255, 200, 180)
	}
}

// --------------------------------------------------------------------------------
// Checks whether player has sunk into the command2 main elevator (which can happen
// if players move around on it on the way down), and if so moves them out of it
// so they don't get crushed.
// Create an Enter Tripwire filling elevator shaft (11x10x2), just above first set of windows,
// switchlinked to itself, then place this script on it.
class scpCmdLiftFix extends SqRootScript {
	function OnTurnOn() {
		local liftObj = ObjID("CommandLift");
		local terPtObj = ObjID("CommandLiftStart");
		if (LinkDest(Link.GetOne("TPathNext", liftObj)) == terPtObj) {
			local playerObj = ObjID("Player");
			local playerPos = Object.Position(playerObj);
			local liftPos = Object.Position(liftObj);
			if (playerPos.z - liftPos.z < 2.4) {
				Object.Teleport(playerObj, vector(playerPos.x, playerPos.y, liftPos.z + 2.4), Object.Facing(playerObj));
			}
		}
	}
}

// --------------------------------------------------------------------------------
// Starts BotM level black then slowly fades in. Also turns off automap.
// Place this on "amb Many start" (925) in many.mis
class scpManyFadeIn extends SqRootScript {
	function OnSim() {
		if (!IsDataSet("Done")) {
			SetData("Done", true);
			// delay check since player isn't instantiated yet
			PostMessage(self, "FadeCheck");
		}
	}

	function OnFadeCheck() {
		// only do this if player is inside shuttle
		if (scp.DistanceSq(Object.Position(self), Object.Position("Player")) < 200) {
			ShockGame.StartFadeIn(10000, 0, 0, 0);
			if (ShockGame.OverlayOn(kOverlayMiniMap)) {
				ShockGame.OverlayChange(kOverlayMiniMap, kOverlayModeOff);
			}
		}
	}
}

// --------------------------------------------------------------------------------
// Enhanced ManyBrain script
// Adds visual effect when defended brain attacked
// TODO: Test this in multiplayer
class scpManyBrain extends SqRootScript {
	// custom Many brain invulnerability metaprop
	static invulnMetaprop = "InvulnManyBrain";

	function OnBeginScript() {
		if (Object.Exists(self) && !Networking.IsProxy(self)) {
			// check for ManyBossBalls (all inbound SwitchLinks assumed to be balls)
			if (Link.AnyExist("~SwitchLink", self)) {
				Object.AddMetaProperty(self, invulnMetaprop);
				Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
			}
			else {
				// just to be safe
				Object.RemoveMetaProperty(self, invulnMetaprop);
			}
		}
		Property.Set(self, "ExtraLight", "Additive?", true);
	}

	// clean up after ourself
	function OnEndScript() {
		Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
	}

	// balls send TurnOn signal with their dying breath
	function OnTurnOn() {
		// give engine time to delete the link
		// (seems to work fine without this delay, but we're making absolutely
		// sure so players don't end up with a permanently invulnerable boss)
		PostMessage(self, "CheckBalls");
	}

	// check if any balls are left
	function OnCheckBalls() {
		if (!Link.AnyExist("~SwitchLink", self)) {
			Object.RemoveMetaProperty(self, invulnMetaprop);
			Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
		}
	}

	// detect weapon impacts
	function OnPhysCollision() {
		if (!Networking.IsPlayer(message().collObj)) {
			brainEffects();
		}
	}

	// detect melee impacts
	// (requires custom Invulnerability metaprop with a WeaponBash -> Send to Scripts
	// receptron above the WeaponBash abort receptron)
	function OnWeaponBashStimulus() {
		brainEffects();
	}

	// display some visual effects to indicate the stars are protecting the brain
	function brainEffects() {
		local i, obj, ball, lnk, speed;
		foreach (lnk in Link.GetAll("~SwitchLink", self)) {
			ball = LinkDest(lnk);
			// create glow
			obj = Object.BeginCreate("ball shield");
			Link.Create("ParticleAttachement", obj, ball);
			Object.EndCreate(obj);
			// create effect linking balls to brain	
			if (!Link.GetOne("TPath", ball)) {
				Link.Create("TPath", ball, self);
			}
			speed = 60;
			for (i = 0; i < 5; i++) {
				obj = Object.BeginCreate("ball shield");
				Link.Create("TPathInit", obj, ball);
				Property.SetSimple(obj, "CollisionType", ePhysMessageResult.kPM_NonPhys);
				Property.SetSimple(obj, "MovingTerrain", true);
				ShockGame.UpdateMovingTerrainVelocity(obj, self, speed);
				Object.EndCreate(obj);
				speed += 25;
			}
		}
		// make brain glow
		Property.Set(self, "ExtraLight", "Amount (-1..1)", 0.8);
		if (IsDataSet("FadeTimer")) {
			KillTimer(GetData("FadeTimer"));
		}
		SetData("FadeTimer", SetOneShotTimer("Fade", 0.05));
	}

	// fade out impact glow
	function OnTimer() {
		if (message().name == "Fade") {
			local glow = Property.Get(self, "ExtraLight", "Amount (-1..1)");
			glow = glow / 1.5;
			if (glow < 0.01) {
				glow = 0;
				ClearData("FadeTimer");
			}
			else {
				SetData("FadeTimer", SetOneShotTimer("Fade", 0.05));
			}
			Property.Set(self, "ExtraLight", "Amount (-1..1)", glow);
		}
	}
}

// --------------------------------------------------------------------------------
// Activate and deactivate fog in many.mis
// TODO: Apply a curve mapping to the fog distance
class scpManyFog extends SqRootScript {
	static FOG_DIST_ON = 100;
	static FOG_DIST_OFF = 500;

	function OnBeginScript() {
		endTween();
	}
	
	function OnTurnOn() {
		if (getFogDist() != FOG_DIST_ON) {
			SetData("FogTarg", FOG_DIST_ON);
			startTimer();
		}
	}

	function OnTurnOff() {
		if (getFogDist() != FOG_DIST_OFF) {
			SetData("FogTarg", FOG_DIST_OFF);
			startTimer();
		}
	}

	function OnTimer() {
		local targ;
		local dist = getFogDist();
		if (message().name == "Tween") {
			targ = GetData("FogTarg");
			local delta = targ > dist ? 10 : -10;
			dist += delta;
			if ((delta > 0 && dist >= targ) || (delta < 0 && dist <= targ)) {
				dist = targ;
				SetData("FogTarg", 0);
			}
			else {
				startTimer();
			}
			setFogDist(dist);
		}
	}

	function startTimer() {
		stopTimer();
		SetData("TweenTimer", SetOneShotTimer("Tween", 0.05));
	}

	function stopTimer() {
		if (IsDataSet("TweenTimer")) {
			KillTimer(GetData("TweenTimer"));
		}
	}

	// set fog tween immediately to its end state
	function endTween() {
		stopTimer();
		local targ = GetData("FogTarg");
		if (IsDataSet("FogTarg") && targ != 0) {
			setFogDist(targ);
			SetData("FogTarg", 0);
		}
	}
	
	function getFogDist() {
		local distRef = float_ref();
		Engine.GetFog(int_ref(), int_ref(), int_ref(), distRef);
		return distRef.tofloat();
	}

	function setFogDist(dist) {
		local rRef = int_ref();
		local gRef = int_ref();
		local bRef = int_ref();
		Engine.GetFog(rRef, gRef, bRef, float_ref());
		Engine.SetFog(rRef.tointeger(), gRef.tointeger(), bRef.tointeger(), dist);
	}
}

// --------------------------------------------------------------------------------
// Centers player in SHODAN pit and sets ideal descent velocity
// Place on tripwire Teleport1Tripwire (775); must be centered in SHODAN pit
// Move Teleport5Tripwire (1354) below bottom of shaft; no longer needed
class scpShodanPit extends SqRootScript {
	function OnPhysEnter() {
		if (IsDataSet("done")) {
			return;
		}
		SetData("done", true);
		local obj = message().transObj;
		local objPos = Object.Position(obj);
		local pitCenter = Object.Position(self);
		Physics.SetVelocity(obj, vector((pitCenter.x - objPos.x) / 10.0, (pitCenter.y - objPos.y) / 10.0, -10));
		SetOneShotTimer("stop", 10);
	}
	
	function OnTimer() {
		if (message().name == "stop") {
			Physics.SetVelocity("Player", vector(0, 0, -10));
		}
	}
}

// --------------------------------------------------------------------------------
// Enhanced SHODAN shields script
// - Replaces both ShodanShield and TransluceByDamage on ShodanShields (-2961)
// - Varies shield regeneration rate based on difficulty (not currently used)
// - Changes shield color/transparency based on current HP
// - Can emulate vanilla behavior when activated via mod

// SHODAN shields vanilla setup
// CPUs (262, 264, 268) each linked to their own CPU#Router (302, 312, 314) that takes
// care of all visual hack-related tasks, and all link to HackMultiTrigger (276), which
// slays all shields when all CPUs hacked.
//
// Shield transparency managed by scripts ShodanShield and TransluceByDamage on the
// archetype (-2961) for all shield segments.
// ShodanShield regenerates shields by 1 HP per second, and sets shield alpha based on HP.
// TransluceByDamage also sets shield alpha based on HP, when damaged, but using a different formula.
class scpShodanShield extends SqRootScript {
	// 0: editor, 1: easy, 2: normal, 3: hard, 4: impossible, 5: multiplayer
	static diffHP     = [140, 130, 140, 150, 160, 160];
	static diffRate   = [ -1,  -1,  -1,  -1,  -1, -1];
	static diffSHODAN = [1, 0, 0.3, 0.6, 1, 1];
	// minimum HP % thresholds for each shield color
	static thresh = [0.99, 0.67, 0.34, 0.0];
	static hpModel = ["shoshld1", "shoshld2", "shoshld3", "shoshld4"];
	static hpAlpha = [0.3, 0.4, 0.55, 0.7];

	function OnBeginScript() {
		local diff, maxhp, arch;
		if (!Object.Exists(self)) {
			return;
		}
		if (scp.IsModEnabled("modFinalBoss")) {
			SetData("RetroMode", true);
		}
		if (!IsDataSet("RegenRate")) {
			if (GetData("RetroMode")) {
				maxhp = Property.Get("ShodanShields", "HitPoints");
				SetData("RegenRate", 1);
				SetData("RegenMax", maxhp);
				SetProperty("HitPoints", maxhp);
				SetProperty("MAX_HP", maxhp);
			}
			else {
				diff = Quest.Get("Difficulty");
				maxhp = diffHP[diff];
				SetData("RegenRate", diffRate[diff]);
				SetData("RegenMax", maxhp);
				SetData("HackCount", 0);
				SetProperty("HitPoints", maxhp);
				SetProperty("MAX_HP", maxhp);
				arch = ShockGame.GetArchetypeName(self);
				if (arch == "ShodanShield_1" || arch == "ShodanShield_3") {
					SetData("IsOdd", true);
				}
				updateShield();
			}
		}
		if (!Networking.IsProxy(self)) {
			if (IsDataSet("RegenTimer")) {
				KillTimer(GetData("RegenTimer"));
			}
			if (GetData("RegenRate") > 0) {
				startTimer();
			}
		}
	}

	function OnDamage() {
		updateShield();
		if (!GetData("RetroMode")) {
			// make shield flash
			SetProperty("RenderAlpha", 0.8)
			if (IsDataSet("FlashTimer")) {
				KillTimer(GetData("FlashTimer"));
			}
			SetData("FlashTimer", SetOneShotTimer("Flash", 0.08));
		}
	}

	function OnSlain() {
		if (GetData("RetroMode")) {
			return;
		}
		local lnk, obj, diffPer;
		local shields = 0;
		// count remaining shields
		foreach (lnk in Link.GetAll("SwitchLink", "HackMultiTrigger")) {
			obj = LinkDest(lnk);
			if (Object.InheritsFrom(obj, "ShodanShields") && Property.Get(obj, "HitPoints") > 0 && obj != self) {
				shields++;
			}
		}
		// calculate difficulty percent adjustment; percent shields destroyed times
		// percent of difficulty adjustment applied for current difficulty level
		diffPer = ((8 - shields) / 8.0) * diffSHODAN[Quest.Get("Difficulty")];
		// make SHODAN fire faster as more shield segments are destroyed
		Property.Set("Shodan Head", "AI_Turret", "Fire Pause", 2000 - diffPer * 1750);
		Property.Set("Shodan Head", "AI_Turret", "Fire Epsilon", 0.1 + diffPer * 0.5);
	}

	function OnHacked() {
		if (GetData("RetroMode")) {
			return;
		}
		// reduce RegenMax to 2/3 of MaxHP on first hack, 1/3 on second hack
		// damage by 1/3 of MaxHP
		local newMax;
		local hp = GetProperty("HitPoints");
		local maxHP = GetProperty("MAX_HP");
		local hacks = GetData("HackCount") + 1;
		SetData("HackCount", hacks);
		// cap regen max
		if (hacks == 1) {
			newMax = maxHP * 0.66;
		}
		else if (hacks == 2) {
			newMax = maxHP * 0.33;
		}
		SetData("RegenMax", newMax);
		// damage by a third
		hp = hp - maxHP * (1.0 / 3.0);
		if (hp > 0) {
			SetProperty("HitPoints", hp);
			OnDamage();
		}
		else {
			Damage.Slay(self, 0);
		}
	}

	function OnTimer() {
		if (message().name == "Flash") {
			local alpha = GetProperty("RenderAlpha");
			local targAlpha = GetData("targAlpha");
			if (typeof targAlpha == "null") {
				return;
			}
			alpha = alpha / 1.25;
			if (alpha <= (targAlpha - 0.01)) {
				alpha = targAlpha;
				ClearData("FlashTimer");
			}
			else {
				SetData("FlashTimer", SetOneShotTimer("Flash", 0.08));
			}
			SetProperty("RenderAlpha", alpha);
		}
		else if (message().name == "Regen") {
			SetProperty("HitPoints", scp.Clamp(GetProperty("HitPoints") + 1, 0, GetData("RegenMax")));
			updateShield();
			startTimer();
		}
	}

	function updateShield() {
		// determine current shield appearance
		local i = 0;
		local hpPer = scp.Clamp(GetProperty("HitPoints").tofloat() / GetProperty("MAX_HP"), 0, 1);
		if (GetData("RetroMode")) {
			SetProperty("RenderAlpha", hpPer * 0.82);
			return;
		}
		while (hpPer < thresh[i]) {
			i++;
		}
		// give even/odd shield segments slightly different transparency
		local finalAlpha = hpAlpha[i] + (IsDataSet("IsOdd") ? 0.05 : 0);
		SetProperty("ModelName", hpModel[i]);
		SetProperty("RenderAlpha", finalAlpha);
		SetData("targAlpha", finalAlpha);
	}

	function startTimer() {
		SetData("RegenTimer", SetOneShotTimer("Regen", GetData("RegenRate")));
	}
}

// --------------------------------------------------------------------------------
// Handle shield interlocks being hacked in SHODAN boss fight
// Replaces script on HackMultiTrigger (276)
class scpShieldHackTrigger extends SqRootScript {
	function OnTurnOn() {
		if (!IsDataSet("HackCount")) {
			SetData("HackCount", 0);
		}
		local hacks = GetData("HackCount") + 1;
		SetData("HackCount", hacks);
		if (hacks == 3) {
			PostMessage("DestroyShieldTrap", "TurnOn");
		}
		else if (hacks < 3) {
			// notify shield segments
			Link.BroadcastOnAllLinks(self, "Hacked", "SwitchLink");
			Sound.PlaySchema(ObjID("Big Shodan Head"), "ShoDoors");
		};
	}
}

// --------------------------------------------------------------------------------
// Helper for SHODAN boss fight big head
// - Makes shots randomly emit from left or right eye
// - Spawns corpse when slain
// - Performs retro mode one-time setup tasks
class scpShodanHeadHelper extends SqRootScript {
	function OnBeginScript() {
		if (scp.IsModEnabled("modFinalBoss")) {
			SetData("RetroMode", true);
			Object.Destroy("BossMusic");
			Property.SetSimple("Shodan Head Sabot", "PhysInitVel", vector(30, 0, 0));
			return;
		}
		if (IsDataSet("EyeTimer")) {
			KillTimer(GetData("EyeTimer"));
		}
		SetData("EyeTimer", SetOneShotTimer("ICU", 1));
	}

	function OnTimer() {
		if (message().name == "ICU") {
			Property.Set("Shodan Head Launcher", "AIGunDesc", "Fire Offset", vector(0, scp.Rand() > 0.5 ? 1.5 : -1.5, -0.25));
			SetData("EyeTimer", SetOneShotTimer("ICU", 0.5));
		}
	}
	
	function OnSlain() {
		if (!IsDataSet("RetroMode")) {
			Object.Teleport(Object.Create("Shodan DeadHead") vector(), vector(0, 0, GetProperty("JointPos", "Joint 1")), self);
			Sound.PlaySchemaAmbient(0, "sh2die");
		}
	}
}

// --------------------------------------------------------------------------------
// Replaces ShodanDeath
// Smoother fadeout and activates respawn throttle
class scpShodanDeath extends SqRootScript {
	function OnSlain() {
		Quest.Set("SpawnAvatars", 0);
		PostMessage("AvatarDelay", "TurnOn");
		SetOneShotTimer("Fade", 0);
	}

	function OnTimer() {
		if (message().name == "Fade") {
			local alpha = GetProperty("RenderAlpha") - 0.03;
			if (alpha > 0) {
				SetProperty("RenderAlpha", alpha)
				SetOneShotTimer("Fade", 0.05);
			}
			else {
				Object.Destroy(self);
			}
		}
	}
}

// --------------------------------------------------------------------------------
// Replaces DieShodanDie
// Makes credits cutscene automatically play after endgame cutscene
class scpDieShodanDie extends SqRootScript {
	function OnTurnOn() {
		Networking.Broadcast(self, "NetTurnOn", false, null);
		playEndVideo();
	}

	function OnNetTurnOn() {
		playEndVideo();
	}

	function OnTimer() {
		if (message().name == "Credits") {
			ShockGame.EndGame();
			ShockGame.PlayVideo("credits.avi");
		}
	}
	
	function playEndVideo() {
		// try to make screen as blacked out as possible so nothing appears between videos
		Quest.Set("HideInterface", 1);
		ShockGame.StartFadeIn(100000, 0, 0, 0);
		// move player away from any audio sources so nothing is heard between videos
		Physics.SetVelocity("Player", vector());
		Object.Teleport("Player", vector(), vector(), ObjID("EndMovieRoom"));
		// sim suspended while video is playing, so this delay will be inserted between the videos
		SetOneShotTimer("Credits", 0.25);
		ShockGame.PlayVideo("cs3.avi");
	}
}


// ================================================================================
//  TRAPS AND TRIPWIRES
// ================================================================================

// --------------------------------------------------------------------------------
// Tripwire that slays any monster or player that enters it
// Implements Trip Control Flags "Player" flag
class scpTripSlay extends SqRootScript {
	function OnBeginScript() {
		Physics.SubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
	}

	function OnEndScript() {
		Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
	}

	function OnPhysEnter() {
		local obj = message().transObj;
		local flags = GetProperty("TripFlags");
		if (Object.InheritsFrom(obj, "Monsters")) {
			Property.SetSimple(obj, "HitPoints", 0);
			Damage.Slay(obj, self);
		}
		else if (Networking.IsPlayer(obj) && scp.BitTest(flags, 5) && Property.Get(obj, "HitPoints") > 0) {
			Property.SetSimple(obj, "HitPoints", 0);
			Damage.Slay(obj, self);
			Sound.PlaySchemaAmbient(obj, "dam_gen_hi");
		}
	}
}

// --------------------------------------------------------------------------------
// Tripwire substitute that uses stims instead of a tripwire. Use sparingly, only
// where a conventional tripwire prevents mantling.
// Required Setup:
// - Stim types TripwireTx and TripwireRx must exist.
// - Player archetype has receptron TripwireTx, No Min, No Max, Effect: Stim Object,
//   Stimulus TripwireRX, Target Source, Agent Me
// - Tripwire has source TripwireTx, Radius, Intensity 1, Radius 10 (or as desired),
//   No line of sight, No max firings, Period 200
// - Tripwire has receptron TripwireRx, No Min, No Max, Effect: Send to Scripts
//
// Usage:
// - On the problematic tripwire, set Physics/Misc/Collision Type: [None] (uncheck
//   everything). This will make the tripwire ignore player collisions, but still
//   inform AIs that they're allowed to open the door, and still generate TurnOff
//   messages to close doors behind AIs (AIs will only automatically open doors for
//   themselves, not close them).
// - Create a Stim Tripwire in the same location as the tripwire and switchlink it
//   to the door to be controlled.
class scpStimTripwire extends SqRootScript {
	function OnTripwireRxStimulus() {
		// don't send multiple TurnOn messages and don't trigger if stimmed through a floor or wall
		// (do a raycast from the tripwire to the return stim source)
		if (!GetData("LastOn") && !Engine.PortalRaycast(Object.Position(self), Object.Position(sLink(message().source).source), vector())) {
			Link.BroadcastOnAllLinks(self, "TurnOn", "SwitchLink");
			SetData("LastOn", true);
		}
		// keep restarting timer while player is in range
		// timer duration must be at least double the stim period
		if (IsDataSet("StimTimer")) {
			KillTimer(GetData("StimTimer"));
		}
		SetData("StimTimer", SetOneShotTimer("StimCheck", 0.4));
	}

	function OnTimer() {
		if (message().name == "StimCheck") {
			// timer completed, so player must be out of range
			Link.BroadcastOnAllLinks(self, "TurnOff", "SwitchLink");
			SetData("LastOn", false);
		}
	}
}

// --------------------------------------------------------------------------------
// Initial level sim trap. Includes a slight delay to allow things to initialize.
class scpTrapSim extends SqRootScript {
	function OnSim() {
		SetOneShotTimer("Send", 0.02);
	}

	function OnTimer() {
		if (message().name == "Send") {
			Link.BroadcastOnAllLinks(self, "TurnOn", "SwitchLink");
		}
	}
}

// --------------------------------------------------------------------------------
// Version of TrapTripLevel that performs elevatoring
class scpTrapTripLevelElev extends SqRootScript {
	function OnBeginScript() {
		Physics.SubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
	}
	
	function OnEndScript() {
		Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
	}
	
	function OnPhysEnter() {
		if (Networking.IsPlayer(message().transObj) && HasProperty("DestLevel") && HasProperty("DestLoc")) {
			ShockGame.LevelTransport(GetProperty("DestLevel"), GetProperty("DestLoc"), 1);
		}
	}
}

// --------------------------------------------------------------------------------
// Enhanced ecology script
// - Fixes duplicate timers accumulating when script restarts
// - Fixes spawn period resetting every time script restarts
// - Fixes raise_spawn_rand allowing rand to go negative
// - Improves consolidation of TriggerEcology and TriggerEcologyDiff
// - Adds spawn escalation for repeated alarms
class TriggerEcology extends SqRootScript {
	function OnBeginScript() {
		if (!Networking.IsProxy(self)) {
			SetEcologyTimer(true);
			if (!IsDataSet("RecoverTime")) {
				SetData("RecoverTime", -1);
			}
			if (SPAWN_ECO_ESCALATE && isAlertEco() && !IsDataSet("TrigCount") && Quest.Get("Difficulty") != 1) {
				SetData("TrigCount", 0);
			}
		}
	}

	function OnNetAlarm() {
		AlarmOn();
	}

	function OnNetClearAlarm() {
		AlarmOff();
	}

	function OnAlarm() {
	    if (GetProperty("EcoState") == 0) {
			EscalateCheck();
			SetRecoveryTimer(GetProperty("Ecology", "Alert Recovery"));
			Link.BroadcastOnAllLinksData(self, "Alarm", "SwitchLink", message().data);
			SetData("Victim", message().data);
			SetProperty("EcoState", 2);
			AlarmOn();
			Networking.Broadcast(self, "NetAlarm", 0, 0);
		}
	}

	function OnReset() {
		if (GetProperty("EcoState") == 2) {
			Link.BroadcastOnAllLinksData(self, "Reset", "SwitchLink", message().data);
			ClearEcology();
			AlarmOff();
			Networking.Broadcast(self, "NetClearAlarm", 0, 0);
			if (GetData("RecoverTime") != -1) {
				KillTimer(GetData("RecoverTime"));
			}
		}
	}

	function OnTimer() {
		local mName = message().name;
		if (mName == "Ecology") {
			EcoActivate();
			SetEcologyTimer();
		}
		else if (mName == "Recovery") {
			ResetEcology();
		}
	}

	function EcoActivate() {
		local min, max, rand, oldMax;
		local fref = float_ref();
		local iref = int_ref();
		local diffMode = IsDataSet("EcoDiff");
		local state = GetProperty("EcoState");
		if (state == 0) {
			min = GetProperty("Ecology", "Normal Min");
			max = GetProperty("Ecology", "Normal Max");
			rand = GetProperty("Ecology", "Normal Rand");
			if (diffMode) {
				if (Engine.ConfigIsDefined("no_spawn")) {
					max = 0;
				}
				else if (Engine.ConfigIsDefined("mult_spawn_max") && !isAlertEco()) {
					oldMax = max;
					Engine.ConfigGetFloat("mult_spawn_max", fref)
					max = (max * fref.tofloat()).tointeger();
					// never allow multiplying down to zero
					if (oldMax == 1 && max == 0) {
						max = 1;
					}
				}
				if (Engine.ConfigIsDefined("lower_spawn_min")) {
					Engine.ConfigGetInt("lower_spawn_min", iref);
					min -= iref.tointeger();
					if (min < 0) {
						min = 0;
					}
				}
				if (Engine.ConfigIsDefined("raise_spawn_rand")) {
					Engine.ConfigGetInt("raise_spawn_rand", iref);
					rand += iref.tointeger();
					if (rand < 0) {
						rand = 0;
					}
				}
			}
		}
		else if (state == 2) {
			min = GetProperty("Ecology", "Alert Min");
			max = GetProperty("Ecology", "Alert Max");
			rand = GetProperty("Ecology", "Alert Rand");
		}
		if (diffMode && Quest.Get("Difficulty") == 1) {
			if (min > 1) {
				--min;
			}
			if (max > 1) {
				--max;
			}
			rand *= 2;
		}
		local count = ShockGame.CountEcoMatching(GetProperty("EcoType"));
		if (SPAWN_DEBUG_LEVEL && !(isAlertEco() && GetProperty("EcoState") == 0)) {
			dprint((diffMode ? "DIFF " : "") + "ECOLOGY " + self + " AWAKENS (" + (isAlertEco() ? "Alert" : "Normal") + ") Min:" + min + " Max:" + max + " Rand:" + rand + " Count:" + count);
		}
		if ((count < max) && ((count < min) || (rand != 0 && Data.RandInt(0, rand) == 0))) {
			Link.BroadcastOnAllLinksData(self, "TurnOn", "SwitchLink", GetData("Victim"));
			dprint("  Requesting spawn...");
		}
	}

	function ClearEcology() {
		SetProperty("EcoState", 0);
	}

	function SetRecoveryTimer(time) {
		if (GetData("RecoverTime") != -1) {
			KillTimer(GetData("RecoverTime"));
		}
		SetData("RecoverTime", SetOneShotTimer("Recovery", time));
	}

	function SetEcologyTimer(beginScript = false) {
		local nextTime, diffTime;
		local fref = float_ref();
		local curTime = ShockGame.SimTime();
		local pTime = (GetProperty("Ecology", "Period") * 1000).tointeger();
		if (IsDataSet("EcoDiff")) {
			if (Quest.Get("Difficulty") == 1) {
				pTime *= 2;
			}
			if (Engine.ConfigIsDefined("mult_spawn_period") && !isAlertEco()) {
				Engine.ConfigGetFloat("mult_spawn_period", fref);
				pTime *= fref.tofloat();
			}
		}
		if (IsDataSet("EcoTimer")) {
			KillTimer(GetData("EcoTimer"));
		}
		if (beginScript && IsDataSet("EcoNextTime")) {
			nextTime = GetData("EcoNextTime");
			diffTime = nextTime - curTime;
			if (diffTime < 0) {
				dprint("Ecology " + self + " past due. Activating...");
				EcoActivate();
			}
			else {
				pTime = diffTime;
				dprint("Ecology " + self + " resuming. " + (pTime.tofloat() / 1000) + " seconds until next activation");
			}
		}
		SetData("EcoTimer", SetOneShotTimer("Ecology", pTime.tofloat() / 1000));
		SetData("EcoNextTime", curTime + pTime);
	}

	function AlarmOn() {
		Sound.PlaySchemaAmbient(self, "xer02");
		ShockGame.AddAlarm(GetProperty("Ecology", "Alert Recovery") * 1000);
		PostMessage("Player", "KlaxOn");
	}

	function AlarmOff() {
		Sound.PlaySchemaAmbient(self, "xer03");
		ShockGame.RemoveAlarm();
		PostMessage("Player", "KlaxOff");
	}

	function ResetEcology() {
		Link.BroadcastOnAllLinksData(self, "Reset", "SwitchLink", 0);
		ClearEcology();
		AlarmOff();
		Networking.Broadcast(self, "NetClearAlarm", 0, 0);
	}

	function EscalateCheck() {
		if (!IsDataSet("TrigCount")) {
			return;
		}
		local trig = GetData("TrigCount") + 1;
		if (trig > SPAWN_ECO_ESCALATE) {
			trig = 1;
			Link.BroadcastOnAllLinks(self, "Escalate", "SwitchLink");
			dprint("Ecology " + self + " requesting spawn escalation!");
		}
		SetData("TrigCount", trig);
	}

	function isAlertEco() {
		return GetProperty("Ecology", "Alert Recovery") != 0.0;
	}

	// debug print
	function dprint(txt) {
		if (SPAWN_DEBUG_LEVEL) {
			scp.Trace(txt);
		}
	}
}

// --------------------------------------------------------------------------------
// Enhanced ecology script (diff variant)
class TriggerEcologyDiff extends TriggerEcology {
	function OnBeginScript() {
		if (!IsDataSet("EcoDiff")) {
			SetData("EcoDiff", true);
		}
		base.OnBeginScript();
	}
}

// --------------------------------------------------------------------------------
// Enhanced TrapSpawn script
// - Suppresses spawn-in effect when Raycast flag set
// - Copies Patrol: Does Patrol from host object in addition to spawn marker
// - Now also copies Patrol: Random Sequence
// - Farthest flag now doesn't cause Raycast to be ignored
// - Raycast now keeps trying when it fails
// - Supply is no longer depleted when spawn fails
class scpTrapSpawn extends SqRootScript {
	function OnBeginScript() {
		if (SPAWN_DEBUG_LEVEL == 2 && !IsDataSet("Init")) {
			SetData("Init", true);
			SetData("Spawns1", 0);
			SetData("Spawns2", 0);
			SetData("Spawns3", 0);
			SetData("Spawns4", 0);
		}
	}

	function OnTurnOn() {
		dprint("--------------------", true);
		dprint("SPAWN REQUESTED (" + self + ")");
		local obj, flags, spawnPt;
		local supply = GetProperty("Spawn", "Supply");
		if (supply < 0) {
			dprint("No more supply");
			return;
		}
		if (supply != 0) {
			dprint("Supply: " + supply);
		}
		flags = GetProperty("Spawn", "Flags");
		spawnPt = findSpawnPoint(flags);
		if (spawnPt) {
			obj = spawnObject(spawnPt, flags);
			if (obj) {
				if (supply != 0) {
					SetProperty("Spawn", "Supply", supply == 1 ? -1 : supply - 1);
				}
				if (eSpawnFlags.kSpawnFlagGotoAlarm & flags) {
					dprint("  Goto player", true);
					AI.MakeGotoObjLoc(obj, message().data || "Player", eAIScriptSpeed.kFast);
				}
				if (HasProperty("ObjSoundName")) {
					Sound.PlaySchemaAmbient(GetProperty("ObjSoundName"), eSoundNetwork.kSoundNetworkAmbient);
				}
			}
		}
	}

	function OnEscalate() {
		local types= [
			["OG-Pipe",        "OG-Shotgun"],
			["OG-Shotgun",     "OG-Grenade"],
			["OG-Grenade",     "Assassin"],
			["Midwife",        "Assassin"],
			["Assassin",       "Rumbler"],
			["Protocol Droid", "Maintenance"],
			["Maintenance",    "Security"],
			["Security",       "Assault"],
			["Blue Monkey",    "Red Monkey"],
			["Baby Arachnid",  "Arachnightmare"],
			["Arachnightmare", "Invisibile Arachnid"]
		];
		local i, curType, escType;
		for (i = 1; i < 5; i++) {
			curType = GetProperty("Spawn", "Type " + i);
			foreach (escType in types) {
				if (curType == escType[0]) {
					SetProperty("Spawn", "Type " + i, escType[1]);
					break;
				}
			}
		}
	}

	// attempt to spawn something
	function spawnObject(spawnPt, flags) {
		local obj, objFX;
		local objType = spawnType();
		if (objType) {
			obj = Object.BeginCreate(objType);
			Property.CopyFrom(obj, "EcoType", self);
			Property.CopyFrom(obj, "AI_Patrol", Property.PossessedSimple(spawnPt, "AI_Patrol") ? spawnPt : self);
			Property.CopyFrom(obj, "AI_PtrlRnd", Property.PossessedSimple(spawnPt, "AI_PtrlRnd") ? spawnPt : self);
			Object.Teleport(obj, vector(), vector(), spawnPt);
			Object.EndCreate(obj);
			ShockAI.ValidateSpawn(obj, spawnPt);
			Link.Create("Spawned", spawnPt, obj);
			if (!(eSpawnFlags.kSpawnFlagRaycast & flags)) {
				objFX = Object.BeginCreate("SpawnSFX");
				Object.Teleport(objFX, vector(), vector(), spawnPt);
				Object.EndCreate(objFX);
			}
			return obj;
		}
		else {
			return null;
		}
	}

	// roll a spawn
	function spawnType() {
		local i, rand, type;
		local sum = 0;
		for (i = 1; i < 5; i++) {
			sum += GetProperty("Spawn", "Rarity " + i);
		}
		rand = Data.RandInt(0, sum - 1);
		sum = 0;
		for (i = 1; i < 5; i++) {
			sum += GetProperty("Spawn", "Rarity " + i);
			if (rand < sum) {
				type = GetProperty("Spawn", "Type " + i);
				if (SPAWN_DEBUG_LEVEL == 2) {
					SetData("Spawns" + i, GetData("Spawns" + i) + 1);
				}
				break;
			}
		}
		dprint("  Spawning: " + type);
		if (SPAWN_DEBUG_LEVEL == 2) {
			dprint("  Stats: " + GetData("Spawns1") + ", " + GetData("Spawns2") + ", " + GetData("Spawns3") + ", " + GetData("Spawns4"));
		}
		return type != "" ? type : null;
	}

	// pick a spawn marker
	function findSpawnPoint(flags) {
		local obj, lnk, count, m, i, t;
		local objList = [];
		local objPlr = ObjID("Player");
		
		// build list of potential spawn points
		if (eSpawnFlags.kSpawnFlagSelfMarker & flags) {
			dprint("Using self as spawn point", true);
			if (validSpawn(self, flags)) {
				objList.push(self)
			}
		}
		foreach (lnk in Link.GetAll("SpawnPoint", self, 0)) {
			obj = LinkDest(lnk);
			if (validSpawn(obj, flags)) {
				objList.push(obj);
			}
		}
		// sort spawn points
		count = objList.len();
		if (count == 0) {
			dprint("No valid spawn points");
			return null;
		}
		else if (count == 1) {
			dprint("Only one valid spawn point...", true);
		}
		else if ((eSpawnFlags.kSpawnFlagFarthest & flags) || SPAWN_FORCE_FARTHEST) {
			// sort by distance
			dprint("Sorting by distance...", true);
			objList.sort(@(a,b) scpTrapSpawn.flatDistSq(Object.Position(objPlr), Object.Position(b)) <=> scpTrapSpawn.flatDistSq(Object.Position(objPlr), Object.Position(a)));
		}
		else {
			// sort randomly (Fisher-Yates shuffle)
			dprint("Sorting randomly...", true);
			m = objList.len();
			while (m) {
				i = floor(scp.Rand(m--));
				t = objList[m];
				objList[m] = objList[i];
				objList[i] = t;
			}
		}
		if (SPAWN_DEBUG_LEVEL == 2) {
			foreach (obj in objList) {
				dprint("  " + obj + " (dist " + flatDistSq(Object.Position(objPlr), Object.Position(obj)) + ")");
			}
		}

		// if Raycast not set, return either the farthest point or a random point
		if (!(eSpawnFlags.kSpawnFlagRaycast & flags)) {
			return objList[0];
		}
		// only return a spawn point that isn't potentially visible to player
		// (check against terrain only; all objects considered as see-through)
		foreach (obj in objList) {
			if (Engine.PortalRaycast(Object.Position(objPlr), Object.Position(obj), vector())) {
				dprint("Found a good spawn point (" + obj + ")", true);
				return obj;
			}
			else {
				dprint("Spawn point " + obj + " rejected due to Raycast", true);
				if (!SPAWN_RAYCAST_RETRY) {
					break;
				}
			}
		}
		dprint("Couldn't find a good spawn point");
		return null;
	}

	// determine whether this is a valid spawn marker
	function validSpawn(obj, flags) {
		// PopLimit flag limits spawns to 1 per marker
		if ((eSpawnFlags.kSpawnFlagPopLimit & flags) && Link.AnyExist("Spawned", obj, 0)) {
			dprint("Spawn point " + obj + " rejected due to PopLimit", true);
			return false;
		}
		// PlrDist flag prevents spawns within 30 DromEd units (X/Y only) from the player
		if ((eSpawnFlags.kSpawnFlagPlayerDist & flags) && (flatDistSq(Object.Position("Player"), Object.Position(obj)) < 900)) {
			dprint("Spawn point " + obj + " rejected due to PlrDist", true);
			return false;
		}
		return true;
	}

	// determine distance squared between two vectors along the X/Y plane only
	function flatDistSq(v1, v2) {
		local dx, dy;
		dx = v1.x - v2.x;
		dy = v1.y - v2.y;
		dx = dx * dx;
		dy = dy * dy;
		return dx + dy;
	}
	
	// debug print
	function dprint(txt, verbose = false) {
		if ((SPAWN_DEBUG_LEVEL == 1 && !verbose) || (SPAWN_DEBUG_LEVEL == 2)) {
			scp.Trace(txt);
		}
	}
}

// --------------------------------------------------------------------------------
// Simplified version of TrapSpawn
// - Spawns only on marker containing the script
// - Spawns first entity only in Script/Spawn
// - Copies EcoType and Patrol: Does Patrol setting on spawner
// - Implements GotoLoc flag
class scpSimpleSpawn extends SqRootScript {
	function OnTurnOn() {
		local type = GetProperty("Spawn", "Type 1");
		if (ObjID(type) != 0) {
			local obj = Object.BeginCreate(type);
			Property.CopyFrom(obj, "EcoType", self);
			Property.CopyFrom(obj, "AI_Patrol", self);
			Object.Teleport(obj, vector(), vector(), self);
			Object.EndCreate(obj);
			ShockAI.ValidateSpawn(obj, self);
			if (scp.BitTest(GetProperty("Spawn", "Flags"), 2)) {
				AI.MakeGotoObjLoc(obj, "Player", eAIScriptSpeed.kFast);
			}
		}
	}
}


// ================================================================================
//  MISC UTILITY SCRIPTS
// ================================================================================

// --------------------------------------------------------------------------------
// Accepts TurnOn or TurnOff signal and broadcasts it down all SwitchLinks, once only
// (replaces OnceRouter, which accepts ANY signal, including ObjRoomTransit!)
class scpOnceRouter extends SqRootScript {
	function OnTurnOn() {
		Broadcast("TurnOn");
	}

	function OnTurnOff() {
		Broadcast("TurnOff");
	}

	function Broadcast(msg) {
		if (!IsDataSet("Done")) {
			SetData("Done", true);
			Link.BroadcastOnAllLinks(self, msg, "SwitchLink");
		}
	}
}

// --------------------------------------------------------------------------------
// Plays a standard button sound when frobbed
class scpFrobBeep extends SqRootScript {
	function OnFrobWorldEnd() {
		Sound.PlaySchema(self, "button1");
	}
}

// --------------------------------------------------------------------------------
// Plays an error sound when frobbed
class scpFrobNope extends SqRootScript {
	function OnFrobWorldEnd() {
		Sound.PlaySchema(self, "no_invroom");
	}
}

// --------------------------------------------------------------------------------
// Stops player motion
class scpStopPlayer extends SqRootScript {
	function OnTurnOn() {
		Physics.SetVelocity("Player", vector());
	}
}

// --------------------------------------------------------------------------------
// Stops player motion once on level start
// (Sim message supposedly only sent once ever the first time a map loads, so no
// other checking should be needed)
class scpStopPlayerOnce extends SqRootScript {
	function OnSim() {
		Physics.SetVelocity("Player", vector());
	}
}

// --------------------------------------------------------------------------------
// Shoves player in direction set in Script: Shove
// Used to fix rick1, hydro2 shake stims not working by forcing full initialization
// of player physics.
class scpShovePlayer extends SqRootScript {
	function OnTurnOn() {
		Physics.SetVelocity("Player", GetProperty("Shove"));
	}
}


// --------------------------------------------------------------------------------
// Hides an AI from Spatially Aware until they leave their starting room
// Must start inside a room brush!
class scpStartHidden extends SqRootScript {
	function OnObjRoomTransit() {
		local roomID = message().ToObjId;
		if (!IsDataSet("StartRoom")) {
			SetData("StartRoom", roomID);
			SetProperty("MapObjIcon", "minvis");
		}
		else if (GetData("StartRoom") != roomID) {
			Property.Remove(self, "MapObjIcon");
			Property.SetSimple(self, "MapObjRotate", false); // sometimes necessary
			Object.RemoveMetaProperty(self, "Start Hidden");
		}
	}
}

// --------------------------------------------------------------------------------
// Converts radius stims on impacting projectiles to simulated contact damage.
// For use on objects too large for damage stims to reliably reach center.
class scpRadiusDamageSponge extends SqRootScript {
	function OnBeginScript() {
		if (Object.Exists(self)) {
			Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
			if (!IsDataSet("LastDmg")) {
				SetData("LastDmg", 0);
			}
		}
	}

	function OnEndScript() {
		Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
	}

	function OnDamage() {
		// record when most recent non-simulated damage was received
		if (message().culprit != 0) {
			SetData("LastDmg", ShockGame.SimTime());
		}
	}

	function OnPhysCollision() {
		local lnk, cLnk, kind, intensity;
		local proj = Object.Archetype(message().collObj);
		if (!Object.InheritsFrom(proj, "Projectile")) {
			return;
		}
		foreach (lnk in Link.GetAll("corpse", proj)) {
			foreach (cLnk in Link.GetAll("arSrcDesc", LinkDest(lnk))) {
				if (LinkTools.LinkGetData(cLnk, "Propagator") == 2) {
					kind = LinkDest(cLnk);
					intensity = LinkTools.LinkGetData(cLnk, "Intensity");
					// delay until after native stim processing
					PostMessage(self, "SimDmg", kind, intensity);
				}
			}
		}
	}

	function OnSimDmg() {
		local m = message();
		if (ShockGame.SimTime() - GetData("LastDmg") > 50) {
			ActReact.Stimulate(self, m.data, m.data2, 0);
		}
	}
}

// --------------------------------------------------------------------------------
// Shuffle positions of all objects linked to from object with this script
// - Switchlink fron host object to objects to be shuffled
// - Runs once on initial level load
// - Can be used with markers to randomize the location of a single object
// - Can be used with a blue room to randomize the type of a single object
// TODO: make this multiplayer-safe
// TOOD: skip items in player inventory
// TODO: add support for a "ShufflePos" marker that will get deleted after shuffling
class scpShuffle extends SqRootScript {
	function OnSim() {
		if (!scp.IsModEnabled("modItemRand")) {
			return;
		}
		local t, m, lnk, obj;
		local order = [];
		local objRef = [];
		local objPos = [];
		local objFac = [];
		local objDest = [];
		local i = 0;
		// cache pos/loc/container of every linked object
		foreach (lnk in Link.GetAll("SwitchLink", self, 0)) {
			order.push(i++);
			obj = LinkDest(lnk);
			objRef.push(obj);
			objPos.push(Object.Position(obj));
			objFac.push(Object.Facing(obj));
			objDest.push(LinkDest(Link.GetOne("~Contains", obj)));
		}
		// do the Fisher-Yates Shuffle
		m = order.len();
		while (m) {
			i = floor(scp.Rand(m--));
			t = order[m];
			order[m] = order[i];
			order[i] = t;
		}
		// process objects
		for (i = 0; i < order.len(); i++) {
			t = order[i];
			if (t != i) {
				obj = objRef[i];
				Object.Teleport(obj, objPos[t], objFac[t]);
				lnk = Link.GetOne("~Contains", obj);
				if (lnk) {
					Link.Destroy(lnk);
				}
				if (objDest[t]) {
					Link.Create("~Contains", obj, objDest[t]);
					Property.SetSimple(obj, "HasRefs", false);
				}
				else {
					Property.SetSimple(obj, "HasRefs", true);
				}
			}
		}
	}
}


// ================================================================================
//  DEBUG/TESTING SCRIPTS
// ================================================================================

// --------------------------------------------------------------------------------
// Makes tripwires visible in-game, checks that physics dimensions match model
// dimensions, valid links exist, and various other possible setup mistakes
class scpTripwireDebug extends SqRootScript {
	function OnBeginScript() {
		if (!Version.IsEditor() || !TRIPWIRE_DEBUG_ENABLE) {
			return;
		}
		// make visible in game mode
		SetProperty("RenderAlpha", 0.25);
		SetProperty("RenderType", 2); // unlit
		SetProperty("PickBias", -100); // necessary for egg tripwires
		// check for valid physics setup
		local objName = Object.GetName(self);
		local header = "WARNING: " + self + " (" + (objName != "" ? objName : ShockGame.GetArchetypeName(self)) + ") ";
		local scale = HasProperty("Scale") ? GetProperty("Scale") : vector(1, 1, 1);
		if (GetProperty("PhysType", "Type") != 0) {
			Debug.MPrint(header + "non-OBB physics type");
		}
		if (!HasProperty("PhysControl") || GetProperty("PhysControl", "Controls Active") != 24) {
			Debug.MPrint(header + "missing controls Location and/or Rotation");
		}
		if (!HasProperty("PhysDims")) {
			Debug.MPrint(header + "missing physics dimensions");
		}
		else {
			local size = GetProperty("PhysDims", "Size");
			local offs = GetProperty("PhysDims", "Offset 1");
			if (!isEqual(size.x, scale.x) || !isEqual(size.y, scale.y) || !isEqual(size.z, scale.z)) {
				Debug.MPrint(header + "physics size doesn't match object size");
			}
			if (offs.x != 0 || offs.y != 0 || offs.z != 0) {
				Debug.MPrint(header + "has physics offset");
			}
			if (Physics.HasPhysics(self) && !Physics.ValidPos(self)) {
				Debug.MPrint(header + "center in solid");
			}
		}
		// check for valid links (unless it's a pusher or a slayer)
		if (!Object.InheritsFrom(self, "Slay Tripwire") && !scp.BitTest(GetProperty("TripFlags"), 7) && Link.GetOne("SwitchLink", self) == 0) {
			Debug.MPrint(header + "has no switchlinks");
		}
	}

	function isEqual(size1, scale) {
		local size2 = scale * 4.0;
		return fabs(size1 - size2) < 0.01;
	}
}

// --------------------------------------------------------------------------------
// Displays entity damage info in the mono
// Place script on desired concrete or archetype
// For testing purposes only. Do not leave in shipping maps!
class scpDamageTest extends SqRootScript {
	function OnDamage() {
		local m = message();
		scp.Trace(ShockGame.GetArchetypeName(self) + " (" + self + "): " + m.damage + " \"" + Object.GetName(m.kind) + "\" damage from \"" + ShockGame.GetArchetypeName(m.culprit) + "\" @" + ShockGame.SimTime()+" ms");
	}
}

// --------------------------------------------------------------------------------
// Says hello. For testing whether an object exists, metaprop has been added, etc.
// For testing purposes only. Do not leave in shipping maps!
class scpHello extends SqRootScript {
	function OnBeginScript() {
		print(ShockGame.GetArchetypeName(self) + " (" + self + ") says hello!");
	}
}


// ================================================================================
//  SHARED SUPPORT FUNCTIONS
// ================================================================================

// --------------------------------------------------------------------------------
// Helper functions for the other SCP script classes
class scp extends SqRootScript {
	// Improved text display function
	// Combines functionality of AddText, AddTranslatableText, and AddTranslatableTextInt
	// Accepts:
	// - string ID
	// - string file
	// - string default if string not found (optional)
	// - value to be substituted for %d or %s in string (optional)
	function AddText(strID, strFile, strDefault = "", subVal = null) {
		local strText = Data.GetString(strFile, strID, strDefault);
		if (strText != "") {
			if (subVal != null) {
				local s = strText.find("%d");
				if (s == null) {
					s = strText.find("%s");
				}
				if (s != null) {
					strText = strText.slice(0, s) + subVal + strText.slice(s + 2);
				}
				else {
					print("WARN: String '" + strID + "' in '" + strFile + "' missing %d or %s");
				}
			}
			ShockGame.AddText(strText, "Player");
		}
		else {
			print("ERROR: String '" + strID + "' not found in '" + strFile + "'");
		}
	}

	// consume an inventory item and optionally play a sound
	// pass "*" to play the object's activation schema
	// handles both stacked and non-stacked items
	function Consume(obj, schema) {
		if (Property.Possessed(obj, "StackCount")) {
			Container.StackAdd(obj, -1);
			if (Property.Get(obj, "StackCount") == 0) {
				ShockGame.DestroyInvObj(obj);
			}
		}
		else {
			ShockGame.DestroyInvObj(obj);
		}
		if (typeof schema == "string") {
			if (schema == "*") {
				Sound.PlayEnvSchema(obj, "Event Activate", 0, 0, eEnvSoundLoc.kEnvSoundAmbient);
			}
			else {
				Sound.PlaySchemaAmbient(obj, schema);
			}
		}
	}

	// report if object is in any of the equip slots
	function IsEquipped(selfID) {
		return selfID == ShockGame.Equipped(ePlayerEquip.kEquipArmor) ||
			selfID == ShockGame.Equipped(ePlayerEquip.kEquipSpecial) ||
			selfID == ShockGame.Equipped(ePlayerEquip.kEquipSpecial2);
	}

	// check whether a minimod is enabled
	// (this hits the filesystem so DO NOT call in a loop; cache result if possible)
	function IsModEnabled(modfile) {
		local fname = string();
		return Engine.FindFileInPath("resname_base", "scriptdata\\" + modfile, fname);
	}

	// silence any Xerxes security announcements from ecologies
	// requires scpEcologyHelper on all alert ecologies to build the list of ecology IDs
	function SilenceEcoXerxes() {
		local i = 0;
		local prefix = "ecoObjID";
		while (Quest.Exists(prefix + i)) {
			Sound.HaltSchema(Quest.Get(prefix + i));
			i++;
		}
	}

	// return object at first link found of the specified flavor to object with the specified property
	function GetLinkedWith(flavor, prop, from) {
		local lnk, obj;
		local foundObj = 0;
		// sanity check
		if (from == 0) {
			return 0;
		}
		// scan all links of the specified flavor
		foreach (lnk in Link.GetAll(flavor, from, 0)) {
			obj = LinkDest(lnk);
			if (Property.Possessed(obj, prop)) {
				foundObj = obj;
				break;
			}
		}
		return foundObj;
	}

	// print flavor and destination of all links from/to specified object
	function DumpLinks(obj) {
		local lnk, slnk, dest;
		if (typeof obj == "string") {
			obj = ObjID(obj);
		}
		if (!obj) {
			print("ERROR: Requested DumpLinks object does not exist.");
			return;
		}
		print(obj + " (" + (obj < 0 ? Object.GetName(obj) : ShockGame.GetArchetypeName(obj)) + ") links:");
		foreach (lnk in Link.GetAll(0, obj)) {
			slnk = sLink(lnk);
			dest = slnk.dest;
			print("   " + LinkTools.LinkKindName(slnk.flavor) + ": " + dest + " (" + (dest < 0 ? Object.GetName(dest) : ShockGame.GetArchetypeName(dest)) + ")");
		}
	}

	// return name of current map, without extension, normalized to lowercase
	function MapName() {
		local mapRef = string();
		Version.GetMap(mapRef);
		local map = mapRef.tostring().tolower();
		local s = map.find(".mis");
		return map.slice(0, s);
	}

	// return how many nanites player currently has
	// (there is probably a better way to do this)
	function PlayerNanites() {
		local lnk;
		local nanites = 0;
		foreach (lnk in Link.GetAll("Contains", ObjID("Player"), 0)) {
			if (Object.InheritsFrom(LinkDest(lnk), "FakeNanites")) {
				nanites = Property.Get(LinkDest(lnk), "StackCount");
				break;
			}
		}
		return nanites;
	}

	// return distance squared between two points
	function DistanceSq(v1, v2) {
		return ((v1.x - v2.x) * (v1.x - v2.x) + (v1.y - v2.y) * (v1.y - v2.y) + (v1.z - v2.z) * (v1.z - v2.z));
	}

	// return a random float between 0 and 1
	// accepts optional multiplier
	function Rand(mult = 1.0) {
		return (rand().tofloat() / RAND_MAX) * mult;
	}
	
	// return a properly rounded number
	function Round(n) {
		n = n.tofloat();
		return (n < 0 ? (n - 0.5) : (n + 0.5)).tointeger().tofloat();
	}

	// return a numeric value within the specified min and max range
	function Clamp(val, min, max) {
		if (val > max) {
			return max;
		}
		else if (val < min) {
			return min;
		}
		else {
			return val;
		}
	}

	// return whether specified bit is set
	function BitTest(bitfield, idx) {
		return bitfield >> idx & 1;
	}

	// display a message onscreen and in mono
	function Trace(msg) {
		print(msg);
		ShockGame.AddText(msg, "Player");
	}
}
