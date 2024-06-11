/*
 * controller_api.c
 *
 *  Created on: May 9, 2024
 *      Author: tamas
 */

#include "main.h"
#include "stdlib.h"
#include "math.h"
#include "string.h"
#include "stm32f4xx_hal.h"
#include "ring_buffer.h"
#include "controller.h"
#include "crc.h"

#define CONTROLLER_COMMAND_LENGTH 8
#define CONTROLLER_INFO_COMMAND_LENGTH 17
#define CONTROLLER_COMMAND_INITIATOR 0x7F
#define CONTROLLER_COMMAND_END 0xA9

#define CONTROLLER_HANDLE_VECTOR_LENGTH 8

#define MAX_SPEED_REFERENCE 30000
#define MIN_SPEED_REFERENCE 0

#define GEAR_RATIO 4.4
#define ENCODER_COUNTS_PER_HALF_TURN 440

#define MAX_VOLTAGE 11.835

static void Loop_Timeout(TIM_HandleTypeDef* htim);
static void Command_Timeout(TIM_HandleTypeDef* htim);
static void Receive_Command(SerialInterface_t* buffer);
static void Transmit_Complete(SerialInterface_t* hinterface);

static void execute_control_loop(Controller_t*);
static void send_control_command(Controller_t*);
static void update_position(Controller_t*);
static void parse_controller_command(Controller_t* controller);
static void execute_controller_command(Controller_t* controller);
static void send_controller_info(Controller_t* controller);
static void send_command_response(Controller_t* controller, ControllerCommand command);
static void loop_start(Controller_t* controller);
static void loop_stop(Controller_t* controller);
static void serialise_u16(uint16_t value, uint8_t dest[]);
static void serialise_u32(uint32_t value, uint8_t dest[]);
static void serialise_float(float value, uint8_t dest[]);

static Controller_t* handles[CONTROLLER_HANDLE_VECTOR_LENGTH] = {};
static uint16_t handle_index = 0;


ControllerOperationResult Controller_init(
		Controller_t* controller,
		SerialInterface_t* command_interface,
		SOLO_API_Interface_t* driver_interface,
		TIM_HandleTypeDef* loop_timer,
		TIM_HandleTypeDef* command_timer,
		TIM_HandleTypeDef* encoder_timer) {

	if(handle_index == CONTROLLER_HANDLE_VECTOR_LENGTH) {
		return CONTROLLER_FAILED;
	}

	controller->command_interface = command_interface;
	controller->driver_interface = driver_interface;
	controller->loop_timer = loop_timer;
	controller->command_timer = command_timer;
	controller->encoder_timer = encoder_timer;
	controller->loop_count = 0;

	controller->Aimp = 0.0f;
	for (size_t i = 0; i < 3; i++) {
		controller->Bimp[i] = 0.0f;
	}
	controller->Cimp = 0.0f;
	for (size_t i = 0; i < 3; i++) {
		controller->Dimp[i] = 0.0f;
	}

	controller->nu = 0.0f;
	controller->position = 0.0f;
	controller->position_reference = 0.0f;
	controller->state = CONTROLLER_READY;
	controller->command_parser.state = CONTROLLER_COMMAND_PARSER_READY;
	controller->command_parser.data_index = 0;

	HAL_TIM_RegisterCallback(controller->loop_timer, HAL_TIM_PERIOD_ELAPSED_CB_ID, Loop_Timeout);
	HAL_TIM_RegisterCallback(controller->command_timer, HAL_TIM_PERIOD_ELAPSED_CB_ID, Command_Timeout);

	handles[handle_index++] = controller;

	return CONTROLLER_OK;
}

void Controller_listen(Controller_t* controller) {
	SerialInterface_register_rx_callback(controller->command_interface, Receive_Command);
	SerialInterface_register_tx_callback(controller->command_interface, Transmit_Complete);
	SerialInterface_listen(controller->command_interface);
}


