/*
**	Command & Conquer Red Alert(tm)
**	Copyright 2025 Electronic Arts Inc.
**
**	This program is free software: you can redistribute it and/or modify
**	it under the terms of the GNU General Public License as published by
**	the Free Software Foundation, either version 3 of the License, or
**	(at your option) any later version.
**
**	This program is distributed in the hope that it will be useful,
**	but WITHOUT ANY WARRANTY; without even the implied warranty of
**	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**	GNU General Public License for more details.
**
**	You should have received a copy of the GNU General Public License
**	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/*****************************************************************************\
          C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S
*******************************************************************************
 File:       main.cpp
 Programmer: Neal Kettler
 
 StartDate:  Feb  6, 1998
 LastUpdate: Feb 10, 1998
-------------------------------------------------------------------------------

 Launcher application for games/apps using the chat API.  This should be
 run by the user and it will start the actual game executable.  If a patch
 file has been downloaded the patch will be applied before starting the game.

 This does not download patches or do version checks, the game/app is responsible
 for that.  This just applies patches that are in the correct location for the
 game.  All patches should be in the "Patches" folder of the app.

 The launcher should have a config file (launcher.cfg) so it knows which apps
 should be checked for patches. The file should look like this:

 # comment
 # RUN = the game to launch
 RUN = . notepad.exe        # directory and app name
 #
 # Sku's to check for patches
 #
 SKU1 = 1100 SOFTWARE\Westwood\WOnline      # skus and registry keys
 SKU2 = 1234 SOFTWARE\Westwood\FakeGame

\*****************************************************************************/


#include "dialog.h"
#include "patch.h"
#include "findpatch.h"
#include "process.h"

#include "wdebug.h"
#include "monod.h"
#include "filed.h"
#include "configfile.h"
#include <windows.h>

#define UPDATE_RETVAL 123456789  // if a program returns this it means it wants to check for patches

void CreatePrimaryWin(char *prefix);
void myChdir(char *path);


//
// Called by WinMain
//
int main(int argc, char *argv[])
{
  char      patchFile[MAX_PATH];
  bit8      ok;
  int       skuIndex=0;
  char      cwd[MAX_PATH];  // save current directory before game start
  _getcwd(cwd,MAX_PATH);

  InitCommonControls();

  #ifdef DEBUG
    ///MonoD outputDevice;
    FileD outputDevice("launcher.out");
    MsgManager::setAllStreams(&outputDevice);
    DBGMSG("Launcher initialized");
  #endif

  
  // Goto the folder where launcher is installed
  myChdir(argv[0]);

  // extract the program name from argv[0].  Change the extension to
  //   .lcf (Launcher ConFig).  This is the name of our config file.
  char  configName[MAX_PATH+3];
  strcpy(configName,argv[0]);
  char *extension=configName;
  char *tempptr;
  while((tempptr=strchr(extension+1,'.')))
    extension=tempptr;
  if (*extension=='.')
    *extension=0;
  strcat(configName,".lcf");

  DBGMSG("Config Name: "<<configName);

  ConfigFile config;
  FILE *in=fopen(configName,"r");
  if (in==NULL)
  {
    MessageBox(NULL,"You must run the game from its install directory.",
      "Launcher config file missing",MB_OK);
    exit(-1);
  }
  ok=config.readFile(in);
  fclose(in);
  if(ok==FALSE)
  {
     MessageBox(NULL,"File 'launcher.cfg' is corrupt","Error",MB_OK);
     exit(-1);
  }


  // Load process info
  Process proc;
  Read_Process_Info(config,proc);

  DBGMSG("Read process info");

  // Create the main window
  ///CreatePrimaryWin(proc.command);

  while((skuIndex=Find_Patch(patchFile,MAX_PATH,config))!=0)
    Apply_Patch(patchFile,config,skuIndex);

  Delete_Patches(config);  // delete all patches

  for (int i=1; i<argc; i++)
  {
    strcat(proc.args," ");
    strcat(proc.args,argv[i]);
  }
  DBGMSG("ARGS: "<<proc.args);

  while(1)
  {
    myChdir(argv[0]);
    Create_Process(proc);
    Wait_Process(proc);

    if((skuIndex=Find_Patch(patchFile,MAX_PATH,config))!=0)
    {
      do
      {
        Apply_Patch(patchFile,config,skuIndex);
      } while((skuIndex=Find_Patch(patchFile,MAX_PATH,config))!=0);
    }
    else
    {
      break;
    }
  }
  myChdir(cwd);

  // Exit normally

  return(0);
}




//
// Create a primary window
//
void CreatePrimaryWin(char *prefix)
{
  HWND                hwnd;
  WNDCLASS            wc;
  char                name[256];

  sprintf(name,"launcher_%s",prefix);

  DBGMSG("CreatePrimary: "<<name);

  /*
  ** set up and register window class
  */
  wc.style = CS_HREDRAW | CS_VREDRAW;
  wc.lpfnWndProc = DefWindowProc;
  wc.cbClsExtra = 0;            // Don't need any extra class data
  wc.cbWndExtra = 0;            // No extra win data
  wc.hInstance = Global_instance;
  wc.hIcon=LoadIcon(Global_instance, MAKEINTRESOURCE(IDI_ICON));
  wc.hCursor = NULL;  /////////LoadCursor( NULL, IDC_ARROW );
  wc.hbrBackground = NULL;
  wc.lpszMenuName = name;
  wc.lpszClassName = name;
  RegisterClass( &wc );
    
  /*
  ** create a window
  */
  hwnd = CreateWindowEx(
      WS_EX_TOPMOST,
      name,
      name,
      WS_POPUP,
      0, 0,
      GetSystemMetrics( SM_CXSCREEN ),
      GetSystemMetrics( SM_CYSCREEN ),
      NULL,
      NULL,
      Global_instance,
      NULL );

  if( !hwnd )
  {
    DBGMSG("Couldn't make window!");
  }
  else
  {
    DBGMSG("Window created!");
  }
}


//void DestroyPrimaryWin(void)
//{
//  DestroyWindow(PrimaryWin);
//  UnregisterClass(classname);
//}



//
// If given a file, it'll goto it's directory.  If on a diff drive,
//   it'll go there.
//
void myChdir(char *path)
{
  char drive[10];
  char dir[255];
  char file[255];
  char ext[64];
  char filepath[513];
  int  abc;

  _splitpath( path, drive, dir, file, ext );
  _makepath ( filepath,   drive, dir, NULL, NULL );

  if ( filepath[ strlen( filepath ) - 1 ] == '\\' ) 
  {
    filepath[ strlen( filepath ) - 1 ] = '\0';
  }
  abc = (unsigned)( toupper( filepath[0] ) - 'A' + 1 ); 
  if ( !_chdrive( abc )) 
  {
    abc = chdir( filepath );  // Will fail with ending '\\'
  }
  // should be in proper folder now....
}








