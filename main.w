Checking DTR in firmware before sending data to host is necessary in order that
data will not be transmitted to host until
DTR is enabled, which is done in application after applying tty settings, which is
useful when MCU reads data from host - to avoid echoing back sent data if MCU starts to
transmit until echo was disabled by tty settings.
