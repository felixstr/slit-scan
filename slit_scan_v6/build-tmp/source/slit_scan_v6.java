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

public class slit_scan_v6 extends PApplet {





SimpleOpenNI context;
Capture video;
Movie myMovie;

int frameNumber = 0;
HashMap<Integer, PImage> frameBuffer = new HashMap<Integer, PImage>();

static final int INPUT_INTERN = 0;
static final int INPUT_KINECT = 1;
static final int INPUT_VIDEO = 2;

static final int FORM_TOP = 0;
static final int FORM_BOTTOM = 1;
static final int FORM_CENTER = 2;
static final int FORM_VERTICAL_LEFT = 3;

int videoOriginWidth = 640;
int videoOriginHeight = 480;

PImage backgroundImage;

/**
* KONFIGURATION
*/
int rowSize = 2; // h\u00f6he einer reihe
int frameDelayStep = 8; // frame verz\u00f6gerung pro reihe
int delayForm = FORM_BOTTOM; 
int currentInput = INPUT_VIDEO;


public void setup() {
	
	frameRate(30);

	switch (currentInput) {
		case INPUT_INTERN: 
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
			myMovie = new Movie(this, "Amanda.mp4");
			videoOriginWidth = 1280/3*2;
			videoOriginHeight = 720/3*2;

  			myMovie.play();
		break;
	}	

	size(videoOriginWidth*3/2, videoOriginHeight*3/2);
	
	backgroundImage = new PImage(videoOriginWidth, videoOriginHeight);
	// println("frameDelayStep: "+frameDelayStep);
}

public void draw() {
	background(255);

	// frame als bild im buffer speichern
	readFrame();

	pushMatrix();
		float factor = width / PApplet.parseFloat(videoOriginWidth);
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

public void readFrame() {
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

	// bufferImage = deleteBackground(bufferImage);

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

			if (bufferFrameNumber < frameDelay-frameDelayStep) {
				deleteElements.add(bufferFrameNumber);
				
			}

		}

		for (int i = 0; i < deleteElements.size(); i++) {
			frameBuffer.remove(deleteElements.get(i));
		}
	}

}

public PImage deleteBackground(PImage bufferImage) {
	PImage returnImage = new PImage(bufferImage.width, bufferImage.height);

	// println(bufferImage.pixels);
	// println(returnImage.pixels);

	for (int y = 0; y < bufferImage.height; y++) {
		for (int x = 0; x < bufferImage.width; x++) {

			int loc = x + y * bufferImage.width;
			int fgColor = bufferImage.pixels[loc];
			int bgColor = backgroundImage.pixels[loc];

			float r1 = red(fgColor);
			float g1 = green(fgColor);
			float b1 = blue(fgColor);
			float r2 = red(bgColor);
			float g2 = green(bgColor);
			float b2 = blue(bgColor);
			float diff = dist(r1,g1,b1,r2,g2,b2);

			// println(loc);
			
			if (backgroundImage.pixels.length > 0 && diff < 30) {
				returnImage.pixels[loc] = color(20);
			} else {
				returnImage.pixels[loc] = bufferImage.pixels[loc];
			}

		}
	}

	return returnImage;
}

public void keyPressed() {
	switch (key) {
		case 'b':
			
			switch (currentInput) {
				case INPUT_INTERN: 
					backgroundImage = video.get();
					break;

				case INPUT_KINECT:
					backgroundImage = context.rgbImage().get();
					break;
			}	


			break;
		case ' ': 
			myMovie.jump(0);
			break;
		
	}
}

public void movieEvent(Movie m) {
	m.read();
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "slit_scan_v6" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
