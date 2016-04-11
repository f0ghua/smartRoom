PROGRAM_NAME='ge69_light'

DEFINE_DEVICE

dvAmxLight              = 5001:2:0
vdvAmxLight             = 34101:1:0 // the number should sync with 'LightAxi.axi'

DEFINE_TYPE

structure _sShadeAddr
{
    integer addr
    integer relay
}

DEFINE_CONSTANT

LIGHT_ON                = 1
LIGHT_OFF               = 0

// We use AVB-ABS module control 6 AVB-DIN-REL8-50 strong electrical
// controlers, the controller' address are configured by AMX software
AVBDIN_RELAY_M1ADDRESS  = 30
AVBDIN_RELAY_M2ADDRESS  = 31
AVBDIN_RELAY_M3ADDRESS  = 32
AVBDIN_RELAY_M4ADDRESS  = 33
AVBDIN_RELAY_M5ADDRESS  = 34
AVBDIN_RELAY_M6ADDRESS  = 35

AVBDIN_RELAY_MXNUMBER   = 6
AVBDIN_RELAY_CIRSNUM    = 8 // circuit numbers each module

AVBDIN_RELAY_MAXNUM     = (AVBDIN_RELAY_MXNUMBER*AVBDIN_RELAY_CIRSNUM)

integer avbRelayAddr[] = {
    30, 31, 32, 33, 34, 35
}

integer avbIOAddr[] = {
    60, 64, 68
}

// The light buttons' index on TP, since we use 2 relay controlers, so 'M1'
// means controller 1, 'M2' means controller 2. 'L1' means line 1 (or circuit
// 1).
BTN_LIGHT_M1START   = 1
BTN_LIGHT_M1L1      = 1     // porch light
BTN_LIGHT_M1L2      = 2     // fireplace light
BTN_LIGHT_M1L3      = 3     // booth light
BTN_LIGHT_M1L4      = 4     // office background light
BTN_LIGHT_M1L5      = 5     // door light
BTN_LIGHT_M1L6      = 6     // floor light
BTN_LIGHT_M1L7      = 7     // logo light
BTN_LIGHT_M1L8      = 8     // working light
BTN_LIGHT_M1END     = BTN_LIGHT_M1L8
LIGHT_M1_RELAYCNT   = (BTN_LIGHT_M1END - BTN_LIGHT_M1START + 1)

BTN_LIGHT_M2START   = 9
BTN_LIGHT_M2L1      = 9     // cinema atmosphere light  
BTN_LIGHT_M2L2      = 10    // tea room light
BTN_LIGHT_M2L3      = 11    // show window light
BTN_LIGHT_M2L4      = 12    // cinema background light
BTN_LIGHT_M2L5      = 13    // sofa area light
BTN_LIGHT_M2L6      = 14    // equipment room light
BTN_LIGHT_M2L7      = 15    // starry sky light
BTN_LIGHT_M2L8      = 16    // rest room light
BTN_LIGHT_M2END     = BTN_LIGHT_M2L8
LIGHT_M2_RELAYCNT   = (BTN_LIGHT_M2END - BTN_LIGHT_M2START + 1)

BTN_LIGHT_MNEND     = BTN_LIGHT_M2END
BTN_LIGHT_MAXNUM    = BTN_LIGHT_MNEND

// Lights all on and all off
BTN_LIGHT_ALL_ON    = 1
BTN_LIGHT_ALL_OFF   = 2

BTN_LIGHT_SCENE_1   = 3     // work
BTN_LIGHT_SCENE_2   = 4     // leave
BTN_LIGHT_SCENE_3   = 5     // visit
BTN_LIGHT_SCENE_4   = 6     // clean

MAX_LIGHT_SCENE_NUM = 8

BTN_CURTAIN_F2MR_BOPEN  = 1
BTN_CURTAIN_F2MR_BCLOSE = 2
BTN_CURTAIN_F2MR_BSTOP  = 3
BTN_CURTAIN_F2MR_SOPEN  = 4
BTN_CURTAIN_F2MR_SCLOSE = 5
BTN_CURTAIN_F2MR_SSTOP  = 6
BTN_CURTAIN_F3MR_BOPEN  = 7
BTN_CURTAIN_F3MR_BCLOSE = 8
BTN_CURTAIN_F3MR_BSTOP  = 9
BTN_CURTAIN_F3MR_SOPEN  = 10
BTN_CURTAIN_F3MR_SCLOSE = 11
BTN_CURTAIN_F3MR_SSTOP  = 12

