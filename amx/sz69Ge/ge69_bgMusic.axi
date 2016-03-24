PROGRAM_NAME='ge69_bgMusic'

DEFINE_CONSTANT

MIYUE_IPADDRESS     = '192.168.1.12'
MIYUE_PORT          = 6785

MIYUE_CMD_PLAY      = 1
MIYUE_CMD_PAUSE     = 2
MIYUE_CMD_PREV      = 3
MIYUE_CMD_NEXT      = 4
MIYUE_CMD_VOLUP     = 5
MIYUE_CMD_VOLDOWN   = 6
MIYUE_CMD_TOGPL     = 7     // toggle play and pause
MIYUE_CMD_RESET     = 8

MIYUE_CMD_LINK      = 9

MIYUE_LEVEL_INDEX   = 5
MAX_MYLEVEL_NUMBER  = 8
MAX_MYLEVEL_VALUE   = 15    // MIYUE's volume max value is 15

ADCODE_STS_MIYUELINK    = 31    // address code for link status of MIYUE

DEFINE_VARIABLE

// PLAY, PAUSE, |<, >|, VOL+, VOL-, PLAY/PAUSE, FMT, LINK
integer btnMiYue[] = {
    401, 402, 403, 404, 405, 406, 407, 408, 409
}

integer btnMYLevel[MAX_MYLEVEL_NUMBER] = {
    311,
    312,
    313,
    314,
    315,
    316,
    317,
    318
}

char gMYBtnState[MAX_MYLEVEL_NUMBER]
char gblMYLevelValue[MAX_MYLEVEL_NUMBER]
char gblMiyueConnStatus = 0

