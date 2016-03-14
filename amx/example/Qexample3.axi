(*

http://www.amxforums.com/forum/technical-forum/tips-and-tricks/5535-queuing-methods

QUE CODE THAT I USE

This is a que that I use frequently. It doesn't use a lot of overhead and you
can set the time between commands by adjusting the wait time at the bottom. It
works great for me;

*)


DEFINE_FUNCTION AP_DISCONNECT(INTEGER OUTPUT)
{
   AP_COMM("'DL0O',ITOA(OUTPUT),'T'")
}

DEFINE_FUNCTION AP_COMM(CHAR COMM_STR[15])  
{
    AP_COMM_WAITING++
    IF(AP_COMM_WAITING > nAP_BUFFER_SIZE)  //if at the end, loop around to the start
        AP_COMM_WAITING = 1
    cAP_BUFFER[AP_COMM_WAITING] = COMM_STR
}


DEFINE_PROGRAM

IF((AP_COMM_WAITING > 0) && AP_COMM_READY)    //IF WE HAVE A COMMAND AND IT'S READY TO SEND,
{
    OFF[AP_COMM_READY]
    AP_COMM_SENDING++
    IF(AP_COMM_SENDING > nAP_BUFFER_SIZE)   //IF AT THE END OF THE BUFFER, LOOP AROUND TO THE FIRST INDEX
        AP_COMM_SENDING = 1
    SEND_STRING DvAP,cAP_BUFFER[AP_COMM_SENDING]
    cAP_BUFFER[AP_COMM_SENDING] = ''   
    IF(cAP_BUFFER[AP_COMM_WAITING] = '')        //LAST COMMAND IN BUFFER
    {
        OFF[AP_COMM_WAITING]
        OFF[AP_COMM_SENDING]
    }
    WAIT 2
        ON[AP_COMM_READY]
}