static void execute_control_loop(Controller_t* controller) {
	controller->loop_count += 1;
	HAL_GPIO_TogglePin(USER_DBG_GPIO_Port, USER_DBG_Pin);

	float torque = 0.0f;

	update_position(controller);
	float motor_pos_ref = GEAR_RATIO * controller->position_reference;
	float motor_pos = GEAR_RATIO * controller->position;

	float Aimp = controller->Aimp;
	float* Bimp = controller->Bimp;
	float Cimp = controller->Cimp;
	float* Dimp = controller->Dimp;
	float nu = controller->nu;

	float nu_new = Aimp*nu + Bimp[0]*motor_pos_ref + Bimp[1]*torque + Bimp[2]*motor_pos;
	float control_voltage = Cimp*nu + Dimp[0]*motor_pos_ref + Dimp[1]*torque + Dimp[2]*motor_pos;

	controller->nu = nu_new;
	controller->control_voltage = control_voltage;

	if(control_voltage > MAX_VOLTAGE)
		control_voltage = MAX_VOLTAGE;

	if(control_voltage < -MAX_VOLTAGE)
		control_voltage = -MAX_VOLTAGE;

	int16_t speed_reference = (int16_t)(control_voltage / MAX_VOLTAGE * MAX_SPEED_REFERENCE) + MIN_SPEED_REFERENCE;

	if(speed_reference > MAX_SPEED_REFERENCE)
		speed_reference = MAX_SPEED_REFERENCE;

	if(speed_reference < -MAX_SPEED_REFERENCE)
		speed_reference = -MAX_SPEED_REFERENCE;

	controller->speed_reference = abs(speed_reference);

//	if(fabs(controller->position - controller->position_reference) < 0.03f) {
//		controller->speed_reference = 0;
//	}

//	controller->speed_reference = 3000 + 500 * (controller->loop_count / 400);

	controller->direction = speed_reference > 0 ? SOLO_DIRECTION_CCW : SOLO_DIRECTION_CW;
}

static void send_control_command(Controller_t* controller) {
	HAL_TIM_Base_Stop_IT(controller->command_timer);

	if(controller->state != CONTROLLER_RUNNING) {
		SOLO_API_set_speed_reference(controller->driver_interface, 0);
		return;
	}

	SOLO_API_set_direction(controller->driver_interface, controller->direction);
	SOLO_API_set_speed_reference(controller->driver_interface, controller->speed_reference);

	HAL_TIM_Base_Start_IT(controller->command_timer);
}

static void update_position(Controller_t* controller) {
	uint16_t counter = __HAL_TIM_GET_COUNTER(controller->encoder_timer);
	int16_t signed_counter = (int16_t)counter;

	signed_counter = signed_counter > ENCODER_COUNTS_PER_HALF_TURN ? signed_counter - 2*ENCODER_COUNTS_PER_HALF_TURN : signed_counter;
	signed_counter = signed_counter < -ENCODER_COUNTS_PER_HALF_TURN ? signed_counter + 2*ENCODER_COUNTS_PER_HALF_TURN : signed_counter;
	float position = (float)signed_counter / ENCODER_COUNTS_PER_HALF_TURN * M_PI;

	if(position - controller->position_reference > M_PI) {
		controller->position = position - 2*M_PI;
		return;
	}

	if(position - controller->position_reference < -M_PI) {
		controller->position = position + 2*M_PI;
		return;
	}

	controller->position = position;
}

