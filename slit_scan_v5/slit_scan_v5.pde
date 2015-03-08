import processing.video.*;
import java.util.*;
import SimpleOpenNI.*;

SimpleOpenNI context;
Capture video;

int frameNumber = 0;
HashMap<Integer, PImage> frameBuffer = new HashMap<Integer, PImage>();

static final int CAM_INTERN = 0;
static final int CAM_KINECT = 1;
static final int CAM_EXTERN = 2;

/**
* KONFIGURATION
*/
int rowHeight = 5; // höhe einer reihe
int frameDelayStep = 1; // frame verzögerung pro reihe
boolean topToBottom = true;
int currentCam = CAM_KINECT;


void setup() {
	size(640*3/2, 480*3/2);
	frameRate(30);

	switch (currentCam) {
		case CAM_INTERN: 
			video = new Capture(this, 640, 480, 30);
			video.start();
			break;

		case CAM_KINECT:
			context = new SimpleOpenNI(this);
			if (context.isInit() == false) {
				println("Can't init SimpleOpenNI, maybe the camera is not connected!");
				exit();
				return;  
			}
			context.setMirror(false);
			context.enableRGB();
			break;
	}	
	
	println("frameDelayStep: "+frameDelayStep);
}

void draw() {
	background(0);

	switch (currentCam) {
		case CAM_INTERN: 
			if (video.available()) {
				video.read();
			}
			
			video.loadPixels();
			break;

		case CAM_KINECT:
			context.update();
			break;
	}
	
	// frame als bild im buffer speichern
	readFrame();

	pushMatrix();
		scale(-1.66, 1.66);
		// scale(-1, 1);
		translate(-640, 0);

		// bild zeichnen
		drawImage();	

	popMatrix();

	frameNumber++;
	
}	

void readFrame() {
	switch (currentCam) {
		case CAM_INTERN: 
			frameBuffer.put(frameNumber, video.get());
			break;

		case CAM_KINECT:
			frameBuffer.put(frameNumber, context.rgbImage().get());
			break;
	}
}

void drawImage() {
	
	
	int top = 0;
	int step = 0;
	int frameDelay = 0;

	while (top < height) {
		frameDelay = int(frameNumber - (frameDelayStep * step));
		
		if (frameDelay > 0 && frameBuffer.get(frameDelay) != null) {
			int imageTop = top;
			if (!topToBottom) {
				imageTop = height-top-rowHeight;
			}

			PImage frameImage = frameBuffer.get(frameDelay).get(0, imageTop, width, rowHeight);

			image(frameImage, 0, imageTop);
		}

		top += rowHeight;
		step++;
	}

	bufferClean(frameDelay);

}

void bufferClean(int frameDelay) {

	if (frameBuffer.get(frameDelay-1) != null) {
		ArrayList<Integer> deleteElements = new ArrayList<Integer>();


		Iterator itr = frameBuffer.entrySet().iterator();
		while(itr.hasNext()) {
			Map.Entry mapEntry = (Map.Entry)itr.next();
			int bufferFrameNumber = (Integer)mapEntry.getKey();

			if (bufferFrameNumber < frameDelay-frameDelayStep) {
				deleteElements.add(bufferFrameNumber);
				
			}

		}

		for (int i = 0; i < deleteElements.size(); i++) {
			frameBuffer.remove(deleteElements.get(i));
		}
	}

}
