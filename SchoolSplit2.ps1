$destFileName = "Students Missing in Roll Call 11-13-2020.xlsx";
$sourceFileName = "BlankRoll Call Student List 11-13-2020.xlsx";
$sourceFilePath = "C:\Users\OKADAK\Documents\Tasks\2020_11_13\RollCall\Data\Blank\";
#$LT15FilePath = "C:\Users\OKADAK\Documents\Tasks\2020_11_13\RollCall\Data\Blank\LessThan15\";

$ServerOT = "WS-2UA7192G9Q"
$DatabaseOT = "Utils"

$connString = "Server=$ServerOT; Database=$DatabaseOT; "
$connString += "Trusted_Connection=Yes; Integrated Security=SSPI;" 

$connection = New-Object System.Data.SqlClient.SqlConnection($connString)
$connection.Open()

$commandData = $connection.CreateCommand()
$commandData.CommandTimeout = $CommandTimeout
$commandData.commandText = "
    SELECT DISTINCT
        s.[CCSDLoc], s.[School], s.[Region], s.[Student Number], s.[Student], s.[Grade], s.[HouseHoldPhone], s.[Address], s.[City], s.[State], s.[Zip], s.[Connectivity], s.[Device], s.[latitude], s.[longitude],
        f.FolderPath AS CopyDestinationFullPath      
        --REPLACE(f.FolderLocation, '\\WS-MJ810PD\AARSI School Shares\', 'Z:\') AS CopyDestinationFullPath      
    FROM dbo.RollCallOutput_20201113 AS s
    INNER JOIN dbo.schoolFolders AS f ON LTRIM(RTRIM(CAST(s.[CCSDLoc] AS VARCHAR(20)))) = f.schoolID
    --INNER JOIN SSRS.AARSI_SharePaths AS f ON LTRIM(RTRIM(CAST(s.[CCSDLoc] AS VARCHAR(20)))) = f.CCSDNum    
    ORDER BY s.[CCSDLoc] ASC, s.[Student] ASC;
    
    --Less than 15 counts...
    /*SELECT DISTINCT
        s.[CCSDLoc], s.[School], s.[Region], s.[Student Number], s.[Student], s.[Grade], s.[HouseHoldPhone], s.[Address], s.[City], s.[State], s.[Zip], s.[Connectivity], s.[Device], s.[latitude], s.[longitude],
        'test' AS CopyDestinationFullPath, cnt
        --REPLACE(f.FolderLocation, '\\WS-MJ810PD\AARSI School Shares\', 'Z:\') AS CopyDestinationFullPath      
    FROM dbo.RollCallOutput_20201113 AS s
    INNER JOIN (
        SELECT * FROM (
            SELECT CCSDLoc AS schoolID, COUNT(*) cnt 
            FROM dbo.RollCallOutput_20201113 s2
            GROUP BY CCSDLoc
        ) L1 WHERE cnt <= 15
    ) cL ON s.CCSDLoc = cL.schoolID
    --INNER JOIN SSRS.AARSI_SharePaths AS f ON LTRIM(RTRIM(CAST(s.[CCSDLoc] AS VARCHAR(20)))) = f.CCSDNum       
    ORDER BY s.[CCSDLoc] ASC, s.[Student] ASC*/
";
$dataListSet = $commandData.ExecuteReader();
$dataListTable = New-Object "System.Data.DataTable";
$dataListTable.Load($dataListSet);

$tmpSchoolIDTable = New-Object System.Data.DataTable;
$tmpSchoolIDTable = $dataListTable | Select-Object -Property ("CCSDLoc", "School", "CopyDestinationFullPath" )  | Select-Object -Unique ("CCSDLoc", "School", "CopyDestinationFullPath") | Sort-Object -Property ( "CCSDLoc", "School", "CopyDestinationFullPath");
#$tt =  $tmpSchoolIDTable | Where {$_.'CCSDLoc' -in ( "321" ) };

$tt =  $tmpSchoolIDTable 
 $tt


foreach ( $s in $tt)
{   
    $sourcePath = Join-Path -Path $sourceFilePath -ChildPath $sourceFileName 
    $destPath = Join-Path -Path $s.'CopyDestinationFullPath' -ChildPath ($destFileName);    
    $destPathTest = Join-Path -Path $sourceFilePath -ChildPath ($s.'CCSDLoc'.ToString() + "_" + $s.'School' + "_" + $destFileName); 
    #$destPathTest = Join-Path -Path $LT15FilePath -ChildPath ($s.'CCSDLoc'.ToString() + "_" + $s.'School' + "_" + $destFileName); 
    
    
#    $sourcePath;

    $setSchoolData = $dataListTable | Where {$_.'CCSDLoc' -eq $s.'CCSDLoc'};    
    $wsName = "Sheet1";

    #testblock
    # $destPathTest;
    # Copy-Item -Path $sourcePath -dest $destPathTest;
    # $excelPackage = Open-ExcelPackage -Path $destPathTest;
    # $setSchoolData `
    #     | Select 'CCSDLoc', 'School', 'Region', 'Student Number', 'Student', 'Grade', 'HouseHoldPhone', 'Address', 'City', 'State', 'Zip', 'Connectivity', 'Device', 'latitude', 'longitude' `
    #     | Export-Excel -ExcelPackage $excelPackage -WorksheetName $wsName -StartRow 2 -Autosize -AutoFilter;


    # production block      -- w/o geo-coordinates
    $destPath;
    Copy-Item -Path $sourcePath -dest $destPath;
    $excelPackage = Open-ExcelPackage -Path $destPath;    
    $setSchoolData `
        | Select 'CCSDLoc', 'School', 'Region', 'Student Number', 'Student', 'Grade', 'HouseHoldPhone', 'Address', 'City', 'State', 'Zip', 'Connectivity', 'Device' `
        | Export-Excel -ExcelPackage $excelPackage -WorksheetName $wsName -StartRow 2 -Autosize -AutoFilter;      

   $excelPackage.Dispose();
   # $setSchoolData.Dispose();
}


$dataListTable.Dispose();
$dataListSet.Dispose();
$commandData.Dispose();
$connection.Close();
$connection.Dispose();
