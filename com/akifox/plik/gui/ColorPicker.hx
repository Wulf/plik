package com.akifox.plik.gui;

import com.akifox.plik.*;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.MouseEvent;
using hxColorToolkit.ColorToolkit;

class ColorPicker extends SpriteContainer implements IStyle {

    var _spectrum:BitmapData;
    var _slider:BitmapData;
    var _bitmapSpectrum:Bitmap;
    var _bitmapSlider:Bitmap;

    var _style:Style = new Style();
    public var style(get,set):Style;
    private function get_style():Style {return _style;}
    private function set_style(value:Style):Style {
      _style = value;
      return value;
    }

    public function getNetWidth():Float {
      return _bitmapSpectrum.width + _style.offset + _bitmapSlider.width;
    }

    public function getNetHeight():Float {
      return _bitmapSpectrum.height;
    }

    public function getGrossWidth():Float {
      return getNetWidth()+_style.padding*2;//+_style.outline_size/2;
    }

    public function getGrossHeight():Float {
      return getNetHeight()+_style.padding*2;//+_style.outline_size/2;
    }


    var _frameSpectrum:Int;
    var _frameHeight:Int;
    var _frameSlider:Int;
    var _action:Int->Void=null;

    var _selectorSpectrum:ShapeContainer;
    var _selectorSpectrumSize:Int = 20;

    var _selectorSlider:ShapeContainer;
    var _selectorSliderSize:Int = 7;

    var _byteArrayUtil:openfl.utils.ByteArray;

    var _colorHSB:hxColorToolkit.spaces.HSB;

    var _lastdraw:Float = 0;

    var _listen:Bool=false;
    public var listen(get,set):Bool;
    private function get_listen():Bool {return _listen;}
    private function set_listen(value:Bool):Bool {
      _listen = value;
      if (value) {
        //hookers on
        addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
      } else {
        //hookers off
        removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
      }
      return value;
    }

  	public function new (style:Style,action:Int->Void,?width_spectrum:Int=360,?height:Int=150,?width_slider:Int=30) {
  		super();
      _style = style;
      _frameSpectrum = width_spectrum;
      _frameSlider = width_slider;
      _frameHeight = height;
      _action = action;

      _byteArrayUtil = new openfl.utils.ByteArray();

      _spectrum = new BitmapData(_frameSpectrum,_frameHeight,false,0);
      _bitmapSpectrum = new Bitmap(_spectrum);
      _bitmapSpectrum.x = _style.padding;
      _bitmapSpectrum.y = _style.padding;
      addChild(_bitmapSpectrum);

      _slider = new BitmapData(_frameSlider,_frameHeight,false,0);
      _bitmapSlider = new Bitmap(_slider);
      _bitmapSlider.x = _frameSpectrum+_style.offset+_style.padding;
      _bitmapSlider.y = _style.padding;
      addChild(_bitmapSlider);

      _selectorSpectrum = new ShapeContainer();
      drawSelectorColorPicker();
      addChild(_selectorSpectrum);

      _selectorSlider = new ShapeContainer();
      _selectorSlider.x = _frameSpectrum+_style.offset+_style.padding;
      drawSelectorSlider();
      addChild(_selectorSlider);

      // Select default (HSB 180,50,50)
      selector(0x408080);

      Style.drawBackground(this,_style);
  	}

    public override function destroy() {
      _slider.dispose();
      _spectrum.dispose();
      _byteArrayUtil.clear();
      super.destroy();
    }

    public function selector(color:Int) {
      var hsb = color.toHSB();
      _colorHSB = hsb;
      drawSpectrum(true);
      drawSlider(true);
      _selectorSpectrum.x = Std.int(hsb.hue*_frameSpectrum/360-_selectorSpectrumSize*0.5)+_style.padding;
      _selectorSpectrum.y = Std.int((hsb.saturation*_frameHeight/100)-_selectorSpectrumSize*0.5)+_style.padding;
      _selectorSlider.y = Std.int(_frameHeight-(hsb.brightness*_frameHeight/100)-_selectorSliderSize/2)+_style.padding;
    }

    private inline function selectorManual(color:Int,x:Int,y:Int) {
      _colorHSB = color.toHSB();
      if (x>_frameSpectrum+_style.padding) {
        _selectorSlider.y = y-_selectorSliderSize/2;
        drawSpectrum();
      } else {
        _selectorSpectrum.x = x-_selectorSpectrumSize*0.5;
        _selectorSpectrum.y = y-_selectorSpectrumSize*0.5;
        drawSlider();
      }
    }

