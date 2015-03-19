import processing.video.*;
import java.util.*;
import SimpleOpenNI.*;

SimpleOpenNI context;
Capture video;
Movie myMovie;

PGraphics mask;

int frameNumber = 0;
HashMap<Integer, PImage> frameBuffer = new HashMap<Integer, PImage>();

static final int INPUT_INTERN = 0;
static final int INPUT_KINECT = 1;
static final int INPUT_VIDEO = 2;
static final int INPUT_LOGITECH = 3;

static final int FORM_NONE = 0;
static final int FORM_TOP = 1;
static final int FORM_BOTTOM = 2;
static final int FORM_HORIZONTAL_CENTER = 3;
static final int FORM_VERTICAL_RIGHT = 4;
static final int FORM_VERTICAL_CENTER = 5;
static final int FORM_MASK_CENTER_ELLIPSE = 6;
static final int FORM_MASK_CENTER_RECT = 7;

// video input groesse, wird im setup beim jeweiligen input definiert
int videoOriginWidth;
int videoOriginHeight;

// fenster groesse, wird im setup definiert
int windowWidth;
int windowHeight;

// wird im setup berechnet
int videoOutputWidth;
int videoOutputHeight;

// logitec resize-factor (performance)
int logitechResizeFactor = 2;

// position (tiefe) im raum in prozent
int depthPercent = 100;
PVector com = new PVector();

/**
* KONFIGURATION
*/
boolean mirror = true;
int timeZoneRowSizeStart = 8;
int rowSize = 8*timeZoneRowSizeStart; // höhe einer reihe
int frameDelayStep = 1; // frame verzögerung pro reihe
int currentInput = INPUT_LOGITECH;
int delayForm = FORM_BOTTOM; 

boolean measureDepth = true;
boolean blueEffect = true;


void setup() {

	frameRate(20); 

	switch (currentInput) {
		case INPUT_LOGITECH: 
			videoOriginWidth = 1920/logitechResizeFactor;
			videoOriginHeight = 1080/logitechResizeFactor;

			// video = new Capture(this, 1920, 1080, "HD Pro Webcam C920", 15);
			video = new Capture(this, 1920, 1080, "HD Pro Webcam C920 #2", 15);
			video.start();
			break;

		case INPUT_INTERN: 
			videoOriginWidth = 1280;
			videoOriginHeight = 720;

			video = new Capture(this, videoOriginWidth, videoOriginHeight, "FaceTime HD-Kamera (integriert)", 15);
			video.start();
			break;

		case INPUT_KINECT:
			videoOriginWidth = 640;
			videoOriginHeight = 480;

			context = new SimpleOpenNI(this);
			if (context.isInit() == false) {
				println("Can't init SimpleOpenNI, maybe the camera is not connected!");
				exit();
				return;  
			}
			context.setMirror(false);
			context.enableRGB();
			context.enableDepth();

			break;

		case INPUT_VIDEO: 
			myMovie = new Movie(this, "test-video.mp4");
			videoOriginWidth = 1280;
			videoOriginHeight = 720;
  			myMovie.loop();
			break;
	}

	if (measureDepth && currentInput == INPUT_LOGITECH) {
		context = new SimpleOpenNI(this);
		if (context.isInit() == false) {
			println("Can't init SimpleOpenNI, maybe the camera is not connected!");
			exit();
			return;  
		}
		context.setMirror(false);
		context.enableRGB();
		context.enableDepth();
		context.enableUser();

	}

	windowWidth = displayWidth;
	windowHeight = displayHeight;
	// windowWidth = 3240;
	// windowHeight = 1960;
	windowWidth = 960;
	windowHeight = 540;

	// windowWidth = 1960*2;
	// windowHeight = 1080;
	// windowWidth = 1960;
	// windowHeight = 1080;

	size(windowWidth, windowHeight, P2D);

	calcVideoSize();

	mask = createGraphics(videoOutputWidth, videoOutputHeight, P2D);
	
}

