@ @c
#include "config.h"
#include "lib_mcu/usb/usb_drv.h"
#include "usb_descriptors.h"

#include "uart_usb_lib.h"

Uchar rx_counter; /* FIXME: do |rx_counter=0;| on initializing usb uart */

/** 
  * @brief This function checks if a character has been received on the USB bus.
  * 
  * @return bit (true if a byte is ready to be read)
  */
bit uart_usb_test_hit(void)
{
  if (!rx_counter)
  {
    Usb_select_endpoint(RX_EP);
    if (Is_usb_receive_out())
    {
      rx_counter = Usb_byte_counter();
      if (!rx_counter)
      {
        Usb_ack_receive_out();
      }
    }
  }
  return (rx_counter!=0);
}
