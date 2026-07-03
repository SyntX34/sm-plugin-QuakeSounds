#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

#define ANNOUNCE_DELAY				30.0
#define JOIN_DELAY					2.0
#define QUAKE_TEXT_DELAY 			0.12
#define NH_DOUBLEKILL_KILLS     	2
#define NH_TRIPLEKILL_KILLS     	3
#define NH_MULTIKILL_KILLS      	4
#define NH_MEGAKILL_KILLS       	5
#define NH_HEXAKILL_KILLS       	6
#define NH_HEPTAKILL_KILLS      	7
#define NH_OCTAKILL_KILLS       	8
#define NH_ENNEAKILL_KILLS      	9
#define NH_DECAKILL_KILLS       	10
#define NH_RAMPAGE_KILLS        	10
#define NH_DOMINATING_KILLS     	20
#define NH_UNSTOPPABLE_KILLS    	30
#define NH_GODLIKE_KILLS        	40
#define NH_MONSTERKILL_KILLS    	50
#define NH_ULTRAKILL_KILLS      	60

#define NH_HEADHUNTER_HEADSHOTS		7
#define NH_ASSIST_MIN_DAMAGE		50.0
#define NH_ASSIST_WINDOW			3.0

#define MAX_NUM_SETS				255
#define MAX_NUM_KILLS				999

#define PATH_CONFIG_QUAKE_SET		"configs/quake/sets.cfg"
#define PATH_CONFIG_QUAKE_SOUNDS	"configs/quake/sets"

enum SoundCategory
{
	CATEGORY_NONE = 0,
	CATEGORY_HEADSHOT,
	CATEGORY_KILLSTREAK_SHORT,  // Double kill, triple kill, multi-kill
	CATEGORY_KILLSTREAK_LONG,   // Monsterkill, ultrakill, etc.
	CATEGORY_SPECIAL,           // First blood, grenade, knife
	CATEGORY_COMBO,
	CATEGORY_JOIN,
	CATEGORY_ROUND
}

enum NHQuakeEvent
{
	NH_EVENT_NONE = 0,
	NH_EVENT_FIRSTBLOOD,
	NH_EVENT_HEADSHOT,
	NH_EVENT_GOODSHOT,
	NH_EVENT_NICESHOT,
	NH_EVENT_HEADHUNTER,
	NH_EVENT_ASSIST,
	NH_EVENT_JUMPSHOT,
	NH_EVENT_WALLSHOT,
	NH_EVENT_GRENADE,
	NH_EVENT_KNIFE,
	NH_EVENT_DOUBLEKILL,
	NH_EVENT_TRIPLEKILL,
	NH_EVENT_MULTIKILL,
	NH_EVENT_MEGAKILL,
	NH_EVENT_HEXAKILL,
	NH_EVENT_HEPTAKILL,
	NH_EVENT_OCTAKILL,
	NH_EVENT_ENNEAKILL,
	NH_EVENT_DECAKILL,
	NH_EVENT_DOMINATING,
	NH_EVENT_RAMPAGE,
	NH_EVENT_UNSTOPPABLE,
	NH_EVENT_GODLIKE,
	NH_EVENT_MONSTERKILL,
	NH_EVENT_ULTRAKILL
}

public Plugin myinfo = {
	name = "Quake Sounds",
	author = "Spartan_C001, maxime1907, .Rushaway, +SyntX, Denied",
	description = "This version of Quakesounds are heavily modified for NH ZR",
	version = "4.3.1",
	url = "https://novazombie.com/",
}

// Sound Sets
int g_iNumSets = 0;
char g_sSetsName[MAX_NUM_SETS][PLATFORM_MAX_PATH];

// Sound Files
char headshotSound[MAX_NUM_SETS][MAX_NUM_KILLS][PLATFORM_MAX_PATH];
char goodshotSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char niceshotSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char headhunterSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char assistSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char jumpshotSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char wallshotSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char grenadeSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char selfkillSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char roundplaySound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char knifeSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char killSound[MAX_NUM_SETS][MAX_NUM_KILLS][PLATFORM_MAX_PATH];
char firstbloodSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char teamkillSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char comboSound[MAX_NUM_SETS][MAX_NUM_KILLS][PLATFORM_MAX_PATH];
char joinSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];

// Sound Configs
int headshotConfig[MAX_NUM_SETS][MAX_NUM_KILLS];
int goodshotConfig[MAX_NUM_SETS];
int niceshotConfig[MAX_NUM_SETS];
int headhunterConfig[MAX_NUM_SETS];
int assistConfig[MAX_NUM_SETS];
int jumpshotConfig[MAX_NUM_SETS];
int wallshotConfig[MAX_NUM_SETS];
int grenadeConfig[MAX_NUM_SETS];
int selfkillConfig[MAX_NUM_SETS];
int roundplayConfig[MAX_NUM_SETS];
int knifeConfig[MAX_NUM_SETS];
int killConfig[MAX_NUM_SETS][MAX_NUM_KILLS];
int firstbloodConfig[MAX_NUM_SETS];
int teamkillConfig[MAX_NUM_SETS];
int comboConfig[MAX_NUM_SETS][MAX_NUM_KILLS];
int joinConfig[MAX_NUM_SETS];
float g_fVolume = 1.0;

