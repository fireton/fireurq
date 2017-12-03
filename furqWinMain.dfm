object MainForm: TMainForm
  Left = 353
  Top = 233
  Width = 762
  Height = 657
  Caption = 'fireURQ'
  Color = clWindow
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlInput: TPanel
    Left = 0
    Top = 480
    Width = 746
    Height = 36
    Align = alBottom
    BevelOuter = bvNone
    Caption = 'pnlInput'
    TabOrder = 1
    Visible = False
    DesignSize = (
      746
      36)
    object edtInput: TEdit
      Left = 8
      Top = 8
      Width = 641
      Height = 24
      Anchors = [akLeft, akTop, akRight]
      BevelInner = bvNone
      BevelOuter = bvNone
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Verdana'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object btnEnter: TButton
      Left = 658
      Top = 8
      Width = 65
      Height = 24
      Caption = #1044#1072#1083#1100#1096#1077
      Default = True
      TabOrder = 1
      OnClick = btnEnterClick
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 746
    Height = 480
    Align = alClient
    BevelOuter = bvNone
    Color = clWindow
    ParentBackground = False
    TabOrder = 0
    object JvxSplitter1: TJvxSplitter
      Left = 580
      Top = 0
      Width = 4
      Height = 480
      ControlFirst = memTextOut
      ControlSecond = pnlInventory
      Align = alRight
    end
    object memTextOut: TJvMemo
      Left = 0
      Top = 0
      Width = 580
      Height = 480
      Caret.Width = 1
      ClipboardCommands = [caCopy]
      BevelInner = bvNone
      BevelOuter = bvNone
      Align = alClient
      BorderStyle = bsNone
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Lucida Console'
      Font.Style = []
      HideSelection = False
      ParentFlat = False
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
      WantReturns = False
      OnKeyPress = memTextOutKeyPress
      OnMouseMove = memTextOutMouseMove
    end
    object pnlInventory: TPanel
      Left = 584
      Top = 0
      Width = 162
      Height = 480
      Align = alRight
      TabOrder = 2
      object lbInventory: TListBox
        Left = 1
        Top = 34
        Width = 160
        Height = 445
        Align = alClient
        BevelOuter = bvNone
        BorderStyle = bsNone
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Verdana'
        Font.Style = []
        ItemHeight = 16
        ParentFont = False
        TabOrder = 0
        OnClick = lbInventoryClick
        OnMouseMove = lbButtonsMouseMove
      end
      object Panel1: TPanel
        Left = 1
        Top = 1
        Width = 160
        Height = 33
        Align = alTop
        TabOrder = 1
        DesignSize = (
          160
          33)
        object btnAction: TSpeedButton
          Left = 5
          Top = 4
          Width = 150
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          Caption = #1044#1077#1081#1089#1090#1074#1080#1103
          Enabled = False
          Flat = True
          Font.Charset = RUSSIAN_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Verdana'
          Font.Style = []
          ParentFont = False
          OnClick = btnActionClick
          OnMouseMove = btnActionMouseMove
        end
      end
    end
  end
  object JvxSplitter2: TJvxSplitter
    Left = 0
    Top = 516
    Width = 746
    Height = 3
    ControlFirst = Panel2
    ControlSecond = lbButtons
    Align = alBottom
  end
  object lbButtons: TListBox
    Left = 0
    Top = 519
    Width = 746
    Height = 80
    Style = lbOwnerDrawFixed
    Align = alBottom
    BorderStyle = bsNone
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Verdana'
    Font.Style = []
    IntegralHeight = True
    ItemHeight = 20
    ParentFont = False
    TabOrder = 3
    OnClick = lbButtonsClick
    OnDrawItem = lbButtonsDrawItem
    OnMouseMove = lbButtonsMouseMove
  end
  object XPManifest1: TXPManifest
    Left = 464
    Top = 64
  end
  object dlgOpenQuest: TOpenDialog
    DefaultExt = 'qst'
    Filter = #1050#1074#1077#1089#1090#1099' URQ (*.qst;*.qs1;*.qs2)|*.qst;*.qs1;*.qs2'
    Title = #1042#1099#1073#1077#1088#1080#1090#1077' '#1092#1072#1081#1083' '#1080#1075#1088#1099
    Left = 424
    Top = 64
  end
  object ActionList1: TActionList
    Left = 8
    Top = 40
    object actOpenQuest: TAction
      Category = #1060#1072#1081#1083
      Caption = #1054#1090#1082#1088#1099#1090#1100' '#1092#1072#1081#1083'...'
      ShortCut = 16463
      OnExecute = actOpenQuestExecute
    end
    object actFileExit: TFileExit
      Category = #1060#1072#1081#1083
      Caption = #1042#1099#1093#1086#1076
      Hint = 'Exit|Quits the application'
      ImageIndex = 43
    end
    object actLoadSaved: TAction
      Category = #1060#1072#1081#1083
      Caption = #1047#1072#1075#1088#1091#1079#1080#1090#1100' '#1089#1086#1093#1088#1072#1085#1077#1085#1085#1091#1102' '#1080#1075#1088#1091'...'
      Enabled = False
      OnExecute = actLoadSavedExecute
    end
    object actStartOver: TAction
      Category = #1060#1072#1081#1083
      Caption = #1053#1072#1095#1072#1090#1100' '#1080#1075#1088#1091' '#1079#1072#1085#1086#1074#1086
      Enabled = False
      OnExecute = actStartOverExecute
    end
  end
  object MainMenu: TMainMenu
    Left = 48
    Top = 40
    object Afq1: TMenuItem
      Caption = #1060#1072#1081#1083
      object N1: TMenuItem
        Action = actOpenQuest
      end
      object N5: TMenuItem
        Action = actStartOver
      end
      object N4: TMenuItem
        Action = actLoadSaved
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object N2: TMenuItem
        Action = actFileExit
      end
    end
    object G1: TMenuItem
      Caption = #1055#1086#1084#1086#1097#1100
      object miAbout: TMenuItem
        Caption = #1054' '#1087#1088#1086#1075#1088#1072#1084#1084#1077'...'
        OnClick = miAboutClick
      end
    end
  end
  object SaveDlg: TSaveDialog
    DefaultExt = 'sav'
    Filter = #1060#1072#1081#1083#1099' '#1089#1086#1093#1088#1072#1085#1077#1085#1080#1081' (*.sav)|*.sav'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Title = #1047#1072#1087#1080#1089#1100' '#1080#1075#1088#1099
    Left = 8
    Top = 72
  end
  object LoadDlg: TOpenDialog
    DefaultExt = 'sav'
    Filter = #1060#1072#1081#1083#1099' '#1089#1086#1093#1088#1072#1085#1077#1085#1080#1081' (*.sav)|*.sav'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing, ofDontAddToRecent]
    Title = #1047#1072#1075#1088#1091#1079#1082#1072' '#1089#1086#1093#1088#1072#1085#1077#1085#1080#1103
    Left = 48
    Top = 72
  end
  object PauseTimer: TTimer
    Enabled = False
    OnTimer = PauseTimerTimer
    Left = 8
    Top = 112
  end
end
