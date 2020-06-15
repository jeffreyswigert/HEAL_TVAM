/******************************************************************
This is the MASTER do-file for 

		 "Measuring Therapist Value-Added: Evidence from an Online Therapy Platform"

Coded by: Mitchell Zufelt and Jeff Swigert


INPUTS: 
		- TalkSpace_Base.csv
		- analysis_om_scale_id_4.do
		- analysis_om_scale_id_5.do
		- analysis_om_scale_id_47.do
		- analysis_om_scale_id_1.do
		- analysis_om_scale_id_2.do
		- analysis_om_scale_id_3.do
		- va_overall.do
	
***********************************************************************
***********************************************************************
*********************************************************************
*********************************************************************/
clear
set more off

***GLOBALS FOR DIRECTORIES***
//NOTE: All do-files belong in the "main" folder. TalkSpace_Base.csv belongs in the "data" folder.
global main "C:\Users\mitch\OneDrive\Desktop\TVAM\HEAL_TVAM"
global data "C:\Users\mitch\OneDrive\Desktop\TVAM\data"
global analysis "C:\Users\mitch\OneDrive\Desktop\TVAM\analysis"
global reporting "C:\Users\mitch\OneDrive\Desktop\TVAM\reporting"

***INITIAL DATA PREP: Imports and cleans TalkSpace_Base.csv***
cd $main
do "TVAM_data_prep.do"

***ANALYSES AND REPORTING*** 
cd $main
do "analysis_om_scale_id_4.do"
cd $main
do "analysis_om_scale_id_5.do"
cd $main
do "analysis_om_scale_id_47.do"
cd $main
do "analysis_om_scale_id_1.do"
cd $main
do "analysis_om_scale_id_2.do"
cd $main
do "analysis_om_scale_id_3.do"

***COMBINED VA MEASURES***
cd $main
do "va_overall.do"






















