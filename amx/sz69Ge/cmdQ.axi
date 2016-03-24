// http://www.amxforums.com/forum/technical-forum/tips-and-tricks/5535-queuing-methods
(*

I generally use a combination of the timed based cueing and feedback. 

If you set up your timeline which fires the commands out to do so at the
interval specified as the minimum consecutive command gap (if your lucky it
may be in the protocol, otherwise 40ms seems to be about right for a lot of
devices) but combine it with an ACK timeout (say 1 second).

That way each iteration of the timeline will fire of the next command in the
cue if the previous command has been an acknowledged, otherwise it will skip
it and wait until the next timeline event until the timeout has been reached.

previous command  acknowledged/timeout
next command

If the ACK times out it will try and send the command again up to 3 times,
after 3 connsecutive time outs it will bin the command and flag an error -
either in RMS if applicable or just send it to 0:0:0 so I can see it as I
debug.

That way you're verifying all commands for devices that give you nice feedback
(for the ones that don't you can always set up some seperate polling logic and
make sure its always in the state your code is expecting it to be so no one
can play with those damn hardware buttons), and making sure your system
doesn't completely lock up in the event of something going wrong. Additionally
it will always be firing out the commands as fast as the device can accept
them.

*)
(***********************************************************)
(*  FILE CREATED ON: 08/02/2008  AT: 11:04:56              *)
(***********************************************************)
(***********************************************************)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 08/02/2008  AT: 11:31:30        *)
(***********************************************************)


(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT //fnQueueTheCommand, fnSendtheCommand
INTEGER TL_Queue = 101

MAX_CMD_SIZE  = 64
MAX_Q_LEN     = 64
(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

STRUCTURE _sCmdQueue
{
  DEV   dvSendtoDevice
  CHAR  cCmdtoSend[MAX_CMD_SIZE]
}

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE //fnQueueTheCommand, fnSendtheCommand
_sCmdQueue _CmdQueue[MAX_Q_LEN]  
VOLATILE LONG nSendSpacing[1]=  {200} //Time between commands

PERSISTENT INTEGER nCurrentQSendingPosition
PERSISTENT INTEGER nCurrentQueueingPosition



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
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)
DEFINE_FUNCTION fnQueueTheCommand(DEV dvDevice, CHAR cMsg[MAX_CMD_SIZE])
{
  _CmdQueue[nCurrentQueueingPosition].dvSendtoDevice    =   dvDevice
  _CmdQueue[nCurrentQueueingPosition].cCmdtoSend        =   cMsg
  nCurrentQueueingPosition++
  IF (nCurrentQueueingPosition > MAX_Q_LEN)
     nCurrentQueueingPosition=1
  IF(!TIMELINE_ACTIVE(TL_Queue))
     TIMELINE_CREATE(TL_Queue, nSendSpacing, 1, TIMELINE_ABSOLUTE, TIMELINE_REPEAT)  
}


DEFINE_FUNCTION fnSendtheCommand()
{
  SEND_STRING _CmdQueue[nCurrentQSendingPosition].dvSendtoDevice,"_CmdQueue[nCurrentQSendingPosition].cCmdtoSend"
  _CmdQueue[nCurrentQSendingPosition].dvSendtoDevice = 0:0:0    //Clear the Buffer
  _CmdQueue[nCurrentQSendingPosition].cCmdtoSend = "''"         //Clear the Buffer
  nCurrentQSendingPosition++
  IF(nCurrentQSendingPosition > MAX_Q_LEN)
     nCurrentQSendingPosition=1
  IF(nCurrentQSendingPosition==nCurrentQueueingPosition)    //If the current sending position is the same as the current queue position then the Queue is empty, kill the timeline
     TIMELINE_KILL (TL_Queue)
}

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)

DEFINE_START
nCurrentQSendingPosition=1
nCurrentQueueingPosition=1

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

DEFINE_EVENT
TIMELINE_EVENT[TL_Queue]
{
  fnSendtheCommand()
}
(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)