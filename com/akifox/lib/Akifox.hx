package com.akifox.lib;

import openfl.display.Tilesheet;
import openfl.text.Font;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.display.StageDisplayState;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import motion.Actuate;
import motion.easing.*;

import openfl.events.TouchEvent;
import openfl.ui.Multitouch;
import openfl.ui.MultitouchInputMode;

import com.akifox.lib.Screen;

class Akifox
{

	public static var id:String = "";

	private static var inTransition:Bool = false;

	public static function initialize(screenContainer:DisplayObjectContainer,appid:String):Void {								
		if (screenContainer != null){
			_screenContainer = screenContainer;			
		} else {
			throw new Error("AKIFOX Error: Cannot initialize screen container. The value is null.");
		}
		id = Data.id = appid;
		_transition_mode = Constants.TRANSITION_NONE;

		//sound init
		Sfx.setVolume('sound',0);

		Lib.current.stage.addEventListener(FocusEvent.FOCUS_IN,focus);
		Lib.current.stage.addEventListener(FocusEvent.FOCUS_OUT,defocus);
		Lib.current.stage.addEventListener(Event.ACTIVATE,focus);
		Lib.current.stage.addEventListener(Event.DEACTIVATE,defocus);
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP,keyUp);

		multitouchEnable();


	}

	public static var multitouchOn:Bool = false;

	private static function multitouchEnable(){
		multitouchOn = Multitouch.supportsTouchEvents;
		if (multitouchOn)
		{
			// If so, set the input mode and hook up our event handlers
			// TOUCH_POINT means simple touch events will be dispatched, 
			// rather than gestures or mouse events
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			
/*			Lib.current.stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
			Lib.current.stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
			Lib.current.stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);*/
		}
	}

	private static function keyUp(event:KeyboardEvent) {
		if(_currentScene==null) return;
		switch (event.keyCode) {
			case Keyboard.P:
				if(_currentScene.paused) play();
				else pause();
			case Keyboard.F:
				toggleFullscreen();
		}
	}

	public static function pause():Void {
		if (_currentScene==null) return;
		if (_currentScene.pausable) {
			if (inTransition) _currentScene.paused = true; // start() will handle it
			else _currentScene.pause();
		}
	}

	public static function play():Void {
		if (_currentScene==null) return;
			if (inTransition) _currentScene.paused = false; // start() will handle it
			else _currentScene.play();
	}

	private static function focus(event:Dynamic):Void { /*play();*/ }

	private static function defocus(event:Dynamic):Void { pause(); }


	//##########################################################################################
	//
	// SCENE MANAGMENT
	//
	//##########################################################################################

	public static inline var _transition_offset = 300; // offset drawing for the ghost
	public static inline var _transition_span = 250; // distance between slides

	private static var _currentScene(default, null):Screen;
	private static var _holdScene(default, null):Screen;
	private static var _screenContainer:DisplayObjectContainer;

	public static var _transition_mode:String = ""; // USE Constants.TRANSITION_XXX
	private static var _transition_ghost_old:Bitmap=null;
	private static var _transition_ghost_new:Bitmap=null;

	private static var _isSceneOnHold:Bool=false;


	private static var currentWidth:Float;
	private static var currentHeight:Float;
	
