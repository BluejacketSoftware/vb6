Attribute VB_Name = "MFileSystem"
Option Explicit
Public Enum LNFileType
    ftUnKnown = 0
    ftIE = 2
    ftExE = 4
    ftCHM = 8
    ftIMG = 16
    ftAUDIO = 32
    ftVIDEO = 64
    ftHTML = 128
    ftZIP = 256
    ftTxt = 512
    ftZhtm = 1024
    ftRTF = 3
End Enum
Private Enum LNIfStringNotFound
    ReturnOriginalStr = 1
    ReturnEmptyStr = 0
End Enum
Public Enum LNPathType
    LNUnKnown = 0
    LNFolder = 1
    LNFile = 2
End Enum
Public Enum LNPathStyle
    lnpsDos = 0
    lnpsUnix = 1
End Enum
Public Enum LNLOOKFOR
    LN_FILE_prev
    LN_FILE_next
    LN_FILE_RAND
End Enum
Private Const cMaxPath = 256
Private Const MAX_PATH As Long = 260
Private Const FileSystem_Invalid_Path_Chars As String = """*?<>"
Private Const FileSystem_Invalid_Filename_Chars As String = """/\:*?<>"



Private Declare Function APIGetFullPathName Lib "kernel32" Alias "GetFullPathNameW" (ByVal lpFileName As Long, ByVal nBufferLength As Long, ByVal lpBuffer As Long, ByVal lpFilePart As Long) As Long

Private Declare Function APIMoveFileEx Lib "kernel32" Alias "MoveFileExW" (ByVal lpExistingFileName As String, ByVal lpNewFileName As String, ByVal dwFlags As Long) As Long
'Private Declare Function APIMoveFile Lib "kernel32" Alias "MoveFileA" (ByVal lpExistingFileName As Long, ByVal lpNewFileName As Long) As Long

Private Declare Function APIMoveFile Lib "kernel32" Alias "MoveFileA" (ByVal lpExistingFileName As String, ByVal lpNewFileName As String) As Long

Private Declare Function APIGetTempFileName Lib "kernel32" Alias "GetTempFileNameW" (ByVal lpszPath As Long, ByVal lpPrefixString As Long, ByVal wUnique As Long, ByVal lpTempFileName As Long) As Long
Private Declare Function APIGetTempPath Lib "kernel32" Alias "GetTempPathW" (ByVal nBufferLength As Long, ByVal lpBuffer As Long) As Long
Private Declare Function APIGetShortPathName Lib "kernel32" Alias "GetShortPathNameW" (ByVal lpszLongPath As String, ByVal lpszShortPath As String, ByVal cchBuffer As Long) As Long

Public Enum FS_OpenFileMode
    FS_OFM_INPUT
    FS_OFM_OUTPUT
    FS_OFM_RANDOM
    FS_OFM_BINARY
    FS_OFM_BINARY_READ
    FS_OFM_BINARY_WRITE
    FS_OFM_BINARY_READWRITE
End Enum
Private Function ConvertCString(ByRef vSource As String) As String
    Dim I As Long
    I = InStr(vSource, Chr$(0))
    If (I > 0) Then
        ConvertCString = Left$(vSource, I - 1)
    End If
End Function


Public Function GetTempPath() As String
    Dim buffer As String
    buffer = String$(MAX_PATH, " ")
    If (APIGetTempPath(MAX_PATH, StrPtr(buffer)) <> 0) Then
        GetTempPath = ConvertCString(buffer)
    End If
    
End Function

Public Function CreateTempFile(Optional TempPath As String = vbNullString, Optional Prefix As String = vbNullString) As String
    If TempPath = vbNullString Then TempPath = GetTempPath
    If Prefix = vbNullString Then Prefix = "###"
    Dim buffer As String
    buffer = String$(MAX_PATH, " ")
    If APIGetTempFileName(StrPtr(TempPath), StrPtr(Prefix), 0, StrPtr(buffer)) <> 0 Then
        CreateTempFile = ConvertCString(buffer)
    End If
    End Function

Public Function FileExists(ByRef strPath As String) As Boolean
On Error Resume Next
FileExists = False
If GetAttr(strPath) And vbArchive Then
If Err = 0 Then FileExists = True
End If
Err.Clear
End Function
Public Function FolderExists(ByRef strPath As String) As Boolean
On Error Resume Next
FolderExists = False
If GetAttr(strPath) And vbDirectory Then
    If Err = 0 Then FolderExists = True
End If
Err.Clear
End Function

