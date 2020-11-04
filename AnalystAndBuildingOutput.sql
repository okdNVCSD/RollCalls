USE Utils
GO

DROP TABLE #rollcall;
SELECT studentNumber, CCSDLoc, School, Region, firstName, lastName INTO #rollcall 
FROM dbo.RollCall_20201104;

SELECT * FROM dbo.RollCall_20201104

DROP TABLE #tmphouseholds;
SELECT * INTO #tmphouseholds FROM OPENQUERY([ORIONTEST.CIS.CCSD.NET], 'SELECT * FROM ##households_20201104');

DROP TABLE #students;
SELECT * INTO #students FROM OPENQUERY([ORIONTEST.CIS.CCSD.NET], 'SELECT * FROM ##students_20201104');


DROP TABLE #households;
SELECT th.*, s.[student Number] AS studentNumber 
INTO #households FROM #tmphouseholds th INNER JOIN #students s ON th.personID = s.personID;

SELECT DISTINCT personID FROM #tmphouseholds
EXCEPT
SELECT DISTINCT personID FROM #households;



DROP TABLE #missingPrimaryHH;
SELECT * INTO #missingPrimaryHH FROM #rollcall r
WHERE NOT EXISTS ( SELECT * FROM #households h WHERE h.hmNum = 1 AND h.studentNumber = r.studentNumber ) 

SELECT * FROM #missingPrimaryHH

1297619		TEL = (702)755-2243	3237 KEMP ST, NORTH LAS VEGAS, NV 89032
567471
1184106		TEL = (702)742-2391


1184106		TEL = (702)742-2391
567471

12301258	TEL = (540)351-7309	819 ZINNIA CIR, HENDERSON, NV 89015
567471	
1184106		TEL = (702)742-2391
12253794	TEL = (808)727-9779 3080 ST ROSE PKWY #1003, HENDERSON, NV 89052


1118172
12106255	TEL = (626)324-0205 	1827 W GOWAN RD #2077, NORTH LAS VEGAS, NV 89032
12157798	TEL = (702)505-3671		4766 BAYHAM ABBEY CT, LAS VEGAS, NV 89130
12257486	TEL = (702)580-1199		3540 KEMP ST, NORTH LAS VEGAS, NV 89032
12293311	TEL = (702)642-7555		4410 CASSANDRA DR, NORTH LAS VEGAS, NV 89032
1266772		TEL = (702)980-7270		1924 FREMONT ST #7, LAS VEGAS, NV 89101
1285821		TEL = (702)410-4582		1535 WOODWARD HEIGHTS WY, NORTH LAS VEGAS, NV 89032
1301909		TEL = (702)403-4560		3971 MONACO VIEW DR, NORTH LAS VEGAS, NV 89032
1303189		TEL = (702)752-3091		5400 W CHEYENNE AVE #1002, LAS VEGAS, NV 89108
1297204		TEL = (702)826-7750		2712 ALMA LIDIA AVE, NORTH LAS VEGAS, NV 89032
1380252		TEL = (925)497-5080		3237 ARLENE WY #4, LAS VEGAS, NV 89108
12069284	TEL = (702)544-6178		2416 FESTIVE CT, NORTH LAS VEGAS, NV 89032
664154		TEL = (702)300-4077		4552 ROAMING VINES ST, NORTH LAS VEGAS, NV 89031
567471
1184106		TEL = (702)742-2391
12248024	TEL = (937)594-7081		2747 STANLEY AVE, NORTH LAS VEGAS, NV 89030
1199082		TEL = (702)689-4509		2241 ELLIS ST #D, NORTH LAS VEGAS, NV 89030
1083548		TEL = (702)812-4190		1421 MELISSA ST, LAS VEGAS, NV 89101
1294899



1325330		TEL = (702)444-9846	1204 ELEANOR AVE, LAS VEGAS, NV 89106
1104701		TEL = (702)684-2527 1307 W MONROE AVE, LAS VEGAS, NV 89106
12304281	TEL = (701)609-8971 1200 W CHEYENNE AVE #2184, NORTH LAS VEGAS, NV 89030
1254218		TEL = (702)249-4704 3514 FLAMING THORN DR, NORTH LAS VEGAS, NV 89032
1178449		TEL = (702)410-0207 3151 SOARING GULLS DR #2139, LAS VEGAS, NV 89128
12311153	TEL = (929)394-4274 3376 CHEYENNE GARDENS WY, NORTH LAS VEGAS, NV 89032
1223484		TEL = (702)612-4402 2305 SABER DR, NORTH LAS VEGAS, NV 89032
12296260	TEL = (209)594-5944 6908 COBRE AZUL AVE #101, LAS VEGAS, NV 89108
1360402		TEL = (702)409-9757 3613 TUSCANY RIDGE CT, NORTH LAS VEGAS, NV 89032
1125394		TEL = (740)249-3404 3318 N DECATUR BLVD #2050, LAS VEGAS, NV 89130
12157277	TEL = (702)767-7919 1720 SHADOW BAY CT, NORTH LAS VEGAS, NV 89032
12325299	TEL = (702)481-7063
1184106		TEL = (702)742-2391
1118172
567471


SELECT * FROM #households WHERE studentNumber IN ( 
SELECT studentNumber FROM #houseHolds WHERE  hmnum > 1 
) 
ORDER BY MAX(hmnum) OVER( PARTITION BY studentNumber) DESC, studentNumber, hmnum ASC

