PROGRAM_NAME='ge69_gf'

DEFINE_CONSTANT

BTN_GF_POWERON  = 1
BTN_GF_POWEROFF = 2

integer btnGF[] = {
    501, 502, 503, 504
}

integer btnSLI[] = {
    1000, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010
}

integer btnLMD[] = {
    2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010
}

DEFINE_MUTUALLY_EXCLUSIVE
([vdvTP, btnGF[BTN_GF_POWERON]], [vdvTP, btnGF[BTN_GF_POWEROFF]])

DEFINE_MODULE'ModGfIntegra' uMod_GF(dvGF, vdGF)

DEFINE_EVENT

BUTTON_EVENT[vdvTP, btnGF]
{
    PUSH:
    {
        ON[vdvTP, BUTTON.INPUT.CHANNEL]
        do_push(vdGF, GET_LAST(btnGF))
    }
}

BUTTON_EVENT[vdvTP, btnLMD]
{
    PUSH:
    {
        OFF[vdvTP, btnLMD]
        ON[vdvTP, BUTTON.INPUT.CHANNEL]
        SEND_LEVEL vdGF, 1, GET_LAST(btnLMD)
    }
}

BUTTON_EVENT[vdvTP, btnSLI]
{
    PUSH:
    {
        OFF[vdvTP, btnSLI]
        ON[vdvTP, BUTTON.INPUT.CHANNEL]
        SEND_LEVEL vdGF, 2, get_last(btnSLI)
    }
}

