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

public class slit_scan_v8_kinect extends PApplet {





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
int rowSize = 30; // h\u00f6he einer reihe
int frameDelayStep = 1; // frame verz\u00f6gerung pro reihe
int delayForm = FORM_BOTTOM; 




public void setup() {

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

public boolean sketchFullScreen() { return false; }

public void draw() {
	background(200);

	// updateDelay();
	
	// frame als bild im buffer speichern
	readFrame();

	pushMatrix();
		float factor = width / PApplet.parseFloat(videoOriginWidth);

		scale(-factor, factor);
		translate(-videoOriginWidth, 0);


		// bild zeichnen
		drawImage();	

	popMatrix();

	frameNumber++;
	
}	

public PImage getImage() {
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

    rowSize = PApplet.parseInt(map(nearest, 600, maxDepth, 50, 1));

    println("rowSize: "+rowSize);
    return imageOutput;
    // image(imageOutput, 0, 0);
}

public void readFrame() {
	PImage bufferImage = new PImage();

	context.update();
	getImage();
	bufferImage = context.rgbImage().get();
	
	// bufferImage = getImage();

	frameBuffer.put(frameNumber, bufferImage);
}

public void drawImage() {
	
	
	int top = 0;
	int step = 0;
	int frameDelay = 0;
	int imageTop = 0;

	if (delayForm == FORM_TOP || delayForm == FORM_BOTTOM) {
		while (top < videoOriginHeight) {
			frameDelay = PApplet.parseInt(frameNumber - (frameDelayStep * step));
			
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
			frameDelay = PApplet.parseInt(frameNumber - (frameDelayStep * step));
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
			frameDelay = PApplet.parseInt(frameNumber - (frameDelayStep * step));
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


public void bufferClean(int frameDelay) {

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



  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "slit_scan_v8_kinect" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
