
#include "ofApp.h"

#define BUFFERW 160
#define BUFFERH 120 

// ------------------------------------------------------------------
void ofApp::setup() {
	
    blobs.reserve(64); // more than enough
    blobs.clear();
    
    ofSetVerticalSync(false);
    ofSetBackgroundAuto( false );
    
    bTakeBackground = true;
    finder.setThreshold(127);

    buffersize = BUFFERW*BUFFERH;
    buffer = new char[buffersize];
    
    // loading settings 
    settings.setName( "settings");
        settings.add( drawToScreen.set("draw to screen", false) );
    
        camera.setName( "camera");
            camera.add( width.set("width", 640, 640, 1920) );
            camera.add( height.set("height", 480, 480, 1080) );
            camera.add( file.set("calibration file", "pimoroni_fisheye_640x480.yml") );
        settings.add( camera );
    
        parameters.setName( "cvtracker");
            parameters.add( doBackgroundSubtraction.set("background subtraction", false) );
                doBackgroundSubtraction.addListener( this, &ofApp::onBGSubtractionToggle );
            parameters.add( low.set("threshold low", 0, 0, 255) );
            parameters.add( high.set("threshold high", 255, 0, 255) );
            parameters.add( minArea.set("area min", 20, 1, 25000) );
            parameters.add( maxArea.set("area max", 20000, 1, 100000) );;
            parameters.add( distSensitivity.set("distance sensitivity", 10.0f, 1.0f, 80.0f) );
            parameters.add( veloSensitivity.set("velo sensitivity", 0.01f, 0.00001f, 1.0f) );
            parameters.add( persistence.set("persistence", 15, 1, 100) );
            parameters.add( maxDistance.set("max distance", 32, 1, 100) ); 
            parameters.add( deadzoneWidth.set("deadzone width", 0.05f, 0.0f, 0.25f) ); 
                deadzoneWidth.addListener( this, &ofApp::onDeadzone );
            parameters.add( deadzoneHeight.set("deadzone height", 0.0f, 0.0f, 0.25f) ); 
                deadzoneHeight.addListener( this, &ofApp::onDeadzone );
            parameters.add( sendImage.set("send image", 0, 0, 2) );
        settings.add( parameters );
        
        network.setName("network");
            network.add( ip.set("client ip", "localhost") );
          
            ports.setName("ports");
                ports.add( trackingPort.set( "tracking send", 12345, 0, 15000) );
                ports.add( imagePort.set("image send", 4242, 0, 15000) );
                ports.add( syncSendPort.set("sync send", 4243, 0, 15000) );                
                ports.add( syncReceivePort.set("sync receive", 4244, 0, 15000) );                
            network.add( ports );
        settings.add( network );
        
    ofJson json = ofLoadJson("settings.json");
    ofDeserialize( json, settings );

    //ofJson json;
    //ofSerialize( json, settings );
    //ofSavePrettyJson( "settings.json", json );

    // cam setup
    cam.setup( width, height,false );
	calibration.setFillFrame( true ); // true by default
    calibration.load( file );

    
    // setting up matrices
    sender.setup( ip, trackingPort );
    debugger.setup( ip, imagePort );
    sync.setup( parameters, syncReceivePort, ip, syncSendPort );
    
    std::cout<<"[cvtracker] sending blob tracking OSC to "<<ip<<" on port "<<trackingPort<<"\n";
    std::cout<<"[cvtracker] sending debug low res image OSC to "<<ip<<" on port "<<imagePort<<"\n";
    std::cout<<"[cvtracker] syncing parameters to "<<ip<<" with ports "<<syncSendPort<<" (send) and "<<syncReceivePort<<" (receive) \n";
    
    bool hasFrame = false;
    
    while(!hasFrame){
        frame = cam.grab();
        if( !frame.empty() ){
            ofxCv::imitate(undistorted, frame);
            ofxCv::imitate( tLow, frame );
            ofxCv::imitate( tHigh, frame );
            ofxCv::imitate( thresh, frame );
            ofxCv::imitate( background, frame );
            hasFrame = true;
        }
    }

    
    divideW = 1.0f / float(width);
    divideH = 1.0f / float(height);
    
    float dummy = 0.0f;
    onDeadzone( dummy );
    
}


// ------------------------------------------------------------------
void ofApp::update() {
    
    sync.update();
    
    frame = cam.grab();
    
    if(!frame.empty()){
        calibration.undistort(frame, undistorted);
        
        if( bTakeBackground ){
            background = undistorted;
            bTakeBackground = false;
        }
        
        if( doBackgroundSubtraction ){
            // do background subtraction on undistortion 
            cv::subtract( undistorted, background, undistorted );
            cv::threshold( undistorted, undistorted, 0, 255, 3 ); // remove values lower than 0? to test
        }
        
        cv::threshold( undistorted, tLow,   low, 255,  0 );
        cv::threshold( undistorted, tHigh,  high, 255, 1 );
        cv::bitwise_and(tLow, tHigh, thresh );
        
        // set contour tracker parameters
        finder.setMinArea(minArea);
        finder.setMaxArea(maxArea);
        finder.setFindHoles( false ); 
        
        finder.getTracker().setPersistence(persistence);
        finder.getTracker().setMaximumDistance(maxDistance);
        
        
        switch( sendImage ){
            case 1:
            {
                for( int x=0; x<BUFFERW; ++x ){
                    for (int y=0; y<BUFFERH; ++y){
                        int mx = ofMap( x, 0, BUFFERW, 0, width, true );
                        int my = ofMap( y, 0, BUFFERH, 0, height, true );
                        buffer[x+y*BUFFERW] = undistorted.at<char>( my, mx );
                    }
                }
            
                ofBuffer ofbuf;
                ofbuf.clear();
                ofbuf.append(buffer, buffersize);
                
                ofxOscMessage m;
                m.setAddress( "/cvtracker/image" );
                m.addBlobArg(ofbuf);
                debugger.sendMessage(m, false);
            }
            break;
            
            case 2:
            {
                for( int x=0; x<BUFFERW; ++x ){
                    for (int y=0; y<BUFFERH; ++y){
                        int mx = ofMap( x, 0, BUFFERW, 0, width, true );
                        int my = ofMap( y, 0, BUFFERH, 0, height, true );
                        buffer[x+y*BUFFERW] = thresh.at<char>( my, mx );
                    }
                }
            
                ofBuffer ofbuf;
                ofbuf.clear();
                ofbuf.append(buffer, buffersize);
                
                ofxOscMessage m;
                m.setAddress( "/cvtracker/image" );
                m.addBlobArg(ofbuf);
                debugger.sendMessage(m, false);
            }
            break;
            
            default: break;
        }
        
        // determine found contours
        finder.findContours( thresh );
        doBlobs();
	}
    
}

