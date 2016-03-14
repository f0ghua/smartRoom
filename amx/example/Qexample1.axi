// http://www.amxforums.com/forum/technical-forum/tips-and-tricks/5535-queuing-methods
(*

Queuing multiple devices in a single queue is sometimes helpful in large
systems. I use the similar one that I posted for sending text to multiple
panels in large systems. As an example, if for some reason you have 20 panels
that need text updates, it keeps you from slowing the master down by spacing
the send ^txt commands out. That's actually the reason I wrote my particular
queue (and why it doesn't bother to test for ACK).

I don't use one central queue for all the devices on the system but I think
you're right, using one queue for a lot of devices could potentially hurt you
on real-time stuff like volume control, PTZ, etc.

*)

DEFINE_FUNCTION INTEGER SEND_CMD (DEV dvOUT, CHAR sCMND[260])
{
    IF(TIMELINE_ACTIVE(TL_CMDS))
        {
            IF(!(nCURRENT_COMMAND == 1 + ( nCURRENT_QUEUE % AP_QUEUE_SIZE)))
            {
                nCURRENT_QUEUE = 1 + ( nCURRENT_QUEUE % AP_QUEUE_SIZE)  
                uAP_CMD[nCURRENT_QUEUE].CMD = sCMND
                uAP_CMD[nCURRENT_QUEUE].dvDEV = dvOUT
                 
                 
            }  
            ELSE
            {
                nCURRENT_COMMAND = 1 + ( nCURRENT_COMMAND % AP_QUEUE_SIZE) 
                nCURRENT_QUEUE = 1 + ( nCURRENT_QUEUE % AP_QUEUE_SIZE)
                uAP_CMD[nCURRENT_QUEUE].CMD = sCMND
                uAP_CMD[nCURRENT_QUEUE].dvDEV = dvOUT
            }
                    
        } 
    ELSE
        {
            nCURRENT_QUEUE = 1 + ( nCURRENT_QUEUE % AP_QUEUE_SIZE) 
            uAP_CMD[nCURRENT_QUEUE].CMD = sCMND
            uAP_CMD[nCURRENT_QUEUE].dvDEV = dvOUT
            TIMELINE_CREATE(TL_CMDS,lAP_COMM_TL,1,TIMELINE_RELATIVE, TIMELINE_REPEAT)
            
        }  

RETURN 0   

}

....


TIMELINE_EVENT[TL_CMDS]
{
   nCURRENT_COMMAND = 1 + (nCURRENT_COMMAND % AP_QUEUE_SIZE)   
   SEND_STRING uAP_CMD[nCURRENT_COMMAND].dvDEV,uAP_CMD[nCURRENT_COMMAND].CMD
     IF(DEBUG>2)
      SEND_STRING 0,"'COMMAND SENT: ',LEFT_STRING(uAP_CMD[nCURRENT_COMMAND].CMD,25)"
   IF(nCURRENT_COMMAND == nCURRENT_QUEUE)          
      TIMELINE_KILL(TL_CMDS)
}