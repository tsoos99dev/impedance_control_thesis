/*
 * ring_buffer.h
 *
 *  Created on: May 10, 2024
 *      Author: tamas
 */

#ifndef INC_RING_BUFFER_H_
#define INC_RING_BUFFER_H_

#include <stdint.h>

typedef enum {
	RING_BUFFER_OK,
	RING_BUFFER_FAILED,
	RING_BUFFER_EMPTY,
	RING_BUFFER_FULL
} RingBufferOperationResult;

typedef struct {
	uint8_t* data;
	uint16_t head;
	uint16_t tail;
	uint16_t capacity;
} RingBuffer_uint8_t;


void RingBuffer_uint8_init(RingBuffer_uint8_t* buffer, uint8_t* data, uint16_t capacity);
uint16_t RingBuffer_uint8_size(const RingBuffer_uint8_t* buffer);
RingBufferOperationResult RingBuffer_uint8_put(RingBuffer_uint8_t* buffer, const uint8_t data);
RingBufferOperationResult RingBuffer_uint8_pop(RingBuffer_uint8_t* buffer, uint8_t* data);
void RingBuffer_uint8_discard(RingBuffer_uint8_t* buffer, uint16_t n);


#endif /* INC_RING_BUFFER_H_ */
