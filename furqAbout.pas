unit furqAbout;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls;

type
  TAboutBox = class(TForm)
    Panel1: TPanel;
    OKButton: TButton;
    lblVersion: TLabel;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation
uses
 JclFileUtils;

{$R *.dfm}

procedure TAboutBox.FormCreate(Sender: TObject);
begin
 with TJclFileVersionInfo.Create(Application.ExeName) do
 try
  lblVersion.Caption := Format('Версия %s BETA', [FileVersion]);
 finally
  Free;
 end;
end;

end.
 
