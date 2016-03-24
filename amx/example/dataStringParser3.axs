STRING:
{
    LOCAL_VAR CHAR cOppo_Buf[LEN_MAX_TX_STR * DEV_QSIZE];

    //fnDEV_DeBug("'RX: "',DATA.TEXT,'" :DEBUG<',ITOA(__LINE__),'>'");
    cOppo_Buf = "cOppo_Buf,DATA.TEXT";

    CANCEL_WAIT 'CLEAR_BUFFER';
    WAIT 40 'CLEAR_BUFFER'
    {
        cOppo_Buf = '';
    }

    //set flag so we don't query power when we're RXing data
    sOppo.nRX_InLst_10s = 1;
    CANCEL_WAIT 'RX_IN_LST_10s';
    WAIT 100 'RX_IN_LST_10s'
    {
        sOppo.nRX_InLst_10s = 0;
    }

    WHILE(find_string(cOppo_Buf,"DEV_RX_END",1))
    {
        STACK_VAR INTEGER nFBS;
        STACK_VAR CHAR cTmpStr[LEN_MAX_TX_STR];

        cTmpStr = REMOVE_STRING(cOppo_Buf,"DEV_RX_END",1);
        fnDEV_DeBug("'RX: [ ',cTmpStr,' ] :DEBUG<',ITOA(__LINE__),'>'");
        REMOVE_STRING(cTmpStr,"DEV_RX_START",1);

        if(length_string(cTmpStr) > 1)//NOT JUST THE ENDING
        {
            LOCAL_VAR _sRX sRX_Data;//make stack after tested
            STACK_VAR _sRX sRX_Zero;//remove after tested
            
            sRX_Data = sRX_Zero; //remove after tested
            
            //fnDEV_DeBug("'RX: [ ',cTmpStr,' ] :DEBUG<',ITOA(__LINE__),'>'");
            
            nFBS = find_string(cTmpStr,"' '",1);
            //fnDEV_DeBug("'RX: find_string "space" = [ ',itoa(nFBS),' ] :DEBUG<',ITOA(__LINE__),'>'");
            if(nFBS == 3)//not verbose
            {
                fnDEV_CTS();
                sRX_Data.cCmd = sOppo.sQ[sOppo.nQSent].cCmd; //might need work/should match command sent
                sRX_Data.cResult = GET_BUFFER_STRING(cTmpStr,nFBS-1);
                REMOVE_STRING(cTmpStr,"' '",1);
                nFBS = find_string(cTmpStr,"DEV_RX_END",1);
                if(nFBS > 1)//we have a parameter
                {
                    sRX_Data.cParam = GET_BUFFER_STRING(cTmpStr,nFBS-1);
                    fnDEV_Process_RX(sRX_Data,RX_VERBOSE_NOT);
                }
                else
                {
                    fnDEV_DeBug("'RX ERR: No parameter found in non verbose response :DEBUG<',ITOA(__LINE__),'>'");
                    PULSE[vDEVcomm,CHNL_COMM_ERR];
                }
            }
            else if(nFBS == 4)
            {
                fnDEV_CTS();
                sRX_Data.cCmd = GET_BUFFER_STRING(cTmpStr,nFBS-1);
                REMOVE_STRING(cTmpStr,"' '",1);
                if(sRX_Data.cCmd[1] == 'U')//unsolicited response
                {
                    nFBS = find_string(cTmpStr,"DEV_RX_END",1);
                    if(nFBS > 1)
                    {
                        sRX_Data.cParam = GET_BUFFER_STRING(cTmpStr,nFBS-1);
                        fnDEV_Process_RX(sRX_Data,RX_VERBOSE_UNSOL);
                    }
                    else
                    {
                        fnDEV_DeBug("'RX ERR: No parameter found in unsolicited verbose response :DEBUG<',ITOA(__LINE__),'>'");
                        PULSE[vDEVcomm,CHNL_COMM_ERR];
                    }
                }
                else//command response
                {
                    fnDEV_CTS();
                    nFBS = find_string(cTmpStr,"' '",1);
                    if(nFBS == 3)
                    {
                        sRX_Data.cResult = GET_BUFFER_STRING(cTmpStr,nFBS-1);
                        REMOVE_STRING(cTmpStr,"' '",1);
                        nFBS = find_string(cTmpStr,"DEV_RX_END",1);
                        if(nFBS > 1)
                        {
                            sRX_Data.cParam = GET_BUFFER_STRING(cTmpStr,nFBS-1);
                            fnDEV_Process_RX(sRX_Data,RX_VERBOSE_CMD);
                        }
                        else
                        {
                            fnDEV_Process_RX(sRX_Data,RX_VERBOSE_CMD);
                            //fnDEV_DeBug("'RX ERR: No parameter found in verbose cmd rx [ ',cTmpStr,' ] :DEBUG<',ITOA(__LINE__),'>'");
//                          PULSE[vDEVcomm,CHNL_COMM_ERR];
                        }
                    }
                    else if(!nFBS)//if it ain't 3 or 0 F' it
                    {
                        nFBS = find_string(cTmpStr,"DEV_RX_END",1);
                        if(nFBS == 3)
                        {
                            sRX_Data.cResult = GET_BUFFER_STRING(cTmpStr,nFBS-1);
                            if(sRX_Data.cResult == 'OK')
                            {
                                fnDEV_Process_RX(sRX_Data,RX_VERBOSE_CMD);
                            }
                            else
                            {
                                fnDEV_DeBug("'RX ERR: Malformed command rx [ ',sRX_Data.cResult,' ] :DEBUG<',ITOA(__LINE__),'>'");
                                PULSE[vDEVcomm,CHNL_COMM_ERR];
                            }
                        }
                    }
                    else
                    {
                        fnDEV_DeBug("'RX ERR: Malformed command rx [ ',cTmpStr,' ] :DEBUG<',ITOA(__LINE__),'>'");
                        PULSE[vDEVcomm,CHNL_COMM_ERR];
                    }
                }
            }
            else
            {
                fnDEV_CTS(); // let timeout
                fnDEV_DeBug("'RX ERR: Malformed command rx [ ',cTmpStr,' ] :DEBUG<',ITOA(__LINE__),'>'");
                PULSE[vDEVcomm,CHNL_COMM_ERR];
            }
        }
        else
        {
            fnDEV_CTS(); // let timeout
            fnDEV_DeBug("'RX Err No data in rx [ ',cTmpStr,' ] :DEBUG<',ITOA(__LINE__),'>'");
            PULSE[vDEVcomm,CHNL_COMM_ERR];
        }
    }