package monkey.loader {

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import monkey.core.base.Object3D;
	import monkey.core.entities.SkyBox;
	import monkey.core.utils.Zip;
	
	/**
	 * 天空盒加载器 
	 * @author Neil
	 * 
	 */	
	public class SkyboxLoader extends Object3D implements IQueLoader {

		public var skybox 	: SkyBox;
		
		private var zip 	: Zip;
		private var cfg 	: Object;
		private var loader 	: Loader;
		private var url		: String;
		
		private var _urlLoader	 : URLLoader;
		private var _loaded 	 : Boolean;
		private var _closed		 : Boolean;
		private var _bytesTotal  : uint;
		private var _bytesLoaded : uint;

		public function SkyboxLoader(url : String) {
			super();
			this.url = url;
			this._loaded = false;
		}

		public function loadBytes(bytes : ByteArray) : void {
			this.zip = new Zip();
			this.zip.loadBytes(bytes);
			var cfgBytes : ByteArray = zip.getFileByName("config");
			this.cfg = JSON.parse(cfgBytes.readUTFBytes(cfgBytes.length));
			this.loader = new Loader();
			this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onTextureLoadComplete);
			this.loader.loadBytes(zip.getFileByName("texture"));
		}

		public function load() : void {
			this._urlLoader = new URLLoader();
			this._urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			this._urlLoader.addEventListener(Event.COMPLETE, 			onLoadComplete);
			this._urlLoader.addEventListener(ProgressEvent.PROGRESS, 	onProgress);
			this._urlLoader.addEventListener(IOErrorEvent.IO_ERROR, 	onIoError);
			this._urlLoader.load(new URLRequest(url));
		}
		
		private function onIoError(event : IOErrorEvent) : void {
			this.dispatchEvent(event);
		}

		private function onProgress(event : ProgressEvent) : void {
			this._bytesLoaded = event.bytesLoaded;
			this._bytesTotal  = event.bytesTotal;
			this.dispatchEvent(event);
		}
		
		public function get bytesLoaded():uint {
			return _bytesLoaded;
		}
		
		public function get bytesTotal():uint {
			return _bytesTotal;
		}
		
		public function get loaded():Boolean {
			return _loaded;
		}
		
		private function onLoadComplete(event : Event) : void {
			this._urlLoader.removeEventListener(Event.COMPLETE, 		onLoadComplete);
			this._urlLoader.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			this._urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, 	onIoError);
			var bytes : ByteArray = this._urlLoader.data as ByteArray;
			this._urlLoader.close();
			this._urlLoader = null;
			this.loadBytes(bytes);
			bytes.clear();
		}
		
		private function onTextureLoadComplete(event : Event) : void {
			this._loaded = true;
			this._closed = true;
			this.loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onTextureLoadComplete);
			var bmp : BitmapData = (this.loader.content as Bitmap).bitmapData;
			this.loader.unloadAndStop(true);
			this.skybox = new SkyBox(bmp, this.cfg.size, this.cfg.scaleRatio);
			this.skybox.setLayer(this.cfg.layer);
			this.zip.dispose();
			this.addChild(skybox);
			this.transform.updateTransforms(true);
			this.dispatchEvent(event);
		}
		
		public function close():void {
			if (this._closed) {
				return;
			}
			this._closed = true;
			if (this._urlLoader) {
				this._urlLoader.close();
			}
		}
		

	}
}
