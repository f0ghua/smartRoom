(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT
INTEGER AVR_POWER_STATUS    =  1
INTEGER AVR_MUTE_STATUS     =  2
INTEGER AVR_VOLUME_STATUS   =  3
INTEGER AVR_INPUT_STATUS    =  4
INTEGER AVR_INPUT2_STATUS   =  5
INTEGER AVR_POWER2_STATUS   =  6
INTEGER AVR_VOLUME2_STATUS =  7
INTEGER AVR_MUTE2_STATUS    =  8

INTEGER nMAX_DTR                =  2

DEV dv_RCVR[]=
{
     dvRCVR_MGR
    ,dvRCVR_LGR
}

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE
PERSISTENT INTEGER n_AVR_STATUS [nMAX_DTR][10]  // Array to for reciever status

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION   () *)
(* EXAMPLE: DEFINE_CALL '' () *)

DEFINE_FUNCTION CHAR[9] fnDTR_STATION       (* Return formated station feedback */
(CHAR sSTATION[5])
{
    LOCAL_VAR CHAR cSTATION[9]
    LOCAL_VAR INTEGER tbAND
    cSTATION = sSTATION
    IF( LEFT_STRING(cSTATION,2) = '00' OR
        LEFT_STRING(cSTATION,2) = '01'
      )
        tBAND = 1
    ELSE
        tBAND = 2
        
    SWITCH(tBAND)
    {
        CASE 1:
        {
            IF(LEFT_STRING(cSTATION,2) = '00')
                REMOVE_STRING(cSTATION,'00',1)
            ELSE IF(LEFT_STRING(cSTATION,2) = '01')
                REMOVE_STRING(cSTATION,'0',1)
            cSTATION = "cSTATION,' AM'"
        }
        CASE 2:
        {
            IF(LEFT_STRING(cSTATION,1)='0')
                cSTATION = "MID_STRING(cSTATION,2,2),'.',RIGHT_STRING(cSTATION,2)"
            ELSE
                cSTATION = "LEFT_STRING(cSTATION,3),'.',RIGHT_STRING(cSTATION,2)"
            SET_LENGTH_STRING(cSTATION,LENGTH_STRING(cSTATION)-1)
            cSTATION = "cSTATION,' FM'"
        }
    }
    RETURN cSTATION
    cSTATION =''
}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT
DATA_EVENT[dv_RCVR]         // INTEGRA RECIEVER
{
    ONLINE:
    {
        SEND_STRING DATA.DEVICE,"'!1TUNQSTN',CR"
        SEND_STRING DATA.DEVICE,"'!1SLIQSTN',CR"
        SEND_STRING DATA.DEVICE,"'!1LMDQSTN',CR"
        WAIT 20
            SEND_STRING DATA.DEVICE,"'!1MVLQSTN',CR"
    }
    STRING:
    {
        LOCAL_VAR INTEGER nIND
        LOCAL_VAR Reply[100]
        LOCAL_VAR Buffer[100]
        nIND = GET_LAST(dv_RCVR)
        WHILE(FIND_STRING(DATA.TEXT,"$1A",1))
        {
            Reply = "Buffer,REMOVE_STRING(DATA.TEXT,"$1A",1)"
            CLEAR_BUFFER Buffer
            SELECT
            {
                (******** Power Status *******)
                ACTIVE(FIND_STRING(Reply,'PWR',1)): 
                {
                    REMOVE_STRING(Reply,'PWR',1)
                    n_AVR_STATUS[nIND][AVR_POWER_STATUS] = ATOI(Reply)
                }
                (******* Volume Status *******)
                ACTIVE(FIND_STRING(Reply,'MVL',1)): 
                {
                    REMOVE_STRING(Reply,'MVL',1)
                    SET_LENGTH_STRING(Reply,LENGTH_STRING(Reply)-1)
                    n_AVR_STATUS[nIND][AVR_VOLUME_STATUS] = HEXTOI(Reply)
                    OFF[n_AVR_STATUS[nIND][AVR_MUTE_STATUS]]
                    
                }
                (***** Tuner Station Status ****)
                ACTIVE(FIND_STRING(Reply,'TUN',1)):
                {
                    REMOVE_STRING(Reply,'TUN',1)
                    cRADIO_FREQ[nIND] = LEFT_STRING(Reply,5)
                    
                    IF(FIND_STRING(fnDTR_STATION(cRADIO_FREQ[nIND]),'.',1))
                        n_AVR_STATUS[nIND][AVR_INPUT_STATUS] = 24
                    
                    ELSE
                        n_AVR_STATUS[nIND][AVR_INPUT_STATUS] = 25
                        
                    SEND_COMMAND dv_TP[nLOOP1],"'!T',126,'You',39,'re listening to|',
                        fnDTR_STATION(cRADIO_FREQ[nIND])"
                    }
                }
            }
            Reply = ''
            Buffer = "Buffer,DATA.TEXT"
        }
    }
}