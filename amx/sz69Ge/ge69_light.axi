PROGRAM_NAME='ge69_light'

DEFINE_CONSTANT

LIGHT_ON                = 1
LIGHT_OFF               = 0

// We use AVB-ABS module control two AVB-DIN-REL8-50 strong electrical
// controlers, the controller' address are configured by AMX software
AVBDIN_RELAY_M1ADDRESS  = 30
AVBDIN_RELAY_M2ADDRESS  = 31

AVBAO8_DIMMER_M1ADDRESS = 40

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
MAX_DIMLEVEL_NUMBER = 8
MAX_DIMLEVEL_VALUE  = 100

DEFINE_VARIABLE

integer btnLight[BTN_LIGHT_MAXNUM] = {
    101,    // strong electrical controller 1, circuit 1
    102,
    103,
    104,
    105,
    106,
    107,
    108,    // strong electrical controller 1, circuit 8
    109,    // strong electrical controller 2, circuit 1
    110,
    111,
    112,
    113,
    114,
    115,
    116     // strong electrical controller 2, circuit 8
}

integer btnLightScene[] = {
    201,
    202,
    203,
    204,
    205,
    206,
    207,
    208
}

integer btnDimLevel[MAX_DIMLEVEL_NUMBER] = {
    301,
    302,
    303,
    304,
    305,
    306,
    307,
    308
}

// scene id, light button index, on(1)/off(0)
char sceneRelayOnMapping[][2] = {
    {BTN_LIGHT_SCENE_1, BTN_LIGHT_M1L7}, {BTN_LIGHT_SCENE_1, BTN_LIGHT_M1L8}, 
    {BTN_LIGHT_SCENE_3, BTN_LIGHT_M1L1}, {BTN_LIGHT_SCENE_3, BTN_LIGHT_M1L2},
    {BTN_LIGHT_SCENE_3, BTN_LIGHT_M1L3}, {BTN_LIGHT_SCENE_3, BTN_LIGHT_M1L4},
    {BTN_LIGHT_SCENE_3, BTN_LIGHT_M1L6}, {BTN_LIGHT_SCENE_3, BTN_LIGHT_M1L7}, 
    {BTN_LIGHT_SCENE_3, BTN_LIGHT_M1L8}, {BTN_LIGHT_SCENE_3, BTN_LIGHT_M2L8},                                        
    {BTN_LIGHT_SCENE_3, BTN_LIGHT_M2L5}, {BTN_LIGHT_SCENE_3, BTN_LIGHT_M2L6},
    {BTN_LIGHT_SCENE_4, BTN_LIGHT_M1L1}, {BTN_LIGHT_SCENE_4, BTN_LIGHT_M1L2},
    {BTN_LIGHT_SCENE_4, BTN_LIGHT_M1L3}, {BTN_LIGHT_SCENE_4, BTN_LIGHT_M1L4},
    {BTN_LIGHT_SCENE_4, BTN_LIGHT_M1L6}, {BTN_LIGHT_SCENE_4, BTN_LIGHT_M1L7}, 
    {BTN_LIGHT_SCENE_4, BTN_LIGHT_M1L8}, {BTN_LIGHT_SCENE_4, BTN_LIGHT_M2L8},                                        
    {BTN_LIGHT_SCENE_4, BTN_LIGHT_M2L5}, {BTN_LIGHT_SCENE_4, BTN_LIGHT_M2L6}   
}

char sceneRelayOffMapping[][2] = { 
    {BTN_LIGHT_SCENE_3, BTN_LIGHT_M1L1}, {BTN_LIGHT_SCENE_3, BTN_LIGHT_M1L2},
    {BTN_LIGHT_SCENE_3, BTN_LIGHT_M1L3}, {BTN_LIGHT_SCENE_3, BTN_LIGHT_M1L4},
    {BTN_LIGHT_SCENE_3, BTN_LIGHT_M1L6}, {BTN_LIGHT_SCENE_3, BTN_LIGHT_M2L8},                                        
    {BTN_LIGHT_SCENE_3, BTN_LIGHT_M2L5}, {BTN_LIGHT_SCENE_3, BTN_LIGHT_M2L6}
}

char gblDimLevelValue[MAX_DIMLEVEL_NUMBER]


DEFINE_MUTUALLY_EXCLUSIVE


// Include AMX AVB-ABS module to control the AMX relays(AVB-DIN-REL8-50)
#INCLUDE 'LightAxi'
DEFINE_MODULE 'LightModule' uMod_Light(vdvAmxLight, dvAMXLight)

