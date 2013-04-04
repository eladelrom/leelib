package recorder
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import mx.formatters.DateFormatter;
	
	import leelib.util.flvEncoder.ByteArrayFlvEncoder;
	import leelib.util.flvEncoder.FileStreamFlvEncoder;
	import leelib.util.flvEncoder.FlvEncoder;
	import leelib.util.flvEncoder.VideoPayloadMakerAlchemy;
	
	import recorder.model.RecordVO;
	
	public class RecorderHelper
	{
		public static var recordVO:RecordVO;
		private static var streamingFile:File = null;
		
		public static function captureToFile(recordVO:RecordVO=null):void {
			if (recordVO)
				RecorderHelper.recordVO = recordVO;
			
			if (streamingFile == null)
				initFileStreaming('video_'+currentDateTimeString()+'.flv');
			
			RecorderHelper.addBytesToStreamingFile( captureImage() );
			scheduleNextCaptureFrame(captureToFile);			
		}
		
		private static function currentDateTimeString():String
		{               
			var currentDateTime:Date = new Date();
			var currentDF:DateFormatter = new DateFormatter();
			currentDF.formatString = "LL_NN_SS"
			var dateTimeString:String = currentDF.format(currentDateTime);
			return dateTimeString;
		}
		
		public static function captureToMemory(recordVO:RecordVO=null):void
		{
			if (recordVO)
				RecorderHelper.recordVO = recordVO;
			
			var bitmapData:BitmapData = captureImage();
			RecorderHelper.recordVO.bitmaps.push(bitmapData);
			
			scheduleNextCaptureFrame(captureToMemory);
		}
		
		public static function captureImage():BitmapData 
		{
			if (!RecorderHelper.recordVO.encodeVideo)
				return null;
			
			var bitmapData:BitmapData = new BitmapData(RecorderHelper.recordVO.outputWidth,RecorderHelper.recordVO.outputHeight,false,0x0);
			bitmapData.draw(RecorderHelper.recordVO.container);	
			
			return bitmapData;
		}
		
		public static function scheduleNextCaptureFrame(callBack:Function):void {
			
			var sec:int = int( RecorderHelper.recordVO.totalFramesRecorded / RecorderHelper.recordVO.flvFramerate);
			var encodeBitmapsSecond:String = 'Recording: ' + sec;
			
			if (RecorderHelper.recordVO.outputCallBackFunction != null)
				RecorderHelper.recordVO.outputCallBackFunction(encodeBitmapsSecond);			
			
			RecorderHelper.recordVO.totalFramesRecorded++;
			var elapsedMs:int = getTimer() - RecorderHelper.recordVO.startTime;
			var nextMs:int = (RecorderHelper.recordVO.totalFramesRecorded / RecorderHelper.recordVO.flvFramerate) * 1000;
			var deltaMs:int = nextMs - elapsedMs;
			
			if (deltaMs < 10) 
				deltaMs = 10;
			
			RecorderHelper.recordVO.timeoutId = setTimeout(callBack, deltaMs);			
		}
		
		public static function initFileStreaming(fileName:String='video.flv'):void {
			
			streamingFile = File.documentsDirectory.resolvePath(fileName);
			RecorderHelper.recordVO.fsFlvEncoder = new FileStreamFlvEncoder(streamingFile, RecorderHelper.recordVO.flvFramerate);
			
			RecorderHelper.recordVO.fsFlvEncoder.fileStream.openAsync(streamingFile, FileMode.UPDATE);
			
			// video
			if (RecorderHelper.recordVO.encodeVideo)
				RecorderHelper.recordVO.fsFlvEncoder.setVideoProperties(recordVO.outputWidth,recordVO.outputHeight, VideoPayloadMakerAlchemy);	
			
			// audio
			if (RecorderHelper.recordVO.encodeAudio)
				RecorderHelper.recordVO.fsFlvEncoder.setAudioProperties(FlvEncoder.SAMPLERATE_44KHZ, true, false, true);			
			
			RecorderHelper.recordVO.fsFlvEncoder.start();
			RecorderHelper.recordVO.encodeFrameNum = 1;
		}
		
		public static function addBytesToStreamingFile(bitmapData:BitmapData):void {
			
			var micByteArray:ByteArray = null;
			var audioFrameSize:uint = RecorderHelper.recordVO.fsFlvEncoder.audioFrameSize;
			
			// audio
			if (RecorderHelper.recordVO.encodeAudio)
			{
				micByteArray = new ByteArray();
				var posEnd:uint = RecorderHelper.recordVO.encodeFrameNum * audioFrameSize;
				var posStart:uint = posEnd-audioFrameSize;
				micByteArray = RecorderHelper.recordVO.micUtil.clone(RecorderHelper.recordVO.micUtil.byteArray);
				
				if (posStart < 0 || micByteArray.length < posEnd) {
					trace("SILENCE:: Position Start: " + posStart + ", position ends: " + posEnd + ", micByteArray.length: " + micByteArray.length);
					RecorderHelper.recordVO.micUtil.insertSilence(audioFrameSize);
					micByteArray.writeBytes(RecorderHelper.recordVO.micUtil.byteArray, 0, audioFrameSize);
				}
				else {
					//trace("Position Start: " + posStart + ", position ends: " + posEnd + ", micByteArray.length: " + micByteArray.length);
					micByteArray.position = 0;
					try {
						micByteArray.writeBytes(micByteArray, posStart, audioFrameSize);
					} catch (error:Error) {
						trace('error: ' + micByteArray.length);
					}
					
					if (RecorderHelper.recordVO.encodeFrameNum > 50) {
						// cleanup
						trace('---------------------------'+ System.freeMemory +'----------------------------------------');
						trace("size before: " + RecorderHelper.recordVO.micUtil.byteArray.length);
						trace("Position Start: " + posStart + ", position ends: " + posEnd + ", byteArray.length: " + RecorderHelper.recordVO.micUtil.byteArray.length);
						RecorderHelper.recordVO.micUtil.shift(posStart,audioFrameSize);
						RecorderHelper.recordVO.encodeFrameNum = 1;
						trace("size after: " + RecorderHelper.recordVO.micUtil.byteArray.length);
					}
					else {
						RecorderHelper.recordVO.encodeFrameNum++;
					}
				}
			}
			
			RecorderHelper.recordVO.fsFlvEncoder.addFrame(bitmapData, micByteArray);
			
			// clean up
			if (RecorderHelper.recordVO.encodeVideo) {
				bitmapData.dispose();
				bitmapData = null;
			}
			
			if (RecorderHelper.recordVO.encodeAudio) {
				micByteArray.clear();
				micByteArray = null;
			}
			
			// clean gc for AIR apps
			System.gc();
			System.gc();
		}
		
		public static function closeFile():void {
			
			if (RecorderHelper.recordVO.encodeAudio) {
				RecorderHelper.recordVO.micUtil.stop();
			}
			
			RecorderHelper.recordVO.fsFlvEncoder.updateDurationMetadata();
			RecorderHelper.recordVO.fsFlvEncoder.fileStream.close();
			
			if (RecorderHelper.recordVO.encodeVideo)
				RecorderHelper.recordVO.fsFlvEncoder.kill();				
		}
		
		public static function startEncoding():void
		{
			RecorderHelper.recordVO.micUtil.stop();
			
			// Make FlvEncoder object
			RecorderHelper.recordVO.byteArrayFlvEncoder = new ByteArrayFlvEncoder(RecorderHelper.recordVO.flvFramerate);
			
			if (RecorderHelper.recordVO.encodeVideo) 
			{
				// Old way: 
				// RecorderHelper.recordVO.byteArrayFlvEncoder.setVideoProperties(RecorderHelper.recordVO.outputWidth,RecorderHelper.recordVO.outputHeight);
				
				// alchemy way:
				RecorderHelper.recordVO.byteArrayFlvEncoder.setVideoProperties(recordVO.outputWidth,recordVO.outputHeight, VideoPayloadMakerAlchemy);
			}
			if (RecorderHelper.recordVO.encodeAudio) 
			{
				RecorderHelper.recordVO.byteArrayFlvEncoder.setAudioProperties(FlvEncoder.SAMPLERATE_44KHZ, true, false, true);
			}
			
			RecorderHelper.recordVO.byteArrayFlvEncoder.start();
			
			RecorderHelper.recordVO.encodeFrameNum = -1;
			// encode FLV frames on an interval to keep UI from locking up
			RecorderHelper.recordVO.stage.addEventListener(Event.ENTER_FRAME, onEnterFrameEncode);
		}
		
		private static function onEnterFrameEncode(event:*):void
		{
			// Encode 3 frames per iteration
			for (var i:int = 0; i < 3; i++)
			{
				RecorderHelper.recordVO.encodeFrameNum++;
				
				if (RecorderHelper.recordVO.encodeFrameNum < RecorderHelper.recordVO.bitmaps.length) {
					encodeNextFrame();
				}
				else {
					// done
					RecorderHelper.recordVO.stage.removeEventListener(Event.ENTER_FRAME, onEnterFrameEncode);
					RecorderHelper.recordVO.byteArrayFlvEncoder.updateDurationMetadata();
					return;
				}
			}
			
			RecorderHelper.recordVO.outputCallBackFunction("encoding\r" + (RecorderHelper.recordVO.encodeFrameNum+1) + " of " + RecorderHelper.recordVO.bitmaps.length);
		}
		
		private static function encodeNextFrame():void
		{
			var baAudio:ByteArray;
			var bmdVideo:BitmapData;
			
			if (RecorderHelper.recordVO.encodeAudio)
			{
				baAudio = new ByteArray();
				var pos:int = RecorderHelper.recordVO.encodeFrameNum * RecorderHelper.recordVO.byteArrayFlvEncoder.audioFrameSize;
				
				if (pos < 0 || pos + RecorderHelper.recordVO.byteArrayFlvEncoder.audioFrameSize > RecorderHelper.recordVO.micUtil.byteArray.length) {
					// trace('out of bounds:', RecorderHelper.recordVO.encodeFrameNum, pos + RecorderHelper.recordVO.byteArrayFlvEncoder.audioFrameSize, 'versus', RecorderHelper.recordVO.audioData); 
					baAudio.length = RecorderHelper.recordVO.byteArrayFlvEncoder.audioFrameSize; // zero's
				}
				else {
					baAudio.writeBytes(RecorderHelper.recordVO.micUtil.byteArray, pos, RecorderHelper.recordVO.byteArrayFlvEncoder.audioFrameSize);
				}
			}
			
			if (RecorderHelper.recordVO.encodeVideo) 
			{
				bmdVideo = RecorderHelper.recordVO.bitmaps[RecorderHelper.recordVO.encodeFrameNum];
			}
			
			RecorderHelper.recordVO.byteArrayFlvEncoder.addFrame(bmdVideo, baAudio);
			
			// Video frame has been encoded, so we can discard it now
			RecorderHelper.recordVO.bitmaps[RecorderHelper.recordVO.encodeFrameNum].dispose();
		}		
	}
}