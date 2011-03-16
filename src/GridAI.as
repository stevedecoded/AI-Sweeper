package  
{
	/**
	 * ...
	 * @author Stephen McIntyre
	 */
	public class GridAI
	{
		private var _proxGrid:Array;
		private var _publicProxGrid:Array;
		private var _probGrid:Array;
		
		private var _boardRows:int = 8;
		private var _boardCols:int = 8;
		private var _numOfBombs:int = 10;
		
		private var _moves:int = 0;
		private var _bombsFlagged:int = 0;
		private var _gameIsOver:Boolean = false;
		private var _gameIsComplete:Boolean = false;
		
		public const ACTION_FLAG:uint = 0;
		public const ACTION_CLICK:uint = 1;
		public const ACTION_FIRST_EMPTY:uint = 2;
		public const ACTION_LEAST_PROBABLE:uint = 3;
		public const ACTION_BRUTE:uint = 4; // only used in BruteGridAI
		public const ACTION_GRID_FULL:uint = 5;
		public const ACTION_NO_DEFINITES:uint = 6;
		
		public function GridAI(rows:uint = 8, cols:uint = 8, bombs:uint = 10)
		{
			initGrid(rows, cols, bombs); // beginner grid by default
		}
		
		public function get probGrid():Array { return _probGrid; }
		
		public function get proxGrid():Array { return _publicProxGrid; }
		
		public function get rows():uint { return _boardRows; }
		
		public function get cols():uint { return _boardCols; }
		
		public function get complete():Boolean { return _gameIsComplete; }
		
		public function get over():Boolean { return _gameIsOver; }
		
		private function setUpGrid():void
		{
			// pre-fill proximity and probability grid
			_proxGrid = [];
			_publicProxGrid = [];
			_probGrid = [];
			
			for (var r:int = 0; r < _boardRows; r++)
			{
				_proxGrid[r] = [];
				_publicProxGrid[r] = [];
				_probGrid[r] = [];
				
				for (var c:int = 0; c < _boardCols; c++)
				{
					_proxGrid[r][c] = 0;
					_publicProxGrid[r][c] = -1;
						// 0 - 8 bomb proximity
						// -1 not clicked/flagged
					_probGrid[r][c] = -1;
						// 0 - 100 flag probability
						// -1 not clicked (+ not next to clicked)
						// -2 clicked
						// -3 flagged
				}
			}
			
			// place bombs in random positions
			for (var b:int = 0; b < _numOfBombs; b++)
			{
				var randRow:int;
				var randCol:int;
				
				do
				{
					randRow = randomInt(0, _boardRows - 1);
					randCol = randomInt(0, _boardCols - 1);
				}
				while (_proxGrid[randRow][randCol] == -1)
				
				_proxGrid[randRow][randCol] = -1;
			}
			
			// set up proximity numbers
			for (var row:int = 0; row < _boardRows; row++)
			{
				for (var col:int = 0; col < _boardCols; col++)
				{
					setProximity(row, col);
				}
			}
		}
		
		public function initGrid(rows:uint, cols:uint, bombs:uint):Boolean
		{
			if (rows > 0 && cols > 0 && rows * cols > bombs)
			{
				_moves = 0;
				_bombsFlagged = 0;
				_gameIsOver = false;
				_gameIsComplete = false;
				
				_boardRows = rows;
				_boardCols = cols;
				_numOfBombs = bombs;
				
				setUpGrid();
				
				return true;
			}
			
			return false;
		}
		
		public function initBeginnerGrid():Boolean
		{
			return initGrid(8, 8, 10);
		}
		
		public function resetGrid():Boolean
		{
			return initGrid(_boardRows, _boardCols, _numOfBombs);
		}
		
		private function findBestMove(probs:Array):Array
		{
			var definiteClick:Array = [-1, -1];
			var emptyCell:Array = [-1, -1];
			var leastProbable:Array = [ -1, -1];
			var lowProb:int = 101;
			
			for (var row:int = 0; row < _boardRows; row++)
			{
				for (var col:int = 0; col < _boardCols; col++)
				{
					if (probs[row][col] == 100)
					{
						return [row, col, ACTION_FLAG];
					}
					else if (!isFound(definiteClick) && probs[row][col] == 0)
					{
						definiteClick = [row, col];
					}
					else if (!isFound(emptyCell) && probs[row][col] == -1)
					{
						emptyCell = [row, col];
					}
					else if (_probGrid[row][col] >= -1 && probs[row][col] < lowProb)
					{
						leastProbable = [row, col];
						lowProb = probs[row][col];
					}
				}
			}
			
			if (isFound(definiteClick))
			{
				return [definiteClick[0], definiteClick[1], ACTION_CLICK];
			}
			else if (isFound(emptyCell))
			{
				return [emptyCell[0], emptyCell[1], ACTION_FIRST_EMPTY];
			}
			else if(isFound(leastProbable))
			{
				return [leastProbable[0], leastProbable[1], ACTION_LEAST_PROBABLE];
			}
			
			return [-1, -1, ACTION_GRID_FULL];
			// this should never be sent, as script should catch full board before this step
		}
		
		public function bestMove():Array
		{
			return findBestMove(_probGrid);
		}
		
		private function isFound(cell:Array):Boolean
		{
			return cell[0] != -1 && cell[1] != -1;
		}
		
		private function setFlagged(row:int, col:int, probs:Array):void
		{
			probs[row][col] = -3;
			
			recalcProb(_probGrid);
		}
		
		public function flagCell(row:int, col:int):void
		{
			setFlagged(row, col, _probGrid);
			
			_publicProxGrid[row][col] = _proxGrid[row][col];
			
			_bombsFlagged++;
			_moves++;
		}
		
		private function setClicked(row:int, col:int, probs:Array):void
		{
			probs[row][col] = -2;
			
			// note recalcProb isn't called here
			// this allows it to be called after a list of zero-surrounding cells are clicked
		}
		
		public function clickCell(row:int, col:int):void
		{
			// click cell and animate for zero fields
			
			var clickQueue:Array = [[row, col]];
			
			do
			{
				var curPos:Array = clickQueue.pop();
				var r:int = curPos[0];
				var c:int = curPos[1];
				
				setClicked(r, c, _probGrid);
				_publicProxGrid[r][c] = _proxGrid[r][c];
				
				if (_proxGrid[r][c] == -1) // clicked a bomb
				{
					clickAllCells();
					_gameIsOver = true;
				}
				else if (_proxGrid[r][c] == 0)
				{
					for each (var cell:Array in surroundingCells(r, c))
					{
						if (_probGrid[r + cell[0]][c + cell[1]] != -2)
						{
							clickQueue.push([r + cell[0], c + cell[1]]);
						}
					}
				}
			}
			while (clickQueue.length > 0)
			
			_moves++;
			
			if (_bombsFlagged == _numOfBombs)
			{
				_gameIsComplete = true;
				clickAllCells(true);
			}
			else
			{
				recalcProb(_probGrid);
			}
		}
		
		private function recalcProb(probs:Array):void
		{
			// reset probability grid with new percentages
			
			for (var row:int = 0; row < _boardRows; row++)
			{
				for (var col:int = 0; col < _boardCols; col++)
				{
					if (_publicProxGrid[row][col] > 0)
					{
						// clicked or flagged, and has bomb nearby
						
						var surList:Array = surroundingCells(row, col);
						var surCells:int = surList.length;
						var clickedSurCells:int = 0;
						var flaggedSurCells:int = 0;
						
						for each (var cell:Array in surList)
						{
							var cRow:int = row + cell[0];
							var cCol:int = col + cell[1];
							
							if (probs[cRow][cCol] == -2)
							{
								clickedSurCells++;
							}
							else if (probs[cRow][cCol] == -3)
							{
								flaggedSurCells++;
							}
						}
						
						if (clickedSurCells + flaggedSurCells < surCells)
						{
							// >= 1 unclicked cell near clicked cell, check probability
							
							var top:Number = _publicProxGrid[row][col] - flaggedSurCells;
							var bottom:Number = surCells - clickedSurCells - flaggedSurCells;
							
							var prob:int = Math.floor((top / bottom) * 100);
							
							for each (var ce:Array in surList)
							{
								var ceRow:int = row + ce[0];
								var ceCol:int = col + ce[1];
								
								if ((probs[ceRow][ceCol] > 0 || probs[ceRow][ceCol] == -1) && (prob == 0 || prob > probs[ceRow][ceCol]))
								{
									probs[ceRow][ceCol] = prob;
								}
							}
						}
					}
				}
			}
		}
		
		private function surroundingCells(row:int, col:int):Array
		{
			var surList:Array = [];
			
			var checkAbove:Boolean = row > 0;
			var checkBelow:Boolean = row < _boardRows - 1;
			var checkLeft:Boolean = col > 0;
			var checkRight:Boolean = col < _boardCols - 1;
			
			if (checkAbove)
			{
				// check above
				surList.push([-1, 0]);
				
				if (checkLeft)
				{
					// check above-left
					surList.push([-1, -1]);
				}
				
				if (checkRight)
				{
					// check above-right
					surList.push([-1, 1]);
				}
			}
			
			if (checkBelow)
			{
				// check below
				surList.push([1, 0]);
				
				if (checkLeft)
				{
					// check below-left
					surList.push([1, -1]);
				}
				
				if (checkRight)
				{
					// check below-right
					surList.push([1, 1]);
				}
			}
			
			if (checkLeft)
			{
				// check left
				surList.push([0, -1]);
			}
			
			if (checkRight)
			{
				// check right
				surList.push([0, 1]);
			}
			
			return surList;
		}
		
		public function setProximity(row:int, col:int):void
		{
			if (_proxGrid[row][col] != -1)
			{
				var surCells:Array = surroundingCells(row, col);
				var proxims:int = 0;
				
				if (surCells.length > 0)
				{
					for (var i:int = 0; i < surCells.length; i++)
					{
						proxims += cellBomb(row + surCells[i][0], col + surCells[i][1]);
					}
				}
				
				_proxGrid[row][col] = proxims;
			}
		}
		
		public function isBomb(row:uint, col:uint):Boolean
		{
			return _proxGrid[row][col] == -1;
		}
		
		public function cellBomb(row:int, col:int):int
		{
			return isBomb(row, col) ? 1 : 0;
		}
		
		public function randomInt(min:int, max:int):int
		{
			return Math.floor(Math.random() * (1 + max - min)) + min;
		}
		
		private function clickAllCells(excludeFlags:Boolean = false):void
		{
			// clicks all remaining unclicked cells blowing up remaining bombs in the process
			// useful for game overs
			
			for (var row:uint = 0; row < _boardRows; row++)
			{
				for (var col:uint = 0; col < _boardCols; col++)
				{
					if (_probGrid[row][col] >= -1 || (excludeFlags && _proxGrid[row][col] != -1))
					{
						setClicked(row, col, _probGrid);
						_publicProxGrid[row][col] = _proxGrid[row][col];
					}
				}
			}
		}
	}
}