/*	private static var previousTime:Int = 0;	
	public static function update():Void {
		var currentTime:Int = Lib.getTimer();
		var deltaTime = (currentTime - previousTime) / 1000;	
		
		_currentScene.update(deltaTime);
		
		previousTime = currentTime;
	}*/

	public static function resize():Void {
		_currentScene.resize();
	}
	
	private static function deleteGhost():Void {
		Actuate.stop(_transition_ghost_old);
		Actuate.stop(_transition_ghost_new);
		if (_transition_ghost_new!=null) {
			_screenContainer.removeChild(_transition_ghost_new);
			_transition_ghost_new.bitmapData.dispose();
			_transition_ghost_new = null;
		}
		if (_transition_ghost_old!=null) {
			_screenContainer.removeChild(_transition_ghost_old);
			_transition_ghost_old.bitmapData.dispose();
			_transition_ghost_old = null;
		}
	}

	public static function hasHoldScene():Bool {
		return !(_holdScene==null);
	}

	public static function getScene():Screen {
		return _currentScene;
	}

	private static function destroyScene(scene:Screen) {
		if (scene.numChildren != 0) {			
			var i:Int = scene.numChildren;			
			do {
				i--;
				scene.removeChildAt(i);												
			} while (i > 0);
		}			
		_screenContainer.removeChild(scene);	
		scene.unload();
		scene = null;
	}

	public static function changeScreen(?newScreen:Screen=null,?transition:String="") {
		loadScreen(newScreen,transition,false);
	}

	public static function resumeScreen(?transition:String="") {
		loadScreen(null,transition,false);
	}

	public static function holdScreen(?newScreen:Screen=null,?transition:String="") {
		loadScreen(newScreen,transition,true);
	}
	
	private static function loadScreen(?newScreen:Screen=null,?transition:String="",?modal:Bool=false):Void {
		if (newScreen==null) modal = false;

		if (_screenContainer != null) {

			inTransition = true;

			currentWidth = Lib.current.stage.stageWidth;
			currentHeight = Lib.current.stage.stageHeight;

			deleteGhost();
			if (transition != "") _transition_mode = transition;

			if (_currentScene != null) {
				if (modal) {
					//trace('0. modal');
					_currentScene.holdStart();
				}
				else {
					//trace('0. not modal');
					_currentScene.pause();
				}

				if (_transition_mode != Constants.TRANSITION_NONE) {
					_transition_ghost_old = new Bitmap(Utils.makeBitmap(_currentScene,currentWidth,currentHeight,_transition_offset,false));
					_transition_ghost_old.smoothing = false;
					_transition_ghost_old.alpha = 1;
					_transition_ghost_old.visible = true;
					_transition_ghost_old.x=-_transition_offset;
					_transition_ghost_old.y=-_transition_offset;
					_screenContainer.addChild(_transition_ghost_old);
				}

				
				if (!modal) {
					//trace('1. not modal destroy scene');
					//if (_holdScene!=null && newScreen!=null) {
						//trace('1.5 not modal destroyhold');
					//}
					destroyScene(_currentScene);
				} else {
					//trace('1. modal hold scene');
					if (_holdScene!=null) {
						destroyScene(_holdScene);
						_holdScene==null;
					}
					_screenContainer.removeChild(_currentScene);
					_holdScene = _currentScene;
				}
				_currentScene = null;
			}
			else{
				//trace('0. NO PREVIOUS SCREEN');
				//trace('1. NO PREVIOUS SCREEN');
			}	
			
			#if flash
			openfl.system.System.gc();
			#elseif cpp
			cpp.vm.Gc.run(true);
			#elseif neko		
			neko.vm.Gc.run(true);
			#end
			if (newScreen == null) {
				//trace('2. get hold screen');
				_currentScene = _holdScene;
				_currentScene.resize();
				_holdScene = null;
				_isSceneOnHold = true;
				sceneReady(); //launch manually
			} else {
				//trace('2. get new screen');
				newScreen.initialize();
				_currentScene = newScreen;
				// sceneReady(); will be launch automatically by the newScreen
			}
			_currentScene.alpha = 0;
			_screenContainer.addChild(_currentScene);
			newScreen = null;
		}
	}


	public static function sceneReady():Void {
		//trace('3. scene ready');

		if (_transition_mode == Constants.TRANSITION_NONE) {
			sceneStart();
			return;
		}

		_transition_ghost_new = new Bitmap(Utils.makeBitmap(_currentScene,currentWidth,currentHeight,_transition_offset,true));
		_transition_ghost_new.smoothing = false;
		_transition_ghost_new.alpha = 1;
		_transition_ghost_new.visible = true;
		_transition_ghost_new.x=-_transition_offset;
		_transition_ghost_new.y=-_transition_offset;
		_screenContainer.addChild(_transition_ghost_new);

		var timing = 1;
		var delay = #if mobile 0.2 #else 0 #end; //ios needs bit of delay

		var ghostEase = Sine.easeIn;
		var sceneEase = Expo.easeOut;

		switch (_transition_mode) {
			case Constants.TRANSITION_ALPHA:
				_transition_ghost_new.alpha = 0;
				if (_transition_ghost_old!=null) Actuate.tween (_transition_ghost_old, timing, { alpha: 0 }).delay(delay);
				Actuate.tween (_transition_ghost_new, timing, { alpha: 1 }).delay(delay).onComplete(sceneStart);
			case Constants.TRANSITION_SLIDE_UP:
				_transition_ghost_new.y += currentHeight+_transition_span;
				if (_transition_ghost_old!=null) {
						Actuate.tween (_transition_ghost_old, timing, { y: -currentHeight-_transition_span-_transition_offset }).ease(ghostEase).delay(delay);
						Actuate.tween (_transition_ghost_old, timing/3+0.1, { alpha:0 }).ease(ghostEase).delay(delay);
					}
				Actuate.tween (_transition_ghost_new, timing, { y: -_transition_offset }).ease(sceneEase).delay(delay).onComplete(sceneStart);
			case Constants.TRANSITION_SLIDE_DOWN:
				_transition_ghost_new.y -= currentHeight+_transition_span;
				if (_transition_ghost_old!=null) {
					Actuate.tween (_transition_ghost_old, timing, { y: currentHeight+_transition_span-_transition_offset }).ease(ghostEase).delay(delay);
					Actuate.tween (_transition_ghost_old, timing/3+0.1, { alpha:0 }).ease(ghostEase).delay(delay);	
				}
				Actuate.tween (_transition_ghost_new, timing, { y: -_transition_offset }).ease(sceneEase).delay(delay).onComplete(sceneStart);
			case Constants.TRANSITION_SLIDE_LEFT:
				_transition_ghost_new.x += currentWidth+_transition_span;
				if (_transition_ghost_old!=null) {
					Actuate.tween (_transition_ghost_old, timing, { x: -currentWidth-_transition_span-_transition_offset }).ease(ghostEase).delay(delay);
					Actuate.tween (_transition_ghost_old, timing/3+0.1, { alpha:0 }).ease(ghostEase).delay(delay);	
				}
				Actuate.tween (_transition_ghost_new, timing, { x: -_transition_offset }).ease(sceneEase).delay(delay).onComplete(sceneStart);
			case Constants.TRANSITION_SLIDE_RIGHT:
				_transition_ghost_new.x -= currentWidth+_transition_span;
				if (_transition_ghost_old!=null) {
					Actuate.tween (_transition_ghost_old, timing, { x: currentWidth+_transition_span-_transition_offset }).ease(ghostEase).delay(delay);	
					Actuate.tween (_transition_ghost_old, timing/3+0.1, { alpha:0 }).ease(ghostEase).delay(delay);
				}
				Actuate.tween (_transition_ghost_new, timing, { x: -_transition_offset }).ease(sceneEase).delay(delay).onComplete(sceneStart);
		}
	}

	private static function sceneStart():Void {
		deleteGhost();
		_currentScene.alpha = 1;
		inTransition = false;

		if (_isSceneOnHold) {
			sceneContinue();
			return;
		}
		//trace('4. scene start');
		_currentScene.start();
	}

	private static function sceneContinue():Void {
		//trace('4. scene continue');
		_currentScene.holdEnd();
		_isSceneOnHold = false;
	}



	//##########################################################################################
	//
	// STORAGE
	//
	//##########################################################################################

	// Bitmap storage.
	private static var _bitmap:Map<String,BitmapData> = new Map<String,BitmapData>();

	public static function getBitmap(name:String):BitmapData
	{
		if (_bitmap.exists(name))
			return _bitmap.get(name);

		var data:BitmapData = openfl.Assets.getBitmapData(name, false);

		if (data != null)
			_bitmap.set(name, data);

		return data;
	}

