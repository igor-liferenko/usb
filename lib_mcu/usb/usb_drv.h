#ifndef _USB_DRV_H_
#define _USB_DRV_H_

#define MAX_EP_NB             7

#define EP_CONTROL            0

// USB EndPoint
#define MSK_EP_DIR            0x7F
#define MSK_UADD              0x7F

// Parameters for endpoint configuration
// These define are the values used to enable and configure an endpoint.
#define TYPE_CONTROL             0
#define TYPE_BULK                2
#define TYPE_INTERRUPT           3

#define DIRECTION_OUT            0
#define DIRECTION_IN             1

#define SIZE_32                  2

#define ONE_BANK                 0

#define NYET_ENABLED             0
#define NYET_DISABLED            1

#define Is_ep_addr_in(x)         (  (x&USB_ENDPOINT_DIR_MASK)?   TRUE : FALSE)

// Configuration macros for endpoints
#define Usb_build_ep_config0(type, dir, nyet)     ((type<<6) | (nyet<<1) | (dir))
#define Usb_build_ep_config1(size, bank     )     ((size<<4) | (bank<<2)        )
#define usb_configure_endpoint(num, type, dir, size, bank, nyet)             \
                                    ( Usb_select_endpoint(num),              \
                                      usb_config_ep(Usb_build_ep_config0(type, dir, nyet),\
                                                    Usb_build_ep_config1(size, bank)    ))

   //! returns the USB general interrupts (interrupt enabled)
#define Usb_get_general_interrupt()      (USBINT & (USBCON & MSK_IDTE_VBUSTE))
   //! acks the general interrupts (interrupt enabled)
#define Usb_ack_all_general_interrupt()  (USBINT = ~(USBCON & MSK_IDTE_VBUSTE))
#define Usb_ack_cache_id_transition(x)   ((x)  &= ~(1<<IDTI))
#define Usb_ack_cache_vbus_transition(x) ((x)  &= ~(1<<VBUSTI))
#define Is_usb_cache_id_transition(x)    (((x) &   (1<<IDTI))  )
#define Is_usb_cache_vbus_transition(x)  (((x) &   (1<<VBUSTI)))

//! @defgroup USB_device_driver USB device controller drivers
//! These macros manage the USB Device controller.
//! @{
   //! returns the USB device interrupts (interrupt enabled)
   #define Usb_get_device_interrupt()                (UDINT   &   (1<<UDIEN))
   //! acks the USB device interrupts (interrupt enabled)
   #define Usb_ack_all_device_interrupt()            (UDINT   =  ~(1<<UDIEN))

   //! enables USB device address
#define Usb_enable_address()                      (UDADDR  |=  (1<<ADDEN))
   //! disables USB device address
#define Usb_disable_address()                     (UDADDR  &= ~(1<<ADDEN))
   //! test if device is adressed
#define Is_usb_addressed()                        ((UDADDR & (1<<ADDEN)) ? TRUE : FALSE)
   //! sets the USB device address
#define Usb_configure_address(addr)               (UDADDR  =   (UDADDR & (1<<ADDEN)) | ((U8)addr & MSK_UADD))

   //! returns the last frame number
#define Usb_frame_number()                        ((U16)((((U16)UDFNUMH) << 8) | ((U16)UDFNUML)))
   //! tests if a crc error occurs in frame number
#define Is_usb_frame_number_crc_error()           ((UDMFN & (1<<FNCERR)) ? TRUE : FALSE)
//! @}




//! @defgroup usb_gen_ep USB endpoint drivers
//! These macros manage the common features of the endpoints.
//! @{
   //! selects the endpoint number to interface with the CPU
#define Usb_select_endpoint(ep)                   (UENUM = (U8)ep )

   //! get the currently selected endpoint number
#define Usb_get_selected_endpoint()               (UENUM )

   //! resets the selected endpoint
#define Usb_reset_endpoint(ep)                    (UERST   =   1 << (U8)ep, UERST  =  0)

   //! enables the current endpoint
#define Usb_enable_endpoint()                     (UECONX  |=  (1<<EPEN))
   //! enables the STALL handshake for the next transaction
#define Usb_enable_stall_handshake()              (UECONX  |=  (1<<STALLRQ))
   //! resets the data toggle sequence
#define Usb_reset_data_toggle()                   (UECONX  |=  (1<<RSTDT))
   //! disables the current endpoint
#define Usb_disable_endpoint()                    (UECONX  &= ~(1<<EPEN))
   //! disables the STALL handshake
#define Usb_disable_stall_handshake()             (UECONX  |=  (1<<STALLRQC))
   //! selects endpoint interface on CPU
#define Usb_select_epnum_for_cpu()                (UECONX  &= ~(1<<EPNUMS))
   //! tests if the current endpoint is enabled
