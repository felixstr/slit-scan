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

static final int FORM_TOP = 0;
static final int FORM_BOTTOM = 1;
static final int FORM_CENTER = 2;

int videoOriginWidth = 640;
int videoOriginHeight = 480;

/**
* KONFIGURATION
*/
int rowHeight = 2; // höhe einer reihe
int frameDelayStep = 1; // frame verzögerung pro reihe
int delayForm = FORM_CENTER;
int currentCam = CAM_INTERN;


void setup() {
	size(640*3/2, 480*3/2);
	frameRate(30);

	switch (currentCam) {
		case CAM_INTERN: 
			video = new Capture(this, videoOriginWidth, videoOriginHeight, 30);
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
	
	// println("frameDelayStep: "+frameDelayStep);
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
		float factor = width / float(videoOriginWidth);
		scale(-factor, factor);
		// scale(-1, 1);
		translate(-videoOriginWidth, 0);

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
	int imageTop = 0;

	if (delayForm == FORM_TOP || delayForm == FORM_BOTTOM) {
		while (top < videoOriginHeight) {
			frameDelay = int(frameNumber - (frameDelayStep * step));
			
			if (frameDelay > 0 && frameBuffer.get(frameDelay) != null) {

				switch (delayForm) {
					case FORM_TOP: 
						imageTop = top;
						break;
					case FORM_BOTTOM: 
						imageTop = videoOriginHeight-top-rowHeight;
						break;
				}
				

				PImage frameImage = frameBuffer.get(frameDelay).get(0, imageTop, videoOriginWidth, rowHeight);

				image(frameImage, 0, imageTop);
			}

			top += rowHeight;
			step++;
		}
	} else if (delayForm == FORM_CENTER) {
		
		while (top < (videoOriginHeight/2)+rowHeight) {
			frameDelay = int(frameNumber - (frameDelayStep * step));
			if (frameDelay > 0 && frameBuffer.get(frameDelay) != null) {

				int imageTop1 = videoOriginHeight/2 - top;
				int imageTop2 = top + videoOriginHeight/2;

				PImage frameImage1 = frameBuffer.get(frameDelay).get(0, imageTop1, videoOriginWidth, rowHeight);
				image(frameImage1, 0, imageTop1);

				PImage frameImage2 = frameBuffer.get(frameDelay).get(0, imageTop2, videoOriginWidth, rowHeight);
				image(frameImage2, 0, imageTop2);
			}

			top += rowHeight;
			step++;
		}

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
