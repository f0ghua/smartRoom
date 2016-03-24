PROGRAM_NAME='ge69_dvd'

DEFINE_CONSTANT

BTN_DVD_POWERON  = 23
BTN_DVD_POWEROFF = 24
BTN_DVD_STOP     = 13
BTN_DVD_PLAY     = 14
BTN_DVD_PAUSE    = 15

integer btnDVD[] = {
    421, 422, 423, 424, 425, 426, 427, 428, 429, 430, 
    431, 432, 433, 434, 435, 436, 437, 438, 439, 440,
    441, 442, 443, 444
}

char strDVDCode[][3] = {
    'POW', 'EJT', 'HOM', 'TTL', 'MNU', 'SET', 'RET', 'NUP', 'NDN', 'NLT',
    'NRT', 'SEL', 'STP', 'PLA', 'PAU', 'PRE', 'REV', 'FWD', 'NXT', 'AUD',
    'SUB', 'M3D', 'PON', 'POF'
}

DEFINE_VARIABLE

integer gblDvdPlayPauseSwitch = 0
integer gblDVDPowerState
long gTLDVDPolling[] = {500}  // DVD POLLING TIMELINE

DEFINE_FUNCTION updateDVDPowerState (integer pmState)
{
    integer tpId

    for (tpId = length_array(gDvTps); tpId >= 1; tpId--)
    {
        if (gTpStatus[tpId] = TP_STATUS_OFF)
            continue
    }
}

DEFINE_FUNCTION dvdPowerOff(integer tpId)
{
    // to prevent from damaging the dvd, we should stop it first, then
    // poweroff
    //fnQueueTheCommand(dvPJ, "strDVDCode[BTN_DVD_STOP],$0D")
    //wait 50 fnQueueTheCommand(dvPJ, "strDVDCode[BTN_DVD_POWEROFF],$0D")

    send_string dvDVD, "strDVDCode[BTN_DVD_STOP],$0D"
    wait 50
    {
        send_string dvDVD, "strDVDCode[BTN_DVD_POWEROFF],$0D"
    }

    gblDVDPowerState = POWER_MAN_OFF
}

DEFINE_FUNCTION tpDVDBtnSync()
{
    [gDvTps, btnDVD[BTN_DVD_POWERON]] = (gblDVDPowerState == POWER_MAN_ON)
    [gDvTps, btnDVD[BTN_DVD_POWEROFF]] = (gblDVDPowerState != POWER_MAN_ON)
}


DEFINE_MUTUALLY_EXCLUSIVE
//([gDvTps, btnDVD[BTN_DVD_POWERON]], [gDvTps, btnDVD[BTN_DVD_POWEROFF]])

DEFINE_EVENT

BUTTON_EVENT[gDvTps, btnDVD]
{
    PUSH:
    {
        integer idxBtn
        integer tpId

        tpId   = get_last(gDvTps) 
        idxBtn = get_last(btnDVD)

        switch(idxBtn)
        {
            case BTN_DVD_POWERON:
            {
                send_string dvDVD, "strDVDCode[BTN_DVD_POWERON],$0D"
                gblDVDPowerState = POWER_MAN_ON
            }
            case BTN_DVD_POWEROFF:
            {
                send_string dvDVD, "strDVDCode[BTN_DVD_POWEROFF],$0D"
                gblDVDPowerState = POWER_MAN_OFF
            }
            case BTN_DVD_PLAY:
            {
                if (gblDvdPlayPauseSwitch)
                {
                    send_string dvDVD, "strDVDCode[BTN_DVD_PLAY],$0D"
                    gblDvdPlayPauseSwitch = 1
                }
                else
                {
                    send_string dvDVD, "strDVDCode[BTN_DVD_PAUSE],$0D"
                    gblDvdPlayPauseSwitch = 0
                }
            }
            default:
                send_string dvDVD, "strDVDCode[idxBtn],$0D"
        }
    }
}
