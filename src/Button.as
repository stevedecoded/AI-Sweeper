package  
{
	import net.flashpunk.Entity;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.FP;
	import net.flashpunk.utils.Input;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	/**
	 * ...
	 * @author Stephen McIntyre
	 */
	public class Button extends Entity
	{
		private var _active:Boolean = true;
		private var _clicked:Boolean = false;
		private var _pressed:Boolean = false;
		private var _defaultText:String = "Button.";
		
		private var _proxValue:int;
		
		public function Button(prox:int)
		{
			_proxValue = prox;
			
			_defaultText = "-1";
			_defaultGraphic();
			
			width = 40;
			height = 40;
		}
		
		override public function update():void 
		{
			super.update();
			
			if (_clicked)
			{
				// clicked, no click checks
			}
			else if(collidePoint(x, y, Input.mouseX, Input.mouseY))
			{
				// event inside hit box
				if (!_pressed)
				{
					if (Input.mousePressed)
					{
						_pressed = true;
						_pressedGraphic();
					}
					else if(Input.mouseUp)
					{
						_hoverGraphic();
					}
				}
				else if (Input.mouseDown)
				{
					_pressedGraphic();
				}
				else
				{
					click();
				}
			}
			else
			{
				// event outside hit box
				if(_pressed && Input.mouseUp)
				{
					_pressed = false;
				}
				
				//_defaultGraphic();
			}
		}
		
		private function _defaultGraphic():void
		{
			graphic = new Text(_defaultText);
		}
		
		private function _hoverGraphic():void
		{
			graphic = new Text("[x]");
		}
		
		private function _pressedGraphic():void
		{
			graphic = new Text("[...]");
		}
		
		private function _clickedGraphic():void
		{
			graphic = new Text(_proxValue.toString());
		}
		
		public function click():int
		{
			_clicked = true;
			_clickedGraphic();
			
			return _proxValue;
		}
	}
}