PROGRAM_NAME='ge69_gf'

DEFINE_CONSTANT

BTN_GF_POWERON  = 1
BTN_GF_POWEROFF = 2
BTN_GF_VOLUP    = 3
BTN_GF_VOLDOWN  = 4

integer btnGF[] = {
    501, 502, 503, 504
}

integer btnSLI[] = {
    1000, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010
}

integer btnLMD[] = {
    2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010
}

DEFINE_VARIABLE

integer gGfPowerState

DEFINE_MUTUALLY_EXCLUSIVE
//([gDvTps, btnGF[BTN_GF_POWERON]], [gDvTps, btnGF[BTN_GF_POWEROFF]])

DEFINE_MODULE'ModGfIntegra' uMod_GF(dvGF, vdGF)

DEFINE_FUNCTION gf_opPowerOn()
{
    send_string dvGF, "'!1PWR01', $0D"
    gGfPowerState = POWER_MAN_ON
}

DEFINE_FUNCTION gf_opPowerOff()
{
    send_string dvGF, "'!1PWR00', $0D"
    gGfPowerState = POWER_MAN_OFF
}


DEFINE_FUNCTION tpGFBtnSync()
{
    [gDvTps, btnGF[BTN_GF_POWERON]] = (gGfPowerState == POWER_MAN_ON)
    [gDvTps, btnGF[BTN_GF_POWEROFF]] = (gGfPowerState == POWER_MAN_OFF)
}

DEFINE_START

DEFINE_EVENT

BUTTON_EVENT[gDvTps, btnGF]
{
    PUSH:
    {
        integer tpId

        tpId   = get_last(gDvTps)
        switch(get_last(btnGF))
        {  
            case BTN_GF_POWERON:
                gf_opPowerOn()
            case BTN_GF_POWEROFF:
                gf_opPowerOff()
            default:
            {
                tpArrayOn(button.input.channel)
                do_push(vdGF, GET_LAST(btnGF))
            }
        }
    }
    HOLD[1, REPEAT]:
    {
        switch(get_last(btnGF))
        {
            case BTN_GF_VOLUP:
                send_string dvGF, "'!1MVLUP', $0D"
            case BTN_GF_VOLDOWN:
                send_string dvGF, "'!1MVLDOWN', $0D"
        }
    }
}

BUTTON_EVENT[gDvTps, btnLMD]
{
    PUSH:
    {
        integer tpId, i

        tpId = get_last(gDvTps)          
        for (i = length_array(btnLMD); i > 0; i--)
            tpArrayOff(btnLMD[i])
        tpArrayOn(button.input.channel)
        send_level vdGF, 1, GET_LAST(btnLMD)
    }
}

BUTTON_EVENT[gDvTps, btnSLI]
{
    PUSH:
    {
        integer tpId, i

        tpId = get_last(gDvTps)    
        for (i = length_array(btnSLI); i > 0; i--)       
            tpArrayOff(btnSLI[i])
        tpArrayOn(button.input.channel)
        send_level vdGF, 2, get_last(btnSLI)
    }
}