// Kill Streaks
int g_iTotalKills = 0;
int g_iConsecutiveKills[MAXPLAYERS+1];
int g_iComboScore[MAXPLAYERS+1];
int g_iConsecutiveHeadshots[MAXPLAYERS+1];
float g_fLastKillTime[MAXPLAYERS+1];
float g_fAssistDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
float g_fAssistLastDamageTime[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool g_bRoundStarted = false;

// Anti-spam cooldowns
float g_fLastSoundTime[MAXPLAYERS+1];
float g_fLastHeadshotTime[MAXPLAYERS+1];
float g_fLastKillStreakTime[MAXPLAYERS+1];
float g_fLastSpecialTime[MAXPLAYERS+1];
SoundCategory g_iLastSoundCategory[MAXPLAYERS+1];
int g_iKillingSpreeThreshold = NH_RAMPAGE_KILLS;
int g_iUnstoppableThreshold = NH_UNSTOPPABLE_KILLS;
int g_iGodlikeThreshold = NH_GODLIKE_KILLS;
int g_iMonsterkillThreshold = NH_MONSTERKILL_KILLS;
int g_iUltrakillThreshold = NH_ULTRAKILL_KILLS;

int g_iDoubleKillThreshold = NH_DOUBLEKILL_KILLS;
int g_iTripleKillThreshold = NH_TRIPLEKILL_KILLS;
int g_iMultiKillThreshold = NH_MULTIKILL_KILLS;
int g_iMegaKillThreshold = NH_MEGAKILL_KILLS;

// Cooldown times (in seconds)
float g_fHeadshotCooldown = 0.5;
float g_fKillStreakCooldown = 1.0;
float g_fSpecialCooldown = 2.0;
float g_fGeneralCooldown = 0.3;  // Minimum time between any sounds
bool g_bSoundPlaying[MAXPLAYERS+1];
bool g_bGlobalSoundPlaying;
Handle g_hSoundTimer[MAXPLAYERS+1];
Handle g_hGlobalSoundTimer;
char g_sCurrentSound[MAXPLAYERS+1][PLATFORM_MAX_PATH];
char g_sCurrentGlobalSound[PLATFORM_MAX_PATH];
float g_fSoundDuration[MAXPLAYERS+1];
float g_fSoundStartTime[MAXPLAYERS+1];
float g_fGlobalSoundStartTime;
float g_fSoundCooldown = 5.0;

// Preferences
Handle g_hQuakeSettings = INVALID_HANDLE;
enum NotifyMode { NOTIFY_TEXT = 0, NOTIFY_OVERLAY = 1, NOTIFY_DISABLED = 2 }
NotifyMode g_iNotifyMode[MAXPLAYERS + 1];
int g_iSound[MAXPLAYERS + 1] = {0, ...}, g_iSoundPreset[MAXPLAYERS + 1] = {0, ...};
float g_fClientVolume[MAXPLAYERS + 1] = {1.0, ...};

float g_fLastAssistTime[MAXPLAYERS+1];
const float ASSIST_SOUND_COOLDOWN = 10.0;
int g_iLastKillStreakIndex[MAXPLAYERS+1];

ConVar g_cvar_Announce;
ConVar g_cvar_Text;
ConVar g_cvar_Sound;
ConVar g_cvar_SoundPreset;
ConVar g_cvar_Volume;
ConVar g_cvar_TeamKillMode;
ConVar g_cvar_ComboTime;
ConVar g_cvar_SelfKill;
ConVar g_cvar_TeamKill;
ConVar g_cvar_AntiSpam;
ConVar g_cvar_HeadshotCooldown;          
ConVar g_cvar_KillStreakCooldown;        
ConVar g_cvar_SpecialCooldown;        
ConVar g_cvar_GeneralCooldown;      
ConVar g_cvar_SoundQueueMode;
ConVar g_cvar_SoundBroadcastMode;
ConVar g_cvar_SoundCooldown;
ConVar g_cvar_OverlayEnable;
ConVar g_cvar_OverlayDuration;
ConVar g_cvar_OverlayFolder;

Handle g_hOverlayTimer[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
Handle g_hOverlayRefreshTimer[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
int g_iOverlaySerial[MAXPLAYERS + 1];
char g_sActiveOverlayName[MAXPLAYERS + 1][64];
Handle g_hQuakeTextTimer[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
int g_iQuakeTextSerial[MAXPLAYERS + 1];

EngineVersion g_evGameEngine;

bool g_bLate = false;

enum struct SoundDurationInfo
{
    char pattern[32];
    float duration;
}

SoundDurationInfo g_SoundDurations[] = {
    {"monsterkill", 4.5},
    {"ultrakill", 4.0},
    {"godlike", 3.8},
    {"unstoppable", 3.5},
    {"dominating", 3.2},
    {"killingspree", 3.0},
    {"firstblood", 2.5},
    {"headshot", 1.8},
    {"doublekill", 2.2},
    {"triplekill", 2.4},
    {"multikill", 2.6},
    {"megakill", 2.8},
    {"combo", 2.0},
    {"grenade", 2.0},
    {"knife", 2.0},
    {"selfkill", 2.0},
    {"teamkill", 2.0},
    {"round", 3.0},
    {"join", 2.0}
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	g_evGameEngine = GetEngineVersion();
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("plugin.quakesounds");

	g_cvar_Announce = CreateConVar("sm_quakesounds_announce", "1", "Sets whether to announcement to clients as they join, 0=Disabled, 1=Enabled.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvar_Text = CreateConVar("sm_quakesounds_text", "0", "Default notification mode for new users: 0=Text, 1=Overlays, 2=Disabled.", FCVAR_NONE, true, 0.0, true, 2.0);
	g_cvar_Sound = CreateConVar("sm_quakesounds_sound", "1", "Default sound setting for new users, 0=Disable 1=Enable.", FCVAR_NONE, true, 0.0, true, 255.0);
	g_cvar_Volume = CreateConVar("sm_quakesounds_volume", "1.0", "Default sound volume for new users: should be a number between 0.0 and 1.0.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvar_TeamKillMode = CreateConVar("sm_quakesounds_teamkill_mode", "0", "Teamkiller Mode; 0=Normal, 1=Team-Kills count as normal kills.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvar_ComboTime = CreateConVar("sm_quakesounds_combo_time", "2.0", "Max time in seconds between kills to count as combo; 0.0=Minimum, 2.0=Default", FCVAR_NONE, true, 0.0);
	g_cvar_SelfKill = CreateConVar("sm_quakesounds_selfkill", "1", "Enable/Disable selfkill sounds; 0=Disabled, 1=Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvar_TeamKill = CreateConVar("sm_quakesounds_teamkill", "1", "Enable/Disable teamkill sounds; 0=Disabled, 1=Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvar_AntiSpam = CreateConVar("sm_quakesounds_antispam", "0", "Enable anti-spam features (cooldowns and higher thresholds), 0=Disabled, 1=Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvar_HeadshotCooldown = CreateConVar("sm_quakesounds_headshot_cooldown", "0.0", "Cooldown in seconds between headshot sounds", FCVAR_NONE, true, 0.0, true, 5.0);
	g_cvar_KillStreakCooldown = CreateConVar("sm_quakesounds_killstreak_cooldown", "0.0", "Cooldown in seconds between kill streak sounds", FCVAR_NONE, true, 0.0, true, 5.0);
	g_cvar_SpecialCooldown = CreateConVar("sm_quakesounds_special_cooldown", "0.0", "Cooldown in seconds between special sounds", FCVAR_NONE, true, 0.0, true, 5.0);
	g_cvar_GeneralCooldown = CreateConVar("sm_quakesounds_general_cooldown", "0.0", "Minimum time in seconds between any quake sounds", FCVAR_NONE, true, 0.0, true, 5.0);
	g_cvar_SoundQueueMode = CreateConVar("sm_quakesounds_queue_mode", "1", "Sound queue mode: 0=Cooldown-based (old method), 1=Duration-based (wait for sound to finish + cooldown)", FCVAR_NONE, true, 0.0, true, 1.0);
    g_cvar_SoundBroadcastMode = CreateConVar("sm_quakesounds_broadcast_mode", "0", "Sound broadcast mode: 0=Play to individual clients only, 1=Broadcast to all clients (global sounds)", FCVAR_NONE, true, 0.0, true, 1.0);
    g_cvar_SoundCooldown = CreateConVar("sm_quakesounds_sound_cooldown", "0.0", "Cooldown in seconds between sounds when using queue mode", FCVAR_NONE, true, 0.0, true, 30.0);
    g_cvar_OverlayEnable = CreateConVar("sm_quakesounds_overlay_enable", "1", "Enable kill image overlays. 0=Disabled, 1=Enabled.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvar_OverlayDuration = CreateConVar("sm_quakesounds_overlay_duration", "2.0", "How long kill image overlays stay on screen.", FCVAR_NONE, true, 0.1, true, 10.0);
	g_cvar_OverlayFolder = CreateConVar("sm_quakesounds_overlay_folder", "novahunterz/quakecso", "Material folder for kill overlays, relative to materials/. Do not include materials/ or file extension.", FCVAR_NONE);

	g_hQuakeSettings = RegClientCookie("quakesounds_settings", "Quake Sounds Settings", CookieAccess_Private);

	SetCookieMenuItem(CookieMenu_QuakeSounds, INVALID_HANDLE, "Quake Sound Settings");

	RegConsoleCmd("sm_quake", Command_QuakeSounds);
	RegConsoleCmd("sm_qs", Command_QuakeSounds);
	RegConsoleCmd("sm_quakesounds", Command_QuakeSounds);

	RegConsoleCmd("sm_quakevolume", Command_Volume);
	RegConsoleCmd("sm_qsvolume", Command_Volume);

	RegConsoleCmd("sm_killstreak", Command_KillStreak);
	RegConsoleCmd("sm_ks", Command_KillStreak);

	HookGameEvents();

	AutoExecConfig(true, "quake_sounds_antispam");

	// Late load
	if (!g_bLate)
		return;

	InitializeRound();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			OnClientPostAdminCheck(i);
		}
	}

	g_bLate = false;
}

public void OnMapStart()
{
    LoadQuakeSetConfig();
    PrecacheKillOverlays();
    if (g_evGameEngine == Engine_HL2DM)
    {
        InitializeRound();
    }
    
    g_bGlobalSoundPlaying = false;
    g_sCurrentGlobalSound[0] = '\0';
    g_fGlobalSoundStartTime = 0.0;
    
    if (g_hGlobalSoundTimer != INVALID_HANDLE)
    {
        if (IsValidHandle(g_hGlobalSoundTimer))
        {
            KillTimer(g_hGlobalSoundTimer);
        }
        g_hGlobalSoundTimer = INVALID_HANDLE;
    }
    
    for (int i = 1; i <= MaxClients; i++)
    {
        ResetSoundStates(i);
    }
}

public void OnConfigsExecuted()
{
	g_fVolume = g_cvar_Volume.FloatValue;
	g_fHeadshotCooldown = g_cvar_HeadshotCooldown.FloatValue;
	g_fKillStreakCooldown = g_cvar_KillStreakCooldown.FloatValue;
	g_fSpecialCooldown = g_cvar_SpecialCooldown.FloatValue;
	g_fGeneralCooldown = g_cvar_GeneralCooldown.FloatValue;
	g_fSoundCooldown = g_cvar_SoundCooldown.FloatValue;
	g_iKillingSpreeThreshold = NH_RAMPAGE_KILLS;
	g_iUnstoppableThreshold = NH_UNSTOPPABLE_KILLS;
	g_iGodlikeThreshold = NH_GODLIKE_KILLS;
	g_iMonsterkillThreshold = NH_MONSTERKILL_KILLS;
	g_iUltrakillThreshold = NH_ULTRAKILL_KILLS;
	g_iMegaKillThreshold = NH_MEGAKILL_KILLS;
	
	LogMessage("[Quake Sounds] Anti-spam thresholds loaded: Monsterkill=%d, Ultrakill=%d", 
		g_iMonsterkillThreshold, g_iUltrakillThreshold);
}

public void OnClientDisconnect(int client)
{
    ResetSoundStates(client);

    g_iOverlaySerial[client]++;

    if (g_hOverlayRefreshTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hOverlayRefreshTimer[client]);
		g_hOverlayRefreshTimer[client] = INVALID_HANDLE;
	}

    g_sActiveOverlayName[client][0] = '\0';

    if (g_hOverlayTimer[client] != INVALID_HANDLE)
    {
        KillTimer(g_hOverlayTimer[client]);
        g_hOverlayTimer[client] = INVALID_HANDLE;
    }

    g_iQuakeTextSerial[client]++;

    if (g_hQuakeTextTimer[client] != INVALID_HANDLE)
    {
        KillTimer(g_hQuakeTextTimer[client]);
        g_hQuakeTextTimer[client] = INVALID_HANDLE;
    }
}

public void OnClientPostAdminCheck(int client)
{
	int iUserID = GetClientUserId(client);

	g_iConsecutiveKills[client] = 0;
	g_fLastKillTime[client] = -1.0;
	g_iConsecutiveHeadshots[client] = 0;

	if (g_bLate && AreClientCookiesCached(client))
		ReadClientCookies(client);

	if (GetConVarBool(g_cvar_Announce))
		CreateTimer(ANNOUNCE_DELAY, Timer_Announce, iUserID, TIMER_FLAG_NO_MAPCHANGE);

	CreateTimer(JOIN_DELAY, Timer_JoinCheck, iUserID, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientCookiesCached(int client)
{
	ReadClientCookies(client);
}

//   .d8888b.   .d88888b.  888b     d888 888b     d888        d8888 888b    888 8888888b.   .d8888b.
//  d88P  Y88b d88P" "Y88b 8888b   d8888 8888b   d8888       d88888 8888b   888 888  "Y88b d88P  Y88b
//  888    888 888     888 88888b.d88888 88888b.d88888      d88P888 88888b  888 888    888 Y88b.
//  888        888     888 888Y88888P888 888Y88888P888     d88P 888 888Y88b 888 888    888  "Y888b.
//  888        888     888 888 Y888P 888 888 Y888P 888    d88P  888 888 Y88b888 888    888     "Y88b.
//  888    888 888     888 888  Y8P  888 888  Y8P  888   d88P   888 888  Y88888 888    888       "888
//  Y88b  d88P Y88b. .d88P 888   "   888 888   "   888  d8888888888 888   Y8888 888  .d88P Y88b  d88P
//   "Y8888P"   "Y88888P"  888       888 888       888 d88P     888 888    Y888 8888888P"   "Y8888P"

public Action Command_QuakeSounds(int client, int args)
{	
	DisplayCookieMenu(client);
	return Plugin_Handled;
}

public Action Command_Volume(int client, int args)
{
	if (client == 0)
	{
		PrintToServer("This command can only be used in-game.");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		CPrintToChat(client, "{green}[Quake Sounds] {default}Usage: !volume <0.0-1.0> or !volume <percentage>");
		CPrintToChat(client, "{green}[Quake Sounds] {default}Current volume: {lightgreen}%.1f%% {default}({lightgreen}%.2f{default})", g_fClientVolume[client] * 100, g_fClientVolume[client]);
		return Plugin_Handled;
	}
	
	char arg[16];
	GetCmdArg(1, arg, sizeof(arg));
	
	float newVolume = StringToFloat(arg);
	
	// If user entered percentage (e.g., 80), convert to decimal
	if (newVolume > 1.0 && newVolume <= 100.0)
	{
		newVolume = newVolume / 100.0;
	}
	
	if (newVolume < 0.0 || newVolume > 1.0)
	{
		CPrintToChat(client, "{green}[Quake Sounds] {default}Volume must be between {lightgreen}0.0 {default}and {lightgreen}1.0 {default}(or {lightgreen}0%% {default}and {lightgreen}100%%{default})");
		return Plugin_Handled;
	}
	
	g_fClientVolume[client] = newVolume;
	SaveClientCookies(client);
	
	CPrintToChat(client, "{green}[Quake Sounds] {default}Volume set to {lightgreen}%.1f%% {default}({lightgreen}%.2f{default})", newVolume * 100, newVolume);
	
	return Plugin_Handled;
}

public Action Command_KillStreak(int client, int args)
{
	if (client == 0)
	{
		PrintToServer("This command can only be used in-game.");
		return Plugin_Handled;
	}
	
	int kills = g_iConsecutiveKills[client];
	int headshots = g_iConsecutiveHeadshots[client];
	
	char streakName[64];
	GetStreakName(kills, streakName, sizeof(streakName));
	
	CPrintToChat(client, "{green}[Quake Sounds] {default}Current Kill Streak: {lightgreen}%d {default}kills", kills);
	CPrintToChat(client, "{green}[Quake Sounds] {default}Consecutive Headshots: {lightgreen}%d", headshots);
	CPrintToChat(client, "{green}[Quake Sounds] {default}Current Streak: {lightgreen}%s", streakName);
	
	if (kills < g_iDoubleKillThreshold)
		CPrintToChat(client, "{green}[Quake Sounds] {default}Next: {lightgreen}Double Kill {default}({lightgreen}%d{default} kills)", g_iDoubleKillThreshold);
	else if (kills < g_iTripleKillThreshold)
		CPrintToChat(client, "{green}[Quake Sounds] {default}Next: {lightgreen}Triple Kill {default}({lightgreen}%d{default} kills)", g_iTripleKillThreshold);
	else if (kills < g_iMultiKillThreshold)
		CPrintToChat(client, "{green}[Quake Sounds] {default}Next: {lightgreen}Multi-Kill {default}({lightgreen}%d{default} kills)", g_iMultiKillThreshold);
	else if (kills < g_iMegaKillThreshold)
		CPrintToChat(client, "{green}[Quake Sounds] {default}Next: {lightgreen}Mega-Kill {default}({lightgreen}%d{default} kills)", g_iMegaKillThreshold);
	else if (kills < g_iKillingSpreeThreshold)
		CPrintToChat(client, "{green}[Quake Sounds] {default}Next: {lightgreen}Rampage {default}({lightgreen}%d{default} kills)", g_iKillingSpreeThreshold);
	else if (kills < g_iUnstoppableThreshold)
		CPrintToChat(client, "{green}[Quake Sounds] {default}Next: {lightgreen}Unstoppable {default}({lightgreen}%d{default} kills)", g_iUnstoppableThreshold);
	else if (kills < g_iGodlikeThreshold)
		CPrintToChat(client, "{green}[Quake Sounds] {default}Next: {lightgreen}Godlike {default}({lightgreen}%d{default} kills)", g_iGodlikeThreshold);
	else if (kills < g_iMonsterkillThreshold)
		CPrintToChat(client, "{green}[Quake Sounds] {default}Next: {lightgreen}Monsterkill {default}({lightgreen}%d{default} kills)", g_iMonsterkillThreshold);
	else if (kills < g_iUltrakillThreshold)
		CPrintToChat(client, "{green}[Quake Sounds] {default}Next: {lightgreen}Ultrakill {default}({lightgreen}%d{default} kills)", g_iUltrakillThreshold);
	else
		CPrintToChat(client, "{green}[Quake Sounds] {default}You've reached the highest streak!");
	
	return Plugin_Handled;
}

//  888b     d888 8888888888 888b    888 888     888
//  8888b   d8888 888        8888b   888 888     888
//  88888b.d88888 888        88888b  888 888     888
//  888Y88888P888 8888888    888Y88b 888 888     888
//  888 Y888P 888 888        888 Y88b888 888     888
//  888  Y8P  888 888        888  Y88888 888     888
//  888   "   888 888        888   Y8888 Y88b. .d88P
//  888       888 8888888888 888    Y888  "Y88888P"

public void CookieMenu_QuakeSounds(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_SelectOption:
		{
			DisplayCookieMenu(client);
		}
	}
}

public void DisplayCookieMenu(int client)
{
	Menu menu = new Menu(MenuHandler_QuakeSounds, MENU_ACTIONS_DEFAULT | MenuAction_DisplayItem);
	menu.ExitBackButton = true;
	menu.ExitButton = true;

	char sBuffer[128];
	Format(sBuffer, sizeof(sBuffer), "%T\n ", "quake menu", client);
	SetMenuTitle(menu, sBuffer);

	char notifyLabel[64];
	switch (g_iNotifyMode[client])
	{
		case NOTIFY_TEXT:     Format(notifyLabel, sizeof(notifyLabel), "%T", "notify mode text",     client);
		case NOTIFY_OVERLAY:  Format(notifyLabel, sizeof(notifyLabel), "%T", "notify mode overlay",  client);
		case NOTIFY_DISABLED: Format(notifyLabel, sizeof(notifyLabel), "%T", "notify mode disabled", client);
	}
	AddMenuItem(menu, "text pref", notifyLabel);

	Format(sBuffer, sizeof(sBuffer), "%T",  g_iSound[client] ? "sounds disable" : "sounds enable", client);
	AddMenuItem(menu, "no sounds", sBuffer);

	Format(sBuffer, sizeof(sBuffer), "%T: %.0f%%", "volume", client, g_fClientVolume[client] * 100);
	AddMenuItem(menu, "volume", sBuffer);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_QuakeSounds(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			if (param1 != MenuEnd_Selected)
				delete menu;
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				ShowCookieMenu(param1);
		}
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			if (StrEqual(info, "text pref"))
			{
				g_iNotifyMode[param1] = view_as<NotifyMode>((view_as<int>(g_iNotifyMode[param1]) + 1) % 3);
			}
			else if (StrEqual(info, "no sounds"))
			{
				g_iSound[param1] = g_iSound[param1] ? 0 : 1;
			}
			else if (StrEqual(info, "volume"))
			{
				DisplayVolumeMenu(param1);
				return 0;
			}
			
			SaveClientCookies(param1);
			DisplayCookieMenu(param1);
		}
		case MenuAction_DisplayItem:
		{
			char sBuffer[128];
			GetMenuItem(menu, param2, "", 0, _, sBuffer, sizeof(sBuffer));
			return RedrawMenuItem(sBuffer);
		}
	}
	return 0;
}

void DisplayVolumeMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Volume);
	char title[128];
	Format(title, sizeof(title), "%T\nCurrent: %.0f%%", "volume", client, g_fClientVolume[client] * 100);
	menu.SetTitle(title);
	
	char sBuffer[32];
	
	for (int i = 100; i >= 10; i -= 10)
	{
		Format(sBuffer, sizeof(sBuffer), "%d", i);
		AddMenuItem(menu, sBuffer, sBuffer, i/10 == RoundToFloor(g_fClientVolume[client] * 10) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	
	AddMenuItem(menu, "5", "5%");
	AddMenuItem(menu, "0", "Mute");
	AddMenuItem(menu, "custom", "Custom Value...");
	AddMenuItem(menu, "back", "Back");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Volume(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			if (StrEqual(info, "back"))
			{
				DisplayCookieMenu(param1);
				return 0;
			}
			else if (StrEqual(info, "custom"))
			{
				CPrintToChat(param1, "{green}[Quake Sounds] {default}Type {lightgreen}!volume <0.0-1.0> {default}or {lightgreen}!volume <percentage> {default}in chat");
				DisplayVolumeMenu(param1);
				return 0;
			}
			else
			{
				float newVolume = StringToInt(info) / 100.0;
				g_fClientVolume[param1] = newVolume;
				SaveClientCookies(param1);
				CPrintToChat(param1, "{green}[Quake Sounds] {default}Volume set to {lightgreen}%d%%", StringToInt(info));
				DisplayVolumeMenu(param1);
			}
		}
	}
	return 0;
}

void DisplayPresetMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Preset);
	char title[128];
	Format(title, sizeof(title), "%T\n ", "sound pack", client);
	menu.SetTitle(title);

	char sBuffer[128], sIndex[8];

	for (int i = 0; i < g_iNumSets; i++)
	{
		IntToString(i, sIndex, sizeof(sIndex));
		Format(sBuffer, sizeof(sBuffer), "%s", g_sSetsName[i]);
		AddMenuItem(menu, sIndex, sBuffer, i == g_iSoundPreset[client] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}

	AddMenuItem(menu, "back", "Back");

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Preset(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			if (StrEqual(info, "back"))
			{
				DisplayCookieMenu(param1);
				return 0;
			}
			
			int preset = StringToInt(info);
			if (preset >= 0 && preset < g_iNumSets)
			{
				g_iSoundPreset[param1] = preset;
				SaveClientCookies(param1);
				CPrintToChat(param1, "{green}[Quake Sounds] {default}Sound pack set to: {lightgreen}%s", g_sSetsName[preset]);
				DisplayPresetMenu(param1);
			}
		}
	}
	return 0;
}

// Hooks correct game events
public void HookGameEvents()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	switch (g_evGameEngine)
	{
		case Engine_CSS, Engine_CSGO:
		{
			HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
			HookEvent("round_freeze_end", Event_RoundFreezeEnd, EventHookMode_PostNoCopy);
		}
		case Engine_DODS:
		{
			HookEvent("dod_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
			HookEvent("dod_round_active", Event_RoundFreezeEnd, EventHookMode_PostNoCopy);
		}
		case Engine_TF2:
		{
			HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
			HookEvent("teamplay_round_active", Event_RoundFreezeEnd, EventHookMode_PostNoCopy);
			HookEvent("arena_round_start", Event_RoundFreezeEnd, EventHookMode_PostNoCopy);
		}
		case Engine_HL2DM:
		{
			HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		}
		default:
		{
			HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		}
	}
}

// Loads QuakeSetsList config to check for sound sets
public void LoadQuakeSetConfig()
{
	char sConfigFile[PLATFORM_MAX_PATH];

	KeyValues KvConfig = new KeyValues("SetsList");

	BuildPath(Path_SM, sConfigFile, PLATFORM_MAX_PATH, PATH_CONFIG_QUAKE_SET);

	if (!KvConfig.ImportFromFile(sConfigFile))
	{
		delete KvConfig;
		SetFailState("ImportFromFile() failed!");
		return;
	}
	KvConfig.Rewind();

	if (!KvConfig.GotoFirstSubKey())
	{
		delete KvConfig;
		SetFailState("GotoFirstSubKey() failed!");
		return;
	}

	g_iNumSets = 0;

	do
	{
		char sSection[64];
		KvConfig.GetSectionName(sSection, sizeof(sSection));

		char sSoundSet[64];
		KvConfig.GetString("name", sSoundSet, sizeof(sSoundSet));
		if (!sSoundSet[0])
		{
			LogError("Could not find \"name\" in \"%s\"", sSection);
			continue;
		}
		

		g_sSetsName[g_iNumSets] = sSoundSet;

		BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "%s/%s.cfg", PATH_CONFIG_QUAKE_SOUNDS, g_sSetsName[g_iNumSets]);
		PrintToServer("[SM] Quake Sounds: Loading sound set config '%s'", sConfigFile);
		LoadSet(sConfigFile, g_iNumSets);
		g_iNumSets++;
	} while(KvConfig.GotoNextKey(false));

	delete KvConfig;
}

void LoadSingleQuakeSound(Handle kv, const char[] sectionName, char[] soundBuffer, int maxlen, int &soundConfig, const char[] setFile)
{
	char sBuffer[PLATFORM_MAX_PATH];

	KvRewind(kv);

	if (KvJumpToKey(kv, sectionName))
	{
		if (KvGotoFirstSubKey(kv))
		{
			PrintToServer("[SM] Quake Sounds: '%s' section not configured correctly in %s.", sectionName, setFile);
			KvGoBack(kv);
		}
		else
		{
			KvGetString(kv, "sound", soundBuffer, maxlen);
			soundConfig = KvGetNum(kv, "config", 9);

			Format(sBuffer, sizeof(sBuffer), "sound/%s", soundBuffer);

			if (FileExists(sBuffer, true))
			{
				PrecacheSoundCustom(soundBuffer, PLATFORM_MAX_PATH);
				AddFileToDownloadsTable(sBuffer);
			}
			else
			{
				soundConfig = 0;
				PrintToServer("[SM] Quake Sounds: File specified in '%s' does not exist in '%s', ignoring.", sectionName, setFile);
			}
		}
	}
	else
	{
		PrintToServer("[SM] Quake Sounds: '%s' section missing in %s.", sectionName, setFile);
	}
}

// Loads sound file paths and configs for each sound set
public void LoadSet(char[] setFile, int setNum)
{
	char sBuffer[PLATFORM_MAX_PATH];
	Handle SetFileKV = CreateKeyValues("SoundSet");
	if (FileToKeyValues(SetFileKV, setFile))
	{
		if (KvJumpToKey(SetFileKV, "headshot"))
		{
			if (KvGotoFirstSubKey(SetFileKV))
			{
				do
				{
					KvGetSectionName(SetFileKV, sBuffer, sizeof(sBuffer));
					int killNum = StringToInt(sBuffer);
					if (killNum >= 0 && killNum < MAX_NUM_KILLS)
					{
						KvGetString(SetFileKV, "sound", headshotSound[setNum][killNum], sizeof(sBuffer));
						headshotConfig[setNum][killNum] = KvGetNum(SetFileKV, "config", 9);
						Format(sBuffer, sizeof(sBuffer), "sound/%s", headshotSound[setNum][killNum]);
						if (FileExists(sBuffer, true))
						{
							PrecacheSoundCustom(headshotSound[setNum][killNum], PLATFORM_MAX_PATH);
							AddFileToDownloadsTable(sBuffer);
						}
						else
						{
							headshotConfig[setNum][killNum] = 0;
							PrintToServer("[SM] Quake Sounds: File specified in 'headshot %i' does not exist in '%s', ignoring.", killNum, setFile);
						}
					}
				} while (KvGotoNextKey(SetFileKV));
				KvGoBack(SetFileKV);
			}
			else
			{
				PrintToServer("[SM] Quake Sounds: 'headshot' section not configured correctly in %s.", setFile);
			}
		}
		else
		{
			PrintToServer("[SM] Quake Sounds: 'headshot' section missing in %s.", setFile);
		}
		KvRewind(SetFileKV);
		if (KvJumpToKey(SetFileKV,"grenade"))
		{
			if (KvGotoFirstSubKey(SetFileKV))
			{
				PrintToServer("[SM] Quake Sounds: 'grenade' section not configured correctly in %s.", setFile);
				KvGoBack(SetFileKV);
			}
			else
			{
				KvGetString(SetFileKV, "sound", grenadeSound[setNum], sizeof(sBuffer));
				grenadeConfig[setNum] = KvGetNum(SetFileKV, "config", 9);
				Format(sBuffer, sizeof(sBuffer), "sound/%s", grenadeSound[setNum]);
				if (FileExists(sBuffer, true))
				{
					PrecacheSoundCustom(grenadeSound[setNum], PLATFORM_MAX_PATH);
					AddFileToDownloadsTable(sBuffer);
				}
				else
				{
					grenadeConfig[setNum] = 0;
					PrintToServer("[SM] Quake Sounds: File specified in 'grenade' does not exist in '%s', ignoring.", setFile);
				}
			}
		}
		else
		{
			PrintToServer("[SM] Quake Sounds: 'grenade' section missing in %s.", setFile);
		}
		KvRewind(SetFileKV);
		if (KvJumpToKey(SetFileKV, "selfkill"))
		{
			if (KvGotoFirstSubKey(SetFileKV))
			{
				PrintToServer("[SM] Quake Sounds: 'selfkill' section not configured correctly in %s.", setFile);
				KvGoBack(SetFileKV);
			}
			else
			{
				KvGetString(SetFileKV, "sound", selfkillSound[setNum], sizeof(sBuffer));
				selfkillConfig[setNum] = KvGetNum(SetFileKV, "config", 9);
				Format(sBuffer, sizeof(sBuffer), "sound/%s", selfkillSound[setNum]);
				if (FileExists(sBuffer, true))
				{
					PrecacheSoundCustom(selfkillSound[setNum], PLATFORM_MAX_PATH);
					AddFileToDownloadsTable(sBuffer);
				}
				else
				{
					selfkillConfig[setNum] = 0;
					PrintToServer("[SM] Quake Sounds: File specified in 'selfkill' does not exist in '%s', ignoring.", setFile);
				}
			}
		}
		else
		{
			PrintToServer("[SM] Quake Sounds: 'selfkill' section missing in %s.", setFile);
		}
		KvRewind(SetFileKV);
		if (KvJumpToKey(SetFileKV,"round play"))
		{
			if (KvGotoFirstSubKey(SetFileKV))
			{
				PrintToServer("[SM] Quake Sounds: 'round play' section not configured correctly in %s.", setFile);
				KvGoBack(SetFileKV);
			}
			else
			{
				KvGetString(SetFileKV, "sound", roundplaySound[setNum], sizeof(sBuffer));
				roundplayConfig[setNum] = KvGetNum(SetFileKV, "config", 9);
				Format(sBuffer, sizeof(sBuffer), "sound/%s", roundplaySound[setNum]);
				if (FileExists(sBuffer, true))
				{
					PrecacheSoundCustom(roundplaySound[setNum], PLATFORM_MAX_PATH);
					AddFileToDownloadsTable(sBuffer);
				}
				else
				{
					roundplayConfig[setNum] = 0;
					PrintToServer("[SM] Quake Sounds: File specified in 'round play' does not exist in '%s', ignoring.", setFile);
				}
			}
		}
		else
		{
			PrintToServer("[SM] Quake Sounds: 'round play' section missing in %s.", setFile);
		}
		KvRewind(SetFileKV);
		if (KvJumpToKey(SetFileKV, "knife"))
		{
			if (KvGotoFirstSubKey(SetFileKV))
			{
				PrintToServer("[SM] Quake Sounds: 'knife' section not configured correctly in %s.", setFile);
				KvGoBack(SetFileKV);
			}
			else
			{
				KvGetString(SetFileKV, "sound", knifeSound[setNum], sizeof(sBuffer));
				knifeConfig[setNum] = KvGetNum(SetFileKV, "config", 9);
				Format(sBuffer, sizeof(sBuffer), "sound/%s", knifeSound[setNum]);
				if (FileExists(sBuffer, true))
				{
					PrecacheSoundCustom(knifeSound[setNum], PLATFORM_MAX_PATH);
					AddFileToDownloadsTable(sBuffer);
				}
				else
				{
					knifeConfig[setNum] = 0;
					PrintToServer("[SM] Quake Sounds: File specified in 'knife' does not exist in '%s', ignoring.", setFile);
				}
			}
		}
		else
		{
			PrintToServer("[SM] Quake Sounds: 'knife' section missing in %s.", setFile);
		}
		KvRewind(SetFileKV);
		if (KvJumpToKey(SetFileKV, "killsound"))
		{
			if (KvGotoFirstSubKey(SetFileKV))
			{
				do
				{
					KvGetSectionName(SetFileKV, sBuffer, sizeof(sBuffer));
					int killNum = StringToInt(sBuffer);
					if (killNum >= 0 && killNum < MAX_NUM_KILLS)
					{
						KvGetString(SetFileKV, "sound", killSound[setNum][killNum], sizeof(sBuffer));
						killConfig[setNum][killNum] = KvGetNum(SetFileKV, "config", 9);
						Format(sBuffer, sizeof(sBuffer), "sound/%s", killSound[setNum][killNum]);
						if (FileExists(sBuffer, true))
						{
							PrecacheSoundCustom(killSound[setNum][killNum], PLATFORM_MAX_PATH);
							AddFileToDownloadsTable(sBuffer);
						}
						else
						{
							killConfig[setNum][killNum] = 0;
							PrintToServer("[SM] Quake Sounds: File specified in 'killsound %i' does not exist in '%s', ignoring.", killNum, setFile);
						}
					}
				} while (KvGotoNextKey(SetFileKV));
				KvGoBack(SetFileKV);
			}
			else
			{
				PrintToServer("[SM] Quake Sounds: 'killsound' section not configured correctly in %s.", setFile);
			}
		}
		else
		{
			PrintToServer("[SM] Quake Sounds: 'killsound' section missing in %s.", setFile);
		}
		KvRewind(SetFileKV);
		if (KvJumpToKey(SetFileKV, "first blood"))
		{
			if (KvGotoFirstSubKey(SetFileKV))
			{
				PrintToServer("[SM] Quake Sounds: 'first blood' section not configured correctly in %s.", setFile);
				KvGoBack(SetFileKV);
			}
			else
			{
				KvGetString(SetFileKV, "sound", firstbloodSound[setNum], sizeof(sBuffer));
				firstbloodConfig[setNum] = KvGetNum(SetFileKV, "config", 9);
				Format(sBuffer, sizeof(sBuffer), "sound/%s", firstbloodSound[setNum]);
				if (FileExists(sBuffer, true))
				{
					PrecacheSoundCustom(firstbloodSound[setNum], sizeof(sBuffer));
					AddFileToDownloadsTable(sBuffer);
				}
				else
				{
					firstbloodConfig[setNum] = 0;
					PrintToServer("[SM] Quake Sounds: File specified in 'first blood' does not exist in '%s', ignoring.", setFile);
				}
			}
		}
		else
		{
			PrintToServer("[SM] Quake Sounds: 'first blood' section missing in %s.", setFile);
		}
		KvRewind(SetFileKV);
		if (KvJumpToKey(SetFileKV,"teamkill"))
		{
			if (KvGotoFirstSubKey(SetFileKV))
			{
				PrintToServer("[SM] Quake Sounds: 'teamkill' section not configured correctly in %s.", setFile);
				KvGoBack(SetFileKV);
			}
			else
			{
				KvGetString(SetFileKV, "sound", teamkillSound[setNum], sizeof(sBuffer));
				teamkillConfig[setNum] = KvGetNum(SetFileKV, "config", 9);
				Format(sBuffer, sizeof(sBuffer), "sound/%s", teamkillSound[setNum]);
				if (FileExists(sBuffer, true))
				{
					PrecacheSoundCustom(teamkillSound[setNum], sizeof(sBuffer));
					AddFileToDownloadsTable(sBuffer);
				}
				else
				{
					teamkillConfig[setNum] = 0;
					PrintToServer("[SM] Quake Sounds: File specified in 'teamkill' does not exist in '%s', ignoring.", setFile);
				}
			}
		}
		else
		{
			PrintToServer("[SM] Quake Sounds: 'teamkill' section missing in %s.", setFile);
		}
		KvRewind(SetFileKV);
		if (KvJumpToKey(SetFileKV, "combo"))
		{
			if (KvGotoFirstSubKey(SetFileKV))
			{
				do
				{
					KvGetSectionName(SetFileKV, sBuffer, sizeof(sBuffer));
					int killNum = StringToInt(sBuffer);
					if (killNum >= 0 && killNum < MAX_NUM_KILLS)
					{
						KvGetString(SetFileKV, "sound", comboSound[setNum][killNum], sizeof(sBuffer));
						comboConfig[setNum][killNum] = KvGetNum(SetFileKV, "config", 9);
						Format(sBuffer, sizeof(sBuffer), "sound/%s", comboSound[setNum][killNum]);
						if (FileExists(sBuffer, true))
						{
							PrecacheSoundCustom(comboSound[setNum][killNum], sizeof(sBuffer));
							AddFileToDownloadsTable(sBuffer);
						}
						else
						{
							comboConfig[setNum][killNum] = 0;
							PrintToServer("[SM] Quake Sounds: File specified in 'combo %i' does not exist in '%s', ignoring.", killNum, setFile);
						}
					}
				} while (KvGotoNextKey(SetFileKV));
				KvGoBack(SetFileKV);
			}
			else
			{
				PrintToServer("[SM] Quake Sounds: 'combo' section not configured correctly in %s.", setFile);
			}
		}
		else
		{
			PrintToServer("[SM] Quake Sounds: 'combo' section missing in %s.", setFile);
		}
		KvRewind(SetFileKV);
		if (KvJumpToKey(SetFileKV,"join server"))
		{
			if (KvGotoFirstSubKey(SetFileKV))
			{
				PrintToServer("[SM] Quake Sounds: 'join server' section not configured correctly in %s.", setFile);
				KvGoBack(SetFileKV);
			}
			else
			{
				KvGetString(SetFileKV, "sound", joinSound[setNum], sizeof(sBuffer));
				joinConfig[setNum] = KvGetNum(SetFileKV, "config", 9);
				Format(sBuffer, sizeof(sBuffer), "sound/%s", joinSound[setNum]);
				if (FileExists(sBuffer, true))
				{
					PrecacheSoundCustom(joinSound[setNum], PLATFORM_MAX_PATH);
					AddFileToDownloadsTable(sBuffer);
				}
				else
				{
					joinConfig[setNum] = 0;
					PrintToServer("[SM] Quake Sounds: File specified in 'join server' does not exist in '%s', ignoring.", setFile);
				}
			}
		}
		else
		{
			PrintToServer("[SM] Quake Sounds: 'join server' section missing in %s.", setFile);
		}
			LoadSingleQuakeSound(SetFileKV, "good shot", goodshotSound[setNum], sizeof(goodshotSound[]), goodshotConfig[setNum], setFile);
			LoadSingleQuakeSound(SetFileKV, "nice shot", niceshotSound[setNum], sizeof(niceshotSound[]), niceshotConfig[setNum], setFile);
			LoadSingleQuakeSound(SetFileKV, "headhunter", headhunterSound[setNum], sizeof(headhunterSound[]), headhunterConfig[setNum], setFile);
			LoadSingleQuakeSound(SetFileKV, "assist", assistSound[setNum], sizeof(assistSound[]), assistConfig[setNum], setFile);
			LoadSingleQuakeSound(SetFileKV, "jumpshot", jumpshotSound[setNum], sizeof(jumpshotSound[]), jumpshotConfig[setNum], setFile);
			LoadSingleQuakeSound(SetFileKV, "wallshot", wallshotSound[setNum], sizeof(wallshotSound[]), wallshotConfig[setNum], setFile);
	}
	else
	{
		PrintToServer("[SM] Quake Sounds: Cannot parse '%s', file not found or incorrectly structured!", setFile);
	}
	CloseHandle(SetFileKV);
}

// ##     ##  #######   #######  ##    ##  ######  
// ##     ## ##     ## ##     ## ##   ##  ##    ## 
// ##     ## ##     ## ##     ## ##  ##   ##       
// ######### ##     ## ##     ## #####     ######  
// ##     ## ##     ## ##     ## ##  ##         ## 
// ##     ## ##     ## ##     ## ##   ##  ##    ## 
// ##     ##  #######   #######  ##    ##  ######  

public Action Timer_JoinCheck(Handle timer, int iUserID)
{
	int client = GetClientOfUserId(iUserID);
	if (!client || !IsClientConnected(client))
		return Plugin_Stop;

	if (IsClientInGame(client) && AreClientCookiesCached(client))
	{
		if (g_iSound[client])
		{
			for (int i = 1; i < MAX_NUM_SETS; i++)
			{
				if (strcmp(joinSound[g_iSoundPreset[client]], "", false) != 0)
				{
					if (joinConfig[g_iSoundPreset[client]] & i)
					{
						EmitSoundCustom(client, joinSound[g_iSoundPreset[client]], _, _, _, _, g_fVolume * g_fClientVolume[client]);
						break;
					}
				}
				else
					break;
			}
		}
		return Plugin_Stop;
	}
	return Plugin_Stop;
}

public Action Timer_Announce(Handle timer, int iUserID)
{
	int client = GetClientOfUserId(iUserID);
	if (!client || !IsClientInGame(client))
		return Plugin_Stop;

	CPrintToChat(client, "{green}[Quake Sounds] {default}%t", "announce message");
	return Plugin_Stop;
}

// Plays round play sound depending on each players config and the text display
public void Event_RoundFreezeEnd(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && g_iSound[i])
		{
			if (strcmp(roundplaySound[g_iSoundPreset[i]], "", false) != 0 && (roundplayConfig[g_iSoundPreset[i]] & 1) || (roundplayConfig[g_iSoundPreset[i]] & 2) || (roundplayConfig[g_iSoundPreset[i]] & 4))
			{
				EmitSoundCustom(i, roundplaySound[g_iSoundPreset[i]], _, _, _, _, g_fVolume * g_fClientVolume[i]);
			}
			if (g_iNotifyMode[i] == NOTIFY_TEXT && ((roundplayConfig[g_iSoundPreset[i]] & 8) || (roundplayConfig[g_iSoundPreset[i]] & 16) || (roundplayConfig[g_iSoundPreset[i]] & 32)))
			{
				PrintCenterText(i, "%t", "round play");
			}
		}
	}
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if (g_evGameEngine != Engine_HL2DM)
	{
		InitializeRound();
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		ResetPlayerStats(i);
	}
}

