
#include "ofMain.h"
#include "ofApp.h"

//-----------------------------------------------------------------------------
int main(int argc, char *argv[]){

#ifdef __ARM_ARCH
    ofSetupOpenGL( 100, 100, OF_WINDOW);
	ofRunApp( new ofApp() );
#else
    ofSetupOpenGL( 640*2 + 260, 480, OF_WINDOW);
	ofRunApp( new ofApp() );
#endif    

    
}
