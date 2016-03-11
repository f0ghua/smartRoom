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

DEFINE_FUNCTION dvdPowerOff()
{
    // to prevent from damaging the dvd, we should stop it first, then
    // poweroff
    do_push(vdvTP, btnDVD[BTN_DVD_STOP])
    wait 50
    {
        do_push(vdvTP, btnDVD[BTN_DVD_POWEROFF])
    }
}

DEFINE_MUTUALLY_EXCLUSIVE
([vdvTP, btnDVD[BTN_DVD_POWERON]], [vdvTP, btnDVD[BTN_DVD_POWEROFF]])

DEFINE_EVENT

BUTTON_EVENT[vdvTP, btnDVD]
{
    PUSH:
    {
        integer idxBtn

        idxBtn = get_last(btnDVD)
        ON[vdvTP, BUTTON.INPUT.CHANNEL]
        switch(idxBtn)
        {
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
