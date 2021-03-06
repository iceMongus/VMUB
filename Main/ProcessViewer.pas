unit ProcessViewer;

interface

uses
   Windows, SysUtils, Classes, TLHelp32, Math, PSAPI;

type
   TWindowItem = record
      WCaption: string;
      Handle: Int64;
      WClass: string;
   end;

var
   AllWindowsList: array of TWindowItem;
   FCount, FCapacity, lcw1, lcw2: Integer;
   WClassToFind1, WClassToFind2: string;

function EnumWindowsProc(hWnd: HWND; lParam: LPARAM): Bool; stdcall;
function EnumWindowsClassProc(hWnd: HWND; lParam: LPARAM): Bool; stdcall;
function EnumWindows2ClassProc(hWnd: HWND; lParam: LPARAM): Bool; stdcall;
procedure GetAllWindowsList(const WClassToFind1: string = ''; const WClassToFind2: string = '');
function EnumThreadWndProc(HWND: HWND; aParam: LongInt): Boolean; stdcall;
procedure GetWndThrList(const ThreadID: THandle);
function GetFileNameFromHandle(Handle: Int64): string;
function GetFileNameAndThreadFromHandle(Handle: Int64; var ProcessID: THandle): string;

implementation

procedure GetAllWindowsList(const WClassToFind1: string = ''; const WClassToFind2: string = '');
begin
   if Length(AllWindowsList) > 0 then
      SetLength(AllWindowsList, 0);
   if WClassToFind1 = '' then
   begin
      SetLength(AllWindowsList, 100);
      FCount := 0;
      FCapacity := 100;
      EnumWindows(@EnumWindowsProc, 0);
   end
   else
   begin
      lcw1 := Length(WClassToFind1);
      if WClassToFind2 = '' then
      begin
         SetLength(AllWindowsList, 10);
         FCount := 0;
         FCapacity := 10;
         ProcessViewer.WClassToFind1 := WClassToFind1;
         EnumWindows(@EnumWindowsClassProc, 0);
      end
      else
      begin
         lcw2 := Length(WClassToFind2);
         SetLength(AllWindowsList, 20);
         FCount := 0;
         FCapacity := 20;
         ProcessViewer.WClassToFind1 := WClassToFind1;
         ProcessViewer.WClassToFind2 := WClassToFind2;
         EnumWindows(@EnumWindows2ClassProc, 0);
      end;
   end;
   if Length(AllWindowsList) <> FCount then
      SetLength(AllWindowsList, FCount);
end;

function EnumWindowsProc(hWnd: HWND; lParam: LPARAM): Bool;
var
   WCaption, WClass: array[0..255] of Char;
begin
   try
      GetWindowText(hWnd, WCaption, 255);
      GetClassName(hwnd, WClass, 255);
      Inc(FCount);
      if FCount > FCapacity then
      begin
         FCapacity := Ceil(1.1 * FCount);
         SetLength(AllWindowsList, FCapacity);
      end;
      AllWindowsList[FCount - 1].WCaption := WCaption;
      AllWindowsList[FCount - 1].WClass := WClass;
      AllWindowsList[FCount - 1].Handle := hWnd;
   except
   end;
   Result := True;
end;

function EnumWindowsClassProc(hWnd: HWND; lParam: LPARAM): Bool;
var
   WCaption, WClass: array[0..255] of Char;
   i: Integer;
begin
   try
      GetClassName(hwnd, WClass, 255);
      if Integer(StrLen(WClass)) = lcw1 then
      begin
         i := 0;
         while i < lcw1 do
         begin
            if WClass[i] <> WClassToFind1[i + 1] then
            begin
               Result := True;
               Exit;
            end;
            Inc(i);
         end;
      end;
      GetWindowText(hWnd, WCaption, 255);
      Inc(FCount);
      if FCount > FCapacity then
      begin
         FCapacity := Ceil(1.1 * FCount);
         SetLength(AllWindowsList, FCapacity);
      end;
      AllWindowsList[FCount - 1].WCaption := WCaption;
      AllWindowsList[FCount - 1].WClass := WClass;
      AllWindowsList[FCount - 1].Handle := hWnd;
   except
   end;
   Result := True;
end;

function EnumWindows2ClassProc(hWnd: HWND; lParam: LPARAM): Bool;
var
   WCaption, WClass: array[0..255] of Char;
   i, l: Integer;
