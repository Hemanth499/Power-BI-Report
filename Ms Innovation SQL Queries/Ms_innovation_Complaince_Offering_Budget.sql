
Create Or ALTER view  [dbo].[Ms_innovation_Complaince_Offering_Budget]  
as  
SELECT  
 FA.ID AS FFID,  
    ER.RequestId AS EventRequestId,  
 ER.Title AS EventTitle,  
CASE WHEN ERS.Name = 'Approved'  
         AND ER.EndDate < GETUTCDATE()  
        THEN 'Completed'  
        ELSE ERS.Name  
END AS EventRequestStatus,  
CASE WHEN ER.RescheduleReason IS NULL THEN 'No' ELSE 'Yes' END AS IsReschedule,  
  ER.RescheduleReason,  
  ERL.CreatedTime AS ApprovedOn,  
 ER.StartDate as EventStartDate,  
    ER.StartDate AS EventStartDateRaw,  
    CONCAT(ER.EndDate, ' ', ER.EndTime) AS EventEndDate,   
  ER.EndDate AS EventEndDateRaw,  
CASE  
    WHEN O.Name = 'Others' THEN OERA.OfferingName  
    ELSE O.Name  
END AS OfferingName,  
    O.Name AS Offer_Name,  
 FS.Name AS FulfillmentStatus,  
 FMT.Name AS FullfillmentMangeType,  
 ER1.AssignedTo AS EventAssignedTo,  
 FA.AssignedTo AS FulfilmentAssignedTo,  
 COALESCE(NULLIF(CONCAT(EU_FA.FirstName,' ',EU_FA.LastName),''), FA.AssignedTo)  
    AS FulfilmentAssignedToName,  
 ISNULL(BS.Name,'NA') AS BudgetStatus,  
 CT.Name AS ChargeTypeName,  
 FA.FulfillmentDate,  
 convert(date,OERA.SLA) as FulfilmentDueDate ,  
--case when convert(date,FA.FulfillmentDate) <= convert(date,OERA.SLA) then 'Met'  ----Added on 4/2/26  
-- when convert(date,FA.FulfillmentDate) > convert(date,OERA.SLA) then 'Not Met'   
-- when convert(date,FA.FulfillmentDate) is null and convert(date,OERA.SLA)<convert(date,getutcdate())  then 'Not Met'  
-- else null end as SLAmet,
FA.ModifiedTime,
Case  
 WHEN (convert(date,GETUTCDATE()) > convert(date,OERA.SLA)  and FS.Name in ('Pending','On-Hold','In Progress')) OR
 (Convert(Date,FA.ModifiedTime)>convert(date,OERA.SLA) AND FS.Name in ('Completed' ,'Cancelled','Fulfilled')) 
 THEN 'Not Met'  
    when convert(date,OERA.SLA) <= convert(date,GETUTCDATE()) and FS.Name in ('Completed' ,'Cancelled','Fulfilled')  
    THEN 'Met'  
 else 'NA'   
End as OfferingDueDateSLA ,  
Case   
 WHEN ( convert(date,DATEADD(DAY, 3, ER.EndDate))< convert(date,GETUTCDATE()) and FS.Name in ('Pending','On-Hold','In Progress')  ) or
  (Convert(Date,FA.ModifiedTime)>convert(date,DATEADD(DAY, 3, ER.EndDate)) AND FS.Name in ('Completed' ,'Cancelled','Fulfilled')) 
   -- and convert(date, ER.EndDate)< convert(date,GETUTCDATE())  
 THEN 'Not Met'  
    when convert(date,DATEADD(DAY, 3, ER.EndDate))<= convert(date,GETUTCDATE())and FS.Name in ('Completed' ,'Cancelled','Fulfilled') 
	and convert(date,DATEADD(DAY, 3, ER.EndDate))>=Convert(Date,FA.ModifiedTime)
    THEN 'Met'  
 else 'NA'    
END AS BudgetSLA  ,
Case 
	When  GETUTCDATE()>convert(date,OERA.SLA) AND FS.Name in ('Pending','On-Hold','In Progress')
	Then 'Due' 
	Else 'No Due'
	End as
