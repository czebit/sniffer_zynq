/*
 * main.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include <stdlib.h>


uint8_t readEchoChar(){
	uint8_t c;
   	outbyte(c=inbyte());
    return c;
}

uint8_t readChar(){
	uint8_t c;
   	c=inbyte();
    return c;
}

void setModeSeq(void);
void sendSeqChar(char8 c);
void setModeData(void);
void sendData(char8* pData);
char8 getMatch(char8* pMatch);



int main(){
	char8* pReg = (char8*)malloc(sizeof(char8) * 9);
	char8* pMatch = (char8*)malloc(sizeof(char8) * 9);
	char8* pRegD = (char8*)malloc(sizeof(char8) * 9);
	char8* pRegDD = (char8*)malloc(sizeof(char8) * 9);
	*(pReg+8) = (char8)0;
	*(pMatch+8) = (char8)0;
	*(pRegD+8) = (char8)0;
	*(pRegDD+8) = (char8)0;

	uint8_t i = 0;
	char8 mode_char, c;

    init_platform();
	for(i = 0; i<8; i++){
		*(pRegDD+i) = "X";
		*(pRegD+i) = "X";
	}
    print("Hello sniffer\r\n");

    while(1){
    	mode_char = readChar();
    	if(mode_char == '~'){
    		setModeSeq();
    		print("\r\nMatching sequence input mode on. '~' will end sequence input mode\r\n");
    		while(1){
    			c = readChar();
    			if(c == '~'){
    				print("\r\nMatching sequence input mode off.\r\n");
    				setModeData();
    				break;
    			} else {
    				sendSeqChar(c);
    			}
    		}
    	} else {

    		*pReg = mode_char;

        	for(i = 1; i<8; i++){
        		*(pReg+i) = readChar();
        	}

        	sendData(pReg);

        	getMatch(pMatch);

        	for(i=0;i<8;i++){
        		outbyte(*(pRegDD+i));
        		print(" ");
        		outbyte(*(pMatch+i));
        		print("\r\n");
        	}

        	for(i = 0; i<8; i++){
        		*(pRegDD+i) = *(pRegD+i);
        		*(pRegD+i) = *(pReg+i);
        	}

        	print("\r\n");
    	}
    }


}
