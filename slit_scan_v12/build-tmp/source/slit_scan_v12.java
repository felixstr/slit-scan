import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.video.*; 
import java.util.*; 
import SimpleOpenNI.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class slit_scan_v12 extends PApplet {





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


/**
* KONFIGURATION
*/
int rowSize = 20; // h\u00f6he einer reihe
int frameDelayStep = 1; // frame verz\u00f6gerung pro reihe
int currentInput = INPUT_INTERN;
int delayForm = FORM_VERTICAL_CENTER; 

boolean measureDepth = false;


public void setup() {

	frameRate(20); 

	switch (currentInput) {
		case INPUT_LOGITECH: 
			videoOriginWidth = 1920/logitechResizeFactor;
			videoOriginHeight = 1080/logitechResizeFactor;

			video = new Capture(this, 1920, 1080, "HD Pro Webcam C920", 15);
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

			
			// context.enableUser();
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
	}

	// windowWidth = displayWidth;
	// windowHeight = displayHeight;
	// windowWidth = 3240;
	// windowHeight = 1960;
	windowWidth = 960;
	windowHeight = 540;
	// windowWidth = displayWidth;
	// windowHeight = displayHeight;

	size(windowWidth, windowHeight, P2D);

	calcVideoSize();

	mask = createGraphics(videoOutputWidth, videoOutputHeight, P2D);
	
}

public boolean sketchFullScreen() { return false; }

public void calcVideoSize() {
	
	if (PApplet.parseFloat(windowWidth)/PApplet.parseFloat(windowHeight) > PApplet.parseFloat(videoOriginWidth)/PApplet.parseFloat(videoOriginHeight)) {
		videoOutputWidth = videoOriginWidth;
		videoOutputHeight = PApplet.parseInt(videoOriginWidth*(PApplet.parseFloat(windowHeight)/PApplet.parseFloat(windowWidth)));
	} else {
		videoOutputWidth = PApplet.parseInt(videoOriginHeight*(PApplet.parseFloat(windowWidth)/PApplet.parseFloat(windowHeight)));
		videoOutputHeight = videoOriginHeight;
	}

	println(videoOutputWidth);
	println(videoOutputHeight);
}

public void draw() {
	background(255);
	// frame.setLocation(-2160,0); 
	if (frameNumber < 20) {
		frame.setLocation(0,0); 
	}

	// measureDepth
	if (measureDepth) {
		updateDepth();
	}

	// frame als bild im buffer speichern
	readFrame();
	println(frameRate);

	// image(frameBuffer.get(frameNumber), 0, 0);

	pushMatrix();
		float factor = PApplet.parseFloat(windowWidth) / PApplet.parseFloat(videoOutputWidth);
		if (currentInput == INPUT_VIDEO) {
			scale(factor, factor);
		} else {
			scale(-factor, factor);
			translate(-videoOutputWidth, 0);
		}

		// bild zeichnen
		drawImage();	

	popMatrix();

	frameNumber++;
	
}	

public void readFrame() {
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
	bufferImage = bufferImage.get(PApplet.parseInt((videoOriginWidth - videoOutputWidth)/2) ,0, videoOutputWidth, videoOutputHeight);
	frameBuffer.put(frameNumber, bufferImage);
}

public void drawImage() {
	// image(frameBuffer.get(frameNumber), 0, 0);
	
	int top = 0;
	int step = 0;
	int frameDelay = 0;
	int imageTop = 0;

	if (delayForm == FORM_NONE) {
		frameDelay = PApplet.parseInt(frameNumber);
		image(frameBuffer.get(frameDelay), 0, 0);
	} if (delayForm == FORM_MASK_CENTER_ELLIPSE || delayForm == FORM_MASK_CENTER_RECT) {
		
		while (top < videoOutputWidth) {
			frameDelay = PApplet.parseInt(frameNumber - (frameDelayStep * step));

			if (frameDelay > 0 && frameBuffer.get(frameDelay) != null) {
				PImage frameImage = mask(frameDelay, top);
				image(frameImage, 0, 0);
			}

			top += rowSize;
			step++;
		}

	} else if (delayForm == FORM_TOP || delayForm == FORM_BOTTOM) {
		while (top < videoOutputHeight) {
			frameDelay = PApplet.parseInt(frameNumber - (frameDelayStep * step));
			
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
			frameDelay = PApplet.parseInt(frameNumber - (frameDelayStep * step));
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
			frameDelay = PApplet.parseInt(frameNumber - (frameDelayStep * step));
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
			frameDelay = PApplet.parseInt(frameNumber - (frameDelayStep * step));
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

public void updateDepth() {
	context.update();
	context.alternativeViewPointDepthToImage();

	int[] depthMap = context.depthMap();
	int maxDepth = 1500;
	int nearest = 0;
	for(int x=0; x < depthMap.length; x++) {
   		if (depthMap[x] > 600 && depthMap[x] < maxDepth) {
   			if (nearest == 0 || depthMap[x] < nearest) {
   				nearest = depthMap[x];
   			}
   		}
    }

    println(nearest);

    if (nearest < 1000) {
    	rowSize = 50;
		frameDelayStep = 2;
    } else if (nearest < 2000) {
    	rowSize = 20;
		frameDelayStep = 1;
    } else if (nearest < 3000) {
    	rowSize = 10;
		frameDelayStep = 1;
    }

}

public PImage mask(int frameDelay, int top) {
	PImage frameImage = frameBuffer.get(frameDelay);

	// println(videoOutputWidth);
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

public void bufferClean(int frameDelay) {
	int limitClean = (videoOutputHeight/rowSize)*frameDelayStep;

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

public void keyPressed() {
	println(keyCode);
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

		case 49: 
		 	rowSize = 50;
			frameDelayStep = 2;
		 	break;
		case 50: 
			rowSize = 30;
			frameDelayStep = 1;
			break;
		case 51: 
			rowSize = 10;
			frameDelayStep = 1;
			break;
	}
}


public void movieEvent(Movie m) {
	m.read();
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "slit_scan_v12" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
