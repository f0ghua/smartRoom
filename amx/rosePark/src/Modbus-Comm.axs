MODULE_NAME='Modbus-Comm' (DEV vdvDEVICE, DEV dvDEVICE)
(*{{PS_SOURCE_INFO(PROGRAM STATS)                          *)
(***********************************************************)
(*  FILE CREATED ON: 3/17/04                               *)
(***********************************************************)
(*  ORPHAN_FILE_PLATFORM: 1                                *)
(***********************************************************)
//#####################################################################//
//# Copyright Notice :                                                #//
//#    Copyright, AMX, Inc., 2004                                     #//
//#    Private, proprietary information, the sole property of AMX.    #//
//#    The contents, ideas, and concepts expressed herein are not to  #//
//#    be disclosed except within the confines of a confidential      #//
//#    relationship and only then on a need to know basis.            #//
//#####################################################################// 
(********************************************************************)
(* COMMENTS:                                              
 * $Header: /NetLinxModules/Modbus/Modbus-Comm.axs 1     5/13/04 11:42a Chicks $                                               
 * $Revision: 1 $                                              
 * $Log: /NetLinxModules/Modbus/Modbus-Comm.axs $
 * 
 * 1     5/13/04 11:42a Chicks
 * Initial checkin before release. 
 * $API: None                                                    
*)
(*
    Version 1.1 10-04-2004   Updated to handle the partial message
    case.  Curt Hicks 

    Version 1.2 3/12/07 DJH: added device address parameter to ADD_POLL=
    command, to allow polling across multiple device addresses. Individual
    READ_ and WRITE_ commands have the DEV= commands to set up a different
    device address for each command, if desired. Increased MB_MAX_POLL_ITEMS
    to 500.
    
    This version of the module was tested piecewise, without a real MODBUS
    device.

    Rev 1.4 fixes check for duplicates in poll table to include 
    multiple device numbers

    Version 1.5 replaces Comm Queue WAIT with timeline to send next commands
    at 0.5 sec. intervals if no valid reply is received

    Version 1.6 04-24-08 SMA - added line to set bool bStringOK = TRUE (line
    1432), if no other error conditions exist.  This is required to satisfy
    the conditional on Line 1845, which allows the buffer to be cleared and
    fnDEQ () to empty the command buffer.  There was no other location in code
    in which bStringOK was set to true, so the conditional would never be
    satisfied.

*)
(***********************************************************)
(*}}PS_SOURCE_INFO                                         *)
(***********************************************************)

(***********************************************************)
(* System Type : Netlinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)

