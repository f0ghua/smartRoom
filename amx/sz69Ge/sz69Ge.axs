PROGRAM_NAME='sz69Ge'
(***********************************************************)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 04/05/2006  AT: 09:00:25        *)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)
(*
    $History: $
    
    The Suzhou 69 Ge project use NX3200 with severl modules
    
        - AVB-ABS [serial]
        - AVB-DIN-REL8-50(strong electrical controller)
        - AVB-AO8-0-10(dimmer controller)
        - dvd oppo BDP-103 [serial rs232]
        - preamplifiers Onkyo PR-SC5530 [serial rs232]
        - projector JVC DLA-XC3800 [serial rs232]
    
    2 AVB-DIN-REL8-50 and 1 AVB-AO8-0-10 connect to AVB-ABS  and then linked
    to NX3200's serial port.

*)
(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

dvTerminal  = 0:1:1

//vdvTP       = 10001:1:0
/*
vdvTP       = 33000:1:0 // virtual device to combine all TPs
*/
dvTP1       = 10001:1:0 // ipad 1024x768
dvTP2       = 10002:1:0 // iphone 640x960

// MET-6N keypad, the order is left,right,top,bottom, 1~6 are buttons, 
// 7~11 are cycle buttons, 12 rotate left, 13 rotate right
dvKeypad    = 85:1:0

dvAmxLight  = 5001:2:0
vdvAmxLight = 34101:1:0 // the number should sync with 'LightAxi.axi'

// MiYue is used as backgroud music device
dvMiYue     = 0:31:0
vdvMiYue    = 33100:1:0

dvGF        = 5001:3:0
vdGF        = 33103:1:0

dvPJ        = 5001:4:0      // projector

dvDVD       = 5001:6:0

dvRL        = 5001:21:0     // relay

DEFINE_COMBINE

//Combine devices doesn't work so well when a device in the combine goes
//offline or takes a long time to come online. It's really an old Axess
//command carried over for compatibility.

//(vdvTP, dvTP1, dvTP2)

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

TP_MAX_PANELS       = 4
TP_STATUS_OFF       = 0
TP_STATUS_ON        = 1

POWER_MAN_ON        = 1
POWER_MAN_OFF       = 0
(*
    MET-6N is a 13 key keypad defined as following, 12 is rotate 
    clockwise, and 13 is rotate counter-clockwise
    
      +------+   +------+
      |   1  |   |   2  |
      +------+   +------+
      +------+   +------+
      |   3  |   |   4  |
      +------+   +------+
      +------+   +------+
      |   5  |   |   6  |
      +------+   +------+
           ---------
     13 --/    7    \-- 12
      -/               \-
     /                   \
     |9        11      10|
     \                   /
      -\               /-
        --\    8    /--
           ---------
*)
KP_PRINTEDPB_1      = 1     // pre-printed push button 1
KP_PRINTEDPB_2      = 2
KP_PRINTEDPB_3      = 3
KP_PRINTEDPB_4      = 4
KP_PRINTEDPB_5      = 5
KP_PRINTEDPB_6      = 6
KP_DIRPB_UP         = 7     // directional push button UP
KP_DIRPB_DOWN       = 8     // directional push button DOWN
KP_DIRPB_LEFT       = 9     // directional push button LEFT
KP_DIRPB_RIGHT      = 10    // directional push button RIGHT
KP_DIRPB_CENTER     = 11    // directional push button CENTER
KP_DIRPB_RCLK       = 12    // rotate clockwise
KP_DIRPB_RCCLK      = 13    // rotate counter-clockwise
KB_MAX_RCCLKVAL     = 255

CHCODE_NAV_BGMUSIC  = 4     // chanel code for backgroud music button on nav bar

BTN_GBL_SCENE_1   = 1
BTN_GBL_SCENE_2   = 2
BTN_GBL_SCENE_3   = 3
BTN_GBL_SCENE_4   = 4
BTN_GBL_SCENE_5   = 5
BTN_GBL_SCENE_6   = 6

DEV advBaud9600[] = {dvAmxLight, dvDVD, dvGF}
DEV advBaud19200[] = {dvPJ}

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

volatile dev gDvTps[TP_MAX_PANELS] = {dvTP1, dvTP2}
volatile integer gTpStatus[TP_MAX_PANELS]

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
    56
}