DEFINE_FUNCTION miyueIpOpen()
{
    if (gblMiyueConnStatus == 0)
    {
        //print(LOG_LEVEL_DEBUG, "call function IP_CLIENT_OPEN")
        debug('bgMusic', 4, "'ip client open: lport=', itoa(dvMiYue.port), 
            ', ip=', MIYUE_IPADDRESS, ', port=', itoa(MIYUE_PORT)")
        IP_CLIENT_OPEN(dvMiYue.port, MIYUE_IPADDRESS, MIYUE_PORT, IP_TCP)
    }
}

DEFINE_FUNCTION miyueIpClose()
{
    IP_CLIENT_CLOSE(dvMiYue.port)
}

DEFINE_FUNCTION bgMuicCommand(integer cmdId)
{
    if (gblMiyueConnStatus == 1)
    {
        debug('bgMusic', 4, "'bgMuicCommand: cmdId = ', cmdId")
        switch (cmdId)
        {
            case MIYUE_CMD_TOGPL: // play|pause, now use only 1 button
            {
                if (gMYBtnState[MIYUE_CMD_TOGPL] == 0)
                {
                    SEND_LEVEL vdvMiYue, 1, MIYUE_CMD_PLAY
                    gMYBtnState[MIYUE_CMD_TOGPL] = 1
                }
                else
                {
                    SEND_LEVEL vdvMiYue, 1, MIYUE_CMD_PAUSE
                    gMYBtnState[MIYUE_CMD_TOGPL] = 0
                }
            }
            default:
            {
                SEND_LEVEL vdvMiYue, 1, cmdId
            }

        }
    }
    else
    {
        debug('bgMusic', 4, "'bgMuicCommand: no ip connection ESTABLISHED'")
    }
}

DEFINE_FUNCTION integer setBgMusicVol(char vol)
{
    long v
    char cmdStr[64]

    if (vol > MAX_MYLEVEL_VALUE) return 0

    v = type_cast(vol)
    // volume is set at 20~27 bit
    v = (v << 20)
    // 30~31 bit control the play state, {1,1} means ignore
    v = ($03 << 30) + v
    
    cmdStr = "'SET PLAYER_STAT {M:',itohex(v),',P:-1,EQ:-1,CM:-1}',13"
    debug('bgMusic', 4, "'setBgMusicVol: cmd = ', cmdStr")

    //fnQueueTheCommand(dvMiYue, "'SET PLAYER_STAT {M:', itoa(v), ',P:-1,EQ:-1,CM:-1}', $0D")
    send_string dvMiYue, "'SET PLAYER_STAT {M:', itoa(v), ',P:-1,EQ:-1,CM:-1}', $0D"
    
    return 1
}    

// prints ip errors to diagnostics
DEFINE_FUNCTION char[100] ipError (long err)
{
    switch (err)
    {
        case 0:
            return "";
        Case 2:
            return "'IP ERROR (',itoa(err),'): General Failure (IP_CLIENT_OPEN/IP_SERVER_OPEN)'";
        case 4:
            return "'IP ERROR (',itoa(err),'): unknown host or DNS error (IP_CLIENT_OPEN)'";
        case 6:
            return "'IP ERROR (',itoa(err),'): connection refused (IP_CLIENT_OPEN)'";
        case 7:
            return "'IP ERROR (',itoa(err),'): connection timed out (IP_CLIENT_OPEN)'";
        case 8:
            return "'IP ERROR (',itoa(err),'): unknown connection error (IP_CLIENT_OPEN)'";
        case 14:
            return "'IP ERROR (',itoa(err),'): local port already used (IP_CLIENT_OPEN/IP_SERVER_OPEN)'";
        case 16:
            return "'IP ERROR (',itoa(err),'): too many open sockets (IP_CLIENT_OPEN/IP_SERVER_OPEN)'";
        case 10:
            return "'IP ERROR (',itoa(err),'): Binding error (IP_SERVER_OPEN)'";
        case 11:
            return "'IP ERROR (',itoa(err),'): Listening error (IP_SERVER_OPEN)'";
        case 15:
            return "'IP ERROR (',itoa(err),'): UDP socket already listening (IP_SERVER_OPEN)'";
        case 9:
            return "'IP ERROR (',itoa(err),'): Already closed (IP_CLIENT_CLOSE/IP_SERVER_CLOSE)'";
        case 17:
            return "'IP ERROR (',itoa(err),'): Local port not open, can not send string (IP_CLIENT_OPEN)'";
        default:
            return "'IP ERROR (',itoa(err),'): Unknown'";
    }
} 

DEFINE_START
miyueIpOpen()

// Define the backgroud music module with 'MIYUE'
DEFINE_MODULE 'ModMiYue' uMod_MiYue (dvMiYue, vdvMiYue)

DEFINE_EVENT

BUTTON_EVENT[gDvTps, btnMiYue]
{
    PUSH:
    {
        integer idxBtn
        integer tpId

        tpId   = get_last(gDvTps)
        idxBtn = get_last(btnMiYue)

        switch(idxBtn)
        {
            case MIYUE_CMD_VOLDOWN:
            {
                if (gblMYLevelValue[1] > 0) gblMYLevelValue[1]--
                setBgMusicVol(gblMYLevelValue[1])
                updateLevelValue(btnMYLevel[1], gblMYLevelValue[1])
            }
            case MIYUE_CMD_VOLUP:
            {
                if (gblMYLevelValue[1] <= MAX_MYLEVEL_VALUE) gblMYLevelValue[1]++
                setBgMusicVol(gblMYLevelValue[1])
                updateLevelValue(btnMYLevel[1], gblMYLevelValue[1])
            }
            case MIYUE_CMD_LINK:
            {
                gblMiyueConnStatus = 0
                miyueIpOpen()
            }
            default:
                bgMuicCommand(idxBtn)
        }
    }
}

BUTTON_EVENT[gDvTps, btnMYLevel]
{
    RELEASE:
    {
        integer i 

        i = get_last(btnMYLevel)

        debug('bgMusic', 4, "'BUTTON_EVENT: gblMYLevelValue[', itoa(i), '] = ', gblMYLevelValue[i]")
        setBgMusicVol(gblMYLevelValue[i])
        //SEND_LEVEL vdvMiYue, 1, gblMYLevelValue[i]
    }
}

LEVEL_EVENT[gDvTps, btnMYLevel]
{
    integer i;
    
    i = get_last(btnMYLevel)
    
    debug('bgMusic', 4, "'LEVEL_EVENT: gblMYLevelValue[', itoa(i), '] = ', LEVEL.VALUE")
    gblMYLevelValue[i] = LEVEL.VALUE
}

DATA_EVENT[dvMiYue]
{
    ONLINE:
    {
        gblMiyueConnStatus = 1
        PULSE[vdvMiYue, MIYUE_CMD_RESET]    // initialize the device
        debug('bgMusic', 4, "'***TRACE*** IP CONNECTION ESTABLISHED'")
        SEND_COMMAND gDvTps, "'^TXT-', itoa(ADCODE_STS_MIYUELINK), ',0,ONLINE'"
    }
    OFFLINE:
    {
        gblMiyueConnStatus = 0
        debug('bgMusic', 4, "'***TRACE*** IP CONNECTION TERMINATED'")
        SEND_COMMAND gDvTps, "'^TXT-', itoa(ADCODE_STS_MIYUELINK), ',0,OFFLINE'"
        wait 300 miyueIpOpen()
    }
    ONERROR:
    {
        gblMiyueConnStatus = 0
        debug('bgMusic', 4, "ipError(DATA.NUMBER)")

        switch(DATA.NUMBER)
        {
            case 14:
                miyueIpClose()
        }

        wait 300 miyueIpOpen()
    }
}
