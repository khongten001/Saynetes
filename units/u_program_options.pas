unit u_program_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  LCLTranslator, Buttons, StdCtrls, ComCtrls, Spin, DividerBevel,
  u_notebook_util, u_common;

type

  { TFormProgramOptions }

  TFormProgramOptions = class(TForm)
    BApply: TSpeedButton;
    ColorButton1: TColorButton;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    CBStage: TComboBox;
    CBSeats: TComboBox;
    DividerBevel2: TDividerBevel;
    DividerBevel3: TDividerBevel;
    DividerBevel4: TDividerBevel;
    DividerBevel5: TDividerBevel;
    DividerBevel6: TDividerBevel;
    DividerBevel7: TDividerBevel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Notebook1: TNotebook;
    PageDMX: TPage;
    PageAudioDevice: TPage;
    PageSequence: TPage;
    PageAppColor: TPage;
    PageAppGeneral: TPage;
    PaintBox1: TPaintBox;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    BOk: TSpeedButton;
    BCancel: TSpeedButton;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    SpinEdit1: TSpinEdit;
    Splitter1: TSplitter;
    TV: TTreeView;
    procedure CBStageSelect(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; {%H-}Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure BOkClick(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure TVSelectionChanged(Sender: TObject);
  private
    FLoadingOptions: boolean;
    FPlaybackDeviceCount, FCaptureDeviceCount: integer;
    procedure RefreshAudioDeviceList;
    procedure UpdateLanguageOnWidgets;
    procedure ProgramOptionsToWidgets;
    procedure WidgetsToProgramOptions;
  public

  end;

type
  TSaynetesLanguage = record
    FullName,
    ShortName: string;
  end;
const
  SupportedLanguages: array [0..1] of TSaynetesLanguage =
     (
       (FullName: 'English'; ShortName: 'en'),
       (FullName: 'Français'; ShortName: 'fr')
     );
type

{ TProgramOptions }

TProgramOptions=class
private
  FLanguage: string;
  FMaxRecentProjectFile: integer;
  FRecentProjects: TStringArray;

  // AUDIO
  FPlaybackDeviceIndex,
  FCaptureDeviceIndex: integer;

  // DMX
  FStageType: TStageType;
  FSeatType: TSeatType;

  FSaveFolder,
  FSaveFileName: string;
  FWorkingProject,
  FWorkingFolder: string;
  FLockSave: boolean;
  function GetLastProject: string;
  procedure InitByDefault;
  procedure SetLanguage(AValue: string);
  procedure SetLastProject(AValue: string);
  procedure SetMaxRecentProjectFile(AValue: integer);
  procedure SetWorkingFolder(AValue: string);
  procedure SetWorkingProject(AValue: string);
public
  constructor Create;
  destructor Destroy; override;

  procedure Save;
  procedure Load;

  procedure LockSave;
  procedure UnlockSave;

  procedure RemoveProjectNameFromRecentList(const aProjectName: string);

  property SaveFolder: string read FSaveFolder;

  // General
  property WorkingProject: string read FWorkingProject write SetWorkingProject;
  property WorkingFolder: string read FWorkingFolder write SetWorkingFolder;

  property LastProjectFileNameUsed: string read GetLastProject write SetLastProject;
  property RecentProjects: TStringArray read FRecentProjects;
  property MaxRecentProjectFile: integer read FMaxRecentProjectFile write SetMaxRecentProjectFile;

  property Language: string read FLanguage write SetLanguage;

  // Audio
  property PlaybackDeviceIndex: integer read FPlaybackDeviceIndex;
  property CaptureDeviceIndex: integer read FCaptureDeviceIndex;


  // DMX
  property StageType: TStageType read FStageType;
  property SeatType: TSeatType read FSeatType;

end;

var
  ProgramOptions: TProgramOptions;


implementation
uses LCLType, ALSound, u_project_manager, u_utils, u_logfile,
  u_resource_string, u_dmx_util, BGRABitmap, BGRABitmapTypes, BGRASVG, Math;

{$R *.lfm}

{ TProgramOptions }

constructor TProgramOptions.Create;
begin
  //FSaveFolder:=CreateAPPSaveFolder('');
  FSaveFolder := Application.Location;
  FSaveFileName := ConcatPaths([FSaveFolder, APP_CONFIG_FILENAME]);
  if not FileExists(FSaveFileName) then
  begin
    InitByDefault;
    Save;
  end;
end;

destructor TProgramOptions.Destroy;
begin
  inherited Destroy;
end;

procedure TProgramOptions.InitByDefault;
begin
  // GENERAL
  FRecentProjects := NIL;
  FMaxRecentProjectFile := 5;
  FLanguage := 'en';

  // Audio
  FPlaybackDeviceIndex := 0;
  FCaptureDeviceIndex := 0;

  // DMX
  FStageType := stRectangle;
  FSeatType := seatType1;
end;

procedure TProgramOptions.SetLanguage(AValue: string);
begin
  if FLanguage = AValue then Exit;
  FLanguage := AValue;
  SetDefaultLang(FLanguage);
  Save;

  Project.UpdateStringAfterLanguageChange;
end;

function TProgramOptions.GetLastProject: string;
begin
  if Length(FRecentProjects) > 0 then
    Result := FRecentProjects[0]
  else
    Result := '';
end;

procedure TProgramOptions.SetLastProject(AValue: string);
var i, j: integer;
  flagFound: boolean;
begin
  if not FileExists(AValue) then exit;

  if Length(FRecentProjects) > 0 then
    if FRecentProjects[0] = AValue then exit;

  flagFound := False;
  for i:=0 to High(FRecentProjects) do
    if FRecentProjects[i] = AValue then
    begin
      flagFound := True;
      for j:=i downto 1 do
        FRecentProjects[j] := FRecentProjects[j-1];
      FRecentProjects[0] := AValue;
      break;
    end;

  if not flagFound then
    Insert(AValue, FRecentProjects, 0);

  if Length(FRecentProjects) > FMaxRecentProjectFile then
    Delete(FRecentProjects, FMaxRecentProjectFile, Length(FRecentProjects)-FMaxRecentProjectFile);

  Save;
end;

procedure TProgramOptions.SetMaxRecentProjectFile(AValue: integer);
begin
  if FMaxRecentProjectFile = AValue then Exit;
  FMaxRecentProjectFile := AValue;
  Save;
end;

procedure TProgramOptions.SetWorkingFolder(AValue: string);
begin
  AValue := ExcludeTrailingPathDelimiter(AValue);
  if FWorkingFolder = AValue then Exit;
  FWorkingFolder := AValue;

  Save;
end;

procedure TProgramOptions.SetWorkingProject(AValue: string);
begin
  if FWorkingProject = AValue then Exit;
  FWorkingProject := AValue;
  Save;
end;

const
  APP_GENERAL_HEADER = '[APPLICATION GENERAL]';
  APP_COLOR_HEADER = '[APPLICATION COLOR]';
  AUDIO_HEADER = '[AUDIO]';
  DMX_HEADER = '[DMX]';

procedure TProgramOptions.Save;
var t: TStringList;
  i: Integer;
  prop: TPackProperty;
begin
  if FLockSave then exit;

  Log.Info('Saving program options to '+FSaveFileName);
  t := TStringList.Create;
  try
   // Application General
   prop.Init('|');
   prop.Add('Language', FLanguage);
   prop.Add('WorkingProject', FWorkingProject);
   prop.Add('WorkingFolder', FWorkingFolder);
   prop.Add('MaxRecent', FMaxRecentProjectFile);
   for i:=0 to High(FRecentProjects) do
     prop.Add('Recent'+i.ToString, FRecentProjects[i]);

   t.Add(APP_GENERAL_HEADER);
   t.Add(prop.PackedProperty);

   // sequence window
     // height of frames

   // Audio
   prop.Init('|');
   prop.Add('Playback', FPlaybackDeviceIndex);
   prop.Add('Capture', FCaptureDeviceIndex);
   t.Add(AUDIO_HEADER);
   t.Add(prop.PackedProperty);

   // DMX
   prop.Init('|');
   prop.Add('Stage', Ord(FStageType));
   prop.Add('Seat', Ord(FSeatType));
   t.Add(DMX_HEADER);
   t.Add(prop.PackedProperty);

   try
     t.SaveToFile(FSaveFileName);
   except
     Log.Error('TProgramOptions.Save - Error while saving TStringList to file "'+FSaveFileName+'"');
   end;
  finally
    t.Free;
  end;
end;

procedure TProgramOptions.Load;
var i, k: integer;
  t: TStringList;
  prop: TSplitProperty;
  s1: string;
begin
  Log.Info('Loading program options from '+FSaveFileName);
  s1 := '';

  LockSave;
  InitByDefault;
  t := TStringList.Create;
  try
    try
      t.LoadFromFile(FSaveFileName);
    except
      Log.Error('TProgramOptions.Load - Error while loading TStringList from file "'+FSaveFileName+'"');
    end;

    k := t.indexOf(APP_GENERAL_HEADER);
    if (k > -1) and (k < t.Count) then
      prop.Split(t.Strings[k+1], '|')
    else
      prop.SetEmpty;

    if prop.StringValueOf('Language', FLanguage, FLanguage) then
      SetDefaultLang(FLanguage);

    prop.StringValueOf('WorkingProject', s1, WorkingProject);
    if FileExists(s1) then WorkingProject := s1
      else WorkingProject := '';

    prop.StringValueOf('WorkingFolder', s1, WorkingFolder);
    if DirectoryExists(s1) then WorkingFolder := s1
      else WorkingFolder := '';

    prop.IntegerValueOf('MaxRecent', FMaxRecentProjectFile, FMaxRecentProjectFile);
    FRecentProjects := NIL;

    for i:=0 to FMaxRecentProjectFile-1 do
     if prop.StringValueOf('Recent'+i.ToString, s1, '') then
       Insert(s1, FRecentProjects, Length(FRecentProjects));

    // sequence window
      // height of the frame

    // Audio
    k := t.IndexOf(AUDIO_HEADER);
    if (k > -1) and (k < t.Count) then
      prop.Split(t.Strings[k+1], '|')
    else
      prop.SetEmpty;
    prop.integerValueOf('Playback', i, 0);
    FPlaybackDeviceIndex := i;
    prop.integerValueOf('Capture', i, 1);
    FCaptureDeviceIndex := i;

    // DMX
    k := t.IndexOf(DMX_HEADER);
    if (k > -1) and (k < t.Count) then
      prop.Split(t.Strings[k+1], '|')
    else
      prop.SetEmpty;
    prop.integerValueOf('Stage', i, 1);
    FStageType := TStageType(EnsureRange(i, 0, Ord(High(TStageType))));
    prop.integerValueOf('Seat', i, 1);
    FSeatType := TSeatType(EnsureRange(i, 0, Ord(High(TSeatType))));
  finally
    t.Free;
    UnLockSave;
  end;
end;

procedure TProgramOptions.LockSave;
begin
  FLockSave := True;
end;

procedure TProgramOptions.UnlockSave;
begin
  FLockSave := False;
end;

procedure TProgramOptions.RemoveProjectNameFromRecentList(
  const aProjectName: string);
var i: integer;
begin
  if aProjectName = '' then exit;

  for i:=0 to High(FRecentProjects) do
  begin
    if FRecentProjects[i] = aProjectName then
    begin
      Delete(FRecentProjects, i, 1);
      Save;
      exit;
    end;
  end;
end;

{ TFormProgramOptions }

procedure TFormProgramOptions.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

procedure TFormProgramOptions.FormCreate(Sender: TObject);
var i: integer;
begin
  ComboBox1.Clear;
  for i:=Low(SupportedLanguages) to High(SupportedLanguages) do
    ComboBox1.Items.Add(SupportedLanguages[i].FullName+' ('+
                        SupportedLanguages[i].ShortName+')');
end;

procedure TFormProgramOptions.CBStageSelect(Sender: TObject);
begin
  ProgramOptions.FStageType := TStageType(CBStage.ItemIndex);
  ProgramOptions.FSeatType := TSeatType(CBSeats.ItemIndex);
  PaintBox1.Invalidate;
end;

procedure TFormProgramOptions.FormShow(Sender: TObject);
begin
  RefreshAudioDeviceList;
  ProgramOptionsToWidgets;
  UpdateLanguageOnWidgets;


  TV.Selected := TV.Items.GetFirstNode;
end;

procedure TFormProgramOptions.BOkClick(Sender: TObject);
begin
  if Sender = BCancel then
  begin
    Close;
    exit;
  end;

  if Sender = BApply then
  begin
    WidgetsToProgramOptions;
    exit;
  end;

  // apply new value and save program options
  WidgetsToProgramOptions;
  ModalResult := mrOk;
end;

procedure TFormProgramOptions.PaintBox1Paint(Sender: TObject);
var ima: TBGRABitmap;
  svg: TBGRASvg;
  aspectRatio: single;
  h, margin: integer;
  f: string;
begin
  with PaintBox1.Canvas do
  begin
    Pen.Color := clActiveCaption;
    Brush.Color := clBlack; // $00242424;
    Brush.Style := bsSolid;
    Rectangle(PaintBox1.ClientRect);
  end;
  margin := ScaleDesignToForm(5);
  h := (PaintBox1.ClientHeight-margin*3) div 2;

  // stage
  f := StageSvgFileFor(TStageType(CBStage.ItemIndex));
  if f <> '' then
  begin
    svg := TBGRASvg.Create(f);
    aspectRatio := svg.WidthAsPixel/svg.HeightAsPixel;
    ima := TBGRABitmap.Create(Trunc(h*aspectRatio), h);

    svg.StretchDraw(ima.Canvas2D, taCenter, tlCenter,
      0, 0, ima.Width, ima.Height);
    ima.Draw(PaintBox1.Canvas, (PaintBox1.ClientWidth-ima.Width) div 2, margin);
    svg.Free;
    ima.Free;
  end;

  // seats
  f := SeatSvgFileFor(TSeatType(CBSeats.ItemIndex));
  if f <> '' then
  begin
    svg := TBGRASvg.Create(f);
    aspectRatio := svg.WidthAsPixel/svg.HeightAsPixel;
    ima := TBGRABitmap.Create(Trunc(h*aspectRatio), h);

    svg.StretchDraw(ima.Canvas2D, taCenter, tlCenter,
      0, 0, ima.Width, ima.Height);
    ima.Draw(PaintBox1.Canvas, (PaintBox1.ClientWidth-ima.Width) div 2, h+margin*2);
    svg.Free;
    ima.Free;
  end;
end;

procedure TFormProgramOptions.TVSelectionChanged(Sender: TObject);
var
  nodeParent: TTreeNode;
  txt: string;
begin
  txt := 'Selected: '+TV.Selected.Text+' Level '+TV.Selected.Level.ToString+' Index'+TV.Selected.Index.ToString;

  nodeParent := TV.Selected;
  while nodeParent.Level <> 0 do
    nodeParent := nodeParent.Parent;
  txt := txt+' - Parent: '+nodeParent.Text+' Level '+nodeParent.Level.ToString+' Index'+nodeParent.Index.ToString;
  Caption := txt;

  case nodeParent.Index of
   0: // Application
     begin
       case TV.Selected.Index of
        0: Notebook1.PageIndex := Notebook1.IndexOf(PageAppGeneral);
        1: Notebook1.PageIndex := Notebook1.IndexOf(PageAppColor);
       end;

     end;
   1: // Sequence
     begin
       Notebook1.PageIndex := Notebook1.IndexOf(PageSequence);
     end;
   2: // Audio
     begin
       Notebook1.PageIndex := Notebook1.IndexOf(PageAudioDevice);
     end;
   3: // DMX
     begin
       Notebook1.PageIndex := Notebook1.IndexOf(PageDMX);
     end;
  end;
end;

procedure TFormProgramOptions.RefreshAudioDeviceList;
var A: TStringArray;
begin
  ComboBox2.Clear;
  A := ALSManager.ListOfPlaybackDeviceName;
  FPlaybackDeviceCount := Length(A);
  if FPlaybackDeviceCount > 0 then ComboBox2.Items.AddStrings(A, False)
    else ComboBox2.Items.Add(SNone);

  ComboBox3.Clear;
  A := ALSManager.ListOfCaptureDeviceName;
  FCaptureDeviceCount := Length(A);
  if FCaptureDeviceCount > 0 then ComboBox3.Items.AddStrings(A, False)
    else ComboBox3.Items.Add(SNone);
end;

procedure TFormProgramOptions.UpdateLanguageOnWidgets;
begin
  BOk.Caption := SOk;
  BCancel.Caption := SCancel;
  BApply.Caption := SApply;

  Label1.Caption := SRequireTheProgramToBeRestarted;
  Label4.Caption := SRequireTheProgramToBeRestarted;
  Label5.Caption := SRequireTheProgramToBeRestarted;

  CBStage.Items.Strings[0] := SNone;
  CBStage.Items.Strings[1] := SRectangle;
  CBStage.Items.Strings[2] := SQuare;
  CBStage.Items.Strings[3] := SHalfCircle;
  CBStage.Items.Strings[4] := SEllipse;
  CBStage.Items.Strings[5] := SCustom1;

  CBSeats.Items.Strings[0] := SNone;
  CBSeats.Items.Strings[1] := SSeats1;
  CBSeats.Items.Strings[2] := SSeats2;
end;

procedure TFormProgramOptions.ProgramOptionsToWidgets;
var i: integer;
begin
  try
    FLoadingOptions := True;

// Application - General
    // language
    for i:=0 to High(SupportedLanguages) do
      if SupportedLanguages[i].ShortName = ProgramOptions.Language then
      begin
        ComboBox1.ItemIndex := i;
        break;
      end;
    // max recent
    SpinEdit1.Value := ProgramOptions.MaxRecentProjectFile;

// Audio
    if FPlaybackDeviceCount = 0 then ComboBox2.ItemIndex := 0
    else begin
      i := ProgramOptions.FPlaybackDeviceIndex;
      if (i < 0) or (i >= FPlaybackDeviceCount) then i := 0;
      ComboBox2.ItemIndex := i;
    end;
    i := ProgramOptions.FCaptureDeviceIndex;
    if (i < 0) or (i >= FCaptureDeviceCount) then i := 0;
    ComboBox3.ItemIndex := i;

// DMX
    CBStage.ItemIndex := Ord(ProgramOptions.FStageType);
    CBSeats.ItemIndex := Ord(ProgramOptions.FSeatType);
  finally
    FLoadingOptions := False;
  end;

end;

procedure TFormProgramOptions.WidgetsToProgramOptions;
begin
  if FLoadingOptions then exit;

  ProgramOptions.LockSave;
  try
// Application - General
   // language
   ProgramOptions.Language := SupportedLanguages[ComboBox1.ItemIndex].ShortName;
   UpdateLanguageOnWidgets;
   // max recent
   ProgramOptions.MaxRecentProjectFile := SpinEdit1.Value;

   // Audio
   if FPlaybackDeviceCount = 0 then ProgramOptions.FPlaybackDeviceIndex := -1
     else ProgramOptions.FPlaybackDeviceIndex := ComboBox2.ItemIndex;
   if FCaptureDeviceCount = 0 then ProgramOptions.FCaptureDeviceIndex := -1
     else ProgramOptions.FCaptureDeviceIndex := ComboBox3.ItemIndex;

   // DMX
   ProgramOptions.FStageType := TStageType(CBStage.ItemIndex);
   ProgramOptions.FSeatType := TSeatType(CBSeats.ItemIndex);

  finally
    ProgramOptions.UnlockSave;
    ProgramOptions.Save;
  end;

end;

end.

