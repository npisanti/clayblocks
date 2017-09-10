// ----------- SETUP ----------------------------
String destinationIP = "192.168.1.4";
int    port          = 12345;
String id            = "zero";
float  deadzone      = 0.7;
String savename = "\\sdcard\\cb_accelerometer.txt";
//-----------------------------------------------



import ketai.sensors.*;
import ketai.ui.*;
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;
KetaiSensor sensor;
float ax, ay, az; // accelerometer xyz
float bx, by, bz; // base xyz
int counter;
boolean bSettings;
boolean bCalibrate;

void setup()
{

    File f = new File( savename );
    if (f.exists()) {
        println("found settings file");
        String[] lines = loadStrings( savename );
        id = lines[0];
        destinationIP = lines[1];
        port = parseInt(lines[2]);
        bx = parseFloat(lines[3]);
        by = parseFloat(lines[4]);
        bz = parseFloat(lines[5]);
    }else{
        bx = by = bz = 0.0;   
    }
    
    fullScreen();
    oscP5 = new OscP5(this, 42);
    myRemoteLocation = new NetAddress( destinationIP, port);
    sensor = new KetaiSensor(this);
    sensor.start();
    orientation( PORTRAIT );
    textAlign( CENTER, CENTER );
    textSize(displayDensity * 12);

    counter = -1;
    bSettings = false;
    bCalibrate = false;
    settingsSetup();
}

void draw()
{
    
  if(!bSettings){
      counter--;
      if(counter > 0 ){
          background( 0 );
          fill(255);
          rect(width*0.3, 0, width*0.4, height);
          fill( 0 );
      }else{
          background( 0 );      
          fill(255);
      }
      textAlign( CENTER, CENTER );
      text("Output: \n" +
        "/"+ id + "/ax : " + nfp(ax, 1, 3) + "\n" +
        "/"+ id + "/ay : " + nfp(ay, 1, 3) + "\n" +
        "/"+ id + "/az : " + nfp(az, 1, 3) + "\n\n\n\n" +
        "fast tap the screen \nthree times for settings",
        0, 0, width, height);
        
    } else {
        settingsDraw();
    }
}

void onAccelerometerEvent(float x, float y, float z)
{
    if(bCalibrate){ bx = x; by = y;  bz = z; }
    
    ax = x - bx;
    ay = y - by;
    az = z - bz;
    if(ax < -deadzone){ ax+=deadzone; }else if(ax > deadzone){ ax-=deadzone; }else { ax=0.0; }
    if(ay < -deadzone){ ay+=deadzone; }else if(ay > deadzone){ ay-=deadzone; }else { ay=0.0; }
    if(az < -deadzone){ az+=deadzone; }else if(az > deadzone){ az-=deadzone; }else { az=0.0; }
    
    if(ax!=0.0 ){ 
        ax = -ax; // positive to the right
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