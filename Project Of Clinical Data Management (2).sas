LIBNAME CDM XLSX "/home/u64061897/Clinical Data/clinical_data_management.xlsx";

/* IMPORTING CDM DATA */
proc import 
		datafile="/home/u64061897/Clinical Data/clinical_data_management.xlsx" 
		dbms=xlsx out=cdm_data_raw replace;
	getnames=yes;
run;

title "First 10 Records of Raw Clinical Data";

proc print data=cdm_data_raw (obs=10);
run;

title;

/* DATA CLEANING AND PREPARATION */
/* Data Step to Clean and Prepare Data */
data cdm_data;
	set cdm_data_raw;
	Gender=upcase(Gender);

	if Adverse_Event in ("none", "NONE") then
		Adverse_Event="None";
	else if Adverse_Event in ("mild", "MILD") then
		Adverse_Event="Mild";
	else if Adverse_Event in ("moderate", "MODERATE") then
		Adverse_Event="Moderate";
	else if Adverse_Event in ("severe", "SEVERE") then
		Adverse_Event="Severe";

	if Age < 30 then
		Age_Group="Under 30";
	else if Age >=30 and Age < 50 then
		Age_Group="30-49";
	else
		Age_Group="50+";
run;

title "First 10 Records of Cleaned Clinical Data";

proc print data=cdm_data (obs=10);
run;

/*DATA VALIDATION*/
ods noproctitle;
title "Missing Values Check in Clinical Data";

proc means data=cdm_data n nmiss mean std min max;
run;

title;
ods proctitle;

proc sort data=cdm_data nodupkey;
	by Patient_ID;
run;

/* FREQUENCY ANALYSIS OF CATEGORICAL VARIABLES */
ods noproctitle;
title "Frequency Analysis of Categorical Variables";

proc freq data=cdm_data;
	tables Gender Country Treatment_Group Adverse_Event Age_Group;
run;

ods proctitle;

/* SQL-BASED ANALYSIS */
title "Patient Count by Country";

proc sql;
	select Country, count(*) as Patient_Count from cdm_data group by Country;
quit;

title "Average Efficacy Score by Treatment Group";

proc sql;
	select Treatment_Group, avg(Efficacy_Score) as Avg_Efficacy from cdm_data 
		group by Treatment_Group;
quit;

/* SUMMARY DATASET CREATION */
proc sort data=cdm_data;
	by Country;
run;

/* Creating Summary Dataset for Patient Count per Country */
data country_summary;
	set cdm_data;
	by Country;
	retain Patient_Count 0;

	if first.Country then
		Patient_Count=0;
	Patient_Count + 1;

	if last.Country then
		output;
run;

proc print data=country_summary;
run;

/* Creating summary dataset for efficacy scores */
ods noproctitle;
title "Summary Statistics for Efficacy Scores by Treatment Group";

proc means data=cdm_data mean std min max;
	class Treatment_Group;
	var Efficacy_Score;
	output out=efficacy_summary mean=Avg_Efficacy;
run;

title;
ods proctitle;

/* DATA VISUALIZATION WITH GRAPHS */
title "Vertical Bar Chart - Patient Distribution by Country";

proc sgplot data=cdm_data;
	vbar Country / response=Patient_ID group=Country datalabel 
		groupdisplay=cluster;
	styleattrs datacolors=(red green blue orange purple cyan pink yellow brown 
		gray);
run;

title "Pie Chart - Adverse Event Distribution";

proc template;
	define statgraph piechart;
		begingraph;
		layout region;
		piechart category=Adverse_Event / datalabelAttrs=inside dataskin=pressed;
		endlayout;
		endgraph;
	end;
run;

proc sgrender data=cdm_data template=piechart;
run;

title "Line Chart - Adverse Events by Treatment Group";

proc sgplot data=cdm_data;
	series x=Treatment_Group y=Adverse_Event / group=Adverse_Event markers;
run;

title "Histogram - Average Efficacy Score by Treatment Group";

proc sgplot data=cdm_data;
	histogram Efficacy_Score / group=Treatment_Group transparency=0.5;
	density Efficacy_Score;
	keylegend / location=outside position=topleft;
run;