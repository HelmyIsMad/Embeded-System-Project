// sketch.ino

extern "C" {
  // Declare the assembly function
  byte mainAssembly(); 
}

void setup() {
  Serial.begin(9600);
  
  // Call the assembly function
  byte result = mainAssembly();
  
  Serial.print("Result from Assembly: ");
  Serial.println(result);
}

void loop() {
  // Nothing here for now
}