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

static final int FORM_TOP = 0;
static final int FORM_BOTTOM = 1;
static final int FORM_CENTER = 2;
static final int FORM_VERTICAL_LEFT = 3;
static final int FORM_MASK_CENTER = 4; // doesnt work yet

int videoOriginWidth = 1280;
int videoOriginHeight = 720;

int videoOutputWidth;
int videoOutputHeight;

int windowWidth;
int windowHeight;


/**
* KONFIGURATION
*/
int rowSize = 20; // höhe einer reihe
int frameDelayStep = 1; // frame verzögerung pro reihe
int currentInput = INPUT_INTERN;
int delayForm = FORM_BOTTOM; 



void setup() {

	frameRate(120); // ???

	switch (currentInput) {
		case INPUT_INTERN: 
			println(Capture.list());
			video = new Capture(this, videoOriginWidth, videoOriginHeight, 30);
			video.start();
			break;

		case INPUT_KINECT:
			context = new SimpleOpenNI(this);
			if (context.isInit() == false) {
				println("Can't init SimpleOpenNI, maybe the camera is not connected!");
				exit();
				return;  
			}
			context.setMirror(false);
			context.enableRGB();
			// context.enableUser();
			break;

		case INPUT_VIDEO: 
			myMovie = new Movie(this, "Under One_ Amanda MacLeod. Vernon Ave Brooklyn NY-HD.mp4");
			videoOriginWidth = 1280/3*2;
			videoOriginHeight = 720/3*2;
  			myMovie.loop();
		break;
	}	

	// size(videoOriginWidth*3/2, videoOriginHeight*3/2, P2D);
	// float factor = float(displayHeight)/float(videoOriginHeight);
	// size(displayWidth, displayHeight, P2D);
	// size(int(videoOriginWidth*factor), displayHeight, P2D);

	// windowWidth = 3240;
	// windowHeight = 1960;
	windowWidth = 1500;
	windowHeight = 720;

	size(windowWidth, windowHeight, P2D);

	videoOutputWidth = windowWidth;
	videoOutputHeight = int(videoOriginWidth*(float(windowHeight)/float(windowWidth)));

	mask = createGraphics(videoOutputWidth, videoOutputHeight, P2D);
	
	// println("frameDelayStep: "+frameDelayStep);
}

boolean sketchFullScreen() { return false; }

void draw() {
	background(255);
	// frame.setLocation(-2160,0); 
	frame.setLocation(0,0); 

	// frame als bild im buffer speichern
	readFrame();

	pushMatrix();
		float factor = width / float(videoOriginWidth);
		if (currentInput == INPUT_VIDEO) {
			scale(factor, factor);
		} else {
			scale(-factor, factor);
			translate(-videoOriginWidth, 0);
		}

		// bild zeichnen
		drawImage();	

	popMatrix();

	frameNumber++;
	
}	

void readFrame() {
	PImage bufferImage = new PImage();

	switch (currentInput) {
		case INPUT_INTERN: 
			if (video.available()) {
				video.read();
			}
			
			video.loadPixels();

			bufferImage = video.get();
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
	bufferImage = bufferImage.get(0,0, videoOutputWidth, videoOutputHeight);
	frameBuffer.put(frameNumber, bufferImage);
}

void drawImage() {
	// image(frameBuffer.get(frameNumber), 0, 0);
	
	int top = 0;
	int step = 0;
	int frameDelay = 0;
	int imageTop = 0;

	if (delayForm == FORM_MASK_CENTER) {
		
		while (top < videoOriginWidth) {
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
	} else if (delayForm == FORM_CENTER) {
		
		while (top < (videoOriginHeight/2)+rowSize) {
			frameDelay = int(frameNumber - (frameDelayStep * step));
			if (frameDelay > 0 && frameBuffer.get(frameDelay) != null) {

				int imageTop1 = videoOriginHeight/2 - top;
				int imageTop2 = top + videoOriginHeight/2;

				PImage frameImage1 = frameBuffer.get(frameDelay).get(0, imageTop1, videoOriginWidth, rowSize);
				image(frameImage1, 0, imageTop1);

				PImage frameImage2 = frameBuffer.get(frameDelay).get(0, imageTop2, videoOriginWidth, rowSize);
				image(frameImage2, 0, imageTop2);
			}

			top += rowSize;
			step++;
		}

	} else if (delayForm == FORM_VERTICAL_LEFT) {
		
		int left = 0;
		int imageLeft = 0;

		while (left < videoOriginWidth) {
			frameDelay = int(frameNumber - (frameDelayStep * step));
			if (frameDelay > 0 && frameBuffer.get(frameDelay) != null) {

				imageLeft = left;

				PImage frameImage = frameBuffer.get(frameDelay).get(imageLeft, 0, rowSize, videoOriginHeight);
				image(frameImage, imageLeft, 0);
			}

			left += rowSize;
			step++;
		}

	}



	bufferClean(frameDelay);

}

PImage mask(int frameDelay, int top) {
	PImage frameImage = frameBuffer.get(frameDelay);

	// println(videoOutputWidth);
	// create mask

	mask.beginDraw();

	mask.background(0);
	mask.noStroke();
	mask.fill(255);
	mask.smooth();
	mask.ellipse(videoOutputWidth/2,0,300,300);
	// mask.ellipse(20,20,rowSize+top,rowSize+top);

	// mask.fill(0);
	// mask.ellipse(mask.width/2,mask.height/2,top-2,top-2);
	mask.endDraw();

	frameImage.mask( mask.get() );


	return frameImage;

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
	}
}


void movieEvent(Movie m) {
	m.read();
}
