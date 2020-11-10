
SELECT * FROM SSRS.AARSI_SharePaths


drop table ##households_20201110
select *
into ##households_20201110
from OPENQUERY(campus, '
	DECLARE @endYear VARCHAR(10) = ''2021'';
	SELECT *
		, ROW_NUMBER() over(PARTITION by personiD order by 
				CASE WHEN secondary IS NULL THEN 1 ELSE 0 END DESC, secondary ASC,
				CASE WHEN memberEndDate IS NULL THEN 1 ELSE 0 END DESC, 				
				CASE WHEN locEndDate IS NULL THEN 1 ELSE 0 END DESC, 
				memberEndDate DESC, 
				locEndDate DESC,				
				ISNUMERIC(Address) ASC,
				memberStartDate ASC, locStartDate DESC				
			) as hmNum
	FROM (
		select distinct hm.personID	
			--, p.studentNumber
			, hm.householdID
			, h.name as HouseHold
			, h.phone as HouseHoldPhone
			, concat(a.number, '' '', coalesce(a.prefix, ''''), '' '', a.street, '' '', a.tag, '' '', case when a.apt is not null then CONCAT(''#'', a.apt) else '''' end) as Address
			, a.city as City
			, a.state as State
			, a.zip as Zip 
			, a.latitude
			, a.longitude	
			, hm.startDate AS memberStartDate
			, hm.endDate AS memberEndDate
			, hl.startDate AS locStartDate
			, hl.endDate AS locEndDate
			, hm.secondary
		from clark.dbo.householdMember as hm
			inner join clark.dbo.Household as h on h.householdID = hm.householdID
			inner join clark.dbo.HouseholdLocation as hl on hl.householdID = h.householdID
			inner join clark.dbo.Address as a on a.addressID = hl.addressID
			--INNER JOIN clark.dbo.person p ON hm.personID = p.personID
		where 1=1
			and GETDATE() between coalesce(hm.startDate, getdate()) and coalesce(hm.endDate, getdate())
			and GETDATE() between coalesce(hl.startDate, getdate()) and coalesce(hl.endDate, getdate())
			--and hm.secondary = 0
			and hm.personID in (select e.personiD 
								from clark.dbo.Enrollment as e
									inner join clark.dbo.Calendar as c on c.calendarID = e.calendarID
									inner join clark.dbo.School as s on s.schoolID = c.schoolID
								where 1=1
									and e.endYear = @endYear 
									--and s.standardCode = @ccsdschool
									and GETDATE() between e.startDate and coalesce(e.endDate, getdate())
									) 
	) as h
	--where h.hmNum = 1
')


drop table ##students_20201110
select *
into ##students_20201110
from OPENQUERY(campus, '
	DECLARE @endYear VARCHAR(10) = ''2021'';
	SELECT * FROM (
		select distinct s.standardCode as CCSDLoc
			, s.name as [School]
			, cc.value as [Region]
			, id.studentNumber as [Student Number]
			, concat(id.lastname, '', '', id.firstname) as [Student]
			, e.grade as Grade
			, e.personID
			/*, h.HouseHold
			, h.HouseHoldPhone
			, h.Address
			, h.City
			, h.State
			, h.Zip*/
			, id.homePrimaryLanguage
			/*, h.latitude
			, h.longitude*/
			, coalesce(cd1.name, ''No'') as [FSC Connectivity Action]
			, coalesce(cd2.name, ''No'') as [FSC Device Action]
			, coalesce(cd3.name, ''No'') as [Destiny Device]
			, coalesce(cd4.name, ''No'') as [Destiny Hotspot]
			, coalesce(cd5.name, ''No'') as [Survey Device]
			, coalesce(cd6.name, ''No'') as [Survey Internet]
			, coalesce(cd7.name, ''No'') as [SOS Internet]
			, coalesce(cd8.name, ''No'') as [SOS Device]
			, ROW_NUMBER() over(partition by e.personID 
								order by case when e.serviceType = ''P'' then 1 when e.serviceType = ''N'' then 2 when e.serviceType = ''S'' then 3 end,
									e.startDate desc
								) as enrNum
		from clark.dbo.Enrollment as e with(nolock)
			inner join clark.dbo.EnrollmentNV as env on env.enrollmentID = e.enrollmentID 
				left outer join clark.dbo.campusDictionary as cd on cd.code = env.homeLanguage and cd.attributeID = 176
			inner join clark.dbo.Calendar as c on c.calendarID = e.calendarID
				left outer join clark.dbo.customCalendar as cc on cc.calendarID = c.calendarID and cc.attributeID = 628
			inner join clark.dbo.school as s on s.schoolID = c.schoolID
			inner join clark.dbo.individual as id on id.personID = e.personID 
			--left outer join #households as h on h.personID = e.personID and h.hmNum = 1 
			--family support center fields
			left outer join clark.dbo.CustomStudent as cs1 on cs1.personID = e.personID and cs1.attributeID = 2382		--FSC Connectivity Action
				left outer join clark.dbo.CampusDictionary as cd1 on cd1.attributeID = cs1.attributeID and cd1.code = cs1.value
			left outer join clark.dbo.CustomStudent as cs2 on cs2.personID = e.personID and cs2.attributeID = 2392		--FSC Device Action
				left outer join clark.dbo.CampusDictionary as cd2 on cd2.attributeID = cs2.attributeID   and cd2.code = cs2.value 
			left outer join clark.dbo.CustomStudent as cs3 on cs3.personID = e.personID and cs3.attributeID = 2393		--FSC Destiny Device
				left outer join clark.dbo.CampusDictionary as cd3 on cd3.attributeID = cs3.attributeID  and cd3.code = cs3.value 
			left outer join clark.dbo.CustomStudent as cs4 on cs4.personID = e.personID and cs4.attributeID = 2400		--FSC Destiny Hotspot
				left outer join clark.dbo.CampusDictionary as cd4 on cd4.attributeID = cs4.attributeID and cd4.code = cs4.value 
			left outer join clark.dbo.CustomStudent as cs5 on cs5.personID = e.personID and cs5.attributeID = 2379		--FSC Survey Device
				left outer join clark.dbo.CampusDictionary as cd5 on cd5.attributeID = cs5.attributeID and cd5.code = cs5.value 
			left outer join clark.dbo.CustomStudent as cs6 on cs6.personID = e.personID and cs6.attributeID = 2380		--FSC Survey Internet
				left outer join clark.dbo.CampusDictionary as cd6 on cd6.attributeID = cs6.attributeID and cd6.code = cs6.value 
			--SOS Tab
			left outer join clark.dbo.CustomStudent as cs7 on cs7.personID = e.personID and cs7.attributeID = 2398		--SOS Tab Internet
				left outer join clark.dbo.CampusDictionary as cd7 on cd7.attributeID = cs7.attributeID and cd7.code = cs7.value 
			left outer join clark.dbo.CustomStudent as cs8 on cs8.personID = e.personID and cs8.attributeID = 2399		--SOS Tab Device
				left outer join clark.dbo.CampusDictionary as cd8 on cd8.attributeID = cs8.attributeID and cd8.code = cs8.value 
		where 1=1
			and 
			e.endYear = @endYear
			--and s.standardCode = @ccsdschool
			--and id.studentNumber in (select studentNumber from ##rollcall)
			--and s.city = ''Henderson''
	) as enr
	where enr.enrNum = 1
');


drop table ##studentSpecific_20201110
select *
into ##studentSpecific_20201110
from OPENQUERY(campus, '
	DECLARE @endYear VARCHAR(10) = ''2021'';
	SELECT * FROM (
		select distinct s.standardCode as CCSDLoc
			, s.name as [School]
			, cc.value as [Region]
			, id.studentNumber as [Student Number]
			, concat(id.lastname, '', '', id.firstname) as [Student]
			, e.grade as Grade
			, e.personID
			/*, h.HouseHold
			, h.HouseHoldPhone
			, h.Address
			, h.City
			, h.State
			, h.Zip*/
			, id.homePrimaryLanguage
			/*, h.latitude
			, h.longitude*/
			/*, coalesce(cd1.name, ''No'') as [FSC Connectivity Action]
			, coalesce(cd2.name, ''No'') as [FSC Device Action]
			, coalesce(cd3.name, ''No'') as [Destiny Device]
			, coalesce(cd4.name, ''No'') as [Destiny Hotspot]
			, coalesce(cd5.name, ''No'') as [Survey Device]
			, coalesce(cd6.name, ''No'') as [Survey Internet]
			, coalesce(cd7.name, ''No'') as [SOS Internet]
			, coalesce(cd8.name, ''No'') as [SOS Device]*/
			, ROW_NUMBER() over(partition by e.personID 
								order by case when e.serviceType = ''P'' then 1 when e.serviceType = ''N'' then 2 when e.serviceType = ''S'' then 3 end,
									e.startDate desc
								) as enrNum
		from clark.dbo.Enrollment as e with(nolock)
			--inner join clark.dbo.EnrollmentNV as env on env.enrollmentID = e.enrollmentID 
				--left outer join clark.dbo.campusDictionary as cd on cd.code = env.homeLanguage and cd.attributeID = 176
			inner join clark.dbo.Calendar as c on c.calendarID = e.calendarID
				left outer join clark.dbo.customCalendar as cc on cc.calendarID = c.calendarID and cc.attributeID = 628
			inner join clark.dbo.school as s on s.schoolID = c.schoolID
			inner join clark.dbo.individual as id on id.personID = e.personID 
			--left outer join #households as h on h.personID = e.personID and h.hmNum = 1 
			--family support center fields
			left outer join clark.dbo.CustomStudent as cs1 on cs1.personID = e.personID and cs1.attributeID = 2382		--FSC Connectivity Action
				left outer join clark.dbo.CampusDictionary as cd1 on cd1.attributeID = cs1.attributeID and cd1.code = cs1.value
			left outer join clark.dbo.CustomStudent as cs2 on cs2.personID = e.personID and cs2.attributeID = 2392		--FSC Device Action
				left outer join clark.dbo.CampusDictionary as cd2 on cd2.attributeID = cs2.attributeID   and cd2.code = cs2.value 
			left outer join clark.dbo.CustomStudent as cs3 on cs3.personID = e.personID and cs3.attributeID = 2393		--FSC Destiny Device
				left outer join clark.dbo.CampusDictionary as cd3 on cd3.attributeID = cs3.attributeID  and cd3.code = cs3.value 
			left outer join clark.dbo.CustomStudent as cs4 on cs4.personID = e.personID and cs4.attributeID = 2400		--FSC Destiny Hotspot
				left outer join clark.dbo.CampusDictionary as cd4 on cd4.attributeID = cs4.attributeID and cd4.code = cs4.value 
			left outer join clark.dbo.CustomStudent as cs5 on cs5.personID = e.personID and cs5.attributeID = 2379		--FSC Survey Device
				left outer join clark.dbo.CampusDictionary as cd5 on cd5.attributeID = cs5.attributeID and cd5.code = cs5.value 
			left outer join clark.dbo.CustomStudent as cs6 on cs6.personID = e.personID and cs6.attributeID = 2380		--FSC Survey Internet
				left outer join clark.dbo.CampusDictionary as cd6 on cd6.attributeID = cs6.attributeID and cd6.code = cs6.value 
			--SOS Tab
			left outer join clark.dbo.CustomStudent as cs7 on cs7.personID = e.personID and cs7.attributeID = 2398		--SOS Tab Internet
				left outer join clark.dbo.CampusDictionary as cd7 on cd7.attributeID = cs7.attributeID and cd7.code = cs7.value 
			left outer join clark.dbo.CustomStudent as cs8 on cs8.personID = e.personID and cs8.attributeID = 2399		--SOS Tab Device
				left outer join clark.dbo.CampusDictionary as cd8 on cd8.attributeID = cs8.attributeID and cd8.code = cs8.value 
		where 1=1
			and 
			e.endYear = @endYear
			and e.personID = ''2521408''
			--and s.standardCode = @ccsdschool
			--and id.studentNumber in (select studentNumber from ##rollcall)
			--and s.city = ''Henderson''
	) as enr
	where enr.enrNum = 1
');


SELECT * FROM campus.clark.dbo.EnrollmentNV WHERE personID = '2521408'
SELECT * FROM campus.clark.dbo.calendar WHERE calendarID ='14789'
SELECT * FROM campus.clark.dbo.school WHERE name LIKE 'sun%'