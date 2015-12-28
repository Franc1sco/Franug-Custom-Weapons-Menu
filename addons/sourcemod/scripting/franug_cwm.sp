#include <sourcemod>
#include <sdktools>
#include <fpvm_interface>

#define DATA "1.0"

char sConfig[PLATFORM_MAX_PATH];
Handle kv;

char client_w[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "SM FPVMI - Custom Weapons Menu",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
}

public OnPluginStart()
{
	CreateConVar("sm_customweaponsmenu_version", DATA, "plugin info", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegConsoleCmd("sm_cw", Command_cw);
}

public OnMapStart()
{
	RefreshKV();
	Downloads();
}

public void RefreshKV()
{
	BuildPath(Path_SM, sConfig, PLATFORM_MAX_PATH, "configs/franug_cwm/configuration.txt");
	
	if(kv != INVALID_HANDLE) CloseHandle(kv);
	
	kv = CreateKeyValues("CustomModels");
	FileToKeyValues(kv, sConfig);
}

Downloads()
{
	decl String:imFile[PLATFORM_MAX_PATH];
	decl String:line[192];
	
	BuildPath(Path_SM, imFile, sizeof(imFile), "configs/franug_cwm/downloads.txt");
	
	new Handle:file = OpenFile(imFile, "r");
	
	if(file != INVALID_HANDLE)
	{
		while (!IsEndOfFile(file))
		{
			if (!ReadFileLine(file, line, sizeof(line)))
			{
				break;
			}
			
			TrimString(line);
			if( strlen(line) > 0 && (FileExists(line) || FileExists(line, true)))
			{
				AddFileToDownloadsTable(line);
			}
		}

		CloseHandle(file);
	}
	else
	{
		LogError("[SM] no file found for downloads (configs/franug_cwm/downloads.txt)");
	}
}

public Action Command_cw(int client, int args)
{	
	char temp[64];
	Menu menu_cw = new Menu(Menu_Handler);
	SetMenuTitle(menu_cw, "Select a weapon");
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetSectionName(kv, temp, 64);
			AddMenuItem(menu_cw, temp, temp);
			
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);

	DisplayMenu(menu_cw, client, 0);
	return Plugin_Handled;
}

public int Menu_Handler(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{

			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			Format(client_w[client], 64, item);
			
			KvJumpToKey(kv, item);
			
			char temp[64];
			Menu menu_cw = new Menu(Menu_Handler2);
			SetMenuTitle(menu_cw, "Select a custom view model");
			AddMenuItem(menu_cw, "default", "Default model");
			if(KvGotoFirstSubKey(kv))
			{
				do
				{
					KvGetSectionName(kv, temp, 64);
					AddMenuItem(menu_cw, temp, temp);
			
				} while (KvGotoNextKey(kv));
			}
			KvRewind(kv);
			DisplayMenu(menu_cw, client, 0);
		}
		case MenuAction_End:
		{
			//param1 is MenuEnd reason, if canceled param2 is MenuCancel reason
			CloseHandle(menu);

		}

	}
}

public int Menu_Handler2(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{

			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			if(StrEqual(item, "default"))
			{
				FPVMI_RemoveViewModelToClient(client, client_w[client]);
				PrintToChat(client, "Now you have the default weapon model");
				return;
			}
			KvJumpToKey(kv, client_w[client]);
			KvJumpToKey(kv, item);
			
			char cwmodel[PLATFORM_MAX_PATH];
			KvGetString(kv, "model", cwmodel, PLATFORM_MAX_PATH);
			char flag[8];
			KvGetString(kv, "flag", flag, 8, "");
			if(HasPermission(client, flag))
			{
				FPVMI_AddViewModelToClient(client, client_w[client], PrecacheModel(cwmodel));
				PrintToChat(client, "Now you have a custom weapon model in %s", client_w[client]);
			}
			else
			{
				PrintToChat(client, "You dont have access to use this weapon model");
			}
			KvRewind(kv);
		}
		case MenuAction_End:
		{
			//param1 is MenuEnd reason, if canceled param2 is MenuCancel reason
			CloseHandle(menu);

		}

	}
}

stock bool HasPermission(int iClient, char[] flagString) 
{
	if (StrEqual(flagString, "")) 
	{
		return true;
	}
	
	AdminId admin = GetUserAdmin(iClient);
	
	if (admin != INVALID_ADMIN_ID)
	{
		int count, found, flags = ReadFlagString(flagString);
		for (int i = 0; i <= 20; i++) 
		{
			if (flags & (1<<i)) 
			{
				count++;
				
				if (GetAdminFlag(admin, view_as<AdminFlag>(i))) 
				{
					found++;
				}
			}
		}

		if (count == found) {
			return true;
		}
	}

	return false;
} 