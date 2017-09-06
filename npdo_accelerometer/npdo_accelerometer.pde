// ----------- SETUP ----------------------------
String destinationIP = "192.168.1.4";
int    port          = 4444;
String id            = "zero";
float  threshold     = 1.2;
//-----------------------------------------------

import ketai.sensors.*;
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;
KetaiSensor sensor;
float ax, ay, az; // accelerometer xyz
float bx, by, bz; // base xyz
int counter;

void setup()
{
    fullScreen();
    oscP5 = new OscP5(this, 42);
    myRemoteLocation = new NetAddress( destinationIP, port);
    sensor = new KetaiSensor(this);
    sensor.start();
    orientation( LANDSCAPE );
    textAlign( CENTER, CENTER );
    textSize(displayDensity * 12);
    bx = by = bz = 0.0;
    counter = -1;
}

void draw()
{
  counter--;
  if(counter > 0 ){
      background( 0 );
      fill(255);
      rect(width*0.4, 0, width*0.2, height);
      fill( 0 );
  }else{
      background( 0 );      
      fill(255);
  }

  text("Output: \n" +
    "/"+ id + "/ay : " + nfp(ax, 1, 3) + "\n" +
    "/"+ id + "/ax : " + nfp(ay, 1, 3) + "\n" +
    "/"+ id + "/az : " + nfp(az, 1, 3) + "\n\n" +
    "Calibration: \n" +
    "x : " + nfp(bx, 1, 3) + "\n" +
    "y : " + nfp(by, 1, 3) + "\n" +
    "z : " + nfp(bz, 1, 3) + "\n",
    0, 0, width, height);
}

void onAccelerometerEvent(float x, float y, float z)
{
    if(mousePressed){ bx = x; by = y;  bz = z; }
    
    ax = x - bx;
    ay = y - by;
    az = z - bz;
    if(ax < -threshold){ ax+=threshold; }else if(ax > threshold){ ax-=threshold; }else { ax=0.0; }
    if(ay < -threshold){ ay+=threshold; }else if(ay > threshold){ ay-=threshold; }else { ay=0.0; }
    if(az < -threshold){ az+=threshold; }else if(az > threshold){ az-=threshold; }else { az=0.0; }
    
    if(ax!=0.0 ){ 
        OscMessage myMessage = new OscMessage("/"+ id + "/ax");
        myMessage.add( ax );
        oscP5.send(myMessage, myRemoteLocation);
    }
    if(ay!=0.0 ){ 
        OscMessage myMessage = new OscMessage("/"+ id + "/ay");
        myMessage.add( ay );
        oscP5.send(myMessage, myRemoteLocation);
    }
    if(az!=0.0 ){ 
        OscMessage myMessage = new OscMessage("/"+ id + "/az");
        myMessage.add( az );
        oscP5.send(myMessage, myRemoteLocation);
    }
    if(ax!=0.0 || ay!=0.0 || az!=0.0 ) counter = 6;
}