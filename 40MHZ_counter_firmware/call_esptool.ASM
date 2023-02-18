;;https://board.flatassembler.net/post.php?mode=quote&p=118263


;; xiaolaba, 2015-SEP-16
;; call esptool.exe to burn esp8266/ESP-01 (extensa CPU), https://github.com/igrr/esptool-ck
;; 2017-SEP-02, change to esptool_3.exe burn esp32 (extensa CPU)
;; 2022-DEC-22, try esptool_4.2.1.exe, eps32-c3 (riscv CPU)


include 'win32ax.inc'


section '.data' data readable writeable
esptool:
        db 'esptool_4.2.1.exe',0
parameter:
;        db ' --chip 8285'
;        db ' --chip 8266'
;        db ' --chip esp32c3'
        db ' --chip esp32'
        db ' --port '
com_port:
        db 'COM01234'   ;8 byte, repalce by user input parameter
        db ' --baud 921600'
erase_flash:
        db ' erase_flash',0x0 ; 13 bytes, erase chip first, then rip with SPACE, call esotool again to burn chip
        db ' --before default_reset' ; esp32 https://docs.espressif.com/projects/esptool/en/latest/esp32/esptool/flashing-firmware.html
;        db ' --before no_reset_no_sync'
;        db ' --before no_reset'
;        db ' --before --before usb_reset'  ; esp32-c3, built in USB/JTAG, https://docs.espressif.com/projects/esptool/en/latest/esp32c3/esptool/advanced-options.html
        db ' --after hard_reset write_flash -z'
        db ' --flash_mode dio'
        db ' --flash_freq 80m'
        db ' --flash_size detect'
        db ' 0x0'
        db ' ESP32_40MHZ_counter_esp32_merged-flash.bin'
        db 0x0

hCOM    dd -1

section '.code' code readable writeable executable

start:
        ;invoke MessageBox, NULL,  com_port, 'default COM port setting',MB_OK

        invoke GetCommandLine
        mov ebx, eax

OmitName:
        cmp byte [ebx], 0
        je  try_open_com_port ; no parameter, no COM port specified, must be error, then exit

        cmp byte [ebx], ' '
        je  OmitSpaces

        inc ebx
        jmp OmitName
            
OmitSpaces:
        inc ebx
        cmp byte [ebx], ' '
        je  OmitSpaces


; command line parameter 'COM#', validate COM port number
try_open_com_port:
        ;invoke  CreateFile, "COM1", GENERIC_READ or GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL
        invoke  CreateFile, ebx, GENERIC_READ or GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL

        mov     [hCOM], eax
        cmp     eax, -1
        jne     @f

        invoke  MessageBox, 0, "Error, Can't open your COM port", ebx, 0
        jmp     exit
@@:
        invoke MessageBox, NULL, 'COM port available to burn chip', ebx, MB_OK
        invoke CloseHandle, [hCOM]



init_com_port_string:
        mov eax, '    '
        mov [com_port], eax
        mov eax, '    '
        mov [com_port+4], eax


copy_user_com_port_string:
        mov eax, [ebx]
        mov [com_port], eax

display_user_com_port_string:
        ;invoke MessageBox, NULL, com_port, 'user specified COM port', MB_OK


erase_chip_first:
        invoke ShellExecute, NULL, 'open', esptool, parameter, NULL, SW_NORMAL

clear_erase_option:
        mov al,' '
        mov ebx, erase_flash
@@:
        mov [ebx], al
        inc ebx
        cmp byte [ebx], 0
        jne @b
replace_0x0:
        mov [ebx], al

        ;invoke MessageBox, NULL, parameter, 'user specified COM port', MB_OK
        invoke MessageBox, NULL, 'chip erased, burn firmware', 'by xiaolaba', MB_OK


burn_chip:
        invoke ShellExecute, NULL, 'open', esptool, parameter, NULL, SW_NORMAL

exit:

        invoke ExitProcess, NULL



.end start