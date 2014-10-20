package org.gesluxe.core;
import snow.utils.Timer;
import luxe.Vector;
import org.gesluxe.utils.GestureUtils;

/**
 * ...
 * @author Josu Igoa
 */
class TouchesManager
{
	var _gesturesManager:GesturesManager;
	var _touchesMap:Map<UInt, Touch>;
	public var activeTouchesCount(default, null):UInt;

	public function new(gesturesManager:GesturesManager)
	{
		_gesturesManager = gesturesManager;
		_touchesMap = new Map<UInt, Touch>();
		activeTouchesCount = 0;
	}
	
	public function onTouchBegin(touchID:UInt, x:Float, y:Float):Bool //, possibleTarget:Object = null):Bool
	{
		if (_touchesMap.exists(touchID))
			return false;// touch with specified ID is already registered and being tracked
		
		var location = new Vector(x, y);
		
		for (key in _touchesMap.keys())
		{
			// Check if touch at the same location exists.
			// In case we listen to both TouchEvents and MouseEvents, one of them will come first
			// (right now looks like MouseEvent dispatched first, but who know what Adobe will
			// do tomorrow). This check helps to filter out the one comes after.
			
			// NB! According to the tests with some IR multitouch frame and Windows computer
			// TouchEvent comes first, but the following MouseEvent has slightly offset location
			// (1px both axis). That is why Point#distance() used instead of Point#equals()
			
			if (GestureUtils.distance(_touchesMap.get(key).location, location) < 2)
				return false;
		}
		
		var touch:Touch = createTouch();
		touch.id = touchID;
		
		/*
		var target:Object;
		var altTarget:Object;
		for each (var hitTester:ITouchHitTester in _hitTesters)
		{
			target = hitTester.hitTest(location, possibleTarget);
			if (target)
			{
				if ((target is Stage))
				{
					// NB! Target is flash.display::Stage is a special case. If it is true, we want
					// to give a try to a lower-priority (Stage3D) hit-testers. 
					altTarget = target;
					continue;
				}
				else
				{
					// We found a target.
					break;
				}
			}
		}
		if (!target && !altTarget)
		{
			throw new Error("Not touch target found (hit test)." +
			"Something is wrong, at least flash.display::Stage should be found." +
			"See Gestouch#addTouchHitTester() and Gestouch#inputAdapter.");
		}
		*/
		
		//touch.target = target || altTarget;
		touch.setLocation(x, y, Std.int(Timer.stamp() * 1000));
		
		_touchesMap[touchID] = touch;
		activeTouchesCount++;
		
		_gesturesManager.onTouchBegin(touch);
		
		return true;
	}
	
	public function onTouchMove(touchID:UInt, x:Float, y:Float)
	{
		if (!_touchesMap.exists(touchID))
			return;// touch with specified ID isn't registered
		
		var touch = _touchesMap.get(touchID);
		if (touch.updateLocation(x, y, Std.int(Timer.stamp()*1000)))
		{
			// NB! It appeared that native TOUCH_MOVE event is dispatched also when
			// the location is the same, but size has changed. We are only interested
			// in location at the moment, so we shall ignore irrelevant calls.
			
			_gesturesManager.onTouchMove(touch);
		}
	}
	
	
	public function onTouchEnd(touchID:UInt, x:Float, y:Float)
	{
		if (!_touchesMap.exists(touchID))
			return;// touch with specified ID isn't registered
		
		var touch = _touchesMap.get(touchID);
		touch.updateLocation(x, y, Std.int(Timer.stamp()*1000));
		
		_touchesMap.remove(touchID);
		activeTouchesCount--;
		
		_gesturesManager.onTouchEnd(touch);
		
		//touch.target = null;
	}
	
	
	public function onTouchCancel(touchID:UInt, x:Float, y:Float)
	{
		if (!_touchesMap.exists(touchID))
			return;// touch with specified ID isn't registered
		
		var touch = _touchesMap.get(touchID);
		touch.updateLocation(x, y, Std.int(Timer.stamp()*1000));
		
		_touchesMap.remove(touchID);
		activeTouchesCount--;
		
		_gesturesManager.onTouchCancel(touch);
		
		//touch.target = null;
	}
	
	
	function createTouch():Touch
	{
		//TODO: pool
		return new Touch();
	}
}