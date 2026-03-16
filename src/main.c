extern "C" {
  void mainAssembly();
  
  char serial_read() {
    while (Serial.available() == 0);
    char c = Serial.read();
    return c;
  }

  void serial_write(char c) {
    Serial.write(c);
  }
}

void setup() {
  Serial.begin(115200);
  mainAssembly();
}

void loop() {}