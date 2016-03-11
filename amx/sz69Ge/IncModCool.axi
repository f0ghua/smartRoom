PROGRAM_NAME='IncModCool'

DEFINE_DEVICE
vdMod = 33109:1:0

DEFINE_CONSTANT
CHAR DvTpTy     =1
CHAR DvTpMax    =1
// Ty.Type.Name
CHAR TyTpJVC    = 40	//DLA-XC(5/6/7)880R

DEFINE_VARIABLE
DEV aMdDev[DvTpMax]     //MAX = Dev.Type
CHAR aMdA[] = {1, 2, 3}

DEFINE_CALL 'fnDoTy'(DEV ToDev,CHAR TyType,CHAR DoID)
{
    aMdDev[DvTpTy] = ToDev
    aMdA[1] = TyType
    //SEND_STRING ToDev,"ITOA(ToDev.PORT),',',ITOA(TyType),',',ITOA(DoID),',',ITOA(DvTpTy)"
    SEND_LEVEL vdMod, DvTpTy, DoID
}

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START