static void parse_controller_command(Controller_t* controller) {
	RingBufferOperationResult result;

	do {
		uint8_t token = 0;
		result = RingBuffer_uint8_pop(controller->command_interface->buffer_rx, &token);

		switch(controller->command_parser.state) {
			case CONTROLLER_COMMAND_PARSER_READY:
				if(token == CONTROLLER_COMMAND_INITIATOR) controller->command_parser.state = CONTROLLER_COMMAND_PARSER_PARSE_CMD;
				break;
			case CONTROLLER_COMMAND_PARSER_PARSE_CMD:
				controller->command_parser.current_command.code = token;
				controller->command_parser.data_index = 0;
				controller->command_parser.state = CONTROLLER_COMMAND_PARSER_PARSE_DATA;
				break;
			case CONTROLLER_COMMAND_PARSER_PARSE_DATA:
				controller->command_parser.current_command.data[controller->command_parser.data_index++] = token;
				if(controller->command_parser.data_index == 4) controller->command_parser.state = CONTROLLER_COMMAND_PARSER_PARSE_CRC;
				break;
			case CONTROLLER_COMMAND_PARSER_PARSE_CRC:
				uint8_t crc_buffer[] = {
						controller->command_parser.current_command.code,
						controller->command_parser.current_command.data[0],
						controller->command_parser.current_command.data[1],
						controller->command_parser.current_command.data[2],
						controller->command_parser.current_command.data[3],
				};
				uint8_t crc = CRC8(crc_buffer, 5);
				if(token != crc) {
					controller->command_parser.state = CONTROLLER_COMMAND_PARSER_READY;
					break;
				}
				controller->command_parser.state = CONTROLLER_COMMAND_PARSER_PARSE_END;
				break;
			case CONTROLLER_COMMAND_PARSER_PARSE_END:
				if(token == CONTROLLER_COMMAND_END) execute_controller_command(controller);
				controller->command_parser.state = CONTROLLER_COMMAND_PARSER_READY;
				break;
		}
	} while(result != RING_BUFFER_EMPTY);
}

static void execute_controller_command(Controller_t* controller) {
	ControllerCommand command = controller->command_parser.current_command;

	switch(command.code) {
		case CONTROLLER_COMMAND_START:
			send_command_response(controller, command);
			loop_start(controller);
			break;
		case CONTROLLER_COMMAND_STOP:
			loop_stop(controller);
			send_command_response(controller, command);
			break;
		case CONTROLLER_COMMAND_SET_A:
			memcpy(&controller->Aimp, command.data, sizeof(float));
			send_command_response(controller, command);
			break;
		case CONTROLLER_COMMAND_SET_B0:
			memcpy(&controller->Bimp[0], command.data, sizeof(float));
			send_command_response(controller, command);
			break;
		case CONTROLLER_COMMAND_SET_B1:
			memcpy(&controller->Bimp[1], command.data, sizeof(float));
			send_command_response(controller, command);
			break;
		case CONTROLLER_COMMAND_SET_B2:
			memcpy(&controller->Bimp[2], command.data, sizeof(float));
			send_command_response(controller, command);
			break;
		case CONTROLLER_COMMAND_SET_C:
			memcpy(&controller->Cimp, command.data, sizeof(float));
			send_command_response(controller, command);
			break;
		case CONTROLLER_COMMAND_SET_D0:
			memcpy(&controller->Dimp[0], command.data, sizeof(float));
			send_command_response(controller, command);
			break;
		case CONTROLLER_COMMAND_SET_D1:
			memcpy(&controller->Dimp[1], command.data, sizeof(float));
			send_command_response(controller, command);
			break;
		case CONTROLLER_COMMAND_SET_D2:
			memcpy(&controller->Dimp[2], command.data, sizeof(float));
			send_command_response(controller, command);
			break;
		case CONTROLLER_COMMAND_SET_POSITION:
			memcpy(&controller->position, command.data, sizeof(float));
			send_command_response(controller, command);
			break;
		case CONTROLLER_COMMAND_SET_POSITION_REFERENCE:
			memcpy(&controller->position_reference, command.data, sizeof(float));
			send_command_response(controller, command);
			break;
	}
}

static void loop_start(Controller_t* controller) {
	if(controller->state != CONTROLLER_READY) return;

	controller->loop_count = 0;
	controller->nu = 0.0;
	controller->position = 0.0;
	controller->control_voltage = 0.0;
	controller->speed_reference = 0;

	__HAL_TIM_CLEAR_FLAG(controller->command_timer, TIM_FLAG_UPDATE);
	__HAL_TIM_CLEAR_FLAG(controller->loop_timer, TIM_FLAG_UPDATE);

	__HAL_TIM_SET_COUNTER(controller->command_timer, 0);
	__HAL_TIM_SET_COUNTER(controller->loop_timer, 0);
	__HAL_TIM_SET_COUNTER(controller->encoder_timer, 0);

	HAL_TIM_Base_Start_IT(controller->command_timer);
	HAL_TIM_Base_Start_IT(controller->loop_timer);

	HAL_TIM_Encoder_Start(controller->encoder_timer, TIM_CHANNEL_ALL);
	controller->state = CONTROLLER_RUNNING;

	send_controller_info(controller);

	SOLO_API_listen(controller->driver_interface);
}

