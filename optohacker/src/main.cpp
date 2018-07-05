#include "ofMain.h"
#include "ofAppNoWindow.h"
#include "ofxGPIO.h"
#include "ofxXmlSettings.h"
#include "ofxOsc.h"

class noWin : public ofBaseApp{
public:
    int port;
    ofxOscReceiver  receiver;
    vector<GPIO> gpios;

    //-------------------------------------------------------------------------
    void setup(){
            
        ofSetVerticalSync(false);

        std::cout<<"[optohacker] listening on port "<<port<<"\n";
        receiver.setup( port );

        int numCommands = 8;
        gpios.resize(numCommands);

        for(int i = 0; i < numCommands; i++){
            string gpioNum;
            
            switch( i ){
                case 0: gpioNum = "4";  break;
                case 1: gpioNum = "17"; break;
                case 2: gpioNum = "27"; break;
                case 3: gpioNum = "22"; break;
                case 4: gpioNum = "5";  break;
                case 5: gpioNum = "6";  break;
                case 6: gpioNum = "13"; break;
                case 7: gpioNum = "19"; break;
            }
            
            gpios[i].setup( gpioNum );
            gpios[i].export_gpio();
            gpios[i].setdir_gpio("out");
            
            std::cout<< "osc=/opto index="<<i<< " | gpio=" << gpioNum << "\n";
        }
    }

    //-------------------------------------------------------------------------
    void update() {
        while(receiver.hasWaitingMessages()){
            // get the next message
            ofxOscMessage m;
            receiver.getNextMessage(m);
            
            if ( m.getAddress() == "/opto" ){
                int i = m.getArgAsInt32(0);
                if( i>=0 && i<8 ){
                    int out = m.getArgAsInt32(1);
                    if(out==0){
                        gpios[i].setval_gpio("0");
                    }else{
                        gpios[i].setval_gpio("1");
                    }                        
                }
            }
        }
        ofSleepMillis(1);
    }

    //-------------------------------------------------------------------------
    void exit(){
        for(size_t i=0; i<gpios.size(); ++i){
            gpios[i].unexport_gpio();
        }
    }

};

//-----------------------------------------------------------------------------
int main(int argc, char *argv[]){
    ofAppNoWindow window;
    noWin * app = new noWin();
    
    app->port = 4444;
    
    if(argc>1){		
		for(int i=1; i<argc; i+=2){
			if( ! strcmp( argv[i], "-p" ) ){
                app->port = ofToInt( argv[i+1] );	
			}
		}
	}
    
    ofSetupOpenGL(&window, 0,0, OF_WINDOW);
    ofRunApp( app );
}