boolean sketchFullScreen() { return false; }



void draw() {
	background(255);
	// frame.setLocation(-2160,0); 
	if (frameNumber < 20) {
		// frame.setLocation(-windowWidth, 0); 
	}

	// measureDepth
	if (measureDepth) {
		updateDepth();
	}

	// frame als bild im buffer speichern
	readFrame();
	// println(frameRate);


	pushMatrix();
		float factor = float(windowWidth) / float(videoOutputWidth);
		if (currentInput == INPUT_VIDEO) {
			scale(factor, factor);
		} else {

			if (mirror) {
				scale(-factor, factor);
				translate(-videoOutputWidth, 0);
			} else {
				scale(factor, factor);
			}
			
		}

		// bild zeichnen
		drawImage();	

		if (measureDepth && blueEffect) {
			float alpha = map(depthPercent, 100, 0, 1, 140);
			fill(color(195,235,250, alpha));
			noStroke();
			rect(0,0, windowWidth, windowHeight);
		}

	popMatrix();



	// PImage depthImage = context.depthImage();
	// image(depthImage.get(0, 200, width, depthImage.height-200), 0, 0);
	//image(depthImage, 0, 0);

	frameNumber++;
	
}	

/**
* berechnet die höhe und breite der video ausgabe. 
*/
void calcVideoSize() {
	
	if (float(windowWidth)/float(windowHeight) > float(videoOriginWidth)/float(videoOriginHeight)) {
		videoOutputWidth = videoOriginWidth;
		videoOutputHeight = int(videoOriginWidth*(float(windowHeight)/float(windowWidth)));
	} else {
		videoOutputWidth = int(videoOriginHeight*(float(windowWidth)/float(windowHeight)));
		videoOutputHeight = videoOriginHeight;
	}

	println(videoOutputWidth);
	println(videoOutputHeight);
}

/**
* liest das aktuelle frame. schneidet es in das richtige seitenverhältniss und speichert es im buffer
*/
void readFrame() {
	PImage bufferImage = new PImage();

	switch (currentInput) {
		case INPUT_INTERN: 
		case INPUT_LOGITECH: 
			if (video.available()) {
				video.read();
			}
			
			video.loadPixels();

			bufferImage = video.get();
			if (currentInput == INPUT_LOGITECH) {
				bufferImage.resize(bufferImage.width/logitechResizeFactor, bufferImage.height/logitechResizeFactor);
			}
			break;

		case INPUT_KINECT:
			context.update();
			bufferImage = context.rgbImage().get();
			break;

		case INPUT_VIDEO: 
			bufferImage = myMovie.get();
			bufferImage.resize(videoOriginWidth, videoOriginHeight);
			break;
	}

	// buffer bild auf seitenverhaeltniss zuschneiden
	bufferImage = bufferImage.get(int((videoOriginWidth - videoOutputWidth)/2) ,0, videoOutputWidth, videoOutputHeight);

	// bild in den buffer speichern
	frameBuffer.put(frameNumber, bufferImage);
}

