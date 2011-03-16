package
{
	import flash.events.TextEvent;
	import flash.filters.ColorMatrixFilter;
	import net.flashpunk.Entity;
	import net.flashpunk.Graphic;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.masks.Grid;
	import net.flashpunk.World;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	
	/**
	 * ...
	 * @author Stephen McIntyre
	 */
	public class MyWorld extends World
	{
		private var _cellGrid:Array;
		private var _solnGrid:Array;
		
		private var _gameMessage:Entity = new Entity();
		private var _instructionsMessage:Entity = new Entity();
		private var _actionMessage:Entity = new Entity();
		
		private var _gridAI:BruteGridAI;
		private var _proxGrid:Array;
		private var _probGrid:Array;
		
		public function MyWorld()
		{
			var gridText:Entity = new Entity();
			gridText.graphic = new Text("LEVEL");
			gridText.x = 150;
			gridText.y = 10;
			add(gridText);
			
			var solnText:Entity = new Entity();
			solnText.graphic = new Text("SOLUTION");
			solnText.x = 550;
			solnText.y = 10;
			add(solnText);
			
			_instructionsMessage.graphic = new Text("SPACE TO STEP ONE MOVE\n\nENTER TO RESET GRID");
			_instructionsMessage.x = 50;
			_instructionsMessage.y = 400;
			add(_instructionsMessage);
			
			_actionMessage.graphic = new Text(" ");
			_actionMessage.x = 400;
			_actionMessage.y = 400;
			add(_actionMessage);
			
			_gameMessage.graphic = new Text(" ");
			_gameMessage.x = 400;
			_gameMessage.y = 500;
			add(_gameMessage);
			
			_gridAI = new BruteGridAI();
			
			setGrids();
			
			displayBlankGrid();
			
			displaySolution();
		}
		
		private function displayBlankGrid():void
		{
			_cellGrid = [];
			
			for (var row:uint = 0; row < _gridAI.rows; row++)
			{
				_cellGrid[row] = [];
				
				for (var col:uint = 0; col < _gridAI.cols; col++)
				{
					var textGraphic:Cell = new Cell();
					textGraphic.graphic = new Text(".");
					
					textGraphic.x = col * 40 + 40;
					textGraphic.y = row * 40 + 40;
					
					_cellGrid[row][col] = textGraphic;
					
					add(textGraphic);
				}
			}
		}
		
		private function displaySolution():void
		{
			var sol:Array = _gridAI.solution;
			
			_solnGrid = [];
			
			for (var row:uint = 0; row < _gridAI.rows; row++)
			{
				_solnGrid[row] = [];
				
				for (var col:uint = 0; col < _gridAI.cols; col++)
				{
					var textGraphic:Cell = new Cell();
					
					var prox:int = sol[row][col];
					
					if (prox == -1)
					{
						textGraphic.graphic = new Text("[[!]]");
					}
					else
					{
						textGraphic.graphic = new Text(prox.toString());
					}
					
					textGraphic.x = col * 40 + 440;
					textGraphic.y = row * 40 + 40;
					
					_solnGrid[row][col] = textGraphic;
					
					add(textGraphic);
				}
			}
			
			updateSolution();
		}
		
		private function updateSolution():void
		{
			var sol:Array = _gridAI.solution;
			
			for (var row:uint = 0; row < _gridAI.rows; row++)
			{
				for (var col:uint = 0; col < _gridAI.cols; col++)
				{
					if (sol[row][col] == -1)
					{
						_solnGrid[row][col].graphic = new Text("[[!]]");
						
						_solnGrid[row][col].graphic.color = 0xFF0000;
					}
					else
					{
						_solnGrid[row][col].graphic = new Text(sol[row][col].toString());
						
						_solnGrid[row][col].graphic.color = 0xFFFF00;
					}
				}
			}
		}
		
		override public function update():void
		{
			if (Input.released(Key.ENTER))
			{
				_gridAI.resetGrid();
				setGrids();
				updateTiles();
				updateSolution();
				
				_gameMessage.graphic = new Text(" ");
				_actionMessage.graphic = new Text(" ");
			}
			
			if (Input.released(Key.B))
			{
				_gridAI.initBeginnerGrid();
				setGrids();
				updateTiles();
				updateSolution();
				
				_gameMessage.graphic = new Text(" ");
				_actionMessage.graphic = new Text(" ");
			}
			
			if (Input.released(Key.A))
			{
				_gridAI.initAdvancedGrid();
				setGrids();
				updateTiles();
				updateSolution();
				
				_gameMessage.graphic = new Text(" ");
				_actionMessage.graphic = new Text(" ");
			}
			
			if (!_gridAI.over && !_gridAI.complete && Input.released(Key.SPACE))
			{
				newMove();
			}
			else
			{
				updateTiles();
			}
			
			super.update();
		}
		
		public function doAction(actionData:Array):void
		{
			var row:uint = actionData[0];
			var col:uint = actionData[1];
			var type:uint = actionData[2];
			
			switch(type)
			{
				case _gridAI.ACTION_FLAG:
				{
					_gridAI.flagCell(row, col);
					trace("flagged");
					_actionMessage.graphic = new Text("flagged definite bomb "+row+", "+col);
				}
				break;
				case _gridAI.ACTION_CLICK:
				{
					_gridAI.clickCell(row, col);
					trace("clicked");
					_actionMessage.graphic = new Text("clicked definite empty space "+row+", "+col);
				}
				break;
				case _gridAI.ACTION_BRUTE:
				{
					_gridAI.clickCell(row, col);
					trace("found definite clickable cell through brute force checks");
					_actionMessage.graphic = new Text("brute forced into "+row+", "+col);
				}
				break;
				case _gridAI.ACTION_FIRST_EMPTY:
				{
					_gridAI.clickCell(row, col);
					trace("took a guess at first empty cell without probability");
					_actionMessage.graphic = new Text("clicked unchecked space "+row+", "+col);
				}
				break;
				case _gridAI.ACTION_LEAST_PROBABLE:
				{
					_gridAI.clickCell(row, col);
					trace("clicked least probable cell");
					_actionMessage.graphic = new Text("clicked least probable cell "+row+", "+col);
				}
				break;
			}
			
			if (_gridAI.complete)
			{
				_gameMessage.graphic = new Text("GAME COMPLETE! :D");
				trace("all flags found, GAME COMPLETE");
				_actionMessage.graphic = new Text("found all flags");
			}
			else if (_gridAI.over)
			{
				_gridAI.clickCell(row, col);
				_gameMessage.graphic = new Text("GAME OVER... :'(");
				trace("clicked a bomb, GAME OVER");
				_actionMessage.graphic = new Text("clicked a bomb");
			}
		}
		
		private function newMove():void
		{
			var best:Array = _gridAI.bestMove();
			doAction(best);
			setGrids();
			updateTiles();
		}
		
		private function updateTiles():void
		{
			for (var row:int = 0; row < _gridAI.rows; row++)
			{
				for (var col:int = 0; col < _gridAI.cols; col++)
				{
					var cellVal:String = ".";
					var color:uint = 0xFFFFFF;
					
					if (_probGrid[row][col] == -2)
					{
						if (_proxGrid[row][col] == -1) // clicked a bomb
						{
							cellVal = "[[!]]";
							color = 0xFFF0000;
						}
						else
						{
							cellVal = _proxGrid[row][col].toString();
							color = 0xFFFF00;
						}
					}
					else if (_probGrid[row][col] == -3)
					{
						cellVal = "F";
						color = 0xFF0000;
					}
					else if (_probGrid[row][col] >= 0)
					{
						cellVal = _probGrid[row][col].toString()+"%";
					}
					
					_cellGrid[row][col].graphic = new Text(cellVal);
					_cellGrid[row][col].graphic.color = color;
				}
			}
		}
		
		private function setGrids():void
		{
			_proxGrid = _gridAI.proxGrid;
			_probGrid = _gridAI.probGrid;
		}
	}
}