DEFINE_VARIABLE

integer aShadeAddr[][2] = {
    {32, 5}, {32, 6}, {32, 7}, {32, 8},
    {33, 3}, {33, 4}, {33, 5}, {33, 6}
}

integer btnLight[] = {
    101, 102, 103, 104, 105, 106, 107, 108,
    111, 112, 113, 114, 115, 116, 117, 118,
    121, 122, 123, 124, 125, 126, 127, 128,
    131, 132, 133, 134, 135, 136, 137, 138,
    141, 142, 143, 144, 145, 146, 147, 148,
    151, 152, 153, 154, 155, 156, 157, 158
}

integer btnCurtain[] = {
    161, 162, 163, 164, 165, 166, 167, 168,
    169, 170, 171, 172, 173, 174, 175, 176
}

integer btnDimmer[] = {
    1001, 1002, 1003, 1004
}

integer btnLightScene[] = {
    3000
}

DEFINE_MUTUALLY_EXCLUSIVE

// Include AMX AVB-ABS module to control the AMX relays(AVB-DIN-REL8-50)
#INCLUDE 'LightAxi'
DEFINE_MODULE 'LightModule' uMod_Light(vdvAmxLight, dvAMXLight)

define_function fnLightOn(integer index)
{
    integer idxRelay, idxAddr, relayAddr

    idxRelay = index%AVBDIN_RELAY_CIRSNUM
    idxAddr = index/AVBDIN_RELAY_CIRSNUM + 1

    if (idxRelay == 0)
    {
        idxRelay = 8
        idxAddr = idxAddr -1
    }

    relayAddr = avbRelayAddr[idxAddr]

    debug('light', 8, "'on: relayAddr = ', itoa(relayAddr), 'idxRelay = ', itoa(idxRelay)")
    fnOn(vdvAMXLight, relayAddr, idxRelay)
}

define_function fnLightOff(integer index)
{
    integer idxRelay, idxAddr, relayAddr

    idxRelay = index%AVBDIN_RELAY_CIRSNUM
    idxAddr = index/AVBDIN_RELAY_CIRSNUM + 1

    if (idxRelay == 0)
    {
        idxRelay = 8
        idxAddr = idxAddr -1
    }

    relayAddr = avbRelayAddr[idxAddr]

    debug('light', 8, "'off: relayAddr = ', itoa(relayAddr), 'idxRelay = ', itoa(idxRelay)")
    fnOff(vdvAMXLight, relayAddr, idxRelay)
}

define_function light_toggle(integer relayAddr, integer idxRelay)
{
    debug('light', 8, "'toggle: relayAddr = ', itoa(relayAddr), ' idxRelay = ', itoa(idxRelay)")
    if (_sDevSts[relayAddr][1].nVal[idxRelay])
    {
        fnOff(vdvAMXLight, relayAddr, idxRelay)
    }
    else
    {
        fnOn(vdvAMXLight, relayAddr, idxRelay)
    }
}

define_function light_dimToggle(integer relayAddr, integer idxRelay)
{
    debug('light', 8, "'toggle: relayAddr = ', itoa(relayAddr), ' idxRelay = ', itoa(idxRelay)")
    if (_sDevSts[relayAddr][1].nVal[idxRelay])
    {
        fnDimLevel(vdvAmxLight, relayAddr, idxRelay, 0, 0)
    }
    else
    {
        fnDimLevel(vdvAmxLight, relayAddr, idxRelay, 100, 0)
    }
}

define_function char isLightRelay(integer relayAddr, integer idxRelay)
{
    integer i

    for (i = length_array(aShadeAddr); i >= 1; i--)
    {
        if ((aShadeAddr[i][1] == relayAddr) && 
            (aShadeAddr[i][2] == idxRelay))
            return false
    }

    return true
}

