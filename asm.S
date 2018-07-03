;Демонстрационная реализация устройства USB HID на ассемблере для AT90USB162.
;Автор Каменяр Сергей <batonator@yandex.ru> (15 июля 2016 г.)
;Размер EP0=32 байта.
;.include "iousb162.h"
.include "usb162def.inc"
 
.CSEG

;------------------------------------------------
;Вектора сброса и обработчиков прерываний:
;------------------------------------------------
.ORG $000
   rjmp RESET
.ORG $016
   rjmp USB_GENERAL     ;обработка общих событий
.ORG $018
   rjmp USB_ENDPOINT    ;обработка прерывания конечной точки

EP0   EQU   EPNUM0      ;конечная точка управления
EP1   EQU   EPNUM1      ;конечная точка IN
EP2   EQU   EPNUM2      ;конечная точка OUT

CMD_USB_SET_ADDRESS        EQU   0x05
CMD_USB_GET_DESCRIPTOR     EQU   0x06

;------------------------------------------------
;Начало основной программы:
;------------------------------------------------
RESET:
   ldi R16, high(RAMEND)
   out SPH, R16
   ldi R16, low(RAMEND)
   out SPL, R16
   clr R1
   clr R2
   clr R25
   clr R26
 
   ldi R16, 0 << REGDIS
   sts REGCR, R16
 
   cli
   wdr
   in R16, MCUSR
   andi R16, (0xff & (0 << WDRF))
   out MCUSR, R16
   lds R16, WDTCSR
   ori R16, (1 << WDCE)|(1 << WDE)
   sts WDTCSR, R16
   ldi R16, (0 << WDE) 
   sts WDTCSR, R16
   ldi R16, 0x1F   ;00011111
   out DDRD, R16
   ldi R16, 0      ;00000000
   out PORTD, R16
   ldi R16, (0 << PLLP2)+(0 << PLLP1)+(1 << PLLP0)+(1 << PLLE)
   out PLLCSR, R16
bit_lock:
   in R16, PLLCSR
   sbrs R16, 0
   rjmp bit_lock
   lds R16, USBCON
   sbr R16, 1 << USBE
   sts USBCON, R16
   cbr R16, 1 << FRZCLK
   sts USBCON, R16
   lds R16, UDCON
   cbr R16, 1 << DETACH
   sts UDCON, R16
r_bus:
   lds R16, UDINT
   sbrs R16, 3
   rjmp r_bus
   cbr R16, 1 << EORSTI
   sts UDINT, R16
   rcall conf_ep_0
   lds R16, UDCON
   sbr R16, 1 << RSTCPU
   sts UDCON, R16
   ldi R24, (1 << SUSPE)+(1 << EORSTE)
   sts UDIEN, R24
   ldi R24, 1 << RXSTPE
   sts UEIENX, R24
   ldi R16, 1 << SE
   out SMCR, R16
   sei
SLP:
   sleep
   rjmp SLP
   
;------------------------------------------------
;Обработчик общих прерываний USB
;------------------------------------------------
USB_GENERAL:
   lds R24, UDINT 
   sbrs R24, 3
   rjmp next_ev_1
   cbr R24, 1 << EORSTI 
   sts UDINT, R24
   rjmp vihod_ug

next_ev_1:
   sbrs R24, 0
   rjmp next_ev_2
   cbr R24, 1 << SUSPI
   sts UDINT, R24
   lds R24, USBCON
   sbr R24, 1 << FRZCLK
   sts USBCON, R24
   in R16, PLLCSR
   cbr R16, 1 << PLLE
   out PLLCSR, R16
   lds R24, UDIEN
   sbr R24, 1 << WAKEUPE
   sts UDIEN, R24
   rjmp vihod_ug
   
next_ev_2:
   sbrs R24, 4
   rjmp vihod_ug
   in R16, PLLCSR
   sbr R16, 1 << PLLE
   out PLLCSR, R16
lock_bit:
   in R16, PLLCSR
   sbrs R16, 0
   rjmp lock_bit
   lds R24, USBCON 
   cbr R24, 1 << FRZCLK 
   sts USBCON, R24
   lds R24, UDINT
   cbr R24, 1 << WAKEUPI
   sts UDINT, R24
   lds R24, UDIEN
   cbr R24, 1 << WAKEUPE
   sts UDIEN, R24
   sts UENUM, R1
   inc R2
vihod_ug:
   reti

;------------------------------------------------
; Обработчик прерывания конечной точки 
;------------------------------------------------
USB_ENDPOINT:
   lds R24, UEINT
   cpi R24, 1 << EP0
   brne ep_1
   rjmp ep_0

