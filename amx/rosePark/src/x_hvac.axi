PROGRAM_NAME='x_hvac'

// 1-04 is the main slave control, it will control the mode of other slaves.
// Other slaves can only adjust the temp

DEFINE_DEVICE

dvHvac          = 5001:8:0
vdvHvac         = 33001:1:0 

DEFINE_CONSTANT

BTN_ADDR_HVAC_TEMP      = 1

BTN_HVAC_QUERY          = 1
BTN_HVAC_LINKSTATE      = 2
BTN_HVAC_COMMSTATE      = 3
BTN_HVAC_SETADDRANGE    = 4

BTN_HVAC_SLAVEMAIN_PON  = 6
BTN_HVAC_SLAVEMAIN_POFF = 7

BTN_HVAC_F1HALL_LLOFF   = 11
BTN_HVAC_F1HALL_LLON    = 12
BTN_HVAC_F1HALL_LOFF    = 13
BTN_HVAC_F1HALL_LON     = 14
BTN_HVAC_F1HALL_MOFF    = 15
BTN_HVAC_F1HALL_MON     = 16
BTN_HVAC_F1HALL_HOFF    = 17
BTN_HVAC_F1HALL_HON     = 18
BTN_HVAC_F1HALL_HHOFF   = 19
BTN_HVAC_F1HALL_HHON    = 20
BTN_HVAC_F1HALL_MODE_SWING  = 21
BTN_HVAC_F1HALL_MODE_HEAT   = 22
BTN_HVAC_F1HALL_MODE_COOL   = 23
BTN_HVAC_F1HALL_MODE_AUTO   = 24 
BTN_HVAC_F1HALL_MODE_STEP   = 25 
BTN_HVAC_F1HALL_MODE_DRY    = 26
BTN_HVAC_F1HALL_TEMP_UP     = 27
BTN_HVAC_F1HALL_TEMP_DOWN   = 28

BTN_HVAC_F1DINN_LLOFF   = 19
BTN_HVAC_F1DINN_LLON    = 20
BTN_HVAC_F1DINN_LOFF    = 11
BTN_HVAC_F1DINN_LON     = 12
BTN_HVAC_F1DINN_MOFF    = 13
BTN_HVAC_F1DINN_MON     = 14
BTN_HVAC_F1DINN_HOFF    = 15
BTN_HVAC_F1DINN_HON     = 16
BTN_HVAC_F1DINN_HHOFF   = 17
BTN_HVAC_F1DINN_HHON    = 18

HVAC_ZONE_F0_1          = 1     // 1-00, 1-01
HVAC_ZONE_F0_2          = 2     // 1-02
HVAC_ZONE_F0_3          = 3     // 1-03
HVAC_ZONE_F1_1          = 4     // HALL: 1-04, 1-05
HVAC_ZONE_F1_2          = 5     // DINNER: 1-06, 1-07
HVAC_ZONE_F2_1          = 6     // 1-08
HVAC_ZONE_F2_2          = 7     // 1-09
HVAC_ZONE_F2_3          = 8     // 1-10
HVAC_ZONE_F3_1          = 9     // 1-11
HVAC_ZONE_F3_2          = 10    // 1-12, 1-13, 1-14
HVAC_ZONE_F4_1          = 11    // 1-15, 2-00

HVAC_SLAVE_F0_1          = 1
HVAC_SLAVE_F0_2          = 2
HVAC_SLAVE_F0_3          = 3
HVAC_SLAVE_F0_4          = 4
HVAC_SLAVE_F1_1          = 5
HVAC_SLAVE_F1_2          = 6
HVAC_SLAVE_F1_3          = 7
HVAC_SLAVE_F1_4          = 8
HVAC_SLAVE_F2_1          = 9
HVAC_SLAVE_F2_2          = 10
HVAC_SLAVE_F2_3          = 11
HVAC_SLAVE_F3_1          = 12
HVAC_SLAVE_F3_2          = 13
HVAC_SLAVE_F3_3          = 14
HVAC_SLAVE_F3_4          = 15
HVAC_SLAVE_F4_1          = 16
HVAC_SLAVE_F4_2          = 17