// ------------------------------------------------------------------
void ofApp::doBlobs(){
    
    for ( auto & blob : blobs ){ blob.found = false; }
    
    for( size_t i=0; i<finder.size(); ++i ){
       
        if( finder.getCenter(i).x > minX && finder.getCenter(i).x < maxX && finder.getCenter(i).y > minY && finder.getCenter(i).y < maxY ){
                    
            bool insert = true;
           
            for( auto & blob : blobs ){
                
                if( finder.getLabel(i) == blob.label ){
                    blob.found = true;
                    insert = false;
                    
                    if( // check the distance or velocity changed enough
                        ( glm::distance( blob.center, glm::vec2(finder.getCenter(i).x, finder.getCenter(i).y) ) > distSensitivity ) ||
                        (glm::distance( blob.velocity, glm::vec2(finder.getVelocity(i)[0], finder.getVelocity(i)[1]) ) > veloSensitivity )
                     ){ // then 
                        blob.center.x = finder.getCenter(i).x;
                        blob.center.y = finder.getCenter(i).y;
                        blob.velocity.x = finder.getVelocity(i)[0];
                        blob.velocity.y = finder.getVelocity(i)[1];
                        blob.boundaries = ofxCv::toOf( finder.getBoundingRect(i) );
                        blob.update = true;
                    }
                    break;
                }
            }
            
            if( insert ){
                blobs.emplace_back();
                blobs.back().center.x = finder.getCenter(i).x;
                blobs.back().center.y = finder.getCenter(i).y;
                blobs.back().velocity.x = finder.getVelocity(i)[0];
                blobs.back().velocity.y = finder.getVelocity(i)[1];
                blobs.back().boundaries = ofxCv::toOf( finder.getBoundingRect(i) );
                blobs.back().label = finder.getLabel(i);
            }            
            
        }
        
    }
    
    // now delete all the not found and send OSC message for that
    auto it = blobs.begin();
    for ( ; it != blobs.end(); ) {
        if( ! it->found ){
            ofxOscMessage m;
            m.setAddress( "/cvtracker/blobs/delete" );
            m.addIntArg( it->label );
            sender.sendMessage(m, false);
            it = blobs.erase( it );
        }else{
            it++;
        } 
    }

    
    // send all the messages for the blobs to update 
    for( auto & blob : blobs ){
        if( blob.update ){
            ofxOscMessage m;
            
            m.setAddress( "/cvtracker/blobs/update" );
            
            m.addIntArg( blob.label );
            
            // normalized coords
            m.addFloatArg( blob.center.x * divideW );
            m.addFloatArg( blob.center.y * divideH );
            
            // velocities
            m.addFloatArg( blob.velocity.x );
            m.addFloatArg( blob.velocity.y );
            
            // normalized bounding boundaries
            m.addFloatArg( blob.boundaries.x * divideW);
            m.addFloatArg( blob.boundaries.y * divideH);
            m.addFloatArg( blob.boundaries.width * divideW);
            m.addFloatArg( blob.boundaries.height * divideH); 

            sender.sendMessage(m, false);
            
            blob.update = false;
        }
    }
}


// ------------------------------------------------------------------
void ofApp::draw() {
    if( drawToScreen ){
        ofClear( 0, 0, 0, 255 );
        ofSetColor(255);
        if(!frame.empty()){
            ofxCv::drawMat( undistorted, 0, 0, width/2, height/2);
            ofxCv::drawMat( thresh, width/2, 0, width/2, height/2);
        } 
        ofTranslate( width/2, 0 );
        ofScale( 0.5f );
        ofSetColor( 255, 0, 0 );
        finder.draw();        
    }
}

// ------------------------------------------------------------------
void ofApp::exit() {
    delete [] buffer;
}

void ofApp::onBGSubtractionToggle( bool & value ){
    if( value ){
        bTakeBackground = true;
    }
}

void ofApp::onDeadzone( float & value ){
    minX = ofMap( deadzoneWidth, 0.0f, 1.0f, 0.0f, width, true );
    maxX = ofMap( deadzoneWidth, 0.0f, 1.0f, width, 0.0f, true );
    minY = ofMap( deadzoneHeight, 0.0f, 1.0f, 0.0f, height, true );
    maxY = ofMap( deadzoneHeight, 0.0f, 1.0f, height, 0.0f, true );
}