public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	g_bRoundStarted = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		ResetPlayerStats(i);
	}
}

// Important bit - does all kill/combo/custom kill sounds and things!
public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int victimClient = GetClientOfUserId(GetEventInt(event,"userid"));

	if (victimClient < 1 || victimClient > MaxClients)
		return Plugin_Continue;

	int attackerClient = GetClientOfUserId(GetEventInt(event,"attacker"));
	if (attackerClient < 0 || attackerClient > MaxClients)
		return Plugin_Continue;

	// Zombie Riot only:
	// Humans are CT = 3.
	// Zombies are T = 2.
	// Only allow Quake Sounds when a human kills a zombie.
	if (attackerClient <= 0 || !IsClientInGame(attackerClient) || !IsClientInGame(victimClient))
		return Plugin_Continue;

	// If a human dies for any reason, reset their kill/headshot/combo streaks.
	// This must happen BEFORE the Zombie Riot human-kills-zombie filter.
	if (GetClientTeam(victimClient) == 3)
	{
		g_iConsecutiveKills[victimClient] = 0;
		g_iConsecutiveHeadshots[victimClient] = 0;
		g_iComboScore[victimClient] = 0;
		g_fLastKillTime[victimClient] = -1.0;
	}

	if (GetClientTeam(attackerClient) != 3 || GetClientTeam(victimClient) != 2)
		return Plugin_Continue;

	char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH], sBuffer[256];
	GetClientName(attackerClient, attackerName, MAX_NAME_LENGTH);
	GetClientName(victimClient, victimName, MAX_NAME_LENGTH);

	if (attackerClient == victimClient || attackerClient == 0)
	{
		g_iConsecutiveKills[attackerClient] = 0;

		if (!g_cvar_SelfKill.BoolValue)
			return Plugin_Continue;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				int soundPreset = g_iSoundPreset[i];
				int soundConfig = selfkillConfig[soundPreset];
				char sound[PLATFORM_MAX_PATH];
				sound = selfkillSound[soundPreset];

				if ((strcmp(sound, "", false) != 0) && (soundConfig & 1) || ((soundConfig & 2) && attackerClient == i) || ((soundConfig & 4) && victimClient == i))
					EmitSoundCustom(i, sound, _, _, _, _, g_fVolume * g_fClientVolume[i]);

				if (g_iNotifyMode[i] == NOTIFY_TEXT && ((soundConfig & 8) || ((soundConfig & 16) && attackerClient == i) || ((soundConfig & 32) && victimClient == i)))
					PrintCenterText(i, "%t", "selfkill", victimName);
			}
		}
	}
	else if (GetClientTeam(attackerClient) == GetClientTeam(victimClient) && !GetConVarBool(g_cvar_TeamKillMode))
	{
		g_iConsecutiveKills[attackerClient] = 0;

		if (!g_cvar_TeamKill.BoolValue)
			return Plugin_Continue;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && g_iSound[i])
			{
				int soundPreset = g_iSoundPreset[i];
				int soundConfig = selfkillConfig[soundPreset];
				char sound[PLATFORM_MAX_PATH];
				sound = teamkillSound[soundPreset];

				if (strcmp(sound, "", false) != 0 && (soundConfig & 1) || ((soundConfig & 2) && attackerClient == i) || ((soundConfig & 4) && victimClient == i))
					EmitSoundCustom(i, sound, _, _, _, _, g_fVolume * g_fClientVolume[i]);

				if (g_iNotifyMode[i] == NOTIFY_TEXT && ((soundConfig & 8) || ((soundConfig & 16) && attackerClient == i) || ((soundConfig & 32) && victimClient == i)))
					PrintCenterText(i, "%t", "teamkill", attackerName, victimName);
			}
		}
	}
	else
	{
		g_iTotalKills++;
		
		// Increment with bounds checking
		g_iConsecutiveKills[attackerClient]++;
		if (g_iConsecutiveKills[attackerClient] >= MAX_NUM_KILLS)
		{
			g_iConsecutiveKills[attackerClient] = MAX_NUM_KILLS - 1;
		}
		
		bool firstblood = false;
		bool headshot = false;
		bool knife = false;
		bool grenade = false;
		bool combo = false;
		bool jumpshot = false;
		bool wallshot = false;
		int customkill = -1;

		char weapon[64];
		GetEventString(event, "weapon", weapon, sizeof(weapon));

		if (g_evGameEngine == Engine_CSS || g_evGameEngine == Engine_CSGO)
			headshot = GetEventBool(event,"headshot");
		else if (g_evGameEngine == Engine_TF2)
		{
			customkill = GetEventInt(event,"customkill");
			if (customkill == 1)
				headshot = true;
		}

		if (headshot)
		{
			g_iConsecutiveHeadshots[attackerClient]++;
			if (g_iConsecutiveHeadshots[attackerClient] >= MAX_NUM_KILLS)
			{
				g_iConsecutiveHeadshots[attackerClient] = MAX_NUM_KILLS - 1;
			}
		}
		else
		{
			g_iConsecutiveHeadshots[attackerClient] = 0;
		}

		float fLastKillTimeTmp = g_fLastKillTime[attackerClient];
		g_fLastKillTime[attackerClient] = GetEngineTime();
		
		if (fLastKillTimeTmp == -1.0 || (g_fLastKillTime[attackerClient] - fLastKillTimeTmp) > GetConVarFloat(g_cvar_ComboTime))
		{
			g_iComboScore[attackerClient] = 1;
			combo = false;
		}
		else
		{
			g_iComboScore[attackerClient]++;
			combo = true;
		}
		
		// Bounds checking for combo score
		if (g_iComboScore[attackerClient] >= MAX_NUM_KILLS)
		{
			g_iComboScore[attackerClient] = MAX_NUM_KILLS - 1;
		}

		if (g_iTotalKills == 1)
			firstblood = true;

		if (g_evGameEngine == Engine_TF2 && customkill == 2)
			knife = true;

		else if (g_evGameEngine == Engine_CSS)
		{
			
			if (strcmp(weapon, "hegrenade", false) == 0 || strcmp(weapon, "smokegrenade", false) == 0 || strcmp(weapon, "flashbang", false) == 0)
				grenade = true;
			else if (StrContains(weapon, "knife", false) != -1)
				knife = true;
		}
		else if (g_evGameEngine == Engine_CSGO)
		{
			if (strcmp(weapon, "inferno", false) == 0 || strcmp(weapon, "hegrenade", false) == 0 || strcmp(weapon, "flashbang", false) == 0 || strcmp(weapon, "decoy", false) == 0 || strcmp(weapon, "smokegrenade", false) == 0)
				grenade = true;
			else if (StrContains(weapon, "knife", false) != -1 || StrContains(weapon, "bayonet", false) != -1)
				knife = true;
		}
		else if (g_evGameEngine == Engine_DODS)
		{
			
			if (strcmp(weapon, "riflegren_ger", false) == 0 || strcmp(weapon, "riflegren_us", false) == 0 || strcmp(weapon, "frag_ger", false) == 0 || strcmp(weapon, "frag_us", false) == 0 || strcmp(weapon, "smoke_ger", false) == 0 || strcmp(weapon, "smoke_us", false) == 0)
				grenade = true;
			else if (strcmp(weapon, "spade", false) == 0 || strcmp(weapon, "amerknife", false) == 0 || strcmp(weapon, "punch", false) == 0)
				knife = true;
		}
		else if (g_evGameEngine == Engine_HL2DM)
		{
			if (strcmp(weapon, "grenade_frag", false) == 0)
				grenade = true;
			else if (strcmp(weapon,"stunstick", false) == 0 || strcmp(weapon,"crowbar", false) == 0)
				knife = true;
		}
		
		// Check if anti-spam is enabled
		if ((GetEntityFlags(attackerClient) & FL_ONGROUND) == 0)
		{
			jumpshot = true;
		}

		wallshot = IsWallShotKill(attackerClient, victimClient);
		bool bAntiSpam = g_cvar_AntiSpam.BoolValue;
		float fCurrentTime = GetEngineTime();

		NHQuakeEvent quakeEvent = NH_EVENT_NONE;
		int quakeKillIndex = 0;
		SoundCategory quakeCategory = CATEGORY_NONE;

		// Long streaks use kills without dying.
		int longStreakKill = NH_GetStreakEventKill(g_iConsecutiveKills[attackerClient]);

		// Short combo streaks use the combo counter, not kills without dying.
		int shortComboKill = 0;

		switch (g_iComboScore[attackerClient])
		{
			case NH_DOUBLEKILL_KILLS:
			{
				shortComboKill = NH_DOUBLEKILL_KILLS;
			}

			case NH_TRIPLEKILL_KILLS:
			{
				shortComboKill = NH_TRIPLEKILL_KILLS;
			}

			case NH_MULTIKILL_KILLS:
			{
				shortComboKill = NH_MULTIKILL_KILLS;
			}

			case NH_MEGAKILL_KILLS:
			{
				shortComboKill = NH_MEGAKILL_KILLS;
			}

			case NH_HEXAKILL_KILLS:
			{
				shortComboKill = NH_HEXAKILL_KILLS;
			}

			case NH_HEPTAKILL_KILLS:
			{
				shortComboKill = NH_HEPTAKILL_KILLS;
			}

			case NH_OCTAKILL_KILLS:
			{
				shortComboKill = NH_OCTAKILL_KILLS;
			}

			case NH_ENNEAKILL_KILLS:
			{
				shortComboKill = NH_ENNEAKILL_KILLS;
			}

			case NH_DECAKILL_KILLS:
			{
				shortComboKill = NH_DECAKILL_KILLS;
			}
		}

		if (firstblood)
		{
			quakeEvent = NH_EVENT_FIRSTBLOOD;
			quakeCategory = CATEGORY_SPECIAL;
		}
		else if (shortComboKill > 0)
		{
			quakeKillIndex = shortComboKill;
			quakeCategory = CATEGORY_KILLSTREAK_SHORT;

			switch (quakeKillIndex)
			{
				case NH_DOUBLEKILL_KILLS:
				{
					quakeEvent = NH_EVENT_DOUBLEKILL;
				}

				case NH_TRIPLEKILL_KILLS:
				{
					quakeEvent = NH_EVENT_TRIPLEKILL;
				}

				case NH_MULTIKILL_KILLS:
				{
					quakeEvent = NH_EVENT_MULTIKILL;
				}

				case NH_MEGAKILL_KILLS:
				{
					quakeEvent = NH_EVENT_MEGAKILL;
				}

				case NH_HEXAKILL_KILLS:
				{
					quakeEvent = NH_EVENT_HEXAKILL;
				}

				case NH_HEPTAKILL_KILLS:
				{
					quakeEvent = NH_EVENT_HEPTAKILL;
				}

				case NH_OCTAKILL_KILLS:
				{
					quakeEvent = NH_EVENT_OCTAKILL;
				}

				case NH_ENNEAKILL_KILLS:
				{
					quakeEvent = NH_EVENT_ENNEAKILL;
				}

				case NH_DECAKILL_KILLS:
				{
					quakeEvent = NH_EVENT_DECAKILL;
				}
			}
		}
		else if (longStreakKill == NH_RAMPAGE_KILLS ||
				longStreakKill == NH_DOMINATING_KILLS ||
				longStreakKill == NH_UNSTOPPABLE_KILLS ||
				longStreakKill == NH_GODLIKE_KILLS ||
				longStreakKill == NH_MONSTERKILL_KILLS ||
				longStreakKill == NH_ULTRAKILL_KILLS)
		{
			quakeKillIndex = longStreakKill;
			quakeCategory = CATEGORY_KILLSTREAK_LONG;

			switch (quakeKillIndex)
			{

				case NH_RAMPAGE_KILLS:
				{
					quakeEvent = NH_EVENT_RAMPAGE;
				}

				case NH_DOMINATING_KILLS:
				{
					quakeEvent = NH_EVENT_DOMINATING;
				}

				case NH_UNSTOPPABLE_KILLS:
				{
					quakeEvent = NH_EVENT_UNSTOPPABLE;
				}

				case NH_GODLIKE_KILLS:
				{
					quakeEvent = NH_EVENT_GODLIKE;
				}

				case NH_MONSTERKILL_KILLS:
				{
					quakeEvent = NH_EVENT_MONSTERKILL;
				}

				case NH_ULTRAKILL_KILLS:
				{
					quakeEvent = NH_EVENT_ULTRAKILL;
				}
			}
		}
		else if (headshot && g_iConsecutiveHeadshots[attackerClient] >= NH_HEADHUNTER_HEADSHOTS)
		{
			quakeEvent = NH_EVENT_HEADHUNTER;
			quakeCategory = CATEGORY_HEADSHOT;
			g_iConsecutiveHeadshots[attackerClient] = 0;
		}
		else if (jumpshot)
		{
			quakeEvent = NH_EVENT_JUMPSHOT;
			quakeCategory = CATEGORY_SPECIAL;
		}
		else if (wallshot)
		{
			quakeEvent = NH_EVENT_WALLSHOT;
			quakeCategory = CATEGORY_SPECIAL;
		}
		else if (headshot)
		{
			int shotRoll = GetRandomInt(0, 2);

			if (shotRoll == 1)
			{
				quakeEvent = NH_EVENT_GOODSHOT;
			}
			else if (shotRoll == 2)
			{
				quakeEvent = NH_EVENT_NICESHOT;
			}
			else
			{
				quakeEvent = NH_EVENT_HEADSHOT;
			}

			quakeCategory = CATEGORY_HEADSHOT;
		}
		else if (grenade)
		{
			quakeEvent = NH_EVENT_GRENADE;
			quakeCategory = CATEGORY_SPECIAL;
		}
		else if (knife)
		{
			quakeEvent = NH_EVENT_KNIFE;
			quakeCategory = CATEGORY_SPECIAL;
		}
		
		bool bGlobalEvent = NH_IsGlobalQuakeEvent(quakeEvent);

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				if (quakeEvent == NH_EVENT_NONE)
					continue;

				bool bIsOwner = (i == attackerClient);

				// Non-global events are only for the player who earned them.
				// Global events are heard/text-shown by everyone, but overlay remains owner-only.
				if (!bGlobalEvent && !bIsOwner)
					continue;

				int soundPreset = g_iSoundPreset[i];

				int soundConfig = 0;
				char sound[PLATFORM_MAX_PATH];
				char overlayName[64];
				char displayText[128];

				sound[0] = '\0';
				overlayName[0] = '\0';
				displayText[0] = '\0';

				switch (quakeEvent)
				{
					case NH_EVENT_FIRSTBLOOD:
					{
						soundConfig = firstbloodConfig[soundPreset];
						strcopy(sound, sizeof(sound), firstbloodSound[soundPreset]);
						strcopy(overlayName, sizeof(overlayName), "firstblood_nh_quakecso_2048");
						Format(displayText, sizeof(displayText), "%s got the first blood!", attackerName);
					}

					case NH_EVENT_HEADSHOT:
					{
						soundConfig = headshotConfig[soundPreset][0];
						strcopy(sound, sizeof(sound), headshotSound[soundPreset][0]);
						strcopy(overlayName, sizeof(overlayName), "headshot_nh_quakecso_2048");
						Format(displayText, sizeof(displayText), "%s landed a headshot!", attackerName);
					}

					case NH_EVENT_GOODSHOT:
					{
						soundConfig = goodshotConfig[soundPreset];

						if (soundConfig <= 0 || goodshotSound[soundPreset][0] == '\0')
						{
							soundConfig = headshotConfig[soundPreset][0];
							strcopy(sound, sizeof(sound), headshotSound[soundPreset][0]);
							strcopy(overlayName, sizeof(overlayName), "headshot_nh_quakecso_2048");
							Format(displayText, sizeof(displayText), "%s landed a headshot!", attackerName);
						}
						else
						{
							strcopy(sound, sizeof(sound), goodshotSound[soundPreset]);
							strcopy(overlayName, sizeof(overlayName), "good_shot_nh_quakecso_2048");
							Format(displayText, sizeof(displayText), "Good shot, %s!", attackerName);
						}
					}

					case NH_EVENT_NICESHOT:
					{
						soundConfig = niceshotConfig[soundPreset];

						if (soundConfig <= 0 || niceshotSound[soundPreset][0] == '\0')
						{
							soundConfig = headshotConfig[soundPreset][0];
							strcopy(sound, sizeof(sound), headshotSound[soundPreset][0]);
							strcopy(overlayName, sizeof(overlayName), "headshot_nh_quakecso_2048");
							Format(displayText, sizeof(displayText), "%s landed a headshot!", attackerName);
						}
						else
						{
							strcopy(sound, sizeof(sound), niceshotSound[soundPreset]);
							strcopy(overlayName, sizeof(overlayName), "nice_shot_nh_quakecso_2048");
							Format(displayText, sizeof(displayText), "Nice shot, %s!", attackerName);
						}
					}

					case NH_EVENT_HEADHUNTER:
					{
						soundConfig = headhunterConfig[soundPreset];
						strcopy(sound, sizeof(sound), headhunterSound[soundPreset]);
						strcopy(overlayName, sizeof(overlayName), "headhunter_nh_quakecso_2048");
						Format(displayText, sizeof(displayText), "%s is a headhunter!", attackerName);
					}

					case NH_EVENT_JUMPSHOT:
					{
						soundConfig = jumpshotConfig[soundPreset];
						strcopy(sound, sizeof(sound), jumpshotSound[soundPreset]);
						strcopy(overlayName, sizeof(overlayName), "jumpshot_nh_quakecso_2048");
						Format(displayText, sizeof(displayText), "%s got a jumpshot!", attackerName);
					}

					case NH_EVENT_WALLSHOT:
					{
						soundConfig = wallshotConfig[soundPreset];
						strcopy(sound, sizeof(sound), wallshotSound[soundPreset]);
						strcopy(overlayName, sizeof(overlayName), "wallshot_nh_quakecso_2048");
						Format(displayText, sizeof(displayText), "%s got a wallshot!", attackerName);
					}

					case NH_EVENT_GRENADE:
					{
						soundConfig = grenadeConfig[soundPreset];
						strcopy(sound, sizeof(sound), grenadeSound[soundPreset]);
						strcopy(overlayName, sizeof(overlayName), "grenadekill_nh_quakecso_2048");
						Format(displayText, sizeof(displayText), "%s blew up a zombie!", attackerName);
					}

					case NH_EVENT_KNIFE:
					{
						soundConfig = knifeConfig[soundPreset];
						strcopy(sound, sizeof(sound), knifeSound[soundPreset]);
						strcopy(overlayName, sizeof(overlayName), "humiliation_nh_quakecso_2048");
						Format(displayText, sizeof(displayText), "%s humiliated a zombie!", attackerName);
					}

					case NH_EVENT_DOUBLEKILL,
						NH_EVENT_TRIPLEKILL,
						NH_EVENT_MULTIKILL,
						NH_EVENT_MEGAKILL,
						NH_EVENT_HEXAKILL,
						NH_EVENT_HEPTAKILL,
						NH_EVENT_OCTAKILL,
						NH_EVENT_ENNEAKILL,
						NH_EVENT_DECAKILL:
					{
						if (quakeKillIndex <= 0 || quakeKillIndex >= MAX_NUM_KILLS)
							continue;

						soundConfig = comboConfig[soundPreset][quakeKillIndex];
						strcopy(sound, sizeof(sound), comboSound[soundPreset][quakeKillIndex]);

						GetStreakOverlayName(quakeKillIndex, overlayName, sizeof(overlayName));
						GetStreakDisplayName(attackerName, quakeKillIndex, displayText, sizeof(displayText));
					}

					case NH_EVENT_RAMPAGE,
						NH_EVENT_DOMINATING,
						NH_EVENT_UNSTOPPABLE,
						NH_EVENT_GODLIKE,
						NH_EVENT_MONSTERKILL,
						NH_EVENT_ULTRAKILL:
					{
						if (quakeKillIndex <= 0 || quakeKillIndex >= MAX_NUM_KILLS)
							continue;

						soundConfig = killConfig[soundPreset][quakeKillIndex];
						strcopy(sound, sizeof(sound), killSound[soundPreset][quakeKillIndex]);

						GetStreakOverlayName(quakeKillIndex, overlayName, sizeof(overlayName));
						GetStreakDisplayName(attackerName, quakeKillIndex, displayText, sizeof(displayText));
					}
				}

				if (soundConfig <= 0 || sound[0] == '\0')
					continue;

				bool bCanPlaySound = true;

				if (bAntiSpam)
				{
					if (fCurrentTime - g_fLastSoundTime[i] < g_fGeneralCooldown)
					{
						bCanPlaySound = false;
					}

					if (bCanPlaySound)
					{
						float lastCategoryTime = 0.0;
						float requiredCooldown = 0.0;

						switch (quakeCategory)
						{
							case CATEGORY_HEADSHOT:
							{
								lastCategoryTime = g_fLastHeadshotTime[i];
								requiredCooldown = g_fHeadshotCooldown;
							}

							case CATEGORY_SPECIAL:
							{
								lastCategoryTime = g_fLastSpecialTime[i];
								requiredCooldown = g_fSpecialCooldown;
							}

							case CATEGORY_KILLSTREAK_SHORT:
							{
								lastCategoryTime = g_fLastKillStreakTime[i];
								requiredCooldown = g_fKillStreakCooldown;
							}

							case CATEGORY_KILLSTREAK_LONG:
							{
								lastCategoryTime = g_fLastKillStreakTime[i];
								requiredCooldown = g_fKillStreakCooldown;
							}
						}

						if (requiredCooldown > 0.0 && fCurrentTime - lastCategoryTime < requiredCooldown)
						{
							bool allowPreempt = false;
							if ((quakeCategory == CATEGORY_KILLSTREAK_SHORT || quakeCategory == CATEGORY_KILLSTREAK_LONG) && (quakeKillIndex > g_iLastKillStreakIndex[i]))
								allowPreempt = true;
							if (!allowPreempt) bCanPlaySound = false;
						}
					}
				}

				bool bSoundPlayed = false;

				if (bCanPlaySound && g_iSound[i] && sound[0] != '\0')
				{
					bSoundPlayed = EmitSoundCustom(i, sound, _, _, _, _, g_fVolume * g_fClientVolume[i]);
				}

				// Overlay — owner-only, only when mode is NOTIFY_OVERLAY.
				if (bIsOwner && g_iNotifyMode[i] == NOTIFY_OVERLAY && overlayName[0] != '\0')
				{
					ShowKillOverlay(i, overlayName);
				}

				// Center text — only when mode is NOTIFY_TEXT.
				if (g_iNotifyMode[i] == NOTIFY_TEXT && displayText[0] != '\0')
				{
					if (bGlobalEvent || bIsOwner)
					{
						PrintQuakeTextDelayed(i, displayText);
					}
				}
				// Update cooldown timers if a sound was played
				if (bSoundPlayed && bAntiSpam)
				{
					g_fLastSoundTime[i] = fCurrentTime;
		
					switch (quakeCategory)
					{
						case CATEGORY_HEADSHOT:
							g_fLastHeadshotTime[i] = fCurrentTime;
						case CATEGORY_KILLSTREAK_SHORT, CATEGORY_KILLSTREAK_LONG:
							g_fLastKillStreakTime[i] = fCurrentTime;
						case CATEGORY_SPECIAL:
							g_fLastSpecialTime[i] = fCurrentTime;
					}

					g_iLastSoundCategory[i] = quakeCategory;
					}
				}
			}
		}
	int assister = FindBestAssister(victimClient, attackerClient);

	if (assister > 0 && IsClientInGame(assister) && !IsFakeClient(assister))
	{
		int soundPreset = g_iSoundPreset[assister];

		if (assistConfig[soundPreset] > 0)
		{
			float now = GetEngineTime();
			if (now - g_fLastAssistTime[assister] >= ASSIST_SOUND_COOLDOWN)
			{
				g_fLastAssistTime[assister] = now;

				if (g_iSound[assister] && assistSound[soundPreset][0] != '\0')
				{
					EmitSoundCustom(assister, assistSound[soundPreset], _, _, _, _, g_fVolume * g_fClientVolume[assister]);
				}

				if (g_iNotifyMode[assister] == NOTIFY_OVERLAY)
				{
					ShowKillOverlay(assister, "assist_nh_quakecso_2048");
				}
				else if (g_iNotifyMode[assister] == NOTIFY_TEXT)
				{
					char assisterName[MAX_NAME_LENGTH];
					GetClientName(assister, assisterName, sizeof(assisterName));
					char assistText[128];
					Format(assistText, sizeof(assistText), "%s got an assist!", assisterName);
					PrintQuakeTextDelayed(assister, assistText);
				}
			}
		}
	}
	ClearAssistDamageForVictim(victimClient);

	if (g_iConsecutiveKills[attackerClient] >= NH_ULTRAKILL_KILLS)
	{
		g_iConsecutiveKills[attackerClient] = 0;
		g_iLastKillStreakIndex[attackerClient] = 0;
	}

	g_iConsecutiveKills[victimClient] = 0;
	g_iConsecutiveHeadshots[victimClient] = 0;
	g_iLastKillStreakIndex[victimClient] = 0;

	return Plugin_Continue;
}