SELECT * FROM #households WHERE secondary = 1 AND hmnum = 1 
SELECT * FROM #households WHERE hmnum = 1 AND secondary = 1 AND studentNumber IN ( SELECT studentNumber FROM #rollcall ) 


SELECT COUNT(*) FROM #rollcall
SELECT COUNT(DISTINCT studentNumber ) FROM #rollcall
SELECT * FROM dbo.RollCall_20201104 r
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

UPDATE o SET o .householdPhone = '(702)755-2243', Address = '3237 KEMP ST', City='NORTH LAS VEGAS', State='NV', Zip='89032' FROM #output AS o WHERE [student Number] = '1297619'
UPDATE o SET o .householdPhone = '(702)742-2391' FROM #output AS o WHERE [student Number] = '1184106'




SELECT DISTINCT CCSDLoc FROM #output 
--85 schools 





SELECT * FROM #output 
--WHERE Address IS NOT NULL AND LEN(Address) BETWEEN 0 AND 6
ORDER BY LEN(Address)



SELECT * FROM #output 
--WHERE Address IS NOT NULL AND LEN(Address) BETWEEN 0 AND 6
ORDER BY School, grade, Student, LEN(Address)

SELECT *
FROM #output AS o 
WHERE [student number] = '12264531'


UPDATE o 
SET Address = 'PO Box 571150'
FROM #output AS o 
WHERE [student number] = '12264531'



SELECT * FROM #households WHERE studentNumber = '1157199'

DROP TABLE dbo.RollCallOutput_20201104;
SELECT * INTO dbo.RollCallOutput_20201104
FROM #output 




SELECT COUNT(*) FROM dbo.RollCall_20201104
SELECT COUNT(DISTINCT [StudentNumber]) FROM dbo.RollCall_20201104

SELECT COUNT(*) FROM #output 
SELECT COUNT(DISTINCT [student number]) FROM #output

SELECT [StudentNumber] FROM dbo.RollCall_20201104
ExCEPT 
SELECT [student Number] FROM #output 
EXCEPT 
SELECT StudentNumber FROM dbo.RollCall_20201104


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
    FROM dbo.RollCallOutput_20201104 AS s
    INNER JOIN dbo.schoolFolders AS f ON LTRIM(RTRIM(CAST(s.[CCSDLoc] AS VARCHAR(20)))) = f.schoolID
    --INNER JOIN SSRS.AARSI_SharePaths AS f ON LTRIM(RTRIM(CAST(s.[CCSDLoc] AS VARCHAR(20)))) = f.CCSDNum    
    ORDER BY s.[CCSDLoc] ASC, s.[Student] ASC;
    
