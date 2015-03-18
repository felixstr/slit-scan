import processing.video.*;
import java.util.*;
import SimpleOpenNI.*;

SimpleOpenNI context;
Capture video;
Movie myMovie;

PGraphics mask;

int frameNumber = 0;
HashMap<Integer, PImage> frameBuffer = new HashMap<Integer, PImage>();

static final int FORM_TOP = 0;
static final int FORM_BOTTOM = 1;
static final int FORM_CENTER = 2;
static final int FORM_VERTICAL_LEFT = 3;
static final int FORM_MASK_CENTER = 4;

int videoOriginWidth = 640;
int videoOriginHeight = 480;


/**
* KONFIGURATION
*/
int rowSize = 30; // höhe einer reihe
int frameDelayStep = 1; // frame verzögerung pro reihe
int delayForm = FORM_BOTTOM; 




void setup() {

	frameRate(30); // ???

	context = new SimpleOpenNI(this);
	if (context.isInit() == false) {
		println("Can't init SimpleOpenNI, maybe the camera is not connected!");
		exit();
		return;  
	}
	context.setMirror(false);
	context.enableRGB();
	context.enableDepth();

	size(videoOriginWidth*3/2, videoOriginHeight*3/2, P2D);
	// size(displayWidth, displayHeight, P2D);
	
	// println("frameDelayStep: "+frameDelayStep);
}

boolean sketchFullScreen() { return false; }

void draw() {
	background(200);

	// updateDelay();
	
	// frame als bild im buffer speichern
	readFrame();

	pushMatrix();
		float factor = width / float(videoOriginWidth);

		scale(-factor, factor);
		translate(-videoOriginWidth, 0);


		// bild zeichnen
		drawImage();	

	popMatrix();

	frameNumber++;
	
}	

PImage getImage() {
	context.update();
	context.alternativeViewPointDepthToImage();

	int[] depthMap = context.depthMap();
	PImage image = context.rgbImage();
	PImage imageOutput = createImage(image.width, image.height, ARGB);
	int index;
	// println(depthMap);
	int maxDepth = 1500;
	int nearest = 0;
	for(int x=0; x < depthMap.length; x++) {
   		if (depthMap[x] > 600 && depthMap[x] < maxDepth) {
   			imageOutput.pixels[x] = image.pixels[x];
   			if (nearest == 0 || depthMap[x] < nearest) {
   				nearest = depthMap[x];
   			}
   		}

    }


    rowSize = int(map(nearest, 600, maxDepth, 50, 1));

    println("rowSize: "+rowSize);
    return imageOutput;
    // image(imageOutput, 0, 0);
}

void readFrame() {
	PImage bufferImage = new PImage();

	context.update();
	getImage();
	bufferImage = context.rgbImage().get();
	
	// bufferImage = getImage();

	frameBuffer.put(frameNumber, bufferImage);
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
						imageTop = videoOriginHeight-top-rowSize;
						break;
				}
				

				PImage frameImage = frameBuffer.get(frameDelay).get(0, imageTop, videoOriginWidth, rowSize);

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


void bufferClean(int frameDelay) {

	if (frameBuffer.get(frameDelay-1) != null) {
		ArrayList<Integer> deleteElements = new ArrayList<Integer>();


		Iterator itr = frameBuffer.entrySet().iterator();
		while(itr.hasNext()) {
			Map.Entry mapEntry = (Map.Entry)itr.next();
			int bufferFrameNumber = (Integer)mapEntry.getKey();

			if (bufferFrameNumber < frameDelay-400) {
				deleteElements.add(bufferFrameNumber);
				
			}

		}

		for (int i = 0; i < deleteElements.size(); i++) {
			frameBuffer.remove(deleteElements.get(i));
		}
	}

}



