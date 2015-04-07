package monkey.core.utils {
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	import flash.utils.Endian;
	
	import monkey.core.animator.Animator;
	import monkey.core.animator.FrameAnimator;
	import monkey.core.animator.SkeletonAnimator;
	
	/**
	 * 动画工具 
	 * @author Neil
	 * 
	 */	
	public class AnimUtil {
		
		/**
		 * 读取动画 
		 * @param bytes
		 * @return 
		 * 
		 */		
		public static function readAnim(bytes : ByteArray) : Animator {
			bytes.endian = Endian.LITTLE_ENDIAN;
			// 读取压缩格式
			var algorithm : int = bytes.readInt();
			// 读取压缩之前的长度
			var size : int = bytes.readInt();
			var data : ByteArray = new ByteArray();
			data.endian = Endian.LITTLE_ENDIAN;
			bytes.readBytes(data, 0, bytes.bytesAvailable);
			// 解压
			if (algorithm == 1) {
				data.uncompress();
			} else if (algorithm == 2) {
				data.uncompress(CompressionAlgorithm.LZMA);				
			}
			// 
			var type : int = data.readInt();
			if (type == 0) {
				return readFrameAnim(data, type);
			} else {
				return readSkeletonAnim(data, type);
			}
			data.clear();
			return null;
		}
		
		private static function readFrameAnim(bytes : ByteArray, type : int) : FrameAnimator {
			var anim  : FrameAnimator = new FrameAnimator();
			var count : int = bytes.readInt();
			var vec   : Vector3D = new Vector3D();
			for (var i:int = 0; i < count; i++) {
				var frame : Matrix3D = new Matrix3D();
				for (var j:int = 0; j < 3; j++) {
					vec.x = bytes.readFloat();
					vec.y = bytes.readFloat();
					vec.z = bytes.readFloat();
					vec.w = bytes.readFloat();
					frame.copyRowFrom(j, vec);
				}
				anim.frames.push(frame);
			}
			anim.totalFrames = count;
			return anim;
		}
		
		/**
		 * 读取动画 
		 * @param bytes
		 * @return 
		 * 
		 */		
		private static function readSkeletonAnim(bytes : ByteArray, type : int) : SkeletonAnimator {
			
			var render : SkeletonAnimator = new SkeletonAnimator();
			var num  : int = bytes.readInt();
			
			for (var i:int = 0; i < num; i++) {
				var frameCount : int = bytes.readInt();
				var boneNum    : int = bytes.readInt();
				render.totalFrames = frameCount;
				render.quat = type == 2;
				render.boneNum[i] = Math.ceil(render.quat ? boneNum : boneNum * 1.5);
				for (var j:int = 0; j < frameCount; j++) {
					var data : ByteArray = new ByteArray();
					data.endian = Endian.LITTLE_ENDIAN;
					if (render.quat) {
						bytes.readBytes(data, 0, boneNum * 32);
					} else {
						bytes.readBytes(data, 0, boneNum * 48);
					}
					render.addBoneBytes(i, j, data);
				}
			}
			
			frameCount = bytes.readInt();
			num = bytes.readInt();
			
			var vec : Vector3D = new Vector3D();
			for (i = 0; i < num; i++) {
				var size : int = bytes.readInt();
				var name : String = bytes.readUTFBytes(size);
				for (j = 0; j < frameCount; j++) {
					var mt : Matrix3D = new Matrix3D();
					for (var k:int = 0; k < 3; k++) {
						vec.x = bytes.readFloat();
						vec.y = bytes.readFloat();
						vec.z = bytes.readFloat();
						vec.w = bytes.readFloat();
						mt.copyRowFrom(k, vec);
					}
					render.addMount(name, j, mt);
				}
				trace("挂节点:", name);
			}
			
			return render;
		}
		
	}
}