define_function light_toggleAlights(integer state)
{
    integer idxRelay, idxAddr, relayAddr
    integer lightChIdx

    for (lightChIdx = AVBDIN_RELAY_MAXNUM; lightChIdx >= 1; lightChIdx--)
    {
        idxRelay = lightChIdx%AVBDIN_RELAY_CIRSNUM
        idxAddr = lightChIdx/AVBDIN_RELAY_CIRSNUM + 1
        if (idxRelay == 0)
        {
            idxRelay = 8
            idxAddr = idxAddr -1
        }
        relayAddr = avbRelayAddr[idxAddr]
        
        if (!isLightRelay(relayAddr, idxRelay))
            continue

        if (state == LIGHT_ON)
            fnOn(vdvAMXLight, relayAddr, idxRelay)
        else
            fnOff(vdvAMXLight, relayAddr, idxRelay)
    }  
}

define_function light_sceneLeaveHome()
{
    integer idxRelay, idxAddr, relayAddr
    integer lightChIdx

    cancel_wait 'W_LS_LEAVEHOME'
    for (lightChIdx = AVBDIN_RELAY_MAXNUM; lightChIdx >= 1; lightChIdx--)
    {
        idxRelay = lightChIdx%AVBDIN_RELAY_CIRSNUM
        idxAddr = lightChIdx/AVBDIN_RELAY_CIRSNUM + 1
        if (idxRelay == 0)
        {
            idxRelay = 8
            idxAddr = idxAddr -1
        }
        relayAddr = avbRelayAddr[idxAddr]
        
        if (!isLightRelay(relayAddr, idxRelay))
            continue

        if ((relayAddr == 31) && (idxRelay == 4))
        {
            wait 50 'W_LS_LEAVEHOME' fnOff(vdvAMXLight, 31, 4)
        }
        else
            fnOff(vdvAMXLight, relayAddr, idxRelay)
    }
}

define_function light_sceneAllAct(char flagOn)
{
    integer idxRelay, idxAddr, relayAddr
    integer lightChIdx

    for (lightChIdx = AVBDIN_RELAY_MAXNUM; lightChIdx >= 1; lightChIdx--)
    {
        idxRelay = lightChIdx%AVBDIN_RELAY_CIRSNUM
        idxAddr = lightChIdx/AVBDIN_RELAY_CIRSNUM + 1
        if (idxRelay == 0)
        {
            idxRelay = 8
            idxAddr = idxAddr -1
        }
        relayAddr = avbRelayAddr[idxAddr]
        
        if (!isLightRelay(relayAddr, idxRelay))
            continue

        if (flagOn)
            fnOn(vdvAMXLight, relayAddr, idxRelay)
        else
            fnOff(vdvAMXLight, relayAddr, idxRelay)
    }
}

define_function light_sceneBackHome()
{
    cancel_wait 'W_LS_LEAVEHOME'
    fnOn(vdvAMXLight, 31, 4)
    fnOn(vdvAMXLight, 31, 7)
    fnOn(vdvAMXLight, 30, 8)
}

// inverse: inverse the light action of mapping request
define_function lightSceneAc(char map[][], integer sceneId, char lightOn)
{
    integer i, j

    //SEND_STRING 0,"'***LightTrace*** DO lightSceneAc', itoa(sceneId), itoa(MAX_LENGTH_ARRAY(map))"
    for (i = 1; i <= BTN_LIGHT_MNEND; i++)
    {
        integer relayAddr
        char isExit

        isExit = false
        for (j = 1; j <= MAX_LENGTH_ARRAY(map); j++)
        {
            if ((map[j][1] == sceneId) && 
                (map[j][2] == i))
            {
                //SEND_STRING 0,"'***LightTrace*** Found light scene ', itoa(sceneId), itoa(i)"
                isExit = true
            }
        }

        if (isExit)
        {
            if (lightOn == 1)
            {
                fnLightOn(i)
            }
            else
            {
                fnLightOff(i)
            }
        }
    }
}