begin
   try
      GetClassName(hwnd, WClass, 255);
      l := StrLen(WClass);
      if l = lcw1 then
      begin
         i := 0;
         while i < lcw1 do
         begin
            if WClass[i] <> WClassToFind1[i + 1] then
            begin
               Result := True;
               Exit;
            end;
            Inc(i);
         end;
      end;
      if l = lcw2 then
      begin
         i := 0;
         while i < lcw2 do
         begin
            if WClass[i] <> WClassToFind2[i + 1] then
            begin
               Result := True;
               Exit;
            end;
            Inc(i);
         end;
      end;
      GetWindowText(hWnd, WCaption, 255);
      Inc(FCount);
      if FCount > FCapacity then
      begin
         FCapacity := Ceil(1.1 * FCount);
         SetLength(AllWindowsList, FCapacity);
      end;
      AllWindowsList[FCount - 1].WCaption := WCaption;
      AllWindowsList[FCount - 1].WClass := WClass;
      AllWindowsList[FCount - 1].Handle := hWnd;
   except
   end;
   Result := True;
end;

procedure GetWndThrList(const ThreadID: THandle);
begin
   if Length(AllWindowsList) > 0 then
      SetLength(AllWindowsList, 0);
   SetLength(AllWindowsList, 10);
   FCount := 0;
   FCapacity := 10;
   EnumThreadWindows(ThreadID, @EnumThreadWndProc, LongInt(AllWindowsList));
   if Length(AllWindowsList) <> FCount then
      SetLength(AllWindowsList, FCount);
end;

function EnumThreadWndProc(HWND: HWND; aParam: LongInt): Boolean; stdcall;
var
   WCaption, WClass: array[0..255] of Char;
begin
   try
      GetWindowText(hWnd, WCaption, 255);
      GetClassName(hwnd, WClass, 255);
      Inc(FCount);
      if FCount > FCapacity then
      begin
         FCapacity := Ceil(1.1 * FCount);
         SetLength(AllWindowsList, FCapacity);
      end;
      AllWindowsList[FCount - 1].WCaption := WCaption;
      AllWindowsList[FCount - 1].WClass := WClass;
      AllWindowsList[FCount - 1].Handle := hWnd;
   except
   end;
   Result := True;
end;

function GetFileNameFromHandle(Handle: Int64): string;
var
   PID: DWord;
   aSnapShotHandle: THandle;
   ContinueLoop: Boolean;
   aProcessEntry32: TProcessEntry32W;
begin
   GetWindowThreadProcessID(Handle, @PID);
   aSnapShotHandle := CreateToolHelp32SnapShot(TH32CS_SNAPPROCESS, 0);
   aProcessEntry32.dwSize := SizeOf(aProcessEntry32);
   ContinueLoop := Process32First(aSnapShotHandle, aProcessEntry32);
   while Integer(ContinueLoop) <> 0 do
   begin
      if aProcessEntry32.th32ProcessID = PID then
      begin
         Result := WideLowerCase(aProcessEntry32.szExeFile);
         Break;
      end;
      ContinueLoop := Process32Next(aSnapShotHandle, aProcessEntry32);
   end;
   CloseHandle(aSnapShotHandle);
end;

function GetFileNameAndThreadFromHandle(Handle: Int64; var ProcessID: THandle): string;
var
   PID: DWord;
   aSnapShotHandle: THandle;
   ContinueLoop: Boolean;
   aProcessEntry32: TProcessEntry32W;
begin
   GetWindowThreadProcessID(Handle, @PID);
   aSnapShotHandle := CreateToolHelp32SnapShot(TH32CS_SNAPPROCESS, 0);
   aProcessEntry32.dwSize := SizeOf(aProcessEntry32);
   ContinueLoop := Process32First(aSnapShotHandle, aProcessEntry32);
   while Integer(ContinueLoop) <> 0 do
   begin
      if aProcessEntry32.th32ProcessID = PID then
      begin
         Result := WideLowerCase(aProcessEntry32.szExeFile);
         ProcessID := aProcessEntry32.th32ProcessID;
         Break;
      end;
      ContinueLoop := Process32Next(aSnapShotHandle, aProcessEntry32);
   end;
   CloseHandle(aSnapShotHandle);
end;

end.

