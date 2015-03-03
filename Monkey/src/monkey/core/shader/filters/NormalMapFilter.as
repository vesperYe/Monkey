package monkey.core.shader.filters {
	
	import monkey.core.base.Surface3D;
	import monkey.core.shader.utils.FcRegisterLabel;
	import monkey.core.shader.utils.FsRegisterLabel;
	import monkey.core.shader.utils.ShaderRegisterCache;
	import monkey.core.shader.utils.ShaderRegisterElement;
	import monkey.core.textures.Texture3D;
	import monkey.core.utils.Device3D;
	
	/**
	 * 法线贴图 
	 * @author Neil
	 * 
	 */	
	public class NormalMapFilter extends Filter3D {
		
		private var v0 		: ShaderRegisterElement;
		private var v2 		: ShaderRegisterElement;
		private var v3 		: ShaderRegisterElement;
		private var label	: FsRegisterLabel;
		private var camDir 	: Vector.<Number>;
		private var bias	: Vector.<Number>;
		
		public function NormalMapFilter(texture : Texture3D) {
			super("NormalMapFilter");
			this.priority = 14;
			this.camDir= Vector.<Number>([1, 1, 1, 1]);
			this.bias  = Vector.<Number>([2, 1, 1, 0.35]);
			this.label = new FsRegisterLabel(texture);
		}
		
		public function get texture() : Texture3D {
			return label.texture;
		}
		
		public function set texture(value : Texture3D) : void {
			label.texture = value;
		}
		
		public function set luminance(value : Number) : void {
			this.bias[3] = value;
		}
		
		public function get luminance() : Number {
			return this.bias[3];
		}
		
		public function set intensity(value : Number) : void {
			
		}
		
		public function get intensity() : Number {
			return 1;
		}
		
		override public function update() : void {
			this.camDir[0] = -Device3D.cameraDir.x;
			this.camDir[1] = -Device3D.cameraDir.y;
			this.camDir[2] = -Device3D.cameraDir.z;
		}
				
		override public function getFragmentCode(regCache : ShaderRegisterCache, agal:Boolean):String {
			
			this.v0 = regCache.getFreeV();
			this.v2 = regCache.getFreeV();
			this.v3 = regCache.getFreeV();
			
			var fs  : ShaderRegisterElement = regCache.getFs(label);
			regCache.fsUsed.push(label);
			var fc0 : ShaderRegisterElement = regCache.getFc(1, new FcRegisterLabel(bias));
			var fc1 : ShaderRegisterElement = regCache.getFc(1, new FcRegisterLabel(camDir));
			var fc4 : ShaderRegisterElement = regCache.getFc(1, new FcRegisterLabel(Vector.<Number>([2, 2, 2, 2])));
			var ft0 : ShaderRegisterElement = regCache.getFt();
			var ft1 : ShaderRegisterElement = regCache.getFt();
			var ft2 : ShaderRegisterElement = regCache.getFt();
			var ft3 : ShaderRegisterElement = regCache.getFt();
			
			var code : String = '';
			
			if (agal) {
				// 获取normal map法线
				code += 'tex ' + ft0 + ', ' + regCache.getV(Surface3D.UV0) + ', ' + fs + description(label.texture) + ' \n';
				code += 'mul ' + ft0 + ', ' + ft0 + ', ' + fc0 + '.x \n';
				code += 'sub ' + ft0 + ', ' + ft0 + ', ' + fc0 + '.y \n';
				// normal map法线转换到world空间
				code += 'mul ' + ft1 + ', ' + v0 + '. ' + ft0 + '.z \n';
				code += 'mul ' + ft2 + ', ' + ft0 + '.x, ' + v2 + ' \n';
				code += 'mul ' + ft3 + ', ' + ft0 + '.y, ' + v3 + ' \n';
				code += 'add ' + ft0 + '.xyz, ' + ft2 + ', ' + ft3 + ' \n';
				code += 'add ' + ft2 + '.xyz, ' + ft1 + ', ' + ft0 + ' \n';
				code += 'nrm ' + ft0 + '.xyz, ' + ft2 + ' \n';
				code += 'mov ' + regCache.normalFt + ', ' + ft0 + '.xyz \n';
				// 计算颜色
				code += 'dp3 ' + ft0 + '.w, ' + ft0 + ', ' + fc1 + ' \n';
				code += 'max ' + ft0 + '.x, ' + ft0 + '.w, ' + regCache.fc0123 + '.x \n';
				
//				code += 'mul ' + ft1 + ', ' + ft0 + '.x, ' + fc0 + '.z \n';
//				code += 'add ' + ft1 + ', ' + ft1 + ', ' + fc0 + '.w \n';
//				code += 'pow ' + ft1 + ', ' + ft1 + ', ' + fc4 + ' \n';
//				code += 'mul ' + ft1 + ', ' + ft1 + ', ' + regCache.oc + ' \n';
//				code += 'mov ' + ft1 + '.w, ' + fc0 + '.y \n';
//				code += 'sat ' + regCache.oc + ', ' + ft1 + ' \n';
				
				code += 'mul ' + ft1 + '.x, ' + ft0 + '.x, ' + fc0 + '.z \n';
				code += 'add ' + ft1 + '.x, ' + ft1 + '.x, ' + fc0 + '.w \n';
				code += 'pow ' + ft1 + '.x, ' + ft1 + '.x, ' + fc4 + '.x \n';
				code += 'mul ' + ft1 + '.xyz, ' + ft1 + '.x, ' + regCache.oc + ' \n';
				code += 'mov ' + ft1 + '.w, ' + fc0 + '.y \n';
				code += 'sat ' + regCache.oc + ', ' + ft1 + ' \n';
			}
			
			regCache.removeFt(ft0);
			regCache.removeFt(ft1);
			regCache.removeFt(ft2);
			regCache.removeFt(ft3);
			
			return code;
		}
		
		override public function getVertexCode(regCache:ShaderRegisterCache, agal:Boolean):String {
			
			var bitVt : ShaderRegisterElement = regCache.getVt();
			var nrmVt : ShaderRegisterElement = regCache.getVt();
			var tanVt : ShaderRegisterElement = regCache.getVt();
			
			var code : String = '';
			
			if (agal) {
				code += 'm33 ' + nrmVt + '.xyz, ' + regCache.getVa(Surface3D.NORMAL) + ', ' + regCache.vcWorld + ' \n';
				// 切线向量
				code += 'm33 ' + tanVt + '.xyz, ' + regCache.getVa(Surface3D.TANGENT) + ', ' + regCache.vcWorld + ' \n';
				// 法线向量切线向量计算出副切线向量
				code += 'crs ' + bitVt + '.xyz, ' + tanVt + '.xyz, ' + nrmVt + '.xyz \n';
				// 传送到fg
				code += 'mov ' + v0 + '.xyz, ' + nrmVt + '.xyz \n';
				code += 'mov ' + v2 + '.xyz, ' + tanVt + '.xyz \n';
				code += 'mov ' + v3 + '.xyz, ' + bitVt + '.xyz \n';
				code += 'mov ' + v0 + '.w, ' + regCache.vc0123 + '.y \n';
				code += 'mov ' + v2 + '.w, ' + regCache.vc0123 + '.y \n';
				code += 'mov ' + v3 + '.w, ' + regCache.vc0123 + '.y \n';
			}
			
			regCache.removeVt(bitVt);
			regCache.removeVt(nrmVt);
			regCache.removeVt(tanVt);
			
			return code;
		}
		
	}
}