// index: the light index of the button array
// return: 0 - off, 1 - on
define_function integer fnLightStatus(integer index)
{
    integer idxRelay, idxAddr, relayAddr

    idxRelay = index%AVBDIN_RELAY_CIRSNUM
    idxAddr = index/AVBDIN_RELAY_CIRSNUM + 1

    if (idxRelay == 0)
    {
        idxRelay = 8
        idxAddr = idxAddr -1
    }

    relayAddr = avbRelayAddr[idxAddr]

    debug('light', 8, "'sts: relayAddr = ', itoa(relayAddr), 'idxRelay = ', itoa(idxRelay)")
    return _sDevSts[relayAddr][1].nVal[idxRelay] 
}

// floor 3, master bedroom Shalian
// 33-3 open, 33-4 close
define_function curtain_shalianF3MROpen()
{
    cancel_wait 'W_CSF3MR_Open'
    fnOff(vdvAMXLight, 33, 4)
    wait 5 'W_CSF3MR_Open' fnOn(vdvAMXLight, 33, 3)
}

define_function curtain_shalianF3MRClose()
{
    cancel_wait 'W_CSF3MR_Close'
    fnOff(vdvAMXLight, 33, 3)
    wait 5 'W_CSF3MR_Close' fnOn(vdvAMXLight, 33, 4)
}

define_function curtain_shalianF3MRStop()
{
    fnOff(vdvAMXLight, 33, 3)
    fnOff(vdvAMXLight, 33, 4)
}

// floor 3, master bedroom shade curtain
// 33-5 open, 33-6 close
define_function curtain_shadeF3MROpen()
{
    cancel_wait 'W_CBF3MR_Open'
    fnOff(vdvAMXLight, 33, 5)
    wait 5 'W_CBF3MR_Open' fnOn(vdvAMXLight, 33, 6)
}

define_function curtain_shadeF3MRClose()
{
    cancel_wait 'W_CBF3MR_Close'
    fnOff(vdvAMXLight, 33, 6)
    wait 5 'W_CBF3MR_Close' fnOn(vdvAMXLight, 33, 5)
}

define_function curtain_shadeF3MRStop()
{
    fnOff(vdvAMXLight, 33, 5)
    fnOff(vdvAMXLight, 33, 6)
}

// floor 2, master bedroom Shalian
// 32-5 open, 33-6 close
define_function curtain_shalianF2MROpen()
{
    cancel_wait 'W_CSF2MR_Open'
    fnOff(vdvAMXLight, 32, 5)
    wait 5 'W_CSF2MR_Open' fnOn(vdvAMXLight, 32, 6)
}

define_function curtain_shalianF2MRClose()
{
    cancel_wait 'W_CSF2MR_Close'
    fnOff(vdvAMXLight, 32, 6)
    wait 5 'W_CSF2MR_Close' fnOn(vdvAMXLight, 32, 5)
}

define_function curtain_shalianF2MRStop()
{
    fnOff(vdvAMXLight, 32, 5)
    fnOff(vdvAMXLight, 32, 6)
}

// floor 2, master bedroom shade curtain
// 32-7 open, 32-8 close
define_function curtain_shadeF2MROpen()
{
    cancel_wait 'W_CBF2MR_Open'
    fnOff(vdvAMXLight, 32, 7)
    wait 5 'W_CBF2MR_Open' fnOn(vdvAMXLight, 32, 8)
}

define_function curtain_shadeF2MRClose()
{
    cancel_wait 'W_CBF2MR_Close'
    fnOff(vdvAMXLight, 32, 8)
    wait 5 'W_CBF2MR_Close' fnOn(vdvAMXLight, 32, 7)
}

define_function curtain_shadeF2MRStop()
{
    fnOff(vdvAMXLight, 32, 7)
    fnOff(vdvAMXLight, 32, 8)
}

define_function curtain_F3MROpen()
{
    curtain_shadeF3MROpen()
    curtain_shalianF3MROpen()
}

define_function curtain_F2MROpen()
{
    curtain_shadeF2MROpen()
    curtain_shalianF2MROpen()
}

define_function curtain_F3MRClose()
{
    curtain_shadeF3MRClose()
    curtain_shalianF3MRClose()
}

