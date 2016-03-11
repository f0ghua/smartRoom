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
    
        - AVB-ABS
        - AVB-DIN-REL8-50(strong electrical controller)
        - AVB-AO8-0-10(dimmer controller)
    
    2 AVB-DIN-REL8-50 and 1 AVB-AO8-0-10 connect to AVB-ABS  and then linked
    to NX3200's serial port.

*)
(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

dvTerminal  = 0:1:1

vdvTP       = 10001:1:0
/*
vdvTP       = 33000:1:0 // virtual device to combine all TPs
dvTP1       = 10001:1:0 // ipad 1024x768
dvTP2       = 10002:1:0 // iphone 640x960
*/
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

CHCODE_NAV_BGMUSIC  = 2     // chanel code for backgroud music button on nav bar

BTN_GBL_SCENE_1   = 1
BTN_GBL_SCENE_2   = 2
BTN_GBL_SCENE_3   = 3
BTN_GBL_SCENE_4   = 4
BTN_GBL_SCENE_5   = 5

DEV advBaud9600[] = {dvAmxLight, dvDVD, dvGF}
DEV advBaud19200[] = {dvPJ}

long TL_SCENE1_DIMMER = 1
long gTLSceneDimmer[16] = {
    0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 
    10000, 11000, 12000, 13000, 14000, 15000
}

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE
(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

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

#include 'ge69_light.axi'
#include 'ge69_bgMusic.axi'
#include 'ge69_dvd.axi'
#include 'ge69_projector.axi'
#include 'ge69_gf.axi'
(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

BUTTON_EVENT[vdvTP, btnMenu]
{
    PUSH:
    {
        switch(BUTTON.INPUT.CHANNEL)
        {
            case CHCODE_NAV_BGMUSIC:
            {
                // connect to MIYUE
                miyueIpOpen()
            }
        }
    }
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
                DO_PUSH(vdvTP, btnLightScene[BTN_LIGHT_ALL_ON])
            case KP_PRINTEDPB_6:
                DO_PUSH(vdvTP, btnLightScene[BTN_LIGHT_ALL_OFF])
            case KP_DIRPB_UP:
                DO_PUSH(vdvTP, btnMiYue[MIYUE_CMD_PREV])
            case KP_DIRPB_DOWN:
                DO_PUSH(vdvTP, btnMiYue[MIYUE_CMD_NEXT])
            case KP_DIRPB_LEFT:
                DO_PUSH(vdvTP, btnMiYue[MIYUE_CMD_VOLDOWN])
            case KP_DIRPB_RIGHT:
                DO_PUSH(vdvTP, btnMiYue[MIYUE_CMD_VOLUP])
            case KP_DIRPB_CENTER:
                DO_PUSH(vdvTP, btnMiYue[MIYUE_CMD_TOGPL])
            case KP_DIRPB_RCLK:
                DO_PUSH(vdvTP, btnMiYue[MIYUE_CMD_VOLUP])
            case KP_DIRPB_RCCLK:
                DO_PUSH(vdvTP, btnMiYue[MIYUE_CMD_VOLDOWN])
         }
    }
}

BUTTON_EVENT[vdvTP, btnScene]
{
    PUSH:
    {
        integer idxBtn, i
    
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
                
                // power the project
                // !$89$01PW1$0A
                
                do_push(vdvTP, btnProjector[BTN_PJ_POWERON])
                wait 10 send_string dvPJ, "'!', $89, $01, 'PW1', $0A" // resent to make sure device got the serial
                if ([vdvTP, btnLight[BTN_LIGHT_M2L7]] == 0)
                    do_push(vdvTP, btnLight[BTN_LIGHT_M2L7])

                fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 30, 3)
                wait 30 'GBL_SCENE_1_W1'
                {
                    do_push(vdvTP, btnDVD[BTN_DVD_POWERON])
                    wait 10 send_string dvDVD, "'PON', $0D"
                    if ([vdvTP, btnLight[BTN_LIGHT_M2L4]] != 0)
                        do_push(vdvTP, btnLight[BTN_LIGHT_M2L4])
                    fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 20, 5)
                    wait 50 'GBL_SCENE_1_W2'
                    {
                        do_push(vdvTP, btnGF[BTN_GF_POWERON])
                        if ([vdvTP, btnLight[BTN_LIGHT_M2L1]] != 0)
                            do_push(vdvTP, btnLight[BTN_LIGHT_M2L1])
                        fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 10, 5)
                        wait 50 'GBL_SCENE_1_W3'
                        {
                            fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 0, 5)
                            wait 50
                            {
                                // sync the dimmer level
                                send_level vdvTP, btnDimLevel[1], 0
                            }
                        }
                    }
                }
