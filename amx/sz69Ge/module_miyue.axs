MODULE_NAME='module_miyue' (DEV dvMiyue, DEV vdvMiyue)
(***********************************************************)
(*  FILE CREATED ON: 07/22/2013  AT: 12:12:22              *)
(***********************************************************)
(*                                                         *)
(***********************************************************)
(*                                                         *)
(*                                                         *)
(*                                                         *)
(*  COMMENTS:                                              *)
(*                                                         *)
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

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

MAX_STRING_SIZE         = 128
MAX_BUFFER_SIZE         = 256000

MIYUE_COMMS_TIMEOUT     = 20
MIYUE_MAX_VOLVAL        = 15

MIYUE_IPADDRESS         = '192.168.1.12'
MIYUE_PORT              = 6785

MIYUE_CCHAN_PLAY        = 1
MIYUE_CCHAN_PAUSE       = 2
MIYUE_CCHAN_PREV        = 3
MIYUE_CCHAN_NEXT        = 4
MIYUE_CCHAN_VOLUP       = 5
MIYUE_CCHAN_VOLDOWN     = 6
MIYUE_CCHAN_INIT        = 7
MIYUE_CCHAN_TOGPL       = 8     // toggle play and pause
MIYUE_CCHAN_VOLSET      = 9


MCSEP                   = $0A   // MIYUE command separator
(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile char bOnline 
volatile integer nDebug         // toggle debug on or off
volatile integer nCommsError    // communication error
volatile integer nCurrVolume    // current volume level
volatile integer nAudioNumber   // total audio number
volatile integer nPlayState     // play / pause
volatile integer nPlayingId     // audio id which is playing

volatile char caBuffer[MAX_BUFFER_SIZE]

volatile integer ctrlChannels[] = {
    MIYUE_CCHAN_PLAY,
    MIYUE_CCHAN_PAUSE,
    MIYUE_CCHAN_PREV,
    MIYUE_CCHAN_NEXT,
    MIYUE_CCHAN_VOLUP,
    MIYUE_CCHAN_VOLDOWN,
    MIYUE_CCHAN_INIT
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

// pass debug info to console
define_function fnDebug(char caMsg[])
{
    if (nDebug)
        send_string 0, "'[MDL-MIYUE] - ',caMsg"
}


// module debug level
define_function fnSetDebug(char caCmd[])
{
    remove_string(caCmd,'Debug-',1)
    switch (caCmd)
    {
        case 'On':  nDebug = true
        case 'Off': nDebug = false
    }
}

define_function fnSetVolume(char caCmd[])
{
    integer vol

    remove_string(caCmd,'Vol-',1)
    vol = atoi(caCmd)

    volCmdSend(vol)
}

define_function fnDevConnect()
{
    ip_client_open (dvMiyue.port, MIYUE_IPADDRESS, MIYUE_PORT, IP_TCP)
}

// open connection and send string to device
define_function fnSendToDevice (char cmdStr[MAX_STRING_SIZE])
{   
    if (!bOnline)
    {
        fnDebug("'ip_client_open to ', MIYUE_IPADDRESS, ':', itoa(MIYUE_PORT)")
        ip_client_open (dvMiyue.port, MIYUE_IPADDRESS, MIYUE_PORT, IP_TCP)
        wait 5
        {
            send_string dvMiyue, "cmdStr"
            fnDebug("'string to MIYUE: ', cmdStr")
        }
    }   
    else
    {
        send_string dvMiyue, "cmdStr"
        fnDebug("'string to MIYUE: ', cmdStr")
    }
    
    // communications timeout
    wait (MIYUE_COMMS_TIMEOUT) 'CommsTimeout'
    {
        fnDebug ('No response received from device.')
        nCommsError = true
    }
}

define_function integer volCmdSend(integer vol)
{
    long v
    char cmdStr[MAX_STRING_SIZE]

    if ((vol < 0)||(vol > MIYUE_MAX_VOLVAL))
    {
        fnDebug("'Error input vol = ', itoa(vol)")
        return 0
    }

    // 30~31 bit control the play state, {1,1} means ignore
    // volume is set at 20~27 bit
    v = ($03 << 30) + type_cast(vol << 20)
    
    cmdStr = "'SET PLAYER_STAT {M:', itoa(v), ',P:-1,EQ:-1,CM:-1}', MCSEP"
    fnSendToDevice(cmdStr)

    return 1
}

define_function handleChannelCmd(integer chan)
{
    long v
    char cmdStr[MAX_STRING_SIZE]

    cmdStr = ''
    switch (chan)
    {
        case MIYUE_CCHAN_INIT:
        {
            fnSendToDevice("'ALLOW_PLAYER_STAT', MCSEP")
            fnSendToDevice("'GET MEDIA_LIBRARY', MCSEP")
            fnSendToDevice("'GET PLAYER_STAT', MCSEP")
        }        
        case MIYUE_CCHAN_PLAY:
        {
            v = $4ff00000
            cmdStr = "'SET PLAYER_STAT {M:', itoa(v), ',P:-1,EQ:-1,CM:-1}', MCSEP"
            fnSendToDevice(cmdStr)
        }
        case MIYUE_CCHAN_PAUSE:
        {
            v = $0ff00000
            cmdStr = "'SET PLAYER_STAT {M:', itoa(v), ',P:-1,EQ:-1,CM:-1}', MCSEP"
            fnSendToDevice(cmdStr)
        }
        case MIYUE_CCHAN_PREV:
        {
            if (nPlayingId > 0) nPlayingId--
            cmdStr = "'PLAY AUDIO ', itoa(nPlayingId), MCSEP"
            fnSendToDevice(cmdStr)
        }
        case MIYUE_CCHAN_NEXT:
        {
            if (nPlayingId > nAudioNumber) 
                nPlayingId = 0
            else 
                nPlayingId++
            cmdStr = "'PLAY AUDIO ', itoa(nPlayingId), MCSEP"
            fnSendToDevice(cmdStr)
        }            
        case MIYUE_CCHAN_VOLUP:
        {
            if (nCurrVolume < MIYUE_MAX_VOLVAL) nCurrVolume++
            volCmdSend(nCurrVolume)
        }
        case MIYUE_CCHAN_VOLDOWN:
        {
            if (nCurrVolume > 0) nCurrVolume--
            volCmdSend(nCurrVolume)
        }     
    }
}    

define_function integer handleChannelCmdEx(integer chan, integer parm)
{
    long v
    char cmdStr[MAX_STRING_SIZE]

    cmdStr = ''
    switch(chan)
    {
        case MIYUE_CCHAN_VOLSET:
        {
            if (parm > MIYUE_MAX_VOLVAL) return 0

            v = type_cast(parm)
            // 30~31 bit control the play state, {1,1} means ignore
            // volume is set at 20~27 bit
            v = ($03 << 30) + (v << 20)

            cmdStr = "'SET PLAYER_STAT {M:', itoa(v), ',P:-1,EQ:-1,CM:-1}', MCSEP"

            fnSendToDevice(cmdStr)
        }
    }

    return 1
}

define_function char[MAX_STRING_SIZE] ipError (long err)
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

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

bOnline     = false
nDebug      = true      // enable debug info by default

CREATE_BUFFER dvMiyue, caBuffer // only used by STRING

fnDevConnect()

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

/*
C: GET PLAYER_STAT, $0A
S: {"STAT":1089531906,"MOUNT_CHANGE":false,"CURRENT_POSITION":72960,"EQ":2,
"MSG_TYPE":61444,"CM":0,"DURATION":294983,"ONRADIO":0}, $0A
*/
DATA_EVENT[dvMiyue]
{
    ONLINE:
    {   
        bOnline = true
        handleChannelCmd(MIYUE_CCHAN_INIT)
    }
    OFFLINE:
    {
        bOnline = false
    }
    STRING:
    {
        integer len
        //char reply[MAX_BUFFER_SIZE]
        //char reply[MAX_STRING_SIZE] // only hold the preivous 128 bytes of the data
/*
        {
            char dbgMsg[MAX_STRING_SIZE]
            integer start, tlen

            tlen = length_string(data.text)
            start = 1
            while(start < tlen)
            {
                dbgMsg = mid_string(data.text, start, MAX_STRING_SIZE)
                start = start + MAX_STRING_SIZE
                fnDebug("'dbgMsg = ', dbgMsg")
            }
        }   
*/

        // The reply of "GET MEDIA_LIBRARY" is so large that the create buffer
        // value can't store. So we can only parse with the data.text
        select
        {
            // C->S: GET MEDIA_LIBRARY, $0A
            
            // The reply is not according to the document, keyword placed
            // randomly in the data

            active(find_string(data.text, '"AudioLen":', 1)):
            {
                // "AudioLen":13,=>13,...
                remove_string(data.text, '"AudioLen":', 1)
                nAudioNumber = atoi(remove_string(data.text, ',', 1))

                fnDebug("'update audio number = ', itoa(nAudioNumber)")
            }
            // C->S: GET PLAYER_STAT, $0A
            active(find_string(data.text, '"MSG_TYPE":61444', 1)):
            {
                long v

                fnDebug("'data.text = ', data.text")
                // "STAT":1089531906,
                remove_string(data.text, '"STAT":', 1)
                v = atoi(remove_string(data.text, ',', 1))

                nCurrVolume = type_cast((v >> 20) & $FF)
                nPlayState  = type_cast((v >> 30) & $03)
                nPlayingId  = type_cast(v % 4096)

                fnDebug("'update curVol = ', itoa(nCurrVolume)")
                fnDebug("'update playState = ', itoa(nPlayState)")
                fnDebug("'update playingId = ', itoa(nPlayingId)")

                send_string vdvMiyue, "'curVol-',itoa(nCurrVolume)"
            }            
        }


/*
        while(find_string(caBuffer, "MCSEP", 1))
        {
            fnDebug("'dvMiyue STRING: find separator', MCSEP")

            reply = left_string(caBuffer, MAX_STRING_SIZE)
            fnDebug("'[3:25]reply = ', reply")

            //reply = remove_string(caBuffer, "MCSEP", 1)

            select
            {
                // C->S: GET MEDIA_LIBRARY, $0A
                active(find_string(reply, '"MSG_TYPE":61442', 1)):
                {
                    len = length_string(reply) - find_string(reply,'"AudioLen":',1) - 
                        length_string('"AudioLen":') + 1

                    // "AudioLen":13,=>13,...
                    remove_string(reply, '"AudioLen":', 1)
                    nAudioNumber = atoi(remove_string(reply, ',', 1))

                    fnDebug("'update audio number = ', itoa(nAudioNumber)")
                }

                // C->S: GET PLAYER_STAT, $0A
                active(find_string(reply, '"MSG_TYPE":61444', 1)):
                {
                    long v

                    // "STAT":1089531906,
                    remove_string(reply, '"STAT":', 1)
                    v = atoi(remove_string(reply, ',', 1))

                    nCurrVolume = type_cast((v >> 20) & $FF)
                    nPlayState  = type_cast((v >> 30) & $03)
                    nPlayingId  = type_cast(v % 4096)

                    fnDebug("'update curVol = ', itoa(nCurrVolume)")
                    fnDebug("'update playState = ', itoa(nPlayState)")
                    fnDebug("'update playingId = ', itoa(nPlayingId)")

                    send_string vdvMiyue, "'curVol-',itoa(nCurrVolume)"
                }
            }

            remove_string(caBuffer, "MCSEP", 1)
        }
*/
        // well, we got the response, stop waiting
        cancel_wait 'CommsTimeout'
        nCommsError = false
    }
    ONERROR:
    {
        bOnline = false
        fnDebug("ipError(data.number)")
    }
}

DATA_EVENT[vdvMiyue]
{
    COMMAND:
    {
        fnDebug("'command received by module: ', data.text")
        select
        {
            active (find_string(data.text,'Debug-', 1)): 
                fnSetDebug (data.text)
            active (find_string(data.text,'Vol-', 1)): 
                fnSetVolume (data.text)
        }
    }
}

CHANNEL_EVENT[vdvMiyue, ctrlChannels]
{
    ON:
    {
        handleChannelCmd(channel.channel)
    }
}

(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT  *)
(***********************************************************)