void ClearAssistDamageForVictim(int victim)
{
	if (victim <= 0 || victim > MaxClients)
		return;

	for (int i = 1; i <= MaxClients; i++)
	{
		g_fAssistDamage[victim][i] = 0.0;
		g_fAssistLastDamageTime[victim][i] = 0.0;
	}
}

bool NH_IsGlobalQuakeEvent(NHQuakeEvent event)
{
	switch (event)
	{
		case NH_EVENT_FIRSTBLOOD,
			 NH_EVENT_RAMPAGE,
			 NH_EVENT_DOMINATING,
			 NH_EVENT_UNSTOPPABLE,
			 NH_EVENT_GODLIKE,
			 NH_EVENT_MONSTERKILL,
			 NH_EVENT_ULTRAKILL,
			 NH_EVENT_GRENADE,
			 NH_EVENT_KNIFE:
		{
			return true;
		}
	}

	return false;
}

int FindBestAssister(int victim, int killer)
{
	float now = GetEngineTime();
	int bestClient = 0;
	float bestDamage = 0.0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == killer)
			continue;

		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		if (GetClientTeam(i) != 3)
			continue;

		if (g_fAssistDamage[victim][i] < NH_ASSIST_MIN_DAMAGE)
			continue;

		if (now - g_fAssistLastDamageTime[victim][i] > NH_ASSIST_WINDOW)
			continue;

		if (g_fAssistDamage[victim][i] > bestDamage)
		{
			bestDamage = g_fAssistDamage[victim][i];
			bestClient = i;
		}
	}

	return bestClient;
}

