package edu.gatech.ece.fap.flight.vision;

import java.io.BufferedWriter;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import edu.gatech.ece.fap.flight.R;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.graphics.PixelFormat;
import android.hardware.Camera;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore.Images;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.view.View.OnClickListener;
import android.widget.Toast;

public class ImageCapture extends Activity implements SurfaceHolder.Callback, OnClickListener
{
	private SurfaceView mSurfaceView;
	private SurfaceHolder mSurfaceHolder;
	private Camera mCamera;
	private boolean mPreviewRunning;
	private int pictureNum;
	private String flightTime;

	private LocationManager lm;
	private LocationListener locationListener;
	private Location location;
	
	private List<Waypoint> waypoints;
	
	String root;
	String rootForGPS;
	
	private ContentResolver mContentResolver;
	private static final Uri STORAGE_URI = Images.Media.EXTERNAL_CONTENT_URI;
	  
	private class Waypoint {
		private double latitude;
		private double longitude;
		
		public Waypoint(double latitude, double longitude)
		{
			this.latitude = latitude;
			this.longitude = longitude;
		}
	}
	
	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		getWindow().setFormat(PixelFormat.TRANSLUCENT);
		requestWindowFeature(Window.FEATURE_NO_TITLE);
		//We want to see the GPS icon so we can't make it completely fullscreen.
		getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
		setContentView(R.layout.image_capture);

		pictureNum = 0;
		
		//Initialize list of waypoints we check to see if we should take a picture
		waypoints = new ArrayList<Waypoint>();
		waypoints.add(new Waypoint(32.36747682094574, -84.81361091136932));
		
		//Sets up the surface view that holds the preview of what the camera sees
		mSurfaceView = (SurfaceView) findViewById(R.id.surface_camera);
		mSurfaceHolder = mSurfaceView.getHolder();
		mSurfaceHolder.addCallback(this);
		mSurfaceHolder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
		
		//Initializes the manager and listener for the GPS service
		lm = (LocationManager)getSystemService(Context.LOCATION_SERVICE);
		locationListener = new MyLocationListener();
		lm.requestLocationUpdates(LocationManager.GPS_PROVIDER, 0, 0, locationListener);

		root = Environment.getExternalStorageDirectory().getAbsolutePath();
		rootForGPS = Environment.getExternalStorageDirectory().getAbsolutePath();
		
		mContentResolver = getContentResolver();
		