define_function curtain_F2MRClose()
{
    curtain_shadeF2MRClose()
    curtain_shalianF2MRClose()
}

define_function tpLightBtnSync(tpId)
{
    integer idxRelay, idxAddr, relayAddr
    integer lightChIdx

    for (lightChIdx = AVBDIN_RELAY_MAXNUM; lightChIdx >= 1; lightChIdx--)
    {
        idxRelay = lightChIdx%AVBDIN_RELAY_CIRSNUM
        idxAddr = lightChIdx/AVBDIN_RELAY_CIRSNUM + 1
        if (idxRelay == 0)
        {
            idxRelay = 8
            idxAddr = idxAddr -1
        }
        relayAddr = avbRelayAddr[idxAddr]
        /*
        debug('light', 8, 
            "'lightChIdx = ', itoa(lightChIdx), 
            ', relayAddr = ', itoa(relayAddr),
            ', idxRelay = ', itoa(idxRelay),
            ', val = ', itoa(_sDevSts[relayAddr][1].nVal[idxRelay])")
        */
        [gDvTps[tpId], btnLight[lightChIdx]] = _sDevSts[relayAddr][1].nVal[idxRelay]        
    }

    for (lightChIdx = length_array(btnDimmer); lightChIdx >= 1; lightChIdx--)
    {
        idxRelay = lightChIdx
        [gDvTps[tpId], btnDimmer[lightChIdx]] = _sDevSts[40][1].nVal[idxRelay]
    }

}

DEFINE_START
/*
{
    integer i, j

    for (i = 30; i <= 39; i++)
    {
        for (j = 1; j <= 8; j++)
        {
            send_command vdvAmxLight, "'BtnSts', itoa(i), '-', itoa(j), '-0*'"
        }
    }
}
*/

DEFINE_EVENT

DATA_EVENT[vdvAmxLight]
{
    ONLINE:
    {
        send_command data.device, 'SET MODE DATA'
        send_command data.device, 'SET BAUD 9600,N,8,1,485 DISABLE'
    }
}

BUTTON_EVENT[gDvTps, btnLight]
{
    PUSH:
    {
        integer idxBtn;
    
        idxBtn = get_last(btnLight)

        if (!fnLightStatus(idxBtn))
        {
            fnLightOn(idxBtn)
        }
        else
        {
            fnLightOff(idxBtn)
        }
    }
}

BUTTON_EVENT[gDvTps, btnDimmer]
{
    PUSH:
    {
        integer idxBtn;
    
        idxBtn = get_last(btnDimmer)

        light_dimToggle(40, idxBtn)
    }
}

BUTTON_EVENT[gDvTps, btnCurtain]
{
    PUSH:
    {
        integer idxBtn;
    
        idxBtn = get_last(btnCurtain)

        switch(idxBtn)
        {
            case BTN_CURTAIN_F2MR_BOPEN:
                curtain_shadeF2MROpen()
            case BTN_CURTAIN_F2MR_BCLOSE:
                curtain_shadeF2MRClose()
            case BTN_CURTAIN_F2MR_BSTOP:
                curtain_shadeF2MRStop()
            case BTN_CURTAIN_F2MR_SOPEN:
                curtain_shalianF2MROpen()
            case BTN_CURTAIN_F2MR_SCLOSE:
                curtain_shalianF2MRClose()
            case BTN_CURTAIN_F2MR_SSTOP:
                curtain_shalianF2MRStop()

            case BTN_CURTAIN_F3MR_BOPEN:
                curtain_shadeF3MROpen()
            case BTN_CURTAIN_F3MR_BCLOSE:
                curtain_shadeF3MRClose()
            case BTN_CURTAIN_F3MR_BSTOP:
                curtain_shadeF3MRStop()
            case BTN_CURTAIN_F3MR_SOPEN:
                curtain_shalianF3MROpen()
            case BTN_CURTAIN_F3MR_SCLOSE:
                curtain_shalianF3MRClose()
            case BTN_CURTAIN_F3MR_SSTOP:
                curtain_shalianF3MRStop()
        }
    }
}

DEFINE_PROGRAM
