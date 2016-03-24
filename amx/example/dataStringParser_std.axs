
/*
Buffer Parsing in Netlinx

Symptoms

The programmer has converted working Axcess buffer parsing code over to a
NetLinx data event, but it does not work. The symptoms tend to fall into one
of two areas:

    Data is not being successfully parsed from the buffer, so expected
    feedback is not taking place.

    Data is being parsed from the buffer, but feedback is lagging behind.
    Feedback is reflecting old state changes.

Cause

The programmer needs to take into consideration how NetLinx buffer parsing
differs from parsing in Axcess. There are two key points:

    String data events only run when there is new incoming data. In Axcess,
    the buffer parsing is in mainline where it runs on every pass, regardless
    of whether or not new data is available.

    The global structure member DATA.TEXT is not the same as an Axcess buffer.
    It only contains the data that triggered the event and cannot be relied
    upon to be holding a complete reply from serial devices. Note that
    DATA.TEXT will have complete replies from AMX devices (e.g. ICSNet and
    AxLink devices); this limitation only applies to serial-type devices
    (RS232/422/485 and non-AMX devices over IP).

Resolution

Buffer parsing needs to be structured in a manner that takes account of the
behavior of NetLinx. The following example is for a serial device that sends
replies terminated with a carriage return (decimal 13). The programmer is only
interested in replies that contain GAIN and MUTE information. Other replies
may come back, but they will be ignored. Following the example are notes
explaining what specific sections of the example are doing:

*/

DATA_EVENT[dvSerial]
{

    STRING:
    {

        // The following line is not needed if you have created a buffer for this device in DEFINE_START
        LOCAL_VAR Buffer[100] // See Note 1 below

        STACK_VAR Reply[100]

        // The following line is not needed if you have created a buffer for this device in DEFINE_START
        Buffer = "Buffer,DATA.TEXT" // See Note 1 below

        WHILE (FIND_STRING(Buffer,"13",1)) // See note 2 below
        {

            Reply = REMOVE_STRING(Buffer,"13",1) // See Note 3 below
            SELECT
            {

                ACTIVE (FIND_STRING(Reply,'GAIN',1)):
                {

                    // Parse gain data here

                }
                ACTIVE (FIND_STRING(Reply,'MUTE',1)):
                {

                    // Parse mute data here

                }

            }

        } // See Note 4 below

    }

}

/*

Note 1: Parsing is never performed directly on the global structure element
DATA.TEXT, because it is not guaranteed to contain a complete reply. This only
contains the data that led to the triggering of the event. Multiple data
events may run before a complete reply has been returned. To handle this, we
are creating a local character array (named Buffer) and concatenating new
serial data to this buffer.

Also note that, as mentioned in the comments, you could create a buffer for
this device in DEFINE_START instead of concatenating your own local character
array with DATA.TEXT. The advantage to using CREATE_BUFFER is that the buffer
is managed by the NetLinx operating system instead of by the interpreted
NetLinx code. The results are the same, but your code will run slightly
faster, because it is not having to manage the buffer.

Note 2: We are using a WHILE loop here to handle the situations where there is
more than one reply in the buffer. If instead, we only parse one reply (using
IF instead of WHILE), then we may leave the data event with un-parsed data in
the buffer. The next time a data event triggers, we will parse this old data,
and feedback will lag behind.

Note 3: This works in conjunction with our WHILE loop. Each pass through the
loop, we remove a single reply from the buffer and parse it. This assures that
all completed replies have been parsed and that incomplete replies remain in
the buffer, ready to be completed in a future data event. It is important that
we do the REMOVE_STRING on valid replies, even if we do not care about the
contents of a particular reply, so that we can eventually exit the WHILE loop.

Note 4: At this point, the WHILE loop has completed. Note that we are not
doing a CLEAR_BUFFER here. There may still be incomplete messages that need to
be parsed. If we issued a CLEAR_BUFFER, then we would lose that data.

The above example is not the only possible solution. NetLinx provides a robust
set of functions, and depending on the situation, other approaches may be more
appropriate. For example, when the replies consist of long strings that have a
single-character known terminator, searching DATA.TEXT for the terminator is
faster than searching the entire buffer. See the following example:

*/

DATA_EVENT[dvSerial]
{

    STRING:
    {

        LOCAL_VAR Buffer[100]
        STACK_VAR Reply[100]

        WHILE (FIND_STRING (DATA.TEXT,"13",1))
        {

            Reply = "Buffer, REMOVE_STRING (DATA.TEXT,"13",1)"
            CLEAR_BUFFER Buffer
            SELECT
            {

                // parse Reply here

            }

        }
        Buffer = "Buffer,DATA.TEXT"

    }

} 