HVAC_MAX_SLAVES          = 17

// all slaves set heat and cold mode according to the slave main
HVAC_SLAVE_MAIN          = HVAC_SLAVE_F1_1

HVAC_KEY_MODE           = 2

// read
DAIKIN_REGADDR_TEMP     = $07D2

// write 
DAIKIN_REGADDR_FAN      = $07D0
DAIKIN_REGADDR_MODE     = $07D1

DAIKIN_VFAN_POFF        = $0060
DAIKIN_VFAN_PON         = $0061
DAIKIN_VFAN_LLOFF       = $1060
DAIKIN_VFAN_LLON        = $1061
DAIKIN_VFAN_LOFF        = $2060
DAIKIN_VFAN_LON         = $2061
DAIKIN_VFAN_MOFF        = $3060
DAIKIN_VFAN_MON         = $3061
DAIKIN_VFAN_HOFF        = $4060
DAIKIN_VFAN_HON         = $4061
DAIKIN_VFAN_HHOFF       = $5060
DAIKIN_VFAN_HHON        = $5061

DAIKIN_VMODE_SWING      = $0000
DAIKIN_VMODE_HEAT       = $0001
DAIKIN_VMODE_COOL       = $0002
DAIKIN_VMODE_AUTO       = $0003
DAIKIN_VMODE_SETP       = $0006
DAIKIN_VMODE_DRY        = $0007

// constants indicating what generic 
// command is being used
integer READ_INPUT      = 1
integer READ_HOLD       = 2  
integer WRITE_HOLD      = 3
integer READ_DISCRETE   = 4
integer READ_COIL       = 5
integer WRITE_COIL      = 6

