package 
{
	import net.flashpunk.Engine;
	import net.flashpunk.FP;
	
	/**
	 * ...
	 * @author Stephen McIntyre
	 */
	public class Main extends Engine
	{
		public function Main():void
		{
			super(800, 600, 60, false);
		}
		
		override public function init():void
		{
			FP.world = new MyWorld();
		}
	}
}