ep_1:
   cpi R24, 1 << EP1
   brne ep_2
   rjmp ep_in

ep_2:
   cpi R24, 1 << EP2
   brne ep_no
   rjmp ep_out

ep_no:
   rjmp vihod_ep

ep_0:
; Управляющая конечная точка
   lds R17, UEDATX
   lds R16, UEDATX

   cpi R16, CMD_USB_GET_DESCRIPTOR
   brne next_0
   rjmp get_dsc

next_0:
   cpi R16, CMD_USB_SET_ADDRESS
   brne next_1
   rjmp set_adr

next_1:
   cpi R16, 0x09
   brne next_2
   cpi R17, 0x00
   brne next_2
   rjmp set_cfg
   
next_2:
   cpi R16, 0x0A
   brne next_3
   cpi R17, 0x21
   brne next_3
   rjmp set_idle

next_3:
   rjmp n_3

get_dsc:
   cpi R17, 0x80         ;Get_Stand_device
   brne sl_1
   rjmp stand_desc

sl_1:
   cpi R17, 0x81
   brne sl_2
   rjmp int_desc
   
sl_2:
   rjmp vihod_ep
   
stand_desc:
   rcall read_buff
   cpi R19, 1
   brne n_1
   rjmp d_dev

n_1:
   cpi R19, 2
   brne n_2
   rjmp d_con

n_2:
   cpi R19, 3
   brne n_4
   rjmp d_str
   
n_3:
   lds R24, UEINTX
   cbr R24, 1 << RXSTPI
   sts UEINTX, R24
n_4:
   lds R24, UEINTX
   sbrs R24, 0
   rjmp n_4
   lds R24, UECONX
   sbr R24, 1 << STALLRQ
   sts UECONX, R24
   rjmp vihod_ep

d_dev:
   lds R24, UEINTX
   sbrs R24, 0
   rjmp d_dev
   ldi R31, high(dev_desc*2)
   ldi R30, low(dev_desc*2)
out_data_d:
   lpm R24, Z+
   sts UEDATX, R24
   cpi R30, 18
   brne out_data_d
   lds R24, UEINTX
   cbr R24, 1 << TXINI
   sts UEINTX, R24
   rcall w_nakout
   rjmp vihod_ep

d_con:
   lds R24, UEINTX
   sbrs R24, 0
   rjmp d_con
   ldi R31, high(con_desc*2)
   ldi R30, low(con_desc*2)
   clr R23
   cpi R22, 9
   breq con_drv
out_dat_c:
   lpm R24, Z+
   sts UEDATX, R24
   inc R23
   cpi R23, 32
   brne out_dat_c
   lds R24, UEINTX
   cbr R24, 1 << TXINI
   sts UEINTX, R24
d_con_1:
   lds R24, UEINTX
   sbrs R24, 0  
   rjmp d_con_1
out_dat_c1:
   lpm R24, Z+
   sts UEDATX, R24
   inc R23
   cpi R23, 41
   brne out_dat_c1
   lds R24, UEINTX
   cbr R24, 1 << TXINI
   sts UEINTX, R24
   rcall w_nakout
   rjmp vihod_ep
   
con_drv:
   lpm R24, Z+
   sts UEDATX, R24
   inc R23
   cpi R23, 9
   brne con_drv
   lds R24, UEINTX
   cbr R24, 1 << TXINI
   sts UEINTX, R24
   rcall w_nakout
   rjmp vihod_ep

d_str:
   cpi R18, 0
   brne s_1
   ldi R31, high(str_0*2)
   ldi R30, low(str_0*2)
   ldi R20, 4
   rjmp d_str_1

s_1:
   cpi R18, 1
   brne s_2
   ldi R31, high(str_1*2)
   ldi R30, low(str_1*2)
   ldi R20, 12
   rjmp d_str_1

s_2:
   cpi R18, 2
   brne s_3
   ldi R31, high(str_2*2)
   ldi R30, low(str_2*2)
   ldi R20, 32
   rjmp d_str_1

s_3:
   cpi R18, 3
   brne s_4
   ldi R31, high(str_3*2)
   ldi R30, low(str_3*2)
   ldi R20, 10
   rjmp d_str_1

s_4:
   rjmp vihod_ep

d_str_1:
   lds R24, UEINTX 
   sbrs R24, 0
   rjmp d_str_1
out_st:
   lpm R24, Z+
   sts UEDATX, R24
   dec R20
   brne out_st
   lds R24, UEINTX
   cbr R24, 1 << TXINI
   sts UEINTX, R24
   cpi R18, 2
   breq d_str_2
   rcall w_nakout
   rjmp vihod_ep

