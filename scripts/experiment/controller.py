import struct
import time
from dataclasses import dataclass, field
from enum import Enum

import serial
from more_itertools import seekable

from experiment.crc import crc8

COMMAND_INITIATOR = 0x7F
COMMAND_END = 0xA9
DEFAULT_COMMAND_LENGTH = 8


class CommandCode(Enum):
    START = 0x01
    STOP = 0x02
    SET_A = 0x10
    SET_B0 = 0x11
    SET_B1 = 0x12
    SET_B2 = 0x13
    SET_C = 0x14
    SET_D0 = 0x15
    SET_D1 = 0x16
    SET_D2 = 0x17
    SET_POSITION = 0x18
    SET_POSITION_REFERENCE = 0x19
    INFO = 0x20


DEFAULT_DATA_LENGTH = 4
FRAME_DATA_LENGTHS = {
    CommandCode.INFO: 13,
}


@dataclass
class Frame:
    code: CommandCode = CommandCode.START
    data: bytearray = field(default_factory=lambda: bytearray([0x0, 0x0, 0x0, 0x0]))


class FrameParserState(Enum):
    READY = 0
    CODE = 1
    DATA = 2
    CRC = 3
    END = 4


@dataclass
class FrameParser:
    current_frame: Frame = field(default_factory=Frame)
    state: FrameParserState = FrameParserState.READY

    def parse(self, data):
        data = seekable(data)

        for token in data:
            match self.state:
                case FrameParserState.READY:
                    if token == COMMAND_INITIATOR:
                        self.state = FrameParserState.CODE
                case FrameParserState.CODE:
                    try:
                        code = CommandCode(token)
                    except ValueError:
                        data.relative_seek(-1)
                        self.state = FrameParserState.READY
                        continue

                    self.current_frame.code = code
                    self.state = FrameParserState.DATA
                    self.current_frame.data = bytearray()
                case FrameParserState.DATA:
                    data_length = FRAME_DATA_LENGTHS.get(self.current_frame.code, DEFAULT_DATA_LENGTH)
                    self.current_frame.data.append(token)
                    if len(self.current_frame.data) == data_length:
                        self.state = FrameParserState.CRC
                case FrameParserState.CRC:
                    content = [self.current_frame.code.value, *self.current_frame.data]
                    crc = crc8(content)
                    if token != crc:
                        data.relative_seek(-len(content))
                        self.state = FrameParserState.READY
                        continue

                    self.state = FrameParserState.END
                case FrameParserState.END:
                    content = [self.current_frame.code.value, *self.current_frame.data]
                    if token != COMMAND_END:
                        self.state = FrameParserState.READY
                        data.relative_seek(-len(content))
                        continue

                    yield self.current_frame
                    self.state = FrameParserState.READY


class ControllerError(Exception):
    ...


@dataclass
class Controller:
    parser: FrameParser
    interface: serial.Serial
    timeout: float = 10.0

    def start(self):
        frame = Frame(CommandCode.START)
        self.send_frame(frame)

    def stop(self):
        frame = Frame(CommandCode.STOP)
        self.send_frame(frame)

    def listen(self):
        while True:
            response = self.interface.read(DEFAULT_COMMAND_LENGTH)
            for frame in self.parser.parse(response):
                match frame.code:
                    case CommandCode.INFO:
                        loop_count = struct.unpack("<H", frame.data[:2])[0]
                        loop_timer_count = struct.unpack("<H", frame.data[2:4])[0]
                        counter = struct.unpack("<H", frame.data[4:6])[0]
                        voltage = struct.unpack("<f", frame.data[6:10])[0]
                        speed_ref = struct.unpack("<H", frame.data[10:12])[0]
                        direction = frame.data[12]
                        yield loop_count, loop_timer_count, counter, voltage, speed_ref, direction

    def set_parameter(self, command: CommandCode, value: float):
        data = bytearray(struct.pack("<f", value))
        frame = Frame(command, data)
        self.send_frame(frame)

    def send_frame(self, frame: Frame):
        code = frame.code.value
        content = [code, *frame.data]
        crc = crc8(content)
        packet = [COMMAND_INITIATOR, *content, crc, COMMAND_END]
        command = bytearray(packet)

        self.interface.write(command)

        start = time.time()
        while time.time() - start < self.timeout:
            response = self.interface.read(DEFAULT_COMMAND_LENGTH)
            if len(response) == 0:
                break

            for response_frame in self.parser.parse(response):
                print(response_frame)
                if response_frame.code != frame.code:
                    continue

                if any(b1 != b2 for b1, b2 in zip(response_frame.data, frame.data)):
                    continue

                return

        raise ControllerError("Failed to parse response")