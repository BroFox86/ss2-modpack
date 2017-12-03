// ================================================================================
// Shock Community Patch Scripts
// ================================================================================
// scpPlayerScript
// scpEnableDeathTaunts
// scpCameraHelper
// scpSelfDestruct
// scpReaverTeleport
// scpReaverFlash
// scpWormHeartImplant
// scpWormSkin
// scpTraitHelper
// scpFrobBeep
// scpFrobNope
// scpCheeseborger
// scpNavMarker
// scpCompass
// scpMiniGameCart
// scpHealingStation
// scpWrench
// scpStopPlayer
// scpStopPlayerOnce
// scpManyFadeIn
// scpLightHelper
// scpKeypadHelper
// scpApparition
// scpElevatorHelper
// scpElevatorPanel
// scpDoor
// scpShodanDoor
// scpShodanProp
// scp.AddText
// scp.IsEquipped
// scp.Trace
// ================================================================================

// ================================================================================
// Catch-all player stuff
class scpPlayerScript extends SqRootScript {
	function OnBeginScript() {
		initTraits();
	}

	// implement unused death taunts
	// mode 0=Xerxes; 1=Xerxes/Many; 2=Xerxes/Many/SHODAN; 3=Many/SHODAN; 4=Many; 5=SHODAN
	function OnSlain() {
		if (Quest.Get("DeathTaunts")) {
			Sound.PlaySchemaAmbient(self, "PlayerDeath" + Quest.Get("DeathMode"));
		}
	}

	function OnTraitGained() {
		initTraits();
	}

	function initTraits() {
		// make Spatially Aware OS upgrade display all enemies on automap
		if (ShockGame.HasTrait("Player", eTrait.kTraitAutomap)) {
			local baddies = ["Robots", "Hybrids", "Annelids", "Turrets", "Cyborgs", "Security Camera", "Shodan Avatars"];
			foreach (archetype in baddies) {
				Property.SetSimple(archetype, "MapObjIcon", "mevil");
			}
			// hold the eggs
			Property.SetSimple("Eggs", "MapObjIcon", "");
		}
	}
}

// ================================================================================
// Set qvar to enable death taunts
class scpEnableDeathTaunts extends SqRootScript {
	function OnBeginScript() {
		Quest.Set("DeathTaunts", 1, eQuestDataType.kQuestDataCampaign);
	}
}

// ================================================================================
// Visibly disables security cameras while security is hacked
// (requires custom model camblk)
class scpCameraHelper extends SqRootScript {
	function OnBeginScript() {
		if (IsDataSet("HackTimer")) {
			KillTimer(GetData("HackTimer"));
		}
		// randomly space out the timer so every camera on the level isn't
		// calling this at the same time
		if (GetProperty("HitPoints") > 0) {
			SetData("HackTimer", SetOneShotTimer("HackCheck", Data.RandFlt0to1() * 2));
		}
	}
	
	function OnSlain() {
		KillTimer(GetData("HackTimer"));
		if (GetData("SecHacked")) {
			clearHacked(FALSE);
		}
	}

	function OnAlertness() {
		if (GetData("SecHacked")) {
			// fighting the CameraAlert script
			SetOneShotTimer("ResetModel", 0.1)
		}
	}

	function OnTimer() {
		if (message().name == "HackCheck") {
			if (ShockGame.OverlayOn(kOverlayHackIcon)) {
				if (!GetData("SecHacked")) {
					SetData("SecHacked", TRUE);
					SetProperty("ModelName", "camblk");
					SetProperty("SelfIllum", 0);
					SetProperty("AI_Vision", 0);
					SetProperty("AI_Frozen", "Start Time", 0);
					SetProperty("AI_Frozen", "Duration", 2000000000);
				}
			}
			else if (GetData("SecHacked")) {
				clearHacked(TRUE);
			}
			SetData("HackTimer", SetOneShotTimer("HackCheck", 2));
		}
		else if (message().name == "ResetModel") {
			SetProperty("ModelName", "camblk");
		}
	}

	function clearHacked(changeModel) {
		SetData("SecHacked", FALSE);
		if (changeModel) {
			SetProperty("ModelName", "camgrn");
		}
		Property.Remove(self, "SelfIllum");
		Property.Remove(self, "AI_Vision");
		Property.Remove(self, "AI_Frozen");
	}
}

