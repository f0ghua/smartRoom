PROGRAM_NAME='WC_Back_Proj,Rev 1'
(***********************************************************)
(*  FILE REVISION: Rev 1                                   *)
(*  REVISION DATE: 08/30/2009  AT: 16:48:01                *)
(*                                                         *)
(*  COMMENTS:                                              *)
(*  Revamp for new module                                  *)
(*                                                         *)
(***********************************************************)
DEFINE_DEVICE
dvWCBackProjector	= 0:10:0 // Fellowship Sharp
vdvWCBackProjector	= 33050:1:0 //Virtual Fellowship Projector

DEFINE_CONSTANT
DEFINE_TYPE
DEFINE_VARIABLE

volatile integer tl151

VOLATILE INTEGER nWCBackProj_LampHRS_1
VOLATILE INTEGER nWCBackProj_LampHRS_2

VOLATILE INTEGER nWCBackProj_LampLife_1
VOLATILE INTEGER nWCBackProj_LampLife_2

VOLATILE INTEGER nPowerState
PERSISTENT INTEGER nWCBackScreen
VOLATILE INTEGER WCBackProjError

VOLATILE INTEGER nBackProjDebug

VOLATILE LONG WC_BACK_PROJ_QUERRY [] =
{
0,   //Reset
300, //Input
600, //Lamp 1 Hrs
900, //Lamp 2 Hrs
1200,//Lamp 1 Life
1500 //Lamp 2 Life
}

VOLATILE LONG WC_BACK_PROJ_FEEDBACK [] = {0,200}

VOLATILE DEV WCBackTP []= {130:1:10, 10001:12:1}
VOLATILE DEVCHAN WCBackScreen []= {{19:1:10,7}, {19:1:0,8}}

