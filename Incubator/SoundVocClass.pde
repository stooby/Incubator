class SoundVoc {
  float x;
  float y;
  
  float interpAmt = 0.0;
  float currentOpacity = 1.00;
  int id;
  
  int maxDiam = 150; //max diameter range from origin point of sound
  int minDiam = 0;
  float currentDiam = float(minDiam);
  
  boolean soundEnd = false;
  //boolean signalStrong = false; //flag registering whether or not current input level is above minThresh
  boolean threshTrig = false; //flag registering each time input level transitions from below to above minThresh
  float minThresh = 0.05; //if input level drops below this value, min audio input level to
  
  SoundVoc (float xin, float yin, int idInput)
  {
    x = xin;
    y = yin;
    id = idInput;
  }
  
  void displayAudio(float inputLevel)
  { 
    strokeWeight(0); //RENDER CURRENT SOUND RADIUS BASED ON INPUT
    float inputColorOffset = map(inputLevel, 0.0001, 0.05, 0, 100);
    fill(0 + (inputColorOffset * 2.5), 150 - (inputColorOffset * 1.5), 0, 75 * currentOpacity);
    //massage scaling parameters...
    currentDiam = minDiam + map(inputLevel, 0.0001, 0.18, 0, maxDiam - minDiam);
    ellipse(x, y, currentDiam, currentDiam);   
  }
  
}