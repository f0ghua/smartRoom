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

DEFINE_FUNCTION fnOn(DEV vdvLight,INTEGER nNumber,INTEGER nChannel)    // 继电器开   (串口对应的虚拟端口,设备地址  端口号)
{
    SEND_COMMAND vdvLight,"'fnOn',ITOA(nNumber),'-',ITOA(nChannel),'*'"
}


DEFINE_FUNCTION fnOff(DEV vdvLight,INTEGER nNumber,INTEGER nChannel)   // 继电器关   设备地址  端口号
{
     SEND_COMMAND vdvLight,"'fnOff',ITOA(nNumber),'-',ITOA(nChannel),'*'"
}


DEFINE_FUNCTION fnDimUp(DEV vdvLight,INTEGER nNumber,Integer nChannel)  // 调光向上调节   设备地址  端口号
{
     SEND_COMMAND vdvLight,"'fnDimUp',ITOA(nNumber),'-',ITOA(nChannel),'*'"
}


DEFINE_FUNCTION fnDimDn(DEV vdvLight,INTEGER nNumber, Integer nChannel) // 调光向下调节    设备地址 端口号
{
    SEND_COMMAND vdvLight,"'fnDimDn',ITOA(nNumber),'-',ITOA(nChannel),'*'"
}


DEFINE_FUNCTION fnDimStop(DEV vdvLight,INTEGER nNumber , INTEGER nChannel) // 调光停止        设备地址 端口号
{
    SEND_COMMAND vdvLight,"'fnDimStop',ITOA(nNumber),'-',ITOA(nChannel),'*'"
}

DEFINE_FUNCTION fnTempBack(DEV vdvLight,INTEGER nNumber,INTEGER nChannel,INTEGER nValue)
{
    SEND_COMMAND vdvLight,"'fnTempBack',ITOA(nNumber),'-',ITOA(nChannel),'-',ITOA(nValue),'*'"
}
//  发送反馈给温控器   设备地址 功能号 值
//  功能号  1、2、3、4 分为 开关、设定温度、风速、模式
//  开关值0、1 关、开 温度16-32 风速 1、2、3 大、中、小 模式 1、2、3、4 为制冷、制热、除湿、通风

DEFINE_FUNCTION fnDimLevel(DEV vdvLight,INTEGER nNumber, INTEGER nChannel, Integer nLevelValue,Integer nTime)
{
    SEND_COMMAND vdvLight,"'fnDimLevel',ITOA(nNumber),'-',ITOA(nChannel),'-',ITOA(nLevelValue),'-',ITOA(nTime),'*'"
}
//  设定调光值   设备地址  端口号  值  滚动时间

DEFINE_FUNCTION fnStatusDev(DEV vdvLight,nNumber,nChannel,nValue)
{
	if((vdvLight.NUMBER >= nVirDevStart) &&(vdvLight.NUMBER <= nVirDevStart+6))
	{
		IF((nNumber >= 30)&&(nNumber <= 39))
		{
			IF(nValue < 2)
			{
	    		// 继电器开关的状态
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
	   			// 调光器的状态
	    		_sDevSts[nNumber][vdvLight.NUMBER-nVirDevStart+1].nVal[nChannel] = nValue
			}
		}
		ELSE IF((nNumber >= 50)&&(nNumber <= 59))
		{
	    	// 温控器的状态
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
		    // 按钮按下功能 write code here to process push command 
		}
		ELSE IF(FIND_STRING(DATA.TEXT,'BtnR',1))
		{
		    REMOVE_STRING(DATA.TEXT,'BtnR',1)
		    nNumber = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'-',1)
		    nChannel = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'*',1)
		     fnExeBtnRelease(vdvAMXLight2,nNumber,nChannel)
		    // 按钮抬起功能 write code here to process Release command 
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
		    // 设备状态 write code here to process Scroll Left command 
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
		    // 按钮按下功能 write code here to process push command 
		}
		ELSE IF(FIND_STRING(DATA.TEXT,'BtnR',1))
		{
		    REMOVE_STRING(DATA.TEXT,'BtnR',1)
		    nNumber = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'-',1)
		    nChannel = ATOI(DATA.TEXT)
		    REMOVE_STRING(DATA.TEXT,'*',1)
		     fnExeBtnRelease(vdvAMXLight3,nNumber,nChannel)
		    // 按钮抬起功能 write code here to process Release command 
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
		    // 设备状态 write code here to process Scroll Left command 
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
    接线步骤：
    1、主机使用直连串口线 一头公，一头母 连接到 AVB-ABS (AVB-ABS为母头)
    2、所有的设备接入AVB-ABS ,此设备有8条总线，互不干扰，设备可以通过线直接连到AVB-ABS或者并接到AVB-ABS或者串接到ABS.
    3、用串口连接到AVB-ABS的串口，对设备进行地址配置。
    
    配置步骤：
    首先使用安玛思地址设置软件设置地址， 地址范围如下：
    (
     30-39  强电控制器地址 (每个地址8回路)
     40-49  调光器地址(每个地址4路)
     50-59  温控面板地址
     60-89  按键面板地址 (每个地址8回路)
     )
     设定完地址可以使用安玛思控制软件，直接控制设备。
     使用控制软件可以直接控制模块以后，使用串口线把主机和AVB-ABS连接起来，编写软件。
     
     软件编写步骤：
     
    第一步 ： DEFINE_START 中添加： #INCLUDE 'LightAxi'
    第二步 :  添加模块 DEFINE_MODULE 'LightModule' LModule (vdvAMXLight,dvAMXLight)
    第三步 ： 使用功能  
	1、 BUTTON_EVENT 中使用PUSH 和 RELEASE（根据PORT更改）  ( 必须首先定义面板，面板地址为设定地址，面板端口为串口端口  )
	2、 使用按钮时也可以写在 主程序的两个函数下 fnExeBtnPress 和 fnExeBtnRelease
	3、 若要使用HOLD 按住，请使用TimeLine判断时间，在PRESS的时候开始计时，当时间超时时，触发动作
	4、 若要按钮背景灯开启使用fnLTStatus函数
	5、 开关使用函数 fnOn,和fnOff
	6、 调光使用函数 fnDimUp  fnDimDn 和 fnDimStop 或者直接调节亮度值 fnDimLevel
	7、 温控面板控制执行 如下函数：  fnExeTempController,当面板有状态变化时，函数内部的参数会变化，执行操作即可
	8、 若要控制温控面板使用如下函数：fnTempBack 
	9、 若要使温控面板的状态同步使用：fnLTStatus
	10、状态显示： _sDevSts[地址].nVal[端口]，可以知道继电器和调光器的状态，
	如30号模块1号继电器的状态是 _sDevSts[30].nVal[1]
	40号调光器的1号回路的状态值是  _sDevSts[40].nVal[1]
	
	注： 一个系统内 如果存在多个模块的情况，请添加DATA_EVENT[vdvAMXLight] ，并且修改掉	fnExeScrollLeft 各种函数中的 vdvAMXLight ,这个地方主要用于存储状态反馈
	

*/