/*	public static function overwriteBitmapCache(name:String, data:BitmapData):Void
	{
		removeBitmap(name);
		_bitmap.set(name, data);
	}*/

	public static function removeBitmap(name:String):Bool
	{
		if (_bitmap.exists(name))
		{
			var bitmap = _bitmap.get(name);
			bitmap.dispose();
			bitmap = null;
			return _bitmap.remove(name);
		}
		return false;
	}

	//##########################################################################################

	// Tilesheets storage.
	private static var _tilesheet:Map<String,Tilesheet> = new Map<String,Tilesheet>();

	public static function addTilesheet(name:String,columns:Int,rows:Int):Void {
		if (_tilesheet.exists(name)) return;
		var bitmap:BitmapData = getBitmap(name);
		var tileWidth = bitmap.width / columns;
		var tileHeight = bitmap.height / rows;
		if (bitmap!=null) {
			var data:Tilesheet = new Tilesheet(bitmap);
			for (x in 0...columns)
			{
				for (y in 0...rows) {
					data.addTileRect(new Rectangle(x*tileWidth, y*tileHeight, tileWidth, tileHeight));
				}
			}

			if (data != null)
				_tilesheet.set(name, data);
		}
	}

	public static function getTilesheet(name:String):Tilesheet
	{
		if (_tilesheet.exists(name))
			return _tilesheet.get(name);

		return null;
	}

	public static function removeTilesheet(name:String):Bool
	{
		if (_tilesheet.exists(name))
		{
			var tilesheet = _tilesheet.get(name);
			tilesheet = null;
			return _tilesheet.remove(name);
		}
		return false;
	}

	//##########################################################################################

	// Font storage.
	private static var _font:Map<String,Font> = new Map<String,Font>();

	public static function getFont(name:String):Font
	{
		if (_font.exists(name))
			return _font.get(name);

		var data:Font = openfl.Assets.getFont(name, false);

		if (data != null)
			_font.set(name, data);

		return data;
	}

