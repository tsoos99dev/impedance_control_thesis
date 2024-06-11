/*
 * solo_api.h
 *
 *  Created on: May 9, 2024
 *      Author: tamas
 */

#ifndef INC_SOLO_API_H_
#define INC_SOLO_API_H_

#include "serial_interface.h"

typedef enum {
	SOLO_API_OPERATION_OK,
	SOLO_API_OPERATION_FAILED
} SOLO_API_OperationResult;

typedef enum {
  SOLO_DIRECTION_CW = 0,
  SOLO_DIRECTION_CCW = 1
} SOLO_Direction;

typedef enum {
  SOLO_COMMAND_MODE_ANALOG = 0,
  SOLO_COMMAND_MODE_DIGITAL = 1
} SOLO_CommandMode;

typedef struct {
	SerialInterface_t* interface;
	uint8_t is_sending;
	uint8_t device_address;
	RingBuffer_uint8_t* command_buffer;
	TIM_HandleTypeDef* command_timer;
} SOLO_API_Interface_t;

SOLO_API_OperationResult SOLO_API_init(
		SOLO_API_Interface_t* hsolo,
		SerialInterface_t* interface,
		RingBuffer_uint8_t* command_buffer,
		TIM_HandleTypeDef* command_timer,
		uint8_t device_address
);
SOLO_API_OperationResult SOLO_API_listen(SOLO_API_Interface_t* hsolo);
SOLO_API_OperationResult SOLO_API_set_command_mode(SOLO_API_Interface_t* hsolo, SOLO_CommandMode mode);
SOLO_API_OperationResult SOLO_API_set_speed_reference(SOLO_API_Interface_t* hsolo, uint32_t value);
SOLO_API_OperationResult SOLO_API_set_direction(SOLO_API_Interface_t* hsolo, SOLO_Direction direction);

#endif /* INC_SOLO_API_H_ */