bool TraceFilter_Wallshot(int entity, int contentsMask, any data)
{
	// Ignore players. We only care if world/solid map geometry is between attacker and victim.
	if (entity >= 1 && entity <= MaxClients)
		return false;

	return true;
}

bool IsWallShotKill(int attacker, int victim)
{
	if (attacker <= 0 || victim <= 0)
		return false;

	if (!IsClientInGame(attacker) || !IsClientInGame(victim))
		return false;

	float start[3], end[3];
	GetClientEyePosition(attacker, start);
	GetClientEyePosition(victim, end);

	Handle trace = TR_TraceRayFilterEx(start, end, MASK_SHOT, RayType_EndPoint, TraceFilter_Wallshot, 0);
	bool blocked = TR_DidHit(trace);
	CloseHandle(trace);

	return blocked;
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (victim <= 0 || victim > MaxClients || attacker <= 0 || attacker > MaxClients)
		return Plugin_Continue;

	if (!IsClientInGame(victim) || !IsClientInGame(attacker))
		return Plugin_Continue;

	if (victim == attacker)
		return Plugin_Continue;

	// Zombie Riot only:
	// CT humans damage T zombies.
	if (GetClientTeam(attacker) != 3 || GetClientTeam(victim) != 2)
		return Plugin_Continue;

	int damage = GetEventInt(event, "dmg_health");
	if (damage <= 0)
		return Plugin_Continue;

	g_fAssistDamage[victim][attacker] += float(damage);
	g_fAssistLastDamageTime[victim][attacker] = GetEngineTime();

	return Plugin_Continue;
}

