


//ClayblockGraviKeys------------------------------------------------------------------------------------------------------------------------------------------------------------------------
class ClayblockGraviKeys extends ClayblockElement{
  
  //gravikeys must assign the initial number, the other calculations are made by the key
  
   ClayblockVoicePool voices;
   int baseNote;
   int range;
   float noteW;
   float rangeLow;
   float rangeHi;
   int blackKeys[] = {0 , 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0};
   int cursorRadius = 20;
   //use blackKeys[(baseNote+offset)%12] to know if a key is black
   
   ClayblockGraviKeys(int x, int y, int w, int h, int baseNote, int range, ClayblockVoicePool voices){
      super.x=x;
      super.y=y;
      super.w=w;
      super.h=h;
      super.xBoundaryLo=x-deadZone;
      super.xBoundaryHi=x+w+deadZone;
      super.yBoundaryLo=y-deadZone;
      super.yBoundaryHi=y+h+deadZone;
      this.baseNote=baseNote;
      this.range=range;
      this.voices=voices;    
      this.noteW = (float) w / (float) range;
      this.rangeLow = baseNote-0.5;
      this.rangeHi = baseNote+range-0.5;
   }
   
   void interact(float actionX, float actionY, boolean firstTouch, int touchId){
     float actionNumber = floor(map(actionX-x, 0, w, rangeLow+0.5, rangeHi+0.5));
     float ctrl = map(actionY, y, y+h, 1.0, 0.0); 
     
     //println("gravikeys interact. actionX: "+actionX+ ", actionNumber: "+actionNumber+", ctrl: "+ctrl+", touchId: "+touchId);
     voices.interact(actionNumber, actionX, ctrl, touchId, noteW);  
   }
   
   void update() {
     //the voice pool is updated by itself, no updating here
   }
   
   
   void display(int alpha){
     pushMatrix();
     noFill();
     stroke(255);
     rectMode(CORNER);
     rect(x,y,w,h);
     translate(x,y);

     
     ClayblockVoice[] pool = voices.getPool();
     for(ClayblockVoice v : pool){
       float vNumber = v.getNumber();
       float vCtrl = v.getCtrl();
       if(!(v.isDead()) && vNumber>rangeLow && vNumber < rangeHi){

         float noteX = map(vNumber, rangeLow, rangeHi, 0, w);
         float noteY = map(vCtrl, 0, 1, h, 0);   
         
         if(v.getState()==1){
           stroke(90);  
         }else{
           stroke(40);  
         }
         line (noteX, 0, noteX, h);
         line (0, noteY, w, noteY);  
       }
     }
     
     //keys 
     for(int i=0; i<range; i++){ 
       if(blackKeys[(baseNote+i)%12]==0){
          //white key
          stroke(255);
          line(noteW*i+noteW/2, h/3 , noteW*i+noteW/2, h*5/6);   
       }else{
          //black key 
          stroke(130);
          line(noteW*i+noteW/2, h/6, noteW*i+noteW/2, h*2/3); 
       }
       
     }
     
     
     popMatrix();
   }
  
}

//ClayblockVoicePool------------------------------------------------------------------------------------------------------------------------------------------------------------------------

class ClayblockVoicePool{
  
  int voicesNum;
  ClayblockVoice[] voices;
  int oldestDecaying;
  int firstDeadNote;
  
  
  ClayblockVoicePool( int voicesNumber, int deadZone, float bendRatio){
    this.voicesNum = voicesNumber;
    this.voices = new ClayblockVoice[voicesNum];
    
    for(int i=0; i<voicesNum; i++){
      voices[i]= new ClayblockVoice("/gkn"+nf(i,2), this, deadZone, bendRatio);
      
    }
    
    this.oldestDecaying = -1;  
    this.firstDeadNote=0;
  }
  
  ClayblockVoicePool( int voicesNumber, int deadZone){
   this(voicesNumber, deadZone, 1.0); 
    
  }
  
  void interact(float number, float actionX, float ctrlDest, int touchId, float noteWidth){
    //this method is called for each touch event
    //note width must have to be supplied from the gravikeys as differnt simultaneous gravikeys may have different note width
    
    int query = searchId(touchId);
    
    if(query==-1){
      //new note allocation
      
      if(firstDeadNote!=-1){
        voices[firstDeadNote].touched(number, actionX, ctrlDest, touchId, noteWidth);  
      }else{
        voices[oldestDecaying].touched(number, actionX, ctrlDest, touchId, noteWidth); 
      }
    }else{
       //old note interaction continues
       voices[query].touched(number, actionX, ctrlDest, touchId, noteWidth); 
    }
  }
  
  void update(){
    for(ClayblockVoice v : voices){
      v.update();  
    }
  }
  