		mSurfaceView.setOnClickListener(this);
	}

	public void surfaceCreated(SurfaceHolder holder) {
		mCamera = Camera.open();
		flightTime = "" + System.currentTimeMillis();
		BufferedWriter gpxStream;
		try {
			gpxStream = new BufferedWriter(new FileWriter(rootForGPS + "/" + flightTime + ".gpx"));
			gpxStream.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
			gpxStream.write("<gpx version=\"1.1\"\n");
			gpxStream.write("	 creator=\"Flying Android Project - http://www.flyingandroid.com\"\n");
			gpxStream.write("	 xmlns=\"http://www.topografix.com/GPX/1/1\"\n");
			gpxStream.write("	 xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n");
			gpxStream.write("	 xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\">\n");
			gpxStream.flush();
			gpxStream.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		//Use to scale the size of the picture the camera takes
		//Doesn't speed up operation at all
		/*Camera.Parameters p = mCamera.getParameters();	  
		Camera.Size size = p.getPictureSize();
		p.setPictureSize(size.width/2, size.height/2);
		mCamera.setParameters(p);*/
	}

	public void surfaceChanged(SurfaceHolder holder, int format, int w, int h) {
		if (mPreviewRunning) {
			mCamera.stopPreview();
		}
		Camera.Parameters p = mCamera.getParameters();		
		
		p.setPreviewSize(w, h);
		mCamera.setParameters(p);
		
		try {
			mCamera.setPreviewDisplay(holder);
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		mCamera.startPreview();
		mPreviewRunning = true;
	}

	public void surfaceDestroyed(SurfaceHolder holder) {
		mCamera.stopPreview();
		mPreviewRunning = false;
		mCamera.release();
		BufferedWriter gpxStream;
		try {
			gpxStream = new BufferedWriter(new FileWriter(rootForGPS + "/" + flightTime + ".gpx", true));
			gpxStream.write("</gpx>\n");
			gpxStream.flush();
			gpxStream.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	Camera.PictureCallback mPictureCallback = new Camera.PictureCallback() {
		public void onPictureTaken(byte[] imageData, Camera c) {
			try {
				Log.v(TAG, "Picture Taken");
				Date time = new Date(System.currentTimeMillis() + 6*60*60*1000);
				SimpleDateFormat date = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
				StringBuilder timeString = new StringBuilder(date.format(time));
				//Store the picture to the SD card
				FileOutputStream stream = new FileOutputStream(rootForGPS + "/" + pictureNum + ".jpeg");
				stream.write(imageData);
				stream.flush();
				stream.close();
				Log.v(TAG, "Picture Stored");

				if(location != null)
				{
					BufferedWriter gpxStream = new BufferedWriter(new FileWriter(rootForGPS + "/" + flightTime + ".gpx", true));
					gpxStream.write("   <wpt lat=\"" + location.getLatitude() + "\" lon=\"" + location.getLongitude() + "\">\n");
					gpxStream.write("      <ele>" + location.getAltitude() + "</ele>\n");
					gpxStream.write("      <time>" + timeString + "</time>\n");
					gpxStream.write("      <name>" + pictureNum + ".jpeg</name>\n");
					gpxStream.write("      <cmt>" + pictureNum + ".jpeg</cmt>\n");
					gpxStream.write("      <desc>" + pictureNum + ".jpeg</desc>\n");
					gpxStream.write("   </wpt>\n");
					gpxStream.flush();
					gpxStream.close();
				}
				
				/*
				// Stores GPS coords in a content resolver local to the phone
				ContentValues values = new ContentValues();
				values.put(Images.Media.TITLE, "Image" + pictureNum);
				if(location != null)
				{
					values.put(Images.Media.LATITUDE, location.getLatitude());
					values.put(Images.Media.LONGITUDE, location.getLongitude());
				}
				mContentResolver.insert(STORAGE_URI, values);
				
				long gpsTime = System.currentTimeMillis();
				
				//Along with it write the current GPS coordinates for geotagging
				FileWriter gpsWriter = new FileWriter(rootForGPS + "/testpics/GPSdata.txt", true);
				gpsWriter.write(gpsTime + "\n" + pictureNum + "; " 
						+ location.getLatitude() + "; " 
						+ location.getLongitude() + "\n");
				gpsWriter.flush();
				gpsWriter.close();
				*/
				Log.v(TAG, "GPS Taken");
				
				pictureNum++;
			}
			catch(Exception e) { 
				Log.v(TAG, e.toString()); 
			}
		}
   	};
   	
	private class MyLocationListener implements LocationListener {
		//This will pop up a box showing the current long and lat whenever it changes
		public void onLocationChanged(Location loc) {
			if (loc != null) {
				location = loc;
				Toast.makeText(getBaseContext(), 
					"Location changed : Lat: " + loc.getLatitude() + 
					" Lng: " + loc.getLongitude(), 
					Toast.LENGTH_SHORT).show();
			}
		}

		//@Override
		public void onProviderDisabled(String provider) {
			// TODO Auto-generated method stub
		}

		//@Override
		public void onProviderEnabled(String provider) {
			// TODO Auto-generated method stub
		}

		//@Override
		public void onStatusChanged(String provider, int status, 
			Bundle extras) {
			// TODO Auto-generated method stub
		}
	}

	public void onClick(View v) {
		Runnable camRunnable = new Runnable() {
			public void run()
			{
				while(true)
				{
					if(location != null)
					{
						//Waypoint checking is currently disabled due to infrequent GPS updates
						/*Iterator<Waypoint> itr = waypoints.iterator(); 
						while(itr.hasNext())
						{
							Waypoint currentWaypoint = itr.next();
							//TODO: Adjust lat and lng tolerated variance
							//At a latitude of 32.34997
							//Length Of A Degree Of Latitude In Meters:  110892.93
							//Length Of A Degree Of Longitude In Meters: 94132.43
							if(Math.abs(location.getLatitude() - currentWaypoint.latitude) < 10.0/110893.93 &&
							   Math.abs(location.getLongitude() - currentWaypoint.longitude) < 10.0/94132.43)
							{*/

								if (mPreviewRunning)
								{
									mCamera.stopPreview();
								}
								mCamera.takePicture(null, null, mPictureCallback);
								Log.v("CameraCaptureThread", "Picture Taken: " + pictureNum); 
								mCamera.startPreview();
						/*	}
						}*/
					}
					try {
						//Wait a bit before taking the next picture
						Thread.sleep(2000);
					} catch (InterruptedException e) {
						e.printStackTrace();
						Log.v("CameraCaptureThread", "Interrupted Exception");
					}
				}
			}
		};
	
		//We don't want to start more than one picture taking thread so disable the click listener
		mSurfaceView.setOnClickListener(null);
		
		//Start the thread for taking pictures
		Thread camThread = new Thread(camRunnable);
		camThread.start();
	}
/*
	@Override
	public boolean onKeyDown(int keyCode, KeyEvent event) {
		// We don't any button presses to interfere with operation so stop their propagation
		return false;
	}*/

	private static final String TAG = "ImageCapture";
}
