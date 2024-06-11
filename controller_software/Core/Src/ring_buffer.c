/*
 * ring_buffer.c
 *
 *  Created on: May 10, 2024
 *      Author: tamas
 */


#include "ring_buffer.h"


void RingBuffer_uint8_init(RingBuffer_uint8_t* buffer, uint8_t* data, uint16_t capacity) {
	buffer->head = 0;
	buffer->tail = 0;
	buffer->data = data;
	buffer->capacity = capacity;
}

uint16_t RingBuffer_uint8_size(const RingBuffer_uint8_t* buffer) {
	return buffer->head >= buffer->tail ? buffer->head - buffer->tail : buffer->head + buffer->capacity - buffer->tail;
}

RingBufferOperationResult RingBuffer_uint8_put(RingBuffer_uint8_t* buffer, const uint8_t data) {
	uint16_t next = buffer->head + 1;
	if(next >= buffer->capacity) {
		next = 0;
	}

	if(next == buffer->tail) return RING_BUFFER_FULL;
	buffer->data[buffer->head] = data;
	buffer->head = next;

	return RING_BUFFER_OK;
}

RingBufferOperationResult RingBuffer_uint8_pop(RingBuffer_uint8_t* buffer, uint8_t* data) {
	if(buffer->head == buffer->tail) return RING_BUFFER_EMPTY;

	uint8_t next = buffer->tail + 1;
	if(next >= buffer->capacity) {
		next = 0;
	}

	*data = buffer->data[buffer->tail];
	buffer->tail = next;

	return RING_BUFFER_OK;
}

void RingBuffer_uint8_discard(RingBuffer_uint8_t* buffer, uint16_t n) {
	for(uint16_t i = 0; i < n; i += 1) {
		if(buffer->head == buffer->tail) return;

		uint8_t next = buffer->tail + 1;
		if(next >= buffer->capacity) {
			next = 0;
		}

		buffer->tail = next;
	}
}