    //*****************************************************************
    // Main render

    public function drawSpectrum(?forceDraw=false) {
      // avoid too many draw spectrum calls
      if (haxe.Timer.stamp()-_lastdraw<0.05 && !forceDraw) return;

      var hsbcolor = new hxColorToolkit.spaces.HSB(0, 0, Std.int(_colorHSB.brightness));

      // // SPECIAL SPECTRUM (half saturation, half brightness)
      // var x:Int=0; var y:Int=0;
      // _spectrum.lock();
  		// for (i in 0...width) {
  		// 	y=0;
  		// 	hue = Std.int(i*360/width);
  		// 	//bri = 95;
  		// 	for (j in 0...height2) {
  		// 		bri = 100-Std.int(j*5/height2); //from 100 to 95
  		// 		sat = Std.int(j*95/height2); // from 0 to 95
      //     _spectrum.setPixel(x,y,(new hxColorToolkit.spaces.HSB(hue, sat, bri).getColor()));
  		// 		y++;
  		// 	}
  		// 	for (k in 0...height2) {
  		// 		bri = 95-Std.int(k*95/height2); //from 95 to 0
  		// 		sat = 95+Std.int(k*5/height2); //from 95 to 100
      //     _spectrum.setPixel(x,y,(new hxColorToolkit.spaces.HSB(hue, sat, bri).getColor()));
  		// 		y++;
  		// 	}
  		// 	x++;
  		// }

      // // SET PIXEL VERSION (Slower)
      // var x = 0;
      // var y = 0;
      // _spectrum.lock();
      // for (i in 0..._frameSpectrum) {
  		// 	y=0;
      //   hsbcolor.hue = Std.int(i*360/_frameSpectrum);
  		// 	for (j in 0..._frameHeight) {
      //     hsbcolor.saturation = Std.int(j*100/_frameHeight); //from 0 to 100
      //     _spectrum.setPixel(x,y,hsbcolor.getColor());
  		// 		y++;
  		// 	}
  		// 	x++;
  		// }
      // _spectrum.unlock();

      // ByteArray version (Faster)
      _byteArrayUtil.clear();
      for (i in 0..._frameHeight) {
      hsbcolor.saturation = Std.int(i*100/_frameHeight); //from 0 to 100
  			for (j in 0..._frameSpectrum) {
          hsbcolor.hue = Std.int(j*360/_frameSpectrum);
          _byteArrayUtil.writeUnsignedInt(hsbcolor.getColor());
  			}
  		}

      _byteArrayUtil.position = 0;
      _spectrum.lock();
      _spectrum.setPixels(new openfl.geom.Rectangle(0,0,_frameSpectrum,_frameHeight),_byteArrayUtil);
      _spectrum.unlock();

      _lastdraw = haxe.Timer.stamp();

    }

    public function drawSlider(?forceDraw=false) {
      // avoid too many draw side calls
      if (haxe.Timer.stamp()-_lastdraw<0.05 && !forceDraw) return;

      var color:Int=0;
      var hsbcolor = new hxColorToolkit.spaces.HSB(Std.int(_colorHSB.hue), Std.int(_colorHSB.saturation), 0);
      _byteArrayUtil.clear();

  		for (i in 0..._frameHeight) {
        hsbcolor.brightness = 100-Std.int(i*100/_frameHeight); //from 100 to 0
  			color = hsbcolor.getColor();
  			for (j in 0..._frameSlider) {
          _byteArrayUtil.writeUnsignedInt(color);
  			}
  		}

      _byteArrayUtil.position = 0;
      _slider.lock();
      _slider.setPixels(new openfl.geom.Rectangle(0,0,_frameSlider,_frameHeight),_byteArrayUtil);
      _slider.unlock();

      _lastdraw = haxe.Timer.stamp();
    }

    //*****************************************************************
    // Listeners

