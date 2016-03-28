PROGRAM_NAME='ge69_bgMusic'

DEFINE_CONSTANT

MIYUE_IPADDRESS     = '192.168.1.12'
MIYUE_PORT          = 6785

// define module channels
MIYUE_CCHAN_PLAY        = 1
MIYUE_CCHAN_PAUSE       = 2
MIYUE_CCHAN_PREV        = 3
MIYUE_CCHAN_NEXT        = 4
MIYUE_CCHAN_VOLUP       = 5
MIYUE_CCHAN_VOLDOWN     = 6
MIYUE_CCHAN_INIT        = 7

MIYUE_CMD_PLAY      = 1
MIYUE_CMD_PAUSE     = 2
MIYUE_CMD_PREV      = 3
MIYUE_CMD_NEXT      = 4
MIYUE_CMD_VOLUP     = 5
MIYUE_CMD_VOLDOWN   = 6
MIYUE_CMD_RESET     = 7
MIYUE_CMD_TOGPL     = 8     // toggle play and pause


MIYUE_CMD_LINK      = 9

MIYUE_LEVEL_INDEX   = 5
MAX_MYLEVEL_NUMBER  = 8
MAX_MYLEVEL_VALUE   = 15    // MIYUE's volume max value is 15

ADCODE_STS_MIYUELINK    = 31    // address code for link status of MIYUE

DEFINE_VARIABLE

// PLAY, PAUSE, |<, >|, VOL+, VOL-, INIT, PLAY/PAUSE, LINK
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

//char ipaddr[] = MIYUE_IPADDRESS
char gMYBtnState[MAX_MYLEVEL_NUMBER]
char gblMYLevelValue[MAX_MYLEVEL_NUMBER]
char gblMiyueConnStatus

DEFINE_FUNCTION setBgMusicVol(integer vol)
{
    send_command vdvMiYue, "'Vol-', itoa(vol)"
}

DEFINE_FUNCTION bgMuicCommand(integer cmdId)
{
    switch (cmdId)
    {
        case MIYUE_CMD_TOGPL: // play|pause, now use only 1 button
        {
            if (gMYBtnState[MIYUE_CMD_TOGPL] == 0)
            {
                pulse [vdvMiYue, MIYUE_CCHAN_PLAY]
                gMYBtnState[MIYUE_CMD_TOGPL] = 1
            }
            else
            {
                pulse [vdvMiYue, MIYUE_CCHAN_PAUSE]
                gMYBtnState[MIYUE_CMD_TOGPL] = 0
            }
        }
        default:
        {
            pulse [vdvMiYue, cmdId]
        }
    }

}

DEFINE_START

// Define the backgroud music module with 'MIYUE'
DEFINE_MODULE 'module_miyue' uMod_MiYue (dvMiYue, vdvMiYue)

DEFINE_EVENT

DATA_EVENT[vdvMiyue]
{
    STRING:
    {
        select
        {
            active (find_string(data.text, 'curVol-', 1)): 
            {
                remove_string(data.text, 'curVol-', 1)
                gblMYLevelValue[1] = atoi(data.text)

                updateLevelValue(btnMYLevel[1], gblMYLevelValue[1])
            }
        }
    }
}

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

        debug('bgMusic', 4, "'BUTTON_EVENT: gblMYLevelValue[', itoa(i), '] = ', 
            itoa(gblMYLevelValue[i])")
        setBgMusicVol(gblMYLevelValue[1])
    }
}

LEVEL_EVENT[gDvTps, btnMYLevel]
{
    integer i;
    
    i = get_last(btnMYLevel)
    
    debug('bgMusic', 4, "'LEVEL_EVENT: gblMYLevelValue[', itoa(i), '] = ', LEVEL.VALUE")
    gblMYLevelValue[i] = LEVEL.VALUE
}