/*	public static function overwriteBitmapCache(name:String, data:Font):Void
	{
		removeFont(name);
		_font.set(name, data);
	}*/

	public static function removeFont(name:String):Bool
	{
		if (_font.exists(name))
		{
			var font = _font.get(name);
			font = null;
			return _font.remove(name);
		}
		return false;
	}

	private static var _music:Sfx;
	private static var _musicOn:Bool=false;
	private static var _soundOn:Bool=false;

	public static function setMusic(file:String) {
		_music = new Sfx(file);
		_music.type = "music";
	}

	public static function getMusicOn():Bool {
		return _musicOn;
	}

	public static function getSoundOn():Bool {
		return _soundOn;
	}

	public static function toggleMusic():Bool {
		if(_musicOn) {
			_musicOn = false;
			_music.stop();
		} else {
			_musicOn = true;
			_music.loop();
		}
		return _musicOn;
	}

	public static function toggleSound():Bool {
		if(_soundOn) {
			_soundOn = false;
			Sfx.setVolume('sound',0);
		} else {
			_soundOn = true;
			Sfx.setVolume('sound',1);
		}
		return _soundOn;
	}


	//##########################################################################################
	//
	// OTHERS
	//
	//##########################################################################################

	public static function getFullscreenOn():Bool {
	#if mobile
		return true;
	#else
		return Lib.current.stage.displayState != StageDisplayState.NORMAL;
	#end
	}

	public static function toggleFullscreen():Bool {
	#if mobile
		return true;
	#else
		if(Lib.current.stage.displayState != StageDisplayState.FULL_SCREEN_INTERACTIVE){
			Lib.current.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			return true;
		}else {
			Lib.current.stage.displayState = StageDisplayState.NORMAL;
			return false;
		}
	#end
	}

	public static function quit(){
		#if !flash
		Lib.exit();
		#end
	}

}