Function PathExists(ByRef PathName As String) As Boolean

    Dim Temp$
    'Set Default
    PathExists = True
    Temp$ = Replace$(PathName, "/", "\")

    If Right$(Temp$, 1) = "\" Then Temp$ = Left$(Temp$, Len(Temp$) - 1)
    'Set up error handler
    On Error Resume Next
    'Attempt to grab date and time
    Temp$ = GetAttr(Temp$)
    'Process errors

    If Err <> 0 Then PathExists = False
    '    Select Case Err
    '    Case 53, 76, 68   'File Does Not Exist
    '        modFile_FileExists = False
    '        Err = 0
    '    Case Else
    '
    '        If Err <> 0 Then
    '            MsgBox "Error Number: " & Err & Chr$(10) & Chr$(13) & " " & Error, vbOKOnly, "Error"
    '            End
    '        End If
    '
    '    End Select
    Err.Clear
End Function

Function BuildPath(ByVal sPathIn As String, Optional ByVal sFileNameIn As String, Optional lnps As LNPathStyle = lnpsDos) As String

    '*******************************************************************
    '
    '  PURPOSE: Takes a path (including Drive letter and any subdirs) and
    '           concatenates the file name to path. Path may be empty, path
    '           may or may not have an ending backslash '\'.  No validation
    '           or existance is check on path or file.
    '
    '  INPUTS:  sPathIn - Path to use
    '           sFileNameIn - Filename to use
    '
    '
    '  OUTPUTS:  N/A
    '
    '  RETURNS:  Path concatenated to File.
    '
    '*******************************************************************
    '    Dim sPath As String
    '    Dim sFilename As String
    '    'Remove any leading or trailing spaces
    '    sPath = Trim$(sPathIn)
    '    sFilename = Trim$(sFileNameIn)
    Dim sSlash As String

    If lnps = lnpsDos Then
        sSlash = "\"
        sPathIn = Replace$(sPathIn, "/", "\")
        sFileNameIn = Replace$(sFileNameIn, "/", "\")
    Else
        sSlash = "/"
        sPathIn = Replace$(sPathIn, "\", "/")
        sFileNameIn = Replace$(sFileNameIn, "\", "/")
    End If

    If sPathIn = vbNullString Then
        BuildPath = sFileNameIn
    Else

        If Right$(sPathIn, 1) = sSlash Then
            BuildPath = sPathIn & sFileNameIn
        Else
            BuildPath = sPathIn & sSlash & sFileNameIn
        End If

    End If

End Function

Function GetFileName(ByRef sFilename As String) As String
    Dim pLen As String
    Dim sPath As String
    
    sPath = sFilename
    pLen = Len(sPath)
    If pLen < 1 Then Exit Function
    Do While (Right$(sPath, 1) = "\")
        pLen = pLen - 1
        sPath = Left$(sPath, pLen)
        If pLen < 1 Then GetFileName = "\": Exit Function
    Loop
    Do While (Right$(sPath, 1) = "/")
        pLen = pLen - 1
        sPath = Left$(sPath, pLen)
        If pLen < 1 Then GetFileName = "\": Exit Function
    Loop
    
    'GetFileName = sPath
    Dim pos As Long
    pos = InStrRev(sPath, "/")
    If pos < 1 Then pos = InStrRev(sPath, "\")
    If pos < 1 Then
        GetFileName = sPath
    Else
        GetFileName = Right$(sPath, pLen - pos)
    End If
    
    'pos = InStrRev$(sPath, ".")


End Function

Function GetParentFolderName(ByRef sFilename As String) As String

    Dim lF As Long
    Dim pos As Long
    lF = Len(sFilename)
    If lF < 1 Then Exit Function
    
    GetParentFolderName = sFilename
    pos = InStrRev(GetParentFolderName, "/")

    If pos = 0 Then pos = InStrRev(GetParentFolderName, "\")

    If pos = lF Then
        GetParentFolderName = Left$(GetParentFolderName, lF - 1)
        pos = InStrRev(GetParentFolderName, "/")

        If pos = 0 Then pos = InStrRev(GetParentFolderName, "\")
    End If

    If pos = 0 Then
        GetParentFolderName = vbNullString
    Else
        GetParentFolderName = Mid$(sFilename, 1, pos - 1) & "\"
    End If

    '
    '    pos = InStrRev(GetParentFolder, "/")
    '    If pos = 0 Then pos = InStrRev(GetParentFolder, "\")
    '    If pos = 0 Then GetParentFolder = vbNULLSTRING

End Function

Public Function GetBaseName(ByVal sPath As String) As String

    Dim pos As Long
    sPath = GetFileName(sPath)
    pos = InStrRev(sPath, ".")
    If pos > 0 Then
        GetBaseName = Left$(sPath, pos - 1)
    Else
        GetBaseName = sPath
    End If

End Function

Public Function GetExtensionName(ByRef sPath As String) As String

    If sPath = vbNullString Then Exit Function
    GetExtensionName = RightRight(sPath, ".", vbTextCompare, ReturnEmptyStr)

End Function

Private Function RightRight(ByRef Str As String, RFind As String, Optional Compare As VbCompareMethod = vbBinaryCompare, Optional RetError As LNIfStringNotFound = ReturnEmptyStr) As String

    Dim K As Long
    K = InStrRev(Str, RFind, , Compare)

    If K = 0 Then
        RightRight = IIf(RetError = ReturnOriginalStr, Str, vbNullString)
    Else
        RightRight = Mid$(Str, K + 1, Len(Str))
    End If

End Function

Public Function GetTempFilename(Optional sPrefix As String = "lTmp", Optional sExt As String) As String

    Randomize Timer

    If sExt <> vbNullString Then sExt = "." & sExt
    GetTempFilename = sPrefix & Hex$(Int(Rnd(Timer) * 10000 + 1)) & sExt

    Do Until PathExists(GetTempFilename) = False
        GetTempFilename = sPrefix & Hex$(Int(Rnd(Timer) * 10000 + 1)) & sExt
    Loop

End Function

Public Function GetFullPath(sFilename As String) As String

    Dim C As Long, sRet As String
    GetFullPath = sFilename

    If sFilename = Empty Then Exit Function
    ' Get the path size, then create string of that size
    sRet = String$(cMaxPath, 0)
    C = APIGetFullPathName(StrPtr(sFilename), MAX_PATH, StrPtr(sRet), 0)
   ' GetFullPath = StrConv(ConvertCString(sRet), vbUnicode)
    GetFullPath = ConvertCString(sRet)

End Function

Public Function PathType(sPath As String) As LNPathType

    PathType = LNUnKnown
    On Error GoTo Herr

    If sPath = vbNullString Then Exit Function

    If InStr(sPath, ":") < 1 Then sPath = GetFullPath(sPath)
    Dim PathAttr As VbFileAttribute
    PathAttr = GetAttr(sPath)

    If (PathAttr And vbDirectory) Then
        PathType = LNFolder
    ElseIf (PathAttr And vbArchive) Then
        PathType = LNFile
    End If

Herr:

End Function

Public Function subCount(ByVal spathName As String, Optional ByRef lFolders As Long, Optional ByRef lFiles As Long) As Long

    Dim subName As String

    If PathType(spathName) <> LNFolder Then Exit Function
    spathName = GetFullPath(spathName)
    subName = Dir(spathName, vbDirectory Or vbArchive Or vbHidden Or vbNormal Or vbSystem Or vbReadOnly)

    Do Until subName = vbNullString

        If subName = "." Or subName = ".." Then
        Else
            subCount = subCount + 1
            subName = BuildPath(spathName, subName)

            If PathType(subName) = LNFolder Then
                lFolders = lFolders + 1
            Else
                lFiles = lFiles + 1
            End If

        End If

        subName = Dir()
    Loop

End Function
Public Function subFolders(ByVal spathName As String, ByRef strFolder() As String) As Long
    Dim fdCount As Long
    Dim subName As String
    
    spathName = GetFullPath(spathName)
    subName = Dir$(spathName, vbDirectory)
    spathName = BuildPath(spathName)
    Do Until subName = vbNullString
        If subName <> "." And subName <> ".." Then
                If GetAttr(spathName & subName) And vbDirectory Then
                ReDim Preserve strFolder(0 To fdCount) As String
                strFolder(fdCount) = spathName & subName
                fdCount = fdCount + 1
            End If
        End If
        subName = Dir$()
    Loop
    subFolders = fdCount
    
End Function
Public Function subFiles(ByVal spathName As String, ByRef strFile() As String) As Long
    Dim fCount As Long
    Dim subName As String
    
    spathName = GetFullPath(spathName)
    subName = Dir$(spathName, vbArchive)
    Do Until subName = vbNullString
        If subName <> "." And subName <> ".." Then

            ReDim Preserve strFile(0 To fCount) As String
            strFile(fCount) = subName
            fCount = fCount + 1
        End If
        subName = Dir$()
    Loop
    subFiles = fCount
 
End Function

Public Sub xMkdir(sPath As String)
    Dim parentFolder As String
    If FolderExists(sPath) Then Exit Sub
    parentFolder = GetParentFolderName(sPath)
    If parentFolder <> vbNullString And FolderExists(parentFolder) = False Then xMkdir parentFolder
    MkDir sPath
End Sub



Public Function chkFileType(chkfile As String) As LNFileType
    Dim Ext As String
    Dim K As Long
    K = InStrRev(chkfile, ".", , vbTextCompare)

    If K > 0 Then
        Ext = LCase$(Mid$(chkfile, K + 1, Len(chkfile)))
    End If

    Select Case Ext
    Case "rtf"
        chkFileType = ftRTF
    Case "zhtm", "zip"
        chkFileType = ftZIP
    Case "txt", "ini", "bat", "cmd", "css", "log", "cfg", "txtindex"
        chkFileType = ftTxt
    Case "jpg", "jpeg", "gif", "bmp", "png", "ico"
        chkFileType = ftIMG
    Case "htm", "html", "shtml"
        chkFileType = ftIE
    Case "exe", "com"
        chkFileType = ftExE
    Case "chm"
        chkFileType = ftCHM
    Case "mp3", "wav", "wma"
        chkFileType = ftAUDIO
    Case "wmv", "rm", "rmvb", "avi", "mpg", "mpeg"
        chkFileType = ftVIDEO
    End Select

End Function

Public Function LookFor(sCurFile As String, Optional lookForWhat As LNLOOKFOR = LN_FILE_next, Optional sWildcard As String = "*")

Dim sCurFilename As String
Dim sCurFolder As String
Dim I As Long
Dim iCount As Long
Dim sFileList() As String
Dim Index As String

If PathExists(sCurFile) = False Then Exit Function

If PathType(sCurFile) = LNFolder Then
    sCurFolder = sCurFile
ElseIf PathType(sCurFile) = LNFile Then
    sCurFolder = GetParentFolderName(sCurFile)
    sCurFilename = GetFileName(sCurFile)
Else
    Exit Function
End If

iCount = subFiles(BuildPath(sCurFolder, sWildcard), sFileList())
If iCount < 1 Then Exit Function
Index = 0
If lookForWhat = LN_FILE_RAND Then
    Index = Int(Rnd(Timer) * iCount) + 1
ElseIf sCurFilename = vbNullString Then
        Index = 1
Else
    For I = 1 To iCount
        If StrComp(sCurFilename, sFileList(I), vbTextCompare) = 0 Then
            Index = I: Exit For
        End If
    Next
End If

If lookForWhat = LN_FILE_next Then
    Index = Index + 1
    If Index > iCount Then Index = 1
ElseIf lookForWhat = LN_FILE_prev Then
    Index = Index - 1
    If Index < 1 Then Index = iCount
End If

LookFor = BuildPath(sCurFolder, sFileList(Index))

End Function


Public Function DeleteFolder(ByVal vTarget As String) As Boolean
    
On Error GoTo ErrorDeleteFolder

    vTarget = BuildPath(vTarget, vbNullString)
    ForceKill vTarget & "*.*"
    
    
    Dim folders() As String
    Dim count As Long
    count = subFolders(vTarget, folders())
    
    Dim I As Long
    For I = 1 To count
        DeleteFolder folders(I)
    Next
    
    RmDir vTarget
    DeleteFolder = True
        
        
ErrorDeleteFolder:
    DeleteFolder = False
    Err.Raise Err.Number, Err.Source, Err.Description
End Function

Public Sub ForceKill(ByRef vTarget As String)
    On Error Resume Next
    Kill vTarget
    Err.Clear
End Sub

Public Function MoveFile(ByVal vSource As String, ByVal vDest As String) As Boolean
    Dim r As Long
    r = APIMoveFile(vSource, vDest)
    If r <> 0 Then MoveFile = True
End Function

Public Function ReplaceInvalidChars(ByRef vString As String, Optional ByRef vTo As String = vbNullString) As String
    Dim I As Long
    Dim j As Long
    Dim L1 As Long
    Dim L2 As Long
    
    Dim C As String
    Dim invalidChars() As String
    L1 = Len(FileSystem_Invalid_Path_Chars)
    ReDim invalidChars(1 To L1)
    For I = 1 To L1
        invalidChars(I) = Mid$(FileSystem_Invalid_Path_Chars, I, 1)
    Next
       
    L2 = Len(vString)
    For I = 1 To L2
        C = Mid$(vString, I, 1)
        For j = 1 To L1
            If C = invalidChars(j) Then
                C = vTo
                Exit For
            End If
        Next
        ReplaceInvalidChars = ReplaceInvalidChars & C
    Next
End Function

Public Sub WriteToFile(ByRef vFilename As String, ByRef vText As String, Optional vUnicode As Boolean = False)
    On Error Resume Next
    
    Dim fNum As Long
    'Dim l As Long
    fNum = FreeFile
    
    
    Kill vFilename
    
    Dim c_B(1) As Byte
    ReDim bText(LenB(vText)) As Byte
    c_B(0) = 255
    c_B(1) = 254
    bText = vText
    Open vFilename For Binary Access Write As #fNum
    Put #fNum, , c_B()
    Put #fNum, , bText
    
    Close #fNum
    
    If Err Then
        Err.Raise Err.Number, "WriteToFile: " & vFilename, Err.Description
    End If
End Sub

'CSEH: ErrExit
Public Function FS_OpenFile(ByVal vFilename As String, Optional vMode As FS_OpenFileMode = FS_OFM_BINARY_READ) As Integer
    '<EhHeader>
    On Error GoTo FS_OpenFile_Err
    '</EhHeader>
    Dim fNum As Integer
    fNum = FreeFile
    Select Case vMode
        Case FS_OpenFileMode.FS_OFM_BINARY
            Open vFilename For Binary As #fNum
        Case FS_OpenFileMode.FS_OFM_BINARY_READ
            Open vFilename For Binary Access Read As #fNum
        Case FS_OpenFileMode.FS_OFM_BINARY_READWRITE
            Open vFilename For Binary Access Read Write As #fNum
        Case FS_OpenFileMode.FS_OFM_BINARY_WRITE
            Open vFilename For Binary Access Write As #fNum
        Case FS_OpenFileMode.FS_OFM_INPUT
            Open vFilename For Input As #fNum
        Case FS_OpenFileMode.FS_OFM_OUTPUT
            Open vFilename For Output As #fNum
        Case FS_OpenFileMode.FS_OFM_RANDOM
            Open vFilename For Random As #fNum
        Case Else
            GoTo FS_OpenFile_Err
    End Select
        FS_OpenFile = fNum
    '<EhFooter>
    Exit Function

FS_OpenFile_Err:
    FS_OpenFile = -1
    Err.Clear

    '</EhFooter>
End Function
'CSEH: ErrExit
Public Function FS_ReadFile(ByVal vFilename As String, ByRef vData() As Byte, Optional vStart As Long = 1, Optional vLength As Long = -1) As Long
    '<EhHeader>
    On Error GoTo FS_ReadFile_Err
    '</EhHeader>
    Dim fNum As Integer
    Dim fSize As Long
    fNum = FS_OpenFile(vFilename, FS_OFM_BINARY_READ)
    If fNum > 0 Then
        fSize = LOF(fNum)
        If vLength < 1 Then vLength = fSize
        If vStart > fSize Then vStart = 1
        If fSize > 0 Then
            If vLength + vStart - 1 > fSize Then vLength = fSize - vStart + 1
            ReDim vData(0 To vLength - 1)
            Seek #fNum, vStart
            Get #fNum, , vData
            FS_ReadFile = vLength
        Else
            FS_ReadFile = 0
        End If
        Close #fNum
    Else
        FS_ReadFile = -1
    End If
    '<EhFooter>
    Exit Function

FS_ReadFile_Err:
    FS_ReadFile = -1
    If fNum > 0 Then FS_CloseFile fNum
    Err.Clear

    '</EhFooter>
End Function
'CSEH: ErrExit
Public Function FS_WriteFile(ByVal vFilename As String, ByRef vData() As Byte, Optional vStart As Long = 1) As Boolean
    '<EhHeader>
    On Error GoTo FS_WriteFile_Err
    '</EhHeader>
    Dim fNum As Integer
    Dim fSize As Long
    fNum = FS_OpenFile(vFilename, FS_OFM_BINARY_WRITE)
    If fNum > 0 Then
        fSize = LOF(fNum)
        If vStart > fSize Then vStart = fSize
        If vStart < 1 Then vStart = fSize
        If vStart < 1 Then vStart = 1
        Seek #fNum, vStart
        Put #fNum, , vData
        Close #fNum
        FS_WriteFile = True
    Else
        FS_WriteFile = False
    End If
    '<EhFooter>
    Exit Function

FS_WriteFile_Err:
    FS_WriteFile = False
    If fNum > 0 Then FS_CloseFile fNum
    Err.Clear

    '</EhFooter>
End Function
'CSEH: ErrExit
Public Function FS_CloseFile(ByVal vFileNum As Integer) As Boolean
    '<EhHeader>
    On Error GoTo FS_CloseFile_Err
    '</EhHeader>
    If vFileNum > 0 Then Close vFileNum
    FS_CloseFile = True
    '<EhFooter>
    Exit Function

FS_CloseFile_Err:
    FS_CloseFile = False
    Err.Clear

    '</EhFooter>
End Function