d_str_2:
   lds R24, UEINTX
   sbrs R24, 0
   rjmp d_str_2
out_st_1:
   lpm R24, Z+
   sts UEDATX, R24
   inc R20
   cpi R20, 2
   brne out_st_1
   lds R24, UEINTX
   cbr R24, 1 << TXINI
   sts UEINTX, R24
   rcall w_nakout
   rjmp vihod_ep

int_desc:
   rcall read_buff
   cpi R19, 0x22
   breq n_5
   rjmp vihod_ep

n_5:
   cpi R22,0x62
   breq d_rep_1
   rjmp vihod_ep

d_rep_1:
   sbi PORTD, 4
   lds R24, UEINTX
   sbrs R24, 0
   rjmp d_rep_1
   clr R23
   ldi R31, high(rep_desc*2)
   ldi R30, low(rep_desc*2)
out_dat_r:
   lpm R24, Z+
   sts UEDATX, R24
   inc R23
   cpi R23, 32
   brne out_dat_r
   lds R24, UEINTX
   cbr R24, 1 << TXINI
   sts UEINTX, R24
d_rep_2:
   lds R24, UEINTX   
   sbrs R24, 0 
   rjmp d_rep_2
out_dat_r1:
   lpm R24, Z+
   sts UEDATX, R24
   inc R23
   cpi R23, 34
   brne out_dat_r1
   lds R24, UEINTX
   cbr R24, 1 << TXINI
   sts UEINTX, R24
   rcall w_nakout
   ldi R16, 2
   sts UENUM, R16
   ldi R24, 1 << RXOUTE
   sts UEIENX, R24
   rjmp vihod_ep

ep_out:
   lds R24, UEINTX
   sbrs R24, 2           ;RXOUTI
   rjmp ep_out
   sbrs R24, 7           ;FIFOCON
   rjmp ep_out
   lds R24, UEINTX
   cbr R24, 1 << RXOUTI
   sts UEINTX, R24
   lds R3, UEDATX
   lds R4, UEDATX
   lds R5, UEDATX
   lds R6, UEDATX
   lds R7, UEDATX
   lds R8, UEDATX
   lds R9, UEDATX
   lds R10, UEDATX
   lds R24, UEINTX
   cbr R24, 1 << FIFOCON
   sts UEINTX, R24
   ldi R16, 1
   sts UENUM, R16
   ldi R24, 1 << TXINE
   sts UEIENX, R24
   rjmp vihod_ep 

ep_in:
   lds R24, UEINTX
   sbrs R24, 7       ;FIFOCON
   rjmp ep_in
   sbrs R24, 0       ;TXINI
   rjmp ep_in
   sts UEDATX, R3
   sts UEDATX, R4
   sts UEDATX, R5
   sts UEDATX, R6
   sts UEDATX, R7
   sts UEDATX, R8
   sts UEDATX, R9
   sts UEDATX, R10
   lds R24, UEINTX
   cbr R24, 1 << TXINI
   sts UEINTX, R24
   cbr R24, 1 << FIFOCON
   sts 0x00E8, R24
no_in:
   lds R24, UEINTX
   sbrs R24, 0       ;TXINI
   rjmp no_in
   sbrs R24, 7       ;FIFOCON
   rjmp no_in
   ldi R24, 1 << RXOUTE
   sts UEIENX, R24
   ldi R16, 2
   sts UENUM, R16
   rjmp vihod_ep

set_adr:
   lds R24, UEDATX  
   andi R24, 0x7F
   sts UDADDR, R24  
   lds R24, UEINTX  
   cbr R24, 1 << RXSTPI
   sts UEINTX, R24
   lds R24, UEINTX
   sbrs R24, 0   
   rjmp vihod_ep
   cbr R24, 1 << TXINI
   sts UEINTX, R24
vt:
   lds R24, UEINTX
   sbrs R24, 0
   rjmp vt
   lds R24, UDADDR
   ori R24, 0x80
   sts UDADDR, R24
   rjmp vihod_ep

set_cfg:
   lds R24, UEINTX
   cbr R24, 1 << RXSTPI
   sts UEINTX, R24
s_cfg:
   lds R24, UEINTX
   sbrs R24, 0
   rjmp s_cfg
   cbr R24, 1 << TXINI
   sts UEINTX, R24
   ldi R16, 1
   sts UENUM, R16
   lds R16, UECONX  
   sbrs R16, 0
   ori R16, 0x01
   sts UECONX, R16 
   ldi R16, (1 << EPTYPE1)+(1 << EPTYPE0)+(1 << EPDIR)
   sts UECFG0X, R16
   ldi R16, 0x02
   sts UECFG1X, R16
