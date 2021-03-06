
/**************************************************************************
	This query pulls PR data by employee and joins it with AS data. It is
	useful for comparing where an employee's AS hours are mapping versus
	where they are coded in PR. Data pulls PR/AS mapping along with their
	PR allocation %. Set @date to filter by which day - present you want 
	data. Set locations to filter by at bottom of query.
	
	Note: if any employee has PR coding split to multiple locations, their
	AS data will be joined to each location.

	Created by: Elliott Good

	Last Edited: 10/21/16
**************************************************************************/


  DECLARE @date as varchar(10)

  SET @date = '6/1/16'

  SELECT distinct EmployeeId						-- get PR data
		,[First Name] + ' ' + [Last Name] as Name
		,Pay_Period
		,m.Department           as [PR_dept]
		,a.Department           as [AS_dept]
		,m.location             as [PR_loc]
		,c.location_description as [PR_loc_desc]
		,a.location             as [AS_loc]
		,pr.Client              as [PR_client]
		,a.client               as [AS_client]
		,pr.Alloc_Percent		as [PR_Allocation]
		,[Job Group Description]
		,[Job Class Description]
		,a.workcode
		,a.workcode_description
		,hours
  FROM [PR].[dbo].[QRY_PAYROLL_HOURLY] pr

  JOIN [GLP].dim.amr_rollup_center c ON pr.center = c.center_id
  JOIN [AS].dbo.as_map m			 ON m.location = c.location_id

  JOIN (SELECT employee_ssn							-- get AS data
			  ,week_ending
			  ,a_detail.department
			  ,a_map.location
			  ,a_map.client
			  ,a_detail.workcode
			  ,wc.workcode_description
			  ,sum(hours) as [hours]
		FROM [AS].dbo.as_detail a_detail
		JOIN [AS].dbo.as_map a_map
		ON a_detail.department = a_map.department
		AND  a_detail.workcode = a_map.workcode
		JOIN [AS].dbo.workcode wc
		ON a_detail.department = wc.department
		AND  a_detail.workcode = wc.workcode
		WHERE week_ending >= @date
		AND a_detail.workcode <> '090'
		AND hours <> '0'
		GROUP BY employee_ssn
				,week_ending
				,a_detail.department
				,a_map.location
				,a_map.client
				,a_detail.workcode
				,wc.workcode_description
		) a
  ON pr.employeeId = a.employee_ssn
  AND pr.Pay_Period = a.week_ending
  WHERE Pay_Period >= @date 
  AND EarningCode in ('REG','OTD')
  AND center in (
		SELECT center_id
		FROM [GLP].dim.amr_rollup_center 
		WHERE location_id in ('CA517235', 'CA517280')	-- select locations
		)