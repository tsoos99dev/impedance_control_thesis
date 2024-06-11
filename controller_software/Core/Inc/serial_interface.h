/*
 * serial_interface.h
 *
 *  Created on: May 9, 2024
 *      Author: tamas
 */

#ifndef INC_SERIAL_INTERFACE_H_
#define INC_SERIAL_INTERFACE_H_


#include "ring_buffer.h"
#include "stm32f4xx_hal.h"


typedef struct _SerialInterface_t SerialInterface_t;

typedef void (*RX_Callback)(SerialInterface_t* data);
typedef void (*TX_Callback)(SerialInterface_t* data);


typedef enum {
	SERIAL_INTERFACE_OPERATION_OK,
	SERIAL_INTERFACE_OPERATION_FAILED
} SerialInterfaceOperationResult;


struct _SerialInterface_t {
	UART_HandleTypeDef* huart;
	RingBuffer_uint8_t* buffer_rx;
	RingBuffer_uint8_t* buffer_tx;
	RX_Callback rx_callback;
	TX_Callback tx_callback;
};


SerialInterfaceOperationResult SerialInterface_init(
		SerialInterface_t* hinterface,
		UART_HandleTypeDef* huart,
		RingBuffer_uint8_t* buffer_rx,
		RingBuffer_uint8_t* buffer_tx
);

SerialInterfaceOperationResult SerialInterface_listen(SerialInterface_t* hinterface);
void SerialInterface_register_rx_callback(SerialInterface_t* hinterface, RX_Callback rx_callback);
void SerialInterface_register_tx_callback(SerialInterface_t* hinterface, TX_Callback tx_callback);
SerialInterfaceOperationResult SerialInterface_send(SerialInterface_t* hinterface, const uint8_t* data, uint16_t n);

#endif /* INC_SERIAL_INTERFACE_H_ */
