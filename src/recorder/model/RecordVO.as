package recorder.model
{
	import flash.utils.ByteArray;
	
	import leelib.util.flvEncoder.ByteArrayFlvEncoder;

	public class RecordVO
	{
		public var outputWidth:int;
		public var outputHeight:int;
		public var flvFramerate:int;
		public var startTime:int;
		public var timeoutId:int;
		public var bitmaps:Array;
		public var container:*;
		public var outputCallBackFunction:Function;
		
		public var encodeVideo:Boolean;
		public var encodeAudio:Boolean;
		public var byteArrayFlvEncoder:ByteArrayFlvEncoder;
		public var encodeFrameNum:int;
		public var audioData:ByteArray;
		public var stage:*; // needed for framerate event
		
		public function RecordVO(outputWidth:int,outputHeight:int,flvFramerate:int,startTime:int=0,timeoutId:int=0,
								 bitmaps:Array=null,container:*=null,outputCallBackFunction:Function=null, encodeVideo:Boolean = true,
								 encodeAudio:Boolean = true,byteArrayFlvEncoder:ByteArrayFlvEncoder = null,encodeFrameNum:int = 0,
								 audioData:ByteArray = null,stage:* = null)
		{
			this.outputWidth = outputWidth;
			this.outputHeight = outputHeight;
			this.flvFramerate = flvFramerate;
			this.startTime = startTime;
			this.timeoutId = timeoutId;
			this.bitmaps = bitmaps;
			this.container = container;
			this.outputCallBackFunction = outputCallBackFunction;
			
			this.encodeVideo = encodeVideo;
			this.encodeAudio = encodeAudio;
			this.byteArrayFlvEncoder = byteArrayFlvEncoder;
			this.encodeFrameNum = encodeFrameNum;
			this.audioData = audioData;
			this.stage = stage;
		}
	}
}