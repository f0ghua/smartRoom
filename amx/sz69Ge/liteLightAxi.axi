PROGRAM_NAME='liteLightAxi'

//
// The AVB-ABS module has following addresses inside:
//   30-39  Strong electrical controls' address (each address has 8 circuit)
//   40-49  Dimmer address(each address has 4 circuit)
//   50-59  Temperature control panel address
//   60-89  Keypad address(each address has 8 circuit)
//
// In our project, just use address from 30-49, for light and dimmer
//

//****************************************************************
// DESCRIPTION:
//
//    Close the relay which indicated by parameters
//
// ARGUMENTS:
//
//    vdvLight :  virtual devices which controls the relay module
//
//    nNumber  :  The address number of light controls [30 ~ 39]
//
//    nChannel :  The index of the relay
//
// RETURN:
//
//    None
//
//****************************************************************
DEFINE_FUNCTION fnOn(dev vdvLight,integer nNumber,integer nChannel)
{
    send_command vdvLight,
    	"'fnOn',ITOA(nNumber),'-',ITOA(nChannel),'*'"
}

//****************************************************************
// DESCRIPTION:
//
//    Open the relay which indicated by parameters
//
// ARGUMENTS:
//
//    vdvLight :  virtual devices which controls the relay module
//
//    nNumber  :  The address number of light controls [30 ~ 39]
//
//    nChannel :  The index of the relay
//
// RETURN:
//
//    None
//
//****************************************************************
DEFINE_FUNCTION fnOff(dev vdvLight,integer nNumber,integer nChannel)
{
     send_command vdvLight,
     	"'fnOff',ITOA(nNumber),'-',ITOA(nChannel),'*'"
}

//****************************************************************
// DESCRIPTION:
//
//    Dim up the specific light
//
// ARGUMENTS:
//
//    vdvLight :  virtual devices which controls the relay module
//
//    nNumber  :  The address number of light controls [30 ~ 39]
//
//    nChannel :  The index of the relay
//
// RETURN:
//
//    None
//
//****************************************************************
DEFINE_FUNCTION fnDimUp(dev vdvLight,integer nNumber,integer nChannel)
{
     send_command vdvLight,
     	"'fnDimUp',ITOA(nNumber),'-',ITOA(nChannel),'*'"
}

//****************************************************************
// DESCRIPTION:
//
//    Dim down the specific light
//
// ARGUMENTS:
//
//    vdvLight :  virtual devices which controls the relay module
//
//    nNumber  :  The address number of light controls [30 ~ 39]
//
//    nChannel :  The index of the relay
//
// RETURN:
//
//    None
//
//****************************************************************
DEFINE_FUNCTION fnDimDn(dev vdvLight,integer nNumber, integer nChannel)
{
    send_command vdvLight,
    	"'fnDimDn',ITOA(nNumber),'-',ITOA(nChannel),'*'"
}

//****************************************************************
// DESCRIPTION:
//
//   Stop the dimmer
//
// ARGUMENTS:
//
//    vdvLight :  virtual devices which controls the relay module
//
//    nNumber  :  The address number of light controls [30 ~ 39]
//
//    nChannel :  The index of the relay
//
// RETURN:
//
//    None
//
//****************************************************************
DEFINE_FUNCTION fnDimStop(dev vdvLight,integer nNumber , integer nChannel)
{
    send_command vdvLight,
    	"'fnDimStop',ITOA(nNumber),'-',ITOA(nChannel),'*'"
}

//****************************************************************
// DESCRIPTION:
//
//   Set the dim value of a spcific light
//
// ARGUMENTS:
//
//    vdvLight :  virtual devices which controls the relay module
//
//    nNumber  :  The address number of light controls [30 ~ 39]
//
//    nChannel :  The index of the relay
//
//    nLevelValue :  The level's value [0 ~ 100]
//
//    nTime :  The time will be taken from current dim value to nLevelValue
//
// RETURN:
//
//    None
//
//****************************************************************
DEFINE_FUNCTION fnDimLevel(dev vdvLight, integer nNumber, integer nChannel, 
		integer nLevelValue, integer nTime)
{
    send_command vdvLight,
    	"'fnDimLevel',ITOA(nNumber),'-',ITOA(nChannel),'-',
    	ITOA(nLevelValue),'-',ITOA(nTime),'*'"
}
