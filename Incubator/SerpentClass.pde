class Serpent {
  AudioOutput out;
  Sampler sampler;
  ADSR adsr;
  Pan pan;
  Constant sampleStart;
  Constant sampleStop;
  Constant sampleAttack;
  Constant sampleRate;
  Constant sampleAmp;
  
  float red = 255;
  float green = 255;
  float blue = 255;
  int colorInc = 5; //incrementer for color values
  
  int selfID;
  int segments = 3;
  int segLength = 18;
  float xPos, yPos; //current x and y-position of "head" segment origin point
  float angleHead; //current vector angle of "head" segment origin point
  float[] x = new float[segments]; //array storing xpos of each segment (1 segment per array index)
  float[] y = new float[segments]; //array storing ypos of each segment
  int senseDia = 86; //sensory range (diameter) extending from "head" segment origin point
  int senseGoalDist = 30; //desired distance from soundSource (serpent's goal)
  
  float easing = 0.02; //number between 0.0 and 1.0
  float vel = 1.5; //speed (pixels incremented each time we run through the loop)
  
  float destX, destY; //destination X (movement target goal)
  float dist, distX, distY;  
  float startX, startY; //a.k.a. prevDestX
  boolean destReached = true; //for keeping track of mvmt ("have I reached my destination?")
  
  //boolean hearSound = false; //not actively used...
  boolean hearSameSound = false;
  boolean foundSound = false;
  //boolean idleState = false;
  int soundTarget; //stores array index of last heard soundSource for lookup purposes
  
  boolean pauseState = false; 
  float pauseStartTime;
  int pauseDuration = 300; //millis duration to pause and wait to confirm hearing sound
  
  boolean listenState = false;
  float listenStartTime;
  float soundStopTime;
  int listenTimePatienceThresh = 1500; //millis
  
  float recStartTime;
  float recStopTime;
  float sampleStartTime;
  float sampleStopTime;
  int sampleStartNum;
  int sampleStopNum;
  float sampleAmpVal = 0.35;
  //float sampleAttackTime = 0.02; //in seconds, only for use when passing to Sampler amplitude FIELD //<--prev
  float sampleAttackTime = 30; //millis
  float sampleReleaseTime = 100; //millis
  int sampleDuration; //duration of sample to be vocalized in millis
  boolean parametersChanged = false;
  
  float sampleRateMax = 3.0;
  float sampleRateMin = 0.4;
  float currentSampleRate;
  boolean triggerRelease = false;
  
  int recMaxTimeUpperLimit = 3000; //millis
  int recMaxTimeLowerLimit = 500; //millis
  int recMaxTime;
  
  int soundID;
  int lastVocSoundID; //to keep track of most recent sample used when vocalizing
  int recSoundID;
  
  boolean haveSound = false; //flag indicating whether serpent has recorded a sound
  boolean hearingNewSound = false; //flag to keep track of recording start/stop process
  boolean recState = false;
  boolean firstAtSound = false;
  boolean arrivedAtSound = false; //flag to keep track of arrival at separate soundSource events
  
  int origSerpentAtSound; //stores Serpent[] index value for determining which audio recording to sample
  
  boolean vocState = false;
  boolean vocNow = false;
  boolean createSampler = false; //flag keeping track of creation of Sampler
  float vocStartTime;
  float vocStopTime = 0;
  int minTimeBetweenVoc = 700;
  int maxTimeBetweenVoc = 5000;
  int timeBetweenVoc = int(random(minTimeBetweenVoc, maxTimeBetweenVoc));
  int soundVocIndex; //used to store arrayList index of soundVoc objects - for visualizing vocalization...not fully implemented yet...
  float currentLevel; //stores current RMS value of serpent output bus

  boolean hearSerpentVoc = false;
  boolean influenced = false;
  float influencedTime; //millis of last time influenced by other serpent vocalization...
  float hearSerpentStartTime;
  int minTimeToBeInfluenced = 500; //not using right now, debating between this and current method of determining influenced based on percentage of vocalizing serpent's sampleDur
  //float hearSerpentStopTime;
  int minTimeBetweenInfluence = 1000; //minimum amount of millis before serpent becomes influenceable again after being influenced by other serpent vocalization
  int lastSerpentHeard; //counter keeping track of array index value of last serpent heard
  
//boolean stopVocDisplay = false;
//float playBackOffset
//float ampOffset
//BPF cutoff freq?

//float activeSoundX;
//float activeSoundY;

  Serpent(int numSegments, int lengthSegment, float xin, float yin) //Constructor
  {
    segments = numSegments;
    segLength = lengthSegment;
    xPos = xin;
    yPos = yin;
    selfID = serpentNum;
    currentSampleRate = 1.0;
    //println(selfID);
    recMaxTime = int(random(recMaxTimeLowerLimit, recMaxTimeUpperLimit)); //initialize w/ a random-sized recording buffer duration
    out = minim.getLineOut(Minim.STEREO);
    pan = new Pan(0);
  }
  
  void sense()
  {
    if (listenState == false && vocState == false)
    {//if not actively listening to a sound, sense soundSources
      if (sources.size() > 0) //only execute enclosed code if there is any active sound source in SoundSource array list... (for efficiency and to eliminate some bugs)
      {
        /* in progress code section for more hesistant / natural response to intermittent sound stimuli
        if (hearSound == true) //if just heard a sound, but not actively travelling towards it
        {
          if (millis() - pauseStartTime > listenTimePatienceThresh) //wait for a little bit (as if serpent's triangulating precise soundSource location)
          {
            if (sources.contains(soundTarget)) //not working the way I expected...
            {//if the soundSource last heard still exists, change serpent state
              foundSound = true;
              hearSound = false;  //redundant state flag...?
              pauseState = false; 
            }
            else
            {//if the soundSource last heard no longer exists, reset flags and revert to standard sensing state
              hearSound = false; //redundant state flag...?
              pauseState = false;
            }
          }
        }*/
        
        if (foundSound == true) //if verified continuous soundSource, travel towards it
        {
          float distSource = dist(xPos, yPos, destX, destY); //measure distance between serpent head and targeted soundSource center
          if (distSource <= senseGoalDist) //if w/in optimal listening range, stop moving & start listening
          {
            foundSound = false; //reset this flag before serpent enters the "listening" state (in prep for future soundSource location events)
            listen();
          }
        }
        
        else //if no sound heard or found, sense (listen for) sounds
        {
          for (int i = 0; i < sources.size(); i++)
          { 
            SoundSource aSource = sources.get(i); //get position values of all existing soundSource objects
            float distSource = dist(xPos, yPos, aSource.x, aSource.y); //measure distance between serpent head and soundSource center
            
            if (distSource - (senseDia/2) - (aSource.currentDiam/2) < 0) //if sensory range overlaps w/ soundSource broadcast range
            {
              //hearSound = true;
              //pauseState = true; //pause motion (slow down)
              //pauseStartTime = millis();
              foundSound = true;
              destX = aSource.x; //set soundSource location as new destination
              destY = aSource.y; 
              soundTarget = i; //log soundSource object array index    
            }
          }
        }
      }
      else //if no (0) soundSource objects exist...
      { //reset various state flags (to eliminate buggy behavior)
        //if (pauseState == true) {//wait until pause time dur runs out then resume roaming}
        //if (foundSound == true) {//finish navigating to last known position of sound, wait for patienceDur then reset all flags and resume roaming}
        //pauseState = false;
        //hearSound = false;
        foundSound = false;
      }
      
      if (foundSound == false && serpentNum > 0) //<------------detect other serpent vocalizations
      {
        if (influenced == true) //creating a short buffer of time in which serpent can't be influenced after having recently been influenced
        {
          if (millis() - influencedTime > minTimeBetweenInfluence)
          {
            hearSerpentVoc = false;
            influenced = false;
          } //reset influenced flag to permit future influencing after minTimeBetweenInfluence has passed
        }
        
        if (hearSerpentVoc == false && influenced == false)
        {
          for (int i = 0; i <= serpentNum; i++) {
            if (i != selfID) //to avoid evaluating ourself and considering it as another serpent object
            { 
              float distSerp = dist(xPos, yPos, serpents[i].xPos, serpents[i].yPos); //measure distance between this serpent's head and other serpent head
              if (distSerp - (senseDia/2) - (serpents[i].senseDia/2) < 0) //if sensory range overlaps w/ other serpentVoc broadcast range
              {
                if (serpents[i].vocState == true) //AND if the proximal serpent is vocalizing
                { 
                  hearSerpentVoc = true; //then we've heard a serpent
                  hearSerpentStartTime = millis();
                  lastSerpentHeard = serpents[i].selfID; //remember the id of the vocalizing serpent
                  break;
                }
              }
            }          
          }
        }
        else if (hearSerpentVoc == true && influenced == false)
        {
          float distSerp = dist(xPos, yPos, serpents[lastSerpentHeard].xPos, serpents[lastSerpentHeard].yPos); //measure distance between this serpent's head and head of most recent serpent heard
          if (distSerp - (senseDia/2) - (serpents[lastSerpentHeard].senseDia/2) < 0) //if sensory range STILL overlaps w/ previously heard serpentVoc broadcast range
          {
            if (millis() - hearSerpentStartTime >= serpents[lastSerpentHeard].sampleDuration * 0.8) //if this serpent's been proximal to vocalizing serpent for more than 80% of vocalizing serpent's total vocalization period (aka sampleDuration)
            {
              if (haveSound == false)
              { //if haven't recorded/heard any sounds before, assume the exact same sample as lastSerpentHeard
                haveSound = true;
                recSoundID = serpents[lastSerpentHeard].recSoundID;
                sampleStartNum = serpents[lastSerpentHeard].sampleStartNum;
                sampleStopNum = serpents[lastSerpentHeard].sampleStopNum;
                currentSampleRate = serpents[lastSerpentHeard].currentSampleRate;
                influenced = true;
                influencedTime = millis();
              }
              else //if already haveSound
              {
                int randNum = int(random(0, 100));
                if (randNum >= 50)
                {
                  if (serpents[lastSerpentHeard].currentSampleRate > currentSampleRate) //increment this serpent's currentSampleRate towards that of the vocalizing serpent
                  {  
                    currentSampleRate += 0.4; //increment but don't overshoot
                    if (currentSampleRate > serpents[lastSerpentHeard].currentSampleRate) {currentSampleRate = serpents[lastSerpentHeard].currentSampleRate;}
                  }
                  else if (serpents[lastSerpentHeard].currentSampleRate < currentSampleRate)
                  {
                    currentSampleRate -= 0.4; //increment but don't overshoot
                    if (currentSampleRate < serpents[lastSerpentHeard].currentSampleRate) {currentSampleRate = serpents[lastSerpentHeard].currentSampleRate;}
                  }
                  influenced = true;
                  influencedTime = millis();
                }
                else if (randNum <= 10)
                {
                  recSoundID = serpents[lastSerpentHeard].recSoundID;
                  sampleStartNum = serpents[lastSerpentHeard].sampleStartNum;
                  sampleStopNum = serpents[lastSerpentHeard].sampleStopNum;
                  currentSampleRate = serpents[lastSerpentHeard].currentSampleRate;
                  parametersChanged = true;
                  influenced = true;
                  influencedTime = millis();
                }
              }
            }
          }
          else
          {
            hearSerpentVoc = false;
          }
        }
      }
      //<--------------------
    }
    
    else if (listenState == true) //this may be necessary w/ vocState in the mix    //if listenState == true (when actively listening/hearing to previously discovered soundSource)
    {
      if (hearSameSound == true) //if soundSource was still active as of previous cycle through loop, check to make sure it's still active and continue listening and recording
      {
        if (sources.size() > 0) //if there's at least one active soundSource (safe driving so we don't try and get from an empty array list and crash)
        {
          for (int i = 0; i < sources.size(); i++) //??????is this the safest/only way to avoid risk of reading from recently removed address in array list? no faster way?
          { 
            SoundSource aSource = sources.get(i);
            float sourceX = aSource.x;
            float sourceY = aSource.y;
            float distSource = dist(xPos, yPos, aSource.x, aSource.y); //measure distance between serpent head and soundSource center
            
            if (distSource < senseGoalDist) //if still situated w/in optimal listening range, continue listening...
            {
              hearSameSound = true;
              soundID = aSource.id; //get and remember soundSource ID
              
              if (arrivedAtSound == false)
              {
                //check to see if first to sound (see if other serpents are already listening to sound and what their states are)
                if (serpentNum > 0) //is it feasible to redesign this so it's less omniscient? how would a serpent really know if it's the only one in existence or not?
                {
                  for (i = 0; i <= serpentNum; i++) {
                    if (i != selfID) //to avoid evaluating ourself and considering it as another serpent object
                    { 
                      if (serpents[i].soundID == soundID && serpents[i].firstAtSound == true /* && serpents[i].listenState == true */) //consider changing to detect if first at soundSource based on sensory range feedback instead...
                      {
                        firstAtSound = false;
                        origSerpentAtSound = i; //remember Serpent[] index value of original serpent at soundSource
                        break; //break out of for loop once we've determined we're not the first serpent at soundSource
                      } 
                      else {firstAtSound = true; origSerpentAtSound = selfID;} //if no other serpent is listening to sound, this serpent must be first at sound   
                    }    
                  }
                }
                else {firstAtSound = true; origSerpentAtSound = selfID;} //if only 1 serpent exists, default firstAtSound = true
                arrivedAtSound = true;
              }
              else //if (arrivedAtSound == true)
              {
                if (firstAtSound == true)
                {
                  //record for duration of soundSource life... 
                  if (recState == false && hearingNewSound == false) //if not recording, start recording audio input
                  {
                    //hearingNewSound = true; //could put this inside monitorSampleStart(), but leaving here for now...
                    recSoundID = soundCount; //get soundCount val for naming recorded audio file and allowing other serpents to select correct audio file when sampling
                    recSampleStart();
                    soundCount++; //advance soundCount for keeping track of audio file names...consider encapsulating  w/in recSampleStart();
                  }
                  //else if (recState == true)
                  else if (hearingNewSound == true)
                  { //set sampleStopTime while recording
                    if (millis() - recStartTime > recMaxTime) { //if been recording longer than recMaxTime, set sampleStopTime to recMaxTime
                      sampleStopTime = recMaxTime; //<----kind of weird way of doing things...sampleStartTime will always increment higher, but this will never exceed recMaxTime.........
                      //sampleStopNum = int( (recMaxTime/1000) * in.sampleRate() );
                      sampleStopNum = int( (sampleStopTime/1000) * in.sampleRate() );
                      recState = false; //!!!!!!even though still technically recording at this point, changing this flag to trigger appropriate "recState" to "haveSound" visual cue
                    }
                    else {
                      sampleStopTime = millis() - recStartTime;
                      sampleStopNum = int( (sampleStopTime/1000) * in.sampleRate() );
                    } //else set sampleStopTime to current time distance after sampleStartTime
                  }
                }
                else //if (firstAtSound == false)
                {//don't record a new audio file, log time index points for Sampler begin() and end() values
                  if (recState == false && hearingNewSound == false) {
                    //calculate sampler in value...
                    //recState = true;
                    //recStartTime = millis();
                    //sampleStartTime = millis() - serpents[origSerpentAtSound].recStartTime; //calculate sample start/in times
                    //hearingNewSound = true; //could put this inside monitorSampleStart(), but leaving here for now...
                    monitorSampleStart(); //!!!DOUBLE CHECK THIS FUNCTION IF THINGS BE BUGGY!!!
                    recSoundID = serpents[origSerpentAtSound].recSoundID; //<--------to sample correct audio file...
                  }
                  else if (hearingNewSound == true) {
                    if (millis() - recStartTime > recMaxTime)
                    {
                      //recState = false;
                      //recStopTime = millis();
                      //sampleStopTime = millis() - serpents[origSerpentAtSound].recStartTime; //calculate sample end/out times
                      //monitorSampleStop(); //!!!DOUBLE CHECK THIS FUNCTION IF THINGS BE BUGGY!!!
                      
                      sampleStopTime = sampleStartTime + recMaxTime; //<----kind of weird way of doing things...sampleStartTime will always increment higher, but this will never exceed recMaxTime.........
                      //sampleStopNum = int( (recMaxTime/1000) * in.sampleRate() );
                      sampleStopNum = int( (sampleStopTime/1000) * in.sampleRate() );
                      recState = false;
                    }
                    else {
                      sampleStopTime = millis() - sampleStartTime;
                      sampleStopNum = int( (sampleStopTime/1000) * in.sampleRate() );
                    }
                  }
                }
              }
              break; //break out of the for loop b/c we've located immediate soundSource already
            }
            else //if soundSource has disappeared or stopped sounding, log the time the sound stopped
            {
              soundStopTime = millis();
              //hearSound = false;
              hearSameSound = false;         
              if (/*recState == true &&*/ firstAtSound == true && hearingNewSound == true) {recSampleStop();}
              else if (/*recState == true &&*/ firstAtSound == false && hearingNewSound == true) {monitorSampleStop();} //DOUBLE CHECK THIS FUNCTION IF THINGS BE BUGGY!!!
            }
          }
        }
        else //likewise, if there's 0 active soundSources, log the time of cessation of sound
        {       
          soundStopTime = millis();
          //hearSound = false;
          hearSameSound = false;
          if (/*recState == true &&*/ firstAtSound == true && hearingNewSound == true) {recSampleStop();}
          else if (/*recState == true &&*/ firstAtSound == false && hearingNewSound == true) {monitorSampleStop();} //DOUBLE CHECK THIS FUNCTION IF THINGS BE BUGGY!!!
        }
      }
      
      else //if have recently stopped hearing same soundSource (hearSameSound == false)
      {//measure timespan since sound stopped, if greater than patience threshold stop listening and resume search for new sounds...
        if (millis() - soundStopTime > listenTimePatienceThresh)
        {
          listenState = false;
          hearingNewSound = false;
          arrivedAtSound = false;
          firstAtSound = false;
          //!!!soundMemBufFil = false;
          //hearSound = false;
        }
      }   
    }
  }
  
  void listen()
  {
    listenState = true;
    listenStartTime = millis();
    hearSameSound = true;
    destX = xPos;
    destY = yPos;
  }
  
  /*
  void pauseToConfirmSound(float pauseDuration) //old code, not using anymore
  {
    if (pauseState == false)
    {
      pauseState = true;
      pauseStartTime = millis();
      //destX = xPos; //stop and wait in place
      //destY = yPos;
    }
    else
    {
     if (millis() - pauseStartTime > pauseDuration)
     {//after waiting for short time, confirm hearing sound
       hearSound = true;
       pauseState = false;
     }
    }
  }*/
  
  void recSampleStart()
  {
    //recorder = minim.createRecorder(in, "sound_" + soundID + ".wav"); //<----very economical in terms of overwriting sound files, but realistically would cause massive issues if other serpents sampling from previously recorded audio w/ same filename...
    recorder = minim.createRecorder(in, "sound_" + soundCount + ".wav");
    recorder.beginRecord();
    recStartTime = millis();
    sampleStartNum = 0;
    hearingNewSound = true;
    recState = true;
    if (haveSound == false) {haveSound = true;}
  }
  
  void monitorSampleStart() //like recSampleStart() except doesn't create a new audio file (used when firstAtSound == false)
  { //DOUBLE-CHECK
    recStartTime = millis();
    sampleStartTime = millis() - serpents[origSerpentAtSound].recStartTime; //calculate sample start/in times
    sampleStartNum = int( (sampleStartTime/1000) * in.sampleRate() ); //convert sampleStartTime to audio sample num value
    hearingNewSound = true;
    recState = true;
    if (haveSound == false) {haveSound = true;}
    //recSoundID = soundID; //may be necessary vs. plain soundID for sampling correct audio file?
  }
  
  void recSampleStop()
  {
    recorder.endRecord();
    recorder.save();
    recStopTime = millis(); //not being used for anything now...
    //sampleStopTime = millis() - recStartTime;
    recState = false; //not totally necessary anymore since switching this flag to false w/in sense() method above...
  }
  
  void monitorSampleStop() //like recSampleStop() except doesn't save an audio file (used when firstAtSound == false)
  { //DOUBLE-CHECK
    recStopTime = millis(); //not being used for anything now...
    //sampleStopTime = millis() - serpents[origSerpentAtSound].recStartTime; //calculate sample end/out time
    //sampleStopNum = int( (sampleStopTime/1000) * in.sampleRate() );
    recState = false;
  }
  
  void patchSamplerFields()
  {
    //set sampler parameters (in, out, rate);
    sampleStart = new Constant(sampleStartNum);
    sampleStart.patch(sampler.begin);
    
    sampleStop = new Constant(sampleStopNum);
    sampleStop.patch(sampler.end);
    
    //sampleAttack = new Constant(sampleAttackTime); //<--prev
    //sampleAttack.patch(sampler.attack); //<--prev
    
    sampleRate = new Constant(currentSampleRate);
    sampleRate.patch(sampler.rate);
    
    //sampleAmp = new Constant(sampleAmpVal); //<--prev
    //sampleAmp.patch(sampler.amplitude); //<--prev
  }
  
  void unpatchSamplerFields()
  {
    sampleStart.unpatch(sampler);
    sampleStop.unpatch(sampler);
    //sampleAttack.unpatch(sampler); //<--prev
    sampleRate.unpatch(sampler);
    //sampleAmp.unpatch(sampler); //<--prev
  }
  
  void debugPrint1()
  {
  //println(minute()+":"+second()+"."+(millis()%1000) + " serp_" + selfID + " origSrpnt@snd=" + origSerpentAtSound + " recSndID=" + recSoundID + " smpStrt#=" + sampleStartNum + " smpStp#=" + sampleStopNum +
          //" smpStrtTim=" + sampleStartTime + " smpStpTim=" + sampleStopTime + /*" lastVocID=" + lastVocSoundID +*/ " vocState=" + vocState + " vocNow=" + vocNow + /*" crtSmplr=" + createSampler +*/ " timeBtwnVoc=" + timeBetweenVoc); 
    //println("sampDur=" + sampleDuration + " recMaxTime=" + recMaxTime + " rate=" + currentSampleRate);
  }
  
  void vocalize()
  {
    if (haveSound == true && vocState == false)
    { 
      if (listenState == false && recState == false && foundSound == false)
      {
        if (millis() - vocStopTime > timeBetweenVoc)
        {
          float num = random(100);
          if (num >= 50) //if true, vocalize
          {
            vocState = true;
            if (createSampler == false) //flag for keeping track of first construction of Sampler object after serpent object's creation
            {
              sampler = new Sampler("sound_" + recSoundID + ".wav", 1, minim); //create new sampler
              adsr = new ADSR(sampleAmpVal, sampleAttackTime/1000, 0.05, 1.0, sampleReleaseTime/1000); //create adsr envelope
              lastVocSoundID = recSoundID;
              createSampler = true;
              
              patchSamplerFields(); //set sampler parameters (in, out, rate);
              //BPF = new BPF(freqCutoff, Q);
              //sampler.patch(BPF).patch(pan);???????
              //sampler.patch(pan); //<--prev
              sampler.patch(adsr);
              adsr.patch(pan);
              pan.patch(out);
            }
            else if (createSampler == true && recSoundID != lastVocSoundID)
            {
              //sampler.unpatch(pan); //<--prev
              sampler.unpatch(adsr); //unpatch previous sampler
              unpatchSamplerFields();
              sampler = new Sampler("sound_" + recSoundID + ".wav", 1, minim); //create new sampler sampling from updated source file
              //adsr = new ADSR(0.5, sampleAttackTime, 0.05, 0.5, 0.2);
              
              patchSamplerFields(); //set sampler parameters (in, out, rate);
              //BPF = new BPF(freqCutoff, Q);
              //sampler.patch(BPF).patch(pan);???????
              
              //sampler.patch(pan); //<--prev
              sampler.patch(adsr); //connect new sampler to adsr
              //lastVocSoundID = soundID; //any significant difference of this vs below?
              lastVocSoundID = recSoundID;
            }
            else if (createSampler == true && recSoundID == lastVocSoundID && parametersChanged == true)
            {
              //sampler.unpatch(adsr); //unpatch previous sampler
              unpatchSamplerFields();
              patchSamplerFields(); //update sampler w/ latest field parameter values
              parametersChanged = false; //reset this flag to avoid continually unpatching and repatching samplerFields unnecessarily
            }
            
            float panVal = map(xPos, 0, width, -1, 1); //interpolate pan position value based on horizontal (x-axis) position
            pan.setPan(panVal); //set pan value
            timeBetweenVoc = int(random(minTimeBetweenVoc, maxTimeBetweenVoc) ); //randomly select an amount of time to wait before determining whether to vocalize again  
          }
          else {
            vocStopTime = millis();
            timeBetweenVoc = int(random(minTimeBetweenVoc, maxTimeBetweenVoc) ); //randomly select an amount of time to wait before determining whether to vocalize again
          }
          
          debugPrint1(); //for debugging
          
          /* //first sketch
          //if (hearSerpent == true) <--------
          //{
              //int num = int(random(100));
              //if (num > 50) {
              //trigger Sampler of recorded audio sample
              //vocState = true;
              //}
          //}
          //else <---------
          //{
            //int num = int(random(100));
            //if (num > 80) {//trigger Sampler of recorded audio sample}
            //vocState = true;
            //}
          //}
          */
        }
      }
    }
    else if (haveSound == true && vocState == true)
    {
      if (vocNow == false)
      {
        if (currentSampleRate > 1) { //scale sampleDuration shorter if currentSampleRate > 1
          sampleDuration = round( (( (sampleStopNum - sampleStartNum) / in.sampleRate() ) * 1000) / currentSampleRate ); 
        } 
        else { //if currentSampleRate <= 1.0, vocalize for full duration of original sampling period
          sampleDuration = round( ( (sampleStopNum - sampleStartNum) / in.sampleRate() ) * 1000 ); 
        }
        sampler.trigger();
        adsr.noteOn();
        vocStartTime = millis();
        
        vocNow = true;
        debugPrint1(); //for debugging
        println("serp_" + selfID + " sampRate=" + currentSampleRate);
        //vocs.add(new SoundVoc(xPos, yPos, selfID)); //create a new soundVoc object to visualize vocalization
        //SoundVoc voc = vocs.get(currentVoc);
        //soundVocIndex = currentVoc; //for addressing correct index in array list
        //currentVoc++;
      }
      else //if (vocNow == true)
      {
        //int sampleDuration = round( (( (sampleStopNum - sampleStartNum) / in.sampleRate() ) * 1000) / currentSampleRate );
        //if ( millis() - vocStartTime >= ( ((sampleStopNum - sampleStartNum) / in.sampleRate()) * 1000) - (sampleReleaseTime + 20) )
        if ( millis() - vocStartTime >= sampleDuration - (sampleReleaseTime + 20) )
        { //TRIGGER RELEASE (to avoid pops and clicks @ end of sample): if it's 'sampleReleaseTime' millis BEFORE end of sample, start release
          if (triggerRelease == false)
          {
            adsr.noteOff();
            triggerRelease = true;
          }
        }
        //if (millis() - vocStartTime > ( (sampleStopNum - sampleStartNum) / in.sampleRate() ) * 1000) /*sampleStopTime - sampleStartTime*/ /*mult by playback rate too... */ 
        if ( millis() - vocStartTime >= sampleDuration )
        {//end vocState as soon as time elapsed since vocStartTime > length of sample
          //stopVocDisplay = true;
          vocStopTime = millis();
          vocNow = false;
          vocState = false;
          triggerRelease = false;
          
          mutate_selfRand(33); //specified probability that Sampler field parameter values will randomly change(mutate) slightly 
          
          debugPrint1(); //for debugging
          
          //vocs.remove(soundVocIndex); //remove soundVoc object once vocalization complete
          //currentVoc--;
        }
      }  
    }
  }
  
  void mutate_selfRand(int probabilityPercent) //function determines whether or not sampler parameter values will change(mutate) slightly
  {
    int randNum = int(random(0, 100)); 
    if (randNum < probabilityPercent)
    {
      //mutate sampler parameters
      int randNumRate = int(random(0, 2));
      if (randNumRate == 1) //increment currentSampleRate
      {
        currentSampleRate += 0.2;
        if (currentSampleRate > sampleRateMax) {currentSampleRate = sampleRateMax;} //safe driving
      }
      else //decrement currentSampleRate
      {
        currentSampleRate -= 0.2;
        if (currentSampleRate < sampleRateMin) {currentSampleRate = sampleRateMin;} //safe driving
      }
      
      int randNumDur = int(random(0, 3));
      if (randNumDur == 2)
      { //increase recMaxTime duration by 1/4 of a second
        recMaxTime += 250; 
        if (recMaxTime > recMaxTimeUpperLimit) {recMaxTime = recMaxTimeUpperLimit;} //safe driving
      }
      else if (randNumDur == 1)
      { //decrease recMaxTime duration by 1/4 of a second
        recMaxTime -= 250; 
        if (recMaxTime < recMaxTimeLowerLimit) {recMaxTime = recMaxTimeLowerLimit;} //safe driving
      }
      //else if randNumDur == 0, recMaxTime stays the same
      parametersChanged = true; //set this flag so the Sampler fields will be updated w/ the newest parameter values
    }
  }
  
  void plotMotion()
  {
    if (listenState == false /*&& pauseState == false*/) //if not actively listening to or for sound, plot motion path to destination
    {
      if (destReached == true)
      {
        startX = xPos;
        startY = yPos;
       //orig random destination target point generation
        destX = random(margin, (width-margin));
        destY = random(margin, (height-margin));
      
        //dist = dist(startX, startY, destX, destY);
        //distX = abs(startX - destX);
        //distY = abs(startY - destY);
        
        /* //new navigation plotting scheme...IN PROGRESS...
        prevDestX = xPos;
        prevDestY = yPos;
      
        int mX = int(random(0, 2)); //50% chance addition or subtraction in displacement from current X and Y pos occurs to set new dest X and Y...
        if (mX == 0) {mX = -1;}
        else {mX = 1;}
      
        int mY = int(random(0, 2));
        if (mY == 0) {mY = -1;}
        else {mY = 1;}
      
        destX = xPos + displacement * (mX * angleOffset...?) //set destX to be 'senseDia' pixels away variably offset from headAngle
        if (destX >= (width - margin)) {destX = width - margin;}
        else if (destX <= margin) {destX = margin;}
      
        destY = yPos + displacement * (mY * angleOffset...?); //set destY
      
        if (destY >= (height - margin)) {destY = height - margin;}
        else if (destY <= margin) {destY = margin;}
        */ 
        destReached = false;
      }
    }
    //strokeWeight(4); 
    //stroke(250, 0, 0);
    //point(destX, destY); //to monitor serpent's current destination point
  }
  
  void update() //a.k.a. move -- calc distance to target position & increment x & y positions by vel
  {
    float dx = destX - xPos;
    float dy = destY - yPos;
    
    //float timeScalar = vel * 5;
    //int numSteps = 10;
    //xPos = lerp(startX, destX, distX);
    //yPos = lerp(startY, destY, distY);
    if (abs(dx) <= 1 && abs(dy) <= 1) {destReached = true;} //check to see if destination's been reached
    else if (dx > 1.0)
    {
      if (vocState == true) {xPos = xPos;}
      else if (hearSerpentVoc == true) {xPos += vel/2;}
      else if (foundSound == false && pauseState == false) {xPos += vel;} //move linearly when no sound heard
      else if (foundSound == true) {xPos += dx * easing;} //ease to a stop when approaching a heard soundSource
      //else if (pauseState == true) {xPos = xPos;} //don't move when paused
      else if (pauseState == true) {xPos += (dx * easing) * easing;}
      //xPos += ((1 - dx/distX)) * timeScalar;
      //xPos += (1 - (dx/width)) * timeScalar;
    }
    
    else if (dx < -1.0)
    {
      if (vocState == true) {xPos = xPos;}
      else if (hearSerpentVoc == true) {xPos -= vel/2;}
      else if (foundSound == false && pauseState == false) {xPos -= vel;}
      else if (foundSound == true) {xPos += dx * easing;}
      //else if (pauseState == true) {xPos = xPos;} //don't move when paused
      else if (pauseState == true) {xPos += (dx * easing) * easing;}
      //xPos -= ((1 - dx/distX))*timeScalar;
      //xPos -= (1 - (dx/width)) * timeScalar;
      
    }
    
    /*else*/ if (dy > 1.0)
    {
      if (vocState == true) {yPos = yPos;}
      else if (hearSerpentVoc == true) {yPos += vel/2;}
      else if (foundSound == false && pauseState == false) {yPos += vel;}
      else if (foundSound == true) {yPos += dy * easing;}
      //else if (pauseState == true) {yPos = yPos;}
      else if (pauseState == true) {yPos += (dy * easing) * easing;}
     //yPos += (1 - (dy/distY)) * timeScalar;
     //yPos += (1 - (dy/height)) * timeScalar;
    }
    
    else if (dy < -1.0)
    {
      if (vocState == true) {yPos = yPos;}
      else if (hearSerpentVoc == true) {yPos -= vel/2;}
      else if (foundSound == false && pauseState == false) {yPos -= vel;}
      else if (foundSound == true) {yPos += dy * easing;}  
      //else if (pauseState == true) {yPos = yPos;}
      else if (pauseState == true) {yPos += (dy * easing) * easing;}
      //yPos -= (1 - (dy/distY)) * timeScalar;
      //yPos -= (1 - (dy/height)) * timeScalar;
    }
  }
  
  void dragSegment(int i, float xin, float yin) //function updating the position and orientation of each segment of the total 'snake' form
  {
    float dx = xin - x[i]; //calculate the change in x position
    float dy = yin - y[i]; //calculate the change in y position
    float angle = atan2(dy, dx);  //calculate the angle between the latest x and y positions of the line segment
    if (i == 0) {angleHead = angle;} //store current angle position of "head" segment origin point
    x[i] = xin - cos(angle) * segLength; //update the x position of the line segment
    y[i] = yin - sin(angle) * segLength; //update the y position of the line segment
    segment(x[i], y[i], angle); //generate a line segment using the latest x, y, and angle values
  }
  
  void segment(float x, float y, float a) //function generating an individual line segment
  {
    pushMatrix(); 
    translate(x, y);
    rotate(a);
    line(0, 0, segLength, 0);
    popMatrix();
  }
  
  void renderSensoryRange ()
  {
    strokeWeight(0); //sensory range display
    stroke(10, 10);
    fill(200, 180, 10, 100);
    //arc(xPos, yPos, 120, 120, (angleHead - HALF_PI), angleHead + HALF_PI, CHORD);
    ellipse(xPos, yPos, senseDia, senseDia); //view of sensory range around head origin point
    //strokeWeight(2); //for testing only...
    //stroke(0, 180, 0, 180); //for testing only...
    //line(xPos, yPos, xPos + (senseDia/2), yPos + (senseDia/2)); //sin0 = o(y)/h(senseDia) | o(y) = sin0 * h(senseDia) | cos0 = a(x)/h(senseDia) | a(x) = cos0 * h(senseDia)
  }
  
  void display()
  {
    if (recState == true) //change color of serpent dependent on state
    { //if listenState active, flash red to indicate listening/recording sound
      renderSensoryRange();
      strokeWeight(9); //for serpent segment display
      if (red >= 255)
      {
        red = 255;
        colorInc = -1 * colorInc;
      }
      else if (red <= 0)
      {
        red = 0;
        colorInc = -1 * colorInc;
      }
      stroke(red, 20, 20, 100);
      red = red + colorInc;
    }
    else if (listenState == true && recState == false && haveSound == true)
    {
      renderSensoryRange();
      strokeWeight(9); //for serpent segment display
      //SoundSource aSource = sources.get(soundID); //get the soundSource being listened to
      float inputLevel = in.left.level(); //get the current audio level of the input buffer
      float inputColorOffset = map(inputLevel, 0.0001, 0.5, 0, 100);
      stroke(0, 120 + inputColorOffset, 20, 100); 
    }
    else if (listenState == false && haveSound == true && vocState == false)
    {
      renderSensoryRange();
      strokeWeight(9); //for serpent segment display
      stroke(0, 220, 20, 100);
    }
    else if (vocState == true)
    {
      currentLevel = out.mix.level(); //get current volume level (RMS) of Sampler output
      float currentOpacityOffset = map(currentLevel, 0.0001, 0.05, 0, 1);
      //println("serp_" + selfID + " sampOutLevel=" + currentLevel);
      strokeWeight(0); //sensory range display
      fill(200, 180, 10, 45 + (45 * currentOpacityOffset));
      ellipse(xPos, yPos, senseDia, senseDia); //view of sensory range around head origin point
      
      strokeWeight(9); //for serpent segment display
      
      stroke(220, 220, 20, 100 + (75 * currentOpacityOffset));
    }
    else //starting color when (haveSound == false)
    {
      renderSensoryRange();
      strokeWeight(9); //for serpent segment display
      stroke(255, 100);
    }
    
    dragSegment(0, xPos, yPos); //generate initial segment and update its position w/ via mouse position input
    point(xPos, yPos);
    for(int i=0; i<x.length-1; i++) //iterating to create each additional point-line-segment of the total 'snake' form
    {dragSegment(i+1, x[i], y[i]);}  
  }
}