    private var _isChoosing = false;
    private function onMouseMove(event:MouseEvent) {

      if (!_isChoosing) return;

      var x = Std.int(event.localX);
      var y = Std.int(event.localY);

      // out of big boundaries
      if (x<_style.padding || x>_style.padding+_frameSpectrum+_style.offset+_frameSlider || y<_style.padding || y>_style.padding+_frameHeight) return;

      var color = -1;
      if (x > _style.padding+_frameSpectrum+_style.offset && x < _style.padding+_frameSpectrum+_style.offset+_frameSlider) {
        color = _slider.getPixel(x-_frameSpectrum-_style.offset-_style.padding,y-_style.padding);
      } else if (x > _style.padding && x < _style.padding+_frameSpectrum) {
        color = _spectrum.getPixel(x-_style.padding,y-_style.padding);
      }
      //out of precise boundaries
      if (color==-1) return;

      selectorManual(color,x,y);
      _action(color);
    }

    private function onMouseDown(event:MouseEvent) {
      _isChoosing = true;
      onMouseMove(event);
    }

    private function onMouseUp(event:MouseEvent) {
      _lastdraw = 0;
      _isChoosing = false;
    }

    private function onMouseOut(event:MouseEvent) {
      if (!_isChoosing) return;
      onMouseUp(event);
      onMouseMove(event);
    }


    //*****************************************************************
    // Drawers

    private function drawSelectorColorPicker() {
      _selectorSpectrum.graphics.clear();
      _selectorSpectrum.graphics.lineStyle(3,0x000000);
      _selectorSpectrum.graphics.drawCircle(10,10,5);

      _selectorSpectrum.graphics.moveTo(_selectorSpectrumSize*0.5,0);
      _selectorSpectrum.graphics.lineTo(_selectorSpectrumSize*0.5,_selectorSpectrumSize*0.25+_selectorSpectrumSize/20);
      _selectorSpectrum.graphics.moveTo(_selectorSpectrumSize*0.5,_selectorSpectrumSize*0.75-_selectorSpectrumSize/20);
      _selectorSpectrum.graphics.lineTo(_selectorSpectrumSize*0.5,_selectorSpectrumSize);

      _selectorSpectrum.graphics.moveTo(0,_selectorSpectrumSize*0.5);
      _selectorSpectrum.graphics.lineTo(_selectorSpectrumSize*0.25+_selectorSpectrumSize/20,_selectorSpectrumSize*0.5);
      _selectorSpectrum.graphics.moveTo(_selectorSpectrumSize*0.75-_selectorSpectrumSize/20,_selectorSpectrumSize*0.5);
      _selectorSpectrum.graphics.lineTo(_selectorSpectrumSize,_selectorSpectrumSize*0.5);

      _selectorSpectrum.graphics.lineStyle(1,0xFFFFFF);
      _selectorSpectrum.graphics.drawCircle(_selectorSpectrumSize*0.5,_selectorSpectrumSize*0.5,5);

      _selectorSpectrum.graphics.moveTo(_selectorSpectrumSize*0.5,0);
      _selectorSpectrum.graphics.lineTo(_selectorSpectrumSize*0.5,_selectorSpectrumSize*0.25+_selectorSpectrumSize/20);
      _selectorSpectrum.graphics.moveTo(_selectorSpectrumSize*0.5,_selectorSpectrumSize*0.75-_selectorSpectrumSize/20);
      _selectorSpectrum.graphics.lineTo(_selectorSpectrumSize*0.5,_selectorSpectrumSize);

      _selectorSpectrum.graphics.moveTo(0,_selectorSpectrumSize*0.5);
      _selectorSpectrum.graphics.lineTo(_selectorSpectrumSize*0.25+_selectorSpectrumSize/20,_selectorSpectrumSize*0.5);
      _selectorSpectrum.graphics.moveTo(_selectorSpectrumSize*0.75-_selectorSpectrumSize/20,_selectorSpectrumSize*0.5);
      _selectorSpectrum.graphics.lineTo(_selectorSpectrumSize,_selectorSpectrumSize*0.5);
    }

    private function drawSelectorSlider() {
      _selectorSlider.graphics.clear();


      _selectorSlider.graphics.lineStyle(3,0x000000);
      _selectorSlider.graphics.drawRect(0,0,_frameSlider,_selectorSliderSize);//,_selectorSliderSize/2);
      _selectorSlider.graphics.lineStyle(1,0xFFFFFF);
      _selectorSlider.graphics.drawRect(0,0,_frameSlider,_selectorSliderSize);//,_selectorSliderSize/2);
    }

}
