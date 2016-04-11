PROGRAM_NAME='rosePark'
(***********************************************************)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 04/05/2006  AT: 09:00:25        *)
(***********************************************************)
(* System Type : NetLinx                                   *)
(**************'*********************************************)
(* REV HISTORY:                                            *)
(***********************************************************)
(*
    $History: $
    
    The ZhenJiang rosePark project use NX3200 with severl modules
    
        - AVB-ABS [serial]
        - AVB-DIN-REL8-50(strong electrical controller)
        - AVB-32-IO-I
        - AVB-AO8-0-10(dimmer controller) [ none used ]
        - 
    
    6 AVB-DIN-REL8-50 and 3 AVB-IO8-0-10 connect to AVB-ABS and then linked
    to NX3200's serial port.

    ipad
        - apple id: demo2016_wang@icloud.com/dem0Wang

*)
(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

dvTP1       = 11001:1:0 // ipad 1024x768
dvTP2       = 11005:1:0 // iphone 640x960

dvIOKP1     = 60:2:0    // floor 1
dvIOKP2     = 61:2:0    // floor 1
dvIOKP3     = 64:2:0    // floor 2
dvIOKP4     = 65:2:0    // floor 2
dvIOKP5     = 67:2:0    // floor 2
dvIOKP6     = 68:2:0    // floor 3
dvIOKP7     = 69:2:0    // floor 3
dvIOKP8     = 63:2:0    // floor 0
(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

TP_MAX_PANELS       = 2
TP_STATUS_OFF       = 0
TP_STATUS_ON        = 1

POWER_ON            = 1
POWER_OFF           = 0

ADDRCODE_SPVIEW     = 100
MAX_LIGHTSET_NUMBER = 6
ITEMS_PER_SET       = 8
CHAN_BTN_LIGHTSET_1 = 11
CHAN_BTN_LIGHTSET_2 = 12
CHAN_BTN_LIGHTSET_3 = 13
CHAN_BTN_LIGHTSET_4 = 14
CHAN_BTN_LIGHTSET_5 = 15
CHAN_BTN_LIGHTSET_6 = 16
BTN_LIGHTSET_1      = 1
BTN_LIGHTSET_2      = 2
BTN_LIGHTSET_3      = 3
BTN_LIGHTSET_4      = 4
BTN_LIGHTSET_5      = 5
BTN_LIGHTSET_6      = 6

KP_CHAN_F1DOOR_K1  = 8
KP_CHAN_F1DOOR_K2  = 7
KP_CHAN_F1DINNER_K1= 6
KP_CHAN_F1DINNER_K2= 5
KP_CHAN_F1HALL_K1  = 4
KP_CHAN_F1HALL_K2  = 3
KP_CHAN_F1HALL_K3  = 2

KP_CHAN_F1STAIRS_K1= 8
KP_CHAN_F1STAIRS_K2= 7

KP_CHAN_F2GRDOOR_K1= 6
KP_CHAN_F2GRDOOR_K2= 5
KP_CHAN_F2GRBED_K1 = 7
KP_CHAN_F2GRBED_K2 = 8
KP_CHAN_F2MRBED_K1 = 6
KP_CHAN_F2MRBED_K2 = 5
KP_CHAN_F2MRBED_K3 = 4

KP_CHAN_F2MRDOOR_K1= 6
KP_CHAN_F2MRDOOR_K2= 5
KP_CHAN_F2HALL_K1  = 8
KP_CHAN_F2HALL_K2  = 7
KP_CHAN_F2HALL_K3  = 4

KP_CHAN_F3GRDOOR_K1= 8
KP_CHAN_F3GRDOOR_K2= 7
KP_CHAN_F3GRBED_K1 = 6
KP_CHAN_F3GRBED_K2 = 5
KP_CHAN_F3GRBED_K3 = 4

KP_CHAN_F3MRBED_K1 = 8
KP_CHAN_F3MRBED_K2 = 7
KP_CHAN_F3MRBED_K3 = 6
KP_CHAN_F3MRDOOR_K1= 5
KP_CHAN_F3MRDOOR_K2= 4

KP_CHAN_F0BAR_K1   = 6
KP_CHAN_F0BAR_K2   = 5
KP_CHAN_F0BAR_K3   = 4
KP_CHAN_F0TEA_K1   = 8
KP_CHAN_F0TEA_K2   = 7

BTN_GBL_SCENE_F1_1 = 1  // home
BTN_GBL_SCENE_F1_2 = 2  // leave
BTN_GBL_SCENE_F1_3 = 3  // visit
BTN_GBL_SCENE_F1_4 = 4  // guest
BTN_GBL_SCENE_F2_1 = 5  // visit
BTN_GBL_SCENE_F2_2 = 6  // leave
BTN_GBL_SCENE_F2_3 = 7  // visit
BTN_GBL_SCENE_F2_4 = 8  // leave
BTN_GBL_SCENE_F3_1 = 9  // visit
BTN_GBL_SCENE_F3_2 = 10  // leave
BTN_GBL_SCENE_F3_3 = 11  // leave
BTN_GBL_SCENE_F3_4 = 12  // leave

long TL_TP = 1 // the global timeline, used to sync the panel button state and so on
long gTLTPSpacing[1] = {250}

long TL_PJ = 2 // timeline id of projector status polling
(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE
(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile integer i
volatile dev gDvTps[TP_MAX_PANELS] = {dvTP1, dvTP2}
volatile integer gTpStatus[TP_MAX_PANELS]
volatile integer gBtnScene1Lock, gBtnScene4Lock
volatile integer lightSetExpState[MAX_LIGHTSET_NUMBER]

integer btnLightSet[MAX_LIGHTSET_NUMBER] = {
    CHAN_BTN_LIGHTSET_1,
    CHAN_BTN_LIGHTSET_2,
    CHAN_BTN_LIGHTSET_3,
    CHAN_BTN_LIGHTSET_4,
    CHAN_BTN_LIGHTSET_5,
    CHAN_BTN_LIGHTSET_6
}

// menu functions: 1 ~ 20
integer btnMenu[] = {
    2
}

// define the global senses
integer btnScene[] = {
    51,
    52,
    53,
    54,
    55,
    56,
    57,
    58
}

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
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)

//#include 'cmdQ.axi'   // be care of the timeline duplicate
#include 'amx_tp_api.axi'
#include 'debug.axi'
#include 'x_light.axi'
#include 'x_bgMusic.axi'
#include 'x_hvac.axi'

define_function handleTpOnlineEvent (integer tpId)
{
    debug('Main', 4, "'gDvTps ', itoa(tpId), 'online'")
    gTpStatus[tpId] = TP_STATUS_ON

    tp_hvacOnlineSync(tpId)
}

define_function handleTpOfflineEvent (integer tpId)
{
    debug('Main', 4, "'gDvTps ', itoa(tpId), 'offline'")
    gTpStatus[tpId] = TP_STATUS_OFF
}

define_function tps_updateTxt (integer address, char text[])
{
    integer tpId

    for (tpId = length_array(gDvTps); tpId >= 1; tpId--)
    {
        if (gTpStatus[tpId] == TP_STATUS_OFF)
            continue
        setButtonText(gDvTps[tpId], address, text)
    }    
}

define_function updateLevelValue (integer chan, integer value)
{
    integer tpId

    for (tpId = length_array(gDvTps); tpId >= 1; tpId--)
    {
        if (gTpStatus[tpId] == TP_STATUS_OFF)
            continue
        send_level gDvTps[tpId], chan, value
    }    
}

define_function tpArrayOn (integer chan)
{
    integer tpId

    for (tpId = length_array(gDvTps); tpId >= 1; tpId--)
    {
        if (gTpStatus[tpId] == TP_STATUS_OFF)
            continue
        ON[gDvTps[tpId], chan]
    }    
}

define_function tpArrayOff (integer chan)
{
    integer tpId

    for (tpId = length_array(gDvTps); tpId >= 1; tpId--)
    {
        if (gTpStatus[tpId] == TP_STATUS_OFF)
            continue
        OFF[gDvTps[tpId], chan]
    }    
}

define_function tpsLightBtnSync ()
{
    integer tpId

    for (tpId = length_array(gDvTps); tpId >= 1; tpId--)
    {
        debug('tpsLightBtnSync', 10, "'gTpStatus[', itoa(tpId), '] = ', itoa(gTpStatus[tpId])")
        if (gTpStatus[tpId] == TP_STATUS_OFF)
            continue
        tpLightBtnSync(tpId)
    }    
}

define_function tpArrayToogleState (integer chan)
{
    integer tpId

    for (tpId = length_array(gDvTps); tpId >= 1; tpId--)
    {
        if (gTpStatus[tpId] == TP_STATUS_OFF)
            continue
        [gDvTps[tpId], chan] = ![gDvTps[tpId], chan]
    }    
}

// 
define_function lightSetTpCmd(dev dvTp, integer setId)
{
    char cmd[8]
    integer i, ps // position start

    if (lightSetExpState[setId] == true)
        cmd = '^SHD'
    else
        cmd = '^SSH'

    ps = 1
    for (i = 1; i < setId; i++)
    {
        if (lightSetExpState[i])
            ps = ps + ITEMS_PER_SET + 1
        else
            ps = ps + 1
    }

    for (i = ITEMS_PER_SET; i > 0; i--)
    {
        send_command dvTp, 
            "cmd, '-',itoa(ADDRCODE_SPVIEW),
            ',[light]btn', itoa(setId),'-',itoa(i), ',', itoa(ps)"
    }
}
(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START
{
    integer i

    for (i = length_array(lightSetExpState); i > 0; i--)
        lightSetExpState[i] = true

    TIMELINE_CREATE(TL_TP, gTLTPSpacing, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT)
}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

DATA_EVENT[gDvTps]
{
    ONLINE:  { handleTpOnlineEvent(get_last(gDvTps)) }
    OFFLINE: { handleTpOfflineEvent(get_last(gDvTps)) }
}

// keypad near the F1 stairs
BUTTON_EVENT[dvIOKP1, 0]
{
    PUSH:
    {
        switch(button.input.channel)
        {
            case KP_CHAN_F1STAIRS_K1:    // same as backhome
            {
                light_sceneBackHome()
            }
            case KP_CHAN_F1STAIRS_K2:    // leave F1, close all F1 lights
            {
                fnOff(vdvAMXLight, 31, 4)
                fnOff(vdvAMXLight, 31, 5)
                fnOff(vdvAMXLight, 30, 6)
                fnOff(vdvAMXLight, 31, 6)
                fnOff(vdvAMXLight, 31, 7)
                fnOff(vdvAMXLight, 31, 8)
                fnOff(vdvAMXLight, 30, 7)
                fnOff(vdvAMXLight, 30, 8)
                fnOff(vdvAMXLight, 31, 1)
            }                 
        }
    }           
}

// keypad beside the F1 door
BUTTON_EVENT[dvIOKP2, 0]
{
    PUSH:
    {
        switch(button.input.channel)
        {
            case KP_CHAN_F1DOOR_K1:    // back home
            {
                light_sceneBackHome()
                bgm_start()
            }
            case KP_CHAN_F1DOOR_K2:    // leave home
            {
                light_sceneLeaveHome()
                bgm_stop()
                curtain_F3MROpen()
                curtain_F2MROpen()
            }
            case KP_CHAN_F1DINNER_K1:  // start dinner
            {
                fnOn(vdvAMXLight, 30, 6)
                fnOn(vdvAMXLight, 31, 6)
                fnOn(vdvAMXLight, 31, 7)
                fnOn(vdvAMXLight, 31, 8)
            }
            case KP_CHAN_F1DINNER_K2:  // stop dinner
            {
                fnOff(vdvAMXLight, 31, 6)
                fnOff(vdvAMXLight, 31, 8)
            }
            case KP_CHAN_F1HALL_K1:    // all open
            {
                fnOn(vdvAMXLight, 30, 7)
                fnOn(vdvAMXLight, 30, 8)
                fnOn(vdvAMXLight, 31, 1)
            }
            case KP_CHAN_F1HALL_K2:    // only master light
            {
                light_toggle(30, 7)
            }
            case KP_CHAN_F1HALL_K3:    // guest visit
            {
                fnOn(vdvAMXLight, 30, 7)
                fnOn(vdvAMXLight, 30, 8)
                fnOn(vdvAMXLight, 31, 1)                
            }                      
        }
    }           
}

BUTTON_EVENT[dvIOKP3, 0]
{
    PUSH:
    {
        switch(button.input.channel)
        {
            case KP_CHAN_F2GRDOOR_K1:   // living
            {
                fnOn(vdvAMXLight, 32, 1)
                fnOn(vdvAMXLight, 34, 7)
                fnOn(vdvAMXLight, 34, 8)
            }
            case KP_CHAN_F2GRDOOR_K2:   // leave
            {
                fnOff(vdvAMXLight, 32, 1)
                fnOff(vdvAMXLight, 34, 7)
                fnOff(vdvAMXLight, 34, 8)
            }
            case KP_CHAN_F2GRBED_K1:    // sleep
            {
                fnOff(vdvAMXLight, 32, 1)
                fnOff(vdvAMXLight, 34, 7)
                fnOff(vdvAMXLight, 34, 8)

                //bgm_stop()        
            }
            case KP_CHAN_F2GRBED_K2:    // bathroom
            {
                fnOn(vdvAMXLight, 34, 8)     
            }
        }
    }           
}

BUTTON_EVENT[dvIOKP4, 0]
{
    PUSH:
    {
        switch(button.input.channel)
        {
            case KP_CHAN_F2MRBED_K1:    // sleep
            {
                fnOff(vdvAMXLight, 34, 6)
                fnOff(vdvAMXLight, 34, 1)
                fnOff(vdvAMXLight, 34, 2)
                fnOff(vdvAMXLight, 34, 3)
                fnOff(vdvAMXLight, 34, 4)
                fnOff(vdvAMXLight, 34, 5)

                curtain_F2MRClose()
                //bgm_stop()
            }
            case KP_CHAN_F2MRBED_K2:    // awake
            {
                fnOn(vdvAMXLight, 34, 2)

                curtain_shadeF2MROpen()
                //bgm_start()
            }
            case KP_CHAN_F2MRBED_K3:
            {
                fnOn(vdvAMXLight, 34, 1)
            }            
        }
    }           
}

BUTTON_EVENT[dvIOKP5, 0]
{
    PUSH:
    {
        switch(button.input.channel)
        {
            case KP_CHAN_F2MRDOOR_K1:   // living
            {
                fnOn(vdvAMXLight, 34, 3)
                fnOn(vdvAMXLight, 34, 4)
                fnOn(vdvAMXLight, 34, 5)
            }
            case KP_CHAN_F2MRDOOR_K2:   // leave
            {
                fnOff(vdvAMXLight, 34, 1)
                fnOff(vdvAMXLight, 34, 2)
                fnOff(vdvAMXLight, 34, 3)
                fnOff(vdvAMXLight, 34, 4)
                fnOff(vdvAMXLight, 34, 5)
                fnOff(vdvAMXLight, 34, 6)

                curtain_F2MROpen()
            }
            case KP_CHAN_F2HALL_K1:
            {
                light_toggle(32, 4)
            }
            case KP_CHAN_F2HALL_K2:
            {
                light_toggle(32, 3)
            }
            case KP_CHAN_F2HALL_K3:
            {
                light_toggle(32, 2)  
            }            
        }
    }           
}

BUTTON_EVENT[dvIOKP6, 0]
{
    PUSH:
    {
        switch(button.input.channel)
        {
            case KP_CHAN_F3GRDOOR_K1:   // living
            {
                fnOn(vdvAMXLight, 35, 1)
                fnOn(vdvAMXLight, 35, 3)
            }
            case KP_CHAN_F3GRDOOR_K2:   // leave
            {
                fnOff(vdvAMXLight, 35, 1)
                fnOff(vdvAMXLight, 35, 2)
                fnOff(vdvAMXLight, 35, 3)
                fnOff(vdvAMXLight, 35, 4)
            }
            case KP_CHAN_F3GRBED_K1:    // sleep
            {
                fnOff(vdvAMXLight, 35, 1)
                fnOff(vdvAMXLight, 35, 2)
                fnOff(vdvAMXLight, 35, 3)
                fnOff(vdvAMXLight, 35, 4)
                //bgm_stop()        
            }
            case KP_CHAN_F3GRBED_K2:    // awake
            {
                light_toggle(35, 2)
            }
            case KP_CHAN_F3GRBED_K3:    // bathroom
            {
                light_toggle(35, 4)  
            }            
        }
    }           
}

BUTTON_EVENT[dvIOKP7, 0]
{
    PUSH:
    {
        switch(button.input.channel)
        {
            case KP_CHAN_F3MRDOOR_K1:   // living
            {
                fnOn(vdvAMXLight, 33, 2)
                fnOn(vdvAMXLight, 35, 5)
                fnOn(vdvAMXLight, 35, 8)
            }
            case KP_CHAN_F3MRDOOR_K2:   // leave
            {
                fnOff(vdvAMXLight, 33, 1)
                fnOff(vdvAMXLight, 33, 2)
                fnOff(vdvAMXLight, 35, 5)
                fnOff(vdvAMXLight, 35, 6)
                fnOff(vdvAMXLight, 35, 7)
                fnOff(vdvAMXLight, 35, 8)

                curtain_F3MROpen()
            }
            case KP_CHAN_F3MRBED_K1:    // sleep
            {
                fnOff(vdvAMXLight, 33, 1)
                fnOff(vdvAMXLight, 33, 2)
                fnOff(vdvAMXLight, 35, 5)
                fnOff(vdvAMXLight, 35, 6)
                fnOff(vdvAMXLight, 35, 7)
                fnOff(vdvAMXLight, 35, 8)

                curtain_F3MRClose()
                //bgm_stop()        
            }
            case KP_CHAN_F3MRBED_K2:    // awake
            {
                fnOn(vdvAMXLight, 35, 6)
                curtain_shadeF2MROpen()
            }
            case KP_CHAN_F3MRBED_K3:    // bathroom
            {
                light_toggle(33, 1)  
            }            
        }
    }           
}

// floor 0
BUTTON_EVENT[dvIOKP8, 0]
{
    PUSH:
    {
        switch(button.input.channel)
        {
            case KP_CHAN_F0BAR_K1:
            {
                light_dimToggle(40, 1)
            }
            case KP_CHAN_F0BAR_K2:
            {
                light_dimToggle(40, 2)
            }
            case KP_CHAN_F0BAR_K3:
            {
                light_dimToggle(40, 3)
            }    
            case KP_CHAN_F0TEA_K1:
            {
                light_dimToggle(40, 4)
            }   
            case KP_CHAN_F0TEA_K2:
            {
                light_dimToggle(40, 4)
            }                           
        }
    }           
}

// control the light set expand or not
BUTTON_EVENT[gDvTps, btnLightSet]
{
    PUSH:
    {
        integer tpId, setId

        tpId = get_last(gDvTps)        
        setId = get_last(btnLightSet)

        lightSetTpCmd(gDvTps[tpId], setId)
        lightSetExpState[setId] = !lightSetExpState[setId]
    }
}

BUTTON_EVENT[gDvTps, btnMenu]
{
    PUSH:
    {
        switch(button.input.channel)
        {
            case 0:
            {
                break
            }
        }
    }
}

BUTTON_EVENT[gDvTps, btnScene]
{
    PUSH:
    {
        integer idxBtn, i
        local_var integer tpId

        tpId   = get_last(gDvTps)
        idxBtn = get_last(btnScene)
        switch(idxBtn)
        {
            case BTN_GBL_SCENE_F1_1:    // back home
            {
                light_sceneBackHome()
                bgm_start()
            }
            case BTN_GBL_SCENE_F1_2:    // leave home
            {
                light_sceneLeaveHome()
                bgm_stop()
                curtain_F3MROpen()
                curtain_F2MROpen()                
            }
            case BTN_GBL_SCENE_F1_3:    // browse
            {
                light_sceneAllAct(1)
                bgm_start()
            }
            case BTN_GBL_SCENE_F1_4:    // guest visit
            {
                fnOn(vdvAMXLight, 30, 7)
                fnOn(vdvAMXLight, 30, 8)
                fnOn(vdvAMXLight, 31, 1)  
            }
            case BTN_GBL_SCENE_F2_1:
            {
                break
            }
            case BTN_GBL_SCENE_F2_2:
            {
                break
            }     
        }
    }
}

TIMELINE_EVENT[TL_TP]
{
    tpsLightBtnSync()
    tp_hvacBtnSync()
}

(*****************************************************************)
(*                                                               *)
(*                      !!!! WARNING !!!!                        *)
(*                                                               *)
(* Due to differences in the underlying architecture of the      *)
(* X-Series masters, changing variables in the DEFINE_PROGRAM    *)
(* section of code can negatively impact program performance.    *)
(*                                                               *)
(* See Differences in DEFINE_PROGRAM Program Execution” section *)
(* of the NX-Series Controllers WebConsole & Programming Guide   *)
(* for additional and alternate coding methodologies.            *)
(*****************************************************************)

DEFINE_PROGRAM

(*****************************************************************)
(*                       END OF PROGRAM                          *)
(*                                                               *)
(*         !!!  DO NOT PUT ANY CODE BELOW THIS COMMENT  !!!      *)
(*                                                               *)
(*****************************************************************)


