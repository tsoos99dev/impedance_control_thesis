/*
 * serial_interface.c
 *
 *  Created on: May 9, 2024
 *      Author: tamas
 */

#include "serial_interface.h"


#define SERIAL_INTERFACE_HANDLE_VECTOR_LENGTH 16


static void Transfer_Complete(UART_HandleTypeDef* huart);
static void RX_Event(UART_HandleTypeDef* huart, uint16_t size);


static SerialInterface_t* handles[SERIAL_INTERFACE_HANDLE_VECTOR_LENGTH] = {};
static uint16_t handle_index = 0;


SerialInterfaceOperationResult SerialInterface_init(
		SerialInterface_t* hinterface,
		UART_HandleTypeDef* huart,
		RingBuffer_uint8_t* buffer_rx,
		RingBuffer_uint8_t* buffer_tx
) {
	if(handle_index == SERIAL_INTERFACE_HANDLE_VECTOR_LENGTH) {
		return SERIAL_INTERFACE_OPERATION_FAILED;
	}

	hinterface->huart = huart;

	hinterface->buffer_rx = buffer_rx;
	hinterface->buffer_tx = buffer_tx;
	hinterface->rx_callback = NULL;
	hinterface->tx_callback = NULL;

	HAL_StatusTypeDef status;
	status = HAL_UART_RegisterRxEventCallback(huart, RX_Event);
	if(status != HAL_OK) {
		return SERIAL_INTERFACE_OPERATION_FAILED;
	}

	status = HAL_UART_RegisterCallback(huart, HAL_UART_TX_COMPLETE_CB_ID, Transfer_Complete);
	if(status != HAL_OK) {
		return SERIAL_INTERFACE_OPERATION_FAILED;
	}

	handles[handle_index++] = hinterface;

	return SERIAL_INTERFACE_OPERATION_OK;
}

void SerialInterface_register_rx_callback(SerialInterface_t* hinterface, RX_Callback rx_callback) {
	hinterface->rx_callback = rx_callback;
}

void SerialInterface_register_tx_callback(SerialInterface_t* hinterface, TX_Callback tx_callback) {
	hinterface->tx_callback = tx_callback;
}

SerialInterfaceOperationResult SerialInterface_listen(SerialInterface_t* hinterface) {
	HAL_StatusTypeDef status = HAL_UARTEx_ReceiveToIdle_DMA(hinterface->huart, hinterface->buffer_rx->data, hinterface->buffer_rx->capacity);
	if(status != HAL_OK) {
		return SERIAL_INTERFACE_OPERATION_FAILED;
	}

	return SERIAL_INTERFACE_OPERATION_OK;
}

SerialInterfaceOperationResult SerialInterface_send(SerialInterface_t* hinterface, const uint8_t* data, uint16_t n) {
	for(uint16_t i = 0; i < n; i++) {
		RingBufferOperationResult result = RingBuffer_uint8_put(hinterface->buffer_tx, data[i]);
		if(result != RING_BUFFER_OK) {
			return SERIAL_INTERFACE_OPERATION_FAILED;
		}
	}

	uint16_t size = RingBuffer_uint8_size(hinterface->buffer_tx);
	size = hinterface->buffer_tx->capacity - hinterface->buffer_tx->tail > size ? size : hinterface->buffer_tx->capacity - hinterface->buffer_tx->tail;
	uint8_t* tail = &hinterface->buffer_tx->data[hinterface->buffer_tx->tail];
	HAL_StatusTypeDef status = HAL_UART_Transmit_DMA(hinterface->huart, tail, size);
	if(status == HAL_BUSY) return SERIAL_INTERFACE_OPERATION_OK;
	RingBuffer_uint8_discard(hinterface->buffer_tx, size);

	return SERIAL_INTERFACE_OPERATION_OK;
}

static void Transfer_Complete(UART_HandleTypeDef* huart) {
	for(uint16_t i = 0; i < SERIAL_INTERFACE_HANDLE_VECTOR_LENGTH; i++) {
		SerialInterface_t* hinterface = handles[i];
		if(hinterface->huart != huart) continue;

		if(hinterface->tx_callback != NULL) hinterface->tx_callback(hinterface);

		uint16_t size = RingBuffer_uint8_size(hinterface->buffer_tx);
		if(size == 0) return;

		size = hinterface->buffer_tx->capacity - hinterface->buffer_tx->tail > size ? size : hinterface->buffer_tx->capacity - hinterface->buffer_tx->tail;
		uint8_t* tail = &hinterface->buffer_tx->data[hinterface->buffer_tx->tail];
		HAL_UART_Transmit_DMA(hinterface->huart, tail, size);
		RingBuffer_uint8_discard(hinterface->buffer_tx, size);

		return;
	}
}

static void RX_Event(UART_HandleTypeDef* huart, uint16_t size) {
	for(uint16_t i = 0; i < SERIAL_INTERFACE_HANDLE_VECTOR_LENGTH; i++) {
		SerialInterface_t* hinterface = handles[i];
		if(hinterface->huart != huart) continue;


		hinterface->buffer_rx->head = size;
		if(hinterface->buffer_rx->head == hinterface->buffer_rx->capacity) {
			hinterface->buffer_rx->head = 0;
		}

		if(hinterface->rx_callback != NULL) hinterface->rx_callback(hinterface);
		return;
	}
}