/**
* bild ausgabe. diverse formen.
*/
void drawImage() {
	// image(frameBuffer.get(frameNumber), 0, 0);
	
	int top = 0;
	int step = 0;
	int frameDelay = 0;
	int imageTop = 0;


	if (delayForm == FORM_NONE) {
		frameDelay = int(frameNumber);
		image(frameBuffer.get(frameDelay), 0, 0);
	} if (delayForm == FORM_MASK_CENTER_ELLIPSE || delayForm == FORM_MASK_CENTER_RECT) {
		
		while (top < videoOutputWidth) {
			frameDelay = int(frameNumber - (frameDelayStep * step));

			if (frameDelay > 0 && frameBuffer.get(frameDelay) != null) {
				PImage frameImage = mask(frameDelay, top);
				image(frameImage, 0, 0);
			}

			top += rowSize;
			step++;
		}

	} else if (delayForm == FORM_TOP || delayForm == FORM_BOTTOM) {
		while (top < videoOutputHeight) {
			frameDelay = int(frameNumber - (frameDelayStep * step));
			
			if (frameDelay > 0 && frameBuffer.get(frameDelay) != null) {

				switch (delayForm) {
					case FORM_TOP: 
						imageTop = top;
						break;
					case FORM_BOTTOM: 
						imageTop = videoOutputHeight-top-rowSize;
						break;
				}
				

				PImage frameImage = frameBuffer.get(frameDelay).get(0, imageTop, videoOutputWidth, rowSize);

				image(frameImage, 0, imageTop);
			}

			top += rowSize;
			step++;
		}
	} else if (delayForm == FORM_HORIZONTAL_CENTER) {
		
		while (top < (videoOutputHeight/2)+rowSize) {
			frameDelay = int(frameNumber - (frameDelayStep * step));
			if (frameDelay > 0 && frameBuffer.get(frameDelay) != null) {

				int imageTop1 = videoOutputHeight/2 - top;
				int imageTop2 = top + videoOutputHeight/2;

				PImage frameImage1 = frameBuffer.get(frameDelay).get(0, imageTop1, videoOutputWidth, rowSize);
				image(frameImage1, 0, imageTop1);

				PImage frameImage2 = frameBuffer.get(frameDelay).get(0, imageTop2, videoOutputWidth, rowSize);
				image(frameImage2, 0, imageTop2);
			}

			top += rowSize;
			step++;
		}

	} else if (delayForm == FORM_VERTICAL_RIGHT) {
		
		int left = 0;
		int imageLeft = 0;

		while (left < videoOutputWidth) {
			frameDelay = int(frameNumber - (frameDelayStep * step));
			if (frameDelay > 0 && frameBuffer.get(frameDelay) != null) {

				imageLeft = left;

				PImage frameImage = frameBuffer.get(frameDelay).get(imageLeft, 0, rowSize, videoOutputHeight);
				image(frameImage, imageLeft, 0);
			}

			left += rowSize;
			step++;
		}

	} else if (delayForm == FORM_VERTICAL_CENTER) {
		
		int left = 0;
		int imageLeft = 0;

		while (left < (videoOutputWidth/2)+rowSize) {
			frameDelay = int(frameNumber - (frameDelayStep * step));
			if (frameDelay > 0 && frameBuffer.get(frameDelay) != null) {

				int imageLeft1 = (videoOutputWidth/2) - left;
				int imageLeft2 = (videoOutputWidth/2) + left;

				PImage frameImage1 = frameBuffer.get(frameDelay).get(imageLeft1, 0, rowSize, videoOutputHeight);
				image(frameImage1, imageLeft1, 0);

				PImage frameImage2 = frameBuffer.get(frameDelay).get(imageLeft2, 0, rowSize, videoOutputHeight);
				image(frameImage2, imageLeft2, 0);

			}

			left += rowSize;
			step++;
		}

	}

	

	bufferClean(frameDelay);

}

/**
* misst den nächsten punkt. ändert rowSize und frameDelayStep. speichert die tiefe in prozent (für den blauton).
*/
void updateDepth() {
	context.update();
	
	int minDepth = 600;
	int maxDepth = 5600;
	int nearest = maxDepth;

	int[] userList = context.getUsers();
	for (int i=0;i<userList.length;i++) {
		if(context.getCoM(userList[i],com)) {
			// println(com.z);
			if (com.z > 0 && com.z < nearest) {
   				nearest = int(com.z);
   			}
		}
	}

    

    println("Nearest Point: "+nearest);
    // println(depthPercent);

    /**
    * Konfiguration
    */
    int rSize = timeZoneRowSizeStart;
    if (nearest < maxDepth) {
    	depthPercent = int(map(nearest, minDepth, maxDepth, 100, 0));

	    if (nearest < 2000) {
	    	rowSize = rSize*8;
			frameDelayStep = 1;
	    } else if (nearest < 3100) {
	    	rowSize = rSize*4;
			frameDelayStep = 1;
	    } else if (nearest < 4300) {
	    	rowSize = rSize*2;
			frameDelayStep = 1;
	    } else {
	    	rowSize = rSize;
			frameDelayStep = 1;
	    }
	}
}