DEFINE_FUNCTION fnLightOn(integer index)
{
    integer idxRelay, relayAddr

    if (index <= BTN_LIGHT_M1END)
    {
        relayAddr = AVBDIN_RELAY_M1ADDRESS
        idxRelay = index - BTN_LIGHT_M1START + 1
    }
    else
    {
        relayAddr = AVBDIN_RELAY_M2ADDRESS
        idxRelay = index - BTN_LIGHT_M2START + 1
    }

    fnOn(vdvAMXLight, relayAddr, idxRelay)    
}

DEFINE_FUNCTION fnLightOff(integer index)
{
    integer idxRelay, relayAddr

    if (index <= BTN_LIGHT_M1END)
    {
        relayAddr = AVBDIN_RELAY_M1ADDRESS
        idxRelay = index - BTN_LIGHT_M1START + 1
    }
    else
    {
        relayAddr = AVBDIN_RELAY_M2ADDRESS
        idxRelay = index - BTN_LIGHT_M2START + 1
    }

    fnOff(vdvAMXLight, relayAddr, idxRelay)
}

DEFINE_FUNCTION toggleAlights(integer state)
{
    integer i
    
    if (state == LIGHT_ON)
    {
        for (i = 1; i <= LIGHT_M1_RELAYCNT; i++)
        fnOn(vdvAMXLight, AVBDIN_RELAY_M1ADDRESS, i)
        for (i = 1; i <= LIGHT_M2_RELAYCNT; i++)
        fnOn(vdvAMXLight, AVBDIN_RELAY_M2ADDRESS, i)

        fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 90, 0)
        updateLevelValue(btnDimLevel[1], 90)           
    }
    else
    {
        for (i = 1; i <= LIGHT_M1_RELAYCNT; i++)
        fnOff(vdvAMXLight, AVBDIN_RELAY_M1ADDRESS, i)
        for (i = 1; i <= LIGHT_M2_RELAYCNT; i++)
        fnOff(vdvAMXLight, AVBDIN_RELAY_M2ADDRESS, i)

        fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 0, 0)
        updateLevelValue(btnDimLevel[1], 0)           
    }
}

// inverse: inverse the light action of mapping request
DEFINE_FUNCTION lightSceneAc(char map[][], integer sceneId, char lightOn)
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

DEFINE_FUNCTION tpLightSceneOn(integer idx)
{
    lightSceneAc(sceneRelayOnMapping, idx, 1)
    tpArrayOn(btnLightScene[idx])    
}

// index: the light index of the button array
// return: 0 - off, 1 - on
DEFINE_FUNCTION integer fnLightStatus(integer index)
{
    integer idxRelay, relayAddr

    if (index <= BTN_LIGHT_M1END)
    {
        relayAddr = AVBDIN_RELAY_M1ADDRESS
        idxRelay = index - BTN_LIGHT_M1START + 1
    }
    else
    {
        relayAddr = AVBDIN_RELAY_M2ADDRESS
        idxRelay = index - BTN_LIGHT_M2START + 1
    }

    return _sDevSts[relayAddr][1].nVal[idxRelay] 
}


