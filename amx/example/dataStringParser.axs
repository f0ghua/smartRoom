(*
I'd think of the string this way, almost like an XML file:
Code:

xStatus // This is a status message
  Camera 1 Position *s  // This is a Status message of type: Position from Camera 1
    Camera 1 Position Focus: 4608 *s 
    Camera 1 Position Pan: 352 s* 
    Camera 1 Position Tilt: 34 *s 
    Camera 1 Position Zoom: 687 
** end

So, I might do something like this. I'm leaving out a buch of stuff I wo0uld
also do - but this hopefully will cover enough to explain.

So, first - In the data_event we keep building the string up until we get the
end charactors. You will probably get all this in one chunk anyway. But, it's
always a good idea to build it yourself just in case the message gets broken
up into more than one data_event. There are many ways to do this kind of
thing. This is just one. Once we hafve our whole message in MyCam_Buffer we
pass it into the function's buffer, clear out our main buffer and run off to
parse.

Next - we run up to our function called fn_Parse_The_String() with our message
in its buffer. The first thing we do is determine what type of return it is.
In our case it is a Status message, but it could be other things. I made up
silly names for the other things but you'd put the real names there. The for
loop runs through our array of possible return names looking for a match. Once
it finds it we populate the variable command_id with the id number of the
array. (in our case it's list item (1) so nloop will equal `1. We're done int
he loop so we break out. No point in continuing. bear in mind that if we don't
find the type of message return we just command_id will equal zero. so we
won't parse and will fall through the next section without parsing anything.

Next (step 3) - we go to the Switcch/Case stack and search for the code to
parse a xStatus message (case 1). First thing is to determine whichc camera
we're getting the message from (Camera 1 in this case). we just remove the
text in front of the first "Camera 1" by remvoe_string "Camera" that will
leave the 1 which we can convert to an integer by ATOI(bufffer)

The If(cam_id) statemnet is a catchall to prevent us from trying to do a
Camera 0 if we get goofy data or whatnot.

the remove_string(buffer,'Focus:',1); statement takes up to the space just
after the "Focus:' in the buffer which leaves the buffer saying "4608 *s
Camera 1 Position Pan: 352 s* Camera 1 Position Tilt: 34 *s Camera 1 Position
Zoom: 687 ** end"

we just need to do another atoi() to get the value into our structure.
MyCams[cam_id].Focus=atoi(buffer);
so MyCams[1].Focus=4608

We just need to keep chopping our way through the string until we have all our
values. Once done we can then do something with them like update feedback or
make evaluations about what to do with the values, etc...

There's a whole host of stuff on managing the buffer/queue, command structures
and all that. but, this example, hopefully, expalins the basics of it. For
esxample, I would really try and granularize the individual value returns
since they all contatin the Camera 1 header. it's more than likely you'd get
several cameral IDs stomping all over each other at once. This example assumes
that the message comes in nice order one cam at a time.

*)
DEFINE_DEVICE

dvCam_01=5001:01:0

DEFINE_CONSTANT

integer cam_ct=3;  // for 3 cameras
(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

structure _MyCams{
integer Focus
integer Pan
integer Tilt
integer Zoom
    }
(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile _MyCams MyCams[cam_ct];

volatile char MyCam_Buffer[200];

volatile char Cam_Return_Name[][25]={
    {'xStatus'} // all the different possible return types.
    ,{'xSomethingElse2'}
    ,{'xSomethingElse3'}
    }



define_function fn_Parse_The_String(char buffer[200]){
    stack_var integer command_id;
    stack_var integer nloop;
    stack_var integer cam_id;
    // this section checks what type of return - in this case xStatus
    for(nloop=length_array(Cam_Return_Name);nloop;nloop--){ // finds the return type
        if(find_string(buffer,Cam_Return_Name[nloop],1)){
            command_id=nloop;
            break // we've found the command
            } // if
        } // for(
    
    // this section parses
    switch(command_id){
        case 1:{  // xStatus return
            remove_string(buffer,'Camera',1) // strips off string up to first "Camera"
            cam_id=atoi(buffer);  // get which cam it is.
            if(cam_id){ // if we do indeed have a cam id
                remove_string(buffer,'Focus:',1);
                MyCams[cam_id].Focus=atoi(buffer);
                remove_string(buffer,'Position Pan:',1);
                MyCams[cam_id].Pan=atoi(buffer);
                remove_string(buffer,'Position Tilt:',1);
                MyCams[cam_id].Tilt=atoi(buffer);
                remove_string(buffer,'Zoom:',1);
                MyCams[cam_id].Zoom=atoi(buffer);
                // now go do something with all these new values.
                } // if cam _id
            } // case
        case 2:{  // xSomethingElse2 return
            // parse for this return type
            } // case
        case 3:{  // xSomethingElse3 return
            // parse for this return type
            } // case
        } // swithc(command_id)

    }

DEFINE_EVENT

data_event[dvCam_01]{
    string:{
        MyCam_Buffer="MyCam_Buffer,data.text"
        while(find_string(MyCam_Buffer,'**',1)){ // or whatever the end of message is
            fn_Parse_The_String(remove_string(MyCam_Buffer,'**',1));
            }
        }
    }