// Loopback Demo - James Ashie Kotey

#include <SoftwareSerial.h>

#define MSG_LEN 6 // 5 +1 for null terminator

// setup UART to FPGA using digital pins
SoftwareSerial fpgaSerial(10, 11); // RX, TX

const char message[] = "Sharc!";
size_t count = strlen(message);  
const uint8_t STR_LEN = count;
char dataBuf[MSG_LEN]; 
uint8_t rxIndex = 0;

void setup() {
  // Initialize the Serial monitor for debugging
  Serial.begin(9600);     // Debug with Serial Monitor
  fpgaSerial.begin(9600); // Software Serial FPGA interface  
}

// test the FPGA rx
void send_to_fpga() {
 
 for (size_t i = 0; i < count; i++)
  {
    // send char to FPGA
    fpgaSerial.print(message[i]); 
    
    // debug printing 
    Serial.print("SENT: ");
    Serial.println(message[i]);

    // delay between letters in ms
    delay(1500);
  }
  
}

// Test both the tx and rx
void fpga_loopback() {
  uint8_t rxIndex = 0;

  for (size_t i = 0; i < count; i++)
  {
    // send char to FPGA
    fpgaSerial.print(message[i]);
   
    // debug 
    Serial.print("SENT: ");
    Serial.println(message[i]);
    
    delay(100);
   
    // Wait to receive a char back
    if (fpgaSerial.available()) {
      char c = fpgaSerial.read();
      dataBuf[rxIndex++] = c;
    
      if (rxIndex == count) {
        dataBuf[STR_LEN] = '\0';         // make it a C string
        rxIndex = 0;                     // reset for next packet
        // print out received string
        Serial.print("Received: ");
        Serial.println(dataBuf);
      }
    }
    
    delay(1400);
   
  }
  
}

void loop() {
  // choose a function to repeat
  fpga_loopback();
  // send_to_fpga();
}


