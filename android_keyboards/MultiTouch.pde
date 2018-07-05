//------------------------------
// Setup globals:

// This HashMap will hold all of our queryable Touch data:
Map <Integer, Touch> multiTouch= Collections.synchronizedMap(new HashMap() );


//------------------------------
// Override parent class's surfaceTouchEvent() method to enable multi-touch.
// This is what grabs the Android multitouch data, and feeds our Touch
// classes.  Only executes on touch change (movement across screen, or initial
// touch).
public boolean surfaceTouchEvent(MotionEvent me) {
  int actionIndex = me.getActionIndex();
  int actionId = me.getPointerId(actionIndex);
  int actionMasked = me.getActionMasked();

  switch(actionMasked)
  {
    case MotionEvent.ACTION_DOWN:
    case MotionEvent.ACTION_POINTER_DOWN:
      if (!multiTouch.containsKey(actionId))
      {
        multiTouch.put(actionId, new Touch() );
      }
      //println("Down ID: "+ actionId+" Index: "+ actionIndex +" Total: "+ me.getPointerCount() );
      break;
  
    case MotionEvent.ACTION_UP:
    case MotionEvent.ACTION_POINTER_UP:
    case MotionEvent.ACTION_CANCEL:
      multiTouch.remove(actionId);
      //println("-Up- ID: "+ actionId+" Index: "+actionIndex +" Total: "+ (me.getPointerCount()-1) );
      break;
  
    case 2: //ACTION_MOVE:
      break;
  
    default:
      //println("action: "+actionMasked);
  }

  // update all touch objects in use
  for (int i = 0; i<me.getPointerCount(); i++)
  {
    Touch t = multiTouch.get(me.getPointerId(i));
    if (t != null) // it could have been removed above
    {
      t.update(me, i);
    }
  }

  // If you want the variables for motionX/motionY, mouseX/mouseY etc.
  // to work properly, you'll need to call super.surfaceTouchEvent().
  return super.surfaceTouchEvent(me);
}

//------------------------------
// Class to store our multitouch data per touch event.
class Touch {
  // Public attrs that can be queried for each touch point:
  float motionX, motionY;
  float pmotionX=-1, pmotionY=-1;
  float size, psize=0;
  float pressure, ppressure=0;

  boolean touched = false, ptouched = false;

  // executed whenever there is a surfaceTouchEvent
  void update(MotionEvent me, int index) {
    // me : The passed in MotionEvent being queried
    // index : the index of the item being queried

    pmotionX = motionX;
    pmotionY = motionY;
    psize = size; 
    ppressure = pressure;
    ptouched = touched;

    motionX = me.getX(index);
    motionY = me.getY(index);
    size = me.getSize(index);
    pressure = me.getPressure(index);

    touched = true;
  }
}