DueOfferings ,
Case  
	when  convert(date,GETUTCDATE())>convert(date,DATEADD(DAY, 3, ER.EndDate)) and FS.Name in ('Pending','On-Hold','In Progress') 
	then 'Due'
	Else 'No Due'  
End as BudgetClosureDue
   
FROM EventRequest ER  
JOIN OfferingEventRequestAssociation OERA  
    ON ER.Id = OERA.EventRequestId  
   AND ER.IsActive = 1  
   AND OERA.IsActive = 1  
JOIN ChargeType CT ON CT.Id = OERA.ChargeTypeId  
JOIN Offering O ON O.Id = OERA.OfferingId AND O.IsActive = 1  
  
LEFT JOIN EventRequestStatus ERS ON ER.EventRequestStatusId = ERS.Id  
LEFT JOIN BudgetStatus BS ON BS.Id = ER.BudgetStatusId  
  
OUTER APPLY eventrequest_approval_log(ER.Id) ERL  
LEFT JOIN FulfillmentAssociation FA  
    ON FA.OfferingEventRequestAssociationId = OERA.Id  
   AND FA.IsActive = 1  
  
LEFT JOIN FullfillmentStatus FS ON FS.Id = FA.FulfillmentStatus  
JOIN FullfillmentMangeType FMT ON FMT.Id = OERA.FullfilmentMangeTypeId  
  
LEFT JOIN EventUser EU_FA  
    ON EU_FA.Email = FA.AssignedTo  
   AND EU_FA.IsActive = 1  
   AND EU_FA.Email <> ''  
  
CROSS APPLY OPENJSON(ER.Additionaleventsettings)  
WITH (  
    EventFormat varchar(1000),  
    EventType varchar(1000),  
    AssignedTo nvarchar(200),  
    AssociatedTrack nvarchar(max) AS JSON,  
    CommercialSolutionArea varchar(1000)  
) ER1  
LEFT JOIN Program P ON P.Id = ER.ProgramId  
WHERE ER.EventRequestStatusId <> 1 AND ER.IsActive = 1 
  AND P.PartnerId = 19   
  AND  ER.StartDate>='2026-01-01'  
  
Union   
  
/* =========================================================  
   PRACTICE LAB REQUEST  
========================================================= */  
  
SELECT  
 FA.ID as FFID,  
    ER.RequestId AS EventRequestId,  
 ER.Title AS EventTitle,  
CASE WHEN ERS.Name = 'Approved'  
         AND ER.EndDate < GETUTCDATE()  
        THEN 'Completed'  
        ELSE ERS.Name  
END AS EventRequestStatus,  
CASE WHEN ER.RescheduleReason IS NULL THEN 'No' ELSE 'Yes' END AS IsReschedule,  
  ER.RescheduleReason,  
  ERL.CreatedTime AS ApprovedOn,  
 ER.StartDate as EventStartDate,  
    ER.StartDate AS EventStartDateRaw,  
    CONCAT(ER.EndDate, ' ', ER.EndTime) AS EventEndDate,   
  ER.EndDate AS EventEndDateRaw,  
CASE  
    WHEN O.Name = 'Others' THEN OERA.OfferingName  
    ELSE O.Name  
END AS OfferingName,  
    O.Name AS Offer_Name,  
 FS.Name AS FulfillmentStatus,  
 FMT.Name AS FullfillmentMangeType,  
 ER1.AssignedTo AS EventAssignedTo,  
 FA.AssignedTo AS FulfilmentAssignedTo,  
 COALESCE(NULLIF(CONCAT(EU_FA.FirstName,' ',EU_FA.LastName),''), FA.AssignedTo)  
    AS FulfilmentAssignedToName,  
 ISNULL(BS.Name,'NA') AS BudgetStatus,  
 CT.Name AS ChargeTypeName,  
 FA.FulfillmentDate,  
 convert(date,OERA.SLA) as FulfilmentDueDate ,  
