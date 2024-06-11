/*
 * solo_api.c
 *
 *  Created on: May 9, 2024
 *      Author: tamas
 */

#include "stdint.h"
#include "stdlib.h"
#include "string.h"
#include "stm32f4xx_hal.h"
#include "solo_api.h"

#include "ring_buffer.h"

#define SOLO_API_HANDLE_VECTOR_LENGTH 2

#define SOLO_COMMAND_LENGTH 10
#define SOLO_COMMAND_INITIATOR_BYTE0 0xff
#define SOLO_COMMAND_INITIATOR_BYTE1 0xff
#define SOLO_COMMAND_CRC 0x0
#define SOLO_COMMAND_ENDING 0xfe
#define SOLO_COMMAND_DEVICE_ADDRESS_BYTE_INDEX 2
#define SOLO_COMMAND_CODE_BYTE_INDEX 3
#define SOLO_COMMAND_DATA_BYTE_INDEX 4
#define SOLO_COMMAND_CRC_BYTE_INDEX 8
#define SOLO_COMMAND_ENDING_BYTE_INDEX 9

#define SOLO_DATA_LENGTH 4

#define MAX_SPEED_REFERENCE 30000
#define MAX_ALLOWED_SPEED_REFERENCE 25000

typedef enum {
  SOLO_COMMAND_CODE_COMMAND_MODE = 0x02,
  SOLO_COMMAND_CODE_SPEED_REF = 0x05,
  SOLO_COMMAND_CODE_DIRECTION = 0x0C
} SOLO_CommandCode;

typedef struct {
	uint8_t device_address;
	SOLO_CommandCode code;
	uint8_t data[SOLO_DATA_LENGTH];
} SOLOCommand;

static void Receive_Response(SerialInterface_t* hinterface);
static void Command_Timeout(TIM_HandleTypeDef* htim);

static SOLO_API_OperationResult send_command(SOLO_API_Interface_t* hsolo, SOLO_CommandCode command_code, uint8_t data[SOLO_DATA_LENGTH]);
static void serialise_u32(uint32_t value, uint8_t dest[]);

static SOLO_API_Interface_t* handles[SOLO_API_HANDLE_VECTOR_LENGTH] = {};
static uint16_t handle_index = 0;

SOLO_API_OperationResult SOLO_API_init(
		SOLO_API_Interface_t* hsolo,
		SerialInterface_t* interface,
		RingBuffer_uint8_t* command_buffer,
		TIM_HandleTypeDef* command_timer,
		uint8_t device_address
) {
	if(handle_index == SOLO_API_HANDLE_VECTOR_LENGTH) {
		return SOLO_API_OPERATION_FAILED;
	}

	hsolo->interface = interface;
	hsolo->command_buffer = command_buffer;
	hsolo->is_sending = 0;
	hsolo->device_address = device_address;
	hsolo->command_timer = command_timer;

	handles[handle_index++] = hsolo;

	return SOLO_API_OPERATION_OK;
}

SOLO_API_OperationResult SOLO_API_listen(SOLO_API_Interface_t* hsolo) {
	HAL_TIM_RegisterCallback(hsolo->command_timer, HAL_TIM_PERIOD_ELAPSED_CB_ID, Command_Timeout);
	SerialInterface_register_rx_callback(hsolo->interface, Receive_Response);
	SerialInterface_listen(hsolo->interface);

	return SOLO_API_OPERATION_OK;
}

SOLO_API_OperationResult SOLO_API_set_command_mode(SOLO_API_Interface_t* hsolo, SOLO_CommandMode mode) {
	uint8_t data[SOLO_DATA_LENGTH] = {0};
	serialise_u32(mode, data);
	return send_command(hsolo, SOLO_COMMAND_CODE_COMMAND_MODE, data);
}

SOLO_API_OperationResult SOLO_API_set_speed_reference(SOLO_API_Interface_t* hsolo, uint32_t value) {
	value = value > MAX_ALLOWED_SPEED_REFERENCE ? MAX_ALLOWED_SPEED_REFERENCE : value;
	uint8_t data[SOLO_DATA_LENGTH] = {0};
	serialise_u32(value, data);
	return send_command(hsolo, SOLO_COMMAND_CODE_SPEED_REF, data);
}

