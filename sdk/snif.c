/*
 * snif.c
 *
 *  Created on: 08.06.2021
 *      Author: czebi
 */

#include "xil_io.h"
#include "xparameters.h"
#include "sniffer1.h"

#define SNIFER_BASE_ADDR 	XPAR_SNIFFER1_0_S0_AXI_BASEADDR
#define MODE_REG_OFFSET 	SNIFFER1_S0_AXI_SLV_REG0_OFFSET
#define START_REG_OFFSET	SNIFFER1_S0_AXI_SLV_REG1_OFFSET
#define READY_REG_OFFSET	SNIFFER1_S0_AXI_SLV_REG2_OFFSET
#define MATCH_REG_OFFSET	SNIFFER1_S0_AXI_SLV_REG3_OFFSET
#define DATA0_REG_OFFSET	SNIFFER1_S0_AXI_SLV_REG4_OFFSET
#define DATA1_REG_OFFSET	SNIFFER1_S0_AXI_SLV_REG5_OFFSET
#define SEQ_REG_OFFSET		SNIFFER1_S0_AXI_SLV_REG6_OFFSET


void setModeSeq(void){
	SNIFFER1_mWriteReg(SNIFER_BASE_ADDR, MODE_REG_OFFSET, 1);
}

void sendSeqChar(char8 c){
	outbyte(c);
	SNIFFER1_mWriteReg(SNIFER_BASE_ADDR, SEQ_REG_OFFSET, c);
	SNIFFER1_mWriteReg(SNIFER_BASE_ADDR, START_REG_OFFSET, 1);
	SNIFFER1_mWriteReg(SNIFER_BASE_ADDR, START_REG_OFFSET, 0);
}

void setModeData(void){
	SNIFFER1_mWriteReg(SNIFER_BASE_ADDR, MODE_REG_OFFSET, 0);
}

void sendData(char8* pData){
	u32 data0, data1;
	data0 = *pData     | (*(pData+1) << 8) | (*(pData+2) << 16) | (*(pData+3) << 24);
	data1 = *(pData+4) | (*(pData+5) << 8) | (*(pData+6) << 16) | (*(pData+7) << 24);
	SNIFFER1_mWriteReg(SNIFER_BASE_ADDR, DATA0_REG_OFFSET, data0);
	SNIFFER1_mWriteReg(SNIFER_BASE_ADDR, DATA1_REG_OFFSET, data1);
	SNIFFER1_mWriteReg(SNIFER_BASE_ADDR, START_REG_OFFSET, 1);
	SNIFFER1_mWriteReg(SNIFER_BASE_ADDR, START_REG_OFFSET, 0);
}

void getMatch(char8* pMatch){
	u32 match = 0;
	u8 cmatch = 0;
	while((SNIFFER1_mReadReg(SNIFER_BASE_ADDR, READY_REG_OFFSET)) == 0);
	match = SNIFFER1_mReadReg(SNIFER_BASE_ADDR, MATCH_REG_OFFSET);
	cmatch = match;
	for(u8 i=0;i<8;i++){
		if (((cmatch >> i) & (u8)0b00000001) == 0){
			*(pMatch+i) = '0';
		} else {
			*(pMatch+i) = '1';
		}
	}
}
