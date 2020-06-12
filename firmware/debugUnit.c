#include <stdio.h>
#include <string.h>
#include "xparameters.h"
#include "xil_cache.h"
#include "xgpio.h"
#include "platform.h"
#include "microblaze_sleep.h"
#include "xuartlite.h"



#define PORT_IN	 		XPAR_AXI_GPIO_0_DEVICE_ID //XPAR_GPIO_0_DEVICE_ID
#define PORT_OUT 		XPAR_AXI_GPIO_0_DEVICE_ID //XPAR_GPIO_0_DEVICE_ID

#define READ_REQUEST             0x00ffffff


XUartLite uart_module;
XGpio GpioOutput;
XGpio GpioParameter;
XGpio GpioInput;

void reg_file_write(u32 opcode, u32 data);
u32 reg_file_read();
int main()
{
    init_platform();
    int Status;

    /* inicializacion de los gpio */
    Status=XGpio_Initialize(&GpioInput, PORT_IN);
    if(Status!=XST_SUCCESS){
         return XST_FAILURE;
    }
    Status=XGpio_Initialize(&GpioOutput, PORT_OUT);
    if(Status!=XST_SUCCESS){
        return XST_FAILURE;
    }
	
    XGpio_SetDataDirection(&GpioOutput, 1, 0x00000000);
    /* Inicializacion de uart*/
    XUartLite_Initialize(&uart_module, 0);


    //////variables de estado de register file////////////

    /////////////////////////////////////////////////////
    u8  tmpRecv;
    u32 dataIn  = 0;
    u32 dataOut = 0;
    u32 enable_mask = 0x1 << 31;
    u8  bs1;
    u8  bs2;
    u8  bs3;
    u8  bs4;


    while(1){

    	dataIn = 0;

    	read(stdin,&tmpRecv,1);
    	dataIn = ((u32)tmpRecv) << 16;
    	read(stdin,&tmpRecv,1);
    	dataIn |= ((u32)tmpRecv) << 8;
    	read(stdin,&tmpRecv,1);
    	dataIn |= ((u32)tmpRecv);

    	if(dataIn == READ_REQUEST){
    		dataOut = XGpio_DiscreteRead(&GpioInput, 1);
    		dataOut = XGpio_DiscreteRead(&GpioInput, 1);
    		dataOut = XGpio_DiscreteRead(&GpioInput, 1);

    		bs1 = dataOut & 0x000000ff;
    		bs2 = (dataOut >> 8) & 0x000000ff;
    		bs3 = (dataOut >> 16) & 0x000000ff;
    		bs4 = (dataOut >> 24) & 0x000000ff;
    		 while(XUartLite_IsSending(&uart_module)){}
    		    XUartLite_Send(&uart_module, &bs1,1);
       		 while(XUartLite_IsSending(&uart_module)){}
       		    XUartLite_Send(&uart_module, &bs2,1);
       		 while(XUartLite_IsSending(&uart_module)){}
       		    XUartLite_Send(&uart_module, &bs3,1);
       		 while(XUartLite_IsSending(&uart_module)){}
       		    XUartLite_Send(&uart_module, &bs4,1);

    	}else{
    		 XGpio_DiscreteWrite(&GpioOutput, 1, dataIn);
    		 XGpio_DiscreteWrite(&GpioOutput, 1, dataIn | enable_mask);
    		 XGpio_DiscreteWrite(&GpioOutput, 1, dataIn);
    	}


    }
    cleanup_platform();
    return 0;
}