#define Is_usb_endpoint_enabled()                 ((UECONX & (1<<EPEN))    ? TRUE : FALSE)
   //! tests if STALL handshake request is running
#define Is_usb_endpoint_stall_requested()         ((UECONX & (1<<STALLRQ)) ? TRUE : FALSE)

   //! configures the current endpoint
#define Usb_configure_endpoint_type(type)         (UECFG0X =   (UECFG0X & ~(MSK_EPTYPE)) | ((U8)type << 6))
   //! configures the current endpoint direction
#define Usb_configure_endpoint_direction(dir)     (UECFG0X =   (UECFG0X & ~(1<<EPDIR))  | ((U8)dir))

   //! configures the current endpoint size
#define Usb_configure_endpoint_size(size)         (UECFG1X =   (UECFG1X & ~MSK_EPSIZE) | ((U8)size << 4))
   //! configures the current endpoint number of banks
#define Usb_configure_endpoint_bank(bank)         (UECFG1X =   (UECFG1X & ~MSK_EPBK)   | ((U8)bank << 2))
   //! allocates the current configuration in DPRAM memory
#define Usb_allocate_memory()                     (UECFG1X |=  (1<<ALLOC))
   //! un-allocates the current configuration in DPRAM memory
#define Usb_unallocate_memory()                   (UECFG1X &= ~(1<<ALLOC))

   //! acks endpoint overflow interrupt
#define Usb_ack_overflow_interrupt()              (UESTA0X &= ~(1<<OVERFI))
   //! acks endpoint underflow memory
#define Usb_ack_underflow_interrupt()             (UESTA0X &= ~(1<<UNDERFI))
   //! acks Zero Length Packet received
#define Usb_ack_zlp()                             (UESTA0X &= ~(1<<ZLPSEEN))
   //! returns data toggle
#define Usb_data_toggle()                         ((UESTA0X&MSK_DTSEQ) >> 2)
   //! returns the number of busy banks
#define Usb_nb_busy_bank()                        (UESTA0X &   MSK_NBUSYBK)
   //! tests if at least one bank is busy
#define Is_usb_one_bank_busy()                    ((UESTA0X &  MSK_NBUSYBK) == 0 ? FALSE : TRUE)
   //! tests if current endpoint is configured
#define Is_endpoint_configured()                  ((UESTA0X &  (1<<CFGOK))   ? TRUE : FALSE)
   //! tests if an overflows occurs
#define Is_usb_overflow()                         ((UESTA0X &  (1<<OVERFI))  ? TRUE : FALSE)
   //! tests if an underflow occurs
#define Is_usb_underflow()                        ((UESTA0X &  (1<<UNDERFI)) ? TRUE : FALSE)
   //! tests if a ZLP has been detected
#define Is_usb_zlp()                              ((UESTA0X &  (1<<ZLPSEEN)) ? TRUE : FALSE)

   //! returns the control direction
#define Usb_control_direction()                   ((UESTA1X &  (1<<CTRLDIR)) >> 2)
   //! returns the number of the current bank
#define Usb_current_bank()                        ( UESTA1X & MSK_CURRBK)

   //! clears FIFOCON bit
#define Usb_ack_fifocon()                         (UEINTX &= ~(1<<FIFOCON))
   //! acks NAK IN received
#define Usb_ack_nak_in()                          (UEINTX &= ~(1<<NAKINI))
   //! acks NAK OUT received
#define Usb_ack_nak_out()                         (UEINTX &= ~(1<<NAKOUTI))
   //! acks receive SETUP
#define Usb_ack_receive_setup()                   (UEINTX &= ~(1<<RXSTPI))
   //! acks reveive OUT
#define Usb_ack_receive_out()                     (UEINTX &= ~(1<<RXOUTI), Usb_ack_fifocon())
   //! acks STALL sent
#define Usb_ack_stalled()                         (MSK_STALLEDI=   0)
   //! acks IN ready
#define Usb_ack_in_ready()                        (UEINTX &= ~(1<<TXINI), Usb_ack_fifocon())
   //! Kills last bank
#define Usb_kill_last_in_bank()                   (UENTTX |= (1<<RXOUTI))
   //! tests if endpoint read allowed
#define Is_usb_read_enabled()                     (UEINTX&(1<<RWAL))
   //! tests if endpoint write allowed
#define Is_usb_write_enabled()                    (UEINTX&(1<<RWAL))
   //! tests if read allowed on control endpoint
#define Is_usb_read_control_enabled()             (UEINTX&(1<<TXINI))
   //! tests if a NAK has been sent
#define Is_usb_nak_out_sent()                     (UEINTX&(1<<NAKOUTI))
   //! tests if OUT received