// ================================================================================
// place on marker that Korenchkin reaver should be teleported to; works once
class scpAnatolyTeleport extends SqRootScript {
	function OnTurnOn() {
		if (GetData("Used")) {
			return;
		}
		SetData("Used", TRUE);
		local link = Link.GetOne("SwitchLink", self);
		if (link) {
			local DstObj = sLink(link).dest;
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

// ================================================================================
// flash the screen when a psi reaver brain gets killed
class scpReaverFlash extends SqRootScript {
	function OnTurnOn() {
		ShockGame.StartFadeIn(1000, 255, 200, 180)
	}
}

// ================================================================================
// destroys self on sim start; use to block player if Squirrel isn't loaded
class scpSelfDestruct extends SqRootScript {
	function OnSim() {
		Object.Destroy(self);
	}
}

// ================================================================================
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
		Activate(FALSE);
	}

	function OnEndScript() {
		StopTimers();
	}

	// sent to implant when equipped
	function OnTurnOn() {
		Activate(TRUE);
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
		SetData("Active", TRUE);
		SetData("Betty", FALSE);
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
		SetData("Active", FALSE);
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
			SetData("Betty", FALSE);
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
			Activate(FALSE);
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
						SetData("Betty", TRUE);
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

// ================================================================================
// Replacement WormSkin armor script that fixes it breaking across map transitions.
// Adds support for setting drain rate via Obj/Energy/Drain Rate.
class scpWormSkin extends SqRootScript {
	function OnBeginScript() {
		if (scp.IsEquipped(self)) {
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

// ================================================================================
// Notifies player object when an OS upgrade machine has been used, and removes
// HUD brackets.
class scpTraitHelper extends SqRootScript {
	function OnUsed() {
		//Sound.PlaySchemaAmbient(self, "boot_sw");
		SetProperty("HUDSelect", FALSE);
		// TODO: stop trainer opening again (abort stims here? add metaprop? kill tweq?)
		// inform player that he has a new power
		PostMessage("Player", "TraitGained");
	}
}

// ================================================================================
// Plays a standard button sound when frobbed.
class scpFrobBeep extends SqRootScript {
	function OnFrobWorldEnd() {
		Sound.PlaySchema(self, "button1");
	}
}

// ================================================================================
// Plays an error sound when frobbed.
class scpFrobNope extends SqRootScript {
	function OnFrobWorldEnd() {
		Sound.PlaySchema(self, "no_invroom");
	}
}

// ================================================================================
// Enhanced cheeseborger (diagnostic/repair module) script
// Fixes broken schema playing on use.
class scpCheeseborger extends SqRootScript {
	function OnFrobInvEnd() {
		if (ShockGame.HasTrait("Player", eTrait.kTraitBorg)) {
			ShockGame.HealObj(message().Frobber, 15);
			Sound.PlaySchemaAmbient(self, "act_cheese");
			// consume
			Container.StackAdd(self, -1);
			if (GetProperty("StackCount") == 0) {
				ShockGame.DestroyInvObj(self);
			}
		}
		else {
			Sound.PlaySchemaAmbient(self, "no_invroom");
		}
	}
}

// ================================================================================
// Enhances nav marker object with UI beep and message when created, and ability to
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

// ================================================================================
// Enhanced compass script
// Now plays UI sound when toggled.
class scpCompass extends SqRootScript {
	function OnToggle() {
		Sound.PlaySchemaAmbient(self, "btabs");
		SetProperty("CameraObj", "Draw?", !GetProperty("CameraObj", "Draw?"));
	}

	function OnHide() {
		SetProperty("CameraObj", "Draw?", FALSE);
	}
}

// ================================================================================
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
		Networking.Broadcast("PirateGameCart", GetProperty("MiniGames"));
		Sound.PlaySchemaAmbient(self, "boot_sw");
		//TODO: display name of game added?
		scp.AddText("MFDGameCart", "misc", "MFD game cartridge installed.");
		ShockGame.DestroyInvObj(self);
	}
}

// ================================================================================
// Enhanced HealingStation script
// - Now removes toxins.
// - Removes radiation (and toxins) when player at full health.
// - Displays message when player doesn't need healing.
// When using this remove NVDetoxTrap from player object.
class scpHealingStation extends SqRootScript {
	static healCost = 5; // possibly make this based on difficulty
	function OnFrobWorldEnd() {
		local Frobber = message().Frobber;
		local hp = Property.Get(Frobber, "HitPoints");
		local hpMax = Property.Get(Frobber, "MAX_HP");
		if (hpMax > hp || Property.Get(Frobber, "RadLevel") > 0 || Property.Get(Frobber, "Toxin") > 0) {
			if (ShockGame.PayNanites(healCost) == S_OK) {
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

// ================================================================================
// Enhances wrench script to also repair turrets.
class scpWrench extends SqRootScript {
	function OnFrobToolEnd() {
		ShockGame.PreventSwap();
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
				hp += playerMaintSkill * 10.0;
				if (hp > 100.0) {
					hp = 100.0;
				}
				Property.Set(fixObj, "GunState", "Condition (%)", hp);
				consumeTool();
			}
		}
		// turrets
		else if (Object.InheritsFrom(fixObj, "Turrets")) {
			hp = Property.Get(fixObj, "HitPoints");
			maxHP = Property.Get(fixObj, "MAX_HP");
			if (playerMaintSkill < objSkillRequired) {
				scp.AddText("WrenchSkillReq", "misc", "", objSkillRequired);
			}
			else if (hp >= maxHP) {
				scp.AddText("WrenchUnused", "misc");
			}
			else {
				// repair turret 5 HP per point of maint skill (default turrets have a max HP of 48)
				hp += playerMaintSkill * 5;
				if (hp > maxHP) {
					hp = maxHP;
				}
				Property.SetSimple(fixObj, "HitPoints", hp);
				consumeTool();
			}
		}
		// non-repairable
		else {
			scp.AddText("WrenchOnNonGun", "misc");
		}
	}

	function OnFrobInvEnd() {
		scp.AddText("HelpWrench", "misc");
	}

	function consumeTool() {
		// decrease stack count
		Container.StackAdd(self, -1);
		if (GetProperty("StackCount") == 0) {
			ShockGame.DestroyInvObj(self);
		}
		// play success sound
		Sound.PlayEnvSchema(self, "Event Activate", 0, 0, eEnvSoundLoc.kEnvSoundAmbient);
	}
}

// ================================================================================
// Stops player motion.
class scpStopPlayer extends SqRootScript {
	function OnTurnOn() {
		Physics.SetVelocity("Player", vector());
	}
}

// ================================================================================
// Stops player motion once on level start.
// (Sim message supposedly only sent once ever the first time a map loads, so no
// other checking should be needed)
class scpStopPlayerOnce extends SqRootScript {
	function OnSim() {
		Physics.SetVelocity("Player", vector());
	}
}

// ================================================================================
// Starts level black then slowly fades in.
// (fade functions only work in DromEd with no_endgame disabled)
// (must do battle with player script, which always starts with a fade-in)
class scpManyFadeIn extends SqRootScript {
	function OnSim() {
		if (!IsDataSet("Done")) {
			SetData("Done", TRUE);
			ShockGame.StartFadeOut(1, 0, 0, 0);
			SetOneShotTimer("StartBlack", 0.05);
		}
	}

	function OnTimer() {
		if (message().name == "StartBlack") {
			ShockGame.StartFadeOut(1, 0, 0, 0);
			SetOneShotTimer("FadeIn", 3.0);
		}
		else if (message().name == "FadeIn") {
			ShockGame.StartFadeIn(10000, 0, 0, 0);
		}
	}
}

// ================================================================================
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
// Adds success/failure sound effects to keypads.
// Adds ability to act as a lock (link door tripwire to keypad).
// Adds optional locked message:
//   Use property Script/Locked Message
//   Add string to lockmsg.str
class scpKeypadHelper extends SqRootScript {
	function OnKeypadDone() {
		if (message().code == GetProperty("KeypadCode")) {
			SetData("Opened", TRUE);
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

	function OnReset() {
		ClearData("Opened");
	}

	function OnNetOpened() {
		SetData("Opened", TRUE);
	}

	function OnHackSuccess() {
		SetData("Opened", TRUE);
	}

	function playSuccess() {
		Sound.PlaySchema(self, "use_cardslot");
	}
}

// ================================================================================
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
	static FadeOutTime = 2;
	static FadeInt = 0.05;

	function OnApparBegin() {
		// teleport to ApparStart link dest, if available
		local link = Link.GetOne("ApparStart", self);
		if (link) {
			Object.Teleport(self, Object.Position(sLink(link).To()), Object.Facing(sLink(link).To()));
		}
		// add world ref and initiate fade-in
		SetProperty("RenderAlpha", 0);
		SetProperty("HasRefs", TRUE);
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
		SetProperty("HasRefs", FALSE);
	}

	function OnTimer() {
		local msg = message().name;
		if (msg == "ApparOut") {
			// fade-out
			local alpha = GetData("Alpha");
			if (alpha > 0.0) {
				alpha -= MaxAlpha / (FadeOutTime / FadeInt);
				if (alpha < 0.0) {
					alpha = 0.0;
				}
				SetData("Alpha", alpha);
				alpha = Flicker(alpha);
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
			local alpha = GetData("Alpha");
			if (alpha < MaxAlpha) {
				alpha += MaxAlpha / (FadeInTime / FadeInt);
				if (alpha > MaxAlpha) {
					alpha = MaxAlpha;
				}
				SetData("Alpha", alpha);
				alpha = Flicker(alpha);
				Property.SetSimple(self, "RenderAlpha", alpha);
				Property.SetSimple(self, "SelfLit", alpha / MaxAlpha * 100.0);
				SetOneShotTimer("ApparIn", FadeInt);
			}
			else {
				// done fading in
				SetData("Timer", SetOneShotTimer("ApparFlick", 0.1));
			}
		}
		else if (msg == "ApparFlick") {
			// flicker
			local alpha = Flicker(MaxAlpha);
			Property.SetSimple(self, "RenderAlpha", alpha);
			Property.SetSimple(self, "SelfLit", alpha / MaxAlpha * 100.0);
			SetData("Timer", SetOneShotTimer("ApparFlick", 0.1));
		}
	}

	// add or subtract a random amount from passed alpha
	function Flicker(alpha) {
		local flickAdj = 0.1 * alpha / MaxAlpha;
		return alpha + (flickAdj * (rand().tofloat() / RAND_MAX)) - (flickAdj / 2.0);
	}
}

// ================================================================================
// Elevator door helper
//
// Prevents elevator doors from closing on player by re-opening them if player gets
// close while they're closing. Prevents elevator doors from closing on player
// while standing between doors. Closes doors when elevator control panel frobbed.
//
// Setup:
// - Create tripwire (-305) spanning elevator doors, phydims 5x5x5, floored.
// - Add this script to tripwire. Check do not inherit.
// - Add scpDoor script to elevator doors. Check do not inherit.
// - Link tripwire to elevator doors.
// - Link elevator control panel to tripwire.
// - Add scpElevatorPanel script to control panel.
class scpElevatorHelper extends SqRootScript {
	function OnBeginScript() {
		Physics.SubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
	}

	function OnEndScript() {
		Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
	}

	// when player enters trigger area, force doors back open if they're not completely closed
	function OnPhysEnter() {
		local status;
		local msg = message();
		if (!Object.InheritsFrom(msg.transObj, "Player") || !newPhysEvent(msg)) {
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
		if (!Object.InheritsFrom(msg.transObj, "Player") || !newPhysEvent(msg)) {
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
			return FALSE;
		}
		else {
			SetData("LastMsg", msg.message);
			SetData("LastObj", msg.transObj);
			return TRUE;
		}
	}
}

// ================================================================================
// Relays panel frob message to elevator doors controller
class scpElevatorPanel extends SqRootScript {
	function OnFrobWorldEnd() {
		Link.BroadcastOnAllLinks(self, "FrobPanel", "SwitchLink");
	}
}

// ================================================================================
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
		Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
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
		if (ShockGame.CheckLocked(self, TRUE, message().Frobber)) {
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
		SetData("FastMode", FALSE);
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
		SetData("FastMode", TRUE);
		if (HasProperty("TransDoor")) {
			SetProperty("TransDoor", "Base Speed", 9999);
		}
		else if (HasProperty("RotDoor")) {
			SetProperty("RotDoor", "Base Speed", 9999);
		}
	}
}

// ================================================================================
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
		SetOneShotTimer("DoorClose", 3);
	}
	
	function OnTimer() {
		if (message().name == "DoorClose") {
			if (HasProperty("TransDoor")) {
				SetProperty("TransDoor", "Base Speed", 999);
				SetProperty("BashFactor", 0);
			}
			Door.CloseDoor(self);
			PostMessage(self, "FadeIn");
		}
	}
	
	function OnPhantomOn() {
		Property.Remove(self, "RenderAlpha");
	}
}

// ================================================================================
// Prop fader for SHODAN transformation sequence
// Works in conjunction with NVPhantomTrap
class scpShodanProp extends SqRootScript {
	function OnTurnOff() {
		SetOneShotTimer("FadeDelay", 3);
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


// ================================================================================
// Helper functions for the other SCP script classes
class scp extends SqRootScript {
	// Improved text display function
	// Combines functionality of AddText, AddTranslatableText, and AddTranslatableTextInt
	// Accepts:
	// - string ID
	// - string file
	// - string default if string not found (optional)
	// - value to be substituted for %d in string (optional)
	function AddText(strID, strFile, strDefault = "", dVal = null) {
		local strText = Data.GetString(strFile, strID, strDefault);
		if (strText != "") {
			if (dVal != null) {
				local s = strText.find("%d");
				if (s != null) {
					strText = strText.slice(0, s) + dVal + strText.slice(s + 2);
				}
				else {
					print("WARN: String '" + strID + "' in '" + strFile + "' missing %d");
				}
			}
			ShockGame.AddText(strText, "Player");
		}
		else {
			print("ERROR: String '" + strID + "' not found in '" + strFile + "'");
		}
	}
	
	// reports if object is in any of the equip slots
	function IsEquipped(selfID) {
		return selfID == ShockGame.Equipped(ePlayerEquip.kEquipArmor) ||
			selfID == ShockGame.Equipped(ePlayerEquip.kEquipSpecial) ||
			selfID == ShockGame.Equipped(ePlayerEquip.kEquipSpecial2);
	}
	
	// just display a message onscreen and in mono
	function Trace(msg) {
		print(msg);
		ShockGame.AddText(msg, "Player");
	}
}
