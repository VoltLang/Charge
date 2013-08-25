// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.loader;


version (DynamicSDL):

import watt.library;
import lib.sdl.sdl;

void loadSDL(Loader l)
{
	loadSDL_Audio(l);
	loadSDL_Event(l);
	loadSDL_Joystick(l);
	loadSDL_Keyboard(l);
	loadSDL_Mouse(l);
	loadSDL_RWops(l);
	loadSDL_Timer(l);
	loadSDL_Video(l);

	SDL_Init = cast(typeof(SDL_Init))l("SDL_Init");
	SDL_InitSubSystem = cast(typeof(SDL_InitSubSystem))l("SDL_InitSubSystem");
	SDL_QuitSubSystem = cast(typeof(SDL_QuitSubSystem))l("SDL_QuitSubSystem");
	SDL_WasInit = cast(typeof(SDL_WasInit))l("SDL_WasInit");
	SDL_Quit = cast(typeof(SDL_Quit))l("SDL_Quit");
	return;
}

private:
void loadSDL_Audio(Loader l)
{
	SDL_LoadWAV_RW = cast(typeof(SDL_LoadWAV_RW))l("SDL_LoadWAV_RW");
	SDL_FreeWAV = cast(typeof(SDL_FreeWAV))l("SDL_FreeWAV");
	return;
}

void loadSDL_Event(Loader l)
{
	SDL_PumpEvents = cast(typeof(SDL_PumpEvents))l("SDL_PumpEvents");
	SDL_PeepEvents = cast(typeof(SDL_PeepEvents))l("SDL_PeepEvents");
	SDL_PollEvent = cast(typeof(SDL_PollEvent))l("SDL_PollEvent");
	SDL_WaitEvent = cast(typeof(SDL_WaitEvent))l("SDL_WaitEvent");
	SDL_PushEvent = cast(typeof(SDL_PushEvent))l("SDL_PushEvent");
	SDL_SetEventFilter = cast(typeof(SDL_SetEventFilter))l("SDL_SetEventFilter");
	SDL_GetEventFilter = cast(typeof(SDL_GetEventFilter))l("SDL_GetEventFilter");
	SDL_EventState = cast(typeof(SDL_EventState))l("SDL_EventState");
	return;
}

void loadSDL_Joystick(Loader l)
{
	SDL_NumJoysticks = cast(typeof(SDL_NumJoysticks))l("SDL_NumJoysticks");
	SDL_JoystickName = cast(typeof(SDL_JoystickName))l("SDL_JoystickName");
	SDL_JoystickOpen = cast(typeof(SDL_JoystickOpen))l("SDL_JoystickOpen");
	SDL_JoystickOpened = cast(typeof(SDL_JoystickOpened))l("SDL_JoystickOpened");
	SDL_JoystickIndex = cast(typeof(SDL_JoystickIndex))l("SDL_JoystickIndex");
	SDL_JoystickNumAxes = cast(typeof(SDL_JoystickNumAxes))l("SDL_JoystickNumAxes");
	SDL_JoystickNumBalls = cast(typeof(SDL_JoystickNumBalls))l("SDL_JoystickNumBalls");
	SDL_JoystickNumHats = cast(typeof(SDL_JoystickNumHats))l("SDL_JoystickNumHats");
	SDL_JoystickNumButtons = cast(typeof(SDL_JoystickNumButtons))l("SDL_JoystickNumButtons");
	SDL_JoystickUpdate = cast(typeof(SDL_JoystickUpdate))l("SDL_JoystickUpdate");
	SDL_JoystickEventState = cast(typeof(SDL_JoystickEventState))l("SDL_JoystickEventState");
	SDL_JoystickGetAxis = cast(typeof(SDL_JoystickGetAxis))l("SDL_JoystickGetAxis");
	SDL_JoystickGetHat = cast(typeof(SDL_JoystickGetHat))l("SDL_JoystickGetHat");
	SDL_JoystickGetBall = cast(typeof(SDL_JoystickGetBall))l("SDL_JoystickGetBall");
	SDL_JoystickGetButton = cast(typeof(SDL_JoystickGetButton))l("SDL_JoystickGetButton");
	SDL_JoystickClose = cast(typeof(SDL_JoystickClose))l("SDL_JoystickClose");
	return;
}

void loadSDL_Keyboard(Loader l)
{
	SDL_EnableUNICODE = cast(typeof(SDL_EnableUNICODE))l("SDL_EnableUNICODE");
	SDL_EnableKeyRepeat = cast(typeof(SDL_EnableKeyRepeat))l("SDL_EnableKeyRepeat");
	SDL_GetKeyRepeat = cast(typeof(SDL_GetKeyRepeat))l("SDL_GetKeyRepeat");
	SDL_GetKeyState = cast(typeof(SDL_GetKeyState))l("SDL_GetKeyState");
	SDL_GetModState = cast(typeof(SDL_GetModState))l("SDL_GetModState");
	SDL_SetModState = cast(typeof(SDL_SetModState))l("SDL_SetModState");
	SDL_GetKeyName = cast(typeof(SDL_GetKeyName))l("SDL_GetKeyName");
	return;
}