integer btnKeypad[] = {
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
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
#include 'debug.axi'
#include 'ge69_light.axi'
#include 'ge69_bgMusic.axi'
#include 'ge69_dvd.axi'
#include 'ge69_projector.axi'
#include 'ge69_gf.axi'

DEFINE_FUNCTION handleTpOnlineEvent (integer tpId)
{
    debug('Main', 4, "'gDvTps ', itoa(tpId), 'online'")
    gTpStatus[tpId] = TP_STATUS_ON
}

DEFINE_FUNCTION handleTpOfflineEvent (integer tpId)
{
    debug('Main', 4, "'gDvTps ', itoa(tpId), 'offline'")
    gTpStatus[tpId] = TP_STATUS_OFF
}

DEFINE_FUNCTION updateLevelValue (integer chan, integer value)
{
    integer tpId

    for (tpId = length_array(gDvTps); tpId >= 1; tpId--)
    {
        if (gTpStatus[tpId] == TP_STATUS_OFF)
            continue
        send_level gDvTps[tpId], chan, value
    }    
}

DEFINE_FUNCTION tpArrayOn (integer chan)
{
    integer tpId

    for (tpId = length_array(gDvTps); tpId >= 1; tpId--)
    {
        if (gTpStatus[tpId] == TP_STATUS_OFF)
            continue
        ON[gDvTps[tpId], chan]
    }    
}

DEFINE_FUNCTION tpArrayOff (integer chan)
{
    integer tpId

    for (tpId = length_array(gDvTps); tpId >= 1; tpId--)
    {
        if (gTpStatus[tpId] == TP_STATUS_OFF)
            continue
        OFF[gDvTps[tpId], chan]
    }    
}

DEFINE_FUNCTION tpsLightBtnSync ()
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

DEFINE_FUNCTION tpArrayToogleState (integer chan)
{
    integer tpId

    for (tpId = length_array(gDvTps); tpId >= 1; tpId--)
    {
        if (gTpStatus[tpId] == TP_STATUS_OFF)
            continue
        [gDvTps[tpId], chan] = ![gDvTps[tpId], chan]
    }    
}

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

TIMELINE_CREATE(TL_TP, gTLTPSpacing, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT)

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

DATA_EVENT[gDvTps]
{
    ONLINE:  { handleTpOnlineEvent(get_last(gDvTps)) }
    OFFLINE: { handleTpOfflineEvent(get_last(gDvTps)) }
}

BUTTON_EVENT[gDvTps, btnMenu]
{
    PUSH:
    {
        switch(BUTTON.INPUT.CHANNEL)
        {
            case CHCODE_NAV_BGMUSIC:
            {
                // connect to MIYUE
                //miyueIpOpen()
                break
            }
        }
    }
}

// When rotate, the level event occur at channel 2, value from 0~255
LEVEL_EVENT[dvKeypad, 2]
{
    gblMYLevelValue[1] = MAX_MYLEVEL_VALUE*(LEVEL.VALUE)/KB_MAX_RCCLKVAL

    debug('Main', 4, "'KEYPAD LEVEL: rotateVal = ', itoa(gblMYLevelValue[1])")
}

BUTTON_EVENT[dvKeypad, btnKeypad]
{
    PUSH:
    {
        integer idxKey
        
        idxKey = GET_LAST(btnKeypad)
        TO[dvKeypad, idxKey]
        
        switch (idxKey)
        {
            case KP_PRINTEDPB_1:
            case KP_PRINTEDPB_2:
            case KP_PRINTEDPB_3:
            case KP_PRINTEDPB_4:
            case KP_PRINTEDPB_5:
                tpLightSceneOn(BTN_LIGHT_SCENE_1)
            case KP_PRINTEDPB_6:
                toggleAlights(LIGHT_OFF)
            case KP_DIRPB_UP:
                bgMuicCommand(MIYUE_CMD_PREV)
                break
            case KP_DIRPB_DOWN:
                bgMuicCommand(MIYUE_CMD_NEXT)
                break
            case KP_DIRPB_LEFT:
                bgMuicCommand(MIYUE_CMD_PREV)
                break
            case KP_DIRPB_RIGHT:
                bgMuicCommand(MIYUE_CMD_NEXT)
                break
            case KP_DIRPB_CENTER:
                bgMuicCommand(MIYUE_CMD_TOGPL)
                break
         }
    }
    RELEASE:
    {
        integer idxKey
        
        idxKey = GET_LAST(btnKeypad)
        switch (idxKey)
        {        
            case KP_DIRPB_RCLK:
                setBgMusicVol(gblMYLevelValue[1])
                updateLevelValue(btnMYLevel[1], gblMYLevelValue[1])
            case KP_DIRPB_RCCLK:
                setBgMusicVol(gblMYLevelValue[1])
                updateLevelValue(btnMYLevel[1], gblMYLevelValue[1])    
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
            case BTN_GBL_SCENE_1:
            {
                // cinema start
                // 1. light M2L7: on
                // 2. light M2L4: wait 3s, off
                // 3. light M2L1: after step 2 done, wait 5s, off
                // 4. light dimmer: when step 2 done, dim to 50%;
                
                projector_opPowerOn()
                //wait 10 send_string dvPJ, "'!', $89, $01, 'PW1', $0A" // resent to make sure device got the serial

                fnLightOn(BTN_LIGHT_M2L7)
                fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 30, 3)

                wait 30 'GBL_SCENE_1_W1'
                {
                    do_push(gDvTps[tpId], btnDVD[BTN_DVD_POWERON])
                    wait 10 send_string dvDVD, "'PON', $0D"

                    fnLightOff(BTN_LIGHT_M2L4)
                    fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 20, 5)

                    wait 50 'GBL_SCENE_1_W2'
                    {
                        do_push(gDvTps[tpId], btnGF[BTN_GF_POWERON])

                        fnLightOff(BTN_LIGHT_M2L1)
                        fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 10, 5)

                        wait 180 'GBL_SCENE_1_W3'
                        {
                            fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 0, 5)
                            wait 50
                            {
                                // sync the dimmer level
                                updateLevelValue(btnDimLevel[1], 0)
                            }
                        }
                    }
                }
            }
            case BTN_GBL_SCENE_2:
            {
                // sing a song
                // 1. light M2L7: on
                // 2. light M2L1: on
                // 3. light M2L4: wait 3s, off
                // 4. dimmer: 10%
                fnLightOn(BTN_LIGHT_M2L7)
                fnLightOn(BTN_LIGHT_M2L1)
                fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 10, 3)
                wait 30
                {
                    fnLightOff(BTN_LIGHT_M2L4)
                    updateLevelValue(btnDimLevel[1], 10)
                }
            }
            case BTN_GBL_SCENE_3:
            case BTN_GBL_SCENE_5:
            {
                // 
                // 1. light M2L7: on
                // 2. light M2L1: on
                // 3. light M2L4: on
                // 4. dimmer: 90%
                fnLightOn(BTN_LIGHT_M2L7)
                fnLightOn(BTN_LIGHT_M2L1)
                fnLightOn(BTN_LIGHT_M2L4)
                fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 90, 0)
                updateLevelValue(btnDimLevel[1], 90)
            }
            case BTN_GBL_SCENE_4:
            {
                // 
                // 1. light M2L7: on
                // 2. light M2L1: on
                // 3. light M2L4: on
                // 4. dimmer: 90%
                fnLightOn(BTN_LIGHT_M2L7)
                fnLightOn(BTN_LIGHT_M2L1)
                fnLightOn(BTN_LIGHT_M2L4)

                fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 90, 0)
                updateLevelValue(btnDimLevel[1], 90)

                do_push(gDvTps[tpId], btnGF[BTN_GF_POWEROFF])
                dvdPowerOff(tpId)
                projector_opPowerOff()
                /*
                wait 10
                {
                    send_string dvDVD, "'POF', $0D"
                    send_string dvPJ, "'!', $89, $01, 'PW0', $0A"
                }
                */               
            }
            case BTN_GBL_SCENE_6:
            {
                // off all cinema lights
                fnLightOff(BTN_LIGHT_M2L7)
                fnLightOff(BTN_LIGHT_M2L1)
                fnLightOff(BTN_LIGHT_M2L4)

                fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 0, 0)
                updateLevelValue(btnDimLevel[1], 0)                
            }          
        }
    }
}

DATA_EVENT[advBaud9600]
{
    ONLINE:
    {
        send_command DATA.DEVICE, 'SET MODE DATA'
        send_command DATA.DEVICE, 'SET BAUD 9600,N,8,1,485 DISABLE'
    }
}

TIMELINE_EVENT[TL_TP]
{
    tpsLightBtnSync()
    tpPJBtnSync()
    tpDVDBtnSync()
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


