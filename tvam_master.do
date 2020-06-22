/******************************************************************
This is the MASTER do-file for 

		 "Measuring Therapist Value-Added: Evidence from an Online Therapy Platform"

Coded by: Mitchell Zufelt and Jeff Swigert


INPUTS: 
		- TalkSpace_Base.csv
		- analysis_om_scale_id_4
		- analysis_om_scale_id_5
		- analysis_om_scale_id_47
		- analysis_om_scale_id_1
		- analysis_om_scale_id_2
		- analysis_om_scale_id_3
	
***********************************************************************
***********************************************************************
*********************************************************************
*********************************************************************/
clear
set more off
global jeff1 "/Users/jeffreyswigert/OneDrive/HEAL_TVAM/"
***SELECT WORKING DIRECTORY***
cd $jeff1 //"E:\"

***INITIAL DATA PREP: Imports and cleans TalkSpace_Base.csv***
do "TVAM_data_prep.do"

***ANALYSES AND REPORTING: Creates a folder (tvam_#) for each of the 6 om_scale_id's we analyze 
do "analysis_om_scale_id_4.do"
do "analysis_om_scale_id_5.do"
do "analysis_om_scale_id_47.do"
do "analysis_om_scale_id_1.do"
do "analysis_om_scale_id_2.do"
do "analysis_om_scale_id_3.do"
