static void loop_stop(Controller_t* controller) {
	if(controller->state != CONTROLLER_RUNNING) return;

	HAL_TIM_Base_Stop_IT(controller->loop_timer);
	HAL_TIM_Encoder_Stop(controller->encoder_timer, TIM_CHANNEL_ALL);

	controller->state = CONTROLLER_READY;

	SOLO_API_set_speed_reference(controller->driver_interface, 0);
}

static void send_controller_info(Controller_t* controller) {
	uint16_t loop_count = controller->loop_count;
	uint16_t loop_timer_count = __HAL_TIM_GET_COUNTER(controller->loop_timer);
	uint16_t counter = __HAL_TIM_GET_COUNTER(controller->encoder_timer);

	uint8_t info_buffer[CONTROLLER_INFO_COMMAND_LENGTH] = {0};
	info_buffer[0] = CONTROLLER_COMMAND_INITIATOR;
	info_buffer[1] = CONTROLLER_RESPONSE_INFO;
	serialise_u16(loop_count, &info_buffer[2]);
	serialise_u16(loop_timer_count, &info_buffer[4]);
	serialise_u16(counter, &info_buffer[6]);
	serialise_float(controller->control_voltage, &info_buffer[8]);
	serialise_u16(controller->speed_reference, &info_buffer[12]);
	info_buffer[14] = controller->direction;
	uint8_t crc = CRC8(&info_buffer[1], 14);
	info_buffer[15] = crc;
	info_buffer[16] = CONTROLLER_COMMAND_END;

	SerialInterface_send(controller->command_interface, info_buffer, CONTROLLER_INFO_COMMAND_LENGTH);
}

static void send_command_response(Controller_t* controller, ControllerCommand command) {
	uint8_t info_buffer[CONTROLLER_COMMAND_LENGTH] = {0};
	info_buffer[0] = CONTROLLER_COMMAND_INITIATOR;
	info_buffer[1] = command.code;
	memcpy(&info_buffer[2], command.data, sizeof(uint8_t)*4);
	uint8_t crc = CRC8(&info_buffer[1], 5);
	info_buffer[6] = crc;
	info_buffer[7] = CONTROLLER_COMMAND_END;

	SerialInterface_send(controller->command_interface, info_buffer, CONTROLLER_COMMAND_LENGTH);
}

static void Loop_Timeout(TIM_HandleTypeDef* htim) {
	for(uint16_t i = 0; i < CONTROLLER_HANDLE_VECTOR_LENGTH; i++) {
		Controller_t* controller = handles[i];
		if(controller->loop_timer != htim) continue;

		execute_control_loop(controller);
	}
}

static void Command_Timeout(TIM_HandleTypeDef* htim) {
	for(uint16_t i = 0; i < CONTROLLER_HANDLE_VECTOR_LENGTH; i++) {
		Controller_t* controller = handles[i];
		if(controller->command_timer != htim) continue;

		send_control_command(controller);
	}
}

static void Transmit_Complete(SerialInterface_t* hinterface) {
	for(uint16_t i = 0; i < CONTROLLER_HANDLE_VECTOR_LENGTH; i++) {
		Controller_t* controller = handles[i];
		if(controller->command_interface != hinterface) continue;

		if(controller->state == CONTROLLER_RUNNING) send_controller_info(controller);
	}
}

static void Receive_Command(SerialInterface_t* hinterface) {
	for(uint16_t i = 0; i < CONTROLLER_HANDLE_VECTOR_LENGTH; i++) {
		Controller_t* controller = handles[i];
		if(controller->command_interface != hinterface) continue;

		parse_controller_command(controller);
	}
}

static void serialise_u16(uint16_t value, uint8_t dest[]) {
	memcpy(dest, &value, sizeof(value));
}

static void serialise_u32(uint32_t value, uint8_t dest[]) {
	memcpy(dest, &value, sizeof(value));
}

static void serialise_float(float value, uint8_t dest[]) {
	memcpy(dest, &value, sizeof(value));
}