// ######## ##     ## ##    ##  ######  ######## ####  #######  ##    ##  ######  
// ##       ##     ## ###   ## ##    ##    ##     ##  ##     ## ###   ## ##    ## 
// ##       ##     ## ####  ## ##          ##     ##  ##     ## ####  ## ##       
// ######   ##     ## ## ## ## ##          ##     ##  ##     ## ## ## ##  ######  
// ##       ##     ## ##  #### ##          ##     ##  ##     ## ##  ####       ## 
// ##       ##     ## ##   ### ##    ##    ##     ##  ##     ## ##   ### ##    ## 
// ##        #######  ##    ##  ######     ##    ####  #######  ##    ##  ######

// Resets combo/headshot streaks (not kill streaks though) on new round
public void InitializeRound()
{
	g_iTotalKills = 0;
	for (int i = 1; i <= MaxClients; i++) 
	{
		g_iConsecutiveHeadshots[i] = 0;
		g_fLastKillTime[i] = -1.0;
	}
}

// Adds specified sound to cache (and for CSGO)
stock void PrecacheSoundCustom(char[] soundFile, int maxLength)
{
	if (g_evGameEngine == Engine_CSGO)
	{
		Format(soundFile, maxLength, "*%s", soundFile);
		AddToStringTable(FindStringTable("soundprecache"), soundFile);
	}
	else
	{
		PrecacheSound(soundFile, true);
	}
}