test_c_ep1:
   lds R16, UESTA0X 
   sbrs R16, 7 
   rjmp test_c_ep1
   ldi R16, 2
   sts UENUM, R16
   lds R16, UECONX
   sbrs R16, 0
   ori R16, 0x01
   sts UECONX, R16
   ldi R16, (1 << EPTYPE1)+(1 << EPTYPE0)+(0 << EPDIR)
   sts UECFG0X, R16 
   ldi R16, 0x02
   sts UECFG1X, R16
test_c_ep2:
   lds R16, UESTA0X
   sbrs R16, 7 
   rjmp test_c_ep2
   sts UENUM, R1  
   rjmp vihod_ep

set_idle:
   lds R24, UEINTX 
   cbr R24, 1 << RXSTPI
   sts UEINTX, R24
   lds R24, UEINTX
   sbrs R24, 0   
   rjmp vihod_ep
   cbr R24, 1 << TXINI
   sts UEINTX, R24
   tst R2
   breq vihod_ep
   clr R2
   ldi R16, 2
   sts UENUM, R16
vihod_ep:
   reti

conf_ep_0:
   sts UENUM, R1
   lds R16, UECONX  
   sbrs R16, 0
   ori R16, 0x01
   sts UECONX, R16
   ldi R16, (0 << EPTYPE1)+(0 << EPTYPE0)+(0 << EPDIR)
   sts UECFG0X, R16
   ldi R16, 0x22
   sts UECFG1X, R16
test_c_ep0:
   lds R16, UESTA0X
   sbrs R16, 7           ;если CFGOK=1 - EP0 сконфигурирована - идем дальше.
   rjmp test_c_ep0
   ret

w_nakout:
   lds R24, UEINTX
   sbrs R24, 4
   rjmp w_nakout
   cbr R24, 1 << NAKOUTI
   sts UEINTX, R24
w_out:
   lds R24, UEINTX
   sbrs R24, 2
   rjmp w_out
   cbr R24, 1 << RXOUTI
   sts UEINTX, R24
   ret

read_buff:
   lds R18, UEDATX    ;String_type
   lds R19, UEDATX    ;Desc_type=01
   lds R20, UEDATX    ;Dummy_byte
   lds R21, UEDATX    ;Dummy_byte
   lds R22, UEDATX    ;LSB(wLength)
   lds R23, UEDATX    ;MSB(wLength)
   lds R24, UEINTX
   cbr R24, 1 << RXSTPI
   sts UEINTX, R24
   ret
   
.ORG $300
dev_desc:
   .DB 0x12,0x01,0x00,0x02,0x00,0x00,0x00,0x20,0xEB,0x03
   .DB 0x13,0x20,0x00,0x10,0x01,0x02,0x03,0x01
con_desc:
   .DB 0x09,0x02,0x29,0x00,0x01,0x01,0x00,0x80,0x32,0x09
   .DB 0x04,0x00,0x00,0x02,0x03,0x00,0x00,0x00,0x09,0x21
   .DB 0x00,0x01,0x00,0x01,0x22,0x22,0x00,0x07,0x05,0x81
   .DB 0x03,0x08,0x00,0x0F,0x07,0x05,0x02,0x03,0x08,0x00
   .DB 0x0F
str_0:
   .DB 0x04,0x03,0x09,0x04
str_1:
   .DB 0x0C,0x03,0x41,0x00,0x54,0x00,0x4D,0x00,0x45,0x00
   .DB 0x4C,0x00
str_2:
   .DB 0x22,0x03,0x41,0x00,0x56,0x00,0x52,0x00,0x20,0x00
   .DB 0x55,0x00,0x53,0x00,0x42,0x00,0x20,0x00,0x48,0x00
   .DB 0x49,0x00,0x44,0x00,0x20,0x00,0x44,0x00,0x45,0x00
   .DB 0x4D,0x00,0x4F,0x00
str_3:
   .DB 0x0A,0x03,0x30,0x00,0x30,0x00,0x30,0x00,0x30,0x00
rep_desc:
   .DB 0x06,0x00,0xFF,0x09,0x00,0xA1,0x01,0x09,0x00,0x15
   .DB 0x00,0x26,0xFF,0x00,0x75,0x08,0x95,0x08,0x81,0x02
   .DB 0x09,0x00,0x15,0x00,0x26,0xFF,0x00,0x75,0x08,0x95
   .DB 0x08,0x91,0x02,0xC0

.EXIT