/**
* erstellt eine maske und errechnet das neue bild
*/ 
PImage mask(int frameDelay, int top) {
	PImage frameImage = frameBuffer.get(frameDelay);

	// create mask

	mask.beginDraw();

	mask.rectMode(CENTER);
	mask.background(0);
	mask.noStroke();
	mask.fill(255);
	mask.smooth();
	if (delayForm == FORM_MASK_CENTER_ELLIPSE) {
		mask.ellipse(mask.width/2,mask.height/2,rowSize+top,rowSize+top);
		mask.fill(0);
		mask.ellipse(mask.width/2,mask.height/2,top-2,top-2);
	} else if (delayForm == FORM_MASK_CENTER_RECT) {
		mask.rectMode(CENTER);
		mask.rect(mask.width/2,mask.height/2,rowSize+top,rowSize+top);
		mask.fill(0);
		mask.rect(mask.width/2,mask.height/2,top-2,top-2);
	}
	mask.endDraw();

	frameImage.mask( mask.get() );


	return frameImage;

}

/**
* löscht die zu alten bilder im buffer.
*/ 
void bufferClean(int frameDelay) {
	// int limitClean = (videoOutputHeight/rowSize)*frameDelayStep;
	int limitClean = (videoOutputHeight/64)*5;


	if (frameBuffer.get(frameDelay-limitClean) != null && frameNumber % 100 == 0) {
		ArrayList<Integer> deleteElements = new ArrayList<Integer>();


		Iterator itr = frameBuffer.entrySet().iterator();
		while(itr.hasNext()) {
			Map.Entry mapEntry = (Map.Entry)itr.next();
			int bufferFrameNumber = (Integer)mapEntry.getKey();

			if (bufferFrameNumber < frameDelay-limitClean) {
				deleteElements.add(bufferFrameNumber);
				
			}

		}

		for (int i = 0; i < deleteElements.size(); i++) {
			frameBuffer.remove(deleteElements.get(i));
		}

		println("frameBuffer-Size: "+frameBuffer.size());
		println("deleteElements-Size: "+deleteElements.size());
	}
}




void keyPressed() {
	// println(keyCode);
	switch (keyCode) {
		case 32: 
		 	myMovie.jump(0);
		 	break;
		case 39: 
			myMovie.jump(myMovie.time()+10);
			break;
		case 37: 
			myMovie.jump(myMovie.time()-7);
			break;

		case 49: // 1
		 	delayForm = FORM_TOP;
		 	break;
		case 50: // 2
			delayForm = FORM_BOTTOM;
			break;
		case 51: // 3
			delayForm = FORM_HORIZONTAL_CENTER;
			break;
		case 52: // 4
			delayForm = FORM_VERTICAL_CENTER;
			break;
		case 53: // 5
			delayForm = FORM_MASK_CENTER_ELLIPSE;
			break;
		case 54: // 6
			delayForm = FORM_MASK_CENTER_RECT;
			break;
	}
}


void movieEvent(Movie m) {
	m.read();
}


// -----------------------------------------------------------------
// SimpleOpenNI events

void onNewUser(SimpleOpenNI curContext, int userId)
{
  println("onNewUser - userId: " + userId);
  println("\tstart tracking skeleton");
  
  curContext.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId)
{
  println("onLostUser - userId: " + userId);
}

void onVisibleUser(SimpleOpenNI curContext, int userId)
{
  //println("onVisibleUser - userId: " + userId);
}
