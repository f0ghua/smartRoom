PROGRAM_NAME='ge69_bgMusic'

DEFINE_CONSTANT

MIYUE_IPADDRESS     = '192.168.1.12'
MIYUE_PORT          = "6785"

MIYUE_CMD_PLAY      = 1
MIYUE_CMD_PAUSE     = 2
MIYUE_CMD_PREV      = 3
MIYUE_CMD_NEXT      = 4
MIYUE_CMD_VOLUP     = 5
MIYUE_CMD_VOLDOWN   = 6
MIYUE_CMD_TOGPL     = 7     // toggle play and pause
MIYUE_CMD_RESET     = 8

MIYUE_LEVEL_INDEX   = 5
MAX_MYLEVEL_NUMBER  = 8
MAX_MYLEVEL_VALUE   = 15    // MIYUE's volume max value is 15

ADCODE_STS_MIYUELINK    = 31    // address code for link status of MIYUE

DEFINE_VARIABLE

// PLAY, PAUSE, |<, >|, VOL+, VOL-, PLAY/PAUSE, FMT
integer btnMiYue[] = {
    401, 402, 403, 404, 405, 406, 407, 408
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

char gblMYLevelValue[MAX_MYLEVEL_NUMBER]
char gblMiyueConnStatus = FALSE

DEFINE_FUNCTION miyueIpOpen()
{
    if (gblMiyueConnStatus == 0)
    {
        //print(LOG_LEVEL_DEBUG, "call function IP_CLIENT_OPEN")
        IP_CLIENT_OPEN(dvMiYue.port, MIYUE_IPADDRESS, MIYUE_PORT, IP_TCP)
    }
}

DEFINE_FUNCTION miyueIpClose()
{
    if (gblMiyueConnStatus == 1)
        IP_CLIENT_CLOSE(dvMiYue.port)
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

// Define the backgroud music module with 'MIYUE'
DEFINE_MODULE 'ModMiYue' uMod2 (dvMiYue, vdvMiYue)

DEFINE_EVENT

BUTTON_EVENT[vdvTP, btnMiYue]
{
    PUSH:
    {
        integer idxBtn

        miyueIpOpen()   // wait here will make user unhappy
        idxBtn = get_last(btnMiYue)
        switch(idxBtn)
        {
            case MIYUE_CMD_PLAY: // play|pause, now use only 1 button
            case MIYUE_CMD_PAUSE:
            {
                if ([vdvTP, BUTTON.INPUT.CHANNEL] == 0)
                {
                    SEND_LEVEL vdvMiYue, 1, MIYUE_CMD_PLAY
                }
                else
                {
                    SEND_LEVEL vdvMiYue, 1, MIYUE_CMD_PAUSE
                }

                [vdvTP, BUTTON.INPUT.CHANNEL] = ![vdvTP, BUTTON.INPUT.CHANNEL]
            }
            default:
            {
                SEND_LEVEL vdvMiYue, 1, idxBtn
            }
        }
    }
}

BUTTON_EVENT[vdvTP, btnMYLevel]
{
    RELEASE:
    {
        integer i 

        i = get_last(btnMYLevel)

        SEND_LEVEL vdvMiYue, 1, gblMYLevelValue[i]
    }
}

LEVEL_EVENT[vdvTP, btnMYLevel]
{
    integer i;
    
    i = get_last(btnMYLevel)
    
    gblMYLevelValue[i] = LEVEL.VALUE
}

DATA_EVENT[dvMiYue]
{
    ONLINE:
    {
        gblMiyueConnStatus = TRUE
        PULSE[vdvMiYue, MIYUE_CMD_RESET]    // initialize the device
        SEND_STRING 0,"'***TRACE*** IP CONNECTION ESTABLISHED'"
        SEND_COMMAND vdvTP, "'^TXT-', itoa(ADCODE_STS_MIYUELINK), ',0,ONLINE'"
    }
    OFFLINE:
    {
        gblMiyueConnStatus = FALSE
        SEND_STRING 0,"'***TRACE*** IP CONNECTION TERMINATED'"
        SEND_COMMAND vdvTP, "'^TXT-', itoa(ADCODE_STS_MIYUELINK), ',0,OFFLINE'"
    }
    ONERROR:
    {
        SEND_STRING 0,"'***TRACE*** IP CONNECTION ERROR'"
        SEND_STRING dvTerminal, ipError(DATA.NUMBER)        
    }
}
