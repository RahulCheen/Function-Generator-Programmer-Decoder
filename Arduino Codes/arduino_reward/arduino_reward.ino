#include <Servo.h>
const int MANUAL    = 23;     // manual reward button pin
const int SOLENOID  = 53;     // output to solenoid transistor switch
const int TOGGLE    = 37;     // Toggle between manual and automatic states

const int rewardDuration  = 500;    // duration of reward, length of time solenoid is on
const int rewardPost      = 1000;   // time to pause after reward, so that no reward is given

const int servoPin = 9;
 
Servo servoCont; 
volatile int buttonOn = LOW;
void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  servoCont.attach(servoPin);
  pinMode(      SOLENOID, OUTPUT);
  digitalWrite( SOLENOID, LOW);

  pinMode(      MANUAL, INPUT);

  pinMode(      TOGGLE, INPUT);
}

void loop() {
  int rewardDelivery = digitalRead(TOGGLE);
  switch (rewardDelivery) {

    //////////////// MANUAL REWARD ////////////////
    case HIGH:
      buttonOn = digitalRead(MANUAL);
      if (buttonOn == HIGH) {
        digitalWrite(SOLENOID, HIGH);
        delay(rewardDuration);
        digitalWrite(SOLENOID, LOW);
        delay(rewardPost);

      } else {
        digitalWrite(SOLENOID, LOW);
      }

      break;

    ////////////// AUTOMATIC REWARD //////////////
    case LOW:

      if (Serial.available() > 0) { // look for serial input

        digitalWrite(SOLENOID, HIGH);
        delay(rewardDuration);
        digitalWrite(SOLENOID, LOW);
        delay(rewardPost);

      } else {
        digitalWrite(SOLENOID, LOW);
      }

      break;

    default:
      break;
  }

}