  void indicize(){
     int decayDummy = -1;
     boolean foundDead=false;
     for (int i=0; i<voicesNum; i++){
       if(voices[i].isDead() && !foundDead){
           foundDead=true;
           firstDeadNote=i;
       }else if(voices[i].getState()==0){
         if(decayDummy == -1){
           decayDummy = i;  
         }else{
           if (voices[decayDummy].getLastStateChange() < voices[i].getLastStateChange()){
             decayDummy = i;
           }
         }
       }
     }
     if(!foundDead) firstDeadNote = -1;
     oldestDecaying = decayDummy;
     //search again for the oldest decaying and the first dead note 
  }
  
  int searchId(int touchId){
    for (int i=0; i<voicesNum; i++){
      if (voices[i].getTouchId() == touchId){
        return i;  
      }
    }
    return -1;
    //return voice index number or -1 if voice isn't in the pool
  }
  
  void reset(){
     //invoke touchReset on all Voices, needed for other routines 
    for(ClayblockVoice v : voices){
      v.reset();  
    }
  }
  
  ClayblockVoice[] getPool(){
    return voices;  
  }
  
}

//ClayblockVoice-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

class ClayblockVoice {
  
  ClayblockVoicePool parent;
  float number;
  float startingX;
  float startingNumber;
  int touchId; 
  float ctrl;
  float ctrlDest;
  float bendRatio;
  float easing=0.5;
  float gravity= 0.001;  // ctrl points for milliseconds
  float lastDecayCheck;
  int state;  //-1 dead 0 decaying 1 sustaining
  int lastStateChange = 0;     //millis of last state change, useful to know oldest decaying note
  float deadZone = 14;
  String oscId;
  boolean touched;


  ClayblockVoice(String oscId, ClayblockVoicePool parent, int deadZone, float bendRatio){
   this.parent = parent; 
   this.oscId= oscId;
   this.number= 0;
   this.startingNumber=0;
   this.startingX=0;
   this.ctrl=0;
   this.ctrlDest=0;
   this.touchId=-1;
   this.state=-1;
   this.deadZone = deadZone;
   this.bendRatio = bendRatio;
   this.touched=false;
   //println("note created, id: "+oscId);
  } 
    
  void touched(float number, float actionX, float ctrlDest,  int touchId, float w){
    
    touched=true;
    this.ctrlDest=ctrlDest;
    
    if(state==-1){
      //println("first touch "+oscId+" at frame:"+frameCount+" number set: "+number);
      //first touch      
      this.touchId = touchId;
      startingX = actionX;
      this.startingNumber = number;
      this.number = number;
      _stateChange(1);  
    }else{
      //other touchs 
      
      if(actionX<startingX-deadZone){
        this.number= startingNumber + map(actionX, startingX-deadZone-w,  startingX-deadZone, -bendRatio, 0.0);
      }else if(actionX>startingX+deadZone){
        this.number = startingNumber + map(actionX, startingX+deadZone, startingX+deadZone+w, 0.0, bendRatio);
      }
    }
  }  
    
  void update(){
    //implement also OSC sending
    
    if(state==1){
      if (touched){
        //easing movement
        if(ctrl!=ctrlDest){
          if(abs(ctrl-ctrlDest)>0.0001){
            ctrl+= (ctrlDest-ctrl)*easing;   
          }else{
            ctrl=ctrlDest; 
          }
        }
      }else{
        //change state to decaying 
        touchId=-1;
        _stateChange(0);  //now is decaying
      }
    }
    
    if(state==0){
      ctrl = ctrl - (millis()-lastDecayCheck)*gravity;
      lastDecayCheck=millis();
      if(ctrl <=0){
        _stateChange(-1); 
        ctrl=0;
        //send this osc message here. Dead note messages are not sent, this is the last
        OscMessage myMessage = new OscMessage(oscId);
        myMessage.add(number);
        myMessage.add(ctrl);
        oscP5.send(myMessage, myRemoteLocation);  
      }
      
      //println(oscId+ " ctrl: "+ctrl);
    }
  
    //send all the osc message
    if(!isDead()){
        OscMessage myMessage = new OscMessage(oscId);
        myMessage.add(number);
        myMessage.add(ctrl);
        oscP5.send(myMessage, myRemoteLocation);  
    }
    
  }
  
  void reset(){
    //to be invoked before the touch control section
    touched=false;
  }  
    
  int getState(){
    return state;
  }  
  
  void _stateChange( int newState){
    state = newState;
    lastStateChange = millis();  
    if(state==0) lastDecayCheck = millis();
    parent.indicize();
    //println("note id "+oscId+" state changed, actual state: "+state);
  }
  
  int getLastStateChange(){
    return lastStateChange;  
    
  }
  
  float getNumber(){
    return number;  
  }
  
  float getCtrl(){
    return ctrl;  
  }
  
  int getTouchId(){
    return touchId;
  }
  
  boolean isDead(){
    return (state==-1);  
  }
  
}