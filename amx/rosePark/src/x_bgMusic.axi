PROGRAM_NAME='x_bgMusic'

DEFINE_DEVICE

dvBgMusic              = 5001:1:0

DEFINE_CONSTANT

BGM_DEFAULT_ROOM  = 533

BGM_CMD_POWERON   = 0
BGM_CMD_POWEROFF  = 1
BGM_CMD_PLAY      = 2
BGM_CMD_PAUSE     = 3
BGM_CMD_VOLDOWN   = 6
BGM_CMD_VOLUP     = 7
BGM_CMD_MUTEOFF   = 8
BGM_CMD_MUTEON    = 9
BGM_CMD_MUTETOG   = 10
BGM_CMD_PREV      = 11
BGM_CMD_NEXT      = 12

DEFINE_VARIABLE

integer btnBGM[] = {
    201, 202, 203, 204, 205, 206, 207, 208, 
    209, 210, 211, 212, 213, 214, 215, 216
}

define_function bgm_cmdSend(integer room, integer cmdId)
{
    integer ck
    char roomH8, roomL8

    roomH8 = type_cast((room&$FF00)>>8)
    roomL8 = type_cast(room&$FF)
    ck = roomH8 + roomL8 + $02 + $10 + cmdId
    send_string dvBgMusic, "$FA,roomH8,roomL8,$02,$10,cmdId,ck,$FE"
}

define_function bgm_start()
{
    bgm_cmdSend(BGM_DEFAULT_ROOM, BGM_CMD_POWERON)
    wait 10
    bgm_cmdSend(BGM_DEFAULT_ROOM, BGM_CMD_PLAY)
}

define_function bgm_stop()
{
    bgm_cmdSend(BGM_DEFAULT_ROOM, BGM_CMD_POWEROFF)
}

DEFINE_START

DEFINE_EVENT

DATA_EVENT[dvBgMusic]
{
    ONLINE:
    {
        send_command data.device, 'SET MODE DATA'
        send_command data.device, 'SET BAUD 9600,N,8,1 485 ENABLE'
    }
    STRING:
    {
        {
            char dbgMsg[128]
            integer start, tlen

            tlen = length_string(data.text)
            start = 1
            while(start < tlen)
            {
                dbgMsg = mid_string(data.text, start, 128)
                start = start + 128
                debug('light', 8, "'dbgMsg = ', dbgMsg")
            }
        }
    }
}

BUTTON_EVENT[gDvTps, btnBGM]
{
    PUSH:
    {
        integer idxBtn
        integer tpId

        tpId   = get_last(gDvTps)
        idxBtn = get_last(btnBGM)

        switch(idxBtn)
        {
            default:
                bgm_cmdSend(BGM_DEFAULT_ROOM, idxBtn-1)
        }
    }
}

