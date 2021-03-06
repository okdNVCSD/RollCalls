USE Utils
GO

DROP TABLE #rollcall;
SELECT studentNumber, CCSDLoc, School, Region, firstName, lastName INTO #rollcall 
FROM dbo.RollCall_20201113;

SELECT * FROM dbo.RollCall_20201113

DROP TABLE #tmphouseholds;
SELECT * INTO #tmphouseholds FROM OPENQUERY([ORIONTEST.CIS.CCSD.NET], 'SELECT * FROM ##households_20201113');

DROP TABLE #students;
SELECT * INTO #students FROM OPENQUERY([ORIONTEST.CIS.CCSD.NET], 'SELECT * FROM ##students_20201113');


DROP TABLE #households;
SELECT th.*, s.[student Number] AS studentNumber 
INTO #households FROM #tmphouseholds th INNER JOIN #students s ON th.personID = s.personID;

SELECT DISTINCT personID FROM #tmphouseholds
EXCEPT
SELECT DISTINCT personID FROM #households;

--12301864. Her enrollment is not included in enrollmentNV for whatever reason...

DROP TABLE #missingPrimaryHH;
SELECT * INTO #missingPrimaryHH FROM #rollcall r
WHERE NOT EXISTS ( SELECT * FROM #households h WHERE h.hmNum = 1 AND h.studentNumber = r.studentNumber ) 

SELECT * FROM #missingPrimaryHH





SELECT * FROM #households WHERE studentNumber IN ( 
SELECT studentNumber FROM #houseHolds WHERE  hmnum > 1 
) 
ORDER BY MAX(hmnum) OVER( PARTITION BY studentNumber) DESC, studentNumber, hmnum ASC

SELECT * FROM #households WHERE secondary = 1 AND hmnum = 1 
SELECT * FROM #households WHERE hmnum = 1 AND secondary = 1 AND studentNumber IN ( SELECT studentNumber FROM #rollcall ) 


SELECT COUNT(*) FROM #rollcall
SELECT COUNT(DISTINCT studentNumber ) FROM #rollcall
SELECT * FROM dbo.RollCall_20201113 r
WHERE NOT EXISTS ( SELECT * FROM #students s WHERE s.[student Number] = r.studentnumber ) 




drop table #output;
SELECT * 
into #output
FROM (
	select 
		e.CCSDLoc
		, e.School 
		, e.[Region]
		, e.[Student Number]
		, e.Student
		, e.Grade
		, h.HouseHoldPhone
		, h.[Address]
		, h.City
		, h.[State]
		, h.Zip
		, case when ([FSC Connectivity Action] = 'No' AND [Destiny Hotspot] = 'No' AND [Survey Internet] = 'No' and [SOS Internet] = 'No') then 'N' else 'Y' end as [Connectivity]
		, case when ([FSC Device Action] = 'No' and [Destiny Device] = 'No' and [Survey Device] = 'No' and [SOS Device] = 'No')  then 'N' else 'Y' end as [Device]
		, h.latitude
		, h.longitude
	from #students e 
	LEFT JOIN ( SELECT * FROM #households WHERE hmnum = 1) h ON e.personID = h.personID 
) L1 
WHERE [student Number] IN ( SELECT studentNumber FROM #rollcall ) 
order by  School, Student ;





SELECT DISTINCT CCSDLoc FROM #output 
--71 schools 





SELECT * FROM #output 
--WHERE Address IS NOT NULL AND LEN(Address) BETWEEN 0 AND 6
ORDER BY LEN(Address)


-- Persisting 2 addresses missing coordinate info.
SELECT * FROM #output 
--WHERE Address IS NOT NULL AND LEN(Address) BETWEEN 0 AND 6
ORDER BY LEN(latitude)



SELECT * FROM #output 
--WHERE Address IS NOT NULL AND LEN(Address) BETWEEN 0 AND 6
ORDER BY School, grade, Student, LEN(Address)

SELECT *
FROM #output AS o 
WHERE [student number] = '12264531'


--UPDATE o 
--SET Address = 'PO Box 571150'
--FROM #output AS o 
--WHERE [student number] = '12264531'



--SELECT * FROM #households WHERE studentNumber = '1157199'

DROP TABLE dbo.RollCallOutput_20201113;
SELECT * INTO dbo.RollCallOutput_20201113
FROM #output 

SELECT * FROM #output WHERE [CCSDLoc] = '951'


SELECT COUNT(*) FROM dbo.RollCall_20201113
SELECT COUNT(DISTINCT [StudentNumber]) FROM dbo.RollCall_20201113

SELECT COUNT(*) FROM #output 
SELECT COUNT(DISTINCT [student number]) FROM #output

SELECT [StudentNumber] FROM dbo.RollCall_20201113
ExCEPT 
SELECT [student Number] FROM #output 
EXCEPT 
SELECT StudentNumber FROM dbo.RollCall_20201113


SELECT DISTINCT CCSDLoc, School FROM #output

SELECT * FROM [ORIONTEST.CIS.CCSD.NET].ACCOUNTABILITY.SSRS.AARSI_SharePaths 
WHERE CCSDNum IN 
(
	SELECT DISTINCT CCSDNum AS CCSDLoc  FROM [ORIONTEST.CIS.CCSD.NET].ACCOUNTABILITY.SSRS.AARSI_SharePaths
	EXCEPT 
	SELECT DISTINCT CCSDLoc FROM #output
) 

SELECT DISTINCT CCSDLoc FROM #output
EXCEPT
SELECT DISTINCT CCSDNum AS CCSDLoc  FROM [ORIONTEST.CIS.CCSD.NET].ACCOUNTABILITY.SSRS.AARSI_SharePaths
	



	SELECT DISTINCT
        s.[CCSDLoc], s.[School], s.[Region], s.[Student Number], s.[Student], s.[Grade], s.[HouseHoldPhone], s.[Address], s.[City], s.[State], s.[Zip], s.[Connectivity], s.[Device], s.[latitude], s.[longitude],
        f.FolderPath AS CopyDestinationFullPath      
        --REPLACE(f.FolderLocation, '\\WS-MJ810PD\AARSI School Shares\', 'Z:\') AS CopyDestinationFullPath      
    FROM dbo.RollCallOutput_20201113 AS s
    INNER JOIN dbo.schoolFolders AS f ON LTRIM(RTRIM(CAST(s.[CCSDLoc] AS VARCHAR(20)))) = f.schoolID
    --INNER JOIN SSRS.AARSI_SharePaths AS f ON LTRIM(RTRIM(CAST(s.[CCSDLoc] AS VARCHAR(20)))) = f.CCSDNum    
    ORDER BY s.[CCSDLoc] ASC, s.[Student] ASC;
    
