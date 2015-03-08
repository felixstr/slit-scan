import processing.video.*;
import java.util.*;
import SimpleOpenNI.*;

SimpleOpenNI context;

Capture video;
int rowHeight = 5;
float rowDelay = 50;
float frameDelayStep;

boolean topToBottom = false;

int frameNumber = 0;

HashMap<Integer, PImage> frameBuffer = new HashMap<Integer, PImage>();

void setup() {
	size(640*3/2, 480*3/2);

	// init simpleopenni
	context = new SimpleOpenNI(this);
	if (context.isInit() == false) {
		println("Can't init SimpleOpenNI, maybe the camera is not connected!");
		exit();
		return;  
	}
	context.setMirror(false);
	context.enableRGB();
	

	frameDelayStep = (rowDelay/1000)* frameRate;
	println(frameDelayStep);
	
}

void draw() {
	background(0);
	context.update();
	// image(context.rgbImage(), 0, 0);

	readFrame();

	pushMatrix();
		scale(-1.66, 1.66);
		translate(-640, 0);
		drawImage();	

	popMatrix();

	frameNumber++;
	
}	

void readFrame() {
	frameBuffer.put(frameNumber, context.rgbImage().get());
}

void drawImage() {

	// image(frameBuffer.get(frameNumber), 0, 0);

	
	int top = 0;
	int step = 0;
	int frameDelay = 0;

	while (top < height) {
		frameDelay = int(frameNumber - (frameDelayStep * step));
		// println("frameDelay: "+frameDelay);
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
	


	// println("frameBuffer Size: "+frameBuffer.size());


}

void bufferClean(int frameDelay) {
	// anzahlrows * delay
	if (frameBuffer.get(frameDelay-1) != null) {
		ArrayList<Integer> deleteElements = new ArrayList<Integer>();


		Iterator itr = frameBuffer.entrySet().iterator();
		while(itr.hasNext()) {
			Map.Entry mapEntry = (Map.Entry)itr.next();
			int bufferFrameNumber = (Integer)mapEntry.getKey();

			if (bufferFrameNumber < frameDelay-50) {
				deleteElements.add(bufferFrameNumber);
				
			}

		}

		for (int i = 0; i < deleteElements.size(); i++) {
			frameBuffer.remove(deleteElements.get(i));
			// println("deleted: "+deleteElements.get(i));
		}
	}

}