DEFINE_FUNCTION tpLightBtnSync(tpId)
{
    [gDvTps[tpId], btnLight[BTN_LIGHT_M1L1]] = _sDevSts[AVBDIN_RELAY_M1ADDRESS][1].nVal[BTN_LIGHT_M1L1]
    [gDvTps[tpId], btnLight[BTN_LIGHT_M1L2]] = _sDevSts[AVBDIN_RELAY_M1ADDRESS][1].nVal[BTN_LIGHT_M1L2]
    [gDvTps[tpId], btnLight[BTN_LIGHT_M1L3]] = _sDevSts[AVBDIN_RELAY_M1ADDRESS][1].nVal[BTN_LIGHT_M1L3]
    [gDvTps[tpId], btnLight[BTN_LIGHT_M1L4]] = _sDevSts[AVBDIN_RELAY_M1ADDRESS][1].nVal[BTN_LIGHT_M1L4]
    [gDvTps[tpId], btnLight[BTN_LIGHT_M1L5]] = _sDevSts[AVBDIN_RELAY_M1ADDRESS][1].nVal[BTN_LIGHT_M1L5]
    [gDvTps[tpId], btnLight[BTN_LIGHT_M1L6]] = _sDevSts[AVBDIN_RELAY_M1ADDRESS][1].nVal[BTN_LIGHT_M1L6]
    [gDvTps[tpId], btnLight[BTN_LIGHT_M1L7]] = _sDevSts[AVBDIN_RELAY_M1ADDRESS][1].nVal[BTN_LIGHT_M1L7]
    [gDvTps[tpId], btnLight[BTN_LIGHT_M1L8]] = _sDevSts[AVBDIN_RELAY_M1ADDRESS][1].nVal[BTN_LIGHT_M1L8]
    [gDvTps[tpId], btnLight[BTN_LIGHT_M2L1]] = _sDevSts[AVBDIN_RELAY_M2ADDRESS][1].nVal[BTN_LIGHT_M2L1-BTN_LIGHT_M2START+1]
    [gDvTps[tpId], btnLight[BTN_LIGHT_M2L2]] = _sDevSts[AVBDIN_RELAY_M2ADDRESS][1].nVal[BTN_LIGHT_M2L2-BTN_LIGHT_M2START+1]
    [gDvTps[tpId], btnLight[BTN_LIGHT_M2L3]] = _sDevSts[AVBDIN_RELAY_M2ADDRESS][1].nVal[BTN_LIGHT_M2L3-BTN_LIGHT_M2START+1]
    [gDvTps[tpId], btnLight[BTN_LIGHT_M2L4]] = _sDevSts[AVBDIN_RELAY_M2ADDRESS][1].nVal[BTN_LIGHT_M2L4-BTN_LIGHT_M2START+1]
    [gDvTps[tpId], btnLight[BTN_LIGHT_M2L5]] = _sDevSts[AVBDIN_RELAY_M2ADDRESS][1].nVal[BTN_LIGHT_M2L5-BTN_LIGHT_M2START+1]
    [gDvTps[tpId], btnLight[BTN_LIGHT_M2L6]] = _sDevSts[AVBDIN_RELAY_M2ADDRESS][1].nVal[BTN_LIGHT_M2L6-BTN_LIGHT_M2START+1]
    [gDvTps[tpId], btnLight[BTN_LIGHT_M2L7]] = _sDevSts[AVBDIN_RELAY_M2ADDRESS][1].nVal[BTN_LIGHT_M2L7-BTN_LIGHT_M2START+1]
    [gDvTps[tpId], btnLight[BTN_LIGHT_M2L8]] = _sDevSts[AVBDIN_RELAY_M2ADDRESS][1].nVal[BTN_LIGHT_M2L8-BTN_LIGHT_M2START+1] 
}

DEFINE_EVENT

DATA_EVENT[vdvAmxLight]
{
    ONLINE:
    {
        /* query light status, and update the light variables */
    }
}

BUTTON_EVENT[gDvTps, btnLight]
{
    PUSH:
    {
        integer idxBtn;
    
        idxBtn = get_last(btnLight)
        select
        {
            active (idxBtn >= BTN_LIGHT_M1START && idxBtn <= BTN_LIGHT_MNEND):
            {

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
    }
}

BUTTON_EVENT[gDvTps, btnLightScene]
{
    PUSH:
    {
        integer idxBtn, i
        integer tpId

        tpId   = get_last(gDvTps)    
        idxBtn = get_last(btnLightScene)
        switch(idxBtn)
        {
            case BTN_LIGHT_ALL_ON:
                toggleAlights(LIGHT_ON)
            case BTN_LIGHT_ALL_OFF:
                toggleAlights(LIGHT_OFF)          
            case BTN_LIGHT_SCENE_2:
            {
                cancel_wait 'W_LSCENE2_DOOROFF'
                fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 0, 0)
                updateLevelValue(btnDimLevel[1], 0)
                for (i = BTN_LIGHT_MAXNUM; i > 0; i--)
                {
                    if (i != BTN_LIGHT_M1L5) fnLightOff(i)
                }
                // wait 30s so that we have time to lock the door
                wait 300 'W_LSCENE2_DOOROFF' fnLightOff(BTN_LIGHT_M1L5)
            }
            case BTN_LIGHT_SCENE_3:
                // buttons with channel type should be defined here
                if ([gDvTps[tpId], BUTTON.INPUT.CHANNEL] == 0)
                {
                    lightSceneAc(sceneRelayOnMapping, idxBtn, 1)
                    tpArrayOn(btnLightScene[idxBtn])
                }
                else
                {
                    lightSceneAc(sceneRelayOffMapping, idxBtn, 0)
                    tpArrayOff(btnLightScene[idxBtn])
                }
            default:
            {
                lightSceneAc(sceneRelayOnMapping, idxBtn, 1)
                tpArrayOn(btnLightScene[idxBtn])
            }   
        }
    }
}

BUTTON_EVENT[gDvTps, btnDimLevel]
{
    RELEASE:
    {
        integer i 

        i = get_last(btnDimLevel)

        fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, i, gblDimLevelValue[i], 0)
    }
    // The dimmer should be changed when drag the level
    HOLD[1, REPEAT]:
    {
        integer i 

        i = get_last(btnDimLevel)

        fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, i, gblDimLevelValue[i], 0)
    }
}

LEVEL_EVENT[gDvTps, btnDimLevel]
{
    integer i;
    
    i = get_last(btnDimLevel)
    
    gblDimLevelValue[i] = LEVEL.VALUE
}

DEFINE_PROGRAM
