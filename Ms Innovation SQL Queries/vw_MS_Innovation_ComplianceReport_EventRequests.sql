

Create or ALTER VIEW [dbo].[vw_MS_Innovation_ComplianceReport_EventRequests]  
AS  
  
Select   
 ER.RequestId,  
CASE  
    WHEN ERS.Name = 'Approved' AND ER.EndDate < GETUTCDATE()  
    THEN 'Completed'  
    ELSE ERS.Name  
    END AS EventRequestStatus,  
CASE WHEN ERMS.HasLab = 'true' then 'Yes' ELSE 'No' END AS LabEnviron,  
 EU.RequesterName,   
 ER.RequestorEmail,  
 AES.AssignedTo AS EventPM,   
CASE WHEN CONCAT(EPM.FirstName,' ',EPM.LastName)  IS NULL OR CONCAT(EPM.FirstName,' ',EPM.LastName)  = ''  
     THEN AES.AssignedTo  
    ELSE CONCAT(EPM.FirstName,' ',EPM.LastName) END AS EventPMName,  
CASE WHEN AES.EventFormat IN ('Single Account', 'Multiple Account')   
 THEN CONCAT(AES.EventFormat, ' ',(CASE when P.TITLE like '%HOL%' THEN 'HOL' ELSE 'Hack' end))  
 ELSE AES.EventFormat END AS EventType,  
 ER.Title as EventName,  
 ER.StartDate ,  
 ER.StartTime ,  
 ER.EndDate ,  
 ER.EndTime,  
 CAST(CAST(ER.StartDate AS DATETIME) + CAST(ER.StartTime AS DATETIME) AT TIME ZONE 'UTC' AT TIME ZONE  ST.SystemTimeZoneId AS DATETIME) AS LocalStartDateTimeFormat,                  
 CAST(CAST(ER.EndDate AS DATETIME) + CAST(ER.EndTime AS DATETIME) AT TIME ZONE 'UTC' AT TIME ZONE  ST.SystemTimeZoneId AS DATETIME) AS LocalEndDateTimeFormat,                  
 CAST(ER.StartDate AS DATETIME) + cast(ER.StartTime AS DATETIME) AS StartDateTime,                  
 CAST(ER.EndDate AS DATETIME) + cast(ER.EndTime AS DATETIME) AS EndDateTime,    
CASE WHEN E.UniqueName IS NULL   
 THEN NULL ELSE CONCAT('https://ms-workshops.cloudevents.ai/events/', E.UniqueName)   
 END AS AdminLink,                  
CASE WHEN E.UniqueName IS NULL   
 THEN NULL ELSE CONCAT('https://ms-workshops.cloudevents.ai/ms-innovation-workshops/events/',E.UniqueName)   
 END AS RegLink,    
 AES.UserRegistrationlimit as NumberOfParticipants,  
 NumberofRegistered,  
 NumberOfApproved,  
COALESCE( CASE       
  WHEN ERMS.DoYouNeedInstructor = 'OwnOnly' THEN 'Yes, Self-Managed'      
  WHEN ERMS.DoYouNeedInstructor = 'NeedAdmin' THEN 'Yes, Admin-Managed'      
  WHEN ERMS.DoYouNeedInstructor = 'NoInstructor' THEN 'No'      
 END,  
 CASE       
  WHEN AES.IsNewRequiredCloudlabsIntructor = 'OwnOnly' THEN 'Yes, Self-Managed'      
  WHEN AES.IsNewRequiredCloudlabsIntructor = 'NeedAdmin' THEN 'Yes, Admin-Managed'      
  WHEN AES.IsNewRequiredCloudlabsIntructor = 'NoInstructor' THEN 'No'      
 END )  as IsNewRequiredCloudlabsIntructor,     
 COALESCE(ERMS.RequiredInsrtuctorCount,AES.RequiredInsrtuctorCount) AS RequiredInsrtuctorCount,  
 Coalesce(ERMS.NoOfInstructorFromEventAdmin, AES.NoOfInstructorFromEventAdmin) AS NoOfInstructorFromEventAdmin ,  
 Case when ER.Startdate>=GetUtcDate() and ER.Startdate<(GetUtcDate()+14) then 'T+14' End as T14,  
 Case when ER.Startdate>=GetUtcDate() and ER.Startdate<(GetUtcDate()+7) then 'T+7' End as T7  
FROM EventRequest ER  
 LEFT JOIN ( Select RequestId,  
    Count( Distinct Useruniquename) NumberofRegistered,  
    Count( Distinct Case when [Access Approved]='Approved' --and (AttendedUserID is not null OR AttendedUserID<>'')  
    then Useruniquename end) NumberOfApproved   
    FROM vw_MS_Innovation_WorkshopRequests_Signups   
    Where StartDate>='2026-01-01'  
    Group by RequestId) WRS On WRS.RequestId=ER.RequestId  
LEFT JOIN Events E ON E.Id = ER.EventId   
LEFT JOIN EventRequestStatus ERS ON ER.EventRequestStatusId = ERS.Id  
LEFT JOIN (SELECT EMAIL,MAX(CONCAT(FirstName,' ',LastName))  as RequesterName FROM  Eventuser  GROUP BY EMAIL) EU   
   ON EU.Email = ER.RequestorEmail    
Outer apply openjson(case when isjson(additionaleventsettings)=1 then additionaleventsettings end )                  
    with (                
   UserRegistrationLimit int,                                         
   EventType Varchar(max),                
   IsRequiredCloudlabsIntructor Varchar(max),                
   EventFormat Varchar(max),                
   TrackUniqueName Varchar(max),                
   AssociatedTrack nvarchar(max) as json,                 
   IsRequiredCloudlabsIntructor varchar(1000),          
   IsNewRequiredCloudlabsIntructor VARCHAR(1000),                              
   AssignedTo NVARCHAR(200),       
   RequiredInsrtuctorCount varchar(1000),  
   NoOfInstructorFromEventAdmin VARCHAR(1000)       
   ) as AES       
 Outer Apply eventrequest_MultiSessionData(ER.ID) ERMS  
 LEFT JOIN EventUser EPM ON EPM.Email = AES.AssignedTo AND EPM.IsActive = 1 AND EPM.Email <> ''  
 LEFT JOIN Program P ON P.Id = ER.ProgramId     
 LEFT JOIN SystemTimeZone ST ON ST.Id = ER.TimeZoneId        
WHERE P.PartnerId = 19   
AND ER.Requestid like 'MS%'   
and AES.Eventformat is not null  
AND ER.StartDate >= '2026-03-01'                  
AND ER.Isactive = 1      
AND ER.EventRequestStatusId <> 1
AND ER.Startdate>=GetUtcDate() and ER.Startdate<(GetUtcDate()+14)



