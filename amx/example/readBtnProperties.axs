PROGRAM_NAME='G4 Custom Events'
(************************************************* **********)
(* FILE_LAST_MODIFIED_ON: 04/26/2005 AT: 10:29:47 *)
(************************************************* **********)

(*{{PS_SOURCE_INFO(PROGRAM STATS) *)
(* ORPHAN_FILE_PLATFORM: 1 *)
(*}}PS_SOURCE_INFO *)

(************************************************* **********)
(* DEVICE NUMBER DEFINITIONS GO BELOW *)
(************************************************* **********)
DEFINE_DEVICE

TP = 29006:1:4073

TPDebug = 0:1:4073

(************************************************* **********)
(* CONSTANT DEFINITIONS GO BELOW *)
(************************************************* **********)
DEFINE_CONSTANT

(************************************************* **********)
(* DATA TYPE DEFINITIONS GO BELOW *)
(************************************************* **********)
DEFINE_TYPE

(************************************************* **********)
(* VARIABLE DEFINITIONS GO BELOW *)
(************************************************* **********)
DEFINE_VARIABLE


(************************************************* **********)
(* LATCHING DEFINITIONS GO BELOW *)
(************************************************* **********)
DEFINE_LATCHING

(************************************************* **********)
(* MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW *)
(************************************************* **********)
DEFINE_MUTUALLY_EXCLUSIVE

(************************************************* **********)
(* SUBROUTINE/FUNCTION DEFINITIONS GO BELOW *)
(************************************************* **********)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)

(************************************************* **********)
(* STARTUP CODE GOES BELOW *)
(************************************************* **********)
DEFINE_START

//CREATE_BUFFER TP,TP_BUFFER

(************************************************* **********)
(* THE EVENTS GO BELOW *)
(************************************************* **********)
DEFINE_EVENT

(* Custome Events - For button Information *)

CUSTOM_EVENT[TP,527,1001] // Text
CUSTOM_EVENT[TP,528,1001] // Text
CUSTOM_EVENT[TP,529,1001] // Text
CUSTOM_EVENT[TP,529,1002] // Bitmap
CUSTOM_EVENT[TP,529,1003] // Icon
CUSTOM_EVENT[TP,529,1004] // Text Justification
CUSTOM_EVENT[TP,529,1005] // Bitmap Justification
CUSTOM_EVENT[TP,529,1006] // Icon Justification
CUSTOM_EVENT[TP,529,1007] // Font
CUSTOM_EVENT[TP,529,1008] // Text Effect Name
CUSTOM_EVENT[TP,529,1009] // Text Effect Color
CUSTOM_EVENT[TP,529,1010] // Word Wrap
CUSTOM_EVENT[TP,529,1011] // ON st Border Color
CUSTOM_EVENT[TP,529,1012] // ON st Fill Color
CUSTOM_EVENT[TP,529,1013] // ON st Text Color
CUSTOM_EVENT[TP,529,1014] // Border Name
CUSTOM_EVENT[TP,529,1015] // Opacity

{
    SEND_STRING 0,"'start of custom event code'" // Entered for debug
    Send_String 0,"'ButtonGet Id=',ITOA(CUSTOM.ID),' Type=',ITOA(CUSTOM.TYPE)"
    Send_String 0,"'Flag =',ITOA(CUSTOM.FLAG)"
    Send_String 0,"'VALUE1 =',ITOA(CUSTOM.VALUE1)"
    Send_String 0,"'VALUE2 =',ITOA(CUSTOM.VALUE2)"
    Send_String 0,"'VALUE3 =',ITOA(CUSTOM.VALUE3)"
    Send_String 0,"'TEXT =',CUSTOM.TEXT"
    Send_String 0,"'TEXT LENGTH =',ITOA(LENGTH_STRING(CUSTOM.TEXT))"
}


BUTTON_EVENT [TP,50]
{
    PUSH:
    {
        SEND_COMMAND TP,"'?TXT-529,1&2'" //1001-Read Text
        SEND_COMMAND TP,"'?TXT-528,1'" //1001-Read Unicode Text
        SEND_COMMAND TP,"'?TXT-527,1'" //1001-Read Long Text
        SEND_COMMAND TP,"'?TXT-527,1,274'" //1001-Read text with Index
        
        SEND_COMMAND TP,"'?BMP-529,1&2'" //1002-Read Bitmap Name
        SEND_COMMAND TP,"'?ICO-529,1&2'" //1003-Read Icon Name
        SEND_COMMAND TP,"'?JST-529,1&2'" //1004-Read Text Justification
        SEND_COMMAND TP,"'?JSB-529,1&2'" //1005-Read Bitmap Justification
        SEND_COMMAND TP,"'?JSI-529,1&2'" //1006-Read Icon Justification
        SEND_COMMAND TP,"'?FON-529,1&2'" //1007-Read Font
        SEND_COMMAND TP,"'?TEF-529,1&2'" //1008-Read Text Effect Name
        SEND_COMMAND TP,"'?TEC-529,1&2'" //1009-Read Text Effect Color
        SEND_COMMAND TP,"'?BWW-529,1&2'" //1010-Read Word Wrap
        SEND_COMMAND TP,"'?BCB-529,1&2'" //1011-Read Border Color
        SEND_COMMAND TP,"'?BCF-529,1&2'" //1012-Read Fill Color
        SEND_COMMAND TP,"'?BCT-529,1&2'" //1013-Read Text Color
        SEND_COMMAND TP,"'?BRD-529,1&2'" //1014-Read Border Name
        SEND_COMMAND TP,"'?BOP-529,1&2'" //1015-Read Button Opacity
    }
}



(************************************************* **********)
(* THE ACTUAL PROGRAM GOES BELOW *)
(************************************************* **********)
DEFINE_PROGRAM

(************************************************* **********)
(* END OF PROGRAM *)
(* DO NOT PUT ANY CODE BELOW THIS COMMENT *)
(************************************************* **********)
