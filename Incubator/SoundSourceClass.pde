class SoundSource {
  float x; //current x-position
  float y; //current y-position
  //int id; //index w/in array
  int originDiam = 10;
  float currentOriginDiam = float(originDiam);
  float interpAmt = 0.0;
  float currentOpacity = 1.00;
  int id;
  
  float startTime;
  float silenceStartTime; //for storing start time of periods of quiet (when inputLevel < minThresh)
  int triggerTime = 4000; //millis after creation before start analyzing level to determine whether or not soundSource is removed
  int decayTime = 3000; //millis time it takes for soundSource to be removed after inputLevel < minThresh
  
  int maxDiam = 250; //max diameter range from origin point of sound
  int minDiam = 30;
  float currentDiam = float(minDiam);
  
  
  boolean soundEnd = false;
  boolean signalStrong = false; //flag registering whether or not current input level is above minThresh
  boolean threshTrig = false; //flag registering each time input level transitions from below to above minThresh
  float minThresh = 0.1;
  
  SoundSource (float xin, float yin)
  {
   x = xin;
   y = yin;
   startTime = millis();
   id = currentSource;
   //println(id);
  }
  
  void displayStatic() //not currently using, originally for testing
  {
    strokeWeight(2);
    stroke(0, 50, 200, 200);
    fill(50, 50, 50, 50);
    ellipse(x, y, originDiam, originDiam);
    soundRange();
  }
  
  void soundRange() //not currently using, originally for testing
  {
   strokeWeight(0);
   fill(0, 20, 150, 90);
   ellipse(x, y, maxDiam, maxDiam);
  }
  
  void displayAudio(float inputLevel)
  {
    strokeWeight(2); //RENDER INNER CIRCLE
    stroke(0, 50, 200, 200 * currentOpacity);
    fill(50, 50, 50, 50 * currentOpacity);
    ellipse(x, y, currentOriginDiam, currentOriginDiam);
    
    strokeWeight(0); //RENDER CURRENT SOUND RADIUS BASED ON INPUT
    float inputColorOffset = map(inputLevel, 0.0005, 0.5, 0, 100);
    fill(0 + (inputColorOffset * 2.5), 20 + inputColorOffset, 150 - (inputColorOffset * 1.5), 200 * currentOpacity);
    //massage scaling parameters...
    currentDiam = minDiam + map(inputLevel, 0.0005, 0.5, 0, maxDiam - minDiam);
    ellipse(x, y, currentDiam, currentDiam);
    
    if (millis() - startTime > triggerTime)
    {
      if (inputLevel >= minThresh)
      {
        signalStrong = true; //not being used for anything right now
        if (currentOriginDiam < originDiam)
        { //increase size of currentOriginDiam to originDiam
          currentOriginDiam = currentOriginDiam + 2; //crude, may need to tweak to lerp() for smoother result... 
        }
        else if (currentOriginDiam > originDiam) {currentOriginDiam = originDiam;}
        
        if (currentOpacity < 1.0) {currentOpacity = currentOpacity + 0.1;} //increase opacity quickly back to 1.0
        else if (currentOpacity > 1.0) {currentOpacity = 1.0;}
        
        if (threshTrig == true) {threshTrig = false;} //reset state transition flag (b/c a 'loud' sound event is now occuring)     
      }
      else //if (inputLevel < minThresh)
      {
        signalStrong = false; //not being used for anything right now
        if (threshTrig == false) //if we've transitioned from silence to loudness
        {
          threshTrig = true;
          silenceStartTime = millis();
          interpAmt = 0.0;
        } 
        else //if (threshTrig == true)
        {
          if (millis() - silenceStartTime > decayTime)
          {//set flag to cause removal of soundSource
            soundEnd = true;
          }
          else
          {
            //change color
            //shrink soundSource size to 0 (increment)
            currentOriginDiam = lerp(originDiam, 0, interpAmt); //interpolate originDiam from start value to 0 (incrementally shrink)
            currentOpacity = lerp(1.00, 0.00, interpAmt); //interpolate from 1.0 to 0 as interpAmt increases over time
            float currentTime = millis();
            interpAmt = map(currentTime, silenceStartTime, (silenceStartTime + decayTime), 0.00, 1.00); //increment interpAmt based on amount of millis passed since silenceStartTime    
          }
        }
      }
    }
  }
  
  /*
  void displayAudio(float inputLevel)
  {
    strokeWeight(2); //RENDER INNER CIRCLE
    stroke(0, 50, 200, 200);
    fill(50, 50, 50, 50);
    ellipse(x, y, originDiam, originDiam);
    
    strokeWeight(0); //RENDER CURRENT SOUND RADIUS BASED ON INPUT
    float inputColorOffset = map(inputLevel, 0.0005, 0.5, 0, 100);
    fill(0 + (inputColorOffset * 2.5), 20 + inputColorOffset, 150 - (inputColorOffset * 1.5), 90);
    //massage scaling parameters...
    currentDiam = minDiam + map(inputLevel, 0.0005, 0.5, 0, maxDiam - minDiam);
    ellipse(x, y, currentDiam, currentDiam);
  }*/
  
  
}