SOLO_API_OperationResult SOLO_API_set_direction(SOLO_API_Interface_t* hsolo, SOLO_Direction direction) {
	uint8_t data[SOLO_DATA_LENGTH] = {0};
	serialise_u32(direction, data);
	return send_command(hsolo, SOLO_COMMAND_CODE_DIRECTION, data);
}

static SOLO_API_OperationResult send_command(SOLO_API_Interface_t* hsolo, SOLO_CommandCode command_code, uint8_t data[SOLO_DATA_LENGTH]) {
	uint8_t command[SOLO_COMMAND_LENGTH] = {0};
	command[0] = SOLO_COMMAND_INITIATOR_BYTE0;
	command[1] = SOLO_COMMAND_INITIATOR_BYTE1;
	command[SOLO_COMMAND_DEVICE_ADDRESS_BYTE_INDEX] = hsolo->device_address;
	command[SOLO_COMMAND_CODE_BYTE_INDEX] = command_code;
	memcpy(&command[SOLO_COMMAND_DATA_BYTE_INDEX], data, sizeof(uint8_t)*SOLO_DATA_LENGTH);
	command[SOLO_COMMAND_CRC_BYTE_INDEX] = SOLO_COMMAND_CRC;
	command[SOLO_COMMAND_ENDING_BYTE_INDEX] = SOLO_COMMAND_ENDING;

	if(hsolo->is_sending) {
		for(uint16_t i = 0; i < SOLO_COMMAND_LENGTH; i++) {
			RingBufferOperationResult status = RingBuffer_uint8_put(hsolo->command_buffer, command[i]);
			if(status != RING_BUFFER_OK) {
				return SOLO_API_OPERATION_FAILED;
			}
		}

		return SOLO_API_OPERATION_OK;
	}

	SerialInterfaceOperationResult result = SerialInterface_send(hsolo->interface, command, SOLO_COMMAND_LENGTH);
	if(result != SERIAL_INTERFACE_OPERATION_OK) {
		return SOLO_API_OPERATION_FAILED;
	}

	HAL_TIM_Base_Start_IT(hsolo->command_timer);

	hsolo->is_sending = 1;
	return SOLO_API_OPERATION_OK;
}

static void serialise_u32(uint32_t value, uint8_t dest[]) {
	value = __REV(value);
	memcpy(dest, &value, sizeof(value));
}

static void Receive_Response(SerialInterface_t* hinterface) {
	for(uint16_t i = 0; i < SOLO_API_HANDLE_VECTOR_LENGTH; i++) {
		SOLO_API_Interface_t* hsolo = handles[i];
		if(hsolo->interface != hinterface) continue;

		HAL_TIM_Base_Stop_IT(hsolo->command_timer);

		uint8_t command[SOLO_COMMAND_LENGTH] = {0};
		for(uint16_t i = 0; i < SOLO_COMMAND_LENGTH; i++) {
			RingBufferOperationResult status = RingBuffer_uint8_pop(hsolo->command_buffer, &command[i]);
			if(status != RING_BUFFER_OK) {
				hsolo->is_sending = 0;
				return;
			}
		}

		SerialInterface_send(hsolo->interface, command, SOLO_COMMAND_LENGTH);
		HAL_TIM_Base_Start_IT(hsolo->command_timer);
	}
}

static void Command_Timeout(TIM_HandleTypeDef* htim) {
	for(uint16_t i = 0; i < SOLO_API_HANDLE_VECTOR_LENGTH; i++) {
		SOLO_API_Interface_t* hsolo = handles[i];
		if(hsolo->command_timer != htim) continue;

		HAL_TIM_Base_Stop_IT(hsolo->command_timer);

		uint8_t command[SOLO_COMMAND_LENGTH] = {0};
		for(uint16_t i = 0; i < SOLO_COMMAND_LENGTH; i++) {
			RingBufferOperationResult status = RingBuffer_uint8_pop(hsolo->command_buffer, &command[i]);
			if(status != RING_BUFFER_OK) {
				hsolo->is_sending = 0;
				return;
			}
		}

		SerialInterface_send(hsolo->interface, command, SOLO_COMMAND_LENGTH);
		HAL_TIM_Base_Start_IT(hsolo->command_timer);
	}
}