/*
                if ([vdvTP, BUTTON.INPUT.CHANNEL] == 0)
                {
 
                    if (timeline_active(TL_SCENE1_DIMMER))
                        timeline_restart(TL_SCENE1_DIMMER)
                    else
                    {
                        timeline_create(TL_SCENE1_DIMMER, gTLSceneDimmer, 1, 
                            TIMELINE_ABSOLUTE, TIMELINE_ONCE)
                    }
                }
*/
            }
            case BTN_GBL_SCENE_2:
            {
                // sing a song
                // 1. light M2L7: on
                // 2. light M2L1: on
                // 3. light M2L4: wait 3s, off
                // 4. dimmer: 10%
                if ([vdvTP, btnLight[BTN_LIGHT_M2L7]] == 0)
                    do_push(vdvTP, btnLight[BTN_LIGHT_M2L7])
                if ([vdvTP, btnLight[BTN_LIGHT_M2L1]] == 0)
                    do_push(vdvTP, btnLight[BTN_LIGHT_M2L4])

                fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 10, 3)
                wait 30
                {
                    if ([vdvTP, btnLight[BTN_LIGHT_M2L4]] != 0)
                        do_push(vdvTP, btnLight[BTN_LIGHT_M2L4])
                    send_level vdvTP, btnDimLevel[1], 10
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
                if ([vdvTP, btnLight[BTN_LIGHT_M2L7]] == 0)
                    do_push(vdvTP, btnLight[BTN_LIGHT_M2L7])
                if ([vdvTP, btnLight[BTN_LIGHT_M2L1]] == 0)
                    do_push(vdvTP, btnLight[BTN_LIGHT_M2L1])
                if ([vdvTP, btnLight[BTN_LIGHT_M2L4]] == 0)
                    do_push(vdvTP, btnLight[BTN_LIGHT_M2L4])
                fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 90, 0)
                send_level vdvTP, btnDimLevel[1], 90
            }
            case BTN_GBL_SCENE_4:
            {
                // 
                // 1. light M2L7: on
                // 2. light M2L1: on
                // 3. light M2L4: on
                // 4. dimmer: 90%
                if ([vdvTP, btnLight[BTN_LIGHT_M2L7]] == 0)
                    do_push(vdvTP, btnLight[BTN_LIGHT_M2L7])
                if ([vdvTP, btnLight[BTN_LIGHT_M2L1]] == 0)
                    do_push(vdvTP, btnLight[BTN_LIGHT_M2L1])
                if ([vdvTP, btnLight[BTN_LIGHT_M2L4]] == 0)
                    do_push(vdvTP, btnLight[BTN_LIGHT_M2L4])
                fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 90, 0)
                send_level vdvTP, btnDimLevel[1], 90

                do_push(vdvTP, btnGF[BTN_GF_POWEROFF])
                dvdPowerOff()
                do_push(vdvTP, btnProjector[BTN_PJ_POWEROFF])
                wait 10
                {
                    send_string dvDVD, "'POF', $0D"
                    send_string dvPJ, "'!', $89, $01, 'PW0', $0A"
                }                

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

DATA_EVENT[advBaud19200]
{
    ONLINE:
    {
        send_command DATA.DEVICE, 'SET MODE DATA'
        send_command DATA.DEVICE, 'SET BAUD 19200,N,8,1,485 DISABLE'
    }
}

TIMELINE_EVENT[TL_SCENE1_DIMMER]
{
    integer lv, lvStep;

    lv= 100 // max of the dim level value
    lvStep = 5

    switch(TIMELINE.SEQUENCE)
    {
        case 5:
        {
            lv = 50
            fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, lv, 0)
            // we also need change the level on TP
        }
        case 10:
        {
            if (lv > lvStep) lv = lv - lvStep
            //fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, lv, 0)
        }
        case 15:
        {
            //fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 0, 0)
        }
    }
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