integer MAX_PARAMS      = 8
integer MAX_ZONES       = 16
(*****************************
******************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE    

// for the command parser
STRUCTURE _sCMD_PARAMETERS
{
    integer count
    char    param[MAX_PARAMS][32]
    char    rawdata[160]
}

structure _sZoneState
{
    integer nLLState
    integer nLState
    integer nMState
    integer nHState
    integer nHHState
    integer nPowerState
    integer nMode
    integer nTemp
}

structure _sZone
{
    integer nHeatSP 
    integer nHeatSpAddr
    integer nCoolSP
    integer nCoolSpAddr
    integer nTemp
    integer nTempAddr
}

DEFINE_VARIABLE

volatile char sCmdString[8][16] =
{  
        'READ_INPUT=', 
        'READ_HOLD=',
        'WRITE_HOLD=',
        'READ_DISCRETE=', 
        'READ_COIL=', 
        'WRITE_COIL=' 
}

integer btnHvac[] = {
    301, 302, 303, 304, 305, 306, 307, 308, 309, 310,
    311, 312, 313, 314, 315, 316, 317, 318, 319, 320,
    321, 322, 323, 324, 325, 326, 327, 328, 329, 330
}

btnAddrCode[] = {
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
    11, 12, 13, 14, 15, 16, 17, 18
}

integer nTempMin, nTempMax
_sZoneState sZoneState[HVAC_MAX_SLAVES]

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
// Name   : ==== fnParseCommand ====
// Purpose: To parse out parameters from module send_command or send_string
// Params : (1) IN  - sndcmd/str data
//          (2) IN  - parameter separating character usually ':' or '|' or even a string
//          (3) OUT - parsed property/method name STILL INCLUDES the '=' or '?'
//          (4) OUT - MDX_PARAMETERS structure
// Returns: integer - -1 if the parse failed OR the count of parameters placed in (4)
// Notes  : Parses the strings sent to or from modules extracting the various parts
//          of the command out into command name, parameters and returning the count
//          of parameters present.   Adapted from the UK mdxStandard.axi
//          Changed the functionality because it didn't appear to support parameters
//          with query commands 
//
define_function integer fnParseCommand(char cmd[], char separator [], 
                               char name[], _sCMD_PARAMETERS params)   
{
    stack_var char p        // use character to save space 
    stack_var char temp[32]
  
    if ( find_string(cmd,"'='",1) )
    {
        name = REMOVE_STRING(cmd,"'='",1) 
    }
    else 
    if  ( find_string(cmd,"'?'",1) )
    {
        name = REMOVE_STRING(cmd,"'?'",1)
    }
    else  
    {
        name = cmd
        return 0
    }
    ///////////////////////////////////////////////////////////////////////////
    // Strip the string down into parameters separated by ':'
    //    
    // Make the whole remaining buffer available for later if needed 
    params.rawdata = cmd
        
    // Tokenize the params
    p = 0         
    params.count = 0
    while( (LENGTH_STRING(cmd)) AND (params.count <= MAX_PARAMS) )
    {
        p++
        // Strip off each param and put into its index place in array
        temp = REMOVE_STRING(cmd,"separator",1)
        // May only be 1 param so no trailing ':'
        //
        // If nothing in temp, set temp = whatever's left in cmd  
        if(!LENGTH_STRING(temp))
        {
            temp = cmd
            CLEAR_BUFFER cmd
            if(LENGTH_STRING(temp) <32)
            {
                params.param[p] = temp
                params.count++
            }
        }
        else
        {
            SET_LENGTH_STRING(temp,LENGTH_STRING(temp)-1) // Remove ':'
            if(LENGTH_STRING(temp) <32)
            {
                params.param[p] = temp
                params.count++
            }
        }
    }
    return params.count
}

define_function integer roundTemp(integer v)
{
    integer i, j

    i = v/10
    j = v%10
    if (j >= 5) i++

    return i
}

define_function integer hvac_getTempGetAddr(integer devId)
{
    integer regBase, regAddr

    regBase = DAIKIN_REGADDR_TEMP
    regAddr = regBase + ((devId-1) * 6)

    return regAddr
}

define_function integer hvac_getFanSetAddr(integer devId)
{
    integer regBase, regAddr

    regBase = DAIKIN_REGADDR_FAN
    regAddr = regBase + ((devId-1) * 3)

    return regAddr
}

define_function integer hvac_getModeSetAddr(integer devId)
{
    integer regBase, regAddr

    regBase = DAIKIN_REGADDR_MODE
    regAddr = regBase + ((devId-1) * 3)

    return regAddr
}

define_function integer hvac_getTempSetAddr(integer devId)
{
    integer regBase, regAddr

    regBase = DAIKIN_REGADDR_TEMP
    regAddr = regBase + ((devId-1) * 3)

    return regAddr
}

// state 1 - on, 0 - off
define_function hvac_setLLToggle(integer devId, integer regAddr)
{
    integer regValue, key

    if (sZoneState[devId].nLLState)
    {
        regValue = DAIKIN_VFAN_LLON
        key = BTN_HVAC_F1HALL_LLON
    }
    else
    {
        regValue = DAIKIN_VFAN_LLOFF
        key = BTN_HVAC_F1HALL_LLOFF
    }

    send_command vdvHvac, "sCmdString[WRITE_HOLD],
                itoa(regAddr), ':', itoa(regValue), // addr, value
                ':', itoa(devId), ':', itoa(key)" // zone, key

    sZoneState[devId].nLLState = !sZoneState[devId].nLLState
}

define_function hvac_setPowerOn(integer devId, integer regAddr)
{
    integer regValue, key

    regValue = DAIKIN_VFAN_PON
    key = BTN_HVAC_SLAVEMAIN_PON

    send_command vdvHvac, "sCmdString[WRITE_HOLD],
                itoa(regAddr), ':', itoa(regValue), // addr, value
                ':', itoa(devId), ':', itoa(key)" // zone, key

    sZoneState[devId].nPowerState = 1
}

define_function hvac_setPowerOff(integer devId, integer regAddr)
{
    integer regValue, key

    regValue = DAIKIN_VFAN_POFF
    key = BTN_HVAC_SLAVEMAIN_POFF

    send_command vdvHvac, "sCmdString[WRITE_HOLD],
                itoa(regAddr), ':', itoa(regValue), // addr, value
                ':', itoa(devId), ':', itoa(key)" // zone, key

    sZoneState[devId].nPowerState = 0
}

define_function hvac_setPowerToggle(integer devId, integer regAddr)
{
    integer regValue, key

    if (sZoneState[devId].nLLState)
    {
        regValue = DAIKIN_VFAN_PON
        key = BTN_HVAC_F1HALL_LLON
    }
    else
    {
        regValue = DAIKIN_VFAN_POFF
        key = BTN_HVAC_F1HALL_LLOFF
    }

    send_command vdvHvac, "sCmdString[WRITE_HOLD],
                itoa(regAddr), ':', itoa(regValue), // addr, value
                ':', itoa(devId), ':', itoa(key)" // zone, key

    sZoneState[devId].nLLState = !sZoneState[devId].nLLState
}

define_function hvac_setDevMode(integer devId, integer regAddr,
                            integer modeValue, integer key)
{
    integer regValue

    regValue = modeValue

    debug('hvac', 8, "'modeValue = ', itoa(modeValue)")
    send_command vdvHvac, "sCmdString[WRITE_HOLD],
                itoa(regAddr), ':', itoa(regValue), // addr, value
                ':', itoa(devId), ':', itoa(key)" // zone, key
}

define_function hvac_setDevTemp(integer devId, integer regAddr,
                            integer tempValue, integer key)
{
    integer regValue

    regValue = (tempValue*10)

    debug('hvac', 8, "'tempValue = ', itoa(tempValue)")
    send_command vdvHvac, "sCmdString[WRITE_HOLD],
                itoa(regAddr), ':', itoa(regValue), // addr, value
                ':', itoa(devId), ':', itoa(key)" // zone, key

    sZoneState[devId].nTemp = tempValue
    tps_updateTxt(devId, itoa(sZoneState[devId].nTemp))
}

define_function tp_hvacOnlineSync(tpId)
{
    integer i

    for (i = 1; i <= HVAC_MAX_SLAVES; i++)
    {
        setButtonText(gDvTps[tpId], btnAddrCode[i], itoa(sZoneState[i].nTemp))
    }
}

define_function tp_hvacBtnSync()
{
    [gDvTps, btnHvac[BTN_HVAC_SLAVEMAIN_PON]] = sZoneState[HVAC_SLAVE_MAIN].nPowerState
    [gDvTps, btnHvac[BTN_HVAC_SLAVEMAIN_POFF]] = !sZoneState[HVAC_SLAVE_MAIN].nPowerState
}



DEFINE_MODULE 'Modbus-Comm' COMM1(vdvHvac, dvHvac)

DEFINE_START

nTempMax = 32
nTempMin = 16

DEFINE_EVENT

DATA_EVENT[dvHvac]
{
    ONLINE:
    {
        //send_command dvHvac, 'SET MODE DATA'
        //send_command dvHvac, 'SET BAUD 9600,N,8,1 485 ENABLE'

        //send_command dvHvac, 'SET BAUD 9600,N,8,1 485 DISABLE'
        //send_command dvHvac, 'HSOFF'
        //send_command dvHvac, 'XOFF'
    }
}

DATA_EVENT[vdvHvac]
{
    ONLINE:
    {
        wait 70
        {
            send_command vdvHvac,"'ADD_POLL=', 
                        itoa(hvac_getTempGetAddr(HVAC_SLAVE_MAIN)), ':4:',
                        itoa(HVAC_SLAVE_MAIN),':',itoa(BTN_ADDR_HVAC_TEMP)"

            //for (i = 1; i <= HVAC_MAX_SLAVES; i++)
            i = HVAC_SLAVE_MAIN
                send_command vdvHvac, "sCmdString[READ_INPUT],
                        itoa(hvac_getTempGetAddr(i)), ':', itoa(1), // addr, number
                        ':', itoa(i), ':', itoa(BTN_ADDR_HVAC_TEMP)" // zone, key
                         
        }          
    }
    STRING:
    {
        stack_var char i
        stack_var char cCMD[20], cVALUE
        stack_var _sCMD_PARAMETERS uParameters         
        stack_var _sCMD_PARAMETERS uValueString 
        stack_var integer nAddress
        stack_var integer nValue
        stack_var integer nValueArray[MAX_PARAMS]      // limited by fnParseCommand 
        //
        // For bits (i.e. coil or discrete input registers) each
        // <value> argument represents 8 registers SEE PROGRAMMING NOTES
        // so IF YOU CHOOSE TO REPRESENT AND CONVERT YOUR BITS IN THIS WAY,
        // then nBitsArray should  be 8 times the size of the nValueArray 
        //
        stack_var integer nZoneID 
        stack_var integer nNumber 
        stack_var integer nKey  
        stack_var char sValue[20]
        stack_var char sJunk[20] 
        stack_var integer nWriteOffset 

        {
            char dbgMsg[128]
            integer start, tlen

            tlen = length_string(data.text)
            start = 1
            while(start < tlen)
            {
                dbgMsg = mid_string(data.text, start, 128)
                start = start + 128
                debug('hvac', 8, "'dbgMsg = ', dbgMsg")
            }
        }

        uParameters.count = 0    
        uValueString.count = 0
        fnParseCommand(DATA.TEXT, "':'", cCMD, uParameters) 
           
        switch(cCMD)
        {
            case 'READ_INPUT=':
            {
                // READ_INPUT=0:1:15:1:DEV=1
                // response looks like
                // READ_INPUT=<address>:<value>:<zone ID>:<key>:DEV=<dev_addr>  
                nAddress = ATOI(uParameters.param[1])
                sValue = uParameters.param[2]
                nZoneID = ATOI(uParameters.param[3] )
                nKey = ATOI(uParameters.param[4] )  

                // check for multiple comma separated values in the value string 
                if (find_string (sValue,"','",1) )
                {
                    sValue = "'VALUE=',sValue"
                    fnParseCommand(sValue, "','", sJunk, uValueString)
                    for (i=1; i<= uValueString.count; i++)
                    {
                        nValueArray[i] = ATOI(uValueString.param[i]) 
                    }
                }
                else    // Single value is returned in the response
                {
                    nValueArray[1] = ATOI(sValue) 
                    uValueString.count = 1 
                }

                select
                {
                    active (nKey == BTN_ADDR_HVAC_TEMP):
                    {
                        debug('havc', 8, "'get zone', itoa(nZoneID), 'temp = ', itoa(roundTemp(nValueArray[1]))")
                        if (sZoneState[nZoneID].nTemp != roundTemp(nValueArray[1]))
                        {
                            sZoneState[nZoneID].nTemp = roundTemp(nValueArray[1])
                            tps_updateTxt(btnAddrCode[nZoneID], itoa(sZoneState[nZoneID].nTemp))
                        }
                    }
                }
                
            }
        }            
    }
}

BUTTON_EVENT[gDvTps, btnHvac]
{
    PUSH:
    {
        integer idxBtn
        integer tpId

        tpId   = get_last(gDvTps)
        idxBtn = get_last(btnHvac)

        pulse[gDvTps, button.input.channel]
        switch(idxBtn)
        {
            case BTN_HVAC_QUERY:
            {
                //send_string dvHvac, "$01,$04,$00,$00,$00,$01,$31,$ca"
                send_command vdvHvac, "sCmdString[READ_INPUT],
                            ITOA(0), ':', ITOA(1), // addr, number
                            ':100', ':', ITOA(READ_INPUT) // zone, key
                            "  
            }              
            case BTN_HVAC_LINKSTATE:
            {
                //send_string dvHvac, "$01,$04,$00,$01,$00,$04,$a0,$09"
                send_command vdvHvac, "sCmdString[READ_INPUT],
                            ITOA(1), ':', ITOA(4), // addr, number
                            ':100', ':', ITOA(READ_INPUT) // zone, key
                            "
            }
            case BTN_HVAC_COMMSTATE:
            {
                send_command vdvHvac, "sCmdString[READ_INPUT],
                            ITOA(5), ':', ITOA(4), // addr, number
                            ':100', ':', ITOA(READ_INPUT) // zone, key
                            "                     
            }
            case BTN_HVAC_SETADDRANGE:
            {
                send_command vdvHvac, "sCmdString[WRITE_HOLD],
                        itoa(0), ':', itoa($8107), // addr, value
                        ':100', ':', itoa(WRITE_HOLD)" // zone, key                      
            }
            case BTN_HVAC_SLAVEMAIN_PON:
            {
                hvac_setPowerOn(HVAC_SLAVE_MAIN, hvac_getFanSetAddr(HVAC_SLAVE_MAIN))
            }
            case BTN_HVAC_SLAVEMAIN_POFF:
            {
                hvac_setPowerOff(HVAC_SLAVE_MAIN, hvac_getFanSetAddr(HVAC_SLAVE_MAIN))
            }            
            case BTN_HVAC_F1HALL_MODE_SWING:
            {
                hvac_setDevMode(HVAC_SLAVE_F1_1, 
                    hvac_getModeSetAddr(HVAC_SLAVE_F1_1), DAIKIN_VMODE_SWING, idxBtn)
            }
            case BTN_HVAC_F1HALL_MODE_HEAT:
            {
                hvac_setDevMode(HVAC_SLAVE_F1_1, 
                    hvac_getModeSetAddr(HVAC_SLAVE_F1_1), DAIKIN_VMODE_HEAT, idxBtn)
            }
            case BTN_HVAC_F1HALL_MODE_COOL:
            {
                hvac_setDevMode(HVAC_SLAVE_F1_1, 
                    hvac_getModeSetAddr(HVAC_SLAVE_F1_1), DAIKIN_VMODE_COOL, idxBtn)
            }
            case BTN_HVAC_F1HALL_MODE_DRY:
            {
                hvac_setDevMode(HVAC_SLAVE_F1_1, 
                    hvac_getModeSetAddr(HVAC_SLAVE_F1_1), DAIKIN_VMODE_DRY, idxBtn)
             }                    
            case BTN_HVAC_F1HALL_TEMP_UP:
            {                
                if (sZoneState[HVAC_SLAVE_F1_1].nTemp <= nTempMax)
                {
                    sZoneState[HVAC_SLAVE_F1_1].nTemp++
                }
                
                hvac_setDevTemp(HVAC_SLAVE_F1_1, 
                    hvac_getTempSetAddr(HVAC_SLAVE_F1_1), 
                    sZoneState[HVAC_SLAVE_F1_1].nTemp, 
                    idxBtn)
                sZoneState[HVAC_SLAVE_F1_2].nTemp = sZoneState[HVAC_SLAVE_F1_1].nTemp
                hvac_setDevTemp(HVAC_SLAVE_F1_2, 
                    hvac_getTempSetAddr(HVAC_SLAVE_F1_2), 
                    sZoneState[HVAC_SLAVE_F1_2].nTemp, idxBtn)
            }
            case BTN_HVAC_F1HALL_TEMP_DOWN:
            {
                if (sZoneState[5].nTemp >= nTempMin)
                {
                    sZoneState[5].nTemp--
                }

                hvac_setDevTemp(HVAC_SLAVE_F1_1, 
                    hvac_getTempSetAddr(HVAC_SLAVE_F1_1), 
                    sZoneState[HVAC_SLAVE_F1_1].nTemp, 
                    idxBtn)
                sZoneState[HVAC_SLAVE_F1_2].nTemp = sZoneState[HVAC_SLAVE_F1_1].nTemp
                hvac_setDevTemp(HVAC_SLAVE_F1_2, 
                    hvac_getTempSetAddr(HVAC_SLAVE_F1_2), 
                    sZoneState[HVAC_SLAVE_F1_2].nTemp, idxBtn)                   
            }     
                   
            default:
                break
        }
    }
}