--case when convert(date,FA.FulfillmentDate) <= convert(date,OERA.SLA) then 'Met'  ----Added on 4/2/26  
-- when convert(date,FA.FulfillmentDate) > convert(date,OERA.SLA) then 'Not Met'   
-- when convert(date,FA.FulfillmentDate) is null and convert(date,OERA.SLA)<convert(date,getutcdate())  then 'Not Met'  
-- else null end as SLAmet,  
FA.ModifiedTime,
Case  
 WHEN   (convert(date,GETUTCDATE()) > convert(date,OERA.SLA)  and FS.Name in ('Pending','On-Hold','In Progress')  OR
 (Convert(Date,FA.ModifiedTime)>convert(date,OERA.SLA) AND FS.Name in ('Completed' ,'Cancelled','Fulfilled')) )
 THEN 'Not Met'  
    when convert(date,OERA.SLA) <= convert(date,GETUTCDATE()) and FS.Name in ('Completed' ,'Cancelled','Fulfilled')  
    THEN 'Met'  
 else 'NA'   
End as OfferingDueDateSLA ,  
Case   
 WHEN convert(date,DATEADD(DAY, 3, ER.EndDate))< convert(date,GETUTCDATE()) and FS.Name in ('Pending','On-Hold','In Progress')  or
  (Convert(Date,FA.ModifiedTime)>convert(date,DATEADD(DAY, 3, ER.EndDate)) AND FS.Name in ('Completed' ,'Cancelled','Fulfilled'))
   -- and convert(date, ER.EndDate)< convert(date,GETUTCDATE())  
 THEN 'Not Met'  
    when convert(date,DATEADD(DAY, 3, ER.EndDate))<= convert(date,GETUTCDATE()) and FS.Name in ('Completed' ,'Cancelled','Fulfilled')  
	and convert(date,DATEADD(DAY, 3, ER.EndDate))>=Convert(Date,FA.ModifiedTime)
    THEN 'Met'  
 else 'NA'    
END AS BudgetSLA  ,
Case 
	When  GETUTCDATE()>convert(date,OERA.SLA) AND FS.Name in ('Pending','On-Hold','In Progress')
	Then 'Due' 
	Else 'No Due'
	End as
DueOfferings,
Case  
	when  convert(date,GETUTCDATE())>convert(date,DATEADD(DAY, 3, ER.EndDate)) and FS.Name in ('Pending','On-Hold','In Progress')  
	then 'Due'
	Else 'No Due'  
End as BudgetClosureDue
   
FROM PracticeLabRequest ER  
JOIN OfferingEventRequestAssociation OERA  
    ON ER.Id = OERA.PracticeLabRequestId  
   AND ER.IsActive = 1  
   AND OERA.IsActive = 1  
JOIN ChargeType CT ON CT.Id = OERA.ChargeTypeId  
JOIN Offering O ON O.Id = OERA.OfferingId AND O.IsActive = 1  
  
  
LEFT JOIN EventRequestStatus ERS ON ER.RequestStatusId = ERS.Id  
LEFT JOIN BudgetStatus BS ON BS.Id = ER.BudgetStatusId  
  
OUTER APPLY eventrequest_approval_log(ER.Id) ERL  
LEFT JOIN FulfillmentAssociation FA  
    ON FA.OfferingEventRequestAssociationId = OERA.Id  
   AND FA.IsActive = 1  
  
LEFT JOIN FullfillmentStatus FS ON FS.Id = FA.FulfillmentStatus  
  
JOIN FullfillmentMangeType FMT ON FMT.Id = OERA.FullfilmentMangeTypeId  
  
LEFT JOIN EventUser EU_FA  
    ON EU_FA.Email = FA.AssignedTo  
   AND EU_FA.IsActive = 1  
   AND EU_FA.Email <> ''  
  
CROSS APPLY OPENJSON(     
  CASE WHEN ISJSON(ER.Additionallabsettings)=1  
         THEN ER.Additionallabsettings END  
   )  
WITH (  
    EventFormat varchar(1000),  
    EventType varchar(1000),  
    AssignedTo nvarchar(200),  
    AssociatedTrack nvarchar(max) AS JSON,  
    CommercialSolutionArea varchar(1000)  
) ER1  
  
WHERE ER.RequestStatusId <> 1  AND ER.IsActive = 1
    AND ER.PartnerId = 19  
  AND  ER.StartDate>='2026-01-01';
GO


