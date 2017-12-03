program FireURQ;

uses
  Forms,
  furqWinMain in 'furqWinMain.pas' {MainForm},
  furqBase in 'furqBase.pas',
  furqTypes in 'furqTypes.pas',
  furqAbout in 'furqAbout.pas' {AboutBox};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.Run;
end.