void loadSDL_Mouse(Loader l)
{
	SDL_ShowCursor = cast(typeof(SDL_ShowCursor))l("SDL_ShowCursor");
	SDL_WarpMouse = cast(typeof(SDL_WarpMouse))l("SDL_WarpMouse");
	return;
}

void loadSDL_RWops(Loader l)
{
	SDL_RWFromFile = cast(typeof(SDL_RWFromFile))l("SDL_RWFromFile");
	SDL_RWFromFP = cast(typeof(SDL_RWFromFP))l("SDL_RWFromFP");
	SDL_RWFromMem = cast(typeof(SDL_RWFromMem))l("SDL_RWFromMem");
	SDL_RWFromConstMem = cast(typeof(SDL_RWFromConstMem))l("SDL_RWFromConstMem");
	SDL_AllocRW = cast(typeof(SDL_AllocRW))l("SDL_AllocRW");
	SDL_FreeRW = cast(typeof(SDL_FreeRW))l("SDL_FreeRW");
	SDL_ReadLE16 = cast(typeof(SDL_ReadLE16))l("SDL_ReadLE16");
	SDL_ReadBE16 = cast(typeof(SDL_ReadBE16))l("SDL_ReadBE16");
	SDL_ReadLE32 = cast(typeof(SDL_ReadLE32))l("SDL_ReadLE32");
	SDL_ReadBE32 = cast(typeof(SDL_ReadBE32))l("SDL_ReadBE32");
	SDL_ReadLE64 = cast(typeof(SDL_ReadLE64))l("SDL_ReadLE64");
	SDL_ReadBE64 = cast(typeof(SDL_ReadBE64))l("SDL_ReadBE64");
	SDL_WriteLE16 = cast(typeof(SDL_WriteLE16))l("SDL_WriteLE16");
	SDL_WriteBE16 = cast(typeof(SDL_WriteBE16))l("SDL_WriteBE16");
	SDL_WriteLE32 = cast(typeof(SDL_WriteLE32))l("SDL_WriteLE32");
	SDL_WriteBE32 = cast(typeof(SDL_WriteBE32))l("SDL_WriteBE32");
	SDL_WriteLE64 = cast(typeof(SDL_WriteLE64))l("SDL_WriteLE64");
	SDL_WriteBE64 = cast(typeof(SDL_WriteBE64))l("SDL_WriteBE64");
	return;
}

void loadSDL_Timer(Loader l)
{
	SDL_GetTicks = cast(typeof(SDL_GetTicks))l("SDL_GetTicks");
	SDL_Delay = cast(typeof(SDL_Delay))l("SDL_Delay");
	SDL_SetTimer = cast(typeof(SDL_SetTimer))l("SDL_SetTimer");
	SDL_AddTimer = cast(typeof(SDL_AddTimer))l("SDL_AddTimer");
	SDL_RemoveTimer = cast(typeof(SDL_RemoveTimer))l("SDL_RemoveTimer");
	return;
}