(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE
(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)

DEFINE_CONSTANT

CHAR  ASCII = 1                     // NetHex translates ASCII characters
CHAR  NO_ASCII = 0                  // NetHex does not translate ASCII characters

INTEGER MAX_PARAMS = 5
INTEGER TX_USER_Q_SIZE = 750        // approx 57 8 byte commands + 3 byte delimiter, + 2 byte 'header' 
INTEGER TX_STATUS_Q_SIZE = 4160     // MAX_POLL_ITEMS * 13    
    
INTEGER FALSE     =   0
INTEGER TRUE      =   1    
INTEGER nPOLLTL   =   1             // poll timeline identifier  
INTEGER nTL_DEQUE =   2	            // Message Deque timeline
    
CHAR CR           = $0D
CHAR LF           = $0A
    
  
INTEGER UNKNOWN = $FFFF  
    
//  Due to limitations on the NetLinx/NI  serial driver,
//  for RTU framing only 64 bytes can be received in one message.   
//  READ_HOLD_MAX must be set to prohibit responses with   
//  more than 64 bytes.  Each register value comes back as two bytes.
//  For bit values, 16 bit values make up two bytes. 
    
// slave address, function code, byte count, [data value High, data value Low]...,
// check sum High, check sum Low 
// 64 - 5 = 49 bytes for data values = 49/2 = 24 
    
INTEGER READ_HOLD_MAX = 24          // slave address, function code, byte count, data values,
INTEGER READ_BITS_MAX = 384     
    
//
// Types of items which can be polled for 
// 
INTEGER COIL = 1
INTEGER DISCRETE_INPUT = 2
INTEGER HOLDING_REGISTER = 3
INTEGER INPUT_REGISTER = 4
       
CHAR sVERSION[] = '1.6'        //
CHAR cDELIM[3]= {$23,$40,$23}
CHAR MIN_LENGTH = 8                 // the minimum message length is 8 bytes
// <device ID>,<function code>,<addr hi>,<addr low>,<value high>,<value low>,<cksum 1>,<cksum 2}     

// Permissible range for slave address    
CHAR MIN_ADDRESS = 0
CHAR MAX_ADDRESS = 247                      
CHAR BROADCAST_ADDRESS = 0 
CHAR DEFAULT_ADDRESS = 1            // not all commands can be sent to the broadcast address
                                   
// 
//  constants for which Queue to use 
//
INTEGER USER_QUEUE = 1
INTEGER STATUS_QUEUE = 2

CHAR DEFAULT_ZONE = 0
CHAR DEFAULT_KEY = 0
                       
INTEGER MB_MAX_POLL_ITEMS = 500  
    
LONG MIN_POLL_TIME = 60             // 1 minute in seconds 
LONG MAX_POLL_TIME =  360000        // 1 hour in seconds 
LONG DEFAULT_POLL_TIME = 180000     // 3 minutes in milliseconds          
                                   
(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE
// for the command parser
STRUCTURE _sCMD_PARAMETERS
{
    integer count
    char    param[MAX_PARAMS][32]
    char    rawdata[160]
};  

STRUCTURE _sPoll_Item
{
    integer nAddress
    integer nValue
    integer nItemType               // COIL, DISCRETE_INPUT, HOLDING_REGISTER, INPUT_REGISTER  
    char    cZoneID
    char    cKey 
    integer nDevAddress		        // Added Device Address (default 1)
};

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

VOLATILE CHAR sRxBuff[500]        // BUFFER FOR INCOMING DATA FROM THE PHYSICAL DEVICE  
    
VOLATILE CHAR sTxUserQ[TX_USER_Q_SIZE]
VOLATILE CHAR sTxStatusQ[TX_STATUS_Q_SIZE]

VOLATILE LONG lBaudRate = 9600
VOLATILE INTEGER nExpectedReply           // Used to track     
VOLATILE INTEGER nPollReply               // FALSE - command sent by user TRUE - command sent by polling 
VOLATILE CHAR sLastCommandSent[100]       // stores the last command sent to the device 
VOLATILE CHAR cZoneIdSaved                // stores the zone ID associated with the last command sent
VOLATILE CHAR cKeySaved                   // stores the key value associated with the last command sent 

VOLATILE CHAR cCrcHigh
VOLATILE CHAR cCrcLow 
    
VOLATILE INTEGER bStringOK = FALSE; 
VOLATILE INTEGER bWaitForReply = FALSE
VOLATILE INTEGER nReplyCounter = 0        // used to track number of replies from device 
    
VOLATILE INTEGER nDebug = TRUE           // DETERMINES IF DEBUGGING IS ON OR OFF  

VOLATILE LONG lPollTLtime[] =   {DEFAULT_POLL_TIME}    // default polling time of 3 minutes 
VOLATILE LONG lDequeTLtime[] =   {500}    // reply timeout of 500 milliseconds 
    
VOLATILE CHAR cStandardAddress = DEFAULT_ADDRESS	// Set by ADDRESS= command                                
VOLATILE CHAR cDeviceAddress = DEFAULT_ADDRESS	// May be set by DEV= parameter, or to cStandardAddress
              
VOLATILE _sPoll_Item uModbusPollList[MB_MAX_POLL_ITEMS]
VOLATILE INTEGER nNumberPollItems 
         
(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING
(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE
(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
// Name   : ==== NetHex ====
// Purpose: for debugging, sends strings to specified device w/ 
//          specified prefix after translating 
//          nonprintable values
// Params : (1) IN  - dvDevice   device to send string to 
//          (2) IN  - sPrefix    prefix to add when string is printed
//          (3) IN  - sBuff      string to print
//          (4) IN - bAsciiFlag  indicates whether NetHex should translate
//                               ASCII characters or not
// Returns: none
// Notes  : from David Deyo
//
DEFINE_FUNCTION INTEGER NetHex(DEV dvDevice, CHAR sPrefix[], CHAR sBuff[],CHAR bAsciiFlag)
{
    STACK_VAR CHAR     sLogBuff[1000], sTempBuff[1000]
    STACK_VAR INTEGER  n, lineno, nLength
    
    FOR (n = 1; n <= LENGTH_STRING(sBuff); n++)
    {
        IF  ( (sBuff[n] >= $21 && sBuff[n] <= $7E) && (bAsciiFlag) )   
            sLogBuff = "sLogBuff, sBuff[n]"
        ELSE
            sLogBuff = "sLogBuff, ' ', format('0x%02X', sBuff[n]), ' '"
    }    
    WHILE (LENGTH_STRING(sLogBuff) > 75)                // chop up output string if it is >75
    {
        sTempBuff = GET_BUFFER_STRING (sLogBuff, 75)   
        SEND_STRING dvDevice, "sPrefix,sTempBuff,$D,$A"
    }
    if (length_string (sLogBuff))
        SEND_STRING dvDevice, "sPrefix,sLogBuff,$D,$A"
}
  
//
//
// Name   : ==== fnDEQ ====      TWO QUEUES !!! 
// Purpose: Removes the first command from the queue by the Delimiter and
//          sends it to the device. Pauses the timeline if the queue is 
//          empty
// Params : (1) OUT  - command Queue with first command removed
//
DEFINE_FUNCTION fnDEQ ()
{
    STACK_VAR CHAR sCmd[100]
        
    IF (nDebug=2)
    {
        NetHex(0, "'fnDEQ: sTxUserQ = '", sTxUserQ,NO_ASCII)
        NetHex(0,"' fnDEQ: Poll Q = '",sTxStatusQ,NO_ASCII) 
    }
    
    sCmd = ''  
    nExpectedReply = UNKNOWN
    nPollReply = FALSE
    
    IF (FIND_STRING(sTxUserQ,cDELIM,1) )
    {
        sCmd = REMOVE_STRING (sTxUserQ, "cDELIM",1)
        IF (nDebug) 
           NetHex(0, "'fnDEQ (USER): sCmd = '", sCmd,NO_ASCII)
    } 
    ELSE IF (FIND_STRING(sTxStatusQ,cDELIM,1) )
    {
        nPollReply = TRUE  
        sCmd = REMOVE_STRING (sTxStatusQ, "cDELIM",1)
        IF (nDebug) 
           NetHex(0, "'fnDEQ (POLL): sCmd = '", sCmd,NO_ASCII)
    }
          
    IF (LENGTH_STRING (sCmd))
    { 
        // cDELIM is used by the queue, not used by the device 
        SET_LENGTH_STRING(sCmd, (LENGTH_STRING(sCmd) - LENGTH_STRING(cDELIM) ) )  
        
        cZoneIdSaved = GET_BUFFER_CHAR (sCmd)
        cKeySaved = GET_BUFFER_CHAR (sCmd) 
        fnSendToDevice(sCmd) 
        sLastCommandSent = sCmd
        bWaitForReply = TRUE 
	   //
	   //  version 1.1    This also takes care of the partial message
	   //  case.  We have 1/2 second to receive the complete message,
	   //  whether that comes in a single string event, or multiple 
	   //  string events. 
	   // 
	   //   Wait for reply will prevent locking up while waiting for
	   //   the rest of a partial message, or a message at all.
	   //
	   //   Version 1.5  Replaced WAIT with timeline for reply timeout and
	   //   sending of next command.
	   IF(!TIMELINE_ACTIVE(nTL_DEQUE))  // Start reply timout timer
	   {
	       TIMELINE_CREATE (nTL_DEQUE, lDequeTLtime, 1, Timeline_Absolute, Timeline_Once)
	   }
    }
    ELSE  // Nothing left to send
    {
	   IF(TIMELINE_ACTIVE(nTL_DEQUE))
	   {
	       TIMELINE_KILL (nTL_DEQUE)
	   }
    }
}   // END OF - fnDEQ 

//
//
// Name   : ==== fnENQ ====    TWO QUEUES !!! 
// Purpose:  Adds the command to the queue if there's room,
//           and restarts the timeline if needed
//
// Params : (1) IN  - sCmd command to add
//          (2) OUT - command Queue modified with new command  
// 
// Returns: integer - TRUE (1) if command was sent or enqueued, FALSE(0) otherwise 
DEFINE_FUNCTION INTEGER fnENQ (char sCmd[], integer nWhichQueue)
{
    STACK_VAR CHAR bResult
    STACK_VAR INTEGER nQLength
       
    IF (nDebug)
        NetHex(0, "'fnENQ: sCmd = '", sCmd,NO_ASCII)
        
    bResult = TRUE
    
    SWITCH (nWhichQueue)
    {
        CASE USER_QUEUE :
        {
            nQLength = LENGTH_STRING(sTxUserQ)

            IF ( (nQLength + LENGTH_STRING(sCmd) + LENGTH_STRING (cDELIM) ) < TX_USER_Q_SIZE)
            {
                sTxUserQ = "sTxUserQ,sCmd,cDELIM"
            }                
            ELSE
            {
                bResult = FALSE
                SEND_STRING 0,"'fnENQ (USER): No room to queue command ',sCmd"
            } 
        }   // END OF - add to user Q   
        
        CASE STATUS_QUEUE :
        {
            nQLength = LENGTH_STRING(sTxStatusQ)

            IF ( (nQLength + LENGTH_STRING(sCmd) + LENGTH_STRING (cDELIM) ) < TX_STATUS_Q_SIZE)
            {
                sTxStatusQ = "sTxStatusQ,sCmd,cDELIM"                
            }
            ELSE
            {
                bResult = FALSE
                SEND_STRING 0,"'fnENQ (POLL): No room to queue command ',sCmd"
            }
        }   // END OF - add to status Q            
    }   // END OF - switch on which queue  
    
    IF (bWaitForReply = FALSE)
    {
        sRxBuff ='';
        fnDEQ();   
    }
    RETURN bResult
} 


// Name   : ==== fnParseCommand ====
// Purpose: To parse out parameters from module send_command or send_string
// Params : (1) IN  - sndcmd/str data
//          (2) IN  - parameter separating character usually ':' or '|' or even a string
//          (3) OUT - parsed property/method name STILL INCLUDES the '=' or '?'
//          (4) OUT - MDX_PARAMETERS structure
// Returns: integer - -1 if the parse failed OR the count of parameters placed in (4)
// Notes  : Parses the strings sent to or from modules extracting the various parts
//          of the command out into command name, parameters and returning the count
//          of parameters present.   Adapted from the UK mdxStandard.axi
//          Changed the functionality because it didn't appear to support parameters
//          with query commands 
//
DEFINE_FUNCTION INTEGER fnParseCommand(char cmd[], char separator [], 
                               char name[], _sCMD_PARAMETERS params)   
{
    STACK_VAR char p        // use character to save space 
    STACK_VAR char temp[32]
  
    IF ( find_string(cmd,"'='",1) )
    {
        name = REMOVE_STRING(cmd,"'='",1) 
    }
    ELSE 
    IF  ( find_string(cmd,"'?'",1) )
    {
        name = REMOVE_STRING(cmd,"'?'",1)
    }
    ELSE  
    {
        name = cmd
        return 0
    }
    ///////////////////////////////////////////////////////////////////////////
    // Strip the string down into parameters separated by ':'
    //    
    // Make the whole remaining buffer available for later if needed 
    params.rawdata = cmd;
        
    // Tokenize the params
    p = 0         
    params.count = 0;
    while( (LENGTH_STRING(cmd)) AND (params.count <= MAX_PARAMS) )
    {
        p++;
        // Strip off each param and put into its index place in array
        temp = REMOVE_STRING(cmd,"separator",1);
        // May only be 1 param so no trailing ':'
        //
        // If nothing in temp, set temp = whatever's left in cmd  
        if(!LENGTH_STRING(temp))
        {
            temp = cmd; 
            CLEAR_BUFFER cmd;
            if(LENGTH_STRING(temp) <32)
            {
                params.param[p] = temp;
                params.count++;
            }
        }
        else
        {
            SET_LENGTH_STRING(temp,LENGTH_STRING(temp)-1); // Remove ':'
            if(LENGTH_STRING(temp) <32)
            {
                params.param[p] = temp; 
                params.count++;
            }
        }
    }
    return params.count;
} 

//
//
// Name   : ==== fnRangeCheck ====
// Purpose: Return TRUE or FALSE if a variable is within a given range
// Params : (1) IN  - variable to check 
//          (2) IN  - Lowest permissible value
//          (3) IN  - Highest permissible value 
// Returns: integer - TRUE (1) if within the range, FALSE(0) otherwise 
DEFINE_FUNCTION INTEGER fnRangeCheck(SLONG Value1, SLONG LowerBound, SLONG UpperBound) 
{
    IF ( (Value1 >= LowerBound) AND (Value1 <=UpperBound))
        RETURN TRUE
    ELSE 
        RETURN FALSE     
}   


// Name   : ==== fnSendToDevice ====
// Purpose: takes the command string, adds any standard additional
//          stuff and sends it to the device 
// Params : (1) IN  - cDATA   command string to send to the device
// Returns: -
// Notes  : -
//     
DEFINE_FUNCTION fnSendToDevice (CHAR sData[])
{    
(*
    STACK_VAR CHAR cCrcHigh
    STACK_VAR CHAR cCrcLow  
  *)         
    fnCalcChecksum(sData (*, cCrcHigh, cCrcLow*) ) 
 
    IF (nDebug)     
        NetHex(0,"'fnSendToDevice: data sent is '","sData,cCrcLow,cCrcHigh",NO_ASCII)
        
    SEND_STRING dvDEVICE, "sData,cCrcLow,cCrcHigh"     
}

//************************************************************************
//
//   MODULE SPECIFIC FUNCTIONS START HERE
//
//*************************************************************************
 
 
// Name   : ==== fnAddPollItem ====
// Purpose:  Adds an item to be polled to the array
//
// Params : (1) IN - string for nAddress     representing the register address to add  
//          (2) IN - string for nItemType    representing the register item type 
//          (3) IN - string for Zone ID 
//          (4) IN - string for Key value 
//	    (5) IN - string for Device Address
//
// Returns: Index   the integer value of the index  or 0 if the item was not added
// Notes  : None
//  
//    
DEFINE_FUNCTION integer fnAddPollItem(char sData1[], char sData2[], 
                char sData3[], char sData4[], char sData5[])
{
    stack_var integer nAddress
    stack_var integer nItemType
    stack_var integer i
    stack_var char cZoneID
    stack_var char cKey  
    stack_var char cDevAddr  
    stack_var integer nTempInt 
    stack_var slong slTemp
    
    slTemp = ATOI(sData1)
    IF (fnRangeCheck(slTemp,0,65535) )
        nAddress = TYPE_CAST(slTemp)
    ELSE
    {
          send_string 0,"'fnAddPollItem(): invalid address ',sData1"
          return 0
    }
  
    nItemType = ATOI(sData2) 

    // check for valid item type 
    if (      (nItemType != COIL) 
          AND (nItemType != HOLDING_REGISTER) 
          AND (nItemType != INPUT_REGISTER) 
          AND (nItemType != DISCRETE_INPUT) ) 
    {
          send_string 0,"'fnAddPollItem(): invalid item type ',itoa(nItemType)"
          return 0
    }    
    
    // check for valid Zone ID 
    nTempInt = ATOI(sData3) 
    IF (fnRangeCheck(TYPE_CAST(nTempInt),0,255) )
        cZoneID = TYPE_CAST(nTempInt) 
    ELSE
    {
        send_string 0,"'fnAddPollItem(): invalid Zone ID ',itoa(nTempInt)"
        return 0;
    }    
    
    // check for valid Key value 
    nTempInt = ATOI(sData4) 
    IF (fnRangeCheck(TYPE_CAST(nTempInt),0,255) )
        cKey = TYPE_CAST(nTempInt) 
    ELSE
    {
        send_string 0,"'fnAddPollItem(): invalid Key value ',itoa(nTempInt)"
        return 0
    }
    // check for valid Device Address value 
    nTempInt = ATOI(sData5) 
    IF (fnRangeCheck(TYPE_CAST(nTempInt),0,247) )
        cDevAddr = TYPE_CAST(nTempInt) 
    ELSE
    {
        send_string 0,"'fnAddPollItem(): invalid Device Address value ',itoa(nTempInt)"
        return 0
    }
    // Make sure we have room in the list
    if (nNumberPollItems == MB_MAX_POLL_ITEMS)
    {
        send_string 0, "'fnAddPollItem(): PollItems array is full!'"
        return 0
    }  
    
    // Don't want duplicates in the list
    for (i = 1; i <= nNumberPollItems; i++)
    {
        if ( (nAddress == uModbusPollList[i].nAddress) AND 
            (nItemType == uModbusPollList[i].nItemType) AND 
            (cDevAddr == uModbusPollList[nNumberPollItems].nDevAddress) )
        {
            send_string 0,('fnAddPollItem(): address / item type / device already in notify list') 
            return 0
        }
    }  
    
    // Not in the list so stick it in
    nNumberPollItems++
    uModbusPollList[nNumberPollItems].nAddress = nAddress
    uModbusPollList[nNumberPollItems].nItemType = nItemType 
    uModbusPollList[nNumberPollItems].nValue = UNKNOWN
    uModbusPollList[nNumberPollItems].cZoneID = cZoneID
    uModbusPollList[nNumberPollItems].cKey = cKey    
    uModbusPollList[nNumberPollItems].nDevAddress = cDevAddr    
    return nNumberPollItems
    
}

// Name   : ==== fnCalcCheckSum ====
// Purpose:  Calculates the CRC checksum for the given string
//
// Params : (1) IN - cBuffer       the array for which to calculate the checksum  
//          (2) OUT - cCrcHigh     the high byte of the calculated checksum
//          (3) OUT - cCrcLow      the low byte of the calculated checksum 
//
// Returns: None
// Notes  : None
//  
//    
DEFINE_FUNCTION fnCalcCheckSum(CHAR cBuffer[] (*, CHAR cCrcHigh, CHAR cCrcLow *) )   

{
    STACK_VAR INTEGER nCRCReg              // CRC checksum working register
    STACK_VAR INTEGER nPOLYNOMIAL          // polynomial constant A001
    STACK_VAR INTEGER i, j                 // loop counters
    STACK_VAR INTEGER nByte                // byte in msg to process
    STACK_VAR INTEGER nLSB                 // temp var to hold value of LSB (Least Significant Bit)
  
    nPOLYNOMIAL = $A001
    nCRCReg = $FFFF
 
    IF ( nDebug = 2)
        NetHex(0, "ITOA( __LINE__ ), ' fnCalcCheckSum'", cBuffer,NO_ASCII) 
  
    for (i=1; i <= LENGTH_STRING(cBuffer); i++) // for each byte in the command string...
    {

        nByte = cBuffer[i]
        nCRCReg = nCRCReg ^ nByte            // XOR first 8-bit byte of str with register
 
        for (j=1; j <= 8; j++)               // will shift a total of 8 times
        {
            nLSB = (nCRCReg & $01)             // save LSB
            nCRCReg = TYPE_CAST (nCRCReg >> 1) // shift 1 bit to the right

            if (nLSB)                          // check if LSB WAS 0 or 1
            {
                nCRCReg = nCRCReg ^ nPOLYNOMIAL  // if 1, XOR with constant A001, otherwise just continue
            } 
        }                                    // END OF - loop thru 8 bits
    }                                      // END OF - loop for each byte in the string
  
    cCrcHigh = TYPE_CAST ((nCRCReg & $FF00) >> 8) 
    cCrcLow =  TYPE_CAST (nCRCReg & $00FF)

    IF (nDebug == 2)
    {
        send_string 0, "'calculated checksum is  ', ITOA(nCRCReg)"
        NetHex(0,"'CRC High byte is '","cCrcHigh",NO_ASCII) 
        NetHex(0,"'CRC Low byte is '","cCrcLow",NO_ASCII) 
    }
}

// Name   : ==== fnBytesToInt ====  
// Purpose  : Convert two bytes (high byte, low byte) to
//            the corresponding integer value 
//
// Params   : 
// Return   : integer value 
// Notes    : None
//
define_function integer fnBytesToInt(char cHighByte, char cLowByte)
{
    stack_var integer nIntegerValue
    
    nIntegerValue = cHighByte
    nIntegerValue = TYPE_CAST (cHighByte << 8)
    nIntegerValue = nIntegerValue + cLowByte   
            
    return nIntegerValue
}


// Name   : ==== fnFindPollItem ====  
// Purpose  : Find an address in the pollItem array
//
// Params   : addr : integer address to find
// Return   : index of address in array is returned, 0 = not found
// Notes    : None
//

define_function integer fnFindPollItem(integer addr,integer nItemType)
{
    stack_var integer i    
    
    // Loop through poll items, stop if end of notify list
    for (i = 1; i <= nNumberPollItems; i++)
    {
        if ( (addr == uModbusPollList[i].nAddress) AND (nItemType == uModbusPollList[i].nItemType) )
        {
            return i
        }
    }
    return 0
}

// Name   : ==== fnGet_Address ====
// Purpose:  enqueues the Read command for the different types of values 
//
// Params : (1) IN - string with address of starting value to read  
//          (2) IN - address type; the type of thing we are reading  i.e. what function code to use   
//              COIL, DISCRETE_INPUT, HOLDING_REGISTER, INPUT_REGISTER                
//          (3) IN - string representing number of items to read 
//          (4) IN -  string representing the zone ID 
//          (5) IN -  string representing the value key 
//	    (6) IN -  string representing device address
//          (7) IN - which queue to use  USER_QUEUE or STATUS_QUEUE
//
// Returns: None
// Notes  : The structure of the read commands for read coil, read discrete input,
//          read holding register(s) and read input register(s) is the same except for the function code  
//          i.e. <function code> 1 byte
//               <address high> 1 byte
//               <address low> 1 byte
//               <number of items to read high> 1 byte
//               <number of items to read low> 1 byte
//
DEFINE_FUNCTION fnGet_Address(char sData1[],	       // Register address
                            integer nAddressType, 	   // Register type
                            char    sData4[],          // reg. to read (# out of order)
                            char    sData2[],               // zone ID   
                            char    sData3[],               // key 
			                 char    sData5[],		// Device address to use
                            integer nWhichQueue)
{
    STACK_VAR INTEGER nAddress
    STACK_VAR CHAR cHighAddr
    STACK_VAR CHAR cLowAddr
    STACK_VAR CHAR cHighNbr
    STACK_VAR CHAR cLowNbr 
    STACK_VAR CHAR cFunctionCode
    STACK_VAR CHAR cDevAddress
                                 
    STACK_VAR INTEGER nTempInt 
    STACK_VAR SINTEGER snTempMax 
    STACK_VAR CHAR cZoneID
    STACK_VAR CHAR cKey
    stack_var slong slTemp 
    
    if (ndebug)
	send_string 0,"'GetAddress:',sData1,':',sData4,':',sData2,':',sData3,':',sData5"
    // check for valid item type 
    if (      (nAddressType != COIL) 
          AND (nAddressType != HOLDING_REGISTER) 
          AND (nAddressType != INPUT_REGISTER) 
          AND (nAddressType != DISCRETE_INPUT) ) 
    {
          send_string 0,"'fnGet_Address(): invalid nAddressType  ',itoa(nAddressType)"
          return
    }    
                  
    // Valid register range is 0 to 65535       
    slTemp = ATOI(sData1)  
    
    IF (fnRangeCheck(slTemp,0,65535) )
        nAddress = TYPE_CAST(slTemp)
    ELSE
    {
          send_string 0,"'fnGet_Address(): invalid address ',sData1"
          return
    }
    
    cHighAddr = TYPE_CAST ( (nAddress & $FF00) >> 8)  
    cLowAddr = TYPE_CAST ( (nAddress & $00FF) )
                                                
    if (nDebug=2)
    {
        send_string 0,"'nAddress is ',ITOA(nAddress)" 
        NetHex (0,"'high byte is '","cHighAddr",NO_ASCII)
        NetHex (0,"' low byte is '","cLowAddr",NO_ASCII)
    }
    nTempInt = ATOI(sData2)
    IF (fnRangeCheck(TYPE_CAST(nTempInt),0,255) )
        cZoneID = TYPE_CAST (nTempInt)
    ELSE
    { 
        send_string 0,"'invalid value for Zone ID ',ITOA(nTempInt)"
        return; 
    }    
    nTempInt = ATOI(sData3)
    IF (fnRangeCheck(TYPE_CAST(nTempInt),0,255) )
        cKey = TYPE_CAST (nTempInt)
    ELSE
    {
        send_string 0,"'invalid value for Key ',ITOA(nTempInt)"
        return; 
    } 
    
    nTempInt = ATOI(sData5)
    IF (fnRangeCheck(TYPE_CAST(nTempInt),0,255) )
        cDevAddress = TYPE_CAST (nTempInt)
    ELSE
    {
        send_string 0,"'invalid value for Device Address ',ITOA(nTempInt)"
        return; 
    }  
    
    nTempInt = ATOI(sData4) 
    IF  ( (nAddressType == HOLDING_REGISTER) OR (nAddressType == INPUT_REGISTER) )
    {
        snTempMax = READ_HOLD_MAX
    }
    ELSE 
    {
        snTempMax = READ_BITS_MAX  
    }
        
    IF (fnRangeCheck(TYPE_CAST(nTempInt),1,snTempMax) ) 
    {   
        cHighNbr =  TYPE_CAST ( (nTempInt & $FF00) >> 8)
        cLowNbr = TYPE_CAST ( (nTempInt & $00FF) )  
    }
    ELSE
    {
        send_string 0,"'invalid value for number of registers to read ',ITOA(nTempInt)"
        return;
    }
    // message is defined in routine fnEnq as characters,
    // so automatically discards high bytes of an integer variable
    
    // explicitly map enumerated addresstype to function codes
    // even though they have the same 'value'
    SWITCH (nAddressType)
    {
        CASE COIL:
        {
            cFunctionCode = $01
        }
        CASE DISCRETE_INPUT:
        {
            cFunctionCode = $02
        }
        CASE HOLDING_REGISTER:
        {
            cFunctionCode = $03
        }
        CASE INPUT_REGISTER:
        {
            cFunctionCode = $04 
        }
    }
    
    fnEnq("cZoneID,cKey,cDevAddress,cFunctionCode,cHighAddr,cLowAddr,cHighNbr,cLowNbr",nWhichQueue)
}
 // Name   : ==== fnSet_Coil  ====
// Purpose:  Write OFF or ON to a single output  
//
// Params : (1) IN - register to write to     
//          (2) IN - value to write 
//          (4) IN -  string representing the zone ID 
//          (5) IN -  sring representing the value key 
//        
// Returns: None
// Notes  : Valid register range is 0 to 65535, no point in validating 
DEFINE_FUNCTION fnSet_Coil(char sData1[], char sData2[], char sData3[], char sData4[])
{
    STACK_VAR INTEGER nRegister, nValue, nTempInt
    STACK_VAR CHAR cHigh1,cLow1,cHigh2,cLow2 
    STACK_VAR CHAR cZoneID
    STACK_VAR CHAR cKey 
    STACK_VAR SLONG slTemp  
    
    // Valid register range is 0 to 65535       
    slTemp = ATOI(sData1)
    IF (fnRangeCheck(slTemp,0,65535) )
        nRegister = TYPE_CAST(slTemp)
    ELSE
    {
          send_string 0,"'fnSet_Coil(): invalid address ',sData1"
          return ;
    } 
     
    // Valid value range is 0 or 1
    nValue = ATOI(sData2) 
    IF (nValue != 0 AND nValue !=1)
    { 
        send_string 0,"'value is not 0 or 1 ',ITOA(nValue)"
        return; 
    }
    
    nTempInt = ATOI(sData3)
    IF (fnRangeCheck(TYPE_CAST(nTempInt),0,255) )
        cZoneID = TYPE_CAST (nTempInt)
    ELSE
    { 
        send_string 0,"'invalid value for Zone ID ',ITOA(nTempInt)"
        return; 
    }
        
    nTempInt = ATOI(sData4)
    IF (fnRangeCheck(TYPE_CAST(nTempInt),0,255) )
        cKey = TYPE_CAST (nTempInt)
    ELSE
    {
        send_string 0,"'invalid value for Key ',ITOA(nTempInt)"
        return; 
    }  

    // register ID or address
    cHigh1 = TYPE_CAST ( (nRegister & $FF00) >> 8)  
    cLow1 = TYPE_CAST ( (nRegister & $00FF) )

    // value to set
    IF (nValue == 0)        // OFF 
    {     
        cHigh2 = $00
        cLow2 = $00
    }
    ELSE                    // ON (have previously checked that value is 0 or 1  
    {
        cLow2 = $00 
        cHigh2 = $FF    
    }
     
    fnEnq("cZoneID,cKey,cDeviceAddress,$05,cHigh1,cLow1,cHigh2,cLow2",USER_QUEUE)    
}


// Name   : ==== fnSet_Register ====
// Purpose:  execute the WRITE_HOLD command   for a SINGLE HOLDING REGISTER !! 
//
// Params : (1) IN - string with register to write to     
//          (2) IN - string with value to write 
//          (4) IN -  string representing the zone ID 
//          (5) IN -  sring representing the value key 
//        
// Returns: None
// Notes  : Valid register range is 0 to 65535, no point in validating 
DEFINE_FUNCTION fnSet_Register(char sData1[], char sData2[], char sData3[], char sData4[])
{
    STACK_VAR INTEGER nRegister, nValue, nTempInt
    STACK_VAR CHAR cHigh1,cLow1,cHigh2,cLow2 
    STACK_VAR CHAR cZoneID
    STACK_VAR CHAR cKey 
    STACK_VAR SLONG slTemp

    // Valid register range is 0 to 65535       
    slTemp = ATOI(sData1)
    IF (fnRangeCheck(slTemp,0,65535) )
        nRegister = TYPE_CAST(slTemp)
    ELSE
    {
          send_string 0,"'fnSet_Register(): invalid address ',sData1"
          return ;
    } 
     
    // Valid value range is 0 to 65535
    slTemp = ATOI(sData2)
    IF (fnRangeCheck(slTemp,0,65535) )
        nValue = TYPE_CAST(slTemp)
    ELSE
    {
          send_string 0,"'fnSet_Register(): invalid value ',sData2"
          return ;
    } 
    
    nTempInt = ATOI(sData3)
    IF (fnRangeCheck(TYPE_CAST(nTempInt),0,255) )
        cZoneID = TYPE_CAST (nTempInt)
    ELSE
    { 
        send_string 0,"'invalid value for Zone ID ',ITOA(nTempInt)"
        return; 
    }
        
    nTempInt = ATOI(sData4)
    IF (fnRangeCheck(TYPE_CAST(nTempInt),0,255) )
        cKey = TYPE_CAST (nTempInt)
    ELSE
    {
        send_string 0,"'invalid value for Key ',ITOA(nTempInt)"
        return; 
    }  

    // register ID or address
    cHigh1 = TYPE_CAST ( (nRegister & $FF00) >> 8)  
    cLow1 = TYPE_CAST ( (nRegister & $00FF) )

    // value to set     
    cHigh2 = TYPE_CAST ( (nValue & $FF00) >> 8 )
    cLow2 = TYPE_CAST ( (nValue & $00FF) ) 
     
    fnEnq("cZoneID,cKey,cDeviceAddress,$06,cHigh1,cLow1,cHigh2,cLow2",USER_QUEUE)    
}



// Name   : ==== fnProcessAPICommands ====
// Purpose:  parses the command strings AND takes the 
//           appropriate action or actions   
//
// Params : (1) sCmdArray passed as data.text from the data event  
//        
// Returns: None
// Notes  : None
//
DEFINE_FUNCTION fnProcessAPICommands(CHAR sCmdArray[])
{
    STACK_VAR CHAR sName[32]
    STACK_VAR CHAR cType 
    STACK_VAR _sCMD_PARAMETERS uParameters
    STACK_VAR INTEGER nTempValue, nTempValue1, nTempValue2
    STACK_VAR INTEGER nDEVICE 
    STACK_VAR LONG lTempBaudRate 
    STACK_VAR INTEGER i 
    STACK_VAR INTEGER nAddressType   
    
    IF ( nDebug )
        NetHex(0, "ITOA( __LINE__ ), ' fnProcessAPICommands '", sCmdArray,ASCII)
 
    uParameters.count = 0    
    fnParseCommand(sCmdArray, "':'", sName, uParameters) 
    
    switch(sName) 
    {   
        (*    used for testing 
        CASE 'POLLGUYS':
        {   
            // coils 
            send_command vdvDEVICE,"'ADD_POLL=0:1:1:1'"
            send_command vdvDEVICE,"'ADD_POLL=1:1:1:2'" 
            send_command vdvDEVICE,"'ADD_POLL=2:1:1:3'"
            send_command vdvDEVICE,"'ADD_POLL=3:1:1:4'" 
            send_command vdvDEVICE,"'ADD_POLL=4:1:1:5'"
            send_command vdvDEVICE,"'ADD_POLL=5:1:1:6'" 
            send_command vdvDEVICE,"'ADD_POLL=6:1:1:7'"
            send_command vdvDEVICE,"'ADD_POLL=7:1:1:8'" 
            // discrete inputs
            send_command vdvDEVICE,"'ADD_POLL=0:2:2:1'"
            send_command vdvDEVICE,"'ADD_POLL=1:2:2:2'"  
            send_command vdvDEVICE,"'ADD_POLL=2:2:2:1'"
            send_command vdvDEVICE,"'ADD_POLL=3:2:2:2'"  
            send_command vdvDEVICE,"'ADD_POLL=4:2:2:1'"
            send_command vdvDEVICE,"'ADD_POLL=5:2:2:2'"  
            send_command vdvDEVICE,"'ADD_POLL=6:2:2:1'"
            send_command vdvDEVICE,"'ADD_POLL=7:2:2:2'"  
            // holding registers
            send_command vdvDEVICE,"'ADD_POLL=0:3:3:1'"
            send_command vdvDEVICE,"'ADD_POLL=1:3:3:2'"   
            send_command vdvDEVICE,"'ADD_POLL=2:3:3:3'"
            send_command vdvDEVICE,"'ADD_POLL=3:3:3:4'"   
            send_command vdvDEVICE,"'ADD_POLL=4:3:3:5'"
            // input registers 
            send_command vdvDEVICE,"'ADD_POLL=0:4:4:1'"
            send_command vdvDEVICE,"'ADD_POLL=1:4:4:2'"
            send_command vdvDEVICE,"'ADD_POLL=2:4:4:3'"
            send_command vdvDEVICE,"'ADD_POLL=3:4:4:4'"
        }
        *)
        CASE 'ADDRESS=' :
        {
            nTempValue = ATOI(uParameters.param[1])
            IF (fnRangeCheck(TYPE_CAST(nTempValue),MIN_ADDRESS,MAX_ADDRESS))
            {
                cStandardAddress =  TYPE_CAST(nTempValue) 
                send_string vdvDEVICE,"'ADDRESS=',TYPE_CAST(itoa(cStandardAddress))" 
            }
            ELSE
                send_string 0,"'ERROR:  Device Address is out of range (1-247) ',uParameters.param[1]"
        }   
        CASE 'ADDRESS?':
        {
            send_string vdvDEVICE,"'ADDRESS=',TYPE_CAST(itoa(cStandardAddress))" 
        }   
        CASE 'ADD_POLL=':
        {
            nTempValue = 0
            IF (uParameters.count = 2)
            { 
                nTempValue = fnAddPollItem(uParameters.param[1],
                              uParameters.param[2], 
                              ITOA(DEFAULT_ZONE), 
                              ITOA(DEFAULT_KEY),
			      cStandardAddress)	// Use current Device address
			
                send_string vdvDEVICE,"'ADD_POLL=',ITOA(nTempValue)" 
            }                 
            ELSE IF (uParameters.count = 4)
            { 
                nTempValue = fnAddPollItem(uParameters.param[1],
                              uParameters.param[2], 
                              uParameters.param[3], 
                              uParameters.param[4],
			                 cStandardAddress)	// Use current Device address
                send_string vdvDEVICE,"'ADD_POLL=',ITOA(nTempValue)"
            } 
            ELSE IF (uParameters.count = 5)	// Added device address
            { 
                REMOVE_STRING(uParameters.param[5],'DEV=',1)	// Remove dev addr leader
                nTempValue = fnAddPollItem(uParameters.param[1],
                            uParameters.param[2], 
                            uParameters.param[3], 
                            uParameters.param[4],
                            uParameters.param[5])	// Explicit device address
                send_string vdvDEVICE,"'ADD_POLL=',ITOA(nTempValue)"
            } 
            ELSE
                send_string 0,"'ERROR - invalid number of arguments for ADD_POLL ',ITOA(uParameters.count)"
                              
        }  
        CASE 'AMX_BAUD=':
        {
            lTempBaudRate = ATOI(uParameters.param[1])  
            IF ( (lTempBaudRate == 1200)
                 || (lTempBaudRate == 2400)
                 || (lTempBaudRate == 4800)
                 || (lTempBaudRate == 9600)
                 || (lTempBaudRate == 19200)
                 || (lTempBaudRate == 38400)
                 || (lTempBaudRate == 57600) ) 
            {
                lBaudRate = lTempBaudRate
		        IF ( DEVICE_ID(dvDEVICE) < 256)  
                    SEND_COMMAND dvDEVICE,"'SET BAUD ',ITOA(lBaudRate),',N,8,1 485 ENABLE'"
                ELSE 
                    SEND_COMMAND dvDEVICE,"'TSET BAUD ',ITOA(lBaudRate),',N,8,1 485 ENABLE'" 
               
                SEND_STRING vdvDEVICE,"'AMX_BAUD=',ITOA(lBaudRate)" 
           }
           ELSE 
           {
                send_string 0,"'ERROR: Invalid argument for Baud Rate'" 
           }
        } 
        CASE 'AMX_BAUD?': 
        { 
            SEND_STRING vdvDEVICE,"'AMX_BAUD=',ITOA(lBaudRate)" 
        }
        CASE  'CLEAR_POLL':
        {
            for (i = 1; i <= nNumberPollItems; i++)
            {
                uModbusPollList[nNumberPollItems].nAddress = 0
                uModbusPollList[nNumberPollItems].nItemType = 0 
                uModbusPollList[nNumberPollItems].nValue = UNKNOWN
                uModbusPollList[nNumberPollItems].cZoneID = 0
                uModbusPollList[nNumberPollItems].cKey = 0   
             }
             nNumberPollItems = 0 
             SEND_STRING vdvDEVICE,"'CLEAR_POLL'" 
             
        }
        CASE 'DEBUG=' :
        {
            nTempValue = ATOI(uParameters.param[1])
            IF (fnRangeCheck(TYPE_CAST(nTempValue),0,2) ) 
            {
                nDebug = nTempValue 
                IF (nDebug)
                {
                    SEND_STRING 0, '>>>  Modbus COMM DEBUG IS NOW ON'
                    SEND_STRING vdvDEVICE,"'DEBUG=',ITOA(nTempValue)" // Turn UI debug ON
                }
                ELSE
                {
                    SEND_STRING 0, '>>> Modbus COMM DEBUG IS NOW OFF'
                    SEND_STRING vdvDEVICE,"'DEBUG=0'"             // turn UI debug OFF
                }
            }
            ELSE
                send_string 0,"'ERROR: Invalid argument for DEBUG ',uParameters.param[1]"
        }            

        CASE 'DEBUG?' :
        {
            SEND_STRING vdvDEVICE,"'DEBUG=',ITOA(nDebug)" 
            SEND_STRING 0,"'DEBUG=',ITOA(nDebug)" 
        }
        
        CASE 'passthru=':
        CASE 'PASSTHRU=':
        {                    
            fnEnq("DEFAULT_ZONE,DEFAULT_KEY,uParameters.rawData",USER_QUEUE) 
        } 
        CASE 'POLLTIME=':
        {
            STACK_VAR INTEGER nValue
                                
            nValue = ATOI (uParameters.param[1])
            //
            // kills and restarts timeline even if value is the same as it was previously  
            //             
            IF (nValue)
            {
                IF ((nValue >= MIN_POLL_TIME) && (nValue  <= MAX_POLL_TIME))
                {
                    IF (TIMELINE_ACTIVE(nPOLLTL) )
                       TIMELINE_KILL(nPOLLTL)
                       
                    lPollTLtime[1] = nValue * 1000
                    TIMELINE_CREATE(nPOLLTL, lPollTLtime, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT)
                }
                ELSE // nValue outside valid range 
                   send_string 0,"'Invalid POLLTIME value :',ITOA(nValue)"
            }
            ELSE // nValue = 0 
            {
                lPollTLtime[1] = nValue             // set to 0 for correct POLLTIME? value       
                IF (TIMELINE_ACTIVE(nPOLLTL) )      // avoid error if it's not active 
                    TIMELINE_KILL(nPOLLTL)
            } 
        }
        CASE 'POLLTIME?':
        {
            send_string vdvDEVICE,"'POLLTIME=',ITOA(lPollTLtime[1]/1000)"
        }                 
        CASE 'READ_COIL=': 
        CASE 'READ_DISCRETE=':
        CASE 'READ_HOLD=':
        CASE 'READ_INPUT=':
        {   
            // This code is exactly the same for all of the READ address cases
            // except for the address type value sent to the GET_ADDRESS routine
            //
            // Rather than repeat the following code block 4 times, I just use
            // this awkward duplicated switch case to determine the address type 
            // to be sent. CH
            SWITCH (sName)
            {
                CASE 'READ_COIL=': 
                {
                    nAddressType = COIL;
                }
                CASE 'READ_DISCRETE=': 
                {
                    nAddressType = DISCRETE_INPUT;
                }
                CASE 'READ_HOLD=':
                {
                    nAddressType = HOLDING_REGISTER; 
                }
                CASE 'READ_INPUT=':
                {
                    nAddressType = INPUT_REGISTER;
                }
            }

            //  Command parameters are <register address>, <register count>, [<zone ID>, <key>, <DEV=device address>]
	    //  fnGetAddress function call is <address>, <address type>, <number of items>, 
            //                    <zone ID>, <key>, <dev address>, <which queue>  
            SWITCH (uParameters.count)
            {
                CASE 1:        // <register address> only
                {
                    fnGet_Address(uParameters.param[1],    // address      
                                  nAddressType,            // hardcoded address type determined above
                                  "'1'",                   // hardcode - number of items    
                                  ITOA(DEFAULT_ZONE),      // hardcode - zone ID 
                                  ITOA(DEFAULT_KEY),       // hardcode - key 
				  ITOA(cStandardAddress),
                                  USER_QUEUE)  
                }
                CASE  2:        // <address>:<number of items>
                {
                    fnGet_Address(uParameters.param[1],    // address
                                  nAddressType,            // address type determined above
                                  uParameters.param[2],    // number of items to read
                                  ITOA(DEFAULT_ZONE),      // hardcode - zone ID 
                                  ITOA(DEFAULT_KEY),       // hardcode - key 
				  ITOA(cStandardAddress),
                                  USER_QUEUE)  
                }
                CASE 3:        // <address>:<zone ID>:<key>
                {
                    fnGet_Address(uParameters.param[1],    // address
                                  nAddressType,            // address type determined above
                                  "'1'",                   // hardcode - number of items  
                                  uParameters.param[2],    // zone ID 
                                  uParameters.param[3],    // key 
				  ITOA(cStandardAddress),
                                  USER_QUEUE)
                }           
                CASE 4:        // <address>:<number of items>:<zone ID>:<key>
                {
                    fnGet_Address(uParameters.param[1],    // address      
                                  nAddressType,            // address type determined above
                                  uParameters.param[2],	   // number of items to get
                                  uParameters.param[3],    // zone ID 
                                  uParameters.param[4],    // key 
				  ITOA(cStandardAddress),
                                  USER_QUEUE)  
                } 
                CASE 5:        // <address>:<number of items>:<zone ID>:<key>:<device address> 
                {
                    REMOVE_STRING(uParameters.param[5],'DEV=',1)	// Remove dev addr leader
                    IF (fnRangeCheck(TYPE_CAST(nTempValue),MIN_ADDRESS,MAX_ADDRESS))
                    {
                        fnGet_Address(uParameters.param[1],    // address      
				            nAddressType,            // address type determined above
				            uParameters.param[2],	   // number of items to get
				            uParameters.param[3],    // zone ID 
				            uParameters.param[4],    // key 
				            uParameters.param[5],	   // specific device address
				            USER_QUEUE)  
                    }
                    ELSE
                        send_string 0,"'ERROR:  Device Address is out of range ',uParameters.param[1]"
                } 
                DEFAULT:
                {
                    send_string 0,"'ERROR - Invalid number of parameters ',ITOA(uParameters.count)" 
                }
            }    // END OF - switch on number of arguments
        }   // END OF - READ_COIL, READ_DISCRETE, READ_HOLD, READ_INPUT  
  
        CASE 'WRITE_COIL=':            // ON or OFF to SINGLE COIL 
        {
            IF (uParameters.count == 2) 
            {
                cDeviceAddress = cStandardAddress
                fnSet_Coil(uParameters.param[1],    // address      
                        uParameters.param[2],     // value to write
                        ITOA(DEFAULT_ZONE),      // hardcode - zone ID 
                        ITOA(DEFAULT_KEY) )       // hardcode - key 
            } 
            ELSE IF (uParameters.count == 4)
            {
                cDeviceAddress = cStandardAddress
                fnSet_Coil(uParameters.param[1],     // address
                               uParameters.param[2],     // value to write
                               uParameters.param[3],     // zone ID
                               uParameters.param[4] )     // key
            }   
            ELSE IF (uParameters.count == 5)	// Explicit device address
            {
                IF (fnRangeCheck(TYPE_CAST(ATOI(uParameters.param[5])),MIN_ADDRESS,MAX_ADDRESS))
                {
	               cDeviceAddress = TYPE_CAST(ATOI(uParameters.param[5]))   // specific device address
	               fnSet_Coil(uParameters.param[1],     // address
				        uParameters.param[2],     // value to write
				        uParameters.param[3],     // zone ID
				        uParameters.param[4])     // key
                }
                ELSE
                    send_string 0,"'ERROR:  Device Address is out of range ',uParameters.param[1]"
            }   
            ELSE
            {
                send_string 0,"'ERROR - Invalid number of parameters ',ITOA(uParameters.count)" 
            }
        }
        CASE 'WRITE_HOLD=':         // SINGLE VALUE to HOLDING REGISTER      
        {    
            IF (uParameters.count == 2)
            {
                cDeviceAddress = cStandardAddress
                fnSet_Register(uParameters.param[1],    // address      
                               uParameters.param[2],     // value to write
                               ITOA(DEFAULT_ZONE),      // hardcode - zone ID 
                               ITOA(DEFAULT_KEY) )       // hardcode - key 
            }   
            ELSE IF (uParameters.count == 4) 
            {
                cDeviceAddress = cStandardAddress
                fnSet_Register(uParameters.param[1],     // address
                               uParameters.param[2],     // value to write
                               uParameters.param[3],     // zone ID
                               uParameters.param[4] )     // key
            } 
            ELSE IF (uParameters.count == 5) 
            {
                IF (fnRangeCheck(TYPE_CAST(ATOI(uParameters.param[5])),MIN_ADDRESS,MAX_ADDRESS))
                {
                    cDeviceAddress = TYPE_CAST(ATOI(uParameters.param[5]))   // specific device address
                    fnSet_Register(uParameters.param[1],     // address
                        uParameters.param[2],     // value to write
                        uParameters.param[3],     // zone ID
                        uParameters.param[4])     // key
                }
                ELSE
                    send_string 0,"'ERROR:  Device Address is out of range ',uParameters.param[1]"
            } 
            ELSE
            {
                send_string 0,"'ERROR - Invalid number of parameters ',ITOA(uParameters.count)" 
            }
         }
        
        CASE 'VERSION?':
        {           
            send_string 0,"'VERSION=',sVERSION" 
            send_string vdvDEVICE, "'VERSION=',sVERSION"
        }
    }   // END SWITCH (sName) 
}

// Name   : ==== fnProcessStrFromDev ====
// Purpose:  parses the responses from the device and takes the appropriate action(s) 
//
// Params : (1) sReplyArray passed as the individual parsed reply 
//           from the receive buffer 
//        
// Returns: None
// Notes  : None
//
DEFINE_FUNCTION fnProcessStrFromDev(CHAR sReplyArray[])
{
 
    STACK_VAR CHAR sJunk[25]
    STACK_VAR CHAR sErrorMsg[128]
    STACK_VAR INTEGER nTempIndex
    STACK_VAR INTEGER nDevAddress
    STACK_VAR INTEGER nTempAddress
    STACK_VAR INTEGER nTempValue 
    STACK_VAR INTEGER nTempLength             // number of BYTES        
    STACK_VAR INTEGER nTempNumber             // number of VALUES requested
    STACK_VAR CHAR sTempValueString[128]
    STACK_VAR INTEGER i 
    STACK_VAR INTEGER nOffSet   
    STACK_VAR INTEGER nCheckSumPosition 
    STACK_VAR CHAR cReplyCrcHigh
    STACK_VAR CHAR cReplyCrcLow   
       
    IF ( nDebug )
        NetHex(0, "ITOA( __LINE__ ), 'fnProcessStrFromDev'", sReplyArray,NO_ASCII) 
    
    nDevAddress = sReplyArray[1]	// Device address
    
    // 
    // VERIFY CHECK SUM 
    //
    // version 1.1 Check sum verification is used to detect 
    // whether partial messages come in or not.  In the case
    // of an actual check-sum error instead of a partial message, 
    // the buffer will be cleared by the WAIT FOR REPLY timeout....
    // 
    nCheckSumPosition = LENGTH_STRING(sReplyArray)
    cReplyCrcHigh = sReplyArray[nCheckSumPosition]
    cReplyCrcLow = sReplyArray[nCheckSumPosition-1]

    // strip off check sum bytes before calculating the check sum to verify against 
    SET_LENGTH_STRING(sReplyArray, nCheckSumPosition-2) 
    fnCalcCheckSum(sReplyArray)
    
    IF ( (cReplyCrcHigh != cCrcHigh) OR 
         (cReplyCrcLow != cCrcLow ) )
    {
        send_string 0,"'ERROR: Checksum verification failed, possible partial message'";
	// 
	//   checksum verification could fail due to partial message
	//   being received.  in this case we need to add the checksum
	//   bytes back again. 
	//
        SET_LENGTH_STRING(sReplyArray, nCheckSumPosition+2) 
        bStringOK = FALSE;
        return; 	// leaves wait for reply active 
    }
    // SMA - rev 1.6 - added because bString was never being set to true, so the conditional
    // on line 1839 was never being met, so the buffer wasn't being cleared.    
    ELSE
    {
        bStringOK = TRUE;  // SMA - 1.6
    }
    
    // get address of applicable register from last command sent      
    nTempAddress = fnBytesToInt(sLastCommandSent[3],sLastCommandSent[4])
    
    // get number of values being returned from last command sent
    // we cannot determine how many values for bit registers because
    // of zero padding. 
    nTempNumber = fnBytesToInt(sLastCommandSent[5],sLastCommandSent[6])
            
    SWITCH (sReplyArray[2])
    {
        CASE 1:           // READ COIL 
        {              
            IF (nPollReply)
            {
                 // this works fine for a single value                 
                IF (sReplyArray[4] != 0)
                  nTempValue = 1
                ELSE
                  nTempValue = 0 
                  
                nTempIndex = fnFindPollItem(nTempAddress,COIL) 
                IF (nTempIndex)
                {   
                    // only send up if data value has changed 
                    IF (nTempValue != uModbusPollList[nTempIndex].nValue)
                    {
                        uModbusPollList[nTempIndex].nValue = nTempValue
                        // send value to UI  include ZONE ID and KEY ID 
                        SEND_STRING vdvDEVICE,"'READ_COIL=',
                                                ITOA(nTempAddress),
                                                ':1',                       // hardcode number 
                                                ':',ITOA(nTempValue),  
                                                ':',ITOA(cZoneIdSaved), 
                                                ':',ITOA(cKeySaved),
						':DEV=',ITOA(nDevAddress)" 
                    } 
                    ELSE
                    {
                        IF (nDebug) send_string 0,"'Data value did not change ',ITOA(nTempValue)"
                    } 
                }   // END OF - value was found in poll list
                ElSE
                    send_string 0,"'ERROR: Poll Reply address NOT found in poll list for COIL',ITOA(nTempAddress)"                
            }   
            ELSE    // command was user initiated
            {
                // NOT POLLING, just send value up to UI   include ZONE ID and KEY ID 
                //
                //        handle MULTIPLE register responses - repeat for number of bytes 
                //       indicated by byte count sReplyArray[3] 
                nTempLength = sReplyArray[3]
                
                FOR ( i=0; i < nTempLength; i++)
                {   
                    // data values start at byte 4
                    nOffSet = 4 + i
                    nTempValue = sReplyArray[nOffSet]
                    
                    // handle comma separator for multiple values 
                    IF (i = 0)
                        sTempValueString = "ITOA(nTempValue)" 
                    ELSE
                        sTempValueString = "sTempValueString,',',ITOA(nTempValue)" 
                        
                }    // END OF - for loop all data values 
                
                SEND_STRING vdvDEVICE,"'READ_COIL=',
                                        ITOA(nTempAddress),
                                        ':',ITOA(nTempNumber),
                                        ':',sTempValueString,  
                                        ':',ITOA(cZoneIdSaved), 
                                        ':',ITOA(cKeySaved),
					':DEV=',ITOA(nDevAddress)"
            }
        }
        CASE 2:           // READ DISCRETE INPUT(s)
        {
            // TO DO handle MULTIPLE register responses - repeat for number of bytes 
            //       indicated by byte count sReplyArray[3]
             
            IF (nPollReply)
            {
                // this works fine for a single value 
                // if multiple values are being read, 
                // then bitwise operations must be performed.
                
                IF (sReplyArray[4] != 0)
                  nTempValue = 1
                ELSE
                  nTempValue = 0
                
                nTempIndex = fnFindPollItem(nTempAddress,DISCRETE_INPUT) 
                IF (nTempIndex)
                {   
                    // only send up if data value has changed 
                    IF (nTempValue != uModbusPollList[nTempIndex].nValue)
                    {
                        uModbusPollList[nTempIndex].nValue = nTempValue
                        // send value to UI  include ZONE ID and KEY ID 
                        SEND_STRING vdvDEVICE,"'READ_DISCRETE=',
                                                ITOA(nTempAddress),
                                                ':1',                       // hardcode number 
                                                ':',ITOA(nTempValue),  
                                                ':',ITOA(cZoneIdSaved), 
                                                ':',ITOA(cKeySaved),
						':DEV=',ITOA(nDevAddress)" 
                    }  
                    ELSE
                    {
                        IF (nDebug) send_string 0,"'Data value did not change ',ITOA(nTempValue)"
                    } 
                }   // END OF - value was found in poll list                  
                ElSE
                    send_string 0,"'ERROR: Poll Reply address NOT found in poll list for D.I.',ITOA(nTempAddress)"                
            }   
            ELSE    // command was user initiated
            {
                // NOT POLLING, just send value up to UI   include ZONE ID and KEY ID 
                //
                //        handle MULTIPLE register responses - repeat for number of bytes 
                //       indicated by byte count sReplyArray[3]
                
                nTempLength = sReplyArray[3]
                
                FOR ( i=0; i < nTempLength; i++)
                {   
                    // data values start at byte 4
                    nOffSet = 4 + i
                    nTempValue = sReplyArray[nOffSet]
                    
                    // handle comma separator for multiple values 
                    IF (i = 0)
                        sTempValueString = "ITOA(nTempValue)" 
                    ELSE
                        sTempValueString = "sTempValueString,',',ITOA(nTempValue)" 
                        
                }    // END OF - for loop all data values 
                SEND_STRING vdvDEVICE,"'READ_DISCRETE=',
                                        ITOA(nTempAddress),
                                        ':',ITOA(nTempNumber),
                                        ':',sTempValueString,  
                                        ':',ITOA(cZoneIdSaved), 
                                        ':',ITOA(cKeySaved),
					':DEV=',ITOA(nDevAddress)"
            }
        }
        CASE 3:            // READ HOLDING REGISTER(s)
        {            
            IF (nPollReply)
            {
                nTempValue = fnBytesToInt(sReplyArray[4],sReplyArray[5])  
            
                nTempIndex = fnFindPollItem(nTempAddress,HOLDING_REGISTER) 
                IF (nTempIndex)
                {   
                    // only send up if data value has changed 
                    IF (nTempValue != uModbusPollList[nTempIndex].nValue)
                    {
                        uModbusPollList[nTempIndex].nValue = nTempValue
                        // send value to UI  include ZONE ID and KEY ID 
                        SEND_STRING vdvDEVICE,"'READ_HOLD=',
                                                ITOA(nTempAddress),
                                                ':',ITOA(nTempValue),  
                                                ':',ITOA(cZoneIdSaved), 
                                                ':',ITOA(cKeySaved)" 
                    }  
                    ELSE
                    {
                        IF (nDebug) send_string 0,"'Data value did not change ',ITOA(nTempValue)"
                    } 
                }   // END OF - value was found in poll list                  
                ElSE
                    send_string 0,"'ERROR: Poll Reply address NOT found in poll list for HOLD',ITOA(nTempAddress)"                
            }   
            ELSE    // command was user initiated
            {     
               // NOT POLLING, just send value up to UI   include ZONE ID and KEY ID 
               //
               // Handle MULTIPLE register responses - repeat for number of bytes 
               //       indicated by byte count sReplyArray[3]                          
            
               // two bytes for every data value 
                nTempLength = sReplyArray[3]/2
                
                FOR ( i=0; i < nTempLength; i++)
                {   
                    // data values start at byte 4, with two bytes per data value
                    // i.e.  first data value is at bytes 4 and 5, second is at 6 & 7, etc. 
                    //
                    nOffSet = 4 + (2 * i)
                    nTempValue = fnBytesToInt(sReplyArray[nOffSet],sReplyArray[nOffSet + 1])
                    
                    // handle comma separator for multiple values 
                    IF (i = 0)
                        sTempValueString = "ITOA(nTempValue)" 
                    ELSE
                        sTempValueString = "sTempValueString,',',ITOA(nTempValue)" 
                        
                }    // END OF - for loop all data values 
                SEND_STRING vdvDEVICE,"'READ_HOLD=',
                                        ITOA(nTempAddress),
                                        ':',sTempValueString,  
                                        ':',ITOA(cZoneIdSaved), 
                                        ':',ITOA(cKeySaved),
					':DEV=',ITOA(nDevAddress)"
            }
        }  
        CASE 4:            // READ INPUT REGISTER(s)
        {
            IF (nPollReply)
            {
                nTempValue = fnBytesToInt(sReplyArray[4],sReplyArray[5]) 
                 
                nTempIndex = fnFindPollItem(nTempAddress,INPUT_REGISTER) 
                IF (nTempIndex)
                {   
                    // only send up if data value has changed 
                    IF (nTempValue != uModbusPollList[nTempIndex].nValue)
                    {
                        uModbusPollList[nTempIndex].nValue = nTempValue
                        // send value to UI  include ZONE ID and KEY ID 
                        SEND_STRING vdvDEVICE,"'READ_INPUT=',
                                                ITOA(nTempAddress),
                                                ':',ITOA(nTempValue),  
                                                ':',ITOA(cZoneIdSaved), 
                                                ':',ITOA(cKeySaved),
						':DEV=',ITOA(nDevAddress)" 
                    }  
                    ELSE
                    {
                        IF (nDebug) send_string 0,"'Data value did not change ',ITOA(nTempValue)"
                    } 
                }   // END OF - value was found in poll list                  
                ElSE
                    send_string 0,"'ERROR: Poll Reply address NOT found in poll list for INPUT',ITOA(nTempAddress)"                
            }  
            ELSE    // command was user initiated
            {
               // NOT POLLING, just send value up to UI   include ZONE ID and KEY ID 
               //
               // Handle MULTIPLE register responses - repeat for number of bytes 
               //       indicated by byte count sReplyArray[3]                          
            
               // two bytes for every data value 
                nTempLength = sReplyArray[3]/2
                
                FOR ( i=0; i < nTempLength; i++)
                {   
                    // data values start at byte 4, with two bytes per data value
                    // i.e.  first data value is at bytes 4 and 5, second is at 6 & 7, etc. 
                    //
                    nOffSet = 4 + (2 * i)
                    nTempValue = fnBytesToInt(sReplyArray[nOffSet],sReplyArray[nOffSet + 1])
                    
                    // handle comma separator for multiple values 
                    IF (i = 0)
                        sTempValueString = "ITOA(nTempValue)" 
                    ELSE
                        sTempValueString = "sTempValueString,',',ITOA(nTempValue)" 
                        
                }    // END OF - for loop all data values 
                
                SEND_STRING vdvDEVICE,"'READ_INPUT=',
                                         ITOA(nTempAddress), 
                                         ':',sTempValueString,  
                                         ':',ITOA(cZoneIdSaved), 
                                         ':',ITOA(cKeySaved),
					 ':DEV=',ITOA(nDevAddress)" 
             }
        }   // END OF - CASE  
        CASE 5:            // WRITE SINGLE COIL 
        {
            nTempValue = fnBytesToInt(sReplyArray[5],sReplyArray[6]) 
            
            //  response is FF00 for ON or 0000 for OFF 
            //  0000 = 0 = same as API OFF value 
            IF (nTempValue == $FF00)
            {
                nTempValue = 1
            } 
                        
            SEND_STRING vdvDEVICE,"'WRITE_COIL=',ITOA(nTempAddress),':',ITOA(nTempValue),
                                        ':',ITOA(cZoneIdSaved),':',ITOA(cKeySaved),
					':DEV=',ITOA(nDevAddress)" 
        }
        CASE 6:            // WRITE SINGLE REGISTER
        {
            nTempValue = fnBytesToInt(sReplyArray[5],sReplyArray[6]) 
            
            SEND_STRING vdvDEVICE,"'WRITE_HOLD=',ITOA(nTempAddress),':',ITOA(nTempValue),
                                        ':',ITOA(cZoneIdSaved),':',ITOA(cKeySaved),
					':DEV=',ITOA(nDevAddress)" 
        }
        CASE 15:           // WRITE MULTIPLE COILS
        {
            // place holder for future expansion
        }
        CASE 16:           // WRITE MULTIPLE REGISTERS
        {
            // place holder for future expansion
        }
        CASE 23:           // READ/WRITE MULTIPLE REGISTERS 
        {
            // place holder for future expansion
        }
        CASE $81:
        CASE $82:
        CASE $83:
        CASE $84:
        CASE $85:
        CASE $86:
        CASE $8F:
        CASE $90:
        CASE $97:
        {
            SWITCH (sReplyArray[3])
            {
                CASE $01: 
                {
                    sErrorMsg =  "',ILLEGAL FUNCTION'"
                }
                CASE $02:
                {
                    sErrorMsg =  "',ILLEGAL DATA ADDRESS'"
                }
                CASE $03:
                {
                    sErrorMsg =  "',ILLEGAL DATA VALUE'"
                }
                CASE $04:
                {
                    sErrorMsg =  "',SLAVE DEVICE FAILURE'"
                }
                CASE $05:
                {
                    sErrorMsg =  "',ACKNOWLEDGE'"
                }
                CASE $06:
                {
                    sErrorMsg =  "',SLAVE DEVICE BUSY'"
                }
                CASE $08:
                {
                    sErrorMsg =  "',MEMORY PARITY ERROR'"
                }
                CASE $0A:
                {
                    sErrorMsg =  "',GATEWAY PATH UNAVAILABLE'"
                }
                CASE $0B:
                {
                    sErrorMsg =  "',GATEWAY FAILED TO RESPOND'"
                }
                DEFAULT : 
                {
                    sErrorMsg =  "',Code not recognized'" 
                }
            }    // END OF - switch on exception code 
            send_string vdvDEVICE,"'ERRORM=Function-',ITOA(sReplyArray[2]),' Code-',ITOA(sReplyArray[3]),sErrorMsg" 
        }   // END OF - stacked error cases    
    }   // END OF - switch on function code  sReplyArray [2]
    
    IF (bWaitForReply)
    {
        bWaitForReply = FALSE;
    }  
}    // END OF - fnProcessStrFromDev 

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

CREATE_BUFFER dvDEVICE, sRxBuff 

TIMELINE_CREATE(nPOLLTL, lPollTLtime, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT)
TIMELINE_CREATE(nTL_Deque, lDequeTLtime, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT)
(***********************************************************)
(*                THE EVENTS GOES BELOW                    *)
(***********************************************************)
DEFINE_EVENT

DATA_EVENT[dvDEVICE]
{
    ONLINE:
    {
        SEND_COMMAND dvDEVICE,"'SET BAUD ',ITOA(lBaudRate),',N,8,1 485 DISABLE'"
        //SEND_COMMAND dvDEVICE,"'SET BAUD ',ITOA(lBaudRate),',N,8,1 485 ENABLE'"
        SEND_COMMAND dvDEVICE,'HSOFF' 
        SEND_COMMAND dvDEVICE,'XOFF'        
    }//END ONLINE
    OFFLINE:
    {
    }//END OFFLINE
    STRING:
    {
        // Version 1.1  Modified to handle partial string responses from
        // the Modbus device.  We will still only get one response at a time, 
        // so I don't handle the case of multiple responses being received,
        // i.e. (using a while loop) 
        // but do handle the case of a partial message being received. 
	
        // partial messages will get cleared from the buffer by the regular
        // reply timeout. 
        fnProcessStrfromDev(sRxBuff)
	
        // bStringOK indicates whether a complete message was received.
        // If so, then clear the receive buffer, and proceed with the 
        // next message. If not, wait for the next string event to trigger.
        if (bStringOK == TRUE)
        {
            sRxBuff ='' 
            fnDEQ();
        }
    }       // END OF - DATA_EVENT STRING
}//END DATA_EVENT[dvDEVICE]

DATA_EVENT[vdvDEVICE]
{
    COMMAND:
    {
        IF (!FIND_STRING(DATA.TEXT, 'PASSTHRU=',1) && 
            !FIND_STRING(DATA.TEXT,'passthru=',1))   
        {
            DATA.TEXT = UPPER_STRING (DATA.TEXT)
        }  
        fnProcessAPICommands(DATA.TEXT)
    }    
}//END DATA_EVENT[vdvDEVICE]   

TIMELINE_EVENT[nPOLLTL]
{
    stack_var integer i 
    stack_var char dev_addr[5]
    
    IF (nDebug)    
        send_string 0,"'polling now !'" 
        
    // Loop through poll items, stop if end of notify list
    for (i = 1; i <= nNumberPollItems; i++)
    { 
        IF (nDebug)    
            send_string 0,"'poll loop:',ITOA(uModbusPollList[i].nDevAddress)" 
	
        if (uModbusPollList[i].nDevAddress == 0)
            {dev_addr = ITOA(cDeviceAddress)}	// Use current address
        else
            {dev_addr = ITOA(uModbusPollList[i].nDevAddress)}
	
        IF (nDebug)    
            send_string 0,"'poll getAddr:',dev_addr"

        fnGet_Address(ITOA(uModbusPollList[i].nAddress),
                      uModbusPollList[i].nItemType,
                      "'1'", 	// One item to read
                      ITOA(uModbusPollList[i].cZoneID),
                      ITOA(uModbusPollList[i].cKey),
		              dev_addr,
                      STATUS_QUEUE)
    }
}

TIMELINE_EVENT[nTL_DEQUE]  // Timeout - no reply - v1.5 - to replace WAIT timeout
{
    IF (nDebug) { SEND_STRING 0, "'No reply received; clear flag, dequeue next cmd'" }
    bWaitForReply = FALSE
    // clear out anything in serial port rcv buffer  
    sRxBuff = '';
    send_command dvDevice,"'RXCLR'";	
    fnDEQ();  // Send next command in queue
}

(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM
(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)