DEFINE_LATCHING
DEFINE_MUTUALLY_EXCLUSIVE
DEFINE_START
SEND_COMMAND WCBackTP[2],"'ADBEEP'"
DEFINE_MODULE 'Sharp XG-PG50,Rev 1' WCBackProj(vdvWCBackProjector, dvWCBackProjector, nBackProjDebug) //Samsvic Projector
DEFINE_CALL 'Panel Update'
{

    SEND_COMMAND WCBackTP,"'!T',22,'Lamp A Hrs: ',ITOA (nWCBackProj_LampHRS_1)"
    SEND_COMMAND WCBackTP,"'!T',23,'Lamp B Hrs: ',ITOA (nWCBackProj_LampHRS_2)"
    SEND_COMMAND WCBackTP,"'!T',24,'Lamp A Life: ',ITOA (nWCBackProj_LampLife_1)"
    SEND_COMMAND WCBackTP,"'!T',25,'Lamp B Life: ',ITOA (nWCBackProj_LampLife_2)"
    
    SWITCH (WCBackProjError)
    {
	CASE 0: SEND_COMMAND WCBackTP,"'!T',26,'Normal'"
	CASE 1: SEND_COMMAND WCBackTP,"'!T',26,'High Temp'"
	CASE 2: SEND_COMMAND WCBackTP,"'!T',26,'Fan Error'"
	CASE 4: SEND_COMMAND WCBackTP,"'!T',26,'Intake Cover Open'"
	CASE 8: SEND_COMMAND WCBackTP,"'!T',26,'Lamp Life 5% or Less'"
	CASE 16: SEND_COMMAND WCBackTP,"'!T',26,'Lamp Burn-Out'"
	CASE 32: SEND_COMMAND WCBackTP,"'!T',26,'Lamp Ignition Failure'"
	CASE 64: SEND_COMMAND WCBackTP,"'!T',26,'Temp Abnormally High'"
    }
}
DEFINE_EVENT
BUTTON_EVENT [WCBackTP,21]//Projector Power
{
    HOLD [20]:
    {
	IF (!([vdvWCBackProjector,254] || [vdvWCBackProjector,253]))
	{
	    IF (![vdvWCBackProjector,255])
	    {
		PULSE [vdvWCBackProjector,27] //Proj On
		
		IF (!(nWCBackScreen = 2))
		{
		    PULSE [WCBackScreen[2]]
		    nWCBackScreen = 2
		}
	    }
	    ELSE
	    {
		PULSE [vdvWCBackProjector,28] //Proj Off
		
		PULSE [WCBackScreen[1]]
		nWCBackScreen = 1
		WAIT 200
		{
		    PULSE [WCBackScreen[1]]
		}
	    }
	}
    }
}
BUTTON_EVENT [WCBackTP,22]//Screen Up
{
    PUSH:
    {
	PULSE [WCBackScreen[1]]
	nWCBackScreen = 1
	WAIT 200
	{
	    PULSE [WCBackScreen[1]]
	}
    }
}
BUTTON_EVENT [WCBackTP,23]//Screen Down
{
    PUSH:
    {
	IF (!(nWCBackScreen = 2))
	{
	    PULSE [WCBackScreen[2]]
	    nWCBackScreen = 2
	}
    }
}
//BUTTON_EVENT [WCBackTP,15] // Freeze
//{
//    PUSH:
//    {
//	PULSE [vdvWCBackProjector,213]
//    }
//}
//BUTTON_EVENT [WCBackTP,16] //Black
//{
//    PUSH:
//    {
//	PULSE [vdvWCBackProjector,210]
//    }
//}
DATA_EVENT [0:1:0] //Master
{
    ONLINE:
    {
	WAIT 20
	{
	    IP_CLIENT_OPEN (10,'192.168.1.128',10002,IP_TCP)
	    TIMELINE_CREATE (151,WC_BACK_PROJ_FEEDBACK,2,TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	}
    }
}
DATA_EVENT [WCBackTP]
{
    ONLINE:
    {
	WAIT 30
	CALL 'Panel Update'
    }
}
DATA_EVENT [dvWCBackProjector]
{
    OFFLINE:
    {
	IP_CLIENT_CLOSE (10)
	IP_CLIENT_OPEN (10,'192.168.1.128',10002,IP_TCP)
    }
    ONERROR:
    {
	SEND_STRING 0,"'ERROR WC Back Projector = ',DATA.NUMBER,13"
    }
}
DATA_EVENT [vdvWCBackProjector]
{
    STRING:
    {
	SELECT
	{
	    ACTIVE (FIND_STRING (DATA.TEXT,'LAMPTIME1-',1)):
	    {
		REMOVE_STRING (DATA.TEXT,'-',1)
		IF (!(nWCBackProj_LampHRS_1 = ATOI ("DATA.TEXT")))
		{
		    nWCBackProj_LampHRS_1 = ATOI ("DATA.TEXT")
		    SEND_COMMAND WCBackTP,"'!T',22,'Lamp A Hrs: ',ITOA (nWCBackProj_LampHRS_1)"
		}
	    }
	    ACTIVE (FIND_STRING (DATA.TEXT,'LAMPTIME2-',1)):
	    {
		REMOVE_STRING (DATA.TEXT,'-',1)
		IF (!(nWCBackProj_LampHRS_2 = ATOI ("DATA.TEXT")))
		{
		    nWCBackProj_LampHRS_2= ATOI ("DATA.TEXT")
		    SEND_COMMAND WCBackTP,"'!T',23,'Lamp B Hrs: ',ITOA (nWCBackProj_LampHRS_2)"
		}
	    }
	    ACTIVE (FIND_STRING (DATA.TEXT,'LAMPLIFE1-',1)):
	    {
		REMOVE_STRING (DATA.TEXT,'-',1)
		IF (!(nWCBackProj_LampLife_1 = ATOI("DATA.TEXT")))
		{
		    nWCBackProj_LampLife_1 = ATOI("DATA.TEXT")
		    SEND_COMMAND WCBackTP,"'!T',24,'Lamp A Life: ',ITOA (nWCBackProj_LampLife_1)"
		}
	    }
	    ACTIVE (FIND_STRING (DATA.TEXT,'LAMPLIFE2-',1)):
	    {
		REMOVE_STRING (DATA.TEXT,'-',1)
		IF (!(nWCBackProj_LampLife_2 = ATOI("DATA.TEXT")))
		{
		    nWCBackProj_LampLife_2 = ATOI("DATA.TEXT")
		    SEND_COMMAND WCBackTP,"'!T',25,'Lamp B Life: ',ITOA (nWCBackProj_LampLife_2)"
		}
	    }
	    ACTIVE (FIND_STRING(DATA.TEXT,'ERROR',1)):
	    {
		REMOVE_STRING (DATA.TEXT,'ERROR',1)
		WCBackProjError = ATOI ("DATA.TEXT")
		REMOVE_STRING (DATA.TEXT,'-',1)
		SEND_COMMAND WCBackTP,"'!T',26,DATA.TEXT"
	    }
	}
    }
    ONLINE:
    {
	WAIT 20
	{
	    TIMELINE_CREATE (150,WC_BACK_PROJ_QUERRY,6,TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	}
    }
    OFFLINE:
    {
	TIMELINE_KILL (150)
    }
}
TIMELINE_EVENT [150] //WC Back Projector Module Querry
{
    SWITCH (TIMELINE.SEQUENCE)
    {
	CASE 1: {}
	CASE 2: SEND_COMMAND vdvWCBackProjector,"'?INPUT'"
	CASE 3: SEND_COMMAND vdvWCBackProjector,"'?LAMPTIME1'"
	CASE 4: SEND_COMMAND vdvWCBackProjector,"'?LAMPTIME2'"
	CASE 5: SEND_COMMAND vdvWCBackProjector,"'?LAMPLIFE1'"
	CASE 6: SEND_COMMAND vdvWCBackProjector,"'?LAMPLIFE2'"
    }
}
TIMELINE_EVENT [151] //Feedback
{
    SWITCH (TIMELINE.SEQUENCE)
    {
	CASE 1:{}
	CASE 2:
	{
	    //Power
	    SELECT
	    {
		ACTIVE (![vdvWCBackProjector,255]&& !(nPowerState=1)): //Off
		{
		    SEND_COMMAND WCBackTP,"'!T',21,'Power Off'"
		    OFF [WCBackTP,21]
		    nPowerState = 1
		}
		ACTIVE ([vdvWCBackProjector,255]&&[vdvWCBackProjector,253]&& !(nPowerState=2)): //Warming
		{
		    SEND_COMMAND WCBackTP,"'!T',21,'Warming'"
		    ON [WCBackTP,21]
		    nPowerState = 2
		}
		ACTIVE ([vdvWCBackProjector,255]&&[vdvWCBackProjector,254]&& !(nPowerState=3)): //Cooling
		{
		    SEND_COMMAND WCBackTP,"'!T',21,'Cooling'"
		    OFF [WCBackTP,21]
		    nPowerState = 3
		}
		ACTIVE ([vdvWCBackProjector,255]&&![vdvWCBackProjector,253]&&![vdvWCBackProjector,254]&& !(nPowerState=4)): //On
		{
		    SEND_COMMAND WCBackTP,"'!T',21,'Power On'"
		    ON [WCBackTP,21]
		    nPowerState = 4
		}
	    }
	    
	    [WCBackTP[1],24] = [vdvWCBackProjector,251]//Online
	    [WCBackTP[2],251] = [vdvWCBackProjector,251]//Online
	    
	    [WCBackTP[1],254] = [vdvWCBackProjector,254]//Cooling
	    [WCBackTP[1],253] = [vdvWCBackProjector,253]//Warming
	    [WCBackTP,21] = [vdvWCBackProjector,255] //Power
	    
	    [WCBackTP,22] = nWCBackScreen == 1
	    [WCBackTP,23] = nWCBackScreen == 2
	}
    }
}

DEFINE_PROGRAM
IF (!TIMELINE_ACTIVE(151))
{
    tl151 = true
    TIMELINE_CREATE (151,WC_BACK_PROJ_FEEDBACK,2,TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
if (timeline_active(151))
{
    tl151 = false
}