void loadSDL_Video(Loader l)
{
	SDL_VideoInit = cast(typeof(SDL_VideoInit))l("SDL_VideoInit");
	SDL_VideoQuit = cast(typeof(SDL_VideoQuit))l("SDL_VideoQuit");
	SDL_VideoDriverName = cast(typeof(SDL_VideoDriverName))l("SDL_VideoDriverName");
	SDL_GetVideoSurface = cast(typeof(SDL_GetVideoSurface))l("SDL_GetVideoSurface");
	SDL_GetVideoInfo = cast(typeof(SDL_GetVideoInfo))l("SDL_GetVideoInfo");
	SDL_VideoModeOK = cast(typeof(SDL_VideoModeOK))l("SDL_VideoModeOK");
	SDL_ListModes = cast(typeof(SDL_ListModes))l("SDL_ListModes");
	SDL_SetVideoMode = cast(typeof(SDL_SetVideoMode))l("SDL_SetVideoMode");
	SDL_UpdateRects = cast(typeof(SDL_UpdateRects))l("SDL_UpdateRects");
	SDL_UpdateRect = cast(typeof(SDL_UpdateRect))l("SDL_UpdateRect");
	SDL_Flip = cast(typeof(SDL_Flip))l("SDL_Flip");
	SDL_SetGamma = cast(typeof(SDL_SetGamma))l("SDL_SetGamma");
	SDL_SetGammaRamp = cast(typeof(SDL_SetGammaRamp))l("SDL_SetGammaRamp");
	SDL_GetGammaRamp = cast(typeof(SDL_GetGammaRamp))l("SDL_GetGammaRamp");
	SDL_SetColors = cast(typeof(SDL_SetColors))l("SDL_SetColors");
	SDL_SetPalette = cast(typeof(SDL_SetPalette))l("SDL_SetPalette");
	SDL_MapRGB = cast(typeof(SDL_MapRGB))l("SDL_MapRGB");
	SDL_MapRGBA = cast(typeof(SDL_MapRGBA))l("SDL_MapRGBA");
	SDL_GetRGB = cast(typeof(SDL_GetRGB))l("SDL_GetRGB");
	SDL_GetRGBA = cast(typeof(SDL_GetRGBA))l("SDL_GetRGBA");
	SDL_CreateRGBSurface = cast(typeof(SDL_CreateRGBSurface))l("SDL_CreateRGBSurface");
	SDL_CreateRGBSurfaceFrom = cast(typeof(SDL_CreateRGBSurfaceFrom))l("SDL_CreateRGBSurfaceFrom");
	SDL_FreeSurface = cast(typeof(SDL_FreeSurface))l("SDL_FreeSurface");
	SDL_LockSurface = cast(typeof(SDL_LockSurface))l("SDL_LockSurface");
	SDL_UnlockSurface = cast(typeof(SDL_UnlockSurface))l("SDL_UnlockSurface");
	SDL_SaveBMP_RW = cast(typeof(SDL_SaveBMP_RW))l("SDL_SaveBMP_RW");
	SDL_SetColorKey = cast(typeof(SDL_SetColorKey))l("SDL_SetColorKey");
	SDL_SetAlpha = cast(typeof(SDL_SetAlpha))l("SDL_SetAlpha");
	SDL_SetClipRect = cast(typeof(SDL_SetClipRect))l("SDL_SetClipRect");
	SDL_GetClipRect = cast(typeof(SDL_GetClipRect))l("SDL_GetClipRect");
	SDL_ConvertSurface = cast(typeof(SDL_ConvertSurface))l("SDL_ConvertSurface");
	SDL_UpperBlit = cast(typeof(SDL_UpperBlit))l("SDL_UpperBlit");
	SDL_LowerBlit = cast(typeof(SDL_LowerBlit))l("SDL_LowerBlit");
	SDL_FillRect = cast(typeof(SDL_FillRect))l("SDL_FillRect");
	SDL_DisplayFormat = cast(typeof(SDL_DisplayFormat))l("SDL_DisplayFormat");
	SDL_DisplayFormatAlpha = cast(typeof(SDL_DisplayFormatAlpha))l("SDL_DisplayFormatAlpha");
	SDL_CreateYUVOverlay = cast(typeof(SDL_CreateYUVOverlay))l("SDL_CreateYUVOverlay");
	SDL_LockYUVOverlay = cast(typeof(SDL_LockYUVOverlay))l("SDL_LockYUVOverlay");
	SDL_UnlockYUVOverlay = cast(typeof(SDL_UnlockYUVOverlay))l("SDL_UnlockYUVOverlay");
	SDL_DisplayYUVOverlay = cast(typeof(SDL_DisplayYUVOverlay))l("SDL_DisplayYUVOverlay");
	SDL_FreeYUVOverlay = cast(typeof(SDL_FreeYUVOverlay))l("SDL_FreeYUVOverlay");
	SDL_GL_LoadLibrary = cast(typeof(SDL_GL_LoadLibrary))l("SDL_GL_LoadLibrary");
	SDL_GL_GetProcAddress = cast(typeof(SDL_GL_GetProcAddress))l("SDL_GL_GetProcAddress");
	SDL_GL_SetAttribute = cast(typeof(SDL_GL_SetAttribute))l("SDL_GL_SetAttribute");
	SDL_GL_GetAttribute = cast(typeof(SDL_GL_GetAttribute))l("SDL_GL_GetAttribute");
	SDL_GL_SwapBuffers = cast(typeof(SDL_GL_SwapBuffers))l("SDL_GL_SwapBuffers");
	SDL_GL_UpdateRects = cast(typeof(SDL_GL_UpdateRects))l("SDL_GL_UpdateRects");
	SDL_GL_Lock = cast(typeof(SDL_GL_Lock))l("SDL_GL_Lock");
	SDL_GL_Unlock = cast(typeof(SDL_GL_Unlock))l("SDL_GL_Unlock");
	SDL_WM_SetCaption = cast(typeof(SDL_WM_SetCaption))l("SDL_WM_SetCaption");
	SDL_WM_GetCaption = cast(typeof(SDL_WM_GetCaption))l("SDL_WM_GetCaption");
	SDL_WM_SetIcon = cast(typeof(SDL_WM_SetIcon))l("SDL_WM_SetIcon");
	SDL_WM_IconifyWindow = cast(typeof(SDL_WM_IconifyWindow))l("SDL_WM_IconifyWindow");
	SDL_WM_ToggleFullScreen = cast(typeof(SDL_WM_ToggleFullScreen))l("SDL_WM_ToggleFullScreen");
	SDL_WM_GrabInput = cast(typeof(SDL_WM_GrabInput))l("SDL_WM_GrabInput");
	SDL_SoftStretch = cast(typeof(SDL_SoftStretch))l("SDL_SoftStretch");
	return;
}
