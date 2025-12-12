// Transmit to FPGA Uart Demo - James Ashie Kotey

void setup() {
   // Initialize the Serial monitor for debugging
  Serial.begin(9600);   
}

void loop() {
  // send characters 's', 'h', 'a', 'r', 'c' with 1500ms second delays
  const char message[] = "sharc";
  size_t count = strlen(message);  

  for (size_t i = 0; i < count; i++)
  {
    Serial.print(message[i]);
    delay(1500);
  }
  
  // End of loop
}
