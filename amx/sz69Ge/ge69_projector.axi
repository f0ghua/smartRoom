PROGRAM_NAME='ge69_projector'

DEFINE_CONSTANT

BTN_PJ_POWERON   = 1
BTN_PJ_POWEROFF  = 2

integer btnProjector[] = {
    481, 482, 483
}

DEFINE_VARIABLE

#INCLUDE 'IncModCool'
DEFINE_MODULE'ModCool' uMdCool(vdMod, aMdDev, aMdA)

DEFINE_CALL 'RfTySn'(CHAR DvID, CHAR DoID)
{
    CALL 'fnDoTy'(dvPJ, TyTpJVC, DoID)
}

DEFINE_MUTUALLY_EXCLUSIVE
([vdvTP, btnProjector[BTN_PJ_POWERON]], [vdvTP, btnProjector[BTN_PJ_POWEROFF]])

DEFINE_EVENT

BUTTON_EVENT[vdvTP, btnProjector]
{
    PUSH:
    {
        char i

        ON[vdvTP, BUTTON.INPUT.CHANNEL]
        i = type_cast(get_last(btnProjector))
        switch(i)
        {
            CASE 1: 
            {
                // Well, the relay is only used to indicate we did the action
                [dvRL, 3] = 1
                CALL 'RfTySn'(1, i)
            }
            CASE 2: 
            {
                [dvRL, 3] = 0
                CALL 'RfTySn'(1, i)
            }
        }
    }
}
