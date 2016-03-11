PROGRAM_NAME='ge69_light'

DEFINE_CONSTANT

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

integer btnLight[] = {
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

            if (i <= LIGHT_M1_RELAYCNT)
            {
                relayAddr = AVBDIN_RELAY_M1ADDRESS
                j = i
            }
            else
            {
                relayAddr = AVBDIN_RELAY_M2ADDRESS
                j = i - LIGHT_M1_RELAYCNT
            }

            if (lightOn == 1)
            {
                fnOn(vdvAMXLight, relayAddr, j)
                ON[vdvTP, btnLight[i]]     
                ON[vdvTP, btnLightScene[sceneId]] 
            }
            else
            {
                fnOff(vdvAMXLight, relayAddr, j)
                OFF[vdvTP, btnLight[i]]
                OFF[vdvTP, btnLightScene[sceneId]]
            }
        }
    }                
}

DEFINE_MUTUALLY_EXCLUSIVE

// Include AMX AVB-ABS module to control the AMX relays(AVB-DIN-REL8-50)
#INCLUDE 'liteLightAxi'
DEFINE_MODULE 'LightModule' uMod_Light(vdvAmxLight, dvAMXLight)

DEFINE_EVENT

BUTTON_EVENT[vdvTP, btnLight]
{
    PUSH:
    {
        integer idxBtn;
    
        idxBtn = get_last(btnLight)
        select
        {
            active (idxBtn >= BTN_LIGHT_M1START && 
                idxBtn <= BTN_LIGHT_MNEND):
            {
                integer addrModule
                integer idxBase
                integer idxRelay
                
                if (idxBtn <= BTN_LIGHT_M1END)
                {
                    addrModule = AVBDIN_RELAY_M1ADDRESS
                    idxBase = BTN_LIGHT_M1START
                }
                else
                {
                    addrModule = AVBDIN_RELAY_M2ADDRESS
                    idxBase = BTN_LIGHT_M2START
                }
                idxRelay = idxBtn - idxBase + 1

                if (![vdvTP, BUTTON.INPUT.CHANNEL])
                {
                    fnOn(vdvAMXLight, addrModule, idxRelay)
                }
                else
                {
                    fnOff(vdvAMXLight, addrModule, idxRelay)
                }

                // The best method is indicating the button status according
                // to light  operation feedback on the EVENT routing, but I
                // don't know how...
                [vdvTP, BUTTON.INPUT.CHANNEL] = ![vdvTP, BUTTON.INPUT.CHANNEL]
            }    
        }
    }
}

BUTTON_EVENT[vdvTP, btnLightScene]
{
    PUSH:
    {
        integer idxBtn, i
    
        idxBtn = get_last(btnLightScene)
        switch(idxBtn)
        {
            case BTN_LIGHT_ALL_ON:
            {
                for (i = 1; i <= LIGHT_M1_RELAYCNT; i++)
                    fnOn(vdvAMXLight, AVBDIN_RELAY_M1ADDRESS, i)
                for (i = 1; i <= LIGHT_M2_RELAYCNT; i++)
                    fnOn(vdvAMXLight, AVBDIN_RELAY_M2ADDRESS, i)
                ON[vdvTP, btnLight]
            }
            case BTN_LIGHT_ALL_OFF:
            case BTN_LIGHT_SCENE_2:
            {
                for (i = 1; i <= LIGHT_M1_RELAYCNT; i++)
                    fnOff(vdvAMXLight, AVBDIN_RELAY_M1ADDRESS, i)
                for (i = 1; i <= LIGHT_M2_RELAYCNT; i++)
                    fnOff(vdvAMXLight, AVBDIN_RELAY_M2ADDRESS, i)
                OFF[vdvTP, btnLight]
                // also close the dimmer
                fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, 1, 0, 0)
                send_level vdvTP, btnDimLevel[1], 0
            }
            case BTN_LIGHT_SCENE_3:
                // buttons with channel type should be defined here
                if ([vdvTP, BUTTON.INPUT.CHANNEL] == 0)
                {
                    lightSceneAc(sceneRelayOnMapping, idxBtn, 1)
                }
                else
                {
                    lightSceneAc(sceneRelayOffMapping, idxBtn, 0)
                }
            default:
            {
                lightSceneAc(sceneRelayOnMapping, idxBtn, 1)
            }   
        }
    }
}

BUTTON_EVENT[vdvTP, btnDimLevel]
{
    RELEASE:
    {
        integer i 

        i = get_last(btnDimLevel)

        fnDimLevel(vdvAmxLight, AVBAO8_DIMMER_M1ADDRESS, i, gblDimLevelValue[i], 0)
    }
}

LEVEL_EVENT[vdvTP, btnDimLevel]
{
    integer i;
    
    i = get_last(btnDimLevel)
    
    gblDimLevelValue[i] = LEVEL.VALUE
}
