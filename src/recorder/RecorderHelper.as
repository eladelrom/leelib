package recorder
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import leelib.util.flvEncoder.ByteArrayFlvEncoder;
	import leelib.util.flvEncoder.FlvEncoder;
	import leelib.util.flvEncoder.VideoPayloadMakerAlchemy;
	
	import recorder.model.RecordVO;

	public class RecorderHelper
	{
		public static var recordVO:RecordVO;
		
		public static function captureFrame(recordVO:RecordVO=null):void
		{
			if (recordVO)
				RecorderHelper.recordVO = recordVO;
			
			// capture frame
			var bitmapData:BitmapData = new BitmapData(RecorderHelper.recordVO.outputWidth,RecorderHelper.recordVO.outputHeight,false,0x0);
			bitmapData.draw(RecorderHelper.recordVO.container);
			RecorderHelper.recordVO.bitmaps.push(bitmapData);
			
			var sec:int = int(RecorderHelper.recordVO.bitmaps.length / RecorderHelper.recordVO.flvFramerate);
			var encodeBitmapsSecond:String = "0:"  +  ((sec < 10) ? ("0" + sec) : sec);
			
			// schedule next captureFrame
			var elapsedMs:int = getTimer() - RecorderHelper.recordVO.startTime;
			var nextMs:int = (RecorderHelper.recordVO.bitmaps.length / RecorderHelper.recordVO.flvFramerate) * 1000;
			var deltaMs:int = nextMs - elapsedMs;
			
			if (deltaMs < 10) 
				deltaMs = 10;
			
			if (RecorderHelper.recordVO.outputCallBackFunction != null)
				RecorderHelper.recordVO.outputCallBackFunction(encodeBitmapsSecond);
			
			RecorderHelper.recordVO.timeoutId = setTimeout(captureFrame, deltaMs);
		}
		
		public static function startEncoding():void
		{
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
				
				if (pos < 0 || pos + RecorderHelper.recordVO.byteArrayFlvEncoder.audioFrameSize > RecorderHelper.recordVO.audioData.length) {
					// trace('out of bounds:', RecorderHelper.recordVO.encodeFrameNum, pos + RecorderHelper.recordVO.byteArrayFlvEncoder.audioFrameSize, 'versus', RecorderHelper.recordVO.audioData); 
					baAudio.length = RecorderHelper.recordVO.byteArrayFlvEncoder.audioFrameSize; // zero's
				}
				else {
					baAudio.writeBytes(RecorderHelper.recordVO.audioData, pos, RecorderHelper.recordVO.byteArrayFlvEncoder.audioFrameSize);
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