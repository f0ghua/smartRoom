PROGRAM_NAME='LightAxi'

DEFINE_CONSTANT
INTEGER nVirDevStart = 34101

DEFINE_TYPE
STRUCTURE devStatus
{
    INTEGER nVal[8];
}

DEFINE_VARIABLE
devStatus _sDevSts[90][7]
char cLightData[5000][7]

DEFINE_FUNCTION fnLTStatus(DEV vdvLight,INTEGER nID,INTEGER nChannel,INTEGER nValue)
{
	if((vdvLight.NUMBER >= nVirDevStart) &&(vdvLight.NUMBER <= nVirDevStart+6))
	{
		IF((nID >= 60)&&(nID <= 89) &&(nChannel <= 8))
		{
			IF(_sDevSts[nID][vdvLight.NUMBER-nVirDevStart+1].nVal[nChannel] != nValue)
			{
				IF(nValue == 1)
				{
					fnOn(vdvLight,nID,nChannel)
				}
				ELSE
				{
					fnOff(vdvLight,nID,nChannel)
				}
				_sDevSts[nID][vdvLight.NUMBER-nVirDevStart+1].nVal[nChannel] = nValue
			}
		}
		ELSE IF((nID >= 50)&&(nID <= 59) &&(nChannel <= 5))
		{
			IF(_sDevSts[nID][vdvLight.NUMBER-nVirDevStart+1].nVal[nChannel] != nValue)
			{
				fnTempBack(vdvLight,nID,nChannel,nValue)
				_sDevSts[nID][vdvLight.NUMBER-nVirDevStart+1].nVal[nChannel] = nValue
			}
		}
	}
}

DEFINE_FUNCTION fnOn(DEV vdvLight,INTEGER nNumber,INTEGER nChannel)    // �̵�����   (���ڶ�Ӧ������˿�,�豸��ַ  �˿ں�)
{
    SEND_COMMAND vdvLight,"'fnOn',ITOA(nNumber),'-',ITOA(nChannel),'*'"
}


DEFINE_FUNCTION fnOff(DEV vdvLight,INTEGER nNumber,INTEGER nChannel)   // �̵�����   �豸��ַ  �˿ں�
{
     SEND_COMMAND vdvLight,"'fnOff',ITOA(nNumber),'-',ITOA(nChannel),'*'"
}


DEFINE_FUNCTION fnDimUp(DEV vdvLight,INTEGER nNumber,Integer nChannel)  // �������ϵ���   �豸��ַ  �˿ں�
{
     SEND_COMMAND vdvLight,"'fnDimUp',ITOA(nNumber),'-',ITOA(nChannel),'*'"
}


DEFINE_FUNCTION fnDimDn(DEV vdvLight,INTEGER nNumber, Integer nChannel) // �������µ���    �豸��ַ �˿ں�
{
    SEND_COMMAND vdvLight,"'fnDimDn',ITOA(nNumber),'-',ITOA(nChannel),'*'"
}


DEFINE_FUNCTION fnDimStop(DEV vdvLight,INTEGER nNumber , INTEGER nChannel) // ����ֹͣ        �豸��ַ �˿ں�
{
    SEND_COMMAND vdvLight,"'fnDimStop',ITOA(nNumber),'-',ITOA(nChannel),'*'"
}

DEFINE_FUNCTION fnTempBack(DEV vdvLight,INTEGER nNumber,INTEGER nChannel,INTEGER nValue)
{
    SEND_COMMAND vdvLight,"'fnTempBack',ITOA(nNumber),'-',ITOA(nChannel),'-',ITOA(nValue),'*'"
}
//  ���ͷ������¿���   �豸��ַ ���ܺ� ֵ
//  ���ܺ�  1��2��3��4 ��Ϊ ���ء��趨�¶ȡ����١�ģʽ
//  ����ֵ0��1 �ء��� �¶�16-32 ���� 1��2��3 ���С�С ģʽ 1��2��3��4 Ϊ���䡢���ȡ���ʪ��ͨ��

DEFINE_FUNCTION fnDimLevel(DEV vdvLight,INTEGER nNumber, INTEGER nChannel, Integer nLevelValue,Integer nTime)
{
    SEND_COMMAND vdvLight,"'fnDimLevel',ITOA(nNumber),'-',ITOA(nChannel),'-',ITOA(nLevelValue),'-',ITOA(nTime),'*'"
}
//  �趨����ֵ   �豸��ַ  �˿ں�  ֵ  ����ʱ��

DEFINE_FUNCTION fnStatusDev(DEV vdvLight,nNumber,nChannel,nValue)
{
	if((vdvLight.NUMBER >= nVirDevStart) &&(vdvLight.NUMBER <= nVirDevStart+6))
	{
		IF((nNumber >= 30)&&(nNumber <= 39))
		{
			IF(nValue < 2)
			{
	    		// �̵������ص�״̬
	    		debug('lightAxi', 10, "'_sDevSts[',itoa(nNumber),'][',
	    			itoa(vdvLight.NUMBER-nVirDevStart+1),'][',itoa(nChannel),'] = ',
	    			itoa(nValue)")
	    		_sDevSts[nNumber][vdvLight.NUMBER-nVirDevStart+1].nVal[nChannel] = nValue
			}
		}
		ELSE IF((nNumber >= 40)&&(nNumber <= 49))
		{
			IF(nValue <= 100)
			{
	   			// ��������״̬
	    		_sDevSts[nNumber][vdvLight.NUMBER-nVirDevStart+1].nVal[nChannel] = nValue
			}
		}
		ELSE IF((nNumber >= 50)&&(nNumber <= 59))
		{
	    	// �¿�����״̬
			//		_sDevSts[nNumber].nVal[nChannel] = nValue
			if(nValue < 50)
			{
				//fnExeTempController(vdvLight,nNumber,nChannel,nValue)
				SEND_STRING 0,"'TEMP CONTROLLER --------------'"
			}
		}
	}
}

DEFINE_START


DEFINE_EVENT

DATA_EVENT[vdvAmxLight]
{
	COMMAND:
	{
		STACK_VAR INTEGER M1,M2
		STACK_VAR INTEGER nNumber,nChannel,nLevelValue,nTime,nValue
		WHILE(FIND_STRING(DATA.TEXT,'Btn',1)&&FIND_STRING(DATA.TEXT,'*',1))
		{
			M1 = FIND_STRING(DATA.TEXT,'Btn',1)
			M2 = FIND_STRING(DATA.TEXT,'*',1)
			IF(M2 > M1)
			{
				IF(FIND_STRING(DATA.TEXT,'BtnP',1))
				{
					REMOVE_STRING(DATA.TEXT,'BtnP',1)
					nNumber = ATOI(DATA.TEXT)
					REMOVE_STRING(DATA.TEXT,'-',1)
					nChannel = ATOI(DATA.TEXT)
					REMOVE_STRING(DATA.TEXT,'*',1)
		    		//fnExeBtnPress(vdvAMXLight,nNumber,nChannel)
		    		// button push, write code here to process push command 
				}
				ELSE IF(FIND_STRING(DATA.TEXT,'BtnR',1))
				{
					REMOVE_STRING(DATA.TEXT,'BtnR',1)
					nNumber = ATOI(DATA.TEXT)
					REMOVE_STRING(DATA.TEXT,'-',1)
					nChannel = ATOI(DATA.TEXT)
					REMOVE_STRING(DATA.TEXT,'*',1)
		    		//fnExeBtnRelease(vdvAMXLight,nNumber,nChannel)
		    		// button release, write code here to process Release command 
				}
				ELSE IF(FIND_STRING(DATA.TEXT,'BtnSts',1))
				{
					REMOVE_STRING(DATA.TEXT,'BtnSts',1)
					nNumber = ATOI(DATA.TEXT)
					REMOVE_STRING(DATA.TEXT,'-',1)
					nChannel = ATOI(DATA.TEXT)
					REMOVE_STRING(DATA.TEXT,'-',1)
					nValue = ATOI(DATA.TEXT)
					REMOVE_STRING(DATA.TEXT,'*',1)
		    		// device status, write code here to process Scroll Left command 
		    		fnStatusDev(vdvAmxLight,nNumber,nChannel,nValue);
				}
			}
			ELSE
			{
				REMOVE_STRING(DATA.TEXT,'*',1)
			}
		}
	}
}

/*
DATA_EVENT[vdvAMXLight2]
{
    COMMAND:
    {
	STACK_VAR INTEGER M1,M2
	STACK_VAR INTEGER nNumber,nChannel,nLevelValue,nTime,nValue
	WHILE(FIND_STRING(DATA.TEXT,'Btn',1)&&FIND_STRING(DATA.TEXT,'*',1))
	{
	    M1 = FIND_STRING(DATA.TEXT,'Btn',1)
	    M2 = FIND_STRING(DATA.TEXT,'*',1)
	    IF(M2 > M1)
	    {
		IF(FIND_STRING(DATA.TEXT,'BtnP',1))
		{
		    REMOVE_STRING(DATA.TEXT,'BtnP',1)
		    nNumber = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'-',1)
		    nChannel = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'*',1)
		    fnExeBtnPress(vdvAMXLight2,nNumber,nChannel)
		    // ��ť���¹��� write code here to process push command 
		}
		ELSE IF(FIND_STRING(DATA.TEXT,'BtnR',1))
		{
		    REMOVE_STRING(DATA.TEXT,'BtnR',1)
		    nNumber = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'-',1)
		    nChannel = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'*',1)
		     fnExeBtnRelease(vdvAMXLight2,nNumber,nChannel)
		    // ��ţ̌���� write code here to process Release command 
		}
		ELSE IF(FIND_STRING(DATA.TEXT,'BtnSts',1))
		{
		    REMOVE_STRING(DATA.TEXT,'BtnSts',1)
		    nNumber = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'-',1)
		    nChannel = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'-',1)
		    nValue = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'*',1)
		    // �豸״̬ write code here to process Scroll Left command 
		    fnStatusDev(vdvAmxLight2,nNumber,nChannel,nValue);
		}
	    }
	    ELSE
	    {
		REMOVE_STRING(DATA.TEXT,'*',1)
	    }
	}
    }
}

DATA_EVENT[vdvAMXLight3]
{
    COMMAND:
    {
	STACK_VAR INTEGER M1,M2
	STACK_VAR INTEGER nNumber,nChannel,nLevelValue,nTime,nValue
	WHILE(FIND_STRING(DATA.TEXT,'Btn',1)&&FIND_STRING(DATA.TEXT,'*',1))
	{
	    M1 = FIND_STRING(DATA.TEXT,'Btn',1)
	    M2 = FIND_STRING(DATA.TEXT,'*',1)
	    IF(M2 > M1)
	    {
		IF(FIND_STRING(DATA.TEXT,'BtnP',1))
		{
		    REMOVE_STRING(DATA.TEXT,'BtnP',1)
		    nNumber = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'-',1)
		    nChannel = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'*',1)
		    fnExeBtnPress(vdvAMXLight3,nNumber,nChannel)
		    // ��ť���¹��� write code here to process push command 
		}
		ELSE IF(FIND_STRING(DATA.TEXT,'BtnR',1))
		{
		    REMOVE_STRING(DATA.TEXT,'BtnR',1)
		    nNumber = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'-',1)
		    nChannel = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'*',1)
		     fnExeBtnRelease(vdvAMXLight3,nNumber,nChannel)
		    // ��ţ̌���� write code here to process Release command 
		}
		ELSE IF(FIND_STRING(DATA.TEXT,'BtnSts',1))
		{
		    REMOVE_STRING(DATA.TEXT,'BtnSts',1)
		    nNumber = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'-',1)
		    nChannel = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'-',1)
		    nValue = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'*',1)
		    // �豸״̬ write code here to process Scroll Left command 
		    fnStatusDev(vdvAmxLight3,nNumber,nChannel,nValue);
		}
	    }
	    ELSE
	    {
		REMOVE_STRING(DATA.TEXT,'*',1)
	    }
	}
    }
}

*/
/*
    ���߲��裺
    1������ʹ��ֱ�������� һͷ����һͷĸ ���ӵ� AVB-ABS (AVB-ABSΪĸͷ)
    2�����е��豸����AVB-ABS ,���豸��8�����ߣ��������ţ��豸����ͨ����ֱ������AVB-ABS���߲��ӵ�AVB-ABS���ߴ��ӵ�ABS.
    3���ô������ӵ�AVB-ABS�Ĵ��ڣ����豸���е�ַ���á�
    
    ���ò��裺
    ����ʹ�ð���˼��ַ����������õ�ַ�� ��ַ��Χ���£�
    (
     30-39  ǿ���������ַ (ÿ����ַ8��·)
     40-49  ��������ַ(ÿ����ַ4·)
     50-59  �¿�����ַ
     60-89  ��������ַ (ÿ����ַ8��·)
     )
     �趨���ַ����ʹ�ð���˼���������ֱ�ӿ����豸��
     ʹ�ÿ����������ֱ�ӿ���ģ���Ժ�ʹ�ô����߰�������AVB-ABS������������д�����
     
     �����д���裺
     
    ��һ�� �� DEFINE_START ����ӣ� #INCLUDE 'LightAxi'
    �ڶ��� :  ���ģ�� DEFINE_MODULE 'LightModule' LModule (vdvAMXLight,dvAMXLight)
    ������ �� ʹ�ù���  
	1�� BUTTON_EVENT ��ʹ��PUSH �� RELEASE������PORT���ģ�  ( �������ȶ�����壬����ַΪ�趨��ַ�����˿�Ϊ���ڶ˿�  )
	2�� ʹ�ð�ťʱҲ����д�� ����������������� fnExeBtnPress �� fnExeBtnRelease
	3�� ��Ҫʹ��HOLD ��ס����ʹ��TimeLine�ж�ʱ�䣬��PRESS��ʱ��ʼ��ʱ����ʱ�䳬ʱʱ����������
	4�� ��Ҫ��ť�����ƿ���ʹ��fnLTStatus����
	5�� ����ʹ�ú��� fnOn,��fnOff
	6�� ����ʹ�ú��� fnDimUp  fnDimDn �� fnDimStop ����ֱ�ӵ�������ֵ fnDimLevel
	7�� �¿�������ִ�� ���º�����  fnExeTempController,�������״̬�仯ʱ�������ڲ��Ĳ�����仯��ִ�в�������
	8�� ��Ҫ�����¿����ʹ�����º�����fnTempBack 
	9�� ��Ҫʹ�¿�����״̬ͬ��ʹ�ã�fnLTStatus
	10��״̬��ʾ�� _sDevSts[��ַ].nVal[�˿�]������֪���̵����͵�������״̬��
	��30��ģ��1�ż̵�����״̬�� _sDevSts[30].nVal[1]
	40�ŵ�������1�Ż�·��״ֵ̬��  _sDevSts[40].nVal[1]
	
	ע�� һ��ϵͳ�� ������ڶ��ģ�������������DATA_EVENT[vdvAMXLight] �������޸ĵ�	fnExeScrollLeft ���ֺ����е� vdvAMXLight ,����ط���Ҫ���ڴ洢״̬����
	

*/


