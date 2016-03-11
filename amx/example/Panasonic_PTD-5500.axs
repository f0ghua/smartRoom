PROGRAM_NAME='Panasonic PTD-5500'
(***********************************************************)
(*  FILE CREATED ON: 04/03/2006  AT: 15:58:57              *)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 04/04/2006  AT: 15:22:07        *)
(***********************************************************)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)

(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE
dvPROJ	=	 5001:1:0							// PANASONIC PROJECTOR
dvTP	=	10001:1:0							// TOUCH PANEL

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

TL1	= 1									// TIMELINE 1 CONSTANT

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

DEVCHAN PROJBUTTONS[] = {
	{dvTP,1},								// PROJECTOR POWER ON/OFF
	{dvTP,2},								// PROJECTOR MUTE ON/OFF
	{dvTP,3},								// INPUT RGB 1 SELECT
	{dvTP,4},								// INPUT RGB 2 SELECT
	{dvTP,5},								// INPUT VIDEO SELECT
	{dvTP,6},								// INPUT S-VIDEO SELECT
	{dvTP,7},								// INPUT DVI SELECT
	{dvTP,8},								// MENU SELECT
	{dvTP,9},								// CURSOR UP
	{dvTP,10},								// CURSOR DOWN
	{dvTP,11},								// CURSOR LEFT
	{dvTP,12},								// CURSOR RIGHT
	{dvTP,13},								// ENTER KEY
	{dvTP,14},								// FRONT/FLOOR
	{dvTP,15},								// REAR/FLOOR
	{dvTP,16},								// FRONT/CEILING
	{dvTP,17}								// REAR/CEILING
}
INTEGER nPROJ_PW								// PROJECTOR POWER VARIABLE
INTEGER nPROJ_MT								// PROJECTOR MUTE VARIABLE
INTEGER nPROJ_IN								// PROJECTOR INPUT VARIABLE
INTEGER nPROJ_SETUP								// PROJECTOR SETUP VARIABLE

LONG lTIMES1[]={500,1000,1500}							// PROJECTOR POLLING TIMELINE

(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT
(***********************************************************)
DATA_EVENT [dvPROJ]
{
    ONLINE :
    {
	SEND_COMMAND dvPROJ,'SET BAUD 9600,N,8,1'
	TIMELINE_CREATE(TL1,lTIMES1,LENGTH_STRING(lTIMES1),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
    }
    STRING :
    {
	LOCAL_VAR CHAR BUF[30]
	BUF = DATA.TEXT
	SELECT
	{
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'001',$03",1)) : nPROJ_PW = 1
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'PON',$03",1)) : nPROJ_PW = 1
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'000',$03",1)) : nPROJ_PW = 0
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'POF',$03",1)) : nPROJ_PW = 0
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'1',$03",1)) : nPROJ_MT = 1
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'0',$03",1)) : nPROJ_MT = 0
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'OSH:1',$03",1)) : nPROJ_MT = 1
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'OSH:0',$03",1)) : nPROJ_MT = 0
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'RG1',$03",1)) : nPROJ_IN = 1
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'RG2',$03",1)) : nPROJ_IN = 2
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'VID',$03",1)) : nPROJ_IN = 3
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'SVD',$03",1)) : nPROJ_IN = 4
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'DVI',$03",1)) : nPROJ_IN = 5
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'IIS:RG1',$03",1)) : nPROJ_IN = 1
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'IIS:RG2',$03",1)) : nPROJ_IN = 2
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'IIS:VID',$03",1)) : nPROJ_IN = 3
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'IIS:SVD',$03",1)) : nPROJ_IN = 4
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'IIS:DVI',$03",1)) : nPROJ_IN = 5
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'OIL:0',$03",1)) : nPROJ_SETUP = 1
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'OIL:1',$03",1)) : nPROJ_SETUP = 2
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'OIL:2',$03",1)) : nPROJ_SETUP = 3
	ACTIVE(FIND_STRING(DATA.TEXT,"$02,'OIL:3',$03",1)) : nPROJ_SETUP = 4
	}
    }
}
(***********************************************************)
TIMELINE_EVENT [TL1]
{
    SWITCH(TIMELINE.SEQUENCE)
    {
	CASE 1 : SEND_STRING dvPROJ,"$02,'QPW',$03"				// PROJECTOR POWER POLL STRING
	CASE 2 : SEND_STRING dvPROJ,"$02,'QSH',$03"				// PROJECTOR SHUTTER POLL STRING
	CASE 3 : SEND_STRING dvPROJ,"$02,'QIN',$03"				// PROJECTOR INPUT MODE POLL STRING
    }
}
(***********************************************************)
BUTTON_EVENT [PROJBUTTONS]
{
    PUSH :
    {
	SWITCH(GET_LAST(PROJBUTTONS))
	{
	    CASE 1 :								// PROJECTOR POWER BUTTON
	    {
		IF(nPROJ_PW)
		{
		    SEND_STRING dvPROJ,"$02,'POF',$03"
		    nPROJ_MT = 0
		    nPROJ_IN = 0
		    nPROJ_SETUP = 0
		}
		ELSE
		{
		    SEND_STRING dvPROJ,"$02,'PON',$03"
		}
	    }
	    CASE 2 :								// PROJECTOR MUTE BUTTON
	    {
		IF(nPROJ_PW)
		{
		    IF(nPROJ_MT)
		    {
			SEND_STRING dvPROJ,"$02,'OSH:0',$03"			// PROJECTOR SHUTTER OFF
		    }
		    ELSE
		    {
			SEND_STRING dvPROJ,"$02,'OSH:1',$03"			// PROJECTOR SHUTTER ON
		    }
		}
	    }
	    CASE 3 : IF(nPROJ_PW) SEND_STRING dvPROJ,"$02,'IIS:RG1',$03"	// RGB1 INPUT BUTTON
	    CASE 4 : IF(nPROJ_PW) SEND_STRING dvPROJ,"$02,'IIS:RG2',$03"	// RGB2 INPUT BUTTON
	    CASE 5 : IF(nPROJ_PW) SEND_STRING dvPROJ,"$02,'IIS:VID',$03"	// VID  INPUT BUTTON
	    CASE 6 : IF(nPROJ_PW) SEND_STRING dvPROJ,"$02,'IIS:SVD',$03"	// SVID INPUT BUTTON
	    CASE 7 : IF(nPROJ_PW) SEND_STRING dvPROJ,"$02,'IIS:DVI',$03"	// DVI  INPUT BUTTON
	    CASE 8 :
	    {
		IF(nPROJ_PW)
		{
		    ON[BUTTON.INPUT]
		    SEND_STRING dvPROJ,"$02,'OMN',$03"				// MENU BUTTON
		}
	    }
	    CASE 9 :
	    {
		IF(nPROJ_PW)
		{
		    ON[BUTTON.INPUT]
		    SEND_STRING dvPROJ,"$02,'OCU',$03"				// CURSOR UP
		}
	    }
	    CASE 10:
	    {
		IF(nPROJ_PW)
		{
		    ON[BUTTON.INPUT]
		    SEND_STRING dvPROJ,"$02,'OCD',$03"				// CURSOR DOWN
		}
	    }
	    CASE 11:
	    {
		IF(nPROJ_PW)
		{
		    ON[BUTTON.INPUT]
		    SEND_STRING dvPROJ,"$02,'OCL',$03"				// CURSOR LEFT
		}
	    }
	    CASE 12:
	    {
		IF(nPROJ_PW)
		{
		    ON[BUTTON.INPUT]
		    SEND_STRING dvPROJ,"$02,'OCR',$03"				// CURSOR RIGHT
		}
	    }
	    CASE 13:
	    {
		IF(nPROJ_PW)
		{
		    SEND_STRING dvPROJ,"$02,'OEN',$03"				// ENTER BUTTON
		}
	    }
	    CASE 14: IF(nPROJ_PW) SEND_STRING dvPROJ,"$02,'OIL:0',$03"		// FRONT/FLOOR
	    CASE 15: IF(nPROJ_PW) SEND_STRING dvPROJ,"$02,'OIL:1',$03"		// REAR/FLOOR
	    CASE 16: IF(nPROJ_PW) SEND_STRING dvPROJ,"$02,'OIL:2',$03"		// FRONT/CEILING
	    CASE 17: IF(nPROJ_PW) SEND_STRING dvPROJ,"$02,'OIL:3',$03"		// REAR/CEILING
	}
    }
    HOLD[2,REPEAT] :
    {
	SWITCH(GET_LAST(PROJBUTTONS))
	{
	    CASE 9 : SEND_STRING dvPROJ,"$02,'OCU',$03"				// CURSOR UP
	    CASE 10: SEND_STRING dvPROJ,"$02,'OCD',$03"				// CURSOR DOWN
	    CASE 11: SEND_STRING dvPROJ,"$02,'OCL',$03"				// CURSOR LEFT
	    CASE 12: SEND_STRING dvPROJ,"$02,'OCR',$03"				// CURSOR RIGHT
	}
    }
    RELEASE :
    {
	SWITCH(GET_LAST(PROJBUTTONS))
	{
	    CASE 8 : OFF[BUTTON.INPUT]
	    CASE 9 : OFF[BUTTON.INPUT]
	    CASE 10: OFF[BUTTON.INPUT]
	    CASE 11: OFF[BUTTON.INPUT]
	    CASE 12: OFF[BUTTON.INPUT]
	    CASE 13: OFF[BUTTON.INPUT]
	}
    }
}
(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM
[dvTP,1]	= (nPROJ_PW)
[dvTP,2]	= (nPROJ_MT)
[dvTP,3]	= (nPROJ_IN = 1)
[dvTP,4]	= (nPROJ_IN = 2)
[dvTP,5]	= (nPROJ_IN = 3)
[dvTP,6]	= (nPROJ_IN = 4)
[dvTP,7]	= (nPROJ_IN = 5)
[dvTP,14]	= (nPROJ_SETUP = 1)
[dvTP,15]	= (nPROJ_SETUP = 2)
[dvTP,16]	= (nPROJ_SETUP = 3)
[dvTP,17]	= (nPROJ_SETUP = 4)
(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)

