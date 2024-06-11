/*
 * controller_api.h
 *
 *  Created on: May 9, 2024
 *      Author: tamas
 */

#ifndef INC_CONTROLLER_H_
#define INC_CONTROLLER_H_

#include "stm32f4xx_hal.h"
#include "serial_interface.h"
#include "solo_api.h"

typedef enum {
	CONTROLLER_OK,
	CONTROLLER_FAILED
} ControllerOperationResult;

typedef enum {
	CONTROLLER_READY,
	CONTROLLER_RUNNING
} ControllerState;

typedef enum {
	CONTROLLER_COMMAND_START = 0x01,
	CONTROLLER_COMMAND_STOP = 0x02,
	CONTROLLER_COMMAND_SET_A = 0x10,
	CONTROLLER_COMMAND_SET_B0 = 0x11,
	CONTROLLER_COMMAND_SET_B1 = 0x12,
	CONTROLLER_COMMAND_SET_B2 = 0x13,
	CONTROLLER_COMMAND_SET_C = 0x14,
	CONTROLLER_COMMAND_SET_D0 = 0x15,
	CONTROLLER_COMMAND_SET_D1 = 0x16,
	CONTROLLER_COMMAND_SET_D2 = 0x17,
	CONTROLLER_COMMAND_SET_POSITION = 0x18,
	CONTROLLER_COMMAND_SET_POSITION_REFERENCE = 0x19,
} ControllerCommandCode;

typedef enum {
	CONTROLLER_RESPONSE_INFO = 0x20,
} ControllerResponseCode;

typedef enum {
	CONTROLLER_COMMAND_PARSER_READY,
	CONTROLLER_COMMAND_PARSER_PARSE_CMD,
	CONTROLLER_COMMAND_PARSER_PARSE_DATA,
	CONTROLLER_COMMAND_PARSER_PARSE_CRC,
	CONTROLLER_COMMAND_PARSER_PARSE_END,
} ControllerCommandParserState;

typedef struct {
	ControllerCommandCode code;
	uint8_t data[4];
} ControllerCommand;

typedef struct {
	ControllerCommandParserState state;
	ControllerCommand current_command;
	uint8_t data_index;
} ControllerCommandParser;

typedef struct {
	float Aimp;
	float Bimp[3];
	float Cimp;
	float Dimp[3];

	float nu;

	float position;
	float position_reference;

	float control_voltage;
	uint16_t speed_reference;
	SOLO_Direction direction;

	SerialInterface_t* command_interface;
	SOLO_API_Interface_t* driver_interface;
	TIM_HandleTypeDef* loop_timer;
	TIM_HandleTypeDef* command_timer;
	TIM_HandleTypeDef* encoder_timer;

	ControllerState state;
	ControllerCommandParser command_parser;
	uint16_t loop_count;
} Controller_t;

ControllerOperationResult Controller_init(
		Controller_t* controller,
		SerialInterface_t* command_interface,
		SOLO_API_Interface_t* driver_interface,
		TIM_HandleTypeDef* loop_timer,
		TIM_HandleTypeDef* command_timer,
		TIM_HandleTypeDef* encoder_timer
);
void Controller_listen(Controller_t* controller);

#endif /* INC_CONTROLLER_H_ */