// Custom EmitSound to allow compatibility with all game engines
stock bool EmitSoundCustom(int client, const char[] sound, int entity=SOUND_FROM_PLAYER, int channel=SNDCHAN_AUTO, int level=SNDLEVEL_NORMAL, int flags=SND_NOFLAGS, float volume=SNDVOL_NORMAL, int pitch=SNDPITCH_NORMAL, int speakerentity=-1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos=true, float soundtime=0.0)
{
	if (client < 1 || client > MaxClients)
		return false;

	if (!IsClientInGame(client) || IsFakeClient(client))
		return false;

	if (sound[0] == '\0')
		return false;

	int clients[1];
	clients[0] = client;

	EmitSound(clients, 1, sound, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	return true;
}

public void ReadClientCookies(int client)
{
	char sValue[256];
	GetClientCookie(client, g_hQuakeSettings, sValue, sizeof(sValue));

	if (strlen(sValue) >= 1)
	{
		char sParts[4][PLATFORM_MAX_PATH];
		int numParts = ExplodeString(sValue, "|", sParts, sizeof(sParts), sizeof(sParts[]));

		if (numParts >= 1)
			g_iNotifyMode[client] = view_as<NotifyMode>(StringToInt(sParts[0]));

		if (numParts >= 2)
			g_iSound[client] = StringToInt(sParts[1]);

		if (numParts >= 3)
		{
			g_iSoundPreset[client] = 0;
		}

		if (numParts >= 4)
		{
			float volume = StringToFloat(sParts[3]);
			g_fClientVolume[client] = (volume >= 0.0 && volume <= 1.0) ? volume : 1.0;
		}
	}
	else
	{
		g_iNotifyMode[client] = view_as<NotifyMode>(GetConVarInt(g_cvar_Text));
		g_iSound[client] = GetConVarInt(g_cvar_Sound);
		g_iSoundPreset[client] = 0;
		g_fClientVolume[client] = GetConVarFloat(g_cvar_Volume);
	}
}

float GetDurationOfSounds(const char[] soundPath)
{
    char lowerSound[PLATFORM_MAX_PATH];
    strcopy(lowerSound, sizeof(lowerSound), soundPath);
    StringToLower(lowerSound);
    
    for (int i = 0; i < sizeof(g_SoundDurations); i++)
    {
        if (StrContains(lowerSound, g_SoundDurations[i].pattern, false) != -1)
        {
            return g_SoundDurations[i].duration;
        }
    }
    
    if (StrContains(lowerSound, ".mp3", false) != -1 || StrContains(lowerSound, ".wav", false) != -1)
    {
        return 2.5;
    }
    
    return 2.0;
}

void StringToLower(char[] str)
{
    for (int i = 0; str[i] != '\0'; i++)
    {
        str[i] = CharToLower(str[i]);
    }
}

/*
bool CanPlaySound(int client, SoundCategory category)
{
    bool queueMode = g_cvar_SoundQueueMode.BoolValue;
    bool broadcastMode = g_cvar_SoundBroadcastMode.BoolValue;
    
    if (queueMode)
    {
        if (broadcastMode)
        {
            return !g_bGlobalSoundPlaying;
        }
        else
        {
            return !g_bSoundPlaying[client];
        }
    }
    else
    {
        float fCurrentTime = GetEngineTime();
        if (fCurrentTime - g_fLastSoundTime[client] < g_fGeneralCooldown)
            return false;
        switch (category)
        {
            case CATEGORY_HEADSHOT:
                if (fCurrentTime - g_fLastHeadshotTime[client] < g_fHeadshotCooldown)
                    return false;
            case CATEGORY_KILLSTREAK_SHORT, CATEGORY_KILLSTREAK_LONG:
                if (fCurrentTime - g_fLastKillStreakTime[client] < g_fKillStreakCooldown)
                    return false;
            case CATEGORY_SPECIAL:
                if (fCurrentTime - g_fLastSpecialTime[client] < g_fSpecialCooldown)
                    return false;
        }
        
        return true;
    }
}
*/

public Action Timer_SoundFinished(Handle timer, int client)
{
    if (client == 0) // Global sound
    {
        g_bGlobalSoundPlaying = false;
        g_sCurrentGlobalSound[0] = '\0';
        g_fGlobalSoundStartTime = 0.0;
        g_hGlobalSoundTimer = INVALID_HANDLE;
        PrintToServer("[Quake Sounds] Global sound finished, ready for next sound");
    }
    else if (client > 0 && client <= MaxClients)
    {
        g_bSoundPlaying[client] = false;
        g_sCurrentSound[client][0] = '\0';
        g_fSoundDuration[client] = 0.0;
        g_fSoundStartTime[client] = 0.0;
        g_hSoundTimer[client] = INVALID_HANDLE;
        PrintToServer("[Quake Sounds] Sound finished for client %d, ready for next sound", client);
    }
    return Plugin_Stop;
}

public void SaveClientCookies(int client)
{
	if (!AreClientCookiesCached(client) || IsFakeClient(client))
		return;

	char sPresetName[PLATFORM_MAX_PATH];
	if (g_iSoundPreset[client] >= 0 && g_iSoundPreset[client] < g_iNumSets)
		strcopy(sPresetName, sizeof(sPresetName), g_sSetsName[g_iSoundPreset[client]]);

	char sValue[256];
	Format(sValue, sizeof(sValue), "%d|%d|%s|%.2f",
		view_as<int>(g_iNotifyMode[client]),
		g_iSound[client],
		sPresetName,
		g_fClientVolume[client]);
	SetClientCookie(client, g_hQuakeSettings, sValue);
}

stock int PickRandomSoundValue()
{
	int iRandom = GetRandomInt(0, 10);
	switch (iRandom)
	{
		case 0:
			iRandom = 4;
		case 1:
			iRandom = 6;
		case 2:
			iRandom = 8;
		case 3:
			iRandom = 10;
		case 4:
			iRandom = 14;
		case 5:
			iRandom = 16;
		case 6:
			iRandom = 18;
		case 7:
			iRandom = 20;
		case 8:
			iRandom = 22;
		case 9:
			iRandom = 24;
		case 10:
			iRandom = 26;
	}
	
	// Ensure within bounds
	if (iRandom >= MAX_NUM_KILLS)
	{
		iRandom = MAX_NUM_KILLS - 1;
	}
	
	return iRandom;
}

public void ResetPlayerStats(int client)
{
    g_iConsecutiveKills[client] = 0;
    g_iComboScore[client] = 0;
    g_iConsecutiveHeadshots[client] = 0;
    g_fLastKillTime[client] = -1.0;
    g_fLastSoundTime[client] = 0.0;
    g_fLastHeadshotTime[client] = 0.0;
    g_fLastKillStreakTime[client] = 0.0;
    g_fLastSpecialTime[client] = 0.0;
    g_iLastSoundCategory[client] = CATEGORY_NONE;
    g_iLastKillStreakIndex[client] = 0;
    g_fLastAssistTime[client] = -ASSIST_SOUND_COOLDOWN;
	ClearAssistDamageForVictim(client);

	for (int i = 1; i <= MaxClients; i++)
	{
		g_fAssistDamage[i][client] = 0.0;
		g_fAssistLastDamageTime[i][client] = 0.0;
	}
    ResetSoundStates(client);
}

public void ResetSoundStates(int client)
{
    if (client == 0)
    {
        g_bGlobalSoundPlaying = false;
        g_sCurrentGlobalSound[0] = '\0';
        g_fGlobalSoundStartTime = 0.0;
        
        if (g_hGlobalSoundTimer != INVALID_HANDLE)
        {
            if (IsValidHandle(g_hGlobalSoundTimer))
            {
                KillTimer(g_hGlobalSoundTimer);
            }
            g_hGlobalSoundTimer = INVALID_HANDLE;
        }
    }
    else if (client > 0 && client <= MaxClients)
    {
        g_bSoundPlaying[client] = false;
        g_sCurrentSound[client][0] = '\0';
        g_fSoundDuration[client] = 0.0;
        g_fSoundStartTime[client] = 0.0;
        
        if (g_hSoundTimer[client] != INVALID_HANDLE)
        {
            if (IsValidHandle(g_hSoundTimer[client]))
            {
                KillTimer(g_hSoundTimer[client]);
            }
            g_hSoundTimer[client] = INVALID_HANDLE;
        }
    }
}

void PrecacheKillOverlays()
{
    AddKillOverlayFile("firstblood_nh_quakecso_2048");
    AddKillOverlayFile("headshot_nh_quakecso_2048");
    AddKillOverlayFile("grenadekill_nh_quakecso_2048");
    AddKillOverlayFile("humiliation_nh_quakecso_2048");
	AddKillOverlayFile("assist_nh_quakecso_2048");
	AddKillOverlayFile("good_shot_nh_quakecso_2048");
	AddKillOverlayFile("nice_shot_nh_quakecso_2048");
	AddKillOverlayFile("headhunter_nh_quakecso_2048");
	AddKillOverlayFile("jumpshot_nh_quakecso_2048");
	AddKillOverlayFile("wallshot_nh_quakecso_2048");
    AddKillOverlayFile("doublekill_nh_quakecso_2048");
    AddKillOverlayFile("triplekill_nh_quakecso_2048");
    AddKillOverlayFile("multikill_nh_quakecso_2048");
    AddKillOverlayFile("megakill_nh_quakecso_2048");
    AddKillOverlayFile("hexakill_nh_quakecso_2048");
	AddKillOverlayFile("heptakill_nh_quakecso_2048");
	AddKillOverlayFile("octakill_nh_quakecso_2048");
	AddKillOverlayFile("enneakill_nh_quakecso_2048");
	AddKillOverlayFile("decakill_nh_quakecso_2048");
    AddKillOverlayFile("dominating_nh_quakecso_2048");
    AddKillOverlayFile("rampage_nh_quakecso_2048");
    AddKillOverlayFile("unstoppable_nh_quakecso_2048");
    AddKillOverlayFile("godlike_nh_quakecso_2048");
    AddKillOverlayFile("monsterkill_nh_quakecso_2048");
    AddKillOverlayFile("ultrakill_nh_quakecso_2048");
}

void AddKillOverlayFile(const char[] overlayName)
{
    char folder[PLATFORM_MAX_PATH];
    g_cvar_OverlayFolder.GetString(folder, sizeof(folder));

    char materialPath[PLATFORM_MAX_PATH];

    Format(materialPath, sizeof(materialPath), "materials/%s/%s.vmt", folder, overlayName);
    if (FileExists(materialPath, true))
    {
        AddFileToDownloadsTable(materialPath);
    }
    else
    {
        PrintToServer("[Quake Sounds] Missing overlay VMT: %s", materialPath);
    }

    Format(materialPath, sizeof(materialPath), "materials/%s/%s.vtf", folder, overlayName);
    if (FileExists(materialPath, true))
    {
        AddFileToDownloadsTable(materialPath);
    }
    else
    {
        PrintToServer("[Quake Sounds] Missing overlay VTF: %s", materialPath);
    }
}

void ShowKillOverlay(int client, const char[] overlayName)
{
    if (!g_cvar_OverlayEnable.BoolValue)
        return;

    if (client <= 0 || client > MaxClients)
        return;

    if (!IsClientInGame(client) || IsFakeClient(client))
        return;

    // Only show Quake overlays to humans / CT team.
    if (GetClientTeam(client) != 3)
        return;

    if (overlayName[0] == '\0')
        return;

    char folder[PLATFORM_MAX_PATH];
    g_cvar_OverlayFolder.GetString(folder, sizeof(folder));

    char overlayPath[PLATFORM_MAX_PATH];
    Format(overlayPath, sizeof(overlayPath), "%s/%s", folder, overlayName);

    // New serial means old clear/reapply timers are ignored.
    g_iOverlaySerial[client]++;

    strcopy(g_sActiveOverlayName[client], sizeof(g_sActiveOverlayName[]), overlayName);

    // Show overlay immediately before the text appears.
    ClientCommand(client, "r_screenoverlay \"%s\"", overlayPath);

    if (g_hOverlayRefreshTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hOverlayRefreshTimer[client]);
		g_hOverlayRefreshTimer[client] = INVALID_HANDLE;
	}

	DataPack refreshPack = new DataPack();
	refreshPack.WriteCell(GetClientUserId(client));
	refreshPack.WriteCell(g_iOverlaySerial[client]);

	g_hOverlayRefreshTimer[client] = CreateTimer(
		0.15,
		Timer_RefreshKillOverlay,
		refreshPack,
		TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE
	);

    // Small protection re-applies.
    // This helps if PrintCenterText or another HUD event clears the overlay shortly after showing.
    int userid = GetClientUserId(client);
    CreateTimer(0.08, Timer_ReapplyOverlayAfterText, userid, TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(0.25, Timer_ReapplyOverlayAfterText, userid, TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(0.60, Timer_ReapplyOverlayAfterText, userid, TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(1.10, Timer_ReapplyOverlayAfterText, userid, TIMER_FLAG_NO_MAPCHANGE);

    if (g_hOverlayTimer[client] != INVALID_HANDLE)
    {
        KillTimer(g_hOverlayTimer[client]);
        g_hOverlayTimer[client] = INVALID_HANDLE;
    }

    DataPack pack = new DataPack();
    pack.WriteCell(userid);
    pack.WriteCell(g_iOverlaySerial[client]);

    g_hOverlayTimer[client] = CreateTimer(
        g_cvar_OverlayDuration.FloatValue,
        Timer_ClearKillOverlay,
        pack,
        TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE
    );
}

public Action Timer_ClearKillOverlay(Handle timer, DataPack pack)
{
    pack.Reset();

    int userid = pack.ReadCell();
    int serial = pack.ReadCell();

    int client = GetClientOfUserId(userid);

    if (client > 0 && client <= MaxClients)
    {
        if (serial != g_iOverlaySerial[client])
        {
            return Plugin_Stop;
        }

        g_hOverlayTimer[client] = INVALID_HANDLE;

        if (g_hOverlayRefreshTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_hOverlayRefreshTimer[client]);
			g_hOverlayRefreshTimer[client] = INVALID_HANDLE;
		}

        g_sActiveOverlayName[client][0] = '\0';

		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			ClientCommand(client, "r_screenoverlay \"\"");
		}
    }

    return Plugin_Stop;
}

void PrintQuakeTextDelayed(int client, const char[] message)
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client))
        return;

    g_iQuakeTextSerial[client]++;

    if (g_hQuakeTextTimer[client] != INVALID_HANDLE)
    {
        KillTimer(g_hQuakeTextTimer[client]);
        g_hQuakeTextTimer[client] = INVALID_HANDLE;
    }

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(g_iQuakeTextSerial[client]);
    pack.WriteString(message);

    g_hQuakeTextTimer[client] = CreateTimer(QUAKE_TEXT_DELAY, Timer_PrintQuakeText, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
}

