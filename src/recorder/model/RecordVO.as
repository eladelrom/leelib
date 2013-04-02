package recorder.model
{
	import leelib.util.flvEncoder.ByteArrayFlvEncoder;
	import leelib.util.flvEncoder.FileStreamFlvEncoder;
	import leelib.util.flvEncoder.MicRecorderUtil;

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
		public var fsFlvEncoder:FileStreamFlvEncoder;
		public var encodeFrameNum:int;
		public var stage:*; // needed for framerate event
		public var micUtil:MicRecorderUtil;
		public var totalFramesRecorded:int;
		
		public function RecordVO(outputWidth:int,outputHeight:int,flvFramerate:int,startTime:int=0,timeoutId:int=0,
								 bitmaps:Array=null,container:*=null,outputCallBackFunction:Function=null, encodeVideo:Boolean = true,
								 encodeAudio:Boolean = true,byteArrayFlvEncoder:ByteArrayFlvEncoder = null,fsFlvEncoder:FileStreamFlvEncoder=null,encodeFrameNum:int = 0,stage:* = null,micUtil:MicRecorderUtil = null,totalFramesRecorded:int=0)
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
			this.fsFlvEncoder = fsFlvEncoder;
			this.encodeFrameNum = encodeFrameNum;
			this.stage = stage;
			this.micUtil = micUtil;
			this.totalFramesRecorded = totalFramesRecorded;
		}
	}
}