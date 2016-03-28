PROGRAM_NAME='ge69_projector'

DEFINE_CONSTANT

PJ_STATE_COOLING  = 2   // cooling need about 100s
PJ_STATE_POWERON  = 1   // power on need about 30s
PJ_STATE_POWEROFF = 0

BTN_PJ_POWERON   = 1
BTN_PJ_POWEROFF  = 2

JVC_INPUT_COMP   = '2'
JVC_INPUT_PC     = '3'
JVC_INPUT_HDMI_1 = '6'
JVC_INPUT_HDMI_2 = '7'

PJ_CMD_SEP       = $0A

// !$89$01IP6$0A
integer btnProjector[] = {
    481, 482, 483
}

LONG gTLPJPolling[] = {500}  // PROJECTOR POLLING TIMELINE

DEFINE_VARIABLE

integer gPJPowerState

volatile char gPjBuf[256]

DEFINE_MUTUALLY_EXCLUSIVE
//([vdvTP, btnProjector[BTN_PJ_POWERON]], [vdvTP, btnProjector[BTN_PJ_POWEROFF]])


DEFINE_FUNCTION jvc_cmdPowerOn()
{
    sendString('JVC', dvPJ, "'!', $89, $01, 'PW1', $0A")
}

DEFINE_FUNCTION jvc_cmdPowerOff()
{
    sendString('JVC', dvPJ, "'!', $89, $01, 'PW0', $0A")
}

DEFINE_FUNCTION jvc_queryPower()
{
    sendString('JVC', dvPJ, "'?',$89,$01,'PW',$0A")
}

DEFINE_FUNCTION jvc_cmdInput(char input)
{
    sendString('JVC', dvPJ, "'!', $89, $01, 'IP', input, $0A")
    //send_string dvPJ, "'!', $89, $01, 'IP6', $0A"
}

// PVC power on need about 30s
DEFINE_FUNCTION projector_opPowerOn()
{
    jvc_queryPower()

    wait 2
    {
        select
        {
            active(gPJPowerState == PJ_STATE_POWEROFF):
            {
                jvc_cmdPowerOn()
                gPJPowerState = PJ_STATE_POWERON

                // switch input to HDMI-1
                // We need give enough time to wait the projector power on
                // finish
                //wait 359 jvc_cmdInput(JVC_INPUT_HDMI_1)
            }
            active(gPJPowerState == PJ_STATE_COOLING):
            {
                // loop wait
                wait 100 projector_opPowerOn()
            }
        }
    }
}

// JVC need about 100s to poweroff(+cooling)
DEFINE_FUNCTION projector_opPowerOff()
{
    jvc_cmdPowerOff()

    gPJPowerState = PJ_STATE_POWEROFF
/*    
    if (!timeline_active(TL_PJ))
    {
        timeline_create(TL_PJ, gTLPJPolling, LENGTH_ARRAY(gTLPJPolling), 
            TIMELINE_ABSOLUTE, TIMELINE_REPEAT)        
    }
*/    
}

DEFINE_FUNCTION tpPJBtnSync()
{
    [gDvTps, btnProjector[BTN_PJ_POWERON]]  = (gPJPowerState == PJ_STATE_POWERON)
    [gDvTps, btnProjector[BTN_PJ_POWEROFF]] = (gPJPowerState != PJ_STATE_POWERON)
}

DEFINE_START
create_buffer dvPJ, gPJBuf

DEFINE_EVENT

DATA_EVENT[dvPJ]
{
    ONLINE :
    {
        debug('JVC', 4, "'JVC projector online'")
        send_command DATA.DEVICE, 'SET MODE DATA'
        send_command DATA.DEVICE, 'SET BAUD 19200,N,8,1,485 DISABLE'
        //send_command DATA.DEVICE, 'RXON'

        // update the status when device online
        jvc_queryPower()
    }

    STRING :
    {
        char reply[128]

        while(find_string(gPJBuf, "PJ_CMD_SEP", 1))
        {
            reply = remove_string(gPJBuf, "PJ_CMD_SEP", 1)
            select
            {
                active (find_string(reply, 'PW2', 1)):
                {
                    gPJPowerState = PJ_STATE_COOLING
                }                
                active (find_string(reply, 'PW1', 1)):
                {
                    gPJPowerState = PJ_STATE_POWERON
                }
                active (find_string(reply, 'PW0', 1)):
                {
                    gPJPowerState = PJ_STATE_POWEROFF
                    //timeline_kill(TL_PJ)
                }

            }            
        }
    }
}

/*
TIMELINE_EVENT[TL_PJ]
{   
    jvc_queryPower()
}
*/

BUTTON_EVENT[gDvTps, btnProjector]
{
    PUSH:
    {
        integer idxBtn

        idxBtn = get_last(btnProjector)
        switch(idxBtn)
        {
            CASE BTN_PJ_POWERON:
            {
                // Well, the relay is only used to indicate we did the action
                [dvRL, 3] = 1
                projector_opPowerOn()
            }
            CASE BTN_PJ_POWEROFF:
            {
                [dvRL, 3] = 0
                projector_opPowerOff()
            }
        }
    }
}