public Action Timer_PrintQuakeText(Handle timer, DataPack pack)
{
    pack.Reset();

    int userid = pack.ReadCell();
    int serial = pack.ReadCell();

    char message[256];
    pack.ReadString(message, sizeof(message));

    int client = GetClientOfUserId(userid);
    if (client <= 0 || !IsClientInGame(client))
        return Plugin_Stop;

    if (serial != g_iQuakeTextSerial[client])
        return Plugin_Stop;

    g_hQuakeTextTimer[client] = INVALID_HANDLE;

    PrintCenterText(client, "%s", message);

    CreateTimer(0.03, Timer_ReapplyOverlayAfterText, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.12, Timer_ReapplyOverlayAfterText, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.25, Timer_ReapplyOverlayAfterText, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Stop;
}

public Action Timer_ReapplyOverlayAfterText(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);

    if (client <= 0 || client > MaxClients)
        return Plugin_Stop;

    if (!IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Stop;

    if (GetClientTeam(client) != 3)
        return Plugin_Stop;

    if (!g_cvar_OverlayEnable.BoolValue)
        return Plugin_Stop;

    if (g_iNotifyMode[client] != NOTIFY_OVERLAY)
        return Plugin_Stop;

    if (g_sActiveOverlayName[client][0] == '\0')
        return Plugin_Stop;

    char folder[PLATFORM_MAX_PATH];
    g_cvar_OverlayFolder.GetString(folder, sizeof(folder));

    char overlayPath[PLATFORM_MAX_PATH];
    Format(overlayPath, sizeof(overlayPath), "%s/%s", folder, g_sActiveOverlayName[client]);

    ClientCommand(client, "r_screenoverlay \"%s\"", overlayPath);

    return Plugin_Stop;
}

public Action Timer_RefreshKillOverlay(Handle timer, DataPack pack)
{
	pack.Reset();

	int userid = pack.ReadCell();
	int serial = pack.ReadCell();

	int client = GetClientOfUserId(userid);

	if (client <= 0 || client > MaxClients)
		return Plugin_Stop;

	if (!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Stop;

	if (serial != g_iOverlaySerial[client])
	{
		g_hOverlayRefreshTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	if (!g_cvar_OverlayEnable.BoolValue)
	{
		g_hOverlayRefreshTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	if (g_sActiveOverlayName[client][0] == '\0')
	{
		g_hOverlayRefreshTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	char folder[PLATFORM_MAX_PATH];
	g_cvar_OverlayFolder.GetString(folder, sizeof(folder));

	char overlayPath[PLATFORM_MAX_PATH];
	Format(overlayPath, sizeof(overlayPath), "%s/%s", folder, g_sActiveOverlayName[client]);

	ClientCommand(client, "r_screenoverlay \"%s\"", overlayPath);

	return Plugin_Continue;
}

void GetStreakOverlayName(int kills, char[] buffer, int maxlen)
{
	buffer[0] = '\0';

	if (kills == NH_ULTRAKILL_KILLS)
	{
		strcopy(buffer, maxlen, "ultrakill_nh_quakecso_2048");
	}
	else if (kills == NH_MONSTERKILL_KILLS)
	{
		strcopy(buffer, maxlen, "monsterkill_nh_quakecso_2048");
	}
	else if (kills == NH_GODLIKE_KILLS)
	{
		strcopy(buffer, maxlen, "godlike_nh_quakecso_2048");
	}
	else if (kills == NH_UNSTOPPABLE_KILLS)
	{
		strcopy(buffer, maxlen, "unstoppable_nh_quakecso_2048");
	}
	else if (kills == NH_RAMPAGE_KILLS)
	{
		strcopy(buffer, maxlen, "rampage_nh_quakecso_2048");
	}
	else if (kills == NH_DOMINATING_KILLS)
	{
		strcopy(buffer, maxlen, "dominating_nh_quakecso_2048");
	}
	else if (kills == NH_MEGAKILL_KILLS)
	{
		strcopy(buffer, maxlen, "megakill_nh_quakecso_2048");
	}
	else if (kills == NH_HEXAKILL_KILLS)
	{
		strcopy(buffer, maxlen, "hexakill_nh_quakecso_2048");
	}
	else if (kills == NH_HEPTAKILL_KILLS)
	{
		strcopy(buffer, maxlen, "heptakill_nh_quakecso_2048");
	}
	else if (kills == NH_OCTAKILL_KILLS)
	{
		strcopy(buffer, maxlen, "octakill_nh_quakecso_2048");
	}
	else if (kills == NH_ENNEAKILL_KILLS)
	{
		strcopy(buffer, maxlen, "enneakill_nh_quakecso_2048");
	}
	else if (kills == NH_DECAKILL_KILLS)
	{
		strcopy(buffer, maxlen, "decakill_nh_quakecso_2048");
	}
	else if (kills == NH_MULTIKILL_KILLS)
	{
		strcopy(buffer, maxlen, "multikill_nh_quakecso_2048");
	}
	else if (kills == NH_TRIPLEKILL_KILLS)
	{
		strcopy(buffer, maxlen, "triplekill_nh_quakecso_2048");
	}
	else if (kills == NH_DOUBLEKILL_KILLS)
	{
		strcopy(buffer, maxlen, "doublekill_nh_quakecso_2048");
	}
}

void GetStreakName(int kills, char[] buffer, int maxlen)
{
    buffer[0] = '\0';

    if (kills == g_iDoubleKillThreshold)
    {
        strcopy(buffer, maxlen, "Double Kill");
    }
    else if (kills == g_iTripleKillThreshold)
    {
        strcopy(buffer, maxlen, "Triple Kill");
    }
    else if (kills == g_iMultiKillThreshold)
    {
        strcopy(buffer, maxlen, "Multi Kill");
    }
    else if (kills == g_iMegaKillThreshold)
    {
        strcopy(buffer, maxlen, "Mega Kill");
    }
    else if (kills == NH_HEXAKILL_KILLS)
	{
		strcopy(buffer, maxlen, "Hexa Kill");
	}
	else if (kills == NH_HEPTAKILL_KILLS)
	{
		strcopy(buffer, maxlen, "Hepta Kill");
	}
	else if (kills == NH_OCTAKILL_KILLS)
	{
		strcopy(buffer, maxlen, "Octa Kill");
	}
	else if (kills == NH_ENNEAKILL_KILLS)
	{
		strcopy(buffer, maxlen, "Ennea Kill");
	}
	else if (kills == NH_DECAKILL_KILLS)
	{
		strcopy(buffer, maxlen, "Deca Kill");
	}
    else if (kills == NH_DOMINATING_KILLS)
	{
		strcopy(buffer, maxlen, "Dominating");
	}
    else if (kills == g_iKillingSpreeThreshold)
    {
        strcopy(buffer, maxlen, "Rampage");
    }
    else if (kills == g_iUnstoppableThreshold)
    {
        strcopy(buffer, maxlen, "Unstoppable");
    }
    else if (kills == g_iGodlikeThreshold)
    {
        strcopy(buffer, maxlen, "Godlike");
    }
    else if (kills == g_iMonsterkillThreshold)
    {
        strcopy(buffer, maxlen, "Monster Kill");
    }
    else if (kills == g_iUltrakillThreshold)
    {
        strcopy(buffer, maxlen, "Ultra Kill");
    }
}

int NH_GetStreakEventKill(int kills)
{
	switch (kills)
	{
		case NH_RAMPAGE_KILLS:        return NH_RAMPAGE_KILLS;
		case NH_DOMINATING_KILLS:     return NH_DOMINATING_KILLS;
		case NH_UNSTOPPABLE_KILLS:    return NH_UNSTOPPABLE_KILLS;
		case NH_GODLIKE_KILLS:        return NH_GODLIKE_KILLS;
		case NH_MONSTERKILL_KILLS:    return NH_MONSTERKILL_KILLS;
		case NH_ULTRAKILL_KILLS:      return NH_ULTRAKILL_KILLS;
	}

	return 0;
}

void GetStreakDisplayName(const char[] attackerName, int kills, char[] buffer, int maxlen)
{
	buffer[0] = '\0';

	if (kills == NH_ULTRAKILL_KILLS)
	{
		Format(buffer, maxlen, "%s reached an ULTRA KILL!", attackerName);
	}
	else if (kills == NH_MONSTERKILL_KILLS)
	{
		Format(buffer, maxlen, "%s became a MONSTER KILLER!", attackerName);
	}
	else if (kills == NH_GODLIKE_KILLS)
	{
		Format(buffer, maxlen, "%s is GODLIKE!", attackerName);
	}
	else if (kills == NH_UNSTOPPABLE_KILLS)
	{
		Format(buffer, maxlen, "%s is UNSTOPPABLE!", attackerName);
	}
	else if (kills == NH_DOMINATING_KILLS)
	{
		Format(buffer, maxlen, "%s is DOMINATING!", attackerName);
	}
	else if (kills == NH_RAMPAGE_KILLS)
	{
		Format(buffer, maxlen, "%s is on a RAMPAGE!", attackerName);
	}
	else if (kills == NH_MEGAKILL_KILLS)
	{
		Format(buffer, maxlen, "%s got a MEGA KILL!", attackerName);
	}
	else if (kills == NH_HEXAKILL_KILLS)
	{
		Format(buffer, maxlen, "%s got a HEXA KILL!", attackerName);
	}
	else if (kills == NH_HEPTAKILL_KILLS)
	{
		Format(buffer, maxlen, "%s got a HEPTA KILL!", attackerName);
	}
	else if (kills == NH_OCTAKILL_KILLS)
	{
		Format(buffer, maxlen, "%s got an OCTA KILL!", attackerName);
	}
	else if (kills == NH_ENNEAKILL_KILLS)
	{
		Format(buffer, maxlen, "%s got an ENNEA KILL!", attackerName);
	}
	else if (kills == NH_DECAKILL_KILLS)
	{
		Format(buffer, maxlen, "%s got a DECA KILL!", attackerName);
	}
	else if (kills == NH_MULTIKILL_KILLS)
	{
		Format(buffer, maxlen, "%s got a MULTI KILL!", attackerName);
	}
	else if (kills == NH_TRIPLEKILL_KILLS)
	{
		Format(buffer, maxlen, "%s got a TRIPLE KILL!", attackerName);
	}
	else if (kills == NH_DOUBLEKILL_KILLS)
	{
		Format(buffer, maxlen, "%s got a DOUBLE KILL!", attackerName);
	}
}