#define Is_usb_receive_out()                      (UEINTX&(1<<RXOUTI))
   //! tests if IN ready
#define Is_usb_in_ready()                         (UEINTX&(1<<TXINI))
   //! sends IN
#define Usb_send_in()                             (UEINTX &= ~(1<<FIFOCON))
   //! sends IN on control endpoint
#define Usb_send_control_in()                     (UEINTX &= ~(1<<TXINI))
   //! frees OUT bank
#define Usb_free_out_bank()                       (UEINTX &= ~(1<<FIFOCON))
   //! acks OUT on control endpoint
#define Usb_ack_control_out()                     (UEINTX &= ~(1<<RXOUTI))

   //! enables flow error interrupt
#define Usb_enable_flow_error_interrupt()         (UEIENX  |=  (1<<FLERRE))
   //! enables NAK IN interrupt
#define Usb_enable_nak_in_interrupt()             (UEIENX  |=  (1<<NAKINE))
   //! enables NAK OUT interrupt
#define Usb_enable_nak_out_interrupt()            (UEIENX  |=  (1<<NAKOUTE))
   //! enables receive SETUP interrupt
#define Usb_enable_receive_setup_interrupt()      (UEIENX  |=  (1<<RXSTPE))
   //! enables receive OUT interrupt
#define Usb_enable_receive_out_interrupt()        (UEIENX  |=  (1<<RXOUTE))
   //! enables STALL sent interrupt
#define Usb_enable_stalled_interrupt()            (UEIENX  |=  (1<<STALLEDE))
   //! enables IN ready interrupt
#define Usb_enable_in_ready_interrupt()           (UEIENX  |=  (1<<TXIN))
   //! disables flow error interrupt
#define Usb_disable_flow_error_interrupt()        (UEIENX  &= ~(1<<FLERRE))
   //! disables NAK IN interrupt
#define Usb_disable_nak_in_interrupt()            (UEIENX  &= ~(1<<NAKINE))
   //! disables NAK OUT interrupt
#define Usb_disable_nak_out_interrupt()           (UEIENX  &= ~(1<<NAKOUTE))
   //! disables receive SETUP interrupt
#define Usb_disable_receive_setup_interrupt()     (UEIENX  &= ~(1<<RXSTPE))
   //! disables receive OUT interrupt
#define Usb_disable_receive_out_interrupt()       (UEIENX  &= ~(1<<RXOUTE))
   //! disables STALL sent interrupt
#define Usb_disable_stalled_interrupt()           (UEIENX  &= ~(1<<STALLEDE))
   //! disables IN ready interrupt
#define Usb_disable_in_ready_interrupt()          (UEIENX  &= ~(1<<TXIN))

   //! returns FIFO byte for current endpoint
#define Usb_read_byte()                           (UEDATX)
   //! writes byte in FIFO for current endpoint
#define Usb_write_byte(byte)                      (UEDATX  =   (U8)byte)

   //! returns number of bytes in FIFO current endpoint (16 bits)
#define Usb_byte_counter()                        ((U8)(UEBCLX))
   //! returns number of bytes in FIFO current endpoint (8 bits)
#define Usb_byte_counter_8()                      ((U8)UEBCLX)

   //! tests the general endpoint interrupt flags
#define Usb_interrupt_flags()                     (UEINT)
   //! tests the general endpoint interrupt flags
#define Is_usb_endpoint_event()                   (Usb_interrupt_flags() != 0x00)
//! @}



//! wSWAP
//! This macro swaps the U8 order in words.
//!
//! @param x        (U16) the 16 bit word to swap
//!
//! @return         (U16) the 16 bit word x with the 2 bytes swaped

#define wSWAP(x)        \
   (   (((x)>>8)&0x00FF) \
   |   (((x)<<8)&0xFF00) \
   )


//! Usb_write_word_enum_struc
//! This macro help to fill the U16 fill in USB enumeration struct.
//! Depending on the CPU architecture, the macro swap or not the nibbles
//!
//! @param x        (U16) the 16 bit word to be written
//!
//! @return         (U16) the 16 bit word written
#if !defined(BIG_ENDIAN) && !defined(LITTLE_ENDIAN)
   #error YOU MUST Define the Endian Type of target: LITTLE_ENDIAN or BIG_ENDIAN
#endif
#ifdef LITTLE_ENDIAN
   #define Usb_write_word_enum_struc(x)   (x)
#else //BIG_ENDIAN
   #define Usb_write_word_enum_struc(x)   (wSWAP(x))
#endif


//! @}

//_____ D E C L A R A T I O N ______________________________________________

U8      usb_config_ep                (U8, U8);
U8      usb_select_enpoint_interrupt (void);
U16     usb_get_nb_byte_epw          (void);
U8      usb_init_device              (void);


#endif  // _